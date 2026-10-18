// Diagnostic only. None of these exports belongs in the printable manifest.
include <parameters.scad>
use <step.scad>
use <hook_bent.scad>
use <rail.scad>

joint_check = "joined";
corner_side = 1;
corner_z_side = 1;

if (joint_check == "joined")
    union() {
        step_geometry();
        hook_bent_geometry();
    }
else if (joint_check == "rail_collision")
    intersection() {
        rail_geometry();
        hook_bent_geometry();
    }
else if (joint_check == "left_step_overlap")
    intersection() {
        step_geometry();
        hook_bond_side_fillet(-1);
    }
else if (joint_check == "right_step_overlap")
    intersection() {
        step_geometry();
        hook_bond_side_fillet(1);
    }
else if (joint_check == "left_hook_overlap")
    intersection() {
        hook_bent_segment(0, hook_bent_weld_length, 0, 0);
        hook_bond_side_fillet(-1);
    }
else if (joint_check == "right_hook_overlap")
    intersection() {
        hook_bent_segment(0, hook_bent_weld_length, 0, 0);
        hook_bond_side_fillet(1);
    }
else if (joint_check == "upper_step_overlap")
    intersection() {
        step_geometry();
        hook_bond_face_fillet(1);
    }
else if (joint_check == "lower_step_overlap")
    intersection() {
        step_geometry();
        hook_bond_face_fillet(-1);
    }
else if (joint_check == "upper_hook_overlap")
    intersection() {
        hook_bent_segment(0, hook_bent_weld_length, 0, 0);
        hook_bond_face_fillet(1);
    }
else if (joint_check == "lower_hook_overlap")
    intersection() {
        hook_bent_segment(0, hook_bent_weld_length, 0, 0);
        hook_bond_face_fillet(-1);
    }
else if (joint_check == "upper_fillet")
    hook_bond_face_fillet(1);
else if (joint_check == "lower_fillet")
    hook_bond_face_fillet(-1);
else if (joint_check == "corner")
    hook_bond_corner_fillet(corner_side, corner_z_side);
else if (joint_check == "side_fillet")
    hook_bond_side_fillet(corner_side);
else if (joint_check == "weld")
    hook_bent_segment(0, hook_bent_weld_length, 0, 0);
