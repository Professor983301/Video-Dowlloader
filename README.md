# Video-Dowlloader
This is self made tool for download all video.
**by Afnan Samir** | v1.1.0

A powerful command-line video downloader for Android (Termux) and Linux. Download videos from 1000+ websites with a single command.

---

## Quick Start

### Android (Termux)

**Step 1 — Install Termux**
Download Termux from [F-Droid](https://f-droid.org) (not Play Store).

**Step 2 — Download the script**
```bash
curl -o /sdcard/Download/downloader.sh https://raw.githubusercontent.com/Professor983301/Video-Downloader/main/downloader.sh
```

**Step 3 — Run**
```bash
bash /sdcard/Download/downloader.sh
```

That's it. Everything installs automatically on first run.

---

### Linux

**Step 1 — Download the script**
```bash
curl -o ~/downloader.sh https://raw.githubusercontent.com/Professor983301/Video-Downloader/main/downloader.sh
```

**Step 2 — Run**
```bash
bash ~/downloader.sh
```

---

## How to Use

1. Paste a video link and press Enter
2. Press Enter on a blank line to confirm
3. Select resolution (1-7)
4. Download starts automatically

**Commands:**
```
st     View statistics
cfg    Open settings
q      Quit
```

**Resolution options:**
```
1   Best Quality
2   2160p (4K)
3   1080p
4   720p
5   480p
6   360p
7   Audio MP3
```

---

## Features

- Download from 1000+ websites
- YouTube, Facebook, Instagram, TikTok, Twitter, Vimeo, Dailymotion, Twitch, SoundCloud, Reddit, Rumble, Bilibili, Pinterest, Telegram and more
- Multiple resolutions including 4K
- Audio-only MP3 download
- Batch download — paste multiple links at once
- Parallel download — download up to 5 videos simultaneously
- Platform folders — videos automatically sorted by platform
- HLS stream support — no conflicting range errors
- Auto retry — if download fails, automatically updates yt-dlp and retries
- Speed limit — control download speed from settings
- Proxy support — use a proxy from settings
- Thumbnail save — save video thumbnail alongside
- Subtitle download — download subtitles automatically
- Metadata embed — embed title, artist, date into file
- Cookie support — bypass bot detection with browser cookies
- Playlist and channel download support
- Auto rename — never overwrites existing files
- Statistics — track total downloads and time
- Responsive banner — adapts to screen size
- Linux sticky header — banner stays visible while downloading (via tmux)
- First-time auto setup — installs all dependencies automatically

---

## Supported Sites (Examples)

YouTube, Facebook, Instagram, TikTok, Twitter / X, Vimeo, Dailymotion, Twitch, SoundCloud, Reddit, Rumble, Bilibili, Pinterest, LinkedIn, Telegram, Snapchat and 1000+ more.

---

## Settings

Open settings by typing `cfg`:

| Option | Description |
|--------|-------------|
| Speed Limit | Limit download speed (e.g. 2M, 500K) |
| Proxy | Set a proxy URL |
| Parallel Downloads | Download 1-5 videos simultaneously |
| Save Thumbnail | Save video cover image |
| Save Subtitle | Download subtitles (English) |
| Embed Metadata | Embed title and info into file |
| Cookie File | Add browser cookies for bot bypass |

---

## YouTube Bot Detection Fix

If you see **"Sign in to confirm you're not a bot"** error:

1. Install Firefox on your device
2. Login to YouTube in Firefox
3. Open settings in the tool: type `cfg`
4. Select option `7` (Cookie file)
5. Follow the instructions

---

## Dependencies

All dependencies install automatically on first run.

| Tool | Purpose |
|------|---------|
| yt-dlp | Download engine |
| ffmpeg | Video/audio merge and convert |
| python3 | Settings and info processing |
| nodejs | YouTube JavaScript runtime |
| tmux | Sticky header on Linux |
| ncurses | Terminal screen handling |

---

## File Structure

```
VideoDownloader/
├── YouTube/
├── Facebook/
├── Instagram/
├── TikTok/
├── Twitter/
├── Vimeo/
└── .data/
    ├── settings.json
    ├── stats.json
    ├── cookies.txt
    └── setup_done
```

---

## Notes

- Downloaded files are saved to `/sdcard/Download/VideoDownloader/` on Android
- Downloaded files are saved to `~/Downloads/VideoDownloader/` on Linux
- Cookie file is never uploaded to GitHub (protected by .gitignore)
- YouTube Mix / Radio playlists are not supported — use direct video links instead

---

## License

Personal use only. Respect copyright laws in your region.
