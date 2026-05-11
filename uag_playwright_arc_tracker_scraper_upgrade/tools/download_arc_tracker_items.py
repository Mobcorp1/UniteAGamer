#!/usr/bin/env python3
"""
UAG ARC Raiders non-blueprint asset pipeline — Playwright rendered scraper upgrade.

Run from project root:
  py tools/download_arc_tracker_items.py

Optional:
  py tools/download_arc_tracker_items.py --clean-unused
  py tools/download_arc_tracker_items.py --keep-browser-open
  py tools/download_arc_tracker_items.py --debug-screenshot

Outputs:
  assets/arc_raiders/items/*.webp
  assets/arc_raiders/items/arc_item_reference_manifest.json
  assets/arc_raiders/items/arctracker_rendered_catalogue.json
  assets/arc_raiders/items/arc_item_download_results.json
  assets/arc_raiders/items/missing_asset_report.json
  assets/arc_raiders/items/duplicate_asset_report.json
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
import shutil
import sys
import time
import urllib.parse
from dataclasses import asdict, dataclass
from io import BytesIO
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Tuple

import requests
from PIL import Image, ImageChops, ImageStat

CONFIG_PATH = Path(__file__).with_name("arc_asset_pipeline_config.json")

STOP_WORDS = {
    "the", "a", "an", "and", "of", "for", "to", "with", "item", "items", "arc", "raiders",
}

BAD_UI_WORDS = {
    "owned", "wanted", "missing", "all", "none", "search", "filter", "open", "close", "home",
    "maps", "settings", "discord", "privacy", "loading", "category", "rarity", "value", "weight",
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


def root() -> Path:
    return Path.cwd()


def slugify(value: str) -> str:
    value = value.strip().lower()
    value = value.replace("+", " plus ").replace("&", " and ")
    value = re.sub(r"['’]", "", value)
    value = re.sub(r"[^a-z0-9]+", "_", value)
    value = re.sub(r"_+", "_", value).strip("_")
    return value or "unknown_item"


def normalize(value: str) -> str:
    value = value.lower().strip()
    value = value.replace("+", " plus ").replace("&", " and ")
    value = re.sub(r"['’]", "", value)
    value = re.sub(r"\bmk\s*([ivx0-9]+)\b", r"mk\1", value)
    value = re.sub(r"\biii\b", "3", value)
    value = re.sub(r"\bii\b", "2", value)
    value = re.sub(r"\bi\b", "1", value)
    value = re.sub(r"[^a-z0-9]+", " ", value)
    parts = [p for p in value.split() if p not in STOP_WORDS]
    return " ".join(parts)


def raw_url(config: dict, rel_path: str) -> str:
    return config["repo_raw_base"].rstrip("/") + "/" + rel_path.lstrip("/")


def fetch_text(url: str) -> str:
    resp = requests.get(url, timeout=60, headers={"User-Agent": "UAGAssetPipeline/2.0"})
    resp.raise_for_status()
    return resp.text


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
        "industrial-battery": "industrial-batteries",
        "power-cable": "power-cables",
        "wire": "wires",
        "tick-pod": "tick-pods",
        "motor": "motors",
        "arc-powercell": "arc-powercells",
        "arc-motion-core": "arc-motion-cores",
        "sentinel-firing-core": "sentinel-firing-cores",
        "explosive-compound": "explosive-compounds",
        "pop-trigger": "pop-triggers",
        "rusted-gear": "rusted-gears",
    }
    return mapping.get(item_id, item_id)


def display_name_override(name: str, canonical_id: str) -> str:
    overrides = {
        "apricots": "Apricots", "lemons": "Lemons", "prickly-pears": "Prickly Pears",
        "very-comfortable-pillows": "Very Comfortable Pillows", "wasp-drivers": "Wasp Drivers",
        "hornet-drivers": "Hornet Drivers", "snitch-scanners": "Snitch Scanners",
        "leaper-pulse-units": "Leaper Pulse Units", "surveyor-vaults": "Surveyor Vaults",
        "fireball-burners": "Fireball Burners", "rocketeer-drivers": "Rocketeer Drivers",
        "bastion-cells": "Bastion Cells", "electrical-components": "Electrical Components",
        "mechanical-components": "Mechanical Components", "advanced-electrical-components": "Advanced Electrical Components",
        "advanced-mechanical-components": "Advanced Mechanical Components", "industrial-batteries": "Industrial Batteries",
        "power-cables": "Power Cables", "wires": "Wires", "tick-pods": "Tick Pods", "motors": "Motors",
        "arc-powercells": "ARC Powercells", "arc-motion-cores": "ARC Motion Cores",
        "sentinel-firing-cores": "Sentinel Firing Cores", "explosive-compounds": "Explosive Compounds",
        "pop-triggers": "Pop Triggers", "rusted-gears": "Rusted Gears",
    }
    return overrides.get(canonical_id, name)


def looks_like_item_name(name: str) -> bool:
    if not name or len(name) < 2 or len(name) > 90:
        return False
    n = normalize(name)
    if not n or n in BAD_UI_WORDS:
        return False
    if any(w in n.split() for w in BAD_UI_WORDS):
        return False
    return True


def extract_asset_paths(body: str) -> Tuple[str, ...]:
    return tuple(dict.fromkeys(re.findall(r"imageAsset\s*:\s*'([^']+)'", body)))


def extract_app_items_from_dart(text: str, source_file: str, config: dict) -> List[AppItem]:
    items: List[AppItem] = []
    seen: set[Tuple[str, str]] = set()
    skip_ids = set(config.get("skip_item_ids", []))

    def add_item(item_id: str, name: str, paths: Sequence[str], category: str) -> None:
        item_id = canonical_resource_id(item_id.strip())
        if item_id in skip_ids:
            return
        name = display_name_override(name.strip(), item_id)
        if not looks_like_item_name(name):
            return
        blocked = tuple(config.get("exclude_asset_paths_containing", []))
        clean_paths = tuple(p for p in paths if not any(b in p for b in blocked))
        if paths and not clean_paths:
            return
        key = (item_id, normalize(name))
        if key in seen:
            return
        items.append(AppItem(item_id, name, source_file, tuple(clean_paths), category))
        seen.add(key)

    for m in re.finditer(r"ArcScrappyItem\s*\((?P<body>.*?)\)\s*,", text, flags=re.DOTALL):
        body = m.group("body")
        id_m = re.search(r"\bid\s*:\s*'([^']+)'", body)
        name_m = re.search(r"\bname\s*:\s*'([^']+)'", body)
        cat_m = re.search(r"\bcategory\s*:\s*'([^']+)'", body)
        if id_m and name_m:
            add_item(id_m.group(1), name_m.group(1), extract_asset_paths(body), cat_m.group(1) if cat_m else "scrappy")

    for m in re.finditer(r"ArcBenchUpgradeRequirement\s*\((?P<body>.*?)\)", text, flags=re.DOTALL):
        body = m.group("body")
        id_m = re.search(r"\bitemId\s*:\s*'([^']+)'", body)
        name_m = re.search(r"\bitemName\s*:\s*'([^']+)'", body)
        station_m = re.search(r"\bstation\s*:\s*'([^']+)'", body)
        if id_m and name_m:
            cid = canonical_resource_id(id_m.group(1))
            path = f"assets/arc_raiders/scrappy_resources/{cid.replace('-', '_')}.webp"
            add_item(cid, name_m.group(1), (path,), station_m.group(1) if station_m else "bench")

    for m in re.finditer(r"ArcQuestRequirement\s*\((?P<body>.*?)\)", text, flags=re.DOTALL):
        body = m.group("body")
        id_m = re.search(r"\bitemId\s*:\s*'([^']+)'", body)
        name_m = re.search(r"\bitemName\s*:\s*'([^']+)'", body)
        trader_m = re.search(r"\btrader\s*:\s*'([^']+)'", body)
        if id_m and name_m:
            cid = canonical_resource_id(id_m.group(1))
            path = f"assets/arc_raiders/scrappy_resources/{cid.replace('-', '_')}.webp"
            add_item(cid, name_m.group(1), (path,), trader_m.group(1) if trader_m else "quest")

    for block in re.finditer(r"\((?P<body>[^()]{0,1400}?(?:id|itemId|value)\s*:\s*'[^']+'[^()]{0,1400}?)\)\s*,", text, flags=re.DOTALL):
        body = block.group("body")
        id_m = re.search(r"\b(?:id|itemId|value)\s*:\s*'([^']+)'", body)
        name_m = re.search(r"\b(?:name|itemName|label)\s*:\s*'([^']+)'", body)
        if id_m and name_m:
            name = name_m.group(1)
            if "blueprint" in body.lower() or "blueprint" in name.lower():
                continue
            path = f"assets/arc_raiders/items/{slugify(name)}.webp"
            add_item(id_m.group(1), name, extract_asset_paths(body) or (path,), "trade")

    return items


def dedupe_items(items: Iterable[AppItem]) -> List[AppItem]:
    merged: Dict[str, AppItem] = {}
    for item in items:
        key = normalize(item.name) or item.id
        if key not in merged:
            merged[key] = item
        else:
            old = merged[key]
            paths = tuple(dict.fromkeys(old.existing_asset_paths + item.existing_asset_paths))
            cats = sorted(set(old.category.split(",") + item.category.split(",")))
            merged[key] = AppItem(old.id, old.name, old.source_file, paths, ",".join(cats))
    return sorted(merged.values(), key=lambda x: (x.category, x.name.lower()))


def build_reference_manifest(config: dict) -> List[AppItem]:
    all_items: List[AppItem] = []
    errors = []
    for rel in config["project_data_files"]:
        url = raw_url(config, rel)
        try:
            text = fetch_text(url)
            all_items.extend(extract_app_items_from_dart(text, rel, config))
        except Exception as exc:
            errors.append({"file": rel, "url": url, "error": str(exc)})
    out = root() / config["output_main_folder"]
    out.mkdir(parents=True, exist_ok=True)
    if errors:
        (out / "github_fetch_errors.json").write_text(json.dumps(errors, indent=2), encoding="utf-8")
    return dedupe_items(all_items)


def clean_candidate_name(value: str) -> str:
    value = re.sub(r"\s+", " ", value or "").strip()
    if not value:
        return ""
    for splitter in ["\n", "Category", "Rarity", "Value", "Weight", "Recycles", "Used For", "Recycle", "Sell"]:
        if splitter in value:
            value = value.split(splitter, 1)[0].strip()
    value = value.strip(" -•|/")
    if len(value) > 80:
        words = value.split()
        value = " ".join(words[:8])
    if not looks_like_item_name(value):
        return ""
    return value


def scrape_arctracker_items(config: dict, keep_browser_open: bool = False, debug_screenshot: bool = False) -> Dict[str, dict]:
    try:
        from playwright.sync_api import TimeoutError as PlaywrightTimeoutError
        from playwright.sync_api import sync_playwright
    except ImportError as exc:
        print("Missing dependency: playwright")
        print("Run: py -m pip install playwright")
        print("Then: py -m playwright install chromium")
        raise exc

    out = root() / config["output_main_folder"]
    out.mkdir(parents=True, exist_ok=True)
    source_url = config["source_items_url"]
    print(f"Opening rendered ARCTracker item DB: {source_url}")

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=not keep_browser_open)
        context = browser.new_context(
            viewport={"width": 1920, "height": 2200},
            user_agent=(
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/124.0.0.0 Safari/537.36"
            ),
        )
        page = context.new_page()
        page.goto(source_url, wait_until="domcontentloaded", timeout=90000)
        try:
            page.wait_for_load_state("networkidle", timeout=60000)
        except PlaywrightTimeoutError:
            pass

        # Accept / close overlays where possible, safely.
        for text in ["Accept", "I Agree", "Got it", "Close", "OK"]:
            try:
                loc = page.get_by_text(text, exact=False).first
                if loc and loc.is_visible(timeout=700):
                    loc.click(timeout=1000)
                    page.wait_for_timeout(500)
            except Exception:
                pass

        # Wait for images, then scroll slowly to hydrate/lazy-load everything.
        page.wait_for_timeout(2500)
        last_height = 0
        stable_rounds = 0
        for _ in range(40):
            height = page.evaluate("() => document.documentElement.scrollHeight")
            page.evaluate("() => window.scrollBy(0, Math.floor(window.innerHeight * 0.85))")
            page.wait_for_timeout(650)
            new_height = page.evaluate("() => document.documentElement.scrollHeight")
            if new_height == last_height == height:
                stable_rounds += 1
            else:
                stable_rounds = 0
            last_height = new_height
            if stable_rounds >= 5:
                break
        page.evaluate("() => window.scrollTo(0, 0)")
        page.wait_for_timeout(1500)

        if debug_screenshot:
            try:
                page.screenshot(path=str(out / "arctracker_debug_page.png"), full_page=True)
            except Exception:
                pass

        html = page.content()
        (out / "arctracker_rendered_page.html").write_text(html, encoding="utf-8")

        raw_items = page.evaluate(
            r"""
            () => {
              function visible(el) {
                const r = el.getBoundingClientRect();
                const s = window.getComputedStyle(el);
                return r.width > 20 && r.height > 20 && s.display !== 'none' && s.visibility !== 'hidden';
              }
              function txt(el) {
                return (el && (el.innerText || el.textContent) || '').replace(/\s+/g, ' ').trim();
              }
              const out = [];
              const imgs = Array.from(document.querySelectorAll('img'));
              for (const img of imgs) {
                const src = img.currentSrc || img.src || img.getAttribute('src') || '';
                if (!src || src.startsWith('data:')) continue;
                if (!visible(img)) continue;
                const rect = img.getBoundingClientRect();
                let node = img;
                const candidates = [];
                const alt = img.getAttribute('alt') || '';
                const title = img.getAttribute('title') || '';
                if (alt) candidates.push(alt);
                if (title) candidates.push(title);
                for (let depth = 0; depth < 7 && node; depth++, node = node.parentElement) {
                  const label = node.getAttribute && (node.getAttribute('aria-label') || node.getAttribute('title'));
                  if (label) candidates.push(label);
                  const t = txt(node);
                  if (t && t.length < 260) candidates.push(t);
                  const headings = node.querySelectorAll ? Array.from(node.querySelectorAll('h1,h2,h3,h4,p,span,div')) : [];
                  for (const h of headings.slice(0, 24)) {
                    const ht = txt(h);
                    if (ht && ht.length <= 90) candidates.push(ht);
                  }
                }
                out.push({src, alt, title, candidates: Array.from(new Set(candidates)), width: rect.width, height: rect.height});
              }
              return out;
            }
            """
        )
        if keep_browser_open:
            print("Browser left open briefly for inspection...")
            time.sleep(30)
        context.close()
        browser.close()

    raw_dump = []
    catalogue: Dict[str, dict] = {}
    for row in raw_items:
        src = row.get("src") or ""
        if not src or src.startswith("data:"):
            continue
        abs_src = urllib.parse.urljoin(source_url, src)
        for candidate in row.get("candidates") or []:
            name = clean_candidate_name(candidate)
            if not name:
                continue
            key = normalize(name)
            if not key:
                continue
            entry = {"name": name, "src": abs_src, "raw": row}
            raw_dump.append({"name": name, "key": key, "src": abs_src, "width": row.get("width"), "height": row.get("height")})
            # Prefer larger images if duplicate name appears.
            score = float(row.get("width") or 0) * float(row.get("height") or 0)
            old = catalogue.get(key)
            old_score = old.get("score", 0) if old else -1
            if old is None or score > old_score:
                entry["score"] = score
                catalogue[key] = entry

    (out / "arctracker_rendered_catalogue.json").write_text(json.dumps(raw_dump, indent=2), encoding="utf-8")
    print(f"Rendered image/name candidates captured: {len(raw_dump)}")
    print(f"Unique normalized item names captured: {len(catalogue)}")
    return catalogue


def candidate_names_for_item(item: AppItem, config: dict) -> List[str]:
    names = [item.name, item.id.replace("-", " ")]
    for extra in config.get("manual_name_overrides", {}).get(item.id, []):
        names.insert(0, extra)
    # plural/singular variants
    expanded = []
    for n in names:
        expanded.append(n)
        if n.endswith("s"):
            expanded.append(n[:-1])
        else:
            expanded.append(n + "s")
    return list(dict.fromkeys(expanded))


def match_item(item: AppItem, catalogue: Dict[str, dict], config: dict) -> Optional[dict]:
    for name in candidate_names_for_item(item, config):
        key = normalize(name)
        if key in catalogue:
            return catalogue[key]

    target_keys = [normalize(n) for n in candidate_names_for_item(item, config)]
    target_token_sets = [set(k.split()) for k in target_keys if k]
    best = None
    best_score = 0.0
    for key, data in catalogue.items():
        source_tokens = set(key.split())
        if not source_tokens:
            continue
        for target_tokens in target_token_sets:
            if not target_tokens:
                continue
            intersection = target_tokens & source_tokens
            score = len(intersection) / max(len(target_tokens), len(source_tokens))
            if score > best_score:
                best = data
                best_score = score
    if best_score >= 0.82:
        return best
    return None


def download_image(url: str) -> Image.Image:
    resp = requests.get(url, timeout=75, headers={"User-Agent": "Mozilla/5.0 UAGAssetPipeline/2.0"})
    resp.raise_for_status()
    return Image.open(BytesIO(resp.content)).convert("RGBA")


def trim_transparent(img: Image.Image) -> Image.Image:
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    alpha = img.getchannel("A")
    bbox = alpha.getbbox()
    if bbox:
        return img.crop(bbox)
    return img


def trim_solid_edges(img: Image.Image, tolerance: int = 10) -> Image.Image:
    """Trim fully solid transparent-ish/flat borders while keeping item card background."""
    img = img.convert("RGBA")
    w, h = img.size
    if w < 8 or h < 8:
        return img
    # If transparent, trim that first.
    img = trim_transparent(img)
    w, h = img.size
    px = img.load()
    def similar(c1, c2):
        return sum(abs(c1[i] - c2[i]) for i in range(4)) <= tolerance * 4
    bg = px[0, 0]
    left = 0
    while left < w - 1 and all(similar(px[left, y], bg) for y in range(0, h, max(1, h // 32))):
        left += 1
    right = w - 1
    while right > left and all(similar(px[right, y], bg) for y in range(0, h, max(1, h // 32))):
        right -= 1
    top = 0
    while top < h - 1 and all(similar(px[x, top], bg) for x in range(0, w, max(1, w // 32))):
        top += 1
    bottom = h - 1
    while bottom > top and all(similar(px[x, bottom], bg) for x in range(0, w, max(1, w // 32))):
        bottom -= 1
    if right - left > 8 and bottom - top > 8:
        return img.crop((max(0, left - 1), max(0, top - 1), min(w, right + 2), min(h, bottom + 2)))
    return img


def crop_and_fit(img: Image.Image, config: dict) -> Image.Image:
    img = img.convert("RGBA")
    keep_background = bool(config.get("keep_background", True))
    crop_percent = float(config.get("border_crop_percent", 0.045))
    final_size = int(config.get("final_canvas_size", 512))
    fill_ratio = float(config.get("object_fill_ratio", 0.88))

    img = trim_transparent(img)
    w, h = img.size
    if crop_percent > 0 and w > 20 and h > 20:
        ix = int(w * crop_percent)
        iy = int(h * crop_percent)
        if ix * 2 < w and iy * 2 < h:
            img = img.crop((ix, iy, w - ix, h - iy))

    if not keep_background:
        img = trim_solid_edges(trim_transparent(img))

    w, h = img.size
    side = max(w, h)
    square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    square.alpha_composite(img, ((side - w) // 2, (side - h) // 2))

    # Fit to requested fill ratio so tiny items don't stay tiny.
    target_inner = max(1, int(final_size * fill_ratio))
    square = square.resize((target_inner, target_inner), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (final_size, final_size), (0, 0, 0, 0))
    canvas.alpha_composite(square, ((final_size - target_inner) // 2, (final_size - target_inner) // 2))
    return canvas


def backup_existing(path: Path, backup_root: Path, base_root: Path) -> None:
    if not path.exists():
        return
    rel = path.relative_to(base_root)
    dest = backup_root / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    if not dest.exists():
        shutil.copy2(path, dest)


def write_webp(img: Image.Image, dest: Path, quality: int) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    img.save(dest, "WEBP", quality=quality, method=6)


def run(clean_unused: bool, keep_browser_open: bool, debug_screenshot: bool) -> int:
    config = load_config()
    base = root()
    out = base / config["output_main_folder"]
    backup = base / config["backup_folder"]
    out.mkdir(parents=True, exist_ok=True)
    backup.mkdir(parents=True, exist_ok=True)

    print("Building exact item manifest from GitHub repo data...")
    app_items = build_reference_manifest(config)
    (out / "arc_item_reference_manifest.json").write_text(json.dumps([asdict(i) for i in app_items], indent=2), encoding="utf-8")
    print(f"Reference items found: {len(app_items)}")

    print("Scraping ARCTracker via rendered browser page...")
    catalogue = scrape_arctracker_items(config, keep_browser_open=keep_browser_open, debug_screenshot=debug_screenshot)

    results: List[DownloadResult] = []
    hashes: Dict[str, List[str]] = {}

    for item in app_items:
        filename = f"{slugify(item.name)}.webp"
        main_rel = f"{config['output_main_folder'].rstrip('/')}/{filename}"
        main_dest = base / main_rel
        matched = match_item(item, catalogue, config)
        if not matched:
            results.append(DownloadResult(item.id, item.name, None, None, main_rel, [], "missing", "No safe exact/fuzzy match found on rendered ARCTracker catalogue."))
            print(f"MISS {filename} <- {item.name}")
            continue
        try:
            source_img = download_image(matched["src"])
            processed = crop_and_fit(source_img, config)
            backup_existing(main_dest, backup, base)
            write_webp(processed, main_dest, int(config.get("webp_quality", 92)))
            mirrored_paths: List[str] = []
            if config.get("mirror_to_existing_asset_paths", True):
                for rel_path in item.existing_asset_paths:
                    if not rel_path or rel_path == main_rel:
                        continue
                    if any(blocked in rel_path for blocked in config.get("exclude_asset_paths_containing", [])):
                        continue
                    dest = base / rel_path
                    backup_existing(dest, backup, base)
                    write_webp(processed, dest, int(config.get("webp_quality", 92)))
                    mirrored_paths.append(rel_path)
            digest = hashlib.sha256(main_dest.read_bytes()).hexdigest()
            hashes.setdefault(digest, []).append(main_rel)
            results.append(DownloadResult(item.id, item.name, matched["name"], matched["src"], main_rel, mirrored_paths, "ok"))
            print(f"OK   {filename} <- {item.name} :: matched {matched['name']}")
        except Exception as exc:
            results.append(DownloadResult(item.id, item.name, matched.get("name"), matched.get("src"), main_rel, [], "failed", str(exc)))
            print(f"FAIL {filename} <- {item.name} :: {exc}")

    ok = [r for r in results if r.status == "ok"]
    missing = [r for r in results if r.status == "missing"]
    failed = [r for r in results if r.status == "failed"]
    duplicates = {h: paths for h, paths in hashes.items() if len(paths) > 1}

    (out / "arc_item_download_results.json").write_text(json.dumps([asdict(r) for r in results], indent=2), encoding="utf-8")
    (out / "missing_asset_report.json").write_text(json.dumps([asdict(r) for r in missing + failed], indent=2), encoding="utf-8")
    (out / "duplicate_asset_report.json").write_text(json.dumps(duplicates, indent=2), encoding="utf-8")

    if clean_unused:
        keep = {Path(r.main_asset_path) for r in ok}
        for r in ok:
            keep.update(Path(p) for p in r.mirrored_paths)
        removed = []
        for folder_rel in [config["output_main_folder"], "assets/arc_raiders/scrappy_resources"]:
            folder = base / folder_rel
            if not folder.exists():
                continue
            for file in folder.glob("*.webp"):
                rel = file.relative_to(base)
                if rel not in keep:
                    backup_existing(file, backup, base)
                    file.unlink()
                    removed.append(str(rel).replace("\\", "/"))
        (out / "clean_unused_removed_files.json").write_text(json.dumps(removed, indent=2), encoding="utf-8")
        print(f"Cleaned unused WebP files: {len(removed)}")

    print("\nSUMMARY")
    print(f"  OK: {len(ok)}")
    print(f"  Missing: {len(missing)}")
    print(f"  Failed: {len(failed)}")
    print(f"  Reports: {out}")
    return 0 if not failed else 2


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--clean-unused", action="store_true", help="Back up then remove unused old WebP files from item folders.")
    parser.add_argument("--keep-browser-open", action="store_true", help="Open visible Chromium and keep it briefly for debugging.")
    parser.add_argument("--debug-screenshot", action="store_true", help="Save arctracker_debug_page.png for troubleshooting.")
    args = parser.parse_args()
    raise SystemExit(run(args.clean_unused, args.keep_browser_open, args.debug_screenshot))


if __name__ == "__main__":
    main()
