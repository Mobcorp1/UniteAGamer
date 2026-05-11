#!/usr/bin/env python3
"""
UAG ARC Raiders Hub asset scraper for non-blueprint tracker/trading assets.

What it does:
- Uses the live rendered page from https://arcraidershub.com/needed-items-recycling-guide
- Extracts real item names and real image URLs from the page DOM. It does not guess names.
- Converts everything to .webp.
- Crops slightly inside each source image border.
- Writes assets for Scrappy Tracker, Bench Tracker, Quest Tracker and Trading Hub item usage.
- Produces reports for missing required images, unmatched scraped images and unused local images.

Run from project root:
  py tools\download_arc_raiders_hub_items.py

Optional cleanup after verifying assets:
  py tools\download_arc_raiders_hub_items.py --move-unused
"""
from __future__ import annotations

import argparse
import asyncio
import base64
import json
import mimetypes
import os
import re
import shutil
import sys
from dataclasses import dataclass, asdict
from io import BytesIO
from pathlib import Path
from typing import Any
from urllib.parse import urljoin

try:
    from PIL import Image, ImageOps
except ImportError:
    print("Missing dependency: pillow. Install with: py -m pip install pillow", file=sys.stderr)
    raise

SOURCE_URL = "https://arcraidershub.com/needed-items-recycling-guide"
OUT_DIR = Path("assets/arc_raiders/scrappy_resources")
ALL_ITEMS_DIR = Path("assets/arc_raiders/items")
REPORT_DIR = Path("assets/arc_raiders/_asset_reports")
LEGACY_UNUSED_DIR = Path("assets/arc_raiders/_legacy_unused_items")

DATA_FILES = [
    Path("lib/features/trading_hub/arc_raiders/data/arc_scrappy_seed_data.dart"),
    Path("lib/features/trading_hub/arc_raiders/data/arc_bench_upgrade_seed_data.dart"),
    Path("lib/features/trading_hub/arc_raiders/data/arc_quest_requirement_seed_data.dart"),
    Path("lib/features/trading_hub/arc_raiders/data/arc_trade_catalog.dart"),
    Path("lib/features/trading_hub/arc_raiders/data/trade_items_data.dart"),
]

BLUEPRINT_PATH_FRAGMENT = "/blueprints/"

ALIASES: dict[str, str] = {
    "apricot": "apricots",
    "lemon": "lemons",
    "prickly pear": "prickly pears",
    "very comfortable pillow": "very comfortable pillows",
    "wasp driver": "wasp drivers",
    "hornet driver": "hornet drivers",
    "snitch scanner": "snitch scanners",
    "leaper pulse unit": "leaper pulse units",
    "surveyor vault": "surveyor vaults",
    "fireball burner": "fireball burners",
    "rocketeer driver": "rocketeer drivers",
    "bastion cell": "bastion cells",
    "tick pod": "tick pods",
    "electrical component": "electrical components",
    "mechanical component": "mechanical components",
    "advanced electrical component": "advanced electrical components",
    "advanced mechanical component": "advanced mechanical components",
    "wire": "wires",
    "arc powercell": "arc powercells",
    "movie tapes": "stack of movie tapes",
    "stack of tapes": "stack of movie tapes",
}

SKIP_NAME_PARTS = [
    "blueprint",
]

@dataclass(frozen=True)
class RequiredAsset:
    display_name: str
    normalized_name: str
    file_name: str
    asset_path: str
    source_file: str
    usage: str

@dataclass
class ScrapedAsset:
    name: str
    normalized_name: str
    src: str
    page_section: str | None
    text: str


def slugify_name(name: str) -> str:
    clean = re.sub(r"\s+", " ", name.strip())
    clean = ALIASES.get(clean.lower(), clean)
    clean = clean.lower().replace("&", "and")
    clean = re.sub(r"[^a-z0-9]+", "_", clean)
    clean = re.sub(r"_+", "_", clean).strip("_")
    return clean


