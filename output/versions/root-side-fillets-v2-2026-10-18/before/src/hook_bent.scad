include <parameters.scad>

// Parameterized bent hook. The path is a straight -Y segment followed by a
// Y-Z circular arc on the person-facing +Z side; X width tapers continuously
// from root to tip. The incoming arc tangent remains -Y. The root stays
// rectangular for the weld zone, then the exposed path uses a rounded swept
// section and a rounded free-end cap.

function hook_bent_path_point(s) =
    s <= hook_bent_straight_length
        ? [hook_bent_root_y - s, hook_bent_root_z]
        : let(
            arc_s = s - hook_bent_straight_length,
            theta = hook_bent_arc_start_angle +
                    hook_bent_arc_turn_sign *
                    arc_s / hook_bent_centerline_radius * 180 / PI
          )
          [
              hook_bent_arc_center_y +
                  hook_bent_centerline_radius * cos(theta),
              hook_bent_arc_center_z +
                  hook_bent_centerline_radius * sin(theta)
          ];

function hook_bent_path_tangent(s) =
    s <= hook_bent_straight_length
        ? [-1, 0]
        : let(
            arc_s = s - hook_bent_straight_length,
            theta = hook_bent_arc_start_angle +
                    hook_bent_arc_turn_sign *
                    arc_s / hook_bent_centerline_radius * 180 / PI
          )
          [
              hook_bent_arc_turn_sign * -sin(theta),
              hook_bent_arc_turn_sign * cos(theta)
          ];

function hook_bent_width(s) =
    hook_bent_root_width_x -
    (hook_bent_root_width_x - hook_bent_tail_width_x) *
    s / hook_bent_total_path_length;

function hook_bent_arc_points(cx, cy, radius, start_angle, end_angle, steps) =
    [for (i = [0 : steps])
        let (angle = start_angle + (end_angle - start_angle) * i / steps)
        [cx + radius * cos(angle), cy + radius * sin(angle)]];

function hook_bent_rounded_rect_points(width, thickness, corner_radius) =
    corner_radius <= 0.0001
        ? [[-width / 2, -thickness / 2],
           [ width / 2, -thickness / 2],
           [ width / 2,  thickness / 2],
           [-width / 2,  thickness / 2]]
        : concat(
            hook_bent_arc_points(
                width / 2 - corner_radius,
                thickness / 2 - corner_radius,
                corner_radius, 0, 90, 4),
            hook_bent_arc_points(
                -width / 2 + corner_radius,
                thickness / 2 - corner_radius,
                corner_radius, 90, 180, 4),
            hook_bent_arc_points(
                -width / 2 + corner_radius,
                -thickness / 2 + corner_radius,
                corner_radius, 180, 270, 4),
            hook_bent_arc_points(
                width / 2 - corner_radius,
                -thickness / 2 + corner_radius,
                corner_radius, 270, 360, 4)
          );

module hook_bent_section_prism(s, corner_radius, epsilon=0.04) {
    point = hook_bent_path_point(s);
    tangent = hook_bent_path_tangent(s);
    normal = [-tangent[1], tangent[0]];
    width = hook_bent_width(s);

    multmatrix([
        [1, 0, 0, hook_carriage_length / 2],
        [0, normal[0], tangent[0], point[0]],
        [0, normal[1], tangent[1], point[1]],
        [0, 0, 0, 1]
    ])
        linear_extrude(height=epsilon, center=true)
            polygon(points=hook_bent_rounded_rect_points(
                width,
                hook_bent_plate_thickness_z,
                corner_radius
            ));
}

module hook_bent_segment(s0, s1, r0, r1) {
    hull() {
        hook_bent_section_prism(s0, r0);
        hook_bent_section_prism(s1, r1);
    }
}

module hook_bent_end_cap() {
    cap_length = hook_bent_end_cap_length;
    cap_base_s = hook_bent_total_path_length - cap_length;
    end_point = hook_bent_path_point(hook_bent_total_path_length);
    tangent = hook_bent_path_tangent(hook_bent_total_path_length);
    normal = [-tangent[1], tangent[0]];
    // Place the ellipsoid pole exactly on the unchanged 240-degree endpoint
    // and orient it with the unchanged terminal tangent. The main sweep stops
    // before this cap, so no large planar endpoint survives the union.
    cap_center = [
        end_point[0] - tangent[0] * cap_length,
        end_point[1] - tangent[1] * cap_length
    ];

    // The ellipsoid is centered one radius behind the path endpoint. Its
    // forward pole closes the exposed end without extending the centerline.
    hull() {
        hook_bent_section_prism(cap_base_s, hook_visible_edge_radius);
        multmatrix([
            [1, 0, 0, hook_carriage_length / 2],
            [0, normal[0], tangent[0], cap_center[0]],
            [0, normal[1], tangent[1], cap_center[1]],
            [0, 0, 0, 1]
        ])
            scale([
                hook_bent_width(cap_base_s) / 2,
                hook_bent_plate_thickness_z / 2,
                cap_length
            ])
                sphere();
    }
}

