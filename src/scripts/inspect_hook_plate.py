#!/usr/bin/env python3
"""Read actual 3MF/G-code statistics and verify a 12-instance plate."""
import argparse
from collections import defaultdict
from datetime import datetime, timezone
import hashlib
import json
import math
from pathlib import Path
import re
import xml.etree.ElementTree as ET
from zipfile import ZipFile

import numpy as np
import trimesh

CORE = 'http://schemas.microsoft.com/3dmanufacturing/core/2015/02'
PRODUCTION = 'http://schemas.microsoft.com/3dmanufacturing/production/2015/06'


def matrix(value):
    result = np.eye(4)
    if value:
        numbers = np.array([float(v) for v in value.split()])
        result[:3,:3] = numbers[:9].reshape(3,3).T
        result[:3,3] = numbers[9:]
    return result


def instances(path):
    result = []
    with ZipFile(path) as package:
        documents = {}
        def document(name):
            if name not in documents:
                documents[name] = ET.fromstring(package.read(name))
                assert documents[name].get('unit') == 'millimeter'
            return documents[name]
        def geometry(file, identifier, transform):
            obj = document(file).find(f'{{{CORE}}}resources/{{{CORE}}}object[@id="{identifier}"]')
            assert obj is not None
            mesh = obj.find(f'{{{CORE}}}mesh')
            if mesh is not None:
                vertices = [[float(v.get(k)) for k in ('x','y','z')]
                            for v in mesh.findall(f'{{{CORE}}}vertices/{{{CORE}}}vertex')]
                faces = [[int(t.get(k)) for k in ('v1','v2','v3')]
                         for t in mesh.findall(f'{{{CORE}}}triangles/{{{CORE}}}triangle')]
                item = trimesh.Trimesh(vertices=vertices, faces=faces, process=False)
                item.apply_transform(transform)
                return [item]
            meshes = []
            for child in obj.findall(f'{{{CORE}}}components/{{{CORE}}}component'):
                child_file = child.get(f'{{{PRODUCTION}}}path', file).lstrip('/')
                meshes += geometry(child_file, child.get('objectid'),
                                   transform @ matrix(child.get('transform')))
            return meshes
        root = '3D/3dmodel.model'
        for item in document(root).findall(f'{{{CORE}}}build/{{{CORE}}}item'):
            transform = matrix(item.get('transform'))
            meshes = geometry(root, item.get('objectid'), transform)
            result.append((trimesh.util.concatenate(meshes), transform))
    return result


def gcode_features(text):
    feature = None
    relative_e = False
    relative_xyz = False
    position = {'X': 0., 'Y': 0., 'Z': 0., 'E': 0.}
    lengths = defaultdict(float)
    segments = defaultdict(list)
    for line in text.splitlines():
        if line.startswith('; FEATURE:'):
            feature = line.split(':', 1)[1].strip()
        code = line.split(';', 1)[0].strip()
        if not code:
            continue
        command = code.split()[0]
        if command in ('M82', 'M83'):
            relative_e = command == 'M83'
        elif command in ('G90', 'G91'):
            relative_xyz = command == 'G91'
        elif command in ('G0', 'G1', 'G2', 'G3', 'G92'):
            values = {k: float(v) for k, v in re.findall(r'([XYZEIJ])(-?(?:\d+\.?\d*|\.\d+))', code)}
            args = {k:v for k,v in values.items() if k in position}
            before = position.copy()
            if command == 'G92':
                position.update(args)
                continue
            for k, value in args.items():
                relative = relative_e if k == 'E' else relative_xyz
                position[k] = before[k] + value if relative else value
            extrusion = position['E'] - before['E']
            distance = math.hypot(position['X']-before['X'], position['Y']-before['Y'])
            if feature and feature != 'Custom' and extrusion > 0 and (distance > 1e-5 or command in ('G2','G3')):
                lengths[feature] += extrusion
                start=np.array([before[k] for k in 'XYZ'])
                end=np.array([position[k] for k in 'XYZ'])
                if command in ('G2','G3'):
                    assert 'I' in values or 'J' in values, code
                    center=start[:2]+[values.get('I',0),values.get('J',0)]
                    a=start[:2]-center;b=end[:2]-center
                    angle0=math.atan2(a[1],a[0]);angle1=math.atan2(b[1],b[0])
                    sweep=(angle1-angle0)%(2*math.pi)
                    if command=='G2':sweep-=2*math.pi
                    if abs(sweep)<1e-9:sweep=2*math.pi
                    radius0=np.linalg.norm(a);radius1=np.linalg.norm(b)
                    count=max(1,math.ceil(abs(sweep)/math.radians(5)),
                              math.ceil(abs(sweep)*max(radius0,radius1)/.25))
                    last=start
                    for index in range(1,count+1):
                        t=index/count;angle=angle0+sweep*t
                        radius=radius0*(1-t)+radius1*t
                        point=np.r_[center+radius*np.array([math.cos(angle),math.sin(angle)]),
                                    start[2]*(1-t)+end[2]*t]
                        if index==count:point=end
                        segments[feature].append([*last,*point,extrusion/count])
                        last=point
                else:
                    segments[feature].append([*start,*end,extrusion])
    return dict(lengths), dict(segments)


