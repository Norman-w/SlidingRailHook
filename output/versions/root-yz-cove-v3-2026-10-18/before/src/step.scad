include <parameters.scad>

// Active printable step/carriage.  The legacy hook profile remains in
// hook.scad for recovery, but is intentionally not referenced here.

module rounded_box(size_xyz, radius) {
    assert(radius < min(size_xyz[0], min(size_xyz[1], size_xyz[2])) / 2);
    translate([radius, radius, radius])
    minkowski() {
        cube([
            size_xyz[0] - 2 * radius,
            size_xyz[1] - 2 * radius,
            size_xyz[2] - 2 * radius
        ]);
        sphere(r=radius, $fn=24);
    }
}

module step_carriage() {
    // Rounded open-bottom collar: the cavity is the rail-facing opening and
    // remains dimensioned by the shared 0.30 mm slide-clearance contract.
    difference() {
        translate([0, hook_outer_y0, hook_outer_z0])
            rounded_box([
                hook_carriage_length,
                hook_outer_y1 - hook_outer_y0,
                hook_outer_z1 - hook_outer_z0
            ], hook_carriage_corner_radius);
        translate([-join_overlap, hook_inner_y0, hook_inner_z0])
            cube([hook_carriage_length + 2 * join_overlap,
                  hook_inner_y1 - hook_inner_y0,
                  hook_inner_z1 - hook_inner_z0]);
    }
}

module step_capture_lip(y0, y1) {
    translate([0, y0, hook_capture_lip_bottom_z])
        rounded_box(
            [hook_carriage_length,
             y1 - y0,
             hook_capture_lip_top_z - hook_capture_lip_bottom_z],
            hook_capture_lip_radius
        );
}

module step_capture_lips() {
    step_capture_lip(hook_capture_left_y0, hook_capture_left_y1);
    step_capture_lip(hook_capture_right_y0, hook_capture_right_y1);
}

module step_geometry() {
    union() {
        step_carriage();
        step_capture_lips();
    }
}

module step_section_preview(section_x=4) {
    intersection() {
        step_geometry();
        translate([-section_x / 2, -1, -1])
            cube([section_x, rail_height + 2, rail_depth_target + 2]);
    }
}

if (debug_section)
    step_section_preview();
else
    step_geometry();
