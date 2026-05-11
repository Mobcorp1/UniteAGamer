#!/usr/bin/env python3
"""
UAG ARC Raiders Fandom asset pipeline.

Run from project root:
  py tools/download_arc_fandom_assets.py

What it does:
- Reads the live GitHub repo data files from tools/arc_fandom_asset_config.json.
- Builds a manifest from Scrappy, Bench, Quest and Trading Hub item names/IDs.
- Scrapes the ARC Raiders Fandom item/category pages, which expose static wiki item images.
- Matches app item names against Fandom names with exact, alias and safe fuzzy matching.
- Downloads the highest quality image URL available.
- Removes transparent padding, scales items up consistently, optionally bakes a dark card background.
- Converts to WebP.
- Saves to assets/arc_raiders/items and mirrors to existing app asset paths.
- Writes reference, catalogue, results, missing and duplicate reports.
"""
from __future__ import annotations

import argparse, hashlib, json, re, shutil, sys, urllib.parse
from dataclasses import dataclass, asdict
from io import BytesIO
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple

import requests
from bs4 import BeautifulSoup
from PIL import Image, ImageChops, ImageColor, ImageOps

CONFIG_PATH = Path(__file__).with_name("arc_fandom_asset_config.json")
STOP_WORDS = {"the","a","an","and","of","for","to","with","item","items","arc","raiders","image"}

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


def slugify(value: str) -> str:
    value = value.strip().lower().replace("+"," plus ").replace("&"," and ")
    value = re.sub(r"['’]", "", value)
    value = re.sub(r"[^a-z0-9]+", "_", value)
    return re.sub(r"_+", "_", value).strip("_") or "unknown_item"


def normalize(value: str) -> str:
    value = value.lower().strip().replace("+"," plus ").replace("&"," and ")
    value = re.sub(r"['’]", "", value)
    value = re.sub(r"\bmk\s*\.?\s*([ivx0-9]+)\b", r"mk\1", value)
    value = re.sub(r"[^a-z0-9]+", " ", value)
    parts = [p for p in value.split() if p not in STOP_WORDS]
    return " ".join(parts)


def singular_key(value: str) -> str:
    parts = normalize(value).split()
    out=[]
    for p in parts:
        if len(p)>3 and p.endswith("ies"):
            p=p[:-3]+"y"
        elif len(p)>3 and p.endswith("s") and not p.endswith("ss"):
            p=p[:-1]
        out.append(p)
    return " ".join(out)


def fetch(url: str) -> requests.Response:
    r=requests.get(url,timeout=60,headers={"User-Agent":"Mozilla/5.0 UAGAssetPipeline/2.0"})
    r.raise_for_status()
    return r


def raw_url(config: dict, rel_path: str) -> str:
    return config["repo_raw_base"].rstrip("/")+"/"+rel_path.lstrip("/")


def canonical_resource_id(item_id: str) -> str:
    mapping={
        "apricot":"apricots","lemon":"lemons","prickly-pear":"prickly-pears","very-comfortable-pillow":"very-comfortable-pillows",
        "wasp-driver":"wasp-drivers","hornet-driver":"hornet-drivers","rocketeer-driver":"rocketeer-drivers","bastion-cell":"bastion-cells",
        "sentinel-firing-core":"sentinel-firing-cores","industrial-battery":"industrial-batteries","power-cable":"power-cables",
        "pop-trigger":"pop-triggers","tick-pod":"tick-pods","snitch-scanner":"snitch-scanners","surveyor-vault":"surveyor-vaults",
        "leaper-pulse-unit":"leaper-pulse-units","damaged-heat-sink":"damaged-heat-sinks","fried-motherboard":"fried-motherboards",
        "arc-powercell":"arc-powercells","arc-motion-core":"arc-motion-cores","fireball-burner":"fireball-burners","bombardier-cell":"bombardier-cells",
        "motor":"motors","toaster":"toasters","wire":"wires","electrical-component":"electrical-components","mechanical-component":"mechanical-components",
        "advanced-electrical-component":"advanced-electrical-components","advanced-mechanical-component":"advanced-mechanical-components",
    }
    return mapping.get(item_id,item_id)


