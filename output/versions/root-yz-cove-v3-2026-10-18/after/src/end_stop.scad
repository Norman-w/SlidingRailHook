include <parameters.scad>

module end_stop_right_geometry() {
    union() {
        // Flange-only insertion sleeve. The cavity is open at local X=0,
        // allowing the rail end to enter; the solid back is the stop plate.
        difference() {
            translate([0, end_stop_outer_y0, end_stop_outer_z0])
                cube([end_stop_socket_length,
                      end_stop_outer_y1 - end_stop_outer_y0,
                      end_stop_outer_z1 - end_stop_outer_z0]);
            translate([-join_overlap, end_stop_inner_y0, end_stop_inner_z0])
                cube([end_stop_socket_length - end_stop_plate_thickness
                          + join_overlap,
                      end_stop_inner_y1 - end_stop_inner_y0,
                      end_stop_inner_z1 - end_stop_inner_z0]);
        }

        // Person-facing stop lip. It does not descend to the mounting plane.
        translate([end_stop_socket_length - end_stop_plate_thickness,
                   end_stop_outer_y0, end_stop_outer_z0])
            cube([end_stop_plate_thickness,
                  end_stop_outer_y1 - end_stop_outer_y0,
                  end_stop_lip_z1 - end_stop_outer_z0]);
    }
}

module end_stop_geometry(side="right") {
    if (side == "left")
        mirror([1, 0, 0]) end_stop_right_geometry();
    else
        end_stop_right_geometry();
}

// Standalone printable selector. CLI override examples are in README.md.
if (end_stop_part == "left")
    end_stop_geometry("left");
else if (end_stop_part == "right")
    end_stop_geometry("right");
else {
    end_stop_geometry("left");
    translate([rail_length, 0, 0]) end_stop_geometry("right");
}
