// SlidingRailHook parameter source. Units: millimetres.
// Coordinate system: X=rail axis, Y=vertical rail height, Z=door normal.
// Door mounting face is Z=0; person-facing side is +Z; hook hangs toward -Y.

$fn = 64;
$fa = 5;
$fs = 0.25;

// Primary envelope.
rail_length = 300;
rail_height = 12;
wall_thickness = 1;          // Nominal base, web and person-side flange wall.
rail_depth_target = 5.8;     // Z extent; intentionally below the 6 mm target.
join_overlap = 0.02;         // CSG robustness only; not a nominal wall thickness.

// Rail cross-section: mounting base + central web + person-side flange.
rail_web_y0 = (rail_height - wall_thickness) / 2;
rail_web_y1 = rail_web_y0 + wall_thickness;
rail_flange_y0 = 2;
rail_flange_y1 = rail_height - 2;
rail_flange_z0 = rail_depth_target - wall_thickness;
rail_flange_z1 = rail_depth_target;
rail_web_z0 = wall_thickness - join_overlap;
rail_web_z1 = rail_flange_z0 + join_overlap;

// Sliding hook carriage.
slide_clearance = 0.30;      // Radial clearance around the flange/web envelope.
hook_carriage_length = 18;
hook_outer_y0 = rail_flange_y0 - wall_thickness;
hook_outer_y1 = rail_flange_y1 + wall_thickness;
hook_outer_z0 = wall_thickness + 0.10;
hook_outer_z1 = rail_depth_target + wall_thickness + 0.10;
hook_inner_y0 = rail_flange_y0 - slide_clearance;
hook_inner_y1 = rail_flange_y1 + slide_clearance;
hook_inner_z0 = hook_outer_z0 - join_overlap;
hook_inner_z1 = rail_depth_target + slide_clearance;
hook_shank_bottom_y = -16;
hook_tip_y = -11.5;
hook_tip_z = 8.4;
hook_carriage_corner_radius = 0.60;
// Hand-contact J-hook load path. A broad external fairing leaves the
// rail-facing cavity untouched, then closes gradually into the J stem.
hook_fairing_length = 10.00;
hook_root_bridge_overlap = 2.20;  // Positive Y overlap into the lower-lip load band.
hook_root_bridge_width_x = 13.60;
hook_root_bridge_edge_radius = 0.25;
hook_root_center_z = 3.35;       // Lowered to keep the enlarged root below the flange.
hook_stem_center_z = 3.90;
hook_root_radius = 1.25;
hook_root_transition_clearance = 0.10;
hook_fairing_root_width_x = 15.60;
hook_fairing_root_center_y = hook_outer_y0 - hook_root_radius + join_overlap;
hook_fairing_end_y = hook_fairing_root_center_y - hook_fairing_length;
hook_bend_radius = 0.92;
hook_profile_min_diameter = 1.40;
hook_tip_radius = hook_profile_min_diameter / 2;
hook_root_width_x = 5.20;
hook_bend_width_x = 4.00;
hook_tip_width_x = 3.20;
hook_tip_center_z = hook_tip_z - hook_tip_radius;

// Straight trapezoid hook plate. Width changes along X while the plate
// descends straight in -Y; there is no bend or J-hook tip in this revision.
hook_trapezoid_root_width_x = hook_carriage_length / 2;
hook_trapezoid_tail_width_x = hook_carriage_length / 4;
// The previous straight-stem span was 5.77 mm; this revision deliberately
// extends the same unbent plate to 20.00 mm.
hook_trapezoid_previous_straight_length = hook_fairing_end_y - hook_shank_bottom_y;
hook_trapezoid_length = 20.00;
hook_trapezoid_root_overlap_y = 0.30;
hook_trapezoid_root_y = hook_outer_y0 + hook_trapezoid_root_overlap_y;
hook_trapezoid_tail_y = hook_trapezoid_root_y - hook_trapezoid_length;
hook_trapezoid_plate_thickness_z = 3.00;
hook_trapezoid_z0 = hook_outer_z0 + 0.60;
hook_trapezoid_z1 = hook_trapezoid_z0 + hook_trapezoid_plate_thickness_z;