def display_name_for_id(name: str, canonical_id: str) -> str:
    overrides={
        "apricots":"Apricots","lemons":"Lemons","prickly-pears":"Prickly Pears","very-comfortable-pillows":"Very Comfortable Pillows",
        "wasp-drivers":"Wasp Drivers","hornet-drivers":"Hornet Drivers","rocketeer-drivers":"Rocketeer Drivers","bastion-cells":"Bastion Cells",
        "sentinel-firing-cores":"Sentinel Firing Cores","industrial-batteries":"Industrial Batteries","power-cables":"Power Cables",
        "pop-triggers":"Pop Triggers","tick-pods":"Tick Pods","snitch-scanners":"Snitch Scanners","surveyor-vaults":"Surveyor Vaults",
        "leaper-pulse-units":"Leaper Pulse Units","damaged-heat-sinks":"Damaged Heat Sinks","fried-motherboards":"Fried Motherboards",
        "arc-powercells":"ARC Powercells","arc-motion-cores":"ARC Motion Cores","fireball-burners":"Fireball Burners","bombardier-cells":"Bombardier Cells",
        "motors":"Motors","toasters":"Toasters","wires":"Wires"
    }
    return overrides.get(canonical_id,name)


def looks_like_item_name(name: str) -> bool:
    if not name or len(name)<2 or len(name)>80: return False
    bad={"Owned","Wanted","Missing","All","None","Search","Filter","Open","Close","Name","Icon","Rarity"}
    return name not in bad and not name.lower().startswith("assets/")


def extract_app_items_from_dart(text: str, source_file: str, config: dict) -> List[AppItem]:
    items=[]; seen=set()
    def add(item_id,name,paths=(),category="unknown"):
        if not looks_like_item_name(name): return
        if any(x.lower() in name.lower() for x in config.get("exclude_item_names_containing", [])): return
        blocked=tuple(config.get("exclude_asset_paths_containing",[]))
        paths=tuple(p for p in paths if not any(b in p for b in blocked))
        key=(item_id,name)
        if key in seen: return
        items.append(AppItem(item_id,name,source_file,paths,category)); seen.add(key)

    for m in re.finditer(r"ArcScrappyItem\s*\((?P<body>.*?)\)\s*,",text,re.DOTALL):
        body=m.group("body")
        id_m=re.search(r"\bid\s*:\s*'([^']+)'",body); name_m=re.search(r"\bname\s*:\s*'([^']+)'",body)
        cat_m=re.search(r"\bcategory\s*:\s*'([^']+)'",body)
        paths=tuple(re.findall(r"imageAsset\s*:\s*'([^']+)'",body))
        if id_m and name_m: add(canonical_resource_id(id_m.group(1)),display_name_for_id(name_m.group(1),canonical_resource_id(id_m.group(1))),paths,cat_m.group(1) if cat_m else "scrappy")

    for cls,catfield,catdefault in [("ArcBenchUpgradeRequirement","station","bench"),("ArcQuestRequirement","trader","quest")]:
        for m in re.finditer(cls+r"\s*\((?P<body>.*?)\)",text,re.DOTALL):
            body=m.group("body")
            id_m=re.search(r"\bitemId\s*:\s*'([^']+)'",body); name_m=re.search(r"\bitemName\s*:\s*'([^']+)'",body)
            cat_m=re.search(r"\b"+catfield+r"\s*:\s*'([^']+)'",body)
            if id_m and name_m:
                cid=canonical_resource_id(id_m.group(1)); name=display_name_for_id(name_m.group(1),cid)
                add(cid,name,(f"assets/arc_raiders/scrappy_resources/{cid.replace('-', '_')}.webp",),cat_m.group(1) if cat_m else catdefault)

    # Trade catalogue patterns; strict enough to avoid UI labels.
    for obj in re.finditer(r"\{(?P<body>[^{}]{0,1200})\}", text, re.DOTALL):
        body=obj.group("body")
        id_m=re.search(r"(?:\bid|\bitemId|\bvalue)\s*:\s*'([^']+)'",body)
        name_m=re.search(r"(?:\bname|\bitemName|\blabel)\s*:\s*'([^']+)'",body)
        if id_m and name_m:
            cid=canonical_resource_id(id_m.group(1)); name=display_name_for_id(name_m.group(1),cid)
            add(cid,name,(f"assets/arc_raiders/items/{slugify(name)}.webp",),"trade")
    return items


def dedupe_items(items: Iterable[AppItem]) -> List[AppItem]:
    merged={}
    for item in items:
        key=singular_key(item.name) or item.id
        if key not in merged:
            merged[key]=item
        else:
            old=merged[key]
            paths=tuple(dict.fromkeys(old.existing_asset_paths+item.existing_asset_paths))
            cats=old.category if item.category in old.category else old.category+","+item.category
            merged[key]=AppItem(old.id,old.name,old.source_file,paths,cats)
    return sorted(merged.values(),key=lambda x:(x.category,x.name.lower()))


