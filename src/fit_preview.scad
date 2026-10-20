// Diagnostic assembly / cross-section, not a printable part.
include <parameters.scad>
use <step.scad>
use <hook_bent.scad>
use <rail.scad>

fit_preview = "new_hook";

module current_hook() {
    union() {
        step_geometry();
        hook_bent_geometry();
    }
}

module fit_assembly(legacy=false) {
    color("silver")
        rail_geometry(length=18,height=12,
            depth=legacy ? 5.8 : 6,front_height=legacy ? 8 : 12);
    color("orange")
        if (legacy)
            import("../output/print-12-v1/source/slider_hook.stl");
        else
            current_hook();
}

if (fit_preview=="new_hook")
    color("orange") current_hook();
else if (fit_preview=="new_section" || fit_preview=="legacy_section")
    intersection() {
        fit_assembly(legacy=fit_preview=="legacy_section");
        translate([8.75,-4,-1]) cube([.5,20,10]);
    }
else
    fit_assembly();
