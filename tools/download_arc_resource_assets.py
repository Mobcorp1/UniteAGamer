#!/usr/bin/env python3
"""
ARC Raiders resource asset downloader for UAG Traders Hub.

Run from project root:
  python tools/download_arc_resource_assets.py

What it does:
- Reads the real Flutter seed files from lib/features/trading_hub/arc_raiders/data/.
- Extracts real item names + expected imageAsset paths.
- Tries multiple public ARC Raiders database URL patterns per item.
- Scrapes the item page for actual item image URLs instead of guessing one URL.
- Converts downloaded images to WebP and saves them to the asset path already used by the app.
- Writes missing_asset_report.json with exact unresolved items.

Requires:
  pip install requests pillow beautifulsoup4
"""

from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass, asdict
from io import BytesIO
from pathlib import Path
from typing import Iterable
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup
from PIL import Image

PROJECT_ROOT = Path.cwd()
DATA_DIR = PROJECT_ROOT / "lib" / "features" / "trading_hub" / "arc_raiders" / "data"
OUTPUT_ROOT = PROJECT_ROOT / "assets" / "arc_raiders" / "scrappy_resources"
REPORT_PATH = OUTPUT_ROOT / "missing_asset_report.json"
MANIFEST_PATH = OUTPUT_ROOT / "arc_resource_asset_manifest.json"

SEED_FILES = [
    DATA_DIR / "arc_scrappy_seed_data.dart",
    DATA_DIR / "arc_bench_upgrade_seed_data.dart",
    DATA_DIR / "arc_quest_requirement_seed_data.dart",
]

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
}

MANUAL_SLUGS = {
    "Dog Collar": ["dog-collar"],
    "Lemons": ["lemon", "lemons"],
    "Apricots": ["apricot", "apricots"],
    "Prickly Pears": ["prickly-pear", "prickly-pears"],
    "Olives": ["olive", "olives"],
    "Cat Bed": ["cat-bed"],
    "Mushrooms": ["mushroom", "mushrooms"],
    "Very Comfortable Pillows": ["very-comfortable-pillow", "very-comfortable-pillows"],
    "Wasp Drivers": ["wasp-driver", "wasp-drivers"],
    "Rusted Gears": ["rusted-gear", "rusted-gears"],
    "Sentinel Firing Cores": ["sentinel-firing-core", "sentinel-firing-cores"],
    "Pop Triggers": ["pop-trigger", "pop-triggers"],
    "Explosive Compounds": ["explosive-compound", "explosive-compounds"],
    "Rocketeer Drivers": ["rocketeer-driver", "rocketeer-drivers"],
    "Power Cables": ["power-cable", "power-cables"],
    "Hornet Drivers": ["hornet-driver", "hornet-drivers"],
    "Industrial Batteries": ["industrial-battery", "industrial-batteries"],
    "Bastion Cells": ["bastion-cell", "bastion-cells"],
    "Cracked Bioscanners": ["cracked-bioscanner", "cracked-bioscanners"],
    "Tick Pods": ["tick-pod", "tick-pods"],
    "Rusted Shut Medical Kits": ["rusted-shut-medical-kit", "rusted-shut-medical-kits"],
    "Surveyor Vaults": ["surveyor-vault", "surveyor-vaults"],
    "Damaged Heat Sinks": ["damaged-heat-sink", "damaged-heat-sinks"],
    "Snitch Scanners": ["snitch-scanner", "snitch-scanners"],
    "Fried Motherboards": ["fried-motherboard", "fried-motherboards"],
    "Leaper Pulse Units": ["leaper-pulse-unit", "leaper-pulse-units"],
    "ARC Powercells": ["arc-powercell", "arc-powercells"],
    "Toasters": ["toaster", "toasters"],
    "ARC Motion Cores": ["arc-motion-core", "arc-motion-cores"],
    "Fireball Burners": ["fireball-burner", "fireball-burners"],
    "Motors": ["motor", "motors"],
    "Bombardier Cells": ["bombardier-cell", "bombardier-cells"],
    "Stack Of Movie Tapes": ["stack-of-movie-tapes", "stack-of-movie-tape"],
    "Fireworks Box": ["fireworks-box"],
    "Espresso Machine Parts": ["espresso-machine-parts", "espresso-machine-part"],
    "Firefly Burner": ["firefly-burner"],
}

