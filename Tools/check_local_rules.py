#!/usr/bin/env python3
"""Same folder rules as LocalFolderReader.swift. Run: python3 Tools/check_local_rules.py <root>"""

import re
import sys
from pathlib import Path

COVERS = {"cover.jpg", "cover.png", "cover.webp", "poster.jpg", "poster.png", "folder.jpg"}
LYRIC = {"lrc", "srt", "ttml"}
SUBTITLE = {"srt", "ass", "ssa", "vtt"}
VIDEO = {"mp4", "mkv", "mov", "m4v", "webm"}
AUDIO = {"mp3", "flac", "m4a", "aac", "wav", "ogg"}
PAGE = {"jpg", "jpeg", "png", "webp"}
NOVEL = {"epub", "txt"}
CHAPTER = re.compile(r"^(chapter|chap|chương|chuong)[\s._-]*[0-9]+", re.I)
SEASON = re.compile(r"^season[\s._-]*[0-9]+", re.I)


def infer_names(names):
    exts = [Path(name).suffix.lower().lstrip(".") for name in names]
    if any(ext in NOVEL for ext in exts):
        return "novel"
    if any(ext in AUDIO for ext in exts):
        return "music"
    if any(ext in VIDEO for ext in exts):
        return "video"
    if any(SEASON.match(name) for name in names):
        return "video"
    if any(CHAPTER.match(name) for name in names):
        return "comic"
    if any(ext in PAGE or ext in {"cbz", "zip"} for ext in exts):
        return "comic"
    return None


def infer(path, names):
    direct = infer_names(names)
    if direct:
        return direct
    nested = []
    for name in names:
        child = path / name
        if not child.is_dir():
            continue
        child_names = [p.name for p in child.iterdir() if not p.name.startswith(".")]
        kind = infer_names(child_names)
        if kind:
            nested.append(kind)
    unique = set(nested)
    if len(unique) == 1:
        return unique.pop()
    return None


def loose_kind(path):
    ext = path.suffix.lower().lstrip(".")
    if ext in NOVEL:
        return "novel"
    if ext in {"cbz", "zip"}:
        return "comic"
    if ext in VIDEO:
        return "video"
    if ext in AUDIO:
        return "music"
    return None


def scan(root):
    found = []
    for child in sorted(root.iterdir(), key=lambda p: p.name.lower()):
        if child.name.startswith("."):
            continue
        if child.is_dir():
            names = [p.name for p in child.iterdir() if not p.name.startswith(".")]
            kind = infer(child, names)
            if not kind:
                continue
            cover = next((n for n in names if n.lower() in COVERS), None)
            extras = [n for n in names if Path(n).suffix.lower().lstrip(".") in LYRIC | SUBTITLE]
            found.append((kind, child.name, cover, extras))
        else:
            kind = loose_kind(child)
            if kind:
                found.append((kind, child.stem, None, []))
    return found


def main():
    root = Path(sys.argv[1] if len(sys.argv) > 1 else "Tools/fixtures/local")
    if not root.is_dir():
        print(f"missing fixture: {root}")
        return 1
    rows = scan(root)
    if not rows:
        print("no media")
        return 1
    for kind, title, cover, extras in rows:
        extra = f" extras={','.join(extras)}" if extras else ""
        poster = f" cover={cover}" if cover else ""
        print(f"{kind}\t{title}{poster}{extra}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
