# SlidingRailHook validation summary

Updated 2026-10-18. Current version: root-yz-cove-v3-2026-10-18; dimensions are mm.

## Correction

The +/-X side coves are unchanged. The previous +Z convex quarter-cylinder bead is replaced with a concave circular fillet; a matching concave fillet is added on -Z. Both use nominal R1.25. The +Z cove is tangent to the base flat face and hook top. The -Z cove is tangent to the base's actual R0.6 lower corner and hook underside. This avoids extending a hypothetical flat base through the mounting plate.

The lower cove reaches Z=1.294594595 mm, leaving 0.274594595 mm above the rail mounting plate's upper Z=1.02 mm. Its curved base contact reaches Y=1.177680594 mm, below the sliding cavity boundary Y=1.70 mm. Face-cove X span is 9 mm; the ends roll back over 0.15 mm. The existing 0.30 mm hook/base overlap and 2 mm weld zone remain.

The hook retains its 12 mm straight segment, 240-degree bend, R5 centerline, +Z bend direction, 9/4.5 mm body widths, 3 mm thickness, 0.75 mm exposed-edge radius and 1.5 mm free-end cap.

## Final STL

- Active part: output/3d-print/hook_bent.stl
- Bounding box: 11.294101 x 18.513018 x 13.405324 mm
- Volume: 650.406749 mm^3; area: 668.558322 mm^2
- 10526 triangles, 5265 vertices; one connected closed shell, genus 0
- Zero degenerate faces, boundary edges, non-manifold edges or inconsistent orientations
- Manifold: NoError. CGAL: Simple yes (successful independent export)

## Actual joint and clearance checks

src/root_joint_check.scad exports Boolean intersections to prove positive contact volumes rather than relying on rendering:

| Cove | Base overlap (mm^3) | Hook overlap (mm^3) |
|---|---:|---:|
| +Z | 0.168705210 | 0.225444785 |
| -Z | 0.062210964 | 0.139588181 |
| -X | 0.053029358 | 0.075557114 |
| +X | 0.053029358 | 0.075557114 |

The hook + step union is one connected closed shell, volume 1000.409327257 mm^3. The exact rail/hook Boolean intersection is EMPTY. The side-cove modules and their overlap measurements are unchanged from v2. Each diagnostic intersection and both isolated face fillets are watertight and have one connected shell.

## Files and renders

The active manifest/API has five parts: rail, step, hook_bent, end_stop_left, end_stop_right. Title: SlidingRailHook — R5 +Z + four concave root fillets. Only hook_bent geometry changed; the rail, step and stops remain unchanged.

Renders are in output/renders/step-only/: assembly-isometric-axes.png, rail-step-bent-assembly-iso.png, hook-bent-root-fillet.png, root-yz-section-axes.png, root-yz-isometric-axes.png, root-left-right-plan.png, root-left-right-iso.png, rail-step-bent-h-section.png, hook-bent.png, hook-bent-side.png and hook-bent-section.png.

Before/after sources, STL, renders and diagnostic meshes are archived under output/versions/root-yz-cove-v3-2026-10-18/. The previous v2 version remains under output/versions/root-side-fillets-v2-2026-10-18/. Older J-hook/flat/R3/reverse-Z history is unchanged in output/3d-print/history/.

These are source and geometry checks. Print slicing, physical sliding fit and load capacity remain untested.
