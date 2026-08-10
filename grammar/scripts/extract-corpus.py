#!/usr/bin/env python3
"""Mine .native markup out of the Native SDK's own Zig test suite.

The SDK vendors its source in the npm package, and its markup tests carry several hundred
snippets as Zig multiline strings (`\\\\`-prefixed lines). Those snippets are the closest thing
to a spec corpus that exists: every one of them is markup the SDK itself accepts or rejects on
purpose. We keep only the ones `native markup check` accepts, so the corpus is all valid input.
"""

import re
import subprocess
import sys
from pathlib import Path

SDK = Path.home() / ".bun/install/global/node_modules/@native-sdk/cli/src"
OUT = Path(__file__).resolve().parent.parent / "test" / "fixtures"

MULTILINE = re.compile(r"^\s*\\\\(.*)$")


def snippets(path: Path):
    """Yield each run of consecutive Zig multiline-string lines that looks like markup."""
    run: list[str] = []
    for line in path.read_text(errors="replace").splitlines():
        m = MULTILINE.match(line)
        if m:
            run.append(m.group(1))
            continue
        if run:
            yield "\n".join(run)
            run = []
    if run:
        yield "\n".join(run)


def is_markup(text: str) -> bool:
    stripped = text.strip()
    return stripped.startswith("<") and "</" in stripped or stripped.startswith("<import")


def main() -> int:
    if not SDK.is_dir():
        print(f"SDK source not found at {SDK}", file=sys.stderr)
        return 1

    OUT.mkdir(parents=True, exist_ok=True)
    for stale in OUT.glob("sdk-*.native"):
        stale.unlink()

    kept = rejected = 0
    seen: set[str] = set()
    for src in sorted(SDK.glob("primitives/canvas/ui_markup*tests.zig")):
        for i, text in enumerate(snippets(src)):
            if not is_markup(text) or text in seen:
                continue
            seen.add(text)
            name = f"sdk-{src.stem.replace('ui_markup_', '').replace('_tests', '')}-{i:04d}.native"
            target = OUT / name
            target.write_text(text + "\n")
            check = subprocess.run(
                ["native", "markup", "check", str(target)],
                capture_output=True,
                text=True,
            )
            if check.returncode == 0:
                kept += 1
            else:
                target.unlink()
                rejected += 1

    print(f"kept {kept} valid snippets, dropped {rejected} the SDK rejects")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
