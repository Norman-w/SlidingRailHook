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

// u is outward +/-Z from the hook face; v is away from the base in -Y.
// Upper: square-minus-quarter-circle cove, tangent to the two flat faces.
// Lower: circular cove tangent to the actual R0.6 rounded base corner and
// the hook underside. Its circle stays clear of the rail mounting plate.
function hook_bond_face_profile(z_side, r) =
    z_side > 0
        ? concat([[-join_overlap, -join_overlap], [r, -join_overlap]],
                 hook_bent_arc_points(r, r, r, -90, -180, 32),
                 [[-join_overlap, r]])
        : let(b = bond_face_base_radius,
              span = sqrt(b*b + 2*b*r) - b,
              tu = b*r/(b+r),
              tv = -b + b*(span+b)/(b+r),
              base_angle = atan2(tv+b, tu),
              cove_angle = atan2(tv-span, tu-r),
              base_arc = hook_bent_arc_points(0, -b, b, 90, base_angle, 24))
          concat([for (p=base_arc) [p[0], p[1]-join_overlap]],
                 hook_bent_arc_points(r, span, r, cove_angle, -180, 32),
                 [[-join_overlap, span], [-join_overlap, -join_overlap]]);

module hook_bond_face_fillet(z_side) {
    // Keep the full cove all the way to the tapered side. The four corner
    // patches continue it around the root; independent end rolls left gaps.
    face_z = z_side > 0 ? hook_trapezoid_z1 : hook_trapezoid_z0;
    intersection() {
        multmatrix([
            [0, 0, 1, 0],
            [0, -1, 0, hook_outer_y0],
            [z_side, 0, 0, face_z],
            [0, 0, 0, 1]
        ])
            linear_extrude(height=hook_carriage_length)
                polygon(points=hook_bond_face_profile(z_side,bond_fillet_radius));
        // Cut by the true tapered sides using a second 2D extrusion. This
        // avoids near-planar floating-point polygon caps in the CGAL backend.
        linear_extrude(height=hook_outer_z1+bond_fillet_radius)
            polygon(points=[for (p=[[-1,-bond_face_base_radius-join_overlap],
                                    [1,-bond_face_base_radius-join_overlap],
                                    [1,bond_fillet_radius+join_overlap],
                                    [-1,bond_fillet_radius+join_overlap]])
                [hook_carriage_length/2+p[0]*(bond_side_corner_half_width-
                    bond_side_taper*p[1]+join_overlap), hook_outer_y0-p[1]]]);
    }
}

module hook_bond_fillet() {
    if (bond_face_enabled)
        for (z_side=[-1,1]) hook_bond_face_fillet(z_side);
}

// Local coordinates: u points outward from the hook's side, v points away
// from the base in -Y. The hook's tapered side is u + k*v = 0 and the base
// face is v = 0. This circular cove is tangent to BOTH faces; it fills their
// concave corner instead of merely rounding the ends of the upper bead.
function hook_bond_side_profile(r=bond_side_profile_radius) =
    let(k = bond_side_taper,
        q = sqrt(1 + k*k),
        a = r * (q - k),
        end_angle = -180 + atan(k),
        arc = hook_bent_arc_points(a, r, r, -90, end_angle, 32),
        last = arc[len(arc)-1])
    concat([[-join_overlap, -join_overlap], [a, -join_overlap]],
           arc,
           [[last[0] - join_overlap/q, last[1] - k*join_overlap/q]]);

module hook_bond_side_fillet(side) {
    corner_x = hook_carriage_length / 2 +
               side * bond_side_corner_half_width;
    // Full-radius side cove overlaps the continuous corner patches at Z ends.
    stations = [hook_trapezoid_z0 - join_overlap,
                hook_trapezoid_z1 + join_overlap];
    count = len(hook_bond_side_profile());
    layers = len(stations);
    points = [for (station=stations)
        for (p=hook_bond_side_profile()) [p[0],p[1],station]];
    faces = concat(
        [[for (j=[count-1:-1:0]) j]],
        [for (i=[0:layers-2]) for (j=[0:count-1])
            [i*count+j, i*count+(j+1)%count, (i+1)*count+(j+1)%count]],
        [for (i=[0:layers-2]) for (j=[0:count-1])
            [i*count+j, (i+1)*count+(j+1)%count, (i+1)*count+j]],
        [[for (j=[0:count-1]) (layers-1)*count+j]]);
    multmatrix([
        [side, 0, 0, corner_x],
        [0, -1, 0, hook_outer_y0],
        [0, 0, 1, 0],
        [0, 0, 0, 1]
    ])
        polyhedron(points=points,
                   faces=[for (face=faces) [for (j=[len(face)-1:-1:0]) face[j]]],
                   convexity=4);
}

