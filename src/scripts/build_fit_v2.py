#!/usr/bin/env python3
"""Measured 12/6/4 hook + legacy-hook reuse rail. Never sends a print job."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

import manifold3d as mf
import numpy as np
import trimesh

import build_hook_plate as plate
from inspect_hook_plate import instances, statistics, verify_plate
from verify_release import load

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'output/fit-12mm-v2'
FIT={'rail_back_height_mm':12,'rail_front_height_mm':12,
     'rail_outer_depth_mm':6,'rail_inner_separation_mm':4,
     'rail_wing_wall_mm':1,'rail_web_wall_mm':1,
     'cavity_y_mm':[-.3,12.3],'cavity_contact_z_mm':[4.15,6.31],
     'hook_base_y_mm':-1.3,'clearance_per_side_mm':.3,
     'carriage_side_wall_mm':1}


def export_legacy(length):
    path=OUT/f'legacy-rail-8mm-front-{length}.stl'
    subprocess.run([plate.OPENSCAD,'--hardwarnings','--backend=CGAL',
        '--export-format','binstl','-D',f'legacy_rail_length={length}',
        '-o',str(path),str(ROOT/'src/rail_legacy_8mm.scad')],check=True,
        stdout=subprocess.DEVNULL)
    return path


def ray_positions(mesh,origin,direction,axis,lo,hi):
    points,_,_=mesh.ray.intersects_location([origin],[direction])
    values=np.unique(np.round(points[:,axis],5))
    return values[(values>=lo)&(values<=hi)]


def fit_checks():
    new,new_solid=load(OUT/'stl/slider_hook.stl')
    rail,rail_solid=load(OUT/'stl/rail.stl')
    old_path=ROOT/'output/print-12-v1/source/slider_hook.stl'
    old,old_solid=load(old_path)
    legacy,legacy_solid=load(OUT/'legacy-rail-8mm-front-300.stl')
    # X=2 avoids the root fairing: measure the straight functional slot,
    # not a center slice through an intentionally protruding glue fillet.
    gap=ray_positions(new,[2,-100,5.5],[0,1,0],1,-1.31,13.31)
    old_gap=ray_positions(old,[2,-100,5.3],[0,1,0],1,.99,11.01)
    rail_z=ray_positions(rail,[9,3,-10],[0,0,1],2,-.01,6.01)
    legacy_z=ray_positions(legacy,[9,3,-10],[0,0,1],2,-.01,5.81)
    # Rounded outer boxes are tessellated (max 0.006 mm chord inset).
    # Functional flat cavity faces must retain the strict 0.00002-mm check.
    assert len(gap)==4 and np.allclose(gap[1:3],[-.3,12.3],atol=2e-5),gap
    assert np.allclose(gap[[0,3]],[-1.3,13.3],atol=.006),gap
    assert len(old_gap)==4 and np.allclose(old_gap[1:3],[1.7,10.3],atol=2e-5),old_gap
    assert np.allclose(old_gap[[0,3]],[1,11],atol=.006),old_gap
    assert np.allclose(rail_z,[0,1,5,6],atol=2e-5),rail_z
    assert np.allclose(legacy_z,[0,1,4.8,5.8],atol=2e-5),legacy_z
    positions=[-18,-12,-1,0,1,50,110,141,282,294,300]
    new_collisions={x:(new_solid.translate((x,0,0))^rail_solid).volume() for x in positions}
    old_collisions={x:(old_solid.translate((x,0,0))^legacy_solid).volume() for x in positions}
    assert all(abs(v)<1e-6 for v in [*new_collisions.values(),*old_collisions.values()])
    wrong=(old_solid^rail_solid).volume()
    assert wrong>1,wrong  # Regression: v1 is NOT a 12-mm-wing hook.
    # Check that the hand-contact J geometry was only translated, not scaled.
    translated=old_solid.translate((0,-2.3,0))
    region=mf.Manifold.cube((30,100,30)).translate((-5,-102.1,-2))
    outside=(new_solid-translated)+(translated-new_solid)
    free_hook_difference=(outside^region).volume()
    assert free_hook_difference<.005,free_hook_difference
    result={'units':'mm','new_fit':FIT,
        'new_cavity_ray_y_mm':gap.tolist(),'old_cavity_ray_y_mm':old_gap.tolist(),
        'new_rail_ray_z_mm':rail_z.tolist(),'legacy_rail_ray_z_mm':legacy_z.tolist(),
        'new_hook_clear_height_mm':float(gap[2]-gap[1]),
        'old_hook_clear_height_mm':float(old_gap[2]-old_gap[1]),
        'new_hook_new_rail_intersection_mm3':new_collisions,
        'old_hook_legacy_rail_intersection_mm3':old_collisions,
        'old_hook_new_rail_negative_control_mm3':wrong,
        'unchanged_free_hook_shape_difference_mm3':free_hook_difference,
        'old_hook_sha256':hashlib.sha256(old_path.read_bytes()).hexdigest(),
        'legacy_rail':{'back_height_mm':12,'front_height_mm':8,
            'outside_mm':5.8,'inside_mm':3.8,'wall_mm':1,'web_mm':1},
        'physical_fit_and_load_test':'pending'}
    plate.write_json(OUT/'fit-validation.json',result)
    print('PASS: measured 12.6 / old 8.6 mm cavities; both correct rail pairs fit.',flush=True)


def hook_plate(count):
    folder=OUT/('new-hooks-12' if count==12 else 'new-hook-test-1')
    (folder/'source').mkdir(parents=True,exist_ok=True)
    source=folder/'source/slider_hook.stl'
    shutil.copy2(OUT/'stl/slider_hook.stl',source)
    plate.write_json(folder/'source/identity.json',{
        'source_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
        'uncommitted_cad_revision':True,
        'sources':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest()
                   for p in sorted((ROOT/'src').glob('*.scad'))},
        'stl_sha256':hashlib.sha256(source.read_bytes()).hexdigest()})
    # Preserve the successfully printed v1 material/process rather than changing
    # printer, hardness validation or material while fixing a dimensional error.
    for name in ('machine','filament','process'):
        data=json.loads((ROOT/'output/print-12-v1/config'/f'{name}.json').read_text())
        plate.write_json(folder/'config'/f'{name}.json',data)
    plate.write_json(folder/'fit-contract.json',FIT)
    plate.poses(folder,names=['side'])
    arranged=plate.model_plate(folder,'side',count)
    name=f'hook-H12x6-v2-{count}pcs-PETG-X1C-0p4-0p12.3mf'
    result=plate.slice_file(folder,arranged,folder,filename=name,arrange=False)
    reopen(result,folder)
    verify_plate(folder)
    return result


def reopen(path,folder):
    with (folder/'reopen-native.log').open('w') as log:
        subprocess.run([plate.STUDIO,'--info',str(path)],check=True,
                       stdout=log,stderr=subprocess.STDOUT)


def legacy_plate(length):
    folder=OUT/f'legacy-rail-{length}-print'
    folder.mkdir(parents=True,exist_ok=True)
    mesh=trimesh.load_mesh(OUT/f'legacy-rail-8mm-front-{length}.stl')
    # The descending diagonal avoids the X1C front-left exclusion rectangle;
    # the ascending (+45) diagonal puts one end too close to that rectangle.
    # Stand on the 12-mm rear wing's long edge: the functional Z faces become
    # vertical and the 8-mm front wing needs support only under its lower edge.
    transform=trimesh.transformations.euler_matrix(np.pi/2,0,-np.pi/4)
    mesh.apply_transform(transform)
    mesh.apply_translation([128-mesh.centroid[0],128-mesh.centroid[1],-mesh.bounds[0,2]])
    assert np.all(mesh.bounds[0]>=[7,7,0]) and np.all(mesh.bounds[1]<=[249,249,256])
    input_file=folder/'rail-diagonal.stl';mesh.export(input_file)
    for kind in ('machine','filament','process'):
        data=json.loads((ROOT/'output/print-12-v1/config'/f'{kind}.json').read_text())
        if kind=='process':
            data.update({'layer_height':'.20','support_top_z_distance':'.24',
                         'support_bottom_z_distance':'.24','brim_width':'3'})
        plate.write_json(folder/'config'/f'{kind}.json',data)
    target=plate.slice_file(folder,input_file,folder,
        filename=f'legacy-8mm-rail-{length}-PETG-X1C-0p4-0p20.3mf',arrange=False)
    actual=instances(target)
    assert len(actual)==1
    exported=actual[0][0]
    assert exported.is_watertight and np.all(exported.nondegenerate_faces())
    assert abs(exported.volume/mesh.volume-1)<1e-5
    assert np.allclose(exported.extents,mesh.extents,atol=1e-4)
    assert np.all(exported.bounds[0]>=[7,7,-1e-4]) and np.all(exported.bounds[1]<=[249,249,256])
    stats,_,_=statistics(target)
    assert not stats['warnings'],stats['warnings']
    assert stats['support_g']>0, 'Suspended 8-mm front wing requires actual support.'
    reopen(target,folder)
    log=(folder/'reopen-native.log').read_text()
    assert 'manifold = yes' in log and 'number_of_parts =  1' in log
    assert 'manifold = no' not in log and 'open_edges' not in log
    plate.write_json(folder/'plate-validation.json',{
        'kind':'sliced-project','part_id':'legacy_rail_8mm_front','count':1,
        'length_mm':length,'print_rotation_x_deg':90,'print_rotation_z_deg':-45,
        'bounds_mm':exported.bounds.tolist(),'no_scaling':True,'statistics':stats,
        'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),
        'support_contact':'lower narrow edge of front wing; functional Z faces printed vertically; clean edge before test',
        'physical_fit_and_load_test':'pending','sent_to_printer':False})
    return target


def review_legacy_support(length):
    folder=OUT/f'legacy-rail-{length}-print'
    path=folder/f'legacy-8mm-rail-{length}-PETG-X1C-0p4-0p20.3mf'
    stats,settings,segments=statistics(path)
    mesh=instances(path)[0][0]
    source=trimesh.load_mesh(OUT/f'legacy-rail-8mm-front-{length}.stl')
    transform=trimesh.transformations.euler_matrix(np.pi/2,0,-np.pi/4)
    expected=source.copy();expected.apply_transform(transform)
    shift=np.array([128-expected.centroid[0],128-expected.centroid[1],-expected.bounds[0,2]])
    transform[:3,3]=shift
    samples=np.array([s for role in ('Support','Support interface')
                      for s in segments.get(role,[])])
    assert len(samples)>0
    points=np.concatenate([samples[:,:3],samples[:,3:6],
                           (samples[:,:3]+samples[:,3:6])/2])
    points[:,:2]+=[float(v) for v in settings['extruder_offset'][0].split('x')]
    near,distance,faces=trimesh.proximity.closest_point(mesh,points)
    keep=(distance<.55)&(mesh.face_normals[faces,2]<-.2)
    original=trimesh.transform_points(near[keep],np.linalg.inv(transform))
    normals=mesh.face_normals[faces[keep]]@transform[:3,:3]
    assert len(original)>0,'No real support contact found under the suspended wing.'
    functional=np.abs(normals[:,2])>.8
    assert not np.any(functional),'Support contact on a functional Z sliding face.'
    data=json.loads((folder/'plate-validation.json').read_text())
    assert data['sha256']==hashlib.sha256(path.read_bytes()).hexdigest()
    data['support_contact_check']={'sample_count':len(points),
        'near_downward_surface_samples':len(original),
        'functional_z_face_samples':int(np.count_nonzero(functional)),
        'contact_original_bounds_mm':[original.min(axis=0).tolist(),original.max(axis=0).tolist()],
        'method':'actual Support + Support interface G-code including arcs; endpoints and midpoints; .55-mm surface threshold'}
    plate.write_json(folder/'plate-validation.json',data)


def package_delivery():
    destination=OUT/'delivery'
    destination.mkdir(parents=True,exist_ok=True)
    files=[(OUT/'stl/slider_hook.stl','new-hook-H12x6-clear12p6-v2.stl'),
        (OUT/'legacy-rail-8mm-front-300.stl','legacy-hooks-rail-front8-back12-L300-v2.stl'),
        (OUT/'legacy-rail-8mm-front-50.stl','legacy-hooks-rail-front8-back12-L50-test-v2.stl')]
    for folder in ('new-hooks-12','new-hook-test-1'):
        files.extend((p,p.name) for p in (OUT/folder).glob('hook-H12x6-v2-*-PETG-X1C-0p4-0p12.3mf'))
    for length in (50,300):
        review_legacy_support(length)
        p=OUT/f'legacy-rail-{length}-print'/f'legacy-8mm-rail-{length}-PETG-X1C-0p4-0p20.3mf'
        files.append((p,p.name))
    manifest={'kind':'two-part-families-print-package','units':'mm',
        'print_families':['new_hook_H12x6','rail_for_already_printed_v1_hooks'],
        'no_new_12mm_rail_in_print_list':True,'sent_to_printer':False,'files':[]}
    for source,name in files:
        target=destination/name;shutil.copy2(source,target)
        manifest['files'].append({'file':name,'source':str(source.relative_to(OUT)),
            'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),
            'kind':'sliced-project' if target.suffix=='.3mf' else 'mesh'})
    plate.write_json(destination/'manifest.json',manifest)
    print('DELIVERY:',destination,flush=True)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action',choices=['fit','print','package'])
    args=parser.parse_args()
    if args.action!='package':
        for length in (50,300):export_legacy(length)
        fit_checks()
    if args.action=='print':
        with ThreadPoolExecutor(max_workers=2) as pool:
            for p in pool.map(hook_plate,[1,12]):print(p,flush=True)
            for p in pool.map(legacy_plate,[50,300]):print(p,flush=True)
    if args.action in ('print','package'):package_delivery()
