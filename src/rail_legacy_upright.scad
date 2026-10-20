// PETG FDM, X1 Carbon 0.4 mm. Units: mm. STL-only print entry.
// Same 12/8-mm, 5.8/3.8-mm H section as rail_legacy_8mm.scad.
// No permanent base or support: add removable 10-mm outer Brim in slicer.
// Assembly X (sliding) -> printer Z; assembly Y -> printer X;
// assembly Z (away from door) -> printer Y. Proper rotation, not a mirror.
// The one-piece rail mounts along its flat rear wing; no joint hardware.
include <parameters.scad>
use <rail.scad>

segment_length = 200;
assert(segment_length > 0 && segment_length <= 240,
       "Use at most 240 mm: leave 10 mm below this X1C profile's 250-mm limit");

multmatrix([[0, 1, 0, 0],
            [0, 0, 1, 0],
            [1, 0, 0, 0],
            [0, 0, 0, 1]])
    rail_geometry(length=segment_length, height=12, depth=5.8,
                  front_height=8, wall=1, web=1);