def statistics(path):
    with ZipFile(path) as package:
        tree = ET.fromstring(package.read('Metadata/slice_info.config'))
        metadata = {e.get('key'): e.get('value') for e in tree.findall('plate/metadata')}
        settings = json.loads(package.read('Metadata/project_settings.config'))
        lengths, segments = gcode_features(package.read('Metadata/plate_1.gcode').decode())
    density = float(settings['filament_density'][0])
    diameter = float(settings['filament_diameter'][0])
    grams_per_mm = math.pi*(diameter/2)**2*density/1000
    masses = {k: v*grams_per_mm for k, v in lengths.items()}
    result = {
        'file': str(path), 'total_g': float(metadata['weight']),
        'total_seconds': int(metadata['prediction']),
        'support_g': sum(v for k,v in masses.items() if k.startswith('Support')),
        'feature_g': masses, 'feature_segment_counts': {k:len(v) for k,v in segments.items()},
        'warnings': [e.attrib for e in tree.findall('plate/warning')],
        'printer': settings['printer_settings_id'], 'filament': settings['filament_type'],
        'layer_mm': settings['layer_height'],
    }
    return result, settings, segments


def comparison(folder):
    result = []
    for path in sorted((folder/'trials').glob('*/sliced.3mf')):
        row, _, _ = statistics(path)
        row['orientation'] = path.parent.name
        result.append(row)
    result.sort(key=lambda row: row['support_g'])
    (folder/'orientation-comparison.json').write_text(json.dumps(result, indent=2)+'\n')
    for row in result:
        print(f"{row['orientation']:10} support={row['support_g']:.3f} g "
              f"total={row['total_g']:.2f} g time={row['total_seconds']/60:.1f} min")


