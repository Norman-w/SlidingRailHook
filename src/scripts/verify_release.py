#!/usr/bin/env python3
"""Check exported meshes, all four root corners and the rail sliding path.

Install requirements-qa.txt first. Does not invoke a printer or modify source.
"""
import argparse
import hashlib
import json
from pathlib import Path

import manifold3d as mf
import numpy as np
import trimesh


def load(path):
    mesh = trimesh.load_mesh(path, process=True)
    assert mesh.is_watertight, f"Open/non-manifold mesh: {path}"
    assert mesh.is_winding_consistent, f"Inconsistent winding: {path}"
    assert np.all(mesh.nondegenerate_faces()), f"Degenerate triangle: {path}"
    solid = mf.Manifold(mf.Mesh(
        np.asarray(mesh.vertices, dtype=np.float32),
        np.asarray(mesh.faces, dtype=np.uint32)))
    assert solid.status() == mf.Error.NoError, (path, solid.status())
    assert solid.volume() > 0, f"Non-positive volume: {path}"
    assert len(solid.decompose()) == 1, f"Disconnected solid/cavity: {path}"
    return mesh, solid


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verify(output, baseline):
    project = Path(__file__).resolve().parents[2]
    parts = {}
    solids = {}
    for name in ("rail", "slider_hook", "end_stop_left", "end_stop_right"):
        path = output / "stl" / f"{name}.stl"
        mesh, solid = load(path)
        solids[name] = solid
        parts[name] = {
            "path": f"stl/{name}.stl", "sha256": sha(path),
            "bounds_mm": mesh.bounds.tolist(), "size_mm": mesh.extents.tolist(),
            "volume_mm3": solid.volume(), "triangles": len(mesh.faces),
            "watertight": True, "winding_consistent": True,
            "connected_solids": 1, "degenerate_faces": 0,
        }
    assert np.allclose(parts["rail"]["size_mm"], [300, 12, 6], atol=1e-4)
    slider = solids["slider_hook"]
    # The rail is a constant-X extrusion: no hidden between-sample obstacle.
    positions = [0, 1, 5, 110, 141, 282]
    collisions = [(x, (slider.translate((x, 0, 0)) ^ solids["rail"]).volume())
                  for x in positions]
    assert all(abs(volume) < 1e-6 for _, volume in collisions), collisions
    _, step = load(output / "reports" / "step.stl")
    _, weld = load(output / "reports" / "weld.stl")
    corners = {}
    old = load(baseline)[1] if baseline else None
    for side in (-1, 1):
        _, side_cove = load(output / "reports" / f"side_{side}.stl")
        for z_side in (-1, 1):
            name = f"corner_{side}_{z_side}"
            _, corner = load(output / "reports" / f"{name}.stl")
            _, face_cove = load(output / "reports" / f"face_{z_side}.stl")
            overlaps = {label: (corner ^ parent).volume()
                        for label, parent in (("base", step), ("hook_weld", weld),
                                              ("side_cove", side_cove),
                                              ("face_cove", face_cove))}
            assert all(v > 1e-6 for v in overlaps.values()), (name, overlaps)
            missing = abs((corner - slider).volume())
            assert missing < 1e-6, (name, "corner not fully filled", missing)
            result = {"volume_mm3": corner.volume(), "overlap_mm3": overlaps,
                      "missing_from_final_mm3": missing}
            if old is not None:
                added = (corner - old).volume()
                assert added > 1e-5, (name, "no regression coverage", added)
                result["newly_filled_vs_v3_mm3"] = added
            corners[name] = result
    regression = None
    if old is not None:
        delta = (slider - old) + (old - slider)
        root_box = mf.Manifold.cube((12, 2.7, 5.08)).translate((3, -1, 1.02))
        outside = abs((delta - root_box).volume())
        # Native backends triangulate the unchanged sweeps differently; bound
        # that serialization noise rather than treating it as a design change.
        assert outside < 0.005, ("material changed outside root", outside)
        regression = {"baseline": "root-yz-cove-v3", "baseline_sha256": sha(baseline),
                      "outside_root_difference_mm3": outside,
                      "outside_root_tolerance_mm3": 0.005,
                      "added_mm3": (slider - old).volume(),
                      "removed_mm3": (old - slider).volume()}
    result = {
        "units": "mm", "parts": parts,
        "export_backend": "OpenSCAD CGAL",
        "independent_checks": "trimesh topology and manifold3d solid booleans",
        "sources": {str(p.relative_to(project)): sha(p)
                    for p in sorted((project / "src").rglob("*"))
                    if p.is_file() and "__pycache__" not in p.parts},
        "root_corners": corners,
        "rail_collision_volume_mm3": dict(collisions),
        "v3_regression": regression,
        "physical_fit_load_and_slicing": "not tested",
    }
    (output / "reports" / "validation.json").write_text(
        json.dumps(result, indent=2) + "\n")
    print("PASS: four single closed print parts; four filled corners with positive")
    print("overlap into both parents and coves; no rail interference.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    parser.add_argument("--baseline", type=Path)
    args = parser.parse_args()
    verify(args.output.resolve(), args.baseline)
