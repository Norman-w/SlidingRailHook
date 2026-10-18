// Printable monolithic slider + hook. Units: mm. Do not print the two
// overlapping diagnostic components separately and try to assemble them.
include <parameters.scad>
use <step.scad>
use <hook_bent.scad>

union() {
    step_geometry();
    hook_bent_geometry();
}