// Boundary curves of the existing coves, parameterized from base to hook.
// The underside uses the real rounded base corner, not a fictitious flat wall.
function hook_bond_side_arc(t) =
    let(r=bond_fillet_radius, k=bond_side_taper,
        a=r*(sqrt(1+k*k)-k), angle=-90+(-90+atan(k))*t)
    [a+r*cos(angle), r+r*sin(angle)];

function hook_bond_face_arc(z_side, t) =
    let(r=bond_fillet_radius, b=bond_face_base_radius,
        span=bond_face_lower_span,
        tu=b*r/(b+r), tv=-b+b*(span+b)/(b+r),
        start=z_side>0 ? -90 : atan2(tv-span, tu-r),
        angle=start+(-180-start)*t)
    [r+r*cos(angle), (z_side>0 ? r : span)+r*sin(angle)];

function hook_bond_corner_point(side, z_side, row, column, inside=false) =
    let(t=max(0,row)/bond_corner_curve_steps,
        phi=90*column/bond_corner_wrap_steps,
        w=pow(sin(phi),2),
        a=hook_bond_side_arc(t), b=hook_bond_face_arc(z_side,t),
        // The first row is buried in the base, giving real volume overlap.
        v=(1-w)*a[1]+w*b[1]-(row<0 ? join_overlap : 0),
        dx=inside ? -join_overlap*(1-cos(phi)/2) :
                    max(join_overlap/4,a[0]+bond_side_taper*a[1])*cos(phi),
        dz=inside ? -join_overlap*(1-sin(phi)/2) :
                    max(join_overlap/4,b[0])*sin(phi))
    [hook_carriage_length/2+side*(bond_side_corner_half_width-
        bond_side_taper*v+dx), hook_outer_y0-v,
     (z_side>0 ? hook_trapezoid_z1 : hook_trapezoid_z0)+z_side*dz];

module hook_bond_corner_fillet(side, z_side) {
    // A closed quarter-wrap solid, not four touching balls or a convex bead.
    // sin(phi)^2 gives a zero cross-derivative at each neighboring cove,
    // keeping the transition tangent while respecting the side taper.
    rows=bond_corner_curve_steps+2;
    cols=bond_corner_wrap_steps+1;
    sheet=rows*cols;
    points=[for (inside=[false,true]) for (i=[0:rows-1])
        for (j=[0:cols-1]) hook_bond_corner_point(side,z_side,i-1,j,inside)];
    faces=concat(
        [for (i=[0:rows-2]) for (j=[0:cols-2])
            [i*cols+j,i*cols+j+1,(i+1)*cols+j+1,(i+1)*cols+j]],
        [for (i=[0:rows-2]) for (j=[0:cols-2])
            [sheet+i*cols+j,sheet+(i+1)*cols+j,
             sheet+(i+1)*cols+j+1,sheet+i*cols+j+1]],
        [for (j=[0:cols-2]) [j,sheet+j,sheet+j+1,j+1]],
        [for (j=[0:cols-2]) let(a=(rows-1)*cols+j)
            [a,a+1,sheet+a+1,sheet+a]],
        [for (i=[0:rows-2]) let(a=i*cols,b=(i+1)*cols)
            [a,b,sheet+b,sheet+a]],
        [for (i=[0:rows-2]) let(a=i*cols+cols-1,b=(i+1)*cols+cols-1)
            [a,sheet+a,sheet+b,b]]);
    triangles=[for (face=faces) for (j=[1:len(face)-2])
        [face[0],face[j],face[j+1]]];
    polyhedron(points=points, faces=side*z_side<0 ? triangles :
        [for (face=triangles) [face[2],face[1],face[0]]], convexity=6);
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
        if (bond_side_enabled)
            for (side = [-1, 1])
                hook_bond_side_fillet(side);
        if (bond_corner_enabled && bond_face_enabled && bond_side_enabled)
            for (side=[-1,1]) for (z_side=[-1,1])
                hook_bond_corner_fillet(side,z_side);
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
