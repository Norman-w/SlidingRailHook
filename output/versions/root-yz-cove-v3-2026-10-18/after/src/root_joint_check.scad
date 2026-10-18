// Diagnostic only. None of these exports belongs in the printable manifest.
include <parameters.scad>
use <step.scad>
use <hook_bent.scad>
use <rail.scad>

joint_check = "joined";

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