def verify_plate(folder):
    from scipy.spatial import cKDTree
    path=folder/'hook-12-PETG-X1C-0p4-0p12.3mf'
    stats,settings,segments=statistics(path)
    actual=instances(path)
    placement=json.loads((folder/'plate-placement.json').read_text())
    pose=json.loads((folder/'trials/side/pose.json').read_text())
    identity=json.loads((folder/'source/identity.json').read_text())
    source=trimesh.load_mesh(folder/'source/slider_hook.stl')
    project=Path(__file__).resolve().parents[2]
    assert all(hashlib.sha256((project/p).read_bytes()).hexdigest()==h
               for p,h in identity['sources'].items())
    assert len(actual)==placement['count']==12
    assert settings['printer_settings_id']=='Bambu Lab X1 Carbon 0.4 nozzle'
    assert settings['filament_type']==['PETG'] and settings['nozzle_diameter']==['0.4']
    assert settings['layer_height']=='0.12' and settings['support_style']=='snug'
    assert settings['support_on_build_plate_only']=='1'
    assert not stats['warnings'], stats['warnings']
    rotation=np.array(pose['rotation']);rotation[:3,3]=pose['bed_shift_mm']
    oriented=source.copy();oriented.apply_transform(rotation)
    expected_centers=np.array([oriented.centroid+xyz
                              for xyz in placement['translations_mm']])
    ids=[];copies=[];all_bounds=[]
    for index,(mesh,build) in enumerate(actual):
        assert mesh.is_watertight and mesh.is_winding_consistent
        assert np.all(mesh.nondegenerate_faces())
        assert abs(mesh.volume/source.volume-1)<1e-5
        assert np.allclose(np.linalg.svd(build[:3,:3])[1],1,atol=1e-7)
        expected_id=int(np.argmin(np.linalg.norm(expected_centers-mesh.centroid,axis=1)))
        ids.append(expected_id)
        assert np.linalg.norm(mesh.centroid-expected_centers[expected_id])<1e-3
        expected=oriented.vertices+placement['translations_mm'][expected_id]
        deviation=float(max(cKDTree(mesh.vertices).query(expected)[0]))
        assert deviation<1e-4, deviation
        assert np.all(mesh.bounds[0]>=np.array([5,5,-1e-4]))
        assert np.all(mesh.bounds[1]<=np.array([251,251,256]))
        all_bounds.append(mesh.bounds)
        copies.append({'copy':index+1,'bounds_mm':mesh.bounds.tolist(),
                       'mesh_max_deviation_mm':deviation,'unit_scale':True})
    assert len(set(ids))==12
    for i,a in enumerate(all_bounds):
        for b in all_bounds[:i]:
            assert np.any(a[0,:2]>b[1,:2]+6) or np.any(b[0,:2]>a[1,:2]+6)
    with ZipFile(path) as package:
        model_settings=ET.fromstring(package.read('Metadata/model_settings.config'))
        assert len(model_settings.findall('plate'))==1
        # 1.10 CLI omits model_instance tags. Count the actual build tree above
        # and assign its bounds to the sole physical plate, not an optional UI
        # cache. Every core object must also have native mesh metadata.
        assert len(model_settings.findall('object'))==12
        for mesh_stat in model_settings.findall('object/part/mesh_stat'):
            assert all(mesh_stat.get(k)=='0' for k in
                       ('edges_fixed','degenerate_facets','facets_removed',
                        'facets_reversed','backwards_edges'))
        assert model_settings.find('plate/metadata[@key="gcode_file"]').get('value')=='Metadata/plate_1.gcode'
        assert package.read('Metadata/plate_1.gcode')
    # Check both ordinary support and interface paths, not just a config flag.
    support=np.array([s for kind in ('Support','Support interface')
                     for s in segments.get(kind,[])])
    points=np.concatenate([support[:,:3],support[:,3:6],
                           (support[:,:3]+support[:,3:6])/2])
    offset=[float(v) for v in settings['extruder_offset'][0].split('x')]
    points[:,:2]+=offset
    centers=np.array([mesh.centroid for mesh,_ in actual])
    assigned=np.argmin(np.linalg.norm(points[:,None,:2]-centers[None,:,:2],axis=2),axis=1)
    contacts=0;cavity=0;front=0
    for index,(mesh,build) in enumerate(actual):
        group=points[assigned==index]
        near,dist,tri=trimesh.proximity.closest_point(mesh,group)
        keep=(dist<.55)&(mesh.face_normals[tri,2]<-.2)
        transform=build@rotation
        original=trimesh.transform_points(near[keep],np.linalg.inv(transform))
        normals=mesh.face_normals[tri[keep]]@transform[:3,:3]
        contacts+=len(original)
        cavity+=int(np.count_nonzero((original[:,1]>1.7)&
                                    (original[:,2]>3.65)&(original[:,2]<6.2)))
        front+=int(np.count_nonzero((original[:,1]<1)&(normals[:,2]>.7)))
    assert cavity==0, ('support on sliding faces',cavity)
    assert front==0, ('support on hook forward face',front)
    reopened=(folder/'reopen-native.log').read_text()
    assert len(re.findall(r'^manifold = yes$',reopened,re.M))==12
    assert len(re.findall(r'^number_of_parts =  1$',reopened,re.M))==12
    assert 'manifold = no' not in reopened and 'open_edges' not in reopened
    result={'schema_version':'hook-print-plate-v1',
            'generated_at_utc':datetime.now(timezone.utc).isoformat(),
            'kind':'sliced-project','slicer':'Bambu Studio 01.10.02.76',
            'source':identity,'part_id':'slider_hook',
            'source_entry':'src/slider_hook.scad (top-level union)',
            'source_modules':['step_geometry','hook_bent_geometry'],
            'material':'PETG','plate_count':1,'object_count':12,'units':'mm',
            'numeric_mesh_normalization':json.loads((folder/'mesh-normalization.json').read_text()),
            'bed_mm':[256,256],'copies':copies,'statistics':stats,
            'support_contact_check':{'ordinary_and_interface_samples':len(points),
                'near_surface_samples':contacts,'sliding_cavity_samples':cavity,
                'hook_forward_face_samples':front,'distance_threshold_mm':.55,
                'method':'all support toolpaths including G2/G3 arcs tessellated at <=0.25 mm / 5 degrees; endpoints and midpoints; nearest downward mesh faces'},
            'file_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
            'target_slicer_reopen':{'method':'Bambu Studio --info',
                'closed_manifold_single_parts':12,'passed':True},
            'native_gui_preview':'pending: computer-use window reads timed out; no GUI preview acceptance claimed',
            'sent_to_printer':False,'physical_print_and_load_test':'pending'}
    (folder/'plate-validation.json').write_text(json.dumps(result,indent=2)+'\n')
    print('PASS: native sliced 3MF; one plate, 12 unchanged rigid copies;')
    print('no scaling, overlap, bed overflow or protected-face support contacts.')
    print(f"Estimated {stats['total_g']} g, {stats['total_seconds']} seconds; "
          f"support {stats['support_g']:.3f} g.")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('folder', type=Path)
    parser.add_argument('--verify-plate',action='store_true')
    args = parser.parse_args()
    if args.verify_plate:
        verify_plate(args.folder)
    else:
        comparison(args.folder)
