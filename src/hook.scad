include <parameters.scad>

module rounded_box(size, radius) {
    // Exact outer bounds are preserved by shrinking the core before the
    // spherical Minkowski round. This rounds carriage edges without changing
    // the rail-facing cavity or its X travel envelope.
    assert(radius < min(size[0], min(size[1], size[2])) / 2);
    translate([radius, radius, radius])
        minkowski() {
            cube([size[0] - 2 * radius,
                  size[1] - 2 * radius,
                  size[2] - 2 * radius]);
            sphere(r=radius, $fn=32);
        }
}

module hook_carriage() {
    // Rounded open-bottom collar: side rails and top cap retain the rail
    // flange while the unchanged rectangular cavity clears the flange and
    // central web with the original sliding clearance.
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

module hook_capture_lip(y0, y1) {
    // Door-side support under the flange. Each lip overlaps the carriage
    // side wall and ends before the web relief slot, so it cannot float or
    // intersect the rail web during X insertion.
    translate([0, y0, hook_capture_lip_bottom_z])
        rounded_box([
            hook_carriage_length,
            y1 - y0,
            hook_capture_lip_top_z - hook_capture_lip_bottom_z
        ], hook_capture_lip_radius);
}

module hook_capture_lips() {
    union() {
        hook_capture_lip(hook_capture_left_y0, hook_capture_left_y1);
        hook_capture_lip(hook_capture_right_y0, hook_capture_right_y1);
    }
}

module hook_root_bridge() {
    // Explicit Y-Z side silhouette with rounded 3D edges. The profile extends
    // 2.20 mm into the lower-lip load band and surrounds the fairing/stem top,
    // so both side edges are a real bridge rather than a tangent contact.
    translate([hook_carriage_length / 2 - hook_root_bridge_width_x / 2, 0, 0])
        multmatrix([
            [0, 0, 1, 0],
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 0, 1]
        ])
            translate([0, 0, hook_root_bridge_edge_radius])
                minkowski() {
                    linear_extrude(
                        height=hook_root_bridge_width_x - 2 * hook_root_bridge_edge_radius
                    )
                        polygon(points=hook_root_bridge_profile);
                    sphere(r=hook_root_bridge_edge_radius, $fn=24);
                }
}

module hook_profile() {
    // J-shaped 3D sweep. Each station is an ellipsoid with its own Y-Z
    // radius and X width; hull() between adjacent stations gives a gradual,
    // continuous taper from the load-bearing mount to the rounded tip.
    rounded_centerline_3d(
        hook_centerline,
        hook_profile_radii,
        hook_profile_widths
    );
}

module profile_station_3d(point, radius, width) {
    translate([hook_carriage_length / 2, point[0], point[1]])
        scale([width / 2, radius, radius])
            sphere(r=1, $fn=32);
}

module rounded_centerline_3d(points, radii, widths) {
    for (i = [0 : len(points) - 2]) {
        hull() {
            profile_station_3d(points[i], radii[i], widths[i]);
            profile_station_3d(points[i + 1], radii[i + 1], widths[i + 1]);
        }
    }
}

module hook_geometry() {
    union() {
        hook_carriage();
        hook_capture_lips();
        hook_root_bridge();
        hook_profile();
    }
}

module hook_root_connection_preview() {
    // Diagnostic-only close-up: distinct colors make the positive-volume
    // overlap between the bridge shoulder, lower lip, carriage, and fairing
    // visible without changing the printable default geometry.
    intersection() {
        union() {
            color([0.35, 0.55, 0.80, 0.72]) hook_carriage();
            color([0.95, 0.65, 0.12, 0.90]) hook_capture_lips();
            color([0.95, 0.20, 0.08, 1.00]) hook_root_bridge();
            color([0.98, 0.82, 0.18, 1.00]) hook_profile();
        }
        translate([-1, -1.5, 2.5])
            cube([hook_carriage_length + 2, 4.8, 2.8]);
    }
}

module hook_section_preview(section_x=4) {
    intersection() {
        hook_geometry();
        translate([hook_carriage_length / 2 - section_x / 2, -18, 0])
            cube([section_x, 22, 12]);
    }
}

if (debug_section)
    hook_section_preview();
else if (debug_root_connection)
    hook_root_connection_preview();
else
    hook_geometry();
