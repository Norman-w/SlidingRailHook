#!/usr/bin/env python3
"""Package current source and checked release artifacts, excluding local state."""
import argparse
import hashlib
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("output", type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
output = args.output.resolve()
archive = output / f"SlidingRailHook-{output.name}.zip"
sources = [root / "README.md", root / "requirements-qa.txt"]
sources += [p for folder in ("src", "docs") for p in (root / folder).rglob("*")
            if p.is_file() and "__pycache__" not in p.parts]
artifacts = [p for folder in ("stl", "renders") for p in (output / folder).glob("*")
             if p.is_file()]
artifacts += [output / "reports" / "validation.json"]
with ZipFile(archive, "w", ZIP_DEFLATED) as package:
    for path in sources:
        package.write(path, f"SlidingRailHook-{output.name}/{path.relative_to(root)}")
    for path in artifacts:
        package.write(path, f"SlidingRailHook-{output.name}/output/releases/{output.name}/{path.relative_to(output)}")
checksums = sorted(artifacts + [archive])
(output / "SHA256SUMS.txt").write_text("".join(
    f"{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.relative_to(output)}\n"
    for path in checksums))
print(archive)
