from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import yt_dlp
import uvicorn
import re

app = FastAPI(title="StreamVault API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def health():
    return {"status": "StreamVault API running", "version": "2.0"}

# ── helpers ──────────────────────────────────────────────────────────────────

def _infer_height(f: dict) -> int | None:
    """Return the pixel height for a format dict, using every available hint."""
    h = f.get("height")
    if h:
        return int(h)

    # Try resolution / format_note / format strings  e.g. "1920x1080", "1080p", "4K"
    for field in ("resolution", "format_note", "format", "quality"):
        s = str(f.get(field) or "")
        m = re.search(r"x(\d{3,4})", s)
        if m:
            return int(m.group(1))
        m = re.search(r"(\d{3,4})[pP]", s)
        if m:
            return int(m.group(1))
        if "4k" in s.lower() or "2160" in s.lower():
            return 2160
        if "1440" in s.lower():
            return 1440
        if "1080" in s.lower():
            return 1080
        if "720" in s.lower():
            return 720

    # Fall back to width
    w = f.get("width")
    if w:
        thresholds = [(3840, 2160), (2560, 1440), (1920, 1080),
                      (1280, 720), (854, 480), (640, 360), (426, 240), (256, 144)]
        for min_w, mapped_h in thresholds:
            if w >= min_w:
                return mapped_h

    return None


def _build_label(height: int, note: str, fps) -> str:
    label = f"{height}p"
    note_up = note.upper()
    if "HDR" in note_up:
        label += " HDR"
    try:
        if float(fps or 0) >= 48:
            label += " 60fps"
    except Exception:
        pass
    if height >= 2160:
        label += " (4K Ultra HD)"
    elif height >= 1440:
        label += " (2K QHD)"
    elif height >= 1080:
        label += " (Full HD)"
    elif height >= 720:
        label += " (HD)"
    return label


def _is_truly_muxed(f: dict) -> bool:
    """
    A format is muxed (has BOTH video and audio in a single file) only when
    NEITHER vcodec NOR acodec is 'none'.
    YouTube's high-res adaptive streams always have acodec == 'none'.
    """
    vcodec = f.get("vcodec") or "none"
    acodec = f.get("acodec") or "none"
    has_video = vcodec != "none"
    has_audio = acodec != "none"
    return has_video and has_audio


# ── endpoint ─────────────────────────────────────────────────────────────────

from functools import lru_cache
import time

# Simple in-memory cache: url -> (timestamp, result)
_cache: dict = {}
_CACHE_TTL = 300  # 5 minutes

@app.get("/extract")
def extract_video(url: str):
    print(f"[extract] URL: {url}")

    # ── Cache check (DISABLED for troubleshooting) ───────────────────────────
    # now = time.time()
    # if url in _cache:
    #    ...
    
    # ── yt-dlp options ────────────────────────────────────────────────────────
    base_opts = {
        "quiet": True,
        "skip_download": True,
        "no_check_certificate": True,
        "ignoreerrors": True,
        "user_agent": (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/122.0.0.0 Safari/537.36"
        ),
    }

    info = None

    # Single attempt — use yt-dlp's own default clients
    try:
        with yt_dlp.YoutubeDL(base_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            print("[extract] ✅ Extraction succeeded")
    except Exception as e:
        print(f"[extract] ❌ Extraction failed: {e}")
        raise HTTPException(status_code=400, detail=str(e))

    if info is None:
        raise HTTPException(status_code=400, detail="Could not extract video info.")

    formats = info.get("formats") or []
    if not formats:
        raise HTTPException(status_code=400, detail="No formats found for this URL.")

    print(f"[extract] Raw formats available: {len(formats)}")

    # ── Collect the best video stream for each (height, is_hdr, is_60fps) bucket ──
    # Key: (height, is_hdr, is_hfr)  →  best format dict
    video_buckets: dict[tuple, dict] = {}

    for f in formats:
        # Must carry video
        vcodec = f.get("vcodec") or "none"
        if vcodec == "none":
            continue

        height = _infer_height(f)
        if not height or height < 100:          # skip tiny previews
            continue

        note = str(f.get("format_note") or "")
        fps  = f.get("fps") or 0
        try:
            fps = float(fps)
        except Exception:
            fps = 0.0

        is_hdr = "hdr" in note.lower()
        is_hfr = fps >= 48

        key = (height, is_hdr, is_hfr)

        # Prefer the format with the higher tbr/vbr (better quality)
        current_tbr = float(f.get("tbr") or f.get("vbr") or 0)
        if key not in video_buckets:
            video_buckets[key] = f
        else:
            existing_tbr = float(
                video_buckets[key].get("tbr") or video_buckets[key].get("vbr") or 0
            )
            if current_tbr > existing_tbr:
                video_buckets[key] = f

    # ── Find the best audio-only stream ──────────────────────────────────────
    audio_formats = [
        f for f in formats
        if (f.get("acodec") or "none") != "none"
        and (f.get("vcodec") or "none") == "none"
    ]
    # Sort by bitrate descending; pick the best
    audio_formats.sort(
        key=lambda f: float(f.get("abr") or f.get("tbr") or 0),
        reverse=True,
    )
    best_audio = audio_formats[0] if audio_formats else None
    audio_url  = best_audio.get("url") if best_audio else None

    print(f"[extract] unique video buckets: {len(video_buckets)}")
    if audio_url:
        print("[extract] best audio stream found")
    else:
        print("[extract] WARNING: no separate audio stream found")

    # ── Build the response resolutions list ──────────────────────────────────
    extracted: list[dict] = []

    for (height, is_hdr, is_hfr), f in video_buckets.items():
        note  = str(f.get("format_note") or "")
        fps   = f.get("fps") or 0
        label = _build_label(height, note, fps)

        is_muxed = _is_truly_muxed(f)

        # For a muxed stream the audio is embedded; for adaptive we supply the
        # separate audio URL so the Flutter side knows to mux with FFmpeg.
        entry = {
            "quality":     label,
            "height":      height,
            "format_id":   f.get("format_id"),
            "video_url":   f.get("url"),
            "ext":         f.get("ext") or "mp4",
            "vcodec":      f.get("vcodec") or "",
            "acodec":      f.get("acodec") or "none",
            "is_muxed":    is_muxed,
            "is_hdr":      is_hdr,
            "is_hfr":      is_hfr,
            "tbr":         f.get("tbr") or f.get("vbr") or 0,
            "audio_url":   None if is_muxed else audio_url,
        }
        extracted.append(entry)
        print(
            f"  ✅ {label:35s} | muxed={is_muxed} | "
            f"vcodec={f.get('vcodec','?')[:10]:10s} | "
            f"acodec={f.get('acodec','?')[:8]}"
        )

    if not extracted:
        # Absolute last-resort fallback
        best_url = info.get("url") or (formats[-1].get("url") if formats else None)
        if best_url:
            extracted.append({
                "quality":   "Best Available",
                "height":    info.get("height") or 720,
                "video_url": best_url,
                "ext":       info.get("ext") or "mp4",
                "vcodec":    info.get("vcodec") or "",
                "acodec":    info.get("acodec") or "none",
                "is_muxed":  True,
                "is_hdr":    False,
                "is_hfr":    False,
                "tbr":       0,
                "audio_url": None,
            })

    # Sort highest quality first
    extracted.sort(key=lambda x: (x["height"], x.get("tbr", 0)), reverse=True)

    result = {
        "id":          info.get("id"),
        "title":       info.get("title"),
        "thumbnail":   info.get("thumbnail"),
        "duration":    info.get("duration"),
        "author":      info.get("uploader") or info.get("uploader_id"),
        "resolutions": extracted,
        "audio_url":   audio_url,
    }

    # Save to cache
    _cache[url] = (time.time(), result)

    return result


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