// Bent hook derived from the current 9/4.5 mm trapezoid. The final two fifths
// are replaced by a 240-degree Y-Z arc; the first three fifths remain straight.
hook_bent_root_width_x = hook_trapezoid_root_width_x;
hook_bent_tail_width_x = hook_trapezoid_tail_width_x;
hook_bent_plate_thickness_z = hook_trapezoid_plate_thickness_z;
hook_bent_straight_length = hook_trapezoid_length * 3 / 5;
hook_bent_arc_angle = 240;
hook_bent_centerline_radius = 5.00;
// Positive Z is the person-facing side. The negative angular sweep keeps
// the incoming tangent at the bend equal to the straight segment's -Y tangent.
hook_bent_arc_z_side = 1;
hook_bent_arc_turn_sign = -hook_bent_arc_z_side;
hook_bent_arc_start_angle = hook_bent_arc_z_side > 0 ? 270 : 90;
hook_bent_arc_end_angle = hook_bent_arc_start_angle +
                          hook_bent_arc_turn_sign * hook_bent_arc_angle;
hook_bent_root_y = hook_trapezoid_root_y;
hook_bent_root_z = hook_trapezoid_z0 + hook_bent_plate_thickness_z / 2;
hook_bent_bend_start_y = hook_bent_root_y - hook_bent_straight_length;
hook_bent_arc_center_y = hook_bent_bend_start_y;
hook_bent_arc_center_z = hook_bent_root_z +
                         hook_bent_arc_z_side * hook_bent_centerline_radius;
hook_bent_arc_length = hook_bent_centerline_radius *
                       hook_bent_arc_angle * PI / 180;
hook_bent_total_path_length = hook_bent_straight_length + hook_bent_arc_length;
hook_bent_straight_station_count = 9;
hook_bent_arc_station_count = 37;
// The root is deliberately kept as a full rectangular weld/attachment zone.
// Rounding then ramps in continuously before the exposed path is swept.
hook_bent_weld_length = 2.00;
hook_bent_round_transition_length = 2.00;
hook_visible_edge_radius = 0.75;
hook_bent_end_cap_length = 1.50;
// Concave root-to-base fillets. Every cove overlaps both parent solids;
// the +/-X side joints and the +/-Z face joints use the same nominal radius.
bond_fillet_radius = 1.25;
bond_fillet_width_x = hook_bent_root_width_x;
// Retained only as the focus of the local root preview.
bond_fillet_center_y = hook_outer_y0 + join_overlap;
bond_fillet_center_z = hook_bent_root_z +
                       hook_bent_plate_thickness_z / 2 - join_overlap;
bond_face_enabled = true;
bond_face_end_roll = 0.15;
bond_face_base_radius = hook_carriage_corner_radius;
// The -Z cove is tangent to the rounded lower base corner, not to an
// imaginary extension of its flat wall through the rail mounting plate.
bond_face_lower_span = sqrt(bond_face_base_radius * bond_face_base_radius +
                           2 * bond_face_base_radius * bond_fillet_radius) -
                       bond_face_base_radius;
bond_face_lower_depth = bond_face_base_radius * bond_fillet_radius /
                        (bond_face_base_radius + bond_fillet_radius);
// Left/right root corners seen in the assembly image: two XY-plane coves
// between the tapered hook sides and the step's exterior Y face.
bond_side_edge_radius = 0.15;
bond_side_taper = (hook_bent_root_width_x - hook_bent_tail_width_x) /
                  (2 * hook_bent_total_path_length);
bond_side_corner_half_width = hook_bent_root_width_x / 2 -
                             bond_side_taper * hook_trapezoid_root_overlap_y;
bond_side_profile_radius = bond_fillet_radius;
bond_side_reach_x = bond_side_profile_radius *
                    (sqrt(1 + bond_side_taper * bond_side_taper) -
                     bond_side_taper) + join_overlap;
bond_side_enabled = true;

