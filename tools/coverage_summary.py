"""Summarize LCOV line coverage. Run from the repository root."""

import sys
from collections import defaultdict
from pathlib import Path


def main():
    root = Path.cwd().resolve()
    report = Path(sys.argv[1] if len(sys.argv) > 1 else "coverage/lcov.info")

    if not report.is_file():
        print("Coverage file not found. Run flutter test --coverage first.")
        return 1

    records = {}
    excluded = set()
    source = None

    for raw in report.read_text(encoding="utf-8").splitlines():
        if raw.startswith("SF:"):
            path = Path(raw[3:])
            if path.is_absolute():
                try:
                    path = path.resolve().relative_to(root)
                except ValueError:
                    source = None
                    continue

            source = path.as_posix()
            if path.name == "firebase_options.dart":
                excluded.add(source)
                source = None
            elif not source.startswith("lib/"):
                source = None
            else:
                records.setdefault(source, {})

        elif raw.startswith("DA:") and source is not None:
            number, hits, *_ = raw[3:].split(",")
            number, hits = int(number), int(hits)
            lines = records[source]
            lines[number] = max(hits, lines.get(number, 0))

        elif raw == "end_of_record":
            source = None

    groups = defaultdict(lambda: [0, 0])

    for name, lines in records.items():
        parts = Path(name).parts
        if len(parts) > 2 and parts[:2] == ("lib", "features"):
            group = parts[2]
        elif len(parts) > 1 and parts[1] == "core":
            group = "core"
        else:
            group = "app / wiring"

        groups[group][0] += sum(hits > 0 for hits in lines.values())
        groups[group][1] += len(lines)

    covered = sum(counts[0] for counts in groups.values())
    measured = sum(counts[1] for counts in groups.values())

    if measured == 0:
        print("No measurable lib/ source lines found in LCOV.")
        return 1

    def percentage(hit, total):
        return f"{100 * hit / total:.2f}%" if total else "N/A"

    print(f"Source: {report}")
    print("Scope: lib/ files represented in LCOV; firebase_options.dart excluded.")
    print()
    print(f"{'Area':<20} {'Covered':>8} {'Measured':>9} {'Coverage':>9}")
    print("-" * 49)

    for group, (hit, total) in sorted(groups.items()):
        print(f"{group:<20} {hit:>8} {total:>9} {percentage(hit, total):>9}")

    print("-" * 49)
    print(f"{'TOTAL':<20} {covered:>8} {measured:>9} "
          f"{percentage(covered, measured):>9}")
    print(f"70% target within LCOV scope: "
          f"{'MET' if covered / measured >= 0.70 else 'NOT MET'}")
    print(f"Generated Firebase source files removed: {len(excluded)}")

    missing = sorted(
        path.relative_to(root).as_posix()
        for path in (root / "lib").rglob("*.dart")
        if path.name != "firebase_options.dart"
        and path.relative_to(root).as_posix() not in records
    )

    print()
    print(f"lib/ Dart files absent from LCOV: {len(missing)}")
    print("Absence does not establish executable-line coverage for these files.")
    for name in missing:
        print(f"  {name}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())