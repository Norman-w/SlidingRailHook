#!/usr/bin/env python3
"""PETG orientation trials and native Bambu Studio 3MF generation (no printing)."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import math
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET
from zipfile import ZIP_DEFLATED, ZipFile

import numpy as np
import trimesh

ROOT = Path(__file__).resolve().parents[2]
PROFILES = Path('/Applications/BambuStudio.app/Contents/Resources/profiles/BBL')
STUDIO = '/Applications/BambuStudio.app/Contents/MacOS/BambuStudio'
OPENSCAD = '/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD'
NS = 'http://schemas.microsoft.com/3dmanufacturing/core/2015/02'
ET.register_namespace('', NS)
ORIENTATIONS = {
    'original': (0, 0, 0), 'x45': (45, 0, 0), 'x90': (90, 0, 0),
    'x135': (135, 0, 0), 'x180': (180, 0, 0),
    'xm45': (-45, 0, 0), 'xm90': (-90, 0, 0),
    'xm135': (-135, 0, 0), 'side': (0, 90, 0),
    'x10': (10, 0, 0), 'x20': (20, 0, 0),
    'xm10': (-10, 0, 0), 'xm20': (-20, 0, 0),
    'side75': (0, 75, 0), 'side105': (0, 105, 0),
}


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + '\n')


def preset(kind, name):
    data = json.loads((PROFILES / kind / f'{name}.json').read_text())
    result = preset(kind, data['inherits']) if data.get('inherits') else {}
    result.update(data)
    result.pop('inherits', None)
    return result


def profiles(out, layer=0.16):
    machine = preset('machine', 'Bambu Lab X1 Carbon 0.4 nozzle')
    machine['printer_settings_id'] = machine['name']
    material = preset('filament', 'Generic PETG')
    material['filament_settings_id'] = [material['name']]
    process = preset('process', '0.16mm High Quality @BBL X1C')
    process.update({
        'name': 'Hook PETG smooth economy', 'print_settings_id': 'Hook PETG smooth economy',
        'layer_height': str(layer), 'initial_layer_print_height': '0.2',
        'wall_loops': '3', 'sparse_infill_density': '12%',
        'sparse_infill_pattern': 'gyroid', 'wall_generator': 'arachne',
        'top_shell_layers': '7', 'bottom_shell_layers': '5',
        'top_shell_thickness': '0.84', 'outer_wall_speed': '30',
        'inner_wall_speed': '70', 'top_surface_speed': '30',
        'outer_wall_acceleration': '1000', 'seam_position': 'back',
        'enable_support': '1', 'support_type': 'tree(auto)',
        'support_style': 'default', 'support_on_build_plate_only': '1',
        'support_threshold_angle': '30', 'support_top_z_distance': '0.24',
        'support_bottom_z_distance': '0.24', 'support_object_xy_distance': '0.4',
        'support_interface_top_layers': '3', 'support_interface_spacing': '0.3',
        'support_interface_speed': '35', 'support_speed': '60',
        'tree_support_branch_diameter': '1.5', 'enable_prime_tower': '0',
        'brim_type': 'outer_only', 'brim_width': '2', 'brim_object_gap': '0.15',
        'curr_bed_type': 'Textured PEI Plate', 'print_sequence': 'by layer',
        'ironing_type': 'no ironing',
    })
    for name, data in [('machine', machine), ('filament', material), ('process', process)]:
        write_json(out / 'config' / f'{name}.json', data)


def prepare(out):
    (out / 'source').mkdir(parents=True, exist_ok=True)
    with (out / 'source' / 'export.log').open('w') as log:
        subprocess.run([OPENSCAD, '--hardwarnings', '--backend=CGAL',
                        '--export-format', 'binstl', '-o', str(out / 'source/slider_hook.stl'),
                        str(ROOT / 'src/slider_hook.scad')], check=True,
                       stdout=log, stderr=subprocess.STDOUT)
    mesh = trimesh.load_mesh(out / 'source/slider_hook.stl')
    assert mesh.is_watertight and mesh.is_winding_consistent
    profiles(out)
    poses(out)
    write_json(out / 'source/identity.json', {
        'source_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT,
                                                 text=True).strip(),
        'sources': {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                    for p in sorted((ROOT / 'src').glob('*.scad'))},
        'stl_sha256': hashlib.sha256((out / 'source/slider_hook.stl').read_bytes()).hexdigest(),
    })


def poses(out, names=None):
    mesh = trimesh.load_mesh(out / 'source/slider_hook.stl')
    for name, angles in ORIENTATIONS.items():
        if names is not None and name not in names:
            continue
        transform = trimesh.transformations.euler_matrix(*np.radians(angles))
        oriented = mesh.copy()
        oriented.apply_transform(transform)
        shift = -oriented.bounds[0]
        oriented.apply_translation(shift)
        folder = out / 'trials' / name
        folder.mkdir(parents=True, exist_ok=True)
        oriented.export(folder / 'hook.stl')
        write_json(folder / 'pose.json', {'euler_deg': angles,
                   'rotation': transform.tolist(), 'bed_shift_mm': shift.tolist(),
                   'bounds_mm': oriented.bounds.tolist(), 'units': 'mm'})


def slice_file(out, input_file, folder, filename='sliced.3mf', arrange=True):
    folder.mkdir(parents=True, exist_ok=True)
    command = [STUDIO, '--load-settings',
               f'{out / "config/machine.json"};{out / "config/process.json"}',
               '--load-filaments', str(out / 'config/filament.json'),
               '--orient', '0', '--arrange', '1' if arrange else '0',
               '--ensure-on-bed', '--slice', '0', '--debug', '2',
               '--outputdir', str(folder), '--export-3mf', filename, str(input_file)]
    with (folder / 'slice.log').open('w') as log:
        run = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT)
    if run.returncode:
        raise RuntimeError(f'{folder.name}: exit {run.returncode}; see slice.log')
    target = folder / filename
    assert target.exists(), target
    return target


def slice_trial(out, name):
    return slice_file(out, out / 'trials' / name / 'hook.stl', out / 'trials' / name)


def quality_trials(out):
    # Preserve the common 0.16-mm orientation study before testing finish.
    for name in ('machine','filament','process'):
        write_json(out/'orientation-config'/f'{name}.json',
                   json.loads((out/'config'/f'{name}.json').read_text()))
    profiles(out, layer=0.12)
    cases = [('side-tree','side','tree(auto)','default'),
             ('side-normal','side','normal(auto)','default'),
             ('side-snug','side','normal(auto)','snug'),
             ('original-tree','original','tree(auto)','default')]
    for name, orientation, support, style in cases:
        folder=out/'quality'/name
        for kind in ('machine','filament','process'):
            data=json.loads((out/'config'/f'{kind}.json').read_text())
            if kind=='process':
                data.update({'support_type':support,'support_style':style})
            if kind=='filament':
                # Stay below the generic PETG profile's 70 C softening warning.
                data.update({'textured_plate_temp':['65'],
                             'textured_plate_temp_initial_layer':['65']})
            write_json(folder/'config'/f'{kind}.json',data)
        print(slice_file(folder,out/'trials'/orientation/'hook.stl',folder),flush=True)


def model_plate(out, name, count=12):
    mesh = trimesh.load_mesh(out / 'trials' / name / 'hook.stl')
    # STL uses float32: rotating the CGAL mesh merges four sub-micron vertex
    # pairs and collapses eight triangles. Remove only those zero-area faces;
    # unlike an STL import, Bambu does not repair a handoff 3MF automatically.
    before_volume = mesh.volume
    zero_area = mesh.area_faces == 0
    removed = int(np.count_nonzero(zero_area))
    mesh.update_faces(~zero_area)
    mesh.remove_unreferenced_vertices()
    assert mesh.is_watertight and mesh.is_winding_consistent
    assert np.all(mesh.nondegenerate_faces())
    assert abs(mesh.volume-before_volume) < 1e-8
    write_json(out/'mesh-normalization.json', {
        'input': f'trials/{name}/hook.stl',
        'operation': 'remove exactly zero-area float32-collapsed faces only',
        'removed_faces': removed, 'remaining_faces': len(mesh.faces),
        'volume_change_mm3': mesh.volume-before_volume,
        'watertight': True, 'degenerate_faces': 0,
        'cad_geometry_changed': False,
    })
    model = ET.Element(f'{{{NS}}}model', unit='millimeter', attrib={'xml:lang': 'en-US'})
    resources = ET.SubElement(model, f'{{{NS}}}resources')
    obj = ET.SubElement(resources, f'{{{NS}}}object', id='1', type='model', name='SliderHook')
    body = ET.SubElement(obj, f'{{{NS}}}mesh')
    vertices = ET.SubElement(body, f'{{{NS}}}vertices')
    for x, y, z in mesh.vertices:
        ET.SubElement(vertices, f'{{{NS}}}vertex', x=f'{x:.9g}', y=f'{y:.9g}', z=f'{z:.9g}')
    triangles = ET.SubElement(body, f'{{{NS}}}triangles')
    for a, b, c in mesh.faces:
        ET.SubElement(triangles, f'{{{NS}}}triangle', v1=str(a), v2=str(b), v3=str(c))
    build = ET.SubElement(model, f'{{{NS}}}build')
    width, depth, _ = mesh.extents
    pitch_x, pitch_y = width+12, depth+12
    positions = []
    columns=min(4,count);rows=math.ceil(count/columns)
    for i in range(count):
        x = 128-(columns-1)*pitch_x/2-width/2+(i%columns)*pitch_x
        y = 128-(rows-1)*pitch_y/2-depth/2+(i//columns)*pitch_y
        ET.SubElement(build, f'{{{NS}}}item', objectid='1',
                      transform=f'1 0 0 0 1 0 0 0 1 {x:.9g} {y:.9g} 0')
        positions.append([x, y, 0])
    target = out / f'hook-{count}-arranged.3mf'
    with ZipFile(target, 'w', ZIP_DEFLATED) as package:
        package.writestr('[Content_Types].xml',
            '<?xml version="1.0"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
            '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
            '<Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/></Types>')
        package.writestr('_rels/.rels',
            '<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Target="/3D/3dmodel.model" Id="rel0" '
            'Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/></Relationships>')
        package.writestr('3D/3dmodel.model', ET.tostring(model, encoding='utf-8', xml_declaration=True))
    write_json(out / 'plate-placement.json', {'units': 'mm', 'count': count,
               'bed_mm': [256, 256], 'orientation': name,
               'object_size_mm': mesh.extents.tolist(), 'translations_mm': positions})
    return target


def final_plate(out):
    for kind in ('machine','filament','process'):
        write_json(out/'config'/f'{kind}.json',json.loads(
            (out/'quality/side-snug/config'/f'{kind}.json').read_text()))
    input_file=model_plate(out,'side',12)
    return slice_file(out,input_file,out,
        filename='hook-12-PETG-X1C-0p4-0p12.3mf',arrange=False)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['prepare', 'poses', 'trial', 'compare', 'quality', 'plate', 'final'])
    parser.add_argument('--output', type=Path, default=ROOT / 'output/print-12-v1')
    parser.add_argument('--orientation', default='original', choices=ORIENTATIONS)
    args = parser.parse_args()
    out = args.output.resolve()
    if args.action == 'prepare':
        prepare(out)
    elif args.action == 'poses':
        poses(out)
    elif args.action == 'trial':
        print(slice_trial(out, args.orientation))
    elif args.action == 'compare':
        with ThreadPoolExecutor(max_workers=3) as pool:
            for path in pool.map(lambda name: slice_trial(out, name), ORIENTATIONS):
                print(path, flush=True)
    elif args.action == 'quality':
        quality_trials(out)
    elif args.action == 'final':
        print(final_plate(out))
    else:
        print(model_plate(out, args.orientation))