@dataclass(frozen=True)
class AssetTarget:
    name: str
    asset_path: str
    filename: str
    source_seed_files: tuple[str, ...]


def slugify(value: str) -> str:
    return re.sub(r"(^-+|-+$)", "", re.sub(r"[^a-z0-9]+", "-", value.lower())).strip("-")


def filename_to_slug(filename: str) -> str:
    return Path(filename).stem.replace("_", "-")


def singular_candidates(slug: str) -> list[str]:
    candidates = [slug]
    if slug.endswith("ies"):
        candidates.append(slug[:-3] + "y")
    if slug.endswith("es"):
        candidates.append(slug[:-2])
    if slug.endswith("s"):
        candidates.append(slug[:-1])
    return candidates


def unique(values: Iterable[str]) -> list[str]:
    seen = set()
    out = []
    for value in values:
        if value and value not in seen:
            out.append(value)
            seen.add(value)
    return out


def extract_targets() -> list[AssetTarget]:
    raw: dict[str, dict] = {}

    for seed_file in SEED_FILES:
        if not seed_file.exists():
            continue
        text = seed_file.read_text(encoding="utf-8", errors="ignore")

        # Direct ArcScrappyItem blocks contain name + imageAsset.
        for match in re.finditer(
            r"name:\s*'([^']+)'[\s\S]*?imageAsset:\s*'([^']+)'",
            text,
            flags=re.MULTILINE,
        ):
            name, asset_path = match.group(1), match.group(2)
            key = asset_path
            raw.setdefault(key, {"name": name, "asset_path": asset_path, "seeds": set()})["seeds"].add(seed_file.name)

        # Bench/quest requirement files often hold itemName and rely on generated _imageAssetForItemId.
        for match in re.finditer(
            r"itemId:\s*'([^']+)'\s*,\s*itemName:\s*'([^']+)'",
            text,
            flags=re.MULTILINE,
        ):
            item_id, name = match.group(1), match.group(2)
            filename = item_id.replace("-", "_") + ".webp"
            asset_path = f"assets/arc_raiders/scrappy_resources/{filename}"
            key = asset_path
            raw.setdefault(key, {"name": name, "asset_path": asset_path, "seeds": set()})["seeds"].add(seed_file.name)

    targets = [
        AssetTarget(
            name=value["name"],
            asset_path=value["asset_path"],
            filename=Path(value["asset_path"]).name,
            source_seed_files=tuple(sorted(value["seeds"])),
        )
        for value in raw.values()
    ]
    return sorted(targets, key=lambda item: item.filename)


def page_urls_for(target: AssetTarget) -> list[str]:
    name_slug = slugify(target.name)
    file_slug = filename_to_slug(target.filename)
    slugs = unique(
        MANUAL_SLUGS.get(target.name, [])
        + singular_candidates(name_slug)
        + singular_candidates(file_slug)
    )

    urls: list[str] = []
    for slug in slugs:
        urls.extend(
            [
                f"https://ardb.tools/items/{slug}",
                f"https://ardb.app/db/items/{slug}",
                f"https://metaforge.app/arc-raiders/database/item/{slug}",
            ]
        )
    return unique(urls)


