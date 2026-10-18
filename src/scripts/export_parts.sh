#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SRC_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
PROJECT_DIR=$(CDPATH= cd -- "$SRC_DIR/.." && pwd)
OUT_DIR="$PROJECT_DIR/output/3d-print"
REPORT_DIR="$PROJECT_DIR/output/reports"

if command -v openscad >/dev/null 2>&1; then
    OPENSCAD_BIN=$(command -v openscad)
elif [ -x "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD" ]; then
    OPENSCAD_BIN="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
else
    echo "OpenSCAD CLI not found; no STL was generated." >&2
    exit 2
fi

mkdir -p "$OUT_DIR" "$REPORT_DIR"

"$OPENSCAD_BIN" -o "$OUT_DIR/rail.stl" "$SRC_DIR/rail.scad"
"$OPENSCAD_BIN" -o "$OUT_DIR/step.stl" "$SRC_DIR/step.scad"
"$OPENSCAD_BIN" -o "$OUT_DIR/hook_bent.stl" "$SRC_DIR/hook_bent.scad"
"$OPENSCAD_BIN" -D 'end_stop_part="left"' \
    -o "$OUT_DIR/end_stop_left.stl" "$SRC_DIR/end_stop.scad"
"$OPENSCAD_BIN" -D 'end_stop_part="right"' \
    -o "$OUT_DIR/end_stop_right.stl" "$SRC_DIR/end_stop.scad"

INSPECT="/Users/norman/.codex/skills/openscad-stl-print/scripts/inspect_stl.py"
for part in rail step hook_bent end_stop_left end_stop_right; do
    python3 "$INSPECT" "$OUT_DIR/$part.stl" --require-watertight \
        > "$REPORT_DIR/$part-inspect.txt"
done

echo "Exported and inspected STL files in $OUT_DIR"