// H-flange capture: two door-side lips under the flange, with a central
// relief slot for the vertical web. The flange remains between these lips
// and the top cap with slide_clearance on both Z faces.
hook_capture_lip_thickness = 0.80;
hook_capture_lip_top_z = rail_flange_z0 - slide_clearance;
hook_capture_lip_bottom_z = hook_capture_lip_top_z - hook_capture_lip_thickness;
hook_capture_web_clearance = slide_clearance;
hook_capture_lip_radius = 0.20;
hook_capture_left_y0 = hook_outer_y0;
hook_capture_left_y1 = rail_web_y0 - hook_capture_web_clearance;
hook_capture_right_y0 = rail_web_y1 + hook_capture_web_clearance;
hook_capture_right_y1 = hook_outer_y1;
// Multi-point Y-Z bridge profile. At y>1.7 it stays within the lower-lip
// band; toward negative Y it expands around the fairing/stem top.
hook_root_bridge_y0 = hook_outer_y0 - 0.30;
hook_root_bridge_y1 = hook_outer_y0 + hook_root_bridge_overlap;
hook_root_bridge_profile = [
    [hook_root_bridge_y1, 4.53],
    [2.75, 4.53], [2.30, 4.50], [1.85, 4.47],
    [1.45, 4.42], [1.00, 4.34], [0.45, 4.24],
    [-0.10, 4.13], [-0.70, 4.02], [-1.25, 3.92], [-1.60, 3.88],
    [-1.60, 3.14], [-1.25, 3.08], [-0.70, 3.02], [-0.10, 2.98],
    [0.45, 3.00], [1.00, 3.12], [1.45, 3.32], [1.85, 3.95],
    [2.30, 3.98], [2.75, 3.98], [hook_root_bridge_y1, 3.98]
];
// Rounded centerline stations for the J hook in the Y-Z profile plane. The
// first nine stations form a broad external fairing; subsequent stations
// keep a near-tangent stem-to-bend-to-tip path instead of a hard shoulder.
hook_centerline = [
    [hook_fairing_root_center_y, hook_root_center_z],
    [hook_fairing_root_center_y - 0.70, 3.51],
    [hook_fairing_root_center_y - 1.60, 3.54],
    [hook_fairing_root_center_y - 2.80, 3.60],
    [hook_fairing_root_center_y - 4.20, 3.68],
    [hook_fairing_root_center_y - 5.80, 3.76],
    [hook_fairing_root_center_y - 7.40, 3.83],
    [hook_fairing_root_center_y - 8.80, 3.87],
    [hook_fairing_end_y, hook_stem_center_z],
    [hook_fairing_end_y - 1.40, hook_stem_center_z + 0.01],
    [hook_fairing_end_y - 2.90, hook_stem_center_z + 0.01],
    [hook_fairing_end_y - 4.40, hook_stem_center_z + 0.03],
    [hook_shank_bottom_y + 0.90, 4.05],
    [hook_shank_bottom_y + 0.35, 4.25],
    [hook_shank_bottom_y + 0.02, 4.55],
    [hook_shank_bottom_y - 0.08, 4.90],
    [hook_shank_bottom_y - 0.02, 5.25],
    [hook_shank_bottom_y + 0.15, 5.60],
    [hook_shank_bottom_y + 0.45, 5.95],
    [hook_shank_bottom_y + 0.90, 6.30],
    [hook_shank_bottom_y + 1.55, 6.65],
    [hook_shank_bottom_y + 2.30, 6.95],
    [hook_shank_bottom_y + 3.15, 7.20],
    [hook_tip_y, hook_tip_center_z]
];
// One radius and one X width per centerline station. These arrays are the
// single taper source consumed by hook.scad's 3D ellipsoid sweep.
hook_profile_radii = [
    hook_root_radius,
    1.23, 1.21, 1.18, 1.14, 1.10, 1.05, 1.00, 0.96,
    hook_bend_radius, 0.92, 0.92, 0.91, 0.90, 0.88, 0.86,
    0.84, 0.82, 0.80, 0.77, 0.74, 0.72, 0.70,
    hook_tip_radius
];
hook_profile_widths = [
    hook_fairing_root_width_x,
    15.20, 14.50, 13.60, 12.50, 11.30, 10.00, 8.60,
    7.20, 6.10, hook_root_width_x, 4.80, 4.50, 4.20, hook_bend_width_x, 3.90,
    3.80, 3.70, 3.60, 3.50, 3.40, 3.30, 3.25,
    hook_tip_width_x
];