def normalize_name(name: str) -> str:
    clean = re.sub(r"\s+", " ", name.strip())
    clean = clean.replace("’", "'").replace("–", "-").replace("—", "-")
    clean = ALIASES.get(clean.lower(), clean)
    return clean.lower()


def parse_required_assets() -> dict[str, RequiredAsset]:
    required: dict[str, RequiredAsset] = {}
    for path in DATA_FILES:
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        if BLUEPRINT_PATH_FRAGMENT in text:
            # Keep this script strictly for non-blueprint assets.
            text = "\n".join(line for line in text.splitlines() if BLUEPRINT_PATH_FRAGMENT not in line)

        # Prefer explicit imageAsset + nearest itemName/name.
        for match in re.finditer(r"imageAsset:\s*'([^']+\.webp)'", text):
            asset_path = match.group(1)
            if BLUEPRINT_PATH_FRAGMENT in asset_path:
                continue
            start = max(0, match.start() - 500)
            block = text[start:match.start()]
            names = re.findall(r"(?:itemName|name):\s*'([^']+)'", block)
            display_name = names[-1] if names else Path(asset_path).stem.replace("_", " ").title()
            file_name = Path(asset_path).name
            usage = path.stem
            req = RequiredAsset(
                display_name=display_name,
                normalized_name=normalize_name(display_name),
                file_name=file_name,
                asset_path=asset_path,
                source_file=str(path),
                usage=usage,
            )
            required[req.normalized_name] = req

        # Also pick requirements that rely on _imageAssetForItemId mappings.
        for display_name in re.findall(r"itemName:\s*'([^']+)'", text):
            norm = normalize_name(display_name)
            file_name = f"{slugify_name(display_name)}.webp"
            required.setdefault(norm, RequiredAsset(
                display_name=display_name,
                normalized_name=norm,
                file_name=file_name,
                asset_path=f"assets/arc_raiders/scrappy_resources/{file_name}",
                source_file=str(path),
                usage=path.stem,
            ))
    return required


def infer_name_from_card(card: dict[str, Any]) -> str | None:
    candidates: list[str] = []
    for key in ["alt", "title", "aria", "heading", "name"]:
        value = str(card.get(key) or "").strip()
        if value:
            candidates.append(value)
    text = str(card.get("text") or "")
    if text:
        lines = [re.sub(r"\s+", " ", line).strip() for line in text.split("\n")]
        for line in lines:
            if not line or len(line) > 70:
                continue
            if re.search(r"^(common|uncommon|rare|epic|legendary|needed|safe|quest|station|crafting|recycle|keep|x\d+|\d+)$", line, re.I):
                continue
            if any(word in line.lower() for word in ["loading", "items", "filter", "recycling guide"]):
                continue
            candidates.append(line)
    for candidate in candidates:
        cleaned = re.sub(r"\.(png|jpg|jpeg|webp|avif)$", "", candidate, flags=re.I)
        cleaned = re.sub(r"[-_]+", " ", cleaned)
        cleaned = re.sub(r"\s+", " ", cleaned).strip(" -_\t\n")
        if 2 <= len(cleaned) <= 60 and not any(skip in cleaned.lower() for skip in SKIP_NAME_PARTS):
            return cleaned.title() if cleaned.islower() else cleaned
    return None


