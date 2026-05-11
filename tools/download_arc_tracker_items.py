#!/usr/bin/env python3
"""
UAG ARC Raiders non-blueprint asset pipeline.

What it does:
- Uses the live GitHub repo raw files as the reference source of truth.
- Extracts exact item IDs, names and existing imageAsset paths from Scrappy, Bench, Quest and Trading data files.
- Opens https://arctracker.io/items in a real browser using Playwright so the JS-loaded item database is visible.
- Builds a title -> image URL catalogue from the rendered page.
- Matches exact app item names first, then safe normalized fallback matches.
- Downloads real ARCTracker item images.
- Crops inside the visible frame/border while keeping/baking a dark item-card background.
- Converts to WebP.
- Saves to assets/arc_raiders/items and mirrors to existing app asset paths such as assets/arc_raiders/scrappy_resources.
- Writes manifest and missing/duplicate reports.

Run from project root:
  py tools/download_arc_tracker_items.py

Optional:
  py tools/download_arc_tracker_items.py --clean-unused
  py tools/download_arc_tracker_items.py --keep-browser-open
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import sys
import time
import urllib.parse
from dataclasses import dataclass, asdict
from io import BytesIO
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple

try:
    import requests
except ImportError:
    print("Missing dependency: requests. Run: py -m pip install requests pillow playwright beautifulsoup4")
    raise

try:
    from PIL import Image, ImageChops
except ImportError:
    print("Missing dependency: pillow. Run: py -m pip install requests pillow playwright beautifulsoup4")
    raise

CONFIG_PATH = Path(__file__).with_name("arc_asset_pipeline_config.json")

STOP_WORDS = {
    "the", "a", "an", "and", "of", "for", "to", "with", "item", "items", "arc", "raiders",
}

@dataclass(frozen=True)
class AppItem:
    id: str
    name: str
    source_file: str
    existing_asset_paths: Tuple[str, ...]
    category: str = "unknown"

@dataclass
class DownloadResult:
    id: str
    name: str
    matched_name: Optional[str]
    source_url: Optional[str]
    main_asset_path: str
    mirrored_paths: List[str]
    status: str
    reason: str = ""


def load_config() -> dict:
    if not CONFIG_PATH.exists():
        raise FileNotFoundError(f"Missing config: {CONFIG_PATH}")
    return json.loads(CONFIG_PATH.read_text(encoding="utf-8"))


def project_root() -> Path:
    return Path.cwd()


def slugify(value: str) -> str:
    value = value.strip().lower()
    value = value.replace("+", " plus ")
    value = value.replace("&", " and ")
    value = re.sub(r"['’]", "", value)
    value = re.sub(r"[^a-z0-9]+", "_", value)
    value = re.sub(r"_+", "_", value).strip("_")
    return value or "unknown_item"


def normalize(value: str) -> str:
    value = value.lower().strip()
    value = value.replace("+", " plus ")
    value = value.replace("&", " and ")
    value = re.sub(r"['’]", "", value)
    value = re.sub(r"\bmk\s*([ivx0-9]+)\b", r"mk\1", value)
    value = re.sub(r"[^a-z0-9]+", " ", value)
    parts = [p for p in value.split() if p not in STOP_WORDS]
    return " ".join(parts)


def raw_url(config: dict, rel_path: str) -> str:
    return config["repo_raw_base"].rstrip("/") + "/" + rel_path.lstrip("/")


def fetch_text(url: str) -> str:
    resp = requests.get(url, timeout=45, headers={"User-Agent": "UAGAssetPipeline/1.0"})
    resp.raise_for_status()
    return resp.text


def extract_existing_asset_paths(text: str, start: int, end: int) -> Tuple[str, ...]:
    chunk = text[start:end]
    paths = re.findall(r"imageAsset\s*:\s*'([^']+)'", chunk)
    return tuple(dict.fromkeys(paths))


def extract_app_items_from_dart(text: str, source_file: str, config: dict) -> List[AppItem]:
    items: List[AppItem] = []
    seen: set[Tuple[str, str]] = set()

    # ArcScrappyItem blocks: id/name/imageAsset are explicit.
    for m in re.finditer(
        r"ArcScrappyItem\s*\((?P<body>.*?)\)\s*,",
        text,
        flags=re.DOTALL,
    ):
        body = m.group("body")
        id_m = re.search(r"\bid\s*:\s*'([^']+)'", body)
        name_m = re.search(r"\bname\s*:\s*'([^']+)'", body)
        cat_m = re.search(r"\bcategory\s*:\s*'([^']+)'", body)
        paths = tuple(re.findall(r"imageAsset\s*:\s*'([^']+)'", body))
        if id_m and name_m:
            item_id = id_m.group(1)
            name = name_m.group(1)
            key = (item_id, name)
            if key not in seen:
                items.append(AppItem(item_id, name, source_file, paths, cat_m.group(1) if cat_m else "scrappy"))
                seen.add(key)

    # Bench requirements.
    for m in re.finditer(
        r"ArcBenchUpgradeRequirement\s*\((?P<body>.*?)\)",
        text,
        flags=re.DOTALL,
    ):
        body = m.group("body")
        id_m = re.search(r"\bitemId\s*:\s*'([^']+)'", body)
        name_m = re.search(r"\bitemName\s*:\s*'([^']+)'", body)
        station_m = re.search(r"\bstation\s*:\s*'([^']+)'", body)
        if id_m and name_m:
            canonical_id = canonical_resource_id(id_m.group(1))
            item_id = canonical_id
            name = plural_display_name(name_m.group(1), canonical_id)
            asset_path = f"assets/arc_raiders/scrappy_resources/{canonical_id.replace('-', '_')}.webp"
            key = (item_id, name)
            if key not in seen:
                items.append(AppItem(item_id, name, source_file, (asset_path,), station_m.group(1) if station_m else "bench"))
                seen.add(key)

    # Quest requirements.
    for m in re.finditer(
        r"ArcQuestRequirement\s*\((?P<body>.*?)\)",
        text,
        flags=re.DOTALL,
    ):
        body = m.group("body")
        id_m = re.search(r"\bitemId\s*:\s*'([^']+)'", body)
        name_m = re.search(r"\bitemName\s*:\s*'([^']+)'", body)
        trader_m = re.search(r"\btrader\s*:\s*'([^']+)'", body)
        if id_m and name_m:
            canonical_id = canonical_resource_id(id_m.group(1))
            name = plural_display_name(name_m.group(1), canonical_id)
            asset_path = f"assets/arc_raiders/scrappy_resources/{canonical_id.replace('-', '_')}.webp"
            key = (canonical_id, name)
            if key not in seen:
                items.append(AppItem(canonical_id, name, source_file, (asset_path,), trader_m.group(1) if trader_m else "quest"))
                seen.add(key)

    # Generic data model patterns used by trade catalog files.
    generic_patterns = [
        (r"\bid\s*:\s*'([^']+)'", r"\bname\s*:\s*'([^']+)'"),
        (r"\bitemId\s*:\s*'([^']+)'", r"\bitemName\s*:\s*'([^']+)'"),
        (r"\bvalue\s*:\s*'([^']+)'", r"\blabel\s*:\s*'([^']+)'"),
    ]
    for id_pat, name_pat in generic_patterns:
        for id_m in re.finditer(id_pat, text):
            search_window = text[id_m.start(): id_m.start() + 800]
            name_m = re.search(name_pat, search_window)
            if not name_m:
                continue
            item_id = canonical_resource_id(id_m.group(1))
            name = plural_display_name(name_m.group(1), item_id)
            if not looks_like_item_name(name):
                continue
            asset_path = f"assets/arc_raiders/items/{slugify(name)}.webp"
            key = (item_id, name)
            if key not in seen:
                items.append(AppItem(item_id, name, source_file, (asset_path,), "trade"))
                seen.add(key)

    # Filter blueprint paths out for this pass.
    blocked = tuple(config.get("exclude_asset_paths_containing", []))
    filtered: List[AppItem] = []
    for item in items:
        paths = tuple(p for p in item.existing_asset_paths if not any(b in p for b in blocked))
        if item.existing_asset_paths and not paths:
            continue
        filtered.append(AppItem(item.id, item.name, item.source_file, paths, item.category))
    return filtered


def canonical_resource_id(item_id: str) -> str:
    mapping = {
        "apricot": "apricots",
        "lemon": "lemons",
        "prickly-pear": "prickly-pears",
        "very-comfortable-pillow": "very-comfortable-pillows",
        "wasp-driver": "wasp-drivers",
        "hornet-driver": "hornet-drivers",
        "snitch-scanner": "snitch-scanners",
        "leaper-pulse-unit": "leaper-pulse-units",
        "surveyor-vault": "surveyor-vaults",
        "fireball-burner": "fireball-burners",
        "rocketeer-driver": "rocketeer-drivers",
        "bastion-cell": "bastion-cells",
        "electrical-component": "electrical-components",
        "mechanical-component": "mechanical-components",
        "advanced-electrical-component": "advanced-electrical-components",
        "advanced-mechanical-component": "advanced-mechanical-components",
        "wire": "wires",
    }
    return mapping.get(item_id, item_id)


def plural_display_name(name: str, canonical_id: str) -> str:
    overrides = {
        "apricots": "Apricots",
        "lemons": "Lemons",
        "prickly-pears": "Prickly Pears",
        "very-comfortable-pillows": "Very Comfortable Pillows",
        "wasp-drivers": "Wasp Drivers",
        "hornet-drivers": "Hornet Drivers",
        "snitch-scanners": "Snitch Scanners",
        "leaper-pulse-units": "Leaper Pulse Units",
        "surveyor-vaults": "Surveyor Vaults",
        "fireball-burners": "Fireball Burners",
        "rocketeer-drivers": "Rocketeer Drivers",
        "bastion-cells": "Bastion Cells",
        "electrical-components": "Electrical Components",
        "mechanical-components": "Mechanical Components",
        "advanced-electrical-components": "Advanced Electrical Components",
        "advanced-mechanical-components": "Advanced Mechanical Components",
        "wires": "Wires",
    }
    return overrides.get(canonical_id, name)


def looks_like_item_name(name: str) -> bool:
    if not name or len(name) < 2:
        return False
    bad = {"Owned", "Wanted", "Missing", "All", "None", "Search", "Filter", "Open", "Close"}
    return name not in bad


def dedupe_items(items: Iterable[AppItem]) -> List[AppItem]:
    merged: Dict[str, AppItem] = {}
    for item in items:
        key = normalize(item.name) or item.id
        if key not in merged:
            merged[key] = item
        else:
            old = merged[key]
            paths = tuple(dict.fromkeys(old.existing_asset_paths + item.existing_asset_paths))
            categories = old.category if item.category in old.category else f"{old.category},{item.category}"
            merged[key] = AppItem(old.id, old.name, old.source_file, paths, categories)
    return sorted(merged.values(), key=lambda x: (x.category, x.name.lower()))


def build_reference_manifest(config: dict) -> List[AppItem]:
    items: List[AppItem] = []
    errors = []
    for rel in config["project_data_files"]:
        url = raw_url(config, rel)
        try:
            text = fetch_text(url)
        except Exception as exc:
            errors.append({"file": rel, "url": url, "error": str(exc)})
            continue
        items.extend(extract_app_items_from_dart(text, rel, config))
    final_items = dedupe_items(items)
    if errors:
        Path("assets/arc_raiders/items").mkdir(parents=True, exist_ok=True)
        Path("assets/arc_raiders/items/github_fetch_errors.json").write_text(json.dumps(errors, indent=2), encoding="utf-8")
    return final_items


def scrape_arctracker_items(config: dict, keep_browser_open: bool = False) -> Dict[str, dict]:
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print("Missing dependency: playwright. Run:")
        print("  py -m pip install playwright")
        print("  py -m playwright install chromium")
        raise

    source_url = config["source_items_url"]
    print(f"Opening rendered item page: {source_url}")
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=not keep_browser_open)
        page = browser.new_page(viewport={"width": 1600, "height": 2200}, user_agent="Mozilla/5.0 UAGAssetPipeline")
        page.goto(source_url, wait_until="networkidle", timeout=90000)
        page.wait_for_timeout(4000)
        # Try to force all lazy-loaded images to resolve.
        for _ in range(12):
            page.mouse.wheel(0, 2000)
            page.wait_for_timeout(700)
        page.mouse.wheel(0, -999999)
        page.wait_for_timeout(1000)

        items = page.evaluate(
            """
            () => {
              const results = [];
              const imageEls = Array.from(document.querySelectorAll('img'));
              for (const img of imageEls) {
                const src = img.currentSrc || img.src || img.getAttribute('src') || '';
                if (!src) continue;
                const card = img.closest('a, article, li, div');
                let text = '';
                let el = img;
                for (let i = 0; i < 5 && el; i++, el = el.parentElement) {
                  const t = (el.innerText || '').trim();
                  if (t && t.length > text.length && t.length < 240) text = t;
                }
                const alt = img.getAttribute('alt') || img.getAttribute('title') || '';
                const aria = card ? (card.getAttribute('aria-label') || card.getAttribute('title') || '') : '';
                const nameCandidates = [alt, aria, text]
                  .map(x => (x || '').replace(/\s+/g, ' ').trim())
                  .filter(Boolean);
                results.push({ src, alt, aria, text, nameCandidates });
              }
              return results;
            }
            """
        )
        html = page.content()
        if keep_browser_open:
            print("Browser kept open for inspection. Close it manually when done.")
            time.sleep(20)
        browser.close()

    catalogue: Dict[str, dict] = {}
    raw_dump = []
    for row in items:
        src = row.get("src") or ""
        if not src or src.startswith("data:"):
            continue
        candidates = row.get("nameCandidates") or []
        for c in candidates:
            # Keep the first clean line as the likely name.
            name = clean_candidate_name(c)
            if not name:
                continue
            key = normalize(name)
            if not key:
                continue
            resolved = urllib.parse.urljoin(source_url, src)
            raw_dump.append({"name": name, "key": key, "src": resolved, "raw": row})
            if key not in catalogue:
                catalogue[key] = {"name": name, "src": resolved, "candidates": candidates}
    out = Path("assets/arc_raiders/items")
    out.mkdir(parents=True, exist_ok=True)
    (out / "arctracker_raw_image_catalogue.json").write_text(json.dumps(raw_dump, indent=2), encoding="utf-8")
    (out / "arctracker_rendered_page.html").write_text(html, encoding="utf-8")
    return catalogue


def clean_candidate_name(value: str) -> str:
    value = re.sub(r"\s+", " ", value).strip()
    if not value:
        return ""
    # Card text often includes stats/categories. Take first meaningful line/sentence chunk.
    splitters = ["\n", "Category", "Rarity", "Value", "Weight", "Recycles", "Used For"]
    for splitter in splitters:
        if splitter in value:
            value = value.split(splitter, 1)[0].strip()
    value = value.strip(" -•|/")
    if len(value) > 64:
        parts = value.split(" ")
        value = " ".join(parts[:6])
    if re.search(r"loading|language|settings|privacy|discord|home|maps", value, re.I):
        return ""
    return value


def match_item(item: AppItem, catalogue: Dict[str, dict]) -> Optional[dict]:
    keys = [normalize(item.name), normalize(item.id.replace("-", " "))]
    keys += [normalize(item.name.rstrip("s")), normalize(item.name + "s")]
    for key in keys:
        if key in catalogue:
            return catalogue[key]
    # Token containment fallback, strict enough to avoid made-up matches.
    target_tokens = set(normalize(item.name).split())
    if not target_tokens:
        return None
    best = None
    best_score = 0.0
    for key, data in catalogue.items():
        source_tokens = set(key.split())
        if not source_tokens:
            continue
        intersection = target_tokens & source_tokens
        score = len(intersection) / max(len(target_tokens), len(source_tokens))
        if score > best_score:
            best = data
            best_score = score
    if best_score >= 0.84:
        return best
    return None


def download_image(url: str) -> Image.Image:
    resp = requests.get(url, timeout=60, headers={"User-Agent": "Mozilla/5.0 UAGAssetPipeline"})
    resp.raise_for_status()
    return Image.open(BytesIO(resp.content)).convert("RGBA")


def trim_transparent(img: Image.Image) -> Image.Image:
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    alpha = img.getchannel("A")
    bbox = alpha.getbbox()
    if bbox:
        return img.crop(bbox)
    bg = Image.new(img.mode, img.size, img.getpixel((0, 0)))
    diff = ImageChops.difference(img, bg)
    bbox = diff.getbbox()
    return img.crop(bbox) if bbox else img


def make_arc_panel(size: int, bg: Tuple[int, int, int, int], grid: Tuple[int, int, int, int]) -> Image.Image:
    """Create a subtle dark ARC-style square background for assets whose source is transparent."""
    panel = Image.new("RGBA", (size, size), bg)
    pixels = panel.load()
    # Soft blueprint/grid lines, intentionally subtle so item art stays dominant.
    spacing = max(32, size // 8)
    for x in range(0, size, spacing):
        for y in range(size):
            r, g, b, a = pixels[x, y]
            pixels[x, y] = (min(255, r + grid[0]), min(255, g + grid[1]), min(255, b + grid[2]), 255)
    for y in range(0, size, spacing):
        for x in range(size):
            r, g, b, a = pixels[x, y]
            pixels[x, y] = (min(255, r + grid[0]), min(255, g + grid[1]), min(255, b + grid[2]), 255)
    return panel


def has_meaningful_background(img: Image.Image) -> bool:
    """True when the source crop already has an opaque/card background worth keeping."""
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    alpha = img.getchannel("A")
    total = img.size[0] * img.size[1]
    opaque = sum(1 for value in alpha.getdata() if value > 245)
    return (opaque / max(total, 1)) > 0.82


def crop_inside_frame(img: Image.Image, crop_percent: float, canvas_size: int, config: Optional[dict] = None) -> Image.Image:
    """
    Crop inside the visible item-card frame, but DO NOT trim the card/background away.
    The previous version trimmed transparency after crop, which produced blank-looking assets.
    This version keeps the source card background when present and bakes a dark ARC panel
    behind transparent item images when the site serves icon-only transparency.
    """
    config = config or {}
    if img.mode != "RGBA":
        img = img.convert("RGBA")

    w, h = img.size
    inset_x = int(w * crop_percent)
    inset_y = int(h * crop_percent)
    if inset_x * 2 < w and inset_y * 2 < h:
        img = img.crop((inset_x, inset_y, w - inset_x, h - inset_y))

    # Square the crop without trimming the actual background away.
    w, h = img.size
    side = max(w, h)
    bg_color = tuple(config.get("fallback_background_rgba", [9, 18, 35, 255]))
    grid_color = tuple(config.get("fallback_grid_boost_rgb", [8, 18, 30, 0]))

    if has_meaningful_background(img):
        square = Image.new("RGBA", (side, side), bg_color)
    else:
        square = make_arc_panel(side, bg_color, grid_color)

    square.alpha_composite(img, ((side - w) // 2, (side - h) // 2))
    square = square.resize((canvas_size, canvas_size), Image.Resampling.LANCZOS)
    return square


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def backup_existing(path: Path, backup_root: Path, root: Path) -> None:
    if not path.exists():
        return
    rel = path.relative_to(root)
    dest = backup_root / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    if not dest.exists():
        shutil.copy2(path, dest)


def write_webp(img: Image.Image, dest: Path, quality: int) -> None:
    ensure_parent(dest)
    img.save(dest, "WEBP", quality=quality, method=6)


def run(clean_unused: bool = False, keep_browser_open: bool = False) -> int:
    config = load_config()
    root = project_root()
    out_main = root / config["output_main_folder"]
    backup_root = root / config["backup_folder"]
    out_main.mkdir(parents=True, exist_ok=True)
    backup_root.mkdir(parents=True, exist_ok=True)

    print("Building exact item manifest from GitHub repo data...")
    app_items = build_reference_manifest(config)
    reference_json = [asdict(item) for item in app_items]
    (out_main / "arc_item_reference_manifest.json").write_text(json.dumps(reference_json, indent=2), encoding="utf-8")
    print(f"Reference items found: {len(app_items)}")

    print("Scraping ARCTracker rendered item catalogue...")
    catalogue = scrape_arctracker_items(config, keep_browser_open=keep_browser_open)
    print(f"ARCTracker image candidates found: {len(catalogue)}")

    results: List[DownloadResult] = []
    hashes: Dict[str, List[str]] = {}

    for item in app_items:
        main_filename = f"{slugify(item.name)}.webp"
        main_rel = f"{config['output_main_folder'].rstrip('/')}/{main_filename}"
        main_dest = root / main_rel
        mirrored: List[str] = []
        matched = match_item(item, catalogue)
        if not matched:
            results.append(DownloadResult(item.id, item.name, None, None, main_rel, [], "missing", "No safe exact/fuzzy match found on ARCTracker."))
            print(f"MISS {main_filename} <- {item.name}")
            continue
        try:
            img = download_image(matched["src"])
            processed = crop_inside_frame(
                img,
                float(config.get("border_crop_percent", 0.10)),
                int(config.get("final_canvas_size", 512)),
                config,
            )
            backup_existing(main_dest, backup_root, root)
            write_webp(processed, main_dest, int(config.get("webp_quality", 92)))
            mirrored_paths = []
            if config.get("mirror_to_existing_asset_paths", True):
                for rel_path in item.existing_asset_paths:
                    if not rel_path or rel_path == main_rel:
                        continue
                    if any(blocked in rel_path for blocked in config.get("exclude_asset_paths_containing", [])):
                        continue
                    dest = root / rel_path
                    backup_existing(dest, backup_root, root)
                    write_webp(processed, dest, int(config.get("webp_quality", 92)))
                    mirrored_paths.append(rel_path)
            file_hash = hashlib.sha256(main_dest.read_bytes()).hexdigest()
            hashes.setdefault(file_hash, []).append(main_rel)
            results.append(DownloadResult(item.id, item.name, matched["name"], matched["src"], main_rel, mirrored_paths, "ok"))
            print(f"OK   {main_filename} <- {item.name} :: matched {matched['name']}")
        except Exception as exc:
            results.append(DownloadResult(item.id, item.name, matched.get("name"), matched.get("src"), main_rel, [], "failed", str(exc)))
            print(f"FAIL {main_filename} <- {item.name} :: {exc}")

    ok = [r for r in results if r.status == "ok"]
    missing = [r for r in results if r.status == "missing"]
    failed = [r for r in results if r.status == "failed"]
    duplicates = {h: paths for h, paths in hashes.items() if len(paths) > 1}

    (out_main / "arc_item_download_results.json").write_text(json.dumps([asdict(r) for r in results], indent=2), encoding="utf-8")
    (out_main / "missing_asset_report.json").write_text(json.dumps([asdict(r) for r in missing + failed], indent=2), encoding="utf-8")
    (out_main / "duplicate_asset_report.json").write_text(json.dumps(duplicates, indent=2), encoding="utf-8")

    if clean_unused:
        keep = {Path(r.main_asset_path) for r in ok}
        for r in ok:
            keep.update(Path(p) for p in r.mirrored_paths)
        removed = []
        for folder in [out_main, root / "assets/arc_raiders/scrappy_resources"]:
            if not folder.exists():
                continue
            for file in folder.glob("*.webp"):
                rel = file.relative_to(root)
                if rel not in keep:
                    backup_existing(file, backup_root, root)
                    file.unlink()
                    removed.append(str(rel))
        (out_main / "clean_unused_removed_files.json").write_text(json.dumps(removed, indent=2), encoding="utf-8")
        print(f"Cleaned unused WebP files: {len(removed)}")

    print("\nSUMMARY")
    print(f"  OK: {len(ok)}")
    print(f"  Missing: {len(missing)}")
    print(f"  Failed: {len(failed)}")
    print(f"  Reports: {out_main}")
    return 0 if not failed else 2


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--clean-unused", action="store_true", help="Back up then remove unused old WebP files from item folders.")
    parser.add_argument("--keep-browser-open", action="store_true", help="Keep browser visible briefly for debugging.")
    args = parser.parse_args()
    raise SystemExit(run(clean_unused=args.clean_unused, keep_browser_open=args.keep_browser_open))


if __name__ == "__main__":
    main()
