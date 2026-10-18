include <parameters.scad>

// Active straight trapezoid hook plate. It is a separate part that overlaps
// the step's outer side wall; the assembly places it beside step_geometry().

module hook_trapezoid_plate() {
    translate([hook_carriage_length / 2, hook_trapezoid_root_y, hook_trapezoid_z0])
        linear_extrude(height=hook_trapezoid_plate_thickness_z)
            polygon(points=[
                [-hook_trapezoid_root_width_x / 2, 0],
                [ hook_trapezoid_root_width_x / 2, 0],
                [ hook_trapezoid_tail_width_x / 2, -hook_trapezoid_length],
                [-hook_trapezoid_tail_width_x / 2, -hook_trapezoid_length]
            ]);
}

module hook_trapezoid_geometry() {
    hook_trapezoid_plate();
}

module hook_trapezoid_section_preview(section_x=3) {
    intersection() {
        hook_trapezoid_geometry();
        translate([hook_carriage_length / 2 - section_x / 2,
                   hook_trapezoid_tail_y - 1,
                   hook_trapezoid_z0 - 1])
            cube([section_x, hook_trapezoid_length + 2,
                  hook_trapezoid_plate_thickness_z + 2]);
    }
}

if (debug_section)
    hook_trapezoid_section_preview();
else
    hook_trapezoid_geometry();
