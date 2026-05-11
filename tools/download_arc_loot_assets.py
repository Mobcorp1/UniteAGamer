#!/usr/bin/env python3
"""
UAG Traders Hub — ARC Raiders item asset pipeline.

Primary image source:
  https://arcraiders.wiki/wiki/Loot

What this script does:
- Reads the live GitHub repo Dart data files as the source of truth.
- Builds the exact item manifest used by Scrappy, Bench, Quest and Trading Hub data.
- Scrapes ARC Raiders Wiki Loot table for real item images.
- Uses manual override assets first when present.
- Uses alias matching for singular/plural and renamed items.
- Converts all output to .webp.
- Saves to assets/arc_raiders/items/.
- Mirrors to assets/arc_raiders/scrappy_resources/ for older resolver paths.
- Mirrors to existing imageAsset paths found in repo data.
- Patches pubspec.yaml to include assets/arc_raiders/items/ if missing.
- Writes detailed reports.

Run from project root:
  py tools/download_arc_loot_assets.py

Optional:
  py tools/download_arc_loot_assets.py --no-pubspec-patch
  py tools/download_arc_loot_assets.py --clean-unused
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import sys
import urllib.parse
from dataclasses import asdict, dataclass
from io import BytesIO
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Tuple

try:
    import requests
    from bs4 import BeautifulSoup
    from PIL import Image, ImageChops, ImageOps
except ImportError as exc:
    print("Missing dependency. Run:")
    print("  py -m pip install requests beautifulsoup4 pillow")
    raise

CONFIG_PATH = Path(__file__).with_name("arc_loot_asset_pipeline_config.json")

STOP_WORDS = {
    "the", "a", "an", "and", "of", "for", "to", "with", "item", "items", "arc", "raiders",
}

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) UAGAssetPipeline/2.0",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
}


@dataclass(frozen=True)
class AppItem:
    id: str
    name: str
    source_file: str
    existing_asset_paths: Tuple[str, ...]
    category: str = "unknown"


@dataclass
class SourceImage:
    name: str
    key: str
    url: str
    page_url: str
    source: str


@dataclass
class DownloadResult:
    id: str
    name: str
    matched_name: Optional[str]
    source: Optional[str]
    source_url: Optional[str]
    main_asset_path: str
    mirrored_paths: List[str]
    status: str
    reason: str = ""


def load_config() -> dict:
    if not CONFIG_PATH.exists():
        raise FileNotFoundError(f"Missing config: {CONFIG_PATH}")
    return json.loads(CONFIG_PATH.read_text(encoding="utf-8"))


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
    response = requests.get(url, timeout=60, headers=HEADERS)
    response.raise_for_status()
    return response.text


def canonical_resource_id(item_id: str) -> str:
    item_id = item_id.replace("_", "-")
    mapping = {
        "apricot": "apricots",
        "lemon": "lemons",
        "prickly-pear": "prickly-pears",
        "very-comfortable-pillow": "very-comfortable-pillows",
        "mushroom": "mushrooms",
        "wasp-driver": "wasp-drivers",
        "hornet-driver": "hornet-drivers",
        "snitch-scanner": "snitch-scanners",
        "leaper-pulse-unit": "leaper-pulse-units",
        "surveyor-vault": "surveyor-vaults",
        "fireball-burner": "fireball-burners",
        "rocketeer-driver": "rocketeer-drivers",
        "bastion-cell": "bastion-cells",
        "bombardier-cell": "bombardier-cells",
        "arc-powercell": "arc-powercells",
        "arc-motion-core": "arc-motion-cores",
        "electrical-component": "electrical-components",
        "mechanical-component": "mechanical-components",
        "advanced-electrical-component": "advanced-electrical-components",
        "advanced-mechanical-component": "advanced-mechanical-components",
        "power-cable": "power-cables",
        "industrial-battery": "industrial-batteries",
        "pop-trigger": "pop-triggers",
        "explosive-compound": "explosive-compounds",
        "sentinel-firing-core": "sentinel-firing-cores",
        "rusted-shut-medical-kit": "rusted-shut-medical-kits",
        "damaged-heat-sink": "damaged-heat-sinks",
        "fried-motherboard": "fried-motherboards",
        "tick-pod": "tick-pods",
        "wire": "wires",
        "fruit-mix": "mixed-fruit",
    }
    return mapping.get(item_id, item_id)


def plural_display_name(name: str, canonical_id: str) -> str:
    overrides = {
        "apricots": "Apricots",
        "lemons": "Lemons",
        "prickly-pears": "Prickly Pears",
        "very-comfortable-pillows": "Very Comfortable Pillows",
        "mushrooms": "Mushrooms",
        "wasp-drivers": "Wasp Drivers",
        "hornet-drivers": "Hornet Drivers",
        "snitch-scanners": "Snitch Scanners",
        "leaper-pulse-units": "Leaper Pulse Units",
        "surveyor-vaults": "Surveyor Vaults",
        "fireball-burners": "Fireball Burners",
        "rocketeer-drivers": "Rocketeer Drivers",
        "bastion-cells": "Bastion Cells",
        "bombardier-cells": "Bombardier Cells",
        "arc-powercells": "ARC Powercells",
        "arc-motion-cores": "ARC Motion Cores",
        "power-cables": "Power Cables",
        "industrial-batteries": "Industrial Batteries",
        "pop-triggers": "Pop Triggers",
        "explosive-compounds": "Explosive Compounds",
        "sentinel-firing-cores": "Sentinel Firing Cores",
        "rusted-shut-medical-kits": "Rusted Shut Medical Kits",
        "damaged-heat-sinks": "Damaged Heat Sinks",
        "fried-motherboards": "Fried Motherboards",
        "tick-pods": "Tick Pods",
        "wires": "Wires",
        "mixed-fruit": "Mixed Fruit",
    }
    return overrides.get(canonical_id, name)


def looks_like_item_name(name: str) -> bool:
    if not name or len(name) < 2:
        return False
    bad = {"Owned", "Wanted", "Missing", "All", "None", "Search", "Filter", "Open", "Close", "Image"}
    return name.strip() not in bad


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

    for cls, cat in [("ArcBenchUpgradeRequirement", "bench"), ("ArcQuestRequirement", "quest")]:
        for m in re.finditer(rf"{cls}\s*\((?P<body>.*?)\)", text, flags=re.DOTALL):
            body = m.group("body")
            id_m = re.search(r"\bitemId\s*:\s*'([^']+)'", body)
            name_m = re.search(r"\bitemName\s*:\s*'([^']+)'", body)
            if id_m and name_m:
                item_id = canonical_resource_id(id_m.group(1))
                name = plural_display_name(name_m.group(1), item_id)
                paths = tuple(re.findall(r"imageAsset\s*:\s*'([^']+)'", body))
                if not paths:
                    paths = (f"assets/arc_raiders/items/{slugify(name)}.webp", f"assets/arc_raiders/scrappy_resources/{slugify(name)}.webp")
                key = (item_id, name)
                if key not in seen:
                    items.append(AppItem(item_id, name, source_file, paths, cat))
                    seen.add(key)

    generic_patterns = [
        (r"\bid\s*:\s*'([^']+)'", r"\bname\s*:\s*'([^']+)'"),
        (r"\bitemId\s*:\s*'([^']+)'", r"\bitemName\s*:\s*'([^']+)'"),
        (r"\bvalue\s*:\s*'([^']+)'", r"\blabel\s*:\s*'([^']+)'"),
    ]
    for id_pat, name_pat in generic_patterns:
        for id_m in re.finditer(id_pat, text):
            window = text[id_m.start(): id_m.start() + 900]
            name_m = re.search(name_pat, window)
            if not name_m:
                continue
            item_id = canonical_resource_id(id_m.group(1))
            name = plural_display_name(name_m.group(1), item_id)
            if not looks_like_item_name(name):
                continue
            paths = tuple(re.findall(r"imageAsset\s*:\s*'([^']+)'", window))
            if not paths:
                paths = (f"assets/arc_raiders/items/{slugify(name)}.webp",)
            key = (item_id, name)
            if key not in seen:
                items.append(AppItem(item_id, name, source_file, paths, "trade"))
                seen.add(key)

    blocked = tuple(config.get("exclude_asset_paths_containing", []))
    filtered: List[AppItem] = []
    for item in items:
        paths = tuple(p for p in item.existing_asset_paths if not any(b in p for b in blocked))
        if item.existing_asset_paths and not paths:
            continue
        if "blueprint" in item.name.lower():
            continue
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
            categories = old.category if item.category in old.category else f"{old.category},{item.category}"
            merged[key] = AppItem(old.id, old.name, old.source_file, paths, categories)
    return sorted(merged.values(), key=lambda x: (x.category, x.name.lower()))


def build_reference_manifest(config: dict, output_dir: Path) -> List[AppItem]:
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
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "arc_item_reference_manifest.json").write_text(
        json.dumps([asdict(item) for item in final_items], indent=2), encoding="utf-8"
    )
    if errors:
        (output_dir / "github_fetch_errors.json").write_text(json.dumps(errors, indent=2), encoding="utf-8")
    return final_items


def mediawiki_original_url(url: str) -> str:
    # Converts /images/thumb/a/ab/File.png/80px-File.png to /images/a/ab/File.png when possible.
    if "/thumb/" not in url:
        return url
    try:
        parts = url.split("/thumb/", 1)
        prefix = parts[0]
        rest = parts[1]
        chunks = rest.split("/")
        if len(chunks) >= 4:
            original = "/".join(chunks[:-1])
            return prefix + "/" + original
    except Exception:
        pass
    return url


def image_url_from_img(img, base_url: str) -> Optional[str]:
    candidates = [
        img.get("src"), img.get("data-src"), img.get("data-lazy-src"), img.get("data-original"),
    ]
    srcset = img.get("srcset") or img.get("data-srcset")
    if srcset:
        # Pick the largest srcset candidate.
        entries = []
        for part in srcset.split(","):
            bits = part.strip().split()
            if bits:
                weight = 0
                if len(bits) > 1:
                    m = re.search(r"(\d+)", bits[1])
                    if m:
                        weight = int(m.group(1))
                entries.append((weight, bits[0]))
        if entries:
            candidates.insert(0, sorted(entries)[-1][1])
    for c in candidates:
        if not c or c.startswith("data:"):
            continue
        resolved = urllib.parse.urljoin(base_url, c)
        return mediawiki_original_url(resolved)
    return None


def scrape_arcraiders_wiki_loot(config: dict, output_dir: Path) -> Dict[str, SourceImage]:
    url = config["primary_source_url"]
    html = fetch_text(url)
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "arcraiders_wiki_loot_page.html").write_text(html, encoding="utf-8")
    soup = BeautifulSoup(html, "html.parser")

    catalogue: Dict[str, SourceImage] = {}
    raw_rows = []

    for row in soup.select("tr"):
        img = row.find("img")
        if not img:
            continue
        image_url = image_url_from_img(img, url)
        if not image_url:
            continue

        links = row.find_all("a", href=True)
        item_name = None
        item_href = None
        for a in links:
            text = a.get_text(" ", strip=True)
            href = a.get("href", "")
            if not text or text.lower() == "image":
                continue
            if href.startswith("/wiki/") and not any(ns in href for ns in ["File:", "Category:", "Special:", "Template:"]):
                item_name = text
                item_href = urllib.parse.urljoin(url, href)
                break
        if not item_name:
            # Some MediaWiki rows put the item name in the second cell plain text.
            cells = row.find_all(["td", "th"])
            if len(cells) > 1:
                text = cells[1].get_text(" ", strip=True)
                if looks_like_item_name(text):
                    item_name = re.sub(r"\s+", " ", text).strip()
                    item_href = url
        if not item_name:
            continue
        key = normalize(item_name)
        if not key:
            continue
        src = SourceImage(item_name, key, image_url, item_href or url, "arcraiders.wiki/loot")
        if key not in catalogue:
            catalogue[key] = src
        raw_rows.append(asdict(src))

    # Also pick gallery/card style item images if present.
    for a in soup.select("a[href^='/wiki/']"):
        text = a.get_text(" ", strip=True)
        if not looks_like_item_name(text):
            continue
        img = a.find("img") or (a.parent.find("img") if a.parent else None)
        if not img:
            continue
        image_url = image_url_from_img(img, url)
        if not image_url:
            continue
        key = normalize(text)
        if key and key not in catalogue:
            src = SourceImage(text, key, image_url, urllib.parse.urljoin(url, a.get("href", "")), "arcraiders.wiki/loot")
            catalogue[key] = src
            raw_rows.append(asdict(src))

    (output_dir / "arcraiders_wiki_loot_catalogue.json").write_text(json.dumps(raw_rows, indent=2), encoding="utf-8")
    return catalogue


def build_alias_keys(item: AppItem, config: dict) -> List[str]:
    names = [item.name, item.id.replace("-", " "), item.id.replace("_", " ")]
    aliases = config.get("name_aliases", {})
    for key in {slugify(item.name), item.id.replace("-", "_"), item.id.replace("_", "-")}: 
        names.extend(aliases.get(key, []))
    # Singular/plural fallbacks.
    if item.name.endswith("s"):
        names.append(item.name[:-1])
    else:
        names.append(item.name + "s")
    out = []
    for n in names:
        k = normalize(n)
        if k and k not in out:
            out.append(k)
    return out


def match_item(item: AppItem, catalogue: Dict[str, SourceImage], config: dict) -> Optional[SourceImage]:
    for key in build_alias_keys(item, config):
        if key in catalogue:
            return catalogue[key]
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
            best_score = score
            best = data
    if best_score >= 0.86:
        return best
    return None


def download_image(url: str) -> Image.Image:
    response = requests.get(url, timeout=90, headers=HEADERS)
    response.raise_for_status()
    return Image.open(BytesIO(response.content)).convert("RGBA")


def trim_transparent(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    alpha = img.getchannel("A")
    bbox = alpha.getbbox()
    if bbox:
        return img.crop(bbox)
    bg = Image.new(img.mode, img.size, img.getpixel((0, 0)))
    diff = ImageChops.difference(img, bg)
    bbox = diff.getbbox()
    return img.crop(bbox) if bbox else img


def has_real_transparency(img: Image.Image) -> bool:
    if img.mode != "RGBA":
        return False
    alpha = img.getchannel("A")
    extrema = alpha.getextrema()
    return extrema[0] < 250


def process_icon(img: Image.Image, canvas_size: int, padding_ratio: float) -> Image.Image:
    img = ImageOps.exif_transpose(img).convert("RGBA")
    transparent = has_real_transparency(img)
    if transparent:
        img = trim_transparent(img)
    else:
        # For non-transparent wiki thumbnails, keep full image but trim obvious uniform edges lightly.
        img = trim_transparent(img)

    w, h = img.size
    if w <= 0 or h <= 0:
        return Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))

    padding = max(8, int(canvas_size * padding_ratio))
    target = canvas_size - padding * 2
    scale = min(target / w, target / h)
    new_size = (max(1, int(w * scale)), max(1, int(h * scale)))
    img = img.resize(new_size, Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    x = (canvas_size - new_size[0]) // 2
    y = (canvas_size - new_size[1]) // 2
    canvas.alpha_composite(img, (x, y))
    return canvas


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def backup_existing(path: Path, backup_root: Path, root: Path) -> None:
    if not path.exists():
        return
    try:
        rel = path.relative_to(root)
    except ValueError:
        rel = Path(path.name)
    dest = backup_root / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    if not dest.exists():
        shutil.copy2(path, dest)


def write_webp(img: Image.Image, dest: Path, quality: int) -> None:
    ensure_parent(dest)
    img.save(dest, "WEBP", quality=quality, method=6)


def copy_manual_override_if_exists(item: AppItem, config: dict, root: Path) -> Optional[Image.Image]:
    folder = root / config["manual_override_folder"]
    candidates = [
        folder / f"{slugify(item.name)}.webp",
        folder / f"{slugify(item.name)}.png",
        folder / f"{slugify(item.name)}.jpg",
        folder / f"{item.id.replace('-', '_')}.webp",
        folder / f"{item.id.replace('-', '_')}.png",
        folder / f"{item.id.replace('-', '_')}.jpg",
        folder / f"{item.id}.webp",
        folder / f"{item.id}.png",
        folder / f"{item.id}.jpg",
    ]
    for path in candidates:
        if path.exists():
            return Image.open(path).convert("RGBA")
    return None


def patch_pubspec(root: Path) -> bool:
    pubspec = root / "pubspec.yaml"
    if not pubspec.exists():
        return False
    text = pubspec.read_text(encoding="utf-8")
    needed = "    - assets/arc_raiders/items/"
    if needed.strip() in text:
        return False
    marker = "    - assets/arc_raiders/scrappy_resources/"
    if marker in text:
        text = text.replace(marker, marker + "\n" + needed)
    else:
        marker2 = "    - assets/arc_raiders/blueprints/"
        if marker2 in text:
            text = text.replace(marker2, marker2 + "\n" + needed)
        else:
            text += "\nflutter:\n  assets:\n" + needed + "\n"
    pubspec.write_text(text, encoding="utf-8")
    return True


def unique_paths_for_item(item: AppItem, config: dict) -> List[str]:
    paths = [f"{config['output_main_folder'].rstrip('/')}/{slugify(item.name)}.webp"]
    # Also write ID slug version if different from name slug.
    id_slug = item.id.replace("-", "_")
    if id_slug != slugify(item.name):
        paths.append(f"{config['output_main_folder'].rstrip('/')}/{id_slug}.webp")
    if config.get("mirror_all_to_scrappy_resources", True):
        paths.append(f"{config['legacy_mirror_folder'].rstrip('/')}/{slugify(item.name)}.webp")
        if id_slug != slugify(item.name):
            paths.append(f"{config['legacy_mirror_folder'].rstrip('/')}/{id_slug}.webp")
    if config.get("mirror_to_existing_asset_paths", True):
        for p in item.existing_asset_paths:
            if p:
                paths.append(p)
    blocked = config.get("exclude_asset_paths_containing", [])
    final = []
    for p in paths:
        p = p.replace("\\", "/")
        if any(b in p for b in blocked):
            continue
        if p not in final:
            final.append(p)
    return final


def create_placeholder(root: Path, config: dict) -> Path:
    folder = root / config.get("placeholder_folder", "assets/arc_raiders/placeholders")
    folder.mkdir(parents=True, exist_ok=True)
    path = folder / "missing_item.webp"
    if path.exists():
        return path
    size = int(config.get("final_canvas_size", 512))
    img = Image.new("RGBA", (size, size), (8, 9, 35, 255))
    # Simple neon-ish placeholder without external font dependency.
    write_webp(img, path, int(config.get("webp_quality", 92)))
    return path


def run(no_pubspec_patch: bool = False, clean_unused: bool = False) -> int:
    config = load_config()
    root = Path.cwd()
    out_dir = root / config["output_main_folder"]
    backup_root = root / config["backup_folder"]
    out_dir.mkdir(parents=True, exist_ok=True)
    backup_root.mkdir(parents=True, exist_ok=True)
    (root / config["manual_override_folder"]).mkdir(parents=True, exist_ok=True)
    (root / config["legacy_mirror_folder"]).mkdir(parents=True, exist_ok=True)

    if config.get("auto_patch_pubspec", True) and not no_pubspec_patch:
        changed = patch_pubspec(root)
        if changed:
            print("Patched pubspec.yaml: added assets/arc_raiders/items/")

    create_placeholder(root, config)

    print("Building item manifest from live GitHub repo...")
    app_items = build_reference_manifest(config, out_dir)
    print(f"Reference items found: {len(app_items)}")

    print("Scraping primary source: arcraiders.wiki Loot...")
    catalogue = scrape_arcraiders_wiki_loot(config, out_dir)
    print(f"Source images found: {len(catalogue)}")

    results: List[DownloadResult] = []
    hashes: Dict[str, List[str]] = {}
    written_files: set[Path] = set()

    for item in app_items:
        paths = unique_paths_for_item(item, config)
        main_rel = paths[0]
        main_dest = root / main_rel
        mirrored_paths = paths[1:]
        try:
            manual_img = copy_manual_override_if_exists(item, config, root)
            if manual_img is not None:
                processed = process_icon(manual_img, int(config["final_canvas_size"]), float(config["padding_ratio"]))
                source_name = "manual_override"
                source_url = None
                matched_name = item.name
            else:
                matched = match_item(item, catalogue, config)
                if not matched:
                    results.append(DownloadResult(item.id, item.name, None, None, None, main_rel, [], "missing", "No safe match found on arcraiders.wiki Loot."))
                    print(f"MISS {main_rel} <- {item.name}")
                    continue
                image = download_image(matched.url)
                processed = process_icon(image, int(config["final_canvas_size"]), float(config["padding_ratio"]))
                source_name = matched.source
                source_url = matched.url
                matched_name = matched.name

            for rel_path in paths:
                dest = root / rel_path
                backup_existing(dest, backup_root, root)
                write_webp(processed, dest, int(config["webp_quality"]))
                written_files.add(dest.relative_to(root))
            file_hash = hashlib.sha256(main_dest.read_bytes()).hexdigest()
            hashes.setdefault(file_hash, []).append(main_rel)
            results.append(DownloadResult(item.id, item.name, matched_name, source_name, source_url, main_rel, mirrored_paths, "ok"))
            print(f"OK   {main_rel} <- {item.name} :: {source_name} :: {matched_name}")
        except Exception as exc:
            results.append(DownloadResult(item.id, item.name, None, None, None, main_rel, [], "failed", str(exc)))
            print(f"FAIL {main_rel} <- {item.name} :: {exc}")

    ok = [r for r in results if r.status == "ok"]
    missing = [r for r in results if r.status == "missing"]
    failed = [r for r in results if r.status == "failed"]
    duplicates = {h: paths for h, paths in hashes.items() if len(paths) > 1}

    (out_dir / "arc_item_download_results.json").write_text(json.dumps([asdict(r) for r in results], indent=2), encoding="utf-8")
    (out_dir / "missing_asset_report.json").write_text(json.dumps([asdict(r) for r in missing + failed], indent=2), encoding="utf-8")
    (out_dir / "duplicate_asset_report.json").write_text(json.dumps(duplicates, indent=2), encoding="utf-8")

    if clean_unused:
        removed = []
        target_dirs = [root / config["output_main_folder"], root / config["legacy_mirror_folder"]]
        for folder in target_dirs:
            if not folder.exists():
                continue
            for file in folder.glob("*.webp"):
                rel = file.relative_to(root)
                if rel not in written_files:
                    backup_existing(file, backup_root, root)
                    file.unlink()
                    removed.append(str(rel))
        (out_dir / "clean_unused_removed_files.json").write_text(json.dumps(removed, indent=2), encoding="utf-8")
        print(f"Cleaned unused files: {len(removed)}")

    print("\nSUMMARY")
    print(f"  OK: {len(ok)}")
    print(f"  Missing: {len(missing)}")
    print(f"  Failed: {len(failed)}")
    print(f"  Reports: {out_dir}")
    return 0 if not failed else 2


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--no-pubspec-patch", action="store_true")
    parser.add_argument("--clean-unused", action="store_true")
    args = parser.parse_args()
    raise SystemExit(run(no_pubspec_patch=args.no_pubspec_patch, clean_unused=args.clean_unused))


if __name__ == "__main__":
    main()
