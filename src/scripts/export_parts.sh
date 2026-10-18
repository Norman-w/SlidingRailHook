#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SRC_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
PROJECT_DIR=$(CDPATH= cd -- "$SRC_DIR/.." && pwd)
BUILD_DIR="${1:-$PROJECT_DIR/output/build}"
OUT_DIR="$BUILD_DIR/stl"
REPORT_DIR="$BUILD_DIR/reports"
PYTHON_BIN="${PYTHON_BIN:-python3}"

if command -v openscad >/dev/null 2>&1; then
    OPENSCAD_BIN=$(command -v openscad)
elif [ -x "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD" ]; then
    OPENSCAD_BIN="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
else
    echo "OpenSCAD CLI not found; no STL was generated." >&2
    exit 2
fi

mkdir -p "$OUT_DIR" "$REPORT_DIR"
export_mesh() {
    "$OPENSCAD_BIN" --hardwarnings --backend=CGAL --export-format binstl "$@"
}

export_mesh -o "$OUT_DIR/rail.stl" "$SRC_DIR/rail.scad"
export_mesh -o "$OUT_DIR/slider_hook.stl" "$SRC_DIR/slider_hook.scad"
export_mesh -D 'end_stop_part="left"' \
    -o "$OUT_DIR/end_stop_left.stl" "$SRC_DIR/end_stop.scad"
export_mesh -D 'end_stop_part="right"' \
    -o "$OUT_DIR/end_stop_right.stl" "$SRC_DIR/end_stop.scad"

export_mesh -o "$REPORT_DIR/step.stl" "$SRC_DIR/step.scad"
export_mesh -D 'joint_check="weld"' -o "$REPORT_DIR/weld.stl" \
    "$SRC_DIR/root_joint_check.scad"
for side in -1 1; do
    export_mesh -D 'joint_check="side_fillet"' -D "corner_side=$side" \
        -o "$REPORT_DIR/side_$side.stl" "$SRC_DIR/root_joint_check.scad"
    if [ "$side" = 1 ]; then face=upper_fillet; else face=lower_fillet; fi
    export_mesh -D "joint_check=\"$face\"" -o "$REPORT_DIR/face_$side.stl" \
        "$SRC_DIR/root_joint_check.scad"
    for z_side in -1 1; do
        export_mesh -D 'joint_check="corner"' -D "corner_side=$side" \
            -D "corner_z_side=$z_side" -o "$REPORT_DIR/corner_${side}_$z_side.stl" \
            "$SRC_DIR/root_joint_check.scad"
    done
done

"$PYTHON_BIN" "$SCRIPT_DIR/verify_release.py" "$BUILD_DIR"
echo "Exported and verified four printable STL files in $OUT_DIR"
