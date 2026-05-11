#!/usr/bin/env python3
"""
UAG ARC Raiders multi-source non-blueprint asset pipeline.

Run from project root:
  py tools/download_arc_multi_source_assets.py

What this does:
- Reads the live UAG GitHub repo Dart data files as the source of truth.
- Builds an exact manifest for Scrappy, Bench, Quest and Trading Hub item assets.
- Checks local manual overrides first.
- Scrapes multiple web sources for item images:
    1) ARCTracker item database
    2) ARC Raiders Fandom item page
    3) thearcraiders.wiki/items
    4) ArcRaidersHub needed-items/recycling guide
- Downloads matched item images.
- Crops/normalises them.
- Converts everything to .webp.
- Saves to assets/arc_raiders/items and mirrors to existing repo asset paths.
- Writes detailed reports.

Optional:
  py tools/download_arc_multi_source_assets.py --clean-unused
  py tools/download_arc_multi_source_assets.py --keep-browser-open
  py tools/download_arc_multi_source_assets.py --debug
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

import requests
from bs4 import BeautifulSoup
from PIL import Image, ImageChops, ImageOps, ImageDraw, ImageFont

CONFIG_PATH = Path(__file__).with_name("arc_multi_source_asset_config.json")

STOP_WORDS = {
    "the", "a", "an", "and", "of", "for", "to", "with", "item", "items", "arc", "raiders",
    "wiki", "database", "guide", "loot", "source", "sources", "used", "uses", "recycles", "recycling",
}
BAD_IMAGE_HINTS = (
    "logo", "favicon", "sprite", "discord", "youtube", "twitter", "x.com", "facebook", "instagram",
    "blank", "placeholder", "avatar", "icon-search", "loading", "ads", "tracking", "banner",
)

@dataclass(frozen=True)
class AppItem:
    id: str
    name: str
    source_file: str
    existing_asset_paths: Tuple[str, ...]
    category: str = "unknown"

@dataclass
class Candidate:
    source_id: str
    name: str
    image_url: str
    page_url: str
    score_hint: float = 1.0

@dataclass
class DownloadResult:
    id: str
    name: str
    matched_name: Optional[str]
    matched_source: Optional[str]
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
    value = value.replace("+", " plus ")
    value = value.replace("&", " and ")
    value = re.sub(r"['’]", "", value)
    value = re.sub(r"[^a-z0-9]+", "_", value)
    return re.sub(r"_+", "_", value).strip("_") or "unknown_item"


def dash_id(value: str) -> str:
    return slugify(value).replace("_", "-")


def normalize(value: str) -> str:
    value = value.lower().strip()
    value = value.replace("+", " plus ")
    value = value.replace("&", " and ")
    value = value.replace("mk.", "mk")
    value = re.sub(r"['’]", "", value)
    value = re.sub(r"\bmk\s*([ivx0-9]+)\b", r"mk\1", value)
    value = re.sub(r"\bmark\s*([ivx0-9]+)\b", r"mk\1", value)
    value = re.sub(r"[^a-z0-9]+", " ", value)
    parts = [p for p in value.split() if p not in STOP_WORDS]
    return " ".join(parts)


def canonical_resource_id(item_id: str) -> str:
    mapping = {
        "apricot": "apricots",
        "lemon": "lemons",
        "olive": "olives",
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
        "motor": "motors",
        "toaster": "toasters",
        "pop-trigger": "pop-triggers",
        "explosive-compound": "explosive-compounds",
        "power-cable": "power-cables",
        "industrial-battery": "industrial-batteries",
        "damaged-heat-sink": "damaged-heat-sinks",
        "fried-motherboard": "fried-motherboards",
        "tick-pod": "tick-pods",
        "arc-powercell": "arc-powercells",
        "arc-motion-core": "arc-motion-cores",
        "sentinel-firing-core": "sentinel-firing-cores",
        "rusted-shut-medical-kit": "rusted-shut-medical-kits",
        "bombardier-cell": "bombardier-cells",
    }
    return mapping.get(item_id, item_id)


def plural_display_name(name: str, canonical_id: str) -> str:
    overrides = {
        "apricots": "Apricots", "lemons": "Lemons", "olives": "Olives", "prickly-pears": "Prickly Pears",
        "very-comfortable-pillows": "Very Comfortable Pillows", "wasp-drivers": "Wasp Drivers",
        "hornet-drivers": "Hornet Drivers", "snitch-scanners": "Snitch Scanners",
        "leaper-pulse-units": "Leaper Pulse Units", "surveyor-vaults": "Surveyor Vaults",
        "fireball-burners": "Fireball Burners", "rocketeer-drivers": "Rocketeer Drivers",
        "bastion-cells": "Bastion Cells", "electrical-components": "Electrical Components",
        "mechanical-components": "Mechanical Components", "advanced-electrical-components": "Advanced Electrical Components",
        "advanced-mechanical-components": "Advanced Mechanical Components", "wires": "Wires",
        "motors": "Motors", "toasters": "Toasters", "pop-triggers": "Pop Triggers",
        "explosive-compounds": "Explosive Compounds", "power-cables": "Power Cables",
        "industrial-batteries": "Industrial Batteries", "damaged-heat-sinks": "Damaged Heat Sinks",
        "fried-motherboards": "Fried Motherboards", "tick-pods": "Tick Pods",
        "arc-powercells": "ARC Powercells", "arc-motion-cores": "ARC Motion Cores",
        "sentinel-firing-cores": "Sentinel Firing Cores", "rusted-shut-medical-kits": "Rusted Shut Medical Kits",
        "bombardier-cells": "Bombardier Cells",
    }
    return overrides.get(canonical_id, name)


def raw_url(config: dict, rel_path: str) -> str:
    return config["repo_raw_base"].rstrip("/") + "/" + rel_path.lstrip("/")


def fetch_text(url: str) -> str:
    resp = requests.get(url, timeout=60, headers={"User-Agent": "Mozilla/5.0 UAGAssetPipeline/2.0"})
    resp.raise_for_status()
    return resp.text


def looks_like_item_name(name: str) -> bool:
    if not name or len(name) < 2 or len(name) > 90:
        return False
    bad = {"Owned", "Wanted", "Missing", "All", "None", "Search", "Filter", "Open", "Close", "Home", "Items"}
    if name in bad:
        return False
    if re.search(r"privacy|cookie|advert|navigation|menu|sign in|register|edit source", name, re.I):
        return False
    return bool(re.search(r"[A-Za-z]", name))


def extract_app_items_from_dart(text: str, source_file: str, config: dict) -> List[AppItem]:
    items: List[AppItem] = []
    seen: set[Tuple[str, str]] = set()

    for m in re.finditer(r"ArcScrappyItem\s*\((?P<body>.*?)\)\s*,", text, flags=re.DOTALL):
        body = m.group("body")
        id_m = re.search(r"\bid\s*:\s*'([^']+)'", body)
        name_m = re.search(r"\bname\s*:\s*'([^']+)'", body)
        cat_m = re.search(r"\bcategory\s*:\s*'([^']+)'", body)
        paths = tuple(re.findall(r"imageAsset\s*:\s*'([^']+)'", body))
        if id_m and name_m:
            item_id = canonical_resource_id(id_m.group(1))
            name = plural_display_name(name_m.group(1), item_id)
            key = (item_id, name)
            if key not in seen:
                items.append(AppItem(item_id, name, source_file, paths, cat_m.group(1) if cat_m else "scrappy"))
                seen.add(key)

    for m in re.finditer(r"ArcBenchUpgradeRequirement\s*\((?P<body>.*?)\)", text, flags=re.DOTALL):
        body = m.group("body")
        id_m = re.search(r"\bitemId\s*:\s*'([^']+)'", body)
        name_m = re.search(r"\bitemName\s*:\s*'([^']+)'", body)
        station_m = re.search(r"\bstation\s*:\s*'([^']+)'", body)
        if id_m and name_m:
            item_id = canonical_resource_id(id_m.group(1))
            name = plural_display_name(name_m.group(1), item_id)
            asset_path = f"assets/arc_raiders/scrappy_resources/{item_id.replace('-', '_')}.webp"
            key = (item_id, name)
            if key not in seen:
                items.append(AppItem(item_id, name, source_file, (asset_path,), station_m.group(1) if station_m else "bench"))
                seen.add(key)

    for m in re.finditer(r"ArcQuestRequirement\s*\((?P<body>.*?)\)", text, flags=re.DOTALL):
        body = m.group("body")
        id_m = re.search(r"\bitemId\s*:\s*'([^']+)'", body)
        name_m = re.search(r"\bitemName\s*:\s*'([^']+)'", body)
        trader_m = re.search(r"\btrader\s*:\s*'([^']+)'", body)
        if id_m and name_m:
            item_id = canonical_resource_id(id_m.group(1))
            name = plural_display_name(name_m.group(1), item_id)
            asset_path = f"assets/arc_raiders/scrappy_resources/{item_id.replace('-', '_')}.webp"
            key = (item_id, name)
            if key not in seen:
                items.append(AppItem(item_id, name, source_file, (asset_path,), trader_m.group(1) if trader_m else "quest"))
                seen.add(key)

    generic_patterns = [
        (r"\bid\s*:\s*'([^']+)'", r"\bname\s*:\s*'([^']+)'"),
        (r"\bitemId\s*:\s*'([^']+)'", r"\bitemName\s*:\s*'([^']+)'"),
        (r"\bvalue\s*:\s*'([^']+)'", r"\blabel\s*:\s*'([^']+)'"),
    ]
    for id_pat, name_pat in generic_patterns:
        for id_m in re.finditer(id_pat, text):
            search_window = text[id_m.start(): id_m.start() + 900]
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

    blocked = tuple(config.get("exclude_asset_paths_containing", []))
    filtered: List[AppItem] = []
    for item in items:
        paths = tuple(p for p in item.existing_asset_paths if not any(b in p for b in blocked))
        if item.existing_asset_paths and not paths:
            continue
        if not any(b in item.name.lower() for b in ("blueprint",)):
            filtered.append(AppItem(item.id, item.name, item.source_file, paths, item.category))
    return filtered


def dedupe_items(items: Iterable[AppItem]) -> List[AppItem]:
    merged: Dict[str, AppItem] = {}
    for item in items:
        key = normalize(item.name) or item.id
        if key not in merged:
            merged[key] = item
        else:
            old = merged[key]
            paths = tuple(dict.fromkeys(old.existing_asset_paths + item.existing_asset_paths))
            cats = sorted(set((old.category + "," + item.category).split(",")))
            merged[key] = AppItem(old.id, old.name, old.source_file, paths, ",".join(cats))
    return sorted(merged.values(), key=lambda x: (x.category, x.name.lower()))


def build_reference_manifest(config: dict) -> List[AppItem]:
    items: List[AppItem] = []
    errors = []
    for rel in config["project_data_files"]:
        url = raw_url(config, rel)
        try:
            text = fetch_text(url)
            items.extend(extract_app_items_from_dart(text, rel, config))
            print(f"Read repo data: {rel}")
        except Exception as exc:
            errors.append({"file": rel, "url": url, "error": str(exc)})
            print(f"WARN repo file failed: {rel} :: {exc}")
    out = root() / config["reports_folder"]
    out.mkdir(parents=True, exist_ok=True)
    if errors:
        (out / "github_fetch_errors.json").write_text(json.dumps(errors, indent=2), encoding="utf-8")
    return dedupe_items(items)


def clean_candidate_name(value: str) -> str:
    value = re.sub(r"\s+", " ", (value or "")).strip()
    value = re.sub(r"\.(png|webp|jpg|jpeg|avif|svg)$", "", value, flags=re.I)
    value = urllib.parse.unquote(value)
    value = value.replace("_", " ").replace("-", " ")
    value = re.sub(r"\b(icon|image|thumbnail|transparent|latest|file|item)\b", "", value, flags=re.I)
    splitters = [" Category ", " Rarity ", " Value ", " Weight ", " Recycles ", " Used For ", " Sell Price "]
    for splitter in splitters:
        if splitter in value:
            value = value.split(splitter, 1)[0].strip()
    value = value.strip(" -•|/:[]()")
    if len(value) > 80:
        value = " ".join(value.split()[:7])
    if not looks_like_item_name(value):
        return ""
    return value


def image_name_from_url(url: str) -> str:
    path = urllib.parse.urlparse(url).path
    name = Path(path).name
    name = re.sub(r"/revision/latest.*$", "", name)
    name = re.sub(r"\?.*$", "", name)
    return clean_candidate_name(name)


def absolute_url(base_url: str, src: str) -> str:
    if not src:
        return ""
    if src.startswith("//"):
        return "https:" + src
    return urllib.parse.urljoin(base_url, src)


def valid_image_url(url: str) -> bool:
    if not url or url.startswith("data:"):
        return False
    low = url.lower()
    if any(b in low for b in BAD_IMAGE_HINTS):
        return False
    if not re.search(r"\.(png|webp|jpg|jpeg|avif)(\?|$|/)", low) and "static.wikia" not in low and "static.wiki" not in low:
        return False
    return True


def candidate_names_from_img(img, page_url: str) -> List[str]:
    names: List[str] = []
    for attr in ("alt", "title", "aria-label"):
        value = clean_candidate_name(img.get(attr, ""))
        if value:
            names.append(value)
    src = img.get("src") or img.get("data-src") or img.get("data-image-key") or ""
    from_url = image_name_from_url(src)
    if from_url:
        names.append(from_url)
    parent = img
    for _ in range(5):
        parent = parent.parent
        if not parent:
            break
        # table rows/cards often contain the true item name next to the image.
        for selector in ["a[title]", "a", "td", "th", "h2", "h3", "span"]:
            for el in parent.select(selector)[:8]:
                txt = clean_candidate_name(el.get("title") or el.get_text(" ", strip=True))
                if txt:
                    names.append(txt)
        txt = clean_candidate_name(parent.get_text(" ", strip=True))
        if txt:
            names.append(txt)
    return list(dict.fromkeys(names))


def scrape_static_catalogue(source: dict, debug_dir: Path) -> List[Candidate]:
    url = source["url"]
    source_id = source["id"]
    print(f"Scraping static source: {source_id} -> {url}")
    html = fetch_text(url)
    (debug_dir / f"{source_id}_page.html").write_text(html, encoding="utf-8")
    soup = BeautifulSoup(html, "html.parser")
    candidates: List[Candidate] = []
    for img in soup.find_all("img"):
        src = img.get("src") or img.get("data-src") or img.get("data-original") or img.get("data-image-key") or ""
        image_url = absolute_url(url, src)
        if not valid_image_url(image_url):
            continue
        names = candidate_names_from_img(img, url)
        for name in names:
            candidates.append(Candidate(source_id, name, image_url, url))
    return candidates


def scrape_playwright_catalogue(source: dict, debug_dir: Path, keep_browser_open: bool = False) -> List[Candidate]:
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print("Missing Playwright. Run: py -m pip install playwright && py -m playwright install chromium")
        raise
    url = source["url"]
    source_id = source["id"]
    print(f"Scraping rendered source: {source_id} -> {url}")
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=not keep_browser_open)
        page = browser.new_page(viewport={"width": 1600, "height": 2400}, user_agent="Mozilla/5.0 UAGAssetPipeline/2.0")
        page.goto(url, wait_until="networkidle", timeout=120000)
        page.wait_for_timeout(3500)
        last_height = 0
        stable_count = 0
        for _ in range(50):
            page.mouse.wheel(0, 1800)
            page.wait_for_timeout(700)
            height = page.evaluate("() => document.documentElement.scrollHeight")
            if height == last_height:
                stable_count += 1
                if stable_count >= 5:
                    break
            else:
                stable_count = 0
                last_height = height
        page.wait_for_timeout(2000)
        rows = page.evaluate("""
        () => {
          const out = [];
          const imgs = Array.from(document.querySelectorAll('img'));
          for (const img of imgs) {
            const src = img.currentSrc || img.src || img.getAttribute('src') || img.getAttribute('data-src') || '';
            if (!src || src.startsWith('data:')) continue;
            let texts = [];
            const attrs = [img.getAttribute('alt'), img.getAttribute('title'), img.getAttribute('aria-label')].filter(Boolean);
            texts.push(...attrs);
            let el = img;
            for (let i = 0; i < 6 && el; i++, el = el.parentElement) {
              const t = (el.innerText || '').replace(/\s+/g, ' ').trim();
              if (t && t.length < 300) texts.push(t);
              const labelled = el.getAttribute && (el.getAttribute('aria-label') || el.getAttribute('title'));
              if (labelled) texts.push(labelled);
            }
            out.push({src, texts});
          }
          return out;
        }
        """)
        html = page.content()
        page.screenshot(path=str(debug_dir / f"{source_id}_debug.png"), full_page=True)
        browser.close()
    (debug_dir / f"{source_id}_rendered.html").write_text(html, encoding="utf-8")
    candidates: List[Candidate] = []
    for row in rows:
        image_url = absolute_url(url, row.get("src", ""))
        if not valid_image_url(image_url):
            continue
        names = []
        for t in row.get("texts", []):
            for part in re.split(r"\n|\||•", t):
                name = clean_candidate_name(part)
                if name:
                    names.append(name)
        from_url = image_name_from_url(image_url)
        if from_url:
            names.append(from_url)
        for name in list(dict.fromkeys(names)):
            candidates.append(Candidate(source_id, name, image_url, url))
    return candidates


def build_catalogue(config: dict, keep_browser_open: bool = False) -> Dict[str, List[Candidate]]:
    debug_dir = root() / config["reports_folder"] / "source_debug"
    debug_dir.mkdir(parents=True, exist_ok=True)
    all_candidates: List[Candidate] = []
    errors = []
    for source in sorted(config["sources"], key=lambda s: s.get("priority", 0)):
        if source["type"] == "local_folder":
            continue
        try:
            if source["type"] == "playwright_catalogue":
                candidates = scrape_playwright_catalogue(source, debug_dir, keep_browser_open=keep_browser_open)
            else:
                candidates = scrape_static_catalogue(source, debug_dir)
            print(f"  candidates found: {len(candidates)}")
            all_candidates.extend(candidates)
        except Exception as exc:
            print(f"WARN source failed: {source['id']} :: {exc}")
            errors.append({"source": source, "error": str(exc)})
    catalogue: Dict[str, List[Candidate]] = {}
    raw = []
    for c in all_candidates:
        key = normalize(c.name)
        if not key:
            continue
        catalogue.setdefault(key, []).append(c)
        raw.append(asdict(c) | {"normalized": key})
    reports = root() / config["reports_folder"]
    reports.mkdir(parents=True, exist_ok=True)
    (reports / "combined_source_catalogue.json").write_text(json.dumps(raw, indent=2), encoding="utf-8")
    if errors:
        (reports / "source_errors.json").write_text(json.dumps(errors, indent=2), encoding="utf-8")
    print(f"Combined unique catalogue keys: {len(catalogue)}")
    return catalogue


def override_names_for_item(item: AppItem, config: dict) -> List[str]:
    ids = {item.id, dash_id(item.name), slugify(item.name)}
    overrides = []
    mapping = config.get("name_overrides", {})
    for key in ids:
        if key in mapping:
            value = mapping[key]
            overrides.extend(value if isinstance(value, list) else [value])
    return overrides


def token_score(target: str, source: str) -> float:
    t = set(normalize(target).split())
    s = set(normalize(source).split())
    if not t or not s:
        return 0.0
    return len(t & s) / max(len(t), len(s))


def find_manual_override(item: AppItem, config: dict) -> Optional[Path]:
    folder = root() / config["manual_overrides_folder"]
    if not folder.exists():
        return None
    candidates = []
    for base in [slugify(item.name), item.id.replace("-", "_"), dash_id(item.name).replace("-", "_")]:
        candidates.extend([folder / f"{base}.png", folder / f"{base}.jpg", folder / f"{base}.jpeg", folder / f"{base}.webp"])
    for p in candidates:
        if p.exists():
            return p
    return None


def match_item(item: AppItem, catalogue: Dict[str, List[Candidate]], config: dict) -> Optional[Candidate]:
    query_names = [item.name, item.id.replace("-", " ")] + override_names_for_item(item, config)
    query_keys = []
    for q in query_names:
        query_keys.append(normalize(q))
        query_keys.append(normalize(q.rstrip("s")))
        query_keys.append(normalize(q + "s"))
    query_keys = [k for k in dict.fromkeys(query_keys) if k]

    for key in query_keys:
        if key in catalogue:
            return sorted(catalogue[key], key=lambda c: c.score_hint, reverse=True)[0]

    best: Optional[Candidate] = None
    best_score = 0.0
    for key, candidates in catalogue.items():
        for q in query_names:
            score = token_score(q, key)
            if score > best_score:
                best_score = score
                best = candidates[0]
    if best and best_score >= float(config.get("min_match_score", 0.84)):
        best.score_hint = best_score
        return best
    return None


def download_image(url: str) -> Image.Image:
    resp = requests.get(url, timeout=70, headers={"User-Agent": "Mozilla/5.0 UAGAssetPipeline/2.0"})
    resp.raise_for_status()
    return Image.open(BytesIO(resp.content)).convert("RGBA")


def load_local_image(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def trim_transparent(img: Image.Image) -> Image.Image:
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    alpha = img.getchannel("A")
    bbox = alpha.getbbox()
    if bbox:
        return img.crop(bbox)
    return img


def crop_keep_background(img: Image.Image, crop_percent: float, canvas_size: int) -> Image.Image:
    img = img.convert("RGBA")
    w, h = img.size
    inset_x = int(w * crop_percent)
    inset_y = int(h * crop_percent)
    if inset_x * 2 < w and inset_y * 2 < h:
        img = img.crop((inset_x, inset_y, w - inset_x, h - inset_y))
    # square crop around centre, keeping actual background/card.
    w, h = img.size
    side = min(w, h)
    left = max(0, (w - side) // 2)
    top = max(0, (h - side) // 2)
    img = img.crop((left, top, left + side, top + side))
    return img.resize((canvas_size, canvas_size), Image.Resampling.LANCZOS)


def normalize_transparent_item(img: Image.Image, canvas_size: int, fill_ratio: float) -> Image.Image:
    img = trim_transparent(img)
    w, h = img.size
    if w == 0 or h == 0:
        return make_placeholder("unknown", canvas_size)
    max_side = int(canvas_size * fill_ratio)
    scale = min(max_side / w, max_side / h)
    new_size = (max(1, int(w * scale)), max(1, int(h * scale)))
    img = img.resize(new_size, Image.Resampling.LANCZOS)
    out = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    out.alpha_composite(img, ((canvas_size - new_size[0]) // 2, (canvas_size - new_size[1]) // 2))
    return out


def process_image(img: Image.Image, config: dict) -> Image.Image:
    canvas_size = int(config.get("final_canvas_size", 512))
    if config.get("keep_background", True):
        return crop_keep_background(img, float(config.get("background_crop_percent", 0.04)), canvas_size)
    return normalize_transparent_item(img, canvas_size, float(config.get("transparent_item_fill_ratio", 0.86)))


def make_placeholder(name: str, canvas_size: int) -> Image.Image:
    img = Image.new("RGBA", (canvas_size, canvas_size), (8, 16, 28, 255))
    draw = ImageDraw.Draw(img)
    border = max(3, canvas_size // 96)
    draw.rounded_rectangle((border, border, canvas_size-border, canvas_size-border), radius=canvas_size//14, outline=(0, 220, 255, 210), width=border)
    draw.rounded_rectangle((border*3, border*3, canvas_size-border*3, canvas_size-border*3), radius=canvas_size//18, outline=(255, 40, 180, 130), width=max(1, border//2))
    text = "?"
    try:
        font = ImageFont.truetype("arial.ttf", canvas_size//3)
    except Exception:
        font = ImageFont.load_default()
    bbox = draw.textbbox((0,0), text, font=font)
    draw.text(((canvas_size-(bbox[2]-bbox[0]))/2, (canvas_size-(bbox[3]-bbox[1]))/2), text, font=font, fill=(255,255,255,230))
    return img


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def backup_existing(path: Path, backup_root: Path, root_path: Path) -> None:
    if not path.exists() or not path.is_file():
        return
    rel = path.relative_to(root_path)
    dest = backup_root / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    if not dest.exists():
        shutil.copy2(path, dest)


def write_webp(img: Image.Image, dest: Path, quality: int) -> None:
    ensure_parent(dest)
    img.save(dest, "WEBP", quality=quality, method=6)


def run(clean_unused: bool = False, keep_browser_open: bool = False, debug: bool = False) -> int:
    config = load_config()
    root_path = root()
    out_main = root_path / config["output_main_folder"]
    reports = root_path / config["reports_folder"]
    backup_root = root_path / config["backup_folder"]
    out_main.mkdir(parents=True, exist_ok=True)
    reports.mkdir(parents=True, exist_ok=True)
    backup_root.mkdir(parents=True, exist_ok=True)

    print("Building exact item manifest from GitHub repo...")
    app_items = build_reference_manifest(config)
    (reports / "arc_item_reference_manifest.json").write_text(json.dumps([asdict(i) for i in app_items], indent=2), encoding="utf-8")
    print(f"Reference items found: {len(app_items)}")

    print("Building multi-source image catalogue...")
    catalogue = build_catalogue(config, keep_browser_open=keep_browser_open)

    results: List[DownloadResult] = []
    hashes: Dict[str, List[str]] = {}
    placeholders = 0

    for item in app_items:
        main_filename = f"{slugify(item.name)}.webp"
        main_rel = f"{config['output_main_folder'].rstrip('/')}/{main_filename}"
        main_dest = root_path / main_rel
        source_url = None
        matched_name = None
        matched_source = None
        status = "ok"
        reason = ""
        try:
            override = find_manual_override(item, config)
            if override:
                img = load_local_image(override)
                matched_name = override.name
                matched_source = "manual_overrides"
                source_url = str(override)
            else:
                matched = match_item(item, catalogue, config)
                if matched:
                    img = download_image(matched.image_url)
                    matched_name = matched.name
                    matched_source = matched.source_id
                    source_url = matched.image_url
                else:
                    img = make_placeholder(item.name, int(config.get("final_canvas_size", 512)))
                    status = "placeholder"
                    reason = "No safe match found in any configured source. Placeholder generated."
                    placeholders += 1
            processed = process_image(img, config) if status != "placeholder" else img
            backup_existing(main_dest, backup_root, root_path)
            write_webp(processed, main_dest, int(config.get("webp_quality", 92)))
            mirrored_paths: List[str] = []
            if config.get("mirror_to_existing_asset_paths", True):
                for rel_path in item.existing_asset_paths:
                    if not rel_path or rel_path == main_rel:
                        continue
                    if any(blocked in rel_path for blocked in config.get("exclude_asset_paths_containing", [])):
                        continue
                    dest = root_path / rel_path
                    backup_existing(dest, backup_root, root_path)
                    write_webp(processed, dest, int(config.get("webp_quality", 92)))
                    mirrored_paths.append(rel_path)
            if main_dest.exists():
                file_hash = hashlib.sha256(main_dest.read_bytes()).hexdigest()
                hashes.setdefault(file_hash, []).append(main_rel)
            results.append(DownloadResult(item.id, item.name, matched_name, matched_source, source_url, main_rel, mirrored_paths, status, reason))
            label = "OK" if status == "ok" else "PLACEHOLDER"
            print(f"{label:<11} {main_filename} <- {item.name} :: {matched_source or 'none'}")
        except Exception as exc:
            results.append(DownloadResult(item.id, item.name, matched_name, matched_source, source_url, main_rel, [], "failed", str(exc)))
            print(f"FAIL       {main_filename} <- {item.name} :: {exc}")

    ok = [r for r in results if r.status == "ok"]
    missing = [r for r in results if r.status == "placeholder"]
    failed = [r for r in results if r.status == "failed"]
    duplicates = {h: paths for h, paths in hashes.items() if len(paths) > 1}

    (reports / "arc_item_download_results.json").write_text(json.dumps([asdict(r) for r in results], indent=2), encoding="utf-8")
    (reports / "missing_asset_report.json").write_text(json.dumps([asdict(r) for r in missing + failed], indent=2), encoding="utf-8")
    (reports / "duplicate_asset_report.json").write_text(json.dumps(duplicates, indent=2), encoding="utf-8")

    if clean_unused:
        keep = {Path(r.main_asset_path) for r in results if r.status in {"ok", "placeholder"}}
        for r in results:
            keep.update(Path(p) for p in r.mirrored_paths)
        removed = []
        for folder in [out_main, root_path / "assets/arc_raiders/scrappy_resources"]:
            if not folder.exists():
                continue
            for file in folder.glob("*.webp"):
                rel = file.relative_to(root_path)
                if rel not in keep:
                    backup_existing(file, backup_root, root_path)
                    file.unlink()
                    removed.append(str(rel))
        (reports / "clean_unused_removed_files.json").write_text(json.dumps(removed, indent=2), encoding="utf-8")
        print(f"Cleaned unused WebP files: {len(removed)}")

    print("\nSUMMARY")
    print(f"  OK real images: {len(ok)}")
    print(f"  Placeholders: {len(missing)}")
    print(f"  Failed: {len(failed)}")
    print(f"  Reports: {reports}")
    return 0 if not failed else 2


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--clean-unused", action="store_true", help="Back up then remove unused old WebP files from item folders.")
    parser.add_argument("--keep-browser-open", action="store_true", help="Keep browser visible during rendered source scrape.")
    parser.add_argument("--debug", action="store_true", help="Keep extra debug output/reports.")
    args = parser.parse_args()
    raise SystemExit(run(clean_unused=args.clean_unused, keep_browser_open=args.keep_browser_open, debug=args.debug))


if __name__ == "__main__":
    main()