def build_reference_manifest(config: dict) -> List[AppItem]:
    items=[]; errors=[]
    for rel in config["project_data_files"]:
        try: text=fetch(raw_url(config,rel)).text
        except Exception as exc:
            errors.append({"file":rel,"error":str(exc)}); continue
        items.extend(extract_app_items_from_dart(text,rel,config))
    out=Path(config["output_main_folder"]); out.mkdir(parents=True,exist_ok=True)
    if errors: (out/"github_fetch_errors.json").write_text(json.dumps(errors,indent=2),encoding="utf-8")
    return dedupe_items(items)


def fullsize_fandom_url(src: str, base: str) -> str:
    src=urllib.parse.urljoin(base,src)
    # Fandom thumbnail URLs commonly contain /revision/latest/scale-to-width-down/NNN.
    src=re.sub(r"/revision/latest/scale-to-width-down/\d+.*$","/revision/latest?format=original",src)
    src=re.sub(r"/revision/latest\?.*$","/revision/latest?format=original",src)
    return src


def clean_name(value: str) -> str:
    value=re.sub(r"\s+"," ",value or "").strip()
    value=re.sub(r"^Image:\s*","",value,flags=re.I)
    value=value.replace("PNG","").strip()
    return value


def scrape_fandom_catalogue(config: dict) -> Dict[str, dict]:
    urls=[config["source_items_url"]]+config.get("extra_source_urls",[])
    catalogue={}; raw=[]
    for url in urls:
        print(f"Scraping Fandom page: {url}")
        soup=BeautifulSoup(fetch(url).text,"html.parser")
        for img in soup.find_all("img"):
            src=img.get("data-src") or img.get("src") or ""
            if not src or "static.wikia" not in src: continue
            candidates=[]
            for attr in ("alt","title"):
                if img.get(attr): candidates.append(clean_name(img.get(attr)))
            a=img.find_parent("a")
            if a:
                if a.get("title"): candidates.append(clean_name(a.get("title")))
                href=a.get("href") or ""
                if href.startswith("/wiki/"):
                    candidates.append(clean_name(urllib.parse.unquote(href.split("/wiki/",1)[1]).replace("_"," ")))
            # Try row/item link name, especially for item tables.
            tr=img.find_parent("tr")
            if tr:
                links=[x for x in tr.find_all("a") if x.get_text(strip=True)]
                for link in links[:3]: candidates.append(clean_name(link.get_text(" ",strip=True)))
            for name in candidates:
                if not looks_like_item_name(name): continue
                key=normalize(name); skey=singular_key(name)
                if not key: continue
                full=fullsize_fandom_url(src,url)
                entry={"name":name,"src":full,"page":url,"candidates":candidates}
                raw.append(entry | {"key":key})
                catalogue.setdefault(key,entry)
                catalogue.setdefault(skey,entry)
        print(f"  catalogue size now: {len(catalogue)}")
    out=Path(config["output_main_folder"]); out.mkdir(parents=True,exist_ok=True)
    (out/"fandom_raw_image_catalogue.json").write_text(json.dumps(raw,indent=2),encoding="utf-8")
    return catalogue


def match_item(item: AppItem, catalogue: Dict[str,dict], config: dict) -> Optional[dict]:
    override=config.get("name_overrides",{}).get(item.id) or config.get("name_overrides",{}).get(slugify(item.name).replace("_","-"))
    candidates=[item.name,item.id.replace("-"," ")]
    if override: candidates.insert(0,override)
    for c in list(candidates):
        candidates += [c.rstrip("s"), c+"s"]
    for c in candidates:
        for key in (normalize(c), singular_key(c)):
            if key in catalogue: return catalogue[key]
    target=set(singular_key(override or item.name).split())
    if not target: return None
    best=None; best_score=0.0
    for key,data in catalogue.items():
        source=set(key.split())
        if not source: continue
        score=len(target & source)/max(len(target),len(source))
        if score>best_score: best=data; best_score=score
    return best if best_score>=0.86 else None


def trim_transparent(img: Image.Image) -> Image.Image:
    img=img.convert("RGBA")
    bbox=img.getchannel("A").getbbox()
    if bbox: return img.crop(bbox)
    bg=Image.new("RGBA",img.size,img.getpixel((0,0)))
    bbox=ImageChops.difference(img,bg).getbbox()
    return img.crop(bbox) if bbox else img


