// NEW rail for REUSING the already printed v1 hooks. Units mm.
// NOT the user's measured 12/12 x 6/4 H rail: rear wing=12, front wing=8,
// outside depth=5.8, inside separation=3.8, wings/web=1.
include <parameters.scad>
use <rail.scad>

legacy_rail_length = 300;
rail_geometry(length=legacy_rail_length, height=12, depth=5.8,
              front_height=8, wall=1, web=1);