// End-stop sleeve. It surrounds only the flange region, so it cannot add
// thickness on the door side near Z=0. The stop plate is person-side only.
end_stop_socket_length = 8;
end_stop_plate_thickness = wall_thickness;
end_stop_outer_y0 = rail_flange_y0 - wall_thickness - slide_clearance;
end_stop_outer_y1 = rail_flange_y1 + wall_thickness + slide_clearance;
end_stop_outer_z0 = rail_flange_z0 - wall_thickness - slide_clearance;
end_stop_outer_z1 = rail_depth_target + wall_thickness;
end_stop_inner_y0 = rail_flange_y0 - slide_clearance;
end_stop_inner_y1 = rail_flange_y1 + slide_clearance;
end_stop_inner_z0 = rail_flange_z0 - slide_clearance;
end_stop_inner_z1 = rail_depth_target + slide_clearance;
end_stop_lip_z1 = rail_depth_target + 2 * wall_thickness;

// Preview controls. These are never used by the printable geometry modules.
part_selector = "rail";
end_stop_part = "left";
debug_section = false;
debug_root_connection = false;
assembly_step_x = 110;
assembly_section_x = 3;
assembly_section_local_x = hook_carriage_length / 2;
assembly_section_debug = false;
assembly_root_debug = false;
assembly_root_plan_debug = false;
show_assembly_rail = true;
show_assembly_end_stops = true;

assert(rail_length > 0);
assert(rail_height > 2 * wall_thickness);
assert(rail_depth_target < 6);
assert(slide_clearance > 0);
assert(hook_inner_y0 > hook_outer_y0);
assert(hook_inner_y1 < hook_outer_y1);
assert(hook_carriage_corner_radius > 0);
assert(hook_carriage_corner_radius < min(hook_outer_y1 - hook_outer_y0,
                                         hook_outer_z1 - hook_outer_z0) / 2);
assert(hook_trapezoid_root_width_x == hook_carriage_length / 2);
assert(hook_trapezoid_tail_width_x == hook_carriage_length / 4);
assert(hook_trapezoid_length > 0);
assert(hook_trapezoid_root_y > hook_outer_y0);
assert(hook_trapezoid_root_y < rail_flange_y0);
assert(hook_trapezoid_tail_y < hook_trapezoid_root_y);
assert(hook_trapezoid_plate_thickness_z > 0);
assert(hook_trapezoid_z0 >= hook_outer_z0);
assert(hook_trapezoid_z1 < rail_flange_z0);
assert(hook_bent_root_width_x == hook_trapezoid_root_width_x);
assert(hook_bent_tail_width_x == hook_trapezoid_tail_width_x);
assert(hook_bent_plate_thickness_z == hook_trapezoid_plate_thickness_z);
assert(hook_bent_straight_length == hook_trapezoid_length * 3 / 5);
assert(hook_bent_arc_angle == 240);
assert(hook_bent_centerline_radius > hook_bent_plate_thickness_z / 2);
assert(hook_bent_arc_angle < 360);
assert(hook_bent_arc_z_side == 1);
assert(hook_bent_arc_turn_sign == -1);
assert(hook_bent_arc_center_z > hook_bent_root_z);
assert(abs(hook_bent_arc_center_z - hook_bent_centerline_radius -
           hook_bent_root_z) < 0.0001);
assert(hook_bent_arc_center_z - hook_bent_centerline_radius -
       hook_bent_plate_thickness_z / 2 > hook_outer_z0);
assert(hook_bent_weld_length > hook_trapezoid_root_overlap_y);
assert(hook_bent_round_transition_length > 0);
assert(hook_bent_weld_length + hook_bent_round_transition_length <
       hook_bent_straight_length);