async def scrape_rendered_items(url: str) -> list[ScrapedAsset]:
    try:
        from playwright.async_api import async_playwright
    except ImportError:
        print("Missing dependency: playwright. Install with:")
        print("  py -m pip install playwright")
        print("  py -m playwright install chromium")
        raise

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page(viewport={"width": 1600, "height": 1200})
        await page.goto(url, wait_until="networkidle", timeout=90000)

        # Try to show all categories/items. The page is dynamic, so click all obvious filters/tabs.
        click_texts = [
            "All Items", "Safe to Recycle", "Quest Items", "Station Upgrades",
            "Expeditions", "Keep for Crafting", "Common", "Uncommon", "Rare", "Epic", "Legendary"
        ]
        for label in click_texts:
            try:
                locator = page.get_by_text(label, exact=True)
                count = await locator.count()
                if count:
                    await locator.first.click(timeout=1500)
                    await page.wait_for_timeout(600)
            except Exception:
                pass

        # Scroll repeatedly for lazy-loaded images/items.
        previous_height = 0
        for _ in range(24):
            height = await page.evaluate("document.body.scrollHeight")
            await page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
            await page.wait_for_timeout(700)
            if height == previous_height:
                break
            previous_height = height
        await page.evaluate("window.scrollTo(0, 0)")
        await page.wait_for_timeout(500)

        cards = await page.evaluate(r"""
        () => {
          const out = [];
          const imgs = Array.from(document.querySelectorAll('img'));
          for (const img of imgs) {
            const src = img.currentSrc || img.src || img.getAttribute('src') || '';
            if (!src || src.includes('Marathon') || src.includes('logo')) continue;
            let card = img.closest('article, li, .card, [class*=card], [class*=item], [data-item], section, div') || img.parentElement;
            let parent = card;
            for (let i = 0; i < 3 && parent && (parent.innerText || '').trim().length < 8; i++) parent = parent.parentElement;
            if (parent) card = parent;
            const heading = card ? (card.querySelector('h1,h2,h3,h4,h5,h6,[class*=title],[class*=name]')?.innerText || '') : '';
            let section = null;
            let walk = card;
            while (walk && walk !== document.body) {
              const prev = walk.previousElementSibling;
              if (prev && /^H[1-3]$/.test(prev.tagName)) { section = prev.innerText; break; }
              walk = walk.parentElement;
            }
            out.push({
              src,
              alt: img.alt || '',
              title: img.title || '',
              aria: img.getAttribute('aria-label') || '',
              heading,
              text: card ? (card.innerText || '') : '',
              section,
            });
          }
          return out;
        }
        """)
        await browser.close()

    scraped: list[ScrapedAsset] = []
    seen: set[tuple[str, str]] = set()
    for card in cards:
        name = infer_name_from_card(card)
        src = str(card.get("src") or "").strip()
        if not name or not src:
            continue
        norm = normalize_name(name)
        key = (norm, src)
        if key in seen:
            continue
        seen.add(key)
        scraped.append(ScrapedAsset(
            name=name,
            normalized_name=norm,
            src=src,
            page_section=card.get("section"),
            text=str(card.get("text") or "")[:400],
        ))
    return scraped


async def download_bytes(src: str, base_url: str) -> bytes:
    if src.startswith("data:"):
        header, payload = src.split(",", 1)
        return base64.b64decode(payload)
    from playwright.async_api import async_playwright
    async with async_playwright() as p:
        request = p.request
        context = await request.new_context(extra_http_headers={"User-Agent": "Mozilla/5.0"})
        response = await context.get(urljoin(base_url, src), timeout=90000)
        if not response.ok:
            raise RuntimeError(f"HTTP {response.status} {response.status_text}")
        data = await response.body()
        await context.dispose()
        return data


def crop_inside_border(img: Image.Image, crop_pct: float) -> Image.Image:
    img = ImageOps.exif_transpose(img).convert("RGBA")
    w, h = img.size
    inset_x = max(0, int(w * crop_pct))
    inset_y = max(0, int(h * crop_pct))
    if inset_x * 2 < w and inset_y * 2 < h:
        img = img.crop((inset_x, inset_y, w - inset_x, h - inset_y))
    return img


