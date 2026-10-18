#!/usr/bin/env python3
"""Independent top/iso plots from actual sliced extrusion moves (not GUI captures)."""
import argparse
from pathlib import Path

import numpy as np

from inspect_hook_plate import instances, statistics


def preview(folder):
    source=folder/'hook-12-PETG-X1C-0p4-0p12.3mf'
    _,settings,roles=statistics(source)
    meshes=instances(source)
    bounds=np.array([m.bounds for m,_ in meshes])
    low=bounds[:,0,:2].min(axis=0)-6
    high=bounds[:,1,:2].max(axis=0)+6
    offset=np.array([float(v) for v in settings['extruder_offset'][0].split('x')])
    colors={'Support':'#21a875','Support interface':'#c48a16','Brim':'#9aa5ab'}
    paths=[]
    for name,lines in roles.items():
        array=np.asarray(lines)[:,:6].reshape(-1,2,3)
        array[:,:,:2]+=offset
        paths.append((name,array))
    pieces=['<svg xmlns="http://www.w3.org/2000/svg" width="1400" height="830" viewBox="0 0 1400 830">',
            '<rect width="1400" height="830" fill="#f5f7f9"/>',
            '<g font-family="sans-serif" fill="#253b4b"><text x="35" y="35" font-size="23">12 hooks | PETG | 0.12 mm | actual extrusion toolpaths</text>',
            '<text x="35" y="65" font-size="15">Blue: part | Green: support | Gold: interface | Gray: brim. Independent plot, not a native slicer screenshot.</text></g>']
    def draw(lines,projection,scale,origin,color,width):
        p=lines@projection.T*scale+origin
        commands=['M%.2f %.2fL%.2f %.2f'%(*a,*b) for a,b in p]
        pieces.append('<path d="'+' '.join(commands)+'" fill="none" stroke="'+color+'" stroke-width="'+str(width)+'" stroke-linecap="round"/>')
    xy=np.array([[1,0,0],[0,-1,0]])
    scale=min(620/(high-low))
    origin=np.array([35-low[0]*scale,110+high[1]*scale])
    # First supports, then the part's contour paths, retaining all layers.
    ordered=sorted(paths,key=lambda p:0 if p[0] in colors else 1)
    for name,lines in ordered:
        draw(lines,xy,scale,origin,colors.get(name,'#39749b'),.65 if name in colors else .5)
    pieces.append('<g font-family="sans-serif" fill="#253b4b"><text x="35" y="795" font-size="18">Top: +X right, +Y up. One plate, 4 x 3 copies.</text></g>')
    # One rigid instance, isometric in printer XYZ coordinates.
    selected=int(np.argmin(bounds[:,0,0]+bounds[:,0,1]))
    box=bounds[selected];center=(box[0]+box[1])/2
    iso=np.array([[2**-.5,-2**-.5,0],[-6**-.5,-6**-.5,-(2/3)**.5]])
    scale=15.;origin=np.array([1050.,450.])
    for name,lines in ordered:
        keep=np.all(lines[:,:,0]>=box[0,0]-5,axis=1)&np.all(lines[:,:,0]<=box[1,0]+5,axis=1)
        keep &=np.all(lines[:,:,1]>=box[0,1]-5,axis=1)&np.all(lines[:,:,1]<=box[1,1]+5,axis=1)
        lines=lines[keep]-center
        draw(lines,iso,scale,origin,colors.get(name,'#39749b'),1.1 if name in colors else .8)
    for index,(label,color) in enumerate(zip('XYZ',('#d9534f','#339c63','#3979cf'))):
        a=np.array([920.,720.]);b=a+iso[:,index]*50
        pieces.append('<path d="M%g %gL%g %g" stroke="%s" stroke-width="3"/>'%(*a,*b,color))
        pieces.append('<text x="%g" y="%g" font-family="sans-serif" font-size="17" fill="%s">%s</text>'%(*(b+[5,-3]),color,label))
    pieces.append('<text x="800" y="795" font-family="sans-serif" fill="#253b4b" font-size="18">Isometric: one hook in its print orientation.</text></svg>')
    target=folder/'toolpaths-review.svg'
    target.write_text(''.join(pieces))
    print(target)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('folder',type=Path)
    preview(parser.parse_args().folder)