def image_urls_from_page(html: str, base_url: str, target: AssetTarget) -> list[str]:
    soup = BeautifulSoup(html, "html.parser")
    urls: list[str] = []

    for selector in [
        ("meta", {"property": "og:image"}),
        ("meta", {"name": "twitter:image"}),
    ]:
        for tag in soup.find_all(*selector):
            content = tag.get("content")
            if content:
                urls.append(urljoin(base_url, content))

    target_words = set(slugify(target.name).split("-"))
    for img in soup.find_all("img"):
        src = img.get("src") or img.get("data-src") or img.get("data-nimg")
        if not src:
            continue
        alt_title = f"{img.get('alt', '')} {img.get('title', '')} {src}".lower()
        score = sum(1 for word in target_words if word and word in alt_title)
        if score > 0 or "item" in alt_title or "icons" in alt_title or "image" in alt_title:
            urls.append(urljoin(base_url, src))

    # Prefer non-logo/non-ui images.
    filtered = []
    for url in unique(urls):
        lower = url.lower()
        if any(blocked in lower for blocked in ["logo", "discord", "avatar", "favicon", "banner"]):
            continue
        filtered.append(url)
    return filtered or unique(urls)


def request_url(url: str) -> requests.Response | None:
    try:
        response = requests.get(url, headers=HEADERS, timeout=25, allow_redirects=True)
        if response.status_code == 200:
            return response
    except requests.RequestException:
        return None
    return None


def save_webp_from_bytes(content: bytes, output_path: Path) -> bool:
    try:
        with Image.open(BytesIO(content)) as image:
            image = image.convert("RGBA") if image.mode in {"RGBA", "LA", "P"} else image.convert("RGB")
            output_path.parent.mkdir(parents=True, exist_ok=True)
            image.save(output_path, "WEBP", quality=92, method=6)
            return True
    except Exception:
        return False


def download_target(target: AssetTarget) -> tuple[bool, dict]:
    output_path = PROJECT_ROOT / target.asset_path
    tried_pages: list[str] = []
    tried_images: list[str] = []

    for page_url in page_urls_for(target):
        tried_pages.append(page_url)
        page = request_url(page_url)
        if not page:
            continue

        image_urls = image_urls_from_page(page.text, page_url, target)
        for image_url in image_urls:
            tried_images.append(image_url)
            image = request_url(image_url)
            if not image:
                continue
            if save_webp_from_bytes(image.content, output_path):
                return True, {
                    "name": target.name,
                    "assetPath": target.asset_path,
                    "filename": target.filename,
                    "sourcePage": page_url,
                    "sourceImage": image_url,
                    "sourceSeedFiles": target.source_seed_files,
                }

    return False, {
        "name": target.name,
        "assetPath": target.asset_path,
        "filename": target.filename,
        "sourceSeedFiles": target.source_seed_files,
        "triedPages": tried_pages,
        "triedImages": tried_images,
    }


def main() -> int:
    targets = extract_targets()
    if not targets:
        print("No asset targets found. Run this from the Flutter project root.")
        return 2

    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    downloaded = []
    missing = []

    print(f"Found {len(targets)} real asset targets from seed files.")
    for target in targets:
        output_path = PROJECT_ROOT / target.asset_path
        if output_path.exists() and output_path.stat().st_size > 0:
            print(f"SKIP {target.filename} <- {target.name}")
            downloaded.append(asdict(target) | {"status": "already_exists"})
            continue

        ok, details = download_target(target)
        if ok:
            print(f"OK   {target.filename} <- {target.name}")
            downloaded.append(details | {"status": "downloaded"})
        else:
            print(f"MISS {target.filename} <- {target.name}")
            missing.append(details | {"status": "missing"})

    manifest = {
        "generatedFrom": [str(path.relative_to(PROJECT_ROOT)) for path in SEED_FILES if path.exists()],
        "outputRoot": str(OUTPUT_ROOT.relative_to(PROJECT_ROOT)),
        "downloadedCount": len(downloaded),
        "missingCount": len(missing),
        "downloaded": downloaded,
        "missing": missing,
    }
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    REPORT_PATH.write_text(json.dumps(missing, indent=2), encoding="utf-8")

    print(f"Completed with {len(missing)} missing. Report: {REPORT_PATH}")
    return 0 if not missing else 1


if __name__ == "__main__":
    raise SystemExit(main())
