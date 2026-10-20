#!/usr/bin/env python3
"""Export legacy-compatible end-up STL; slice locally for QA, never print."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

import manifold3d as mf
import numpy as np
import trimesh

import build_hook_plate as plate
from inspect_hook_plate import instances, statistics
from verify_release import load

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'output/legacy-rail-upright-v3'
SOURCE = ROOT / 'src/rail_legacy_upright.scad'
ROTATION = np.array([[0, 1, 0, 0], [0, 0, 1, 0],
                     [1, 0, 0, 0], [0, 0, 0, 1]], dtype=float)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def solid_of(mesh):
    solid = mf.Manifold(mf.Mesh(np.asarray(mesh.vertices, dtype=np.float32),
                               np.asarray(mesh.faces, dtype=np.uint32)))
    assert solid.status() == mf.Error.NoError
    return solid


def export(length):
    name = f'legacy-hooks-rail-front8-back12-L{length}-upright-v3.stl'
    target = OUT / 'delivery' / name
    target.parent.mkdir(parents=True, exist_ok=True)
    # Never pick a historical STL instead of re-exporting the current source.
    with tempfile.TemporaryDirectory(prefix='upright-rail-') as temporary:
        fresh = Path(temporary) / name
        subprocess.run([plate.OPENSCAD, '--hardwarnings', '--backend=CGAL',
                        '--export-format', 'binstl', '-D', f'segment_length={length}',
                        '-o', str(fresh), str(SOURCE)], check=True,
                       stdout=subprocess.DEVNULL)
        mesh, solid = load(fresh)
        assert np.allclose(mesh.bounds, [[0, 0, 0], [12, 5.8, length]], atol=1e-5)
        assert abs(solid.volume() - 23.8 * length) < .001
        downward = mesh.face_normals[:, 2] < -.001
        assert np.allclose(mesh.triangles[downward, :, 2], 0), 'Suspended down-face'
        vertical = np.abs(mesh.face_normals[:, 2]) < .999
        assert np.allclose(mesh.face_normals[vertical, 2], 0)
        assert np.allclose(np.unique(mesh.vertices[:, 2]), [0, length])
        # Inverse print rotation: compare the exact original H profile and fit
        # against the already printed v1 hook, not the new 12.6-mm hook.
        assembly = mesh.copy()
        assembly.apply_transform(np.linalg.inv(ROTATION))
        assembly_solid = solid_of(assembly)
        reference, reference_solid = load(
            ROOT / 'output/fit-12mm-v2/legacy-rail-8mm-front-300.stl')
        cropped = reference_solid ^ mf.Manifold.cube((length, 12, 5.8))
        difference = ((assembly_solid - cropped) + (cropped - assembly_solid)).volume()
        assert difference < .001, difference
        _, hook = load(ROOT / 'output/print-12-v1/source/slider_hook.stl')
        positions = [-18, -1, 0, 1, length / 2, length - 18, length - 1, length]
        intersections = {str(x): (hook.translate((x, 0, 0)) ^ assembly_solid).volume()
                         for x in positions}
        assert all(abs(v) < 1e-6 for v in intersections.values()), intersections
        shutil.copy2(fresh, target)
    return target, {'file': name, 'sha256': sha(target),
        'part_id': 'legacy_rail_8mm_front', 'variant': f'L{length}_end_up',
        'bounds_mm': mesh.bounds.tolist(), 'volume_mm3': solid.volume(),
        'triangles': len(mesh.faces), 'watertight': True,
        'connected_solids': 1, 'degenerate_faces': 0,
        'assembly_to_stl_matrix': ROTATION.tolist(), 'no_scaling': True,
        'constant_cross_section_area_mm2': 23.8,
        'suspended_downward_faces': 0,
        'original_profile_difference_mm3': difference,
        'old_hook_intersection_mm3': intersections}


def slice_check(path, length):
    folder = OUT / 'validation-only' / f'L{length}'
    folder.mkdir(parents=True, exist_ok=True)
    base = ROOT / 'output/print-12-v1/config'
    settings = {kind: json.loads((base / f'{kind}.json').read_text())
                for kind in ('machine', 'process', 'filament')}
    process = settings['process']
    process.update({'layer_height': '.20', 'brim_width': '10',
        'brim_type': 'outer_only', 'brim_object_gap': '.1',
        'initial_layer_speed': '20', 'initial_layer_infill_speed': '20',
        'outer_wall_speed': '25', 'inner_wall_speed': '35',
        'gap_infill_speed': '30', 'internal_solid_infill_speed': '35',
        'default_acceleration': '500', 'outer_wall_acceleration': '500',
        'top_surface_acceleration': '500', 'travel_speed': '120',
        # Leave support ON for the QA slice: prove that no support is generated.
        'enable_support': '1', 'support_on_build_plate_only': '0'})
    filament = settings['filament']
    filament.update({'slow_down_for_layer_cooling': ['1'],
                     'slow_down_layer_time': ['12'], 'slow_down_min_speed': ['10']})
    for kind, data in settings.items():
        plate.write_json(folder / 'config' / f'{kind}.json', data)
    mesh, _ = load(path)
    mesh.apply_translation([122, 125.1, 0])  # bounding-box centre on 128,128
    input_file = folder / 'centred-rail.stl'
    mesh.export(input_file)
    target = plate.slice_file(folder, input_file, folder, arrange=False)
    actual = instances(target)
    assert len(actual) == 1
    sliced_mesh = actual[0][0]
    assert np.allclose(sliced_mesh.bounds, mesh.bounds, atol=1e-4)
    assert abs(sliced_mesh.volume / mesh.volume - 1) < 1e-5
    stats, saved, segments = statistics(target)
    assert not stats['warnings'], stats['warnings']
    assert saved['enable_support'] == '1'
    assert stats['support_g'] == 0
    assert not any(len(v) for k, v in segments.items() if k.startswith('Support'))
    assert 'Skirt' in segments or 'Brim' in segments, list(segments)
    adhesion = [v for k, v in segments.items() if k in ('Skirt', 'Brim')]
    points = np.concatenate([np.asarray(v)[:, :6].reshape(-1, 3) for v in adhesion])
    # The configured extruder offset is applied by firmware, not in G-code XY.
    points[:, :2] += [float(v) for v in saved['extruder_offset'][0].split('x')]
    assert np.ptp(points[:, 0]) > 30 and np.ptp(points[:, 1]) > 23
    assert np.all(points[:, :2].min(axis=0) > [20, 28])
    assert np.all(points[:, :2].max(axis=0) < [251, 251])
    assert points[:, 2].max() <= .201, 'Brim must remain a single removable layer'
    max_height = float(settings['machine']['printable_height'])
    assert max_height == 250 and length < max_height
    with (folder / 'reopen-native.log').open('w') as log:
        subprocess.run([plate.STUDIO, '--info', str(target)], check=True,
                       stdout=log, stderr=subprocess.STDOUT)
    native = (folder / 'reopen-native.log').read_text()
    assert 'manifold = yes' in native and 'number_of_parts =  1' in native
    return {'slicer': 'BambuStudio 01.10.02.76',
        'source_stl_sha256': sha(path), 'statistics': stats,
        'support_enabled_for_test': True, 'support_toolpath_segments': 0,
        'brim_width_mm': 10, 'brim_object_gap_mm': .1,
        'brim_toolpath_bounds_mm': [points.min(axis=0).tolist(), points.max(axis=0).tolist()],
        'printable_height_mm_from_installed_profile': max_height,
        'headroom_mm': max_height - length,
        'native_reopen': 'closed manifold / one part / unscaled',
        'gui_acceptance': 'not_verified', 'physical_print': 'pending',
        'sent_to_printer': False,
        'config_sha256': {k: sha(folder / 'config' / f'{k}.json') for k in settings},
        'process_overrides': {k: v for k, v in process.items()
                              if v != json.loads((base / 'process.json').read_text()).get(k)}}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--slice-check', action='store_true')
    args = parser.parse_args()
    manifest = {'schema_version': 'upright-rail-stl-v3', 'units': 'mm',
        'created_utc': datetime.now(timezone.utc).isoformat(),
        'delivery_kind': 'STL only; local slicing is validation, not a delivered 3MF',
        'source_commit_before_build': subprocess.check_output(
            ['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
        'sources': {str(p.relative_to(ROOT)): sha(p) for p in
                    [SOURCE, ROOT / 'src/rail.scad', ROOT / 'src/parameters.scad']},
        'profile_mm': {'rear_wing_height': 12, 'front_wing_height': 8,
            'outside_depth': 5.8, 'inside_depth': 3.8, 'wing_wall': 1, 'web_wall': 1},
        'target': 'X1 Carbon / 0.4-mm nozzle / PETG',
        'permanent_base': False, 'special_splice': False,
        'physical_fit_and_stability_test': 'pending', 'parts': []}
    for length in (200, 240):
        path, record = export(length)
        if args.slice_check:
            report = slice_check(path, length)
            plate.write_json(OUT / 'reports' / f'L{length}-slice-validation.json', report)
            record['slice_validation'] = f'../reports/L{length}-slice-validation.json'
        manifest['parts'].append(record)
        print(f'PASS: upright {length} mm, unchanged legacy fit, {path}', flush=True)
    plate.write_json(OUT / 'delivery/manifest.json', manifest)


if __name__ == '__main__':
    main()
