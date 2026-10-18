# SlidingRailHook validation summary

Updated on 2026-10-18 from the active SCAD sources in `/Users/norman/CodeXProjects/SlidingRailHook/src`.

## Active export status

OpenSCAD was run from `/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD`. The active export contains exactly five printable STL files: rail, step, the 240-degree rounded bent hook, and the two end stops. The legacy J-hook, previous flat trapezoid, previous unrounded 240-degree bent hook, and previous 300-degree bent hook are archived and are not referenced by active assembly or export output.

## Active STL measurements

| Part | STL path | Bounding box (X × Y × Z mm) | Volume (mm³) | Surface area (mm²) | Topology |
|---|---|---:|---:|---:|---|
| Rail | `output/3d-print/rail.stl` | 300.0 × 12.0 × 5.8 | 7248.000 | 14928.320 | watertight, manifold; no degenerate/boundary/non-manifold edges |
| Step/carriage | `output/3d-print/step.stl` | 17.997 × 9.997 × 5.790 | 358.832 | 1001.984 | watertight, manifold; no degenerate/boundary/non-manifold edges |
| Rounded bent hook R5 + left/right root fillets | `output/3d-print/hook_bent.stl` | 11.294 × 18.513 × 13.000 | 657.289 | 663.820 | watertight, one connected shell; no degenerate/boundary/non-manifold edges |
| Left end stop | `output/3d-print/end_stop_left.stl` | 8.0 × 10.6 × 4.3 | 194.120 | 458.360 | watertight, manifold; no degenerate/boundary/non-manifold edges |
| Right end stop | `output/3d-print/end_stop_right.stl` | 8.0 × 10.6 × 4.3 | 194.120 | 458.360 | watertight, manifold; no degenerate/boundary/non-manifold edges |

The detailed raw reports are `rail-inspect.txt`, `step-inspect.txt`, `hook_bent-inspect.txt`, `end_stop_left-inspect.txt`, and `end_stop_right-inspect.txt` in this directory. Each was generated with `inspect_stl.py --require-watertight`.

## Bent-hook contract

`src/hook_bent.scad` replaces the previous flat 9×20×3 plate in the active assembly. The X width remains continuously tapered from `9.00 mm` at the root to `4.50 mm` at the tail. The current 20 mm reference length is split according to the “bend begins at 3/5 from the root” assumption: the root-to-bend straight segment is `20×3/5 = 12.00 mm`.

From that point, the centerline follows a `240°` circular arc in the existing Y-Z hook plane with centerline radius `5.00 mm`. With a `3.00 mm` solid thickness, the nominal inner/outer radii are `3.50 / 6.50 mm`. The arc is sampled into stable hull segments and the exposed cross-section is rounded with `hook_visible_edge_radius=0.75 mm`; the free end retains its `1.50 mm` ellipsoidal cap. The previous X-end sphere-cap edit has been reverted: the upper quarter-cylinder bead is restored, and TWO separate `R1.25 mm` concave side coves now fill the left/right hook-to-base corners in the XY plane. Their profiles are tangent to the tapered hook sides and the base face. Z ends roll back over `0.15 mm`, and the middle profile overlaps both parent solids by a deliberate `join_overlap`. Hook-body root/tail widths remain `9.00/4.50 mm`; the added side coves enlarge the hook STL's X envelope to `11.294 mm`.

`src/root_joint_check.scad` verifies the connection independently. Each side cove intersects the base by `0.053029 mm³` and the original hook weld region by `0.075557 mm³`. The final hook STL and the union of hook + step each have exactly ONE connected closed shell. The union volume is `1007.352274 mm³`. The exact rail/hook Boolean intersection is empty, so these additions do not intrude into the rail's X sliding envelope. The active STL has 7218 triangles, 3611 vertices, Genus 0 and zero degenerate, boundary, non-manifold or inconsistent-orientation edges. Both Manifold and CGAL exports succeed; CGAL reports `Simple: yes`. This is a geometry check, not an empirical load test.