def process_image(img: Image.Image, config: dict) -> Image.Image:
    size=int(config.get("final_canvas_size",512)); fill=float(config.get("target_fill_ratio",0.84))
    item=trim_transparent(img)
    iw,ih=item.size
    if iw==0 or ih==0: item=img.convert("RGBA"); iw,ih=item.size
    max_side=max(iw,ih)
    target=max(1,int(size*fill))
    scale=target/max_side
    nw,nh=max(1,int(iw*scale)),max(1,int(ih*scale))
    item=item.resize((nw,nh),Image.Resampling.LANCZOS)
    if config.get("bake_dark_tile_background",True):
        bg=Image.new("RGBA",(size,size),ImageColor.getcolor(config.get("dark_tile_background","#071625"),"RGBA"))
    else:
        bg=Image.new("RGBA",(size,size),(0,0,0,0))
    bg.alpha_composite(item,((size-nw)//2,(size-nh)//2))
    return bg


def download_image(url: str) -> Image.Image:
    return Image.open(BytesIO(fetch(url).content)).convert("RGBA")


def backup_existing(path: Path, backup_root: Path, root: Path):
    if path.exists():
        rel=path.relative_to(root); dest=backup_root/rel; dest.parent.mkdir(parents=True,exist_ok=True)
        if not dest.exists(): shutil.copy2(path,dest)


def write_webp(img: Image.Image, dest: Path, quality: int):
    dest.parent.mkdir(parents=True,exist_ok=True)
    img.save(dest,"WEBP",quality=quality,method=6)


def run(clean_unused=False,dry_run=False):
    config=load_config(); root=Path.cwd(); out=root/config["output_main_folder"]; backup=root/config["backup_folder"]
    out.mkdir(parents=True,exist_ok=True); backup.mkdir(parents=True,exist_ok=True)
    print("Building manifest from GitHub repo...")
    app_items=build_reference_manifest(config)
    (out/"arc_item_reference_manifest.json").write_text(json.dumps([asdict(x) for x in app_items],indent=2),encoding="utf-8")
    print(f"Reference items: {len(app_items)}")
    print("Building image catalogue from Fandom...")
    catalogue=scrape_fandom_catalogue(config)
    print(f"Catalogue entries: {len(catalogue)}")
    results=[]; hashes={}
    for item in app_items:
        main_rel=f"{config['output_main_folder'].rstrip('/')}/{slugify(item.name)}.webp"; main=root/main_rel
        matched=match_item(item,catalogue,config)
        if not matched:
            print(f"MISS {Path(main_rel).name} <- {item.name}")
            results.append(DownloadResult(item.id,item.name,None,None,main_rel,[],"missing","No safe Fandom match found.")); continue
        try:
            mirrored=[]
            if not dry_run:
                img=process_image(download_image(matched["src"]),config)
                backup_existing(main,backup,root); write_webp(img,main,int(config.get("webp_quality",92)))
                if config.get("mirror_to_existing_asset_paths",True):
                    for p in item.existing_asset_paths:
                        if not p or p==main_rel: continue
                        if any(b in p for b in config.get("exclude_asset_paths_containing",[])): continue
                        dest=root/p; backup_existing(dest,backup,root); write_webp(img,dest,int(config.get("webp_quality",92))); mirrored.append(p)
                h=hashlib.sha256(main.read_bytes()).hexdigest(); hashes.setdefault(h,[]).append(main_rel)
            print(f"OK   {Path(main_rel).name} <- {item.name} :: {matched['name']}")
            results.append(DownloadResult(item.id,item.name,matched["name"],matched["src"],main_rel,mirrored,"ok"))
        except Exception as exc:
            print(f"FAIL {Path(main_rel).name} <- {item.name} :: {exc}")
            results.append(DownloadResult(item.id,item.name,matched.get("name"),matched.get("src"),main_rel,[],"failed",str(exc)))
    missing=[r for r in results if r.status!="ok"]; ok=[r for r in results if r.status=="ok"]
    dup={h:p for h,p in hashes.items() if len(p)>1}
    (out/"arc_item_download_results.json").write_text(json.dumps([asdict(r) for r in results],indent=2),encoding="utf-8")
    (out/"missing_asset_report.json").write_text(json.dumps([asdict(r) for r in missing],indent=2),encoding="utf-8")
    (out/"duplicate_asset_report.json").write_text(json.dumps(dup,indent=2),encoding="utf-8")
    print("\nSUMMARY")
    print(f"  OK: {len(ok)}")
    print(f"  Missing/failed: {len(missing)}")
    print(f"  Output: {out}")
    return 0 if not [r for r in results if r.status=="failed"] else 2

if __name__=="__main__":
    p=argparse.ArgumentParser()
    p.add_argument("--dry-run",action="store_true")
    p.add_argument("--clean-unused",action="store_true")
    a=p.parse_args(); raise SystemExit(run(clean_unused=a.clean_unused,dry_run=a.dry_run))