def normalise_canvas(img: Image.Image, size: int) -> Image.Image:
    img.thumbnail((size, size), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    x = (size - img.width) // 2
    y = (size - img.height) // 2
    canvas.alpha_composite(img, (x, y))
    return canvas


async def process_assets(args: argparse.Namespace) -> int:
    if not Path("pubspec.yaml").exists():
        print("Run this from the Flutter project root: C:\\Users\\mikem\\uag_traders_hub", file=sys.stderr)
        return 2

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    ALL_ITEMS_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_DIR.mkdir(parents=True, exist_ok=True)

    required = parse_required_assets()
    scraped = await scrape_rendered_items(args.url)
    scraped_by_norm: dict[str, ScrapedAsset] = {}
    for asset in scraped:
        scraped_by_norm.setdefault(asset.normalized_name, asset)
        scraped_by_norm.setdefault(normalize_name(asset.name.replace(" Of ", " of ")), asset)

    downloaded: list[dict[str, Any]] = []
    failures: list[dict[str, Any]] = []
    unmatched_scraped: list[dict[str, Any]] = []

    # Download all scraped images into all_items, then required tracker images into scrappy_resources.
    async def save_one(asset: ScrapedAsset, file_name: str, target_dir: Path) -> bool:
        try:
            raw = await download_bytes(asset.src, args.url)
            img = Image.open(BytesIO(raw))
            img = crop_inside_border(img, args.crop_pct)
            img = normalise_canvas(img, args.size)
            out_path = target_dir / file_name
            img.save(out_path, "WEBP", quality=args.quality, method=6)
            downloaded.append({"name": asset.name, "file": str(out_path), "source": asset.src})
            return True
        except Exception as exc:
            failures.append({"name": asset.name, "file": file_name, "source": asset.src, "error": str(exc)})
            return False

    for asset in scraped:
        await save_one(asset, f"{slugify_name(asset.name)}.webp", ALL_ITEMS_DIR)

    missing_required: list[dict[str, Any]] = []
    for norm, req in sorted(required.items(), key=lambda pair: pair[1].file_name):
        asset = scraped_by_norm.get(norm)
        if asset is None:
            missing_required.append(asdict(req))
            continue
        await save_one(asset, req.file_name, OUT_DIR)

    required_norms = set(required.keys())
    for asset in scraped:
        if asset.normalized_name not in required_norms:
            unmatched_scraped.append(asdict(asset))

    used_files = {req.file_name for req in required.values()}
    unused_existing = []
    for file in OUT_DIR.glob("*.webp"):
        if file.name not in used_files:
            unused_existing.append(str(file))
            if args.move_unused:
                LEGACY_UNUSED_DIR.mkdir(parents=True, exist_ok=True)
                shutil.move(str(file), str(LEGACY_UNUSED_DIR / file.name))

    reports = {
        "source_url": args.url,
        "downloaded_count": len(downloaded),
        "failure_count": len(failures),
        "missing_required_count": len(missing_required),
        "scraped_count": len(scraped),
        "required_count": len(required),
        "downloaded": downloaded,
        "failures": failures,
        "missing_required": missing_required,
        "unmatched_scraped": unmatched_scraped,
        "unused_existing": unused_existing,
    }
    (REPORT_DIR / "arc_raiders_hub_asset_report.json").write_text(json.dumps(reports, indent=2), encoding="utf-8")
    (REPORT_DIR / "required_assets_from_repo.json").write_text(json.dumps([asdict(v) for v in required.values()], indent=2), encoding="utf-8")
    (REPORT_DIR / "scraped_assets_from_arcraidershub.json").write_text(json.dumps([asdict(v) for v in scraped], indent=2), encoding="utf-8")

    print(f"Scraped: {len(scraped)}")
    print(f"Required from repo: {len(required)}")
    print(f"Downloaded/converted writes: {len(downloaded)}")
    print(f"Failures: {len(failures)}")
    print(f"Missing required: {len(missing_required)}")
    print(f"Report: {REPORT_DIR / 'arc_raiders_hub_asset_report.json'}")
    if missing_required:
        print("Missing required assets remain. Send me the report JSON if this number is not 0.")
    return 0 if not failures else 1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", default=SOURCE_URL)
    parser.add_argument("--size", type=int, default=512)
    parser.add_argument("--quality", type=int, default=88)
    parser.add_argument("--crop-pct", type=float, default=0.065, help="Crop percent from each edge to remove source border")
    parser.add_argument("--move-unused", action="store_true", help="Move unused existing .webp files to _legacy_unused_items after report generation")
    args = parser.parse_args()
    return asyncio.run(process_assets(args))

if __name__ == "__main__":
    raise SystemExit(main())
