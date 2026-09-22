#!/usr/bin/env python3
"""Same rules as Sources/MeineCore. Runs where swiftc is absent."""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEMO = ROOT / "docs" / "examples" / "local-demo"
ID_RE = re.compile(r"^[a-z0-9._-]{3,80}$")
SEMVER_RE = re.compile(r"^\d+\.\d+\.\d+$")
KINDS = {
    "video.movie", "video.shortFilm", "video.clip", "video.album",
    "audio.track", "comic.series", "text.book",
}
SECTIONS = {"hero", "rail", "grid", "list", "continue", "banner", "genreChips", "feed", "spacer"}
failures = []


def expect(cond, name):
    if not cond:
        failures.append(name)


def norm_hex(raw):
    if not raw:
        return None
    text = raw.strip()
    if text.startswith("#"):
        text = text[1:]
    if len(text) != 6 or any(c not in "0123456789abcdefABCDEF" for c in text):
        return None
    return "#" + text.upper()


def safe_relative(value):
    text = value.strip()
    if not text or text.startswith("/") or "\\" in text or "://" in text:
        return False
    parts = text.split("/")
    if ".." in parts or "." in parts or "" in parts:
        return False
    return True


def parse_manifest(obj):
    if obj.get("schemaVersion") != 1:
        return None, "badVersion"
    if not ID_RE.match(str(obj.get("id", ""))):
        return None, "badID"
    name = obj.get("name") or ""
    if not name or len(name) > 60:
        return None, "missing name"
    if not SEMVER_RE.match(str(obj.get("version", ""))):
        return None, "missing version"
    kinds = []
    for kind in obj.get("kinds") or []:
        if kind in KINDS and kind not in kinds:
            kinds.append(kind)
    if not kinds:
        return None, "noKinds"
    home = obj.get("home")
    if not isinstance(home, dict):
        return None, "homeMissing"
    modes = sum(k in home for k in ("ref", "inline", "tabs"))
    if modes != 1:
        return None, "homeMissing"
    if "ref" in home and not safe_relative(home["ref"]):
        return None, "homeMissing"
    catalog = (obj.get("endpoints") or {}).get("catalog")
    if not isinstance(catalog, str):
        return None, "catalogMissing"
    return {"id": obj["id"], "kinds": kinds}, None


def main():
    minimal = {
        "schemaVersion": 1, "id": "local.ten.sach", "name": "Sach",
        "version": "0.1.0", "kinds": ["text.book"],
        "home": {"ref": "catalog/home.json"}, "endpoints": {"catalog": "catalog/"},
    }
    parsed, err = parse_manifest(minimal)
    expect(err is None and parsed["id"] == "local.ten.sach", "minimal")
    _, err = parse_manifest({**minimal, "id": "BAD ID"})
    expect(err == "badID", "bad id")
    _, err = parse_manifest({**minimal, "home": {"ref": "a.json", "inline": {}}})
    expect(err == "homeMissing", "two homes")
    parsed, err = parse_manifest({**minimal, "kinds": ["text.book", "nope"]})
    expect(err is None and parsed["kinds"] == ["text.book"], "drop kind")
    expect(not safe_relative("../secret"), "dotdot")
    expect(safe_relative("catalog/home.json"), "relative")
    expect(norm_hex("7ec8c3") == "#7EC8C3", "hex")
    expect(norm_hex("zzz") is None, "bad hex")

    demo = json.loads((DEMO / "manifest.json").read_text())
    parsed, err = parse_manifest(demo)
    expect(err is None, "demo manifest %s" % err)
    home_path = DEMO / demo["home"]["ref"]
    expect(home_path.exists(), "demo home exists")
    home = json.loads(home_path.read_text())
    seen = set()
    for section in home["sections"]:
        expect(section["id"] not in seen, "dup %s" % section["id"])
        seen.add(section["id"])
        expect(section["type"] in SECTIONS, "type %s" % section["type"])
    expect((DEMO / "lyrics" / "song.lrc").exists(), "lrc")
    expect((DEMO / "media" / "chapter-1.txt").exists(), "chapter")
    if failures:
        print("FAIL")
        for item in failures:
            print(" -", item)
        return 1
    print("ok", parsed["id"], "sections", len(home["sections"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
