include <parameters.scad>

module rail_geometry() {
    union() {
        // Cabinet mounting base; its rear face is exactly Z=0.
        cube([rail_length, rail_height, wall_thickness + join_overlap]);

        // Central web. It overlaps the base and flange by join_overlap.
        translate([0, rail_web_y0, rail_web_z0])
            cube([rail_length, wall_thickness, rail_web_z1 - rail_web_z0]);

        // Person-facing load flange.
        translate([0, rail_flange_y0, rail_flange_z0 - join_overlap])
            cube([rail_length, rail_flange_y1 - rail_flange_y0,
                  rail_flange_z1 - rail_flange_z0 + join_overlap]);
    }
}

module rail_section_preview(section_x=20) {
    intersection() {
        rail_geometry();
        translate([rail_length / 2 - section_x / 2, -1, -1])
            cube([section_x, rail_height + 2, rail_depth_target + 2]);
    }
}

// Standalone printable entry point. debug_section is intentionally a source
// inspection mode, not a modifier on the final print geometry.
if (debug_section)
    rail_section_preview();
else
    rail_geometry();
