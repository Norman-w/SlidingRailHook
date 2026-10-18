include <parameters.scad>
use <rail.scad>
use <step.scad>
use <hook_bent.scad>
use <end_stop.scad>

module assembly_section_slice() {
    // Debug-only X slice at the step. The camera must be centered at
    // assembly_step_x because the slice is translated along the rail axis.
    // Keep the rail opaque and the step/bent hook translucent so the H
    // retention relationship and the bent external hook remain visible.
    color([0.45, 0.58, 0.78, 1.0])
        intersection() {
            rail_geometry();
            translate([assembly_step_x + assembly_section_local_x - assembly_section_x / 2,
                       -1, -1])
                cube([assembly_section_x, rail_height + 2, rail_depth_target + 2]);
        }
    translate([assembly_step_x, 0, 0])
        color([0.95, 0.45, 0.10, 0.58])
            intersection() {
                union() {
                    step_geometry();
                    hook_bent_geometry();
                }
                translate([assembly_section_local_x - assembly_section_x / 2,
                           -18, -1])
                    cube([assembly_section_x, 30,
                          hook_bent_root_z + 2 * hook_bent_centerline_radius +
                          hook_bent_plate_thickness_z / 2 + 2]);
            }
}

module assembly_root_view(plan=false) {
    if (plan)
        projection(cut=false)
            intersection() {
                union() {
                    step_geometry();
                    hook_bent_geometry();
                }
                translate([0, -3, hook_bent_root_z - 0.01])
                    cube([hook_carriage_length, 7, 0.02]);
            }
    else {
        color([0.95, 0.55, 0.15])
            intersection() {
                step_geometry();
                translate([0, -3, -1])
                    cube([hook_carriage_length, 8, 10]);
            }
        color([0.95, 0.32, 0.08])
            intersection() {
                hook_bent_geometry();
                translate([0, -3, -1])
                    cube([hook_carriage_length, 8, 10]);
            }
    }
}

// Preview only: no transparent/debug modifier is part of the printable files.
if (assembly_root_plan_debug)
    assembly_root_view(plan=true);
else if (assembly_root_debug)
    assembly_root_view();
else if (assembly_section_debug)
    assembly_section_slice();
else {
    if (show_assembly_rail)
        color([0.65, 0.70, 0.75, 0.42]) rail_geometry();

    translate([assembly_step_x, 0, 0])
        color([0.95, 0.55, 0.15, 1.0]) step_geometry();

    translate([assembly_step_x, 0, 0])
        color([0.95, 0.32, 0.08, 1.0]) hook_bent_geometry();

    if (show_assembly_end_stops) {
        color([0.15, 0.55, 0.90, 1.0]) end_stop_geometry("left");
        translate([rail_length, 0, 0])
            color([0.15, 0.55, 0.90, 1.0]) end_stop_geometry("right");
    }
}