The root center remains at `y=1.30`, `z=3.20`, so the root cross-section is `z=1.70..4.70` and overlaps the step outer wall by `0.30 mm` in Y. The first `2.00 mm` of path is a full rectangular weld zone; the following `2.00 mm` is a continuous radius ramp to `0.75 mm`. The +Z bond fillet is centered just inside the base/root corner with `bond_fillet_radius=1.25 mm`, spans the full `9.00 mm` root width, and its maximum Y remains below both `rail_flange_y0` and `hook_inner_y0`; it therefore stays outside the H-slot sliding envelope. The rail flange begins at `y=2.00`, `z=4.80`; the root top therefore retains `0.10 mm` vertical clearance. The bent path leaves the rail toward negative Y, then remains on the `+Z` person-facing side. Source assertions enforce positive radius (`5.00 > 3.00/2`), `240° < 360°`, `+Z` arc side, tangent/center placement, weld/transition placement, edge-radius clearance, `1.50 mm` end-cap placement, `1.25 mm` bond-fillet radius, root placement, and flange/H-slot clearance. This is a static source/geometry check, not a physical strength or fit claim.

## Active previews

The active render set is in `output/renders/step-only/`:

- `step.png`
- `hook-bent.png`
- `hook-bent-side.png`
- `hook-bent-root-fillet.png`
- `root-left-right-plan.png`
- `hook-bent-section.png`
- `rail-step-bent-assembly-iso.png`
- `rail-step-bent-h-section.png`

The assembly H-section is generated from `src/assembly.scad -D assembly_section_debug=true`. The slice height now includes the full +Z hook. `-D assembly_root_debug=true` gives the assembly root crop; `-D assembly_root_plan_debug=true` gives an XY section at the hook root's mid-thickness and clearly shows both side coves.

The active preview manifest/API is `output/3d-preview/manifest.json`, titled `SlidingRailHook — R5 +Z + left/right root fillets`, with exactly five parts: `rail`, `step`, `hook_bent`, `end_stop_left`, and `end_stop_right`.

This correction's before/after sources, STL, renders and diagnostic results are retained under `output/versions/root-side-fillets-v2-2026-10-18/`. The before snapshot contains the rejected X-end caps; the after snapshot contains the corrected left/right joints.

## Recoverable history

The legacy J-hook source remains at `src/hook.scad`; its prior STL meshes remain under `output/3d-print/history/`. The replaced flat 9×20×3 STL is preserved at `output/3d-print/history/hook_trapezoid-flat-9x20x3-pre-bend-2026-10-18.stl`; its source remains at `src/hook_trapezoid.scad`. The replaced unrounded 240° bent STL is preserved at `output/3d-print/history/hook_bent-240deg-unrounded-pre-edge-round-2026-10-18.stl`, with its renders under `output/renders/history-hook-bent-240deg-unrounded-2026-10-18/`. The replaced 0.75 mm end-cap STL is preserved at `output/3d-print/history/hook_bent-240deg-rounded-0p75-endcap-pre-full-round-2026-10-18.stl`, with its renders under `output/renders/history-hook-bent-240deg-rounded-0p75-endcap-2026-10-18/`. The replaced 240°/R3 rounded bent STL is preserved at `output/3d-print/history/hook_bent-240deg-R3-rounded-endcap1p5-pre-R5-2026-10-18.stl`, with its renders under `output/renders/history-hook-bent-240deg-R3-rounded-endcap1p5-2026-10-18/`. The replaced reverse-`Z` 240°/R5 rounded bent STL is preserved at `output/3d-print/history/hook_bent-240deg-R5-negative-Z-pre-positive-Z-2026-10-18.stl`, with its renders under `output/renders/history-hook-bent-240deg-R5-negative-Z-2026-10-18/`. The replaced positive-`Z` no-bond-fillet 240°/R5 rounded bent STL is preserved at `output/3d-print/history/hook_bent-240deg-R5-positive-Z-pre-bond-fillet-2026-10-18.stl`, with its renders under `output/renders/history-hook-bent-240deg-R5-positive-Z-no-bond-fillet-2026-10-18/`. The replaced 300° bent STL is preserved at `output/3d-print/history/hook_bent-300deg-pre-240deg-2026-10-18.stl`. The replaced renders are retained under `output/renders/history-hook-trapezoid-flat-2026-10-18/` and `output/renders/history-hook-bent-300deg-2026-10-18/`. None of these historical artifacts are active manifest/API parts.

## Remaining physical checks

- Print at 1:1 scale and confirm the nominal `0.30 mm` sliding clearance on the actual printer/material.
- Confirm step insertion from the rail end, full travel, end-stop seating, and the bent hook's root and re-hook clearance.
- Validate supports, wall count, layer height, first-layer adhesion, and material in the slicer.
- Do not infer a load rating, physical fit, or long-term durability from the static render or watertight STL report.
