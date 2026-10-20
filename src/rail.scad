include <parameters.scad>

// Fixed H rail. Overlap is confined to the web ends; the two flange inner
// faces stay exactly at Z=wall and Z=depth-wall (4 mm apart for the new rail).
module rail_geometry(length=rail_length, height=rail_height,
                     depth=rail_depth_target, front_height=rail_front_height,
                     wall=wall_thickness, web=wall_thickness) {
    front_y0 = (height-front_height)/2;
    web_y0 = (height-web)/2;
    assert(length>0 && height>=front_height && front_height>web);
    assert(depth>2*wall && wall>join_overlap && web>0);
    union() {
        // Cabinet mounting base; its rear face is exactly Z=0.
        cube([length, height, wall]);

        // Central web. It overlaps the base and flange by join_overlap.
        translate([0, web_y0, wall-join_overlap])
            cube([length, web, depth-2*wall+2*join_overlap]);

        // Person-facing load flange.
        translate([0, front_y0, depth-wall])
            cube([length, front_height, wall]);
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
