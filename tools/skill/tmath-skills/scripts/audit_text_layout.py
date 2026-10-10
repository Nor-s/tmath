#!/usr/bin/env python3
"""Audit sampled tmath Text bounds with the production font."""

from __future__ import annotations

import argparse
import json
import math
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class Containment:
    text_id: str
    panel_id: str
    inset: float


def _json_command(command: list[str]) -> dict[str, Any]:
    result = subprocess.run(command, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip() or "command failed"
        raise RuntimeError(f"{' '.join(command)}: {detail}")
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise RuntimeError(f"{' '.join(command)}: invalid JSON: {error}") from error


def _frame_times(duration: float, fps: int) -> list[float]:
    count = math.ceil(duration * fps)
    times = [min(index / fps, duration) for index in range(count + 1)]
    if not times or not math.isclose(times[-1], duration):
        times.append(duration)
    return list(dict.fromkeys(times))


def _box_valid(box: Any) -> bool:
    if not isinstance(box, dict):
        return False
    values = [box.get(name) for name in ("x", "y", "width", "height")]
    return all(isinstance(value, (int, float)) and math.isfinite(value) for value in values) \
        and box["width"] > 0 and box["height"] > 0


def _inside(inner: dict[str, float], outer: dict[str, float], inset: float) -> bool:
    return (
        inner["x"] >= outer["x"] + inset
        and inner["y"] >= outer["y"] + inset
        and inner["x"] + inner["width"] <= outer["x"] + outer["width"] - inset
        and inner["y"] + inner["height"] <= outer["y"] + outer["height"] - inset
    )


def _clearance(inner: dict[str, float], outer: dict[str, float]) -> float:
    return min(
        inner["x"] - outer["x"],
        inner["y"] - outer["y"],
        outer["x"] + outer["width"] - inner["x"] - inner["width"],
        outer["y"] + outer["height"] - inner["y"] - inner["height"],
    )


def _scene_paths(scene: dict[str, Any], path: str = "root"):
    yield path, scene
    for index, viewport in enumerate(scene.get("viewports", [])):
        yield from _scene_paths(viewport["scene"], f"{path}/viewport:{index}")
    for index, transition in enumerate(scene.get("transitions", [])):
        yield from _scene_paths(transition, f"{path}/transition:{index}")


def _inspect_paths(scene: dict[str, Any], path: str = "root"):
    yield path, scene
    for index, viewport in enumerate(scene.get("viewports", [])):
        yield from _inspect_paths(viewport["scene"], f"{path}/viewport:{index}")
    for index, transition in enumerate(scene.get("transitions", [])):
        yield from _inspect_paths(transition, f"{path}/transition:{index}")


def _is_ancestor(parent_map: dict[int, int | None], ancestor: int, child: int) -> bool:
    current = parent_map.get(child)
    while current is not None:
        if current == ancestor:
            return True
        current = parent_map.get(current)
    return False


def _parse_containment(value: str, default_inset: float) -> Containment:
    if "=" not in value:
        raise argparse.ArgumentTypeError("containment must be TEXT_ID=PANEL_ID[:INSET]")
    text_id, panel = value.split("=", 1)
    inset = default_inset
    if ":" in panel:
        panel, raw_inset = panel.rsplit(":", 1)
        try:
            inset = float(raw_inset)
        except ValueError as error:
            raise argparse.ArgumentTypeError("containment inset must be a number") from error
    if not text_id or not panel or inset < 0 or not math.isfinite(inset):
        raise argparse.ArgumentTypeError("invalid containment")
    return Containment(text_id, panel, inset)


def _parse_overlap(value: str) -> frozenset[str]:
    if "=" not in value:
        raise argparse.ArgumentTypeError("allowed overlap must be FIRST_ID=SECOND_ID")
    first, second = value.split("=", 1)
    if not first or not second or first == second:
        raise argparse.ArgumentTypeError("allowed overlap needs two distinct IDs")
    return frozenset((first, second))


def _uncovered_texts(
    expected: set[tuple[str, str]],
    containments: list[Containment],
    allowed_uncontained: set[str],
) -> set[tuple[str, str]]:
    contained = {constraint.text_id for constraint in containments}
    return {item for item in expected if item[1] not in contained | allowed_uncontained}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("scene", type=Path)
    parser.add_argument("--cli", default="tmath", help="installed tmath CLI")
    parser.add_argument("--font", required=True, type=Path, help="exact production font file")
    parser.add_argument("--canvas-inset", type=float, default=4.0)
    parser.add_argument("--text-gap", type=float, default=4.0)
    parser.add_argument("--panel-inset", type=float, default=12.0)
    parser.add_argument("--contain", action="append", default=[], metavar="TEXT=PANEL[:INSET]")
    parser.add_argument(
        "--require-containment-ledger",
        action="store_true",
        help="fail unless every Text is contained or explicitly allowed outside a panel",
    )
    parser.add_argument(
        "--allow-uncontained",
        action="append",
        default=[],
        metavar="TEXT_ID",
        help="Text intentionally outside a Rectangle when the containment ledger is required",
    )
    parser.add_argument("--allow-text-overlap", action="append", default=[], metavar="FIRST=SECOND")
    parser.add_argument("--allow-viewport-stretch", action="store_true")
    args = parser.parse_args()

    for name in ("canvas_inset", "text_gap", "panel_inset"):
        value = getattr(args, name)
        if value < 0 or not math.isfinite(value):
            parser.error(f"--{name.replace('_', '-')} must be finite and non-negative")
    if not args.scene.is_file():
        parser.error(f"scene not found: {args.scene}")
    if not args.font.is_file():
        parser.error(f"font not found: {args.font}")

    try:
        containments = [_parse_containment(value, args.panel_inset) for value in args.contain]
        allowed_overlaps = {_parse_overlap(value) for value in args.allow_text_overlap}
    except argparse.ArgumentTypeError as error:
        parser.error(str(error))
    allowed_uncontained = set(args.allow_uncontained)
    if any(not text_id for text_id in allowed_uncontained):
        parser.error("--allow-uncontained requires a non-empty Text ID")
    contained_ids = {constraint.text_id for constraint in containments}
    duplicate_containments = {
        text_id for text_id in contained_ids
        if sum(constraint.text_id == text_id for constraint in containments) > 1
    }
    if duplicate_containments:
        parser.error(
            "Text has multiple containment owners: "
            + ", ".join(sorted(duplicate_containments))
        )
    duplicate_owners = contained_ids & allowed_uncontained
    if duplicate_owners:
        parser.error(
            "Text cannot be both contained and uncontained: "
            + ", ".join(sorted(duplicate_owners))
        )

    try:
        inspection = _json_command([args.cli, "inspect", str(args.scene)])
    except RuntimeError as error:
        print(f"text-layout audit: {error}", file=sys.stderr)
        return 2
    fps = inspection.get("fps")
    duration = inspection.get("duration")
    if not isinstance(fps, int) or fps <= 0 or not isinstance(duration, (int, float)) or duration < 0:
        print("text-layout audit: inspect returned invalid fps or duration", file=sys.stderr)
        return 2

    structure: dict[str, dict[int, int | None]] = {}
    for path, scene in _inspect_paths(inspection):
        structure[path] = {item["handle"]: item.get("parent") for item in scene.get("objects", [])}

    issues: dict[tuple[Any, ...], str] = {}
    expected_texts: set[tuple[str, str]] = set()
    visible_texts: set[tuple[str, str]] = set()
    matched_containments: set[int] = set()
    worst_canvas: tuple[float, str, str, float] | None = None
    worst_panel: tuple[float, str, str, str, float] | None = None

    def issue(key: tuple[Any, ...], message: str) -> None:
        issues.setdefault(key, message)

    times = _frame_times(float(duration), fps)
    for time in times:
        command = [
            args.cli,
            "layout",
            str(args.scene),
            "--time",
            f"{time:.9g}",
            "--padding",
            f"{args.text_gap:.9g}",
            "--font",
            str(args.font),
        ]
        try:
            report = _json_command(command)
        except RuntimeError as error:
            print(f"text-layout audit: {error}", file=sys.stderr)
            return 2

        for path, scene in _scene_paths(report["scene"]):
            objects = scene.get("objects", [])
            by_handle = {item["handle"]: item for item in objects}
            by_id = {item["id"]: item for item in objects if item.get("id")}
            canvas = {"x": 0.0, "y": 0.0, "width": scene["width"], "height": scene["height"]}

            for item in objects:
                if item.get("type") != "text":
                    continue
                text_id = item.get("id")
                if not text_id:
                    issue(("missing-id", path, item["handle"]),
                          f"{path} Text handle {item['handle']} has no stable ID")
                    text_id = f"#{item['handle']}"
                key = (path, text_id)
                expected_texts.add(key)
                box = item.get("bounds")
                if box is None:
                    continue
                if not _box_valid(box):
                    issue(("invalid-box", *key), f"{path} {text_id} has an invalid render BBox at {time:.6g}s")
                    continue
                visible_texts.add(key)
                clearance = _clearance(box, canvas)
                if worst_canvas is None or clearance < worst_canvas[0]:
                    worst_canvas = (clearance, path, text_id, time)
                if not _inside(box, canvas, args.canvas_inset):
                    issue(("canvas", *key),
                          f"{path} {text_id} leaves the {args.canvas_inset:g}px canvas inset at {time:.6g}s")

            for pair in scene.get("intersections", []):
                first = by_handle.get(pair["first"])
                second = by_handle.get(pair["second"])
                if not first or not second or first.get("type") != "text" or second.get("type") != "text":
                    continue
                first_id, second_id = first.get("id"), second.get("id")
                if first_id and second_id and frozenset((first_id, second_id)) in allowed_overlaps:
                    continue
                issue(("text-gap", path, min(pair["first"], pair["second"]), max(pair["first"], pair["second"])),
                      f"{path} Text {first_id or pair['first']} and {second_id or pair['second']} violate "
                      f"the {args.text_gap:g}px gap at {time:.6g}s")

            for index, constraint in enumerate(containments):
                text = by_id.get(constraint.text_id)
                panel = by_id.get(constraint.panel_id)
                if not text or not panel:
                    continue
                matched_containments.add(index)
                if panel.get("type") != "rectangle":
                    issue(("panel-type", index, path),
                          f"{path} {constraint.panel_id} must be a Rectangle containment reference")
                parent_map = structure.get(path)
                if parent_map and _is_ancestor(parent_map, panel["handle"], text["handle"]):
                    issue(("panel-ancestor", index, path),
                          f"{path} {constraint.panel_id} owns {constraint.text_id}; family bounds make containment tautological")
                text_box = text.get("bounds")
                if text_box is None:
                    continue
                panel_box = panel.get("bounds")
                if not _box_valid(panel_box):
                    issue(("panel-hidden", index, path),
                          f"{path} {constraint.text_id} is visible while {constraint.panel_id} has no render BBox at {time:.6g}s")
                else:
                    clearance = _clearance(text_box, panel_box)
                    if worst_panel is None or clearance < worst_panel[0]:
                        worst_panel = (clearance, path, constraint.text_id, constraint.panel_id, time)
                    if not _inside(text_box, panel_box, constraint.inset):
                        issue(("panel-fit", index, path),
                              f"{path} {constraint.text_id} leaves the {constraint.inset:g}px inset of "
                              f"{constraint.panel_id} at {time:.6g}s")

            if not args.allow_viewport_stretch:
                for index, viewport in enumerate(scene.get("viewports", [])):
                    child = viewport["scene"]
                    destination_aspect = viewport["width"] * scene["width"] / (viewport["height"] * scene["height"])
                    child_aspect = child["width"] / child["height"]
                    if not math.isclose(destination_aspect, child_aspect, rel_tol=1e-3):
                        issue(("viewport-aspect", path, index),
                              f"{path}/viewport:{index} stretches {child_aspect:.4g} content into "
                              f"a {destination_aspect:.4g} destination aspect")

    for key in sorted(expected_texts - visible_texts):
        issue(("never-visible", *key),
              f"{key[0]} {key[1]} never produced a render BBox; verify font registration and visibility")
    for index, constraint in enumerate(containments):
        if index not in matched_containments:
            issue(("unmatched-containment", index),
                  f"containment {constraint.text_id}={constraint.panel_id} did not match one Scene")
    if args.require_containment_ledger:
        for path, text_id in sorted(_uncovered_texts(expected_texts, containments, allowed_uncontained)):
            issue(("missing-containment-owner", path, text_id),
                  f"{path} {text_id} is missing from the containment ledger; add --contain or "
                  "--allow-uncontained")
        expected_ids = {text_id for _, text_id in expected_texts}
        for text_id in sorted(allowed_uncontained - expected_ids):
            issue(("unmatched-uncontained", text_id),
                  f"uncontained Text {text_id} did not match one Scene")

    if issues:
        print(f"text-layout audit: FAIL ({len(issues)} issue(s), {len(times)} frames)", file=sys.stderr)
        for message in issues.values():
            print(f"- {message}", file=sys.stderr)
        return 1
    print(f"text-layout audit: PASS ({len(visible_texts)} Text objects, {len(times)} frames)")
    if worst_canvas is not None:
        clearance, path, text_id, time = worst_canvas
        print(f"- minimum canvas clearance: {clearance:.3f}px ({path} {text_id} at {time:.6g}s)")
    if worst_panel is not None:
        clearance, path, text_id, panel_id, time = worst_panel
        print(f"- minimum declared panel clearance: {clearance:.3f}px "
              f"({path} {text_id} in {panel_id} at {time:.6g}s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