module hook_bond_fillet() {
    x0 = hook_carriage_length / 2 - bond_fillet_width_x / 2;
    x1 = x0 + bond_fillet_width_x;
    x_left_cap = x0 + bond_fillet_radius;
    x_right_cap = x1 - bond_fillet_radius;

    // The middle is a quarter-cylinder in the exterior (+Z) quadrant. The
    // two same-radius quarter-sphere caps eliminate the X-end flat cuts while
    // keeping the total coverage exactly equal to the 9 mm root width.
    union() {
        intersection() {
            translate([x_left_cap, bond_fillet_center_y, bond_fillet_center_z])
                rotate([0, 90, 0])
                    cylinder(
                        r=bond_fillet_radius,
                        h=x_right_cap - x_left_cap,
                        center=false
                    );
            translate([
                x_left_cap,
                bond_fillet_center_y - bond_fillet_radius,
                bond_fillet_center_z
            ])
                cube([
                    x_right_cap - x_left_cap,
                    bond_fillet_radius,
                    bond_fillet_radius
                ]);
        }

        intersection() {
            translate([
                x_left_cap,
                bond_fillet_center_y,
                bond_fillet_center_z
            ])
                sphere(r=bond_fillet_radius);
            translate([
                x0,
                bond_fillet_center_y - bond_fillet_radius,
                bond_fillet_center_z
            ])
                cube([
                    bond_fillet_radius,
                    bond_fillet_radius,
                    bond_fillet_radius
                ]);
        }

        intersection() {
            translate([
                x_right_cap,
                bond_fillet_center_y,
                bond_fillet_center_z
            ])
                sphere(r=bond_fillet_radius);
            translate([
                x_right_cap,
                bond_fillet_center_y - bond_fillet_radius,
                bond_fillet_center_z
            ])
                cube([
                    bond_fillet_radius,
                    bond_fillet_radius,
                    bond_fillet_radius
                ]);
        }
    }
}

module hook_bent_geometry() {
    union() {
        // Full rectangular section retained as the monolithic weld/root zone.
        hook_bent_segment(
            0,
            hook_bent_weld_length,
            0,
            0
        );

        // Continuous radius ramp from the weld zone to the exposed rounded
        // section. There is no cut, gap, hinge, or zero-thickness neck here.
        for (i = [0 : 3])
            hook_bent_segment(
                hook_bent_weld_length +
                    hook_bent_round_transition_length * i / 4,
                hook_bent_weld_length +
                    hook_bent_round_transition_length * (i + 1) / 4,
                hook_visible_edge_radius * i / 4,
                hook_visible_edge_radius * (i + 1) / 4
            );

        // Rounded straight segment after the transition.
        for (i = [0 : hook_bent_straight_station_count - 2])
            hook_bent_segment(
                hook_bent_weld_length + hook_bent_round_transition_length +
                    (hook_bent_straight_length -
                     hook_bent_weld_length - hook_bent_round_transition_length) * i /
                    (hook_bent_straight_station_count - 1),
                hook_bent_weld_length + hook_bent_round_transition_length +
                    (hook_bent_straight_length -
                     hook_bent_weld_length - hook_bent_round_transition_length) * (i + 1) /
                    (hook_bent_straight_station_count - 1),
                hook_visible_edge_radius,
                hook_visible_edge_radius
            );

        for (i = [0 : hook_bent_arc_station_count - 2])
            hook_bent_segment(
                hook_bent_straight_length +
                    (hook_bent_arc_length - hook_bent_end_cap_length) * i /
                        (hook_bent_arc_station_count - 1),
                hook_bent_straight_length +
                    (hook_bent_arc_length - hook_bent_end_cap_length) * (i + 1) /
                        (hook_bent_arc_station_count - 1),
                hook_visible_edge_radius,
                hook_visible_edge_radius
            );

        hook_bond_fillet();
        hook_bent_end_cap();
    }
}

module hook_bent_section_preview(section_x=3) {
    intersection() {
        hook_bent_geometry();
        translate([
            hook_carriage_length / 2 - section_x / 2,
            hook_bent_arc_center_y - hook_bent_centerline_radius -
                hook_bent_plate_thickness_z - 1,
            hook_bent_arc_center_z - hook_bent_centerline_radius -
                hook_bent_plate_thickness_z - 1
        ])
            cube([
                section_x,
                hook_bent_centerline_radius * 2 +
                    hook_bent_plate_thickness_z * 2 + 2,
                hook_bent_centerline_radius * 2 +
                    hook_bent_plate_thickness_z * 2 + 2
            ]);
    }
}

module hook_bent_root_preview() {
    preview_x = bond_fillet_width_x + 2;

    intersection() {
        hook_bent_geometry();
        translate([
            hook_carriage_length / 2 - preview_x / 2,
            bond_fillet_center_y - bond_fillet_radius - 1,
            bond_fillet_center_z - bond_fillet_radius - 1
        ])
            cube([
                preview_x,
                bond_fillet_radius * 2 + 2,
                bond_fillet_radius * 2 + 2
            ]);
    }
}

if (debug_root_connection)
    hook_bent_root_preview();
else if (debug_section)
    hook_bent_section_preview();
else
    hook_bent_geometry();