assert(hook_visible_edge_radius > 0);
assert(hook_visible_edge_radius < hook_bent_plate_thickness_z / 2);
assert(hook_visible_edge_radius < hook_bent_tail_width_x / 2);
assert(hook_bent_end_cap_length > hook_visible_edge_radius);
assert(hook_bent_end_cap_length < hook_bent_arc_length);
assert(bond_fillet_radius > 0);
assert(bond_fillet_radius < hook_bent_plate_thickness_z);
assert(bond_fillet_width_x == hook_bent_root_width_x);
assert(bond_fillet_center_y < rail_flange_y0);
assert(bond_fillet_center_y < hook_inner_y0);
assert(bond_fillet_center_z > hook_bent_root_z);
assert(bond_face_end_roll > 0);
assert(2 * bond_face_end_roll < bond_fillet_width_x);
assert(abs(hook_trapezoid_z0 - hook_outer_z0 -
           bond_face_base_radius) < 0.0001);
assert(hook_trapezoid_z0 - bond_face_lower_depth >
       wall_thickness + join_overlap);
assert(hook_trapezoid_z1 + bond_fillet_radius <
       hook_outer_z1 - hook_carriage_corner_radius);
assert(hook_outer_y0 + bond_face_base_radius *
       (1 - (bond_face_lower_span + bond_face_base_radius) /
             (bond_face_base_radius + bond_fillet_radius)) +
       join_overlap < hook_inner_y0);
assert(bond_side_edge_radius > 0);
assert(2 * bond_side_edge_radius < hook_bent_plate_thickness_z);
assert(hook_carriage_length / 2 - bond_side_corner_half_width -
       bond_side_reach_x > hook_carriage_corner_radius);
assert(hook_outer_y0 + bond_side_edge_radius + join_overlap < hook_inner_y0);
assert(hook_trapezoid_root_overlap_y + bond_side_profile_radius +
       bond_side_edge_radius < hook_bent_weld_length);
assert(hook_bent_root_y > hook_outer_y0);
assert(hook_bent_root_y < rail_flange_y0);
assert(hook_bent_root_z - hook_bent_plate_thickness_z / 2 >= hook_outer_z0);
assert(hook_bent_root_z + hook_bent_plate_thickness_z / 2 < rail_flange_z0);
assert(hook_fairing_length > 4);
assert(hook_root_bridge_overlap >= 2.0);
assert(hook_root_bridge_width_x > hook_root_width_x);
assert(hook_root_bridge_width_x < hook_carriage_length);
assert(hook_root_bridge_edge_radius > 0);
assert(hook_root_bridge_edge_radius < 0.5);
assert(hook_fairing_root_width_x < hook_carriage_length);
assert(hook_fairing_root_center_y + hook_root_radius <= hook_outer_y0 + join_overlap);
assert(hook_root_center_z + hook_root_radius <= rail_flange_z0 - hook_root_transition_clearance);
assert(hook_fairing_root_center_y - hook_root_radius < hook_root_bridge_y1);
assert(hook_fairing_root_center_y + hook_root_radius > hook_root_bridge_y0);
assert(hook_root_center_z - hook_root_radius < 4.53);
assert(hook_root_center_z + hook_root_radius > 2.98);
assert(hook_root_bridge_y1 > hook_outer_y0 + hook_root_bridge_overlap - join_overlap);
assert(hook_root_bridge_profile[0][1] < rail_flange_z0);
assert(hook_root_bridge_profile[len(hook_root_bridge_profile) - 1][1] < rail_flange_z0);
assert(hook_root_center_z + hook_root_radius < rail_flange_z0);
assert(hook_root_radius > hook_bend_radius);
assert(hook_bend_radius > hook_tip_radius);
assert(hook_tip_radius * 2 >= hook_profile_min_diameter);
assert(hook_root_width_x > hook_bend_width_x);
assert(hook_bend_width_x > hook_tip_width_x);
assert(len(hook_centerline) == len(hook_profile_radii));
assert(len(hook_centerline) == len(hook_profile_widths));
assert(hook_capture_lip_thickness > 0);
assert(hook_capture_lip_top_z < rail_flange_z0);
assert(hook_capture_lip_bottom_z > wall_thickness);
assert(hook_capture_left_y1 < rail_web_y0);
assert(hook_capture_right_y0 > rail_web_y1);
assert(hook_capture_lip_radius < hook_capture_lip_thickness / 2);
