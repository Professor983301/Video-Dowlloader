#!/bin/bash

# ================================================================
#  VIDEO DOWNLOADER v1.1.0
#  Author : Afnan Samir
# ================================================================

VERSION="v1.1.0"
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
TMUX_SESSION="vdl"
HEADER_LINES=10

# -- Colors ------------------------------------------------------
R='\033[0;31m'      # Red
G='\033[0;32m'      # Green
Y='\033[1;33m'      # Yellow
C='\033[0;36m'      # Cyan
W='\033[1;37m'      # White Bold
M='\033[0;35m'      # Magenta
B='\033[0;34m'      # Blue
DIM='\033[2m'       # Dim
BOLD='\033[1m'      # Bold
N='\033[0m'         # Reset

# -- OS detect ---------------------------------------------------
detect_os() {
    if [ -d "/data/data/com.termux" ]; then
        OS_TYPE="android"
        BASE_SAVE="/sdcard/Download/VideoDownloader"
        TMP_DIR="/data/data/com.termux/files/usr/tmp"
    else
        OS_TYPE="linux"
        BASE_SAVE="$HOME/Downloads/VideoDownloader"
        TMP_DIR="/tmp"
    fi
    mkdir -p "$BASE_SAVE" "$TMP_DIR"
}
detect_os

# ================================================================
# FIRST TIME SETUP
# ================================================================
SETUP_FLAG="$BASE_SAVE/.data/setup_done"

first_time_setup() {
    clear 2>/dev/null
    echo ""
    echo -e "${C}  ================================================================${N}"
    echo -e "${W}          VIDEO DOWNLOADER - First Time Setup${N}"
    echo -e "${C}  ================================================================${N}"
    echo -e "${Y}  Setting up everything. This will take a few minutes...${N}"
    echo -e "${C}  ================================================================${N}"
    echo ""

    # Step 1: pkg update
    echo -e "${C}  [1/6] Updating package list...${N}"
    pkg update -y -q 2>/dev/null
    pkg upgrade -y -q 2>/dev/null
    echo -e "${G}  [OK] Packages updated${N}"
    echo ""

    # Step 2: storage permission
    echo -e "${C}  [2/6] Setting up storage permission...${N}"
    if [ ! -d "/sdcard/Download" ]; then
        termux-setup-storage
        sleep 3
    fi
    echo -e "${G}  [OK] Storage ready${N}"
    echo ""

    # Step 3: core packages
    echo -e "${C}  [3/6] Installing core packages...${N}"
    pkg install python ffmpeg nodejs ncurses-utils -y -q 2>/dev/null
    echo -e "${G}  [OK] Core packages installed${N}"
    echo ""

    # Step 4: pip + yt-dlp
    echo -e "${C}  [4/6] Installing yt-dlp...${N}"
    python -m ensurepip --upgrade -q 2>/dev/null || true
    pip install yt-dlp -q 2>/dev/null || pip3 install yt-dlp -q 2>/dev/null
    echo -e "${G}  [OK] yt-dlp installed${N}"
    echo ""

    # Step 5: Linux extras
    if [ "$OS_TYPE" = "linux" ]; then
        echo -e "${C}  [5/6] Installing Linux extras...${N}"
        sudo apt install tmux ncurses-bin -y -q 2>/dev/null ||         sudo pacman -S tmux --noconfirm -q 2>/dev/null || true
        echo -e "${G}  [OK] Linux extras ready${N}"
    else
        echo -e "${G}  [5/6] Skipped (Android)${N}"
    fi
    echo ""

    # Step 6: create data dir and flag
    echo -e "${C}  [6/6] Finalizing setup...${N}"
    mkdir -p "$DATA_DIR"
    touch "$SETUP_FLAG"
    echo -e "${G}  [OK] Setup complete${N}"
    echo ""

    echo -e "${C}  ================================================================${N}"
    echo -e "${G}          All done! Starting Video Downloader...${N}"
    echo -e "${C}  ================================================================${N}"
    sleep 2
}

# Run setup only on first time
if [ ! -f "$SETUP_FLAG" ]; then
    first_time_setup
else
    # Quick dependency check on every run
    if ! command -v yt-dlp &>/dev/null; then
        echo -e "${Y}  yt-dlp missing, reinstalling...${N}"
        pip install yt-dlp -q 2>/dev/null || pip3 install yt-dlp -q 2>/dev/null
    fi
    if ! command -v ffmpeg &>/dev/null; then
        echo -e "${Y}  ffmpeg missing, reinstalling...${N}"
        [ "$OS_TYPE" = "android" ] && pkg install ffmpeg -y -q ||         sudo apt install ffmpeg -y -q 2>/dev/null
    fi
fi

# -- Data files --------------------------------------------------
DATA_DIR="$BASE_SAVE/.data"
STATS_FILE="$DATA_DIR/stats.json"
COOKIE_FILE="$DATA_DIR/cookies.txt"
SETTINGS_FILE="$DATA_DIR/settings.json"
mkdir -p "$DATA_DIR"

[ ! -f "$STATS_FILE" ] && echo '{"total_downloads":0,"total_time":0}' > "$STATS_FILE"

[ ! -f "$SETTINGS_FILE" ] && cat > "$SETTINGS_FILE" << 'EOF'
{
  "speed_limit": "",
  "proxy": "",
  "parallel": 1,
  "save_thumbnail": false,
  "save_subtitle": false,
  "embed_metadata": true
}
EOF

get_setting() {
    python3 -c "
import json
try:
    d=json.load(open('$SETTINGS_FILE'))
    print(d.get('$1',''))
except: print('')
" 2>/dev/null
}

set_setting() {
    python3 -c "
import json
try: d=json.load(open('$SETTINGS_FILE'))
except: d={}
d['$1']=$2
json.dump(d,open('$SETTINGS_FILE','w'),indent=2)
" 2>/dev/null
}

# ================================================================
# AUTO INSTALL
# ================================================================
auto_install() {
    local TOOL="$1"
    echo -e "${Y}  >> Installing ${TOOL}...${N}"
    case "$TOOL" in
        yt-dlp)
            command -v pip3 &>/dev/null && pip3 install yt-dlp -q || pip install yt-dlp -q ;;
        ffmpeg)
            [ "$OS_TYPE" = "android" ] && pkg install ffmpeg -y -q || \
            sudo apt install ffmpeg -y -q 2>/dev/null || \
            sudo pacman -S ffmpeg --noconfirm -q 2>/dev/null ;;
        python3)
            [ "$OS_TYPE" = "android" ] && pkg install python -y -q || \
            sudo apt install python3 python3-pip -y -q 2>/dev/null ;;
        nodejs)
            [ "$OS_TYPE" = "android" ] && pkg install nodejs -y -q || \
            sudo apt install nodejs -y -q 2>/dev/null ;;
        tmux)
            [ "$OS_TYPE" = "android" ] && pkg install tmux -y -q || \
            sudo apt install tmux -y -q 2>/dev/null || \
            sudo pacman -S tmux --noconfirm -q 2>/dev/null ;;
    esac
    echo -e "${G}  >> [OK] ${TOOL} ready${N}"
}

check_and_fix_all() {
    echo -e "\n${DIM}${C}  Checking dependencies...${N}"
    command -v python3 &>/dev/null || auto_install python3
    command -v yt-dlp  &>/dev/null || auto_install yt-dlp
    command -v ffmpeg  &>/dev/null || auto_install ffmpeg
    command -v node    &>/dev/null || auto_install nodejs
    [ "$OS_TYPE" = "linux" ] && { command -v tmux &>/dev/null || auto_install tmux; }
    echo -e "${G}  All systems ready${N}\n"
}

auto_update_ytdlp() {
    echo -e "${DIM}${C}  Syncing yt-dlp...${N}"
    command -v pip3 &>/dev/null && pip3 install -U yt-dlp -q || pip install -U yt-dlp -q
    echo -e "${G}  yt-dlp synced${N}"
}

# ================================================================
# TMUX — Linux only
# ================================================================
launch_in_tmux() {
    # Android → skip tmux, run normally
    [ "$OS_TYPE" = "android" ] && return 1

    command -v tmux &>/dev/null || auto_install tmux
    command -v tmux &>/dev/null || return 1

    if [ -n "$TMUX" ]; then
        [ "$(tmux display-message -p '#S' 2>/dev/null)" = "$TMUX_SESSION" ] && return 0
    fi

    tmux kill-session -t "$TMUX_SESSION" 2>/dev/null
    local W H
    W=$(tput cols 2>/dev/null || echo 200)
    H=$(tput lines 2>/dev/null || echo 50)
    tmux new-session -d -s "$TMUX_SESSION" -x "$W" -y "$H"
    tmux split-window -v -t "$TMUX_SESSION" -l "$HEADER_LINES" -b
    tmux select-pane -t "$TMUX_SESSION:0.0"
    tmux send-keys -t "$TMUX_SESSION:0.0" "bash '$SCRIPT_PATH' --header-loop" Enter
    tmux select-pane -t "$TMUX_SESSION:0.1"
    tmux send-keys -t "$TMUX_SESSION:0.1" "bash '$SCRIPT_PATH' --main" Enter
    tmux attach-session -t "$TMUX_SESSION"
    exit 0
}

# ================================================================
# UI HELPERS
# ================================================================
get_width() {
    tput cols 2>/dev/null || echo 80
}

separator() {
    local char="${1:-=}" color="${2:-$C}"
    local w; w=$(get_width)
    printf "${color}"
    printf "%${w}s" | tr ' ' "$char"
    printf "${N}\n"
}

line() {
    local char="${1:--}" color="${2:-$DIM$C}"
    local w; w=$(get_width)
    printf "${color}"
    printf "%${w}s" | tr ' ' "$char"
    printf "${N}\n"
}

center_text() {
    local text="$1" color="${2:-$W}"
    local w; w=$(get_width)
    local len=${#text}
    local pad=$(( (w - len) / 2 ))
    [ $pad -lt 0 ] && pad=0
    printf "${color}%${pad}s%s${N}\n" "" "$text"
}

label() {
    local icon="$1" text="$2" color="${3:-$C}"
    echo -e "${color}  ${icon}  ${W}${text}${N}"
}

success_msg() { echo -e "${G}  [+] $1${N}"; }
error_msg()   { echo -e "${R}  [!] $1${N}"; }
warn_msg()    { echo -e "${Y}  [~] $1${N}"; }
info_msg()    { echo -e "${C}  [*] $1${N}"; }
dim_msg()     { echo -e "${DIM}      $1${N}"; }

# ================================================================
# BANNER
# ================================================================
draw_banner() {
    local w; w=$(get_width)
    local DT OS_LABEL
    DT=$(date '+%d %b %Y  |  %I:%M %p')
    [ "$OS_TYPE" = "android" ] && OS_LABEL="Android (Termux)" || OS_LABEL="Linux"

    clear 2>/dev/null || tput clear 2>/dev/null

    echo -e "${C}"
    if [ "$w" -ge 100 ]; then
        cat << 'BANNER'
        ┏┓┃┃┏┓┃┃┏┓┃┃┃┃┃┃
        ┃┗┓┏┛┃┃┃┃┃┃┃┃┃┃┃
        ┗┓┃┃┏┛┓━┛┃━━┓━━┓
        ┃┃┗┛┃┃┫┏┓┃┏┓┃┏┓┃
        ┃┗┓┏┛┃┃┗┛┃┃━┫┗┛┃
        ┃┃┗┛┃┃┛━━┛━━┛━━┛
        ┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃

┏━━━┓┃┃┃┃┃┃┃┃┃┃┃┓┃┃┃┃┃┃┃┃┃┏┓┃┃┃┃┃
┗┓┏┓┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃
┃┃┃┃┃━━┓┓┏┓┏┓━┓┃┃┃━━┓━━┓┃━┛┃━━┓━┓
┃┃┃┃┃┏┓┃┗┛┗┛┃┏┓┓┃┃┏┓┃┃┓┃┃┏┓┃┏┓┃┏┛
┏┛┗┛┃┗┛┃┓┏┓┏┛┃┃┃┗┓┗┛┃┗┛┗┓┗┛┃┃━┫┃┃
┗━━━┛━━┛┗┛┗┛┃┛┗┛━┛━━┛━━━┛━━┛━━┛┛┃
┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃┃
BANNER
        printf "${M}%${w}s${N}\n" "𝕬𝖋𝖓𝖆𝖓 𝕾𝖆𝖒𝖎𝖗  "
    elif [ "$w" -ge 50 ]; then
        echo ""
        echo ""
        # VIDEO — bigger, red, centered
        center_text "V  I  D  E  O" "${BOLD}\033[1;31m"
        center_text "D O W N L O A D E R" "${BOLD}\033[1;31m"
        echo ""
        center_text "𝕬𝖋𝖓𝖆𝖓 𝕾𝖆𝖒𝖎𝖗" "${M}"
        echo ""
    else
        echo ""
        center_text "VIDEO DOWNLOADER" "\033[1;31m"
        center_text "Afnan Samir" "${M}"
        echo ""
    fi

    echo -e "${N}"
    separator "="
    # Version info — centered
    local INFO="Version : ${VERSION}   |   ${DT}   |   ${OS_LABEL}"
    center_text "${INFO}" "${DIM}${W}"
    separator "="
    # Commands — centered between two lines
    line "-"
    center_text "link=download      st=stats      cfg=settings      q=quit" "${Y}"
    line "-"
    echo ""
}

header_loop() {
    tput civis 2>/dev/null
    while true; do
        draw_banner
        sleep 55
    done
}

# ================================================================
# STATS
# ================================================================
update_stats() {
    local SECS="$1"
    python3 -c "
import json
try: d=json.load(open('$STATS_FILE'))
except: d={'total_downloads':0,'total_time':0}
d['total_downloads']+=1
d['total_time']+=${SECS:-0}
json.dump(d,open('$STATS_FILE','w'))
" 2>/dev/null
}

show_stats() {
    separator "="
    center_text "STATISTICS" "${BOLD}${C}"
    line "-"
    python3 -c "
import json
try: d=json.load(open('$STATS_FILE'))
except: d={'total_downloads':0,'total_time':0}
t=int(d.get('total_time',0)); h,r=divmod(t,3600); m,s=divmod(r,60)
print(f'  Total Downloads : {d.get(\"total_downloads\",0)}')
print(f'  Total Time      : {h}h {m}m {s}s')
" 2>/dev/null
    separator "="
}

# ================================================================
# SETTINGS
# ================================================================
show_settings() {
    while true; do
        separator "="
        center_text "SETTINGS" "${BOLD}${C}"
        line "-"
        echo -e "  ${C}1.${N} Speed Limit    : ${W}$(get_setting speed_limit || echo unlimited)${N}"
        echo -e "  ${C}2.${N} Proxy          : ${W}$(get_setting proxy || echo none)${N}"
        echo -e "  ${C}3.${N} Parallel DLs   : ${W}$(get_setting parallel)${N}"
        echo -e "  ${C}4.${N} Save Thumbnail : ${W}$(get_setting save_thumbnail)${N}"
        echo -e "  ${C}5.${N} Save Subtitle  : ${W}$(get_setting save_subtitle)${N}"
        echo -e "  ${C}6.${N} Embed Metadata : ${W}$(get_setting embed_metadata)${N}"
        echo -e "  ${C}7.${N} Cookie file    : ${W}$([ -s "$COOKIE_FILE" ] && echo loaded || echo none)${N}"
        line "-"
        echo -ne "  ${Y}Select (1-7 / Enter=back): ${N}"
        read -r OPT
        case "$OPT" in
            1) echo -ne "  Speed limit (e.g. 2M / blank=unlimited): "; read -r V; set_setting speed_limit "\"$V\"" ;;
            2) echo -ne "  Proxy URL (blank=none): "; read -r V; set_setting proxy "\"$V\"" ;;
            3) echo -ne "  Parallel (1-5): "; read -r V; set_setting parallel "${V:-1}" ;;
            4) echo -ne "  Save thumbnail? (true/false): "; read -r V; set_setting save_thumbnail "$V" ;;
            5) echo -ne "  Save subtitle? (true/false): "; read -r V; set_setting save_subtitle "$V" ;;
            6) echo -ne "  Embed metadata? (true/false): "; read -r V; set_setting embed_metadata "$V" ;;
            7) echo -ne "  Cookie file path: "; read -r V
               [ -f "$V" ] && cp "$V" "$COOKIE_FILE" && success_msg "Cookie loaded" || error_msg "File not found" ;;
            *) break ;;
        esac
        success_msg "Saved"
    done
}

# ================================================================
# PLATFORM DETECT
# ================================================================
get_platform() {
    local URL="${1,,}"
    if   [[ "$URL" == *"youtube.com"* || "$URL" == *"youtu.be"* ]];  then echo "YouTube"
    elif [[ "$URL" == *"facebook.com"* || "$URL" == *"fb.watch"* ]]; then echo "Facebook"
    elif [[ "$URL" == *"instagram.com"* ]];   then echo "Instagram"
    elif [[ "$URL" == *"tiktok.com"* ]];      then echo "TikTok"
    elif [[ "$URL" == *"twitter.com"* || "$URL" == *"x.com"* ]]; then echo "Twitter"
    elif [[ "$URL" == *"vimeo.com"* ]];       then echo "Vimeo"
    elif [[ "$URL" == *"dailymotion.com"* ]]; then echo "Dailymotion"
    elif [[ "$URL" == *"twitch.tv"* ]];       then echo "Twitch"
    elif [[ "$URL" == *"soundcloud.com"* ]];  then echo "SoundCloud"
    elif [[ "$URL" == *"reddit.com"* ]];      then echo "Reddit"
    elif [[ "$URL" == *"rumble.com"* ]];      then echo "Rumble"
    elif [[ "$URL" == *"bilibili.com"* ]];    then echo "Bilibili"
    elif [[ "$URL" == *"pinterest.com"* ]];   then echo "Pinterest"
    elif [[ "$URL" == *"linkedin.com"* ]];    then echo "LinkedIn"
    elif [[ "$URL" == *"t.me"* ]];            then echo "Telegram"
    else
        echo "$1" | sed 's|https\?://||;s|www\.||;s|/.*||;s|\.[^.]*$||;s|.*\.||' \
            | awk '{print toupper(substr($0,1,1)) substr($0,2)}'
    fi
}

# ================================================================
# SAVE PATH
# ================================================================
get_save_path() {
    local PLATFORM; PLATFORM=$(get_platform "$1")
    if [ "$OS_TYPE" = "linux" ]; then
        echo -ne "  ${C}Save path${N} (Enter = ${DIM}${BASE_SAVE}/${PLATFORM}/${N}): "
        read -r CP
        if [ -n "$CP" ]; then mkdir -p "$CP"; echo "$CP"; return; fi
    fi
    local OUT="${BASE_SAVE}/${PLATFORM}"
    mkdir -p "$OUT"; echo "$OUT"
}

# ================================================================
# RESOLUTION MENU
# ================================================================
show_menu_simple() {
    line "-"
    printf "  ${BOLD}${C}%-4s  %-16s${N}\n" "#" "Resolution"
    line "-"
    echo -e "  ${W}1${N}     Best Quality"
    echo -e "  ${W}2${N}     2160p  (4K)"
    echo -e "  ${W}3${N}     1080p"
    echo -e "  ${W}4${N}     720p"
    echo -e "  ${W}5${N}     480p"
    echo -e "  ${W}6${N}     360p"
    echo -e "  ${W}7${N}     Audio  MP3"
    line "-"
}

# ================================================================
# FETCH VIDEO INFO
# ================================================================
fetch_and_show() {
    local URL="$1"
    echo -e "\n${DIM}${C}  Fetching video info...${N}"

    local TMP; TMP=$(mktemp "${TMP_DIR}/vdinfo_XXXXXX.json")
    yt-dlp --dump-single-json --skip-download --no-playlist \
           --quiet --no-warnings "$URL" > "$TMP" 2>/dev/null

    local SZ; SZ=$(wc -c < "$TMP" 2>/dev/null || echo 0)
    if [ "$SZ" -lt 10 ]; then
        rm -f "$TMP"
        warn_msg "Could not fetch info. Updating yt-dlp..."
        auto_update_ytdlp
        yt-dlp --dump-single-json --skip-download --no-playlist \
               --quiet --no-warnings "$URL" > "$TMP" 2>/dev/null
        SZ=$(wc -c < "$TMP" 2>/dev/null || echo 0)
        if [ "$SZ" -lt 10 ]; then
            rm -f "$TMP"
            warn_msg "Showing menu without size info."
            show_menu_simple; return 2
        fi
    fi

    python3 << PYEOF
import json, sys
try:
    with open("$TMP") as f: d=json.load(f)
except: sys.exit(1)

title=(d.get("title") or "?")[:60]
dur=d.get("duration") or 0
m,s=divmod(int(dur),60)

print(f"\n  \033[1;37m{title}\033[0m")
print(f"  \033[2m\033[0;36m{m}:{s:02d}\033[0m")

fmts=d.get("formats",[]); sm={}; az=0
for f in fmts:
    h=f.get("height"); fs=f.get("filesize") or f.get("filesize_approx") or 0
    vc=f.get("vcodec","none"); ac=f.get("acodec","none")
    if h and vc!="none" and fs:
        if h not in sm or fs>sm[h]: sm[h]=fs
    if vc=="none" and ac!="none" and fs>az: az=fs

def sz(b):
    if not b: return "  -"
    for u in ["B","KB","MB","GB"]:
        if b<1024: return f"{b:.1f} {u}"
        b/=1024
    return f"{b:.1f} GB"

rows=[("1","Best Quality",None),("2","2160p (4K)",2160),("3","1080p",1080),
      ("4","720p",720),("5","480p",480),("6","360p",360),("7","Audio MP3",None)]

print(f"\n  \033[2m\033[0;36m{'─'*40}\033[0m")
print(f"  \033[1m\033[1;37m{'#':<5}{'Resolution':<16}{'Size':>10}\033[0m")
print(f"  \033[2m\033[0;36m{'─'*40}\033[0m")
for k,label,h in rows:
    if k=="7": s2=sz(az)
    elif h: v=sm.get(h,0); s2=sz(v+az) if v else "  -"
    else:
        bh=max(sm.keys()) if sm else None
        v=sm.get(bh,0) if bh else 0; s2=sz(v+az) if v else "  -"
    print(f"  \033[0;36m{k}\033[0m     \033[1;37m{label:<16}\033[0m\033[2m{s2:>10}\033[0m")
print(f"  \033[2m\033[0;36m{'─'*40}\033[0m")
PYEOF

    local RET=$?; rm -f "$TMP"
    [ $RET -ne 0 ] && show_menu_simple && return 2
    return 0
}

# ================================================================
# HLS DETECT
# ================================================================
detect_hls() {
    local URL="$1"
    local TMP; TMP=$(mktemp "${TMP_DIR}/vdhls_XXXXXX.json")
    yt-dlp --dump-single-json --skip-download --quiet --no-warnings \
        --no-playlist "$URL" > "$TMP" 2>/dev/null
    python3 -c "
import json,sys
try:
    d=json.load(open('$TMP'))
    fmts=d.get('formats',[])
    is_hls=any('m3u8' in (f.get('url','') or f.get('manifest_url',''))
               or f.get('protocol','') in ('m3u8','m3u8_native')
               for f in fmts)
    sys.exit(0 if is_hls else 1)
except: sys.exit(1)
" 2>/dev/null
    local R=$?; rm -f "$TMP"; return $R
}

# ================================================================
# DOWNLOAD
# ================================================================
do_download() {
    local URL="$1" CHOICE="$2" IDX="$3" TOTAL="$4"

    # YouTube Mix/Radio check
    if echo "$URL" | grep -q "list=RD"; then
        error_msg "YouTube Mix/Radio not supported."
        dim_msg "Open the video directly and copy that URL instead."
        return 1
    fi

    # YouTube bot detection check
    if echo "$URL" | grep -qi "youtube\|youtu\.be"; then
        if [ ! -s "$COOKIE_FILE" ]; then
            warn_msg "No YouTube cookie found."
            dim_msg "If you get 'Sign in to confirm' error, add cookie via cfg > 7"
        fi
    fi

    case "$CHOICE" in
        1) FMT="bestvideo+bestaudio/best";               LABEL="Best Quality" ;;
        2) FMT="bestvideo[height<=2160]+bestaudio/best"; LABEL="2160p (4K)"   ;;
        3) FMT="bestvideo[height<=1080]+bestaudio/best"; LABEL="1080p"        ;;
        4) FMT="bestvideo[height<=720]+bestaudio/best";  LABEL="720p"         ;;
        5) FMT="bestvideo[height<=480]+bestaudio/best";  LABEL="480p"         ;;
        6) FMT="bestvideo[height<=360]+bestaudio/best";  LABEL="360p"         ;;
        7) FMT="bestaudio/best";                         LABEL="Audio MP3"    ;;
        *) error_msg "Invalid choice"; return 1 ;;
    esac

    local PLATFORM SAVE_PATH PREFIX=""
    PLATFORM=$(get_platform "$URL")
    SAVE_PATH=$(get_save_path "$URL")
    [ -n "$IDX" ] && PREFIX="[${IDX}/${TOTAL}] "

    separator "="
    echo -e "  ${DIM}${C}${PREFIX}Platform${N}  ${W}${PLATFORM}${N}"
    echo -e "  ${DIM}${C}${PREFIX}Quality ${N}  ${W}${LABEL}${N}"
    echo -e "  ${DIM}${C}${PREFIX}Folder  ${N}  ${W}${SAVE_PATH}${N}"
    line "-"

    # HLS detect
    local FRAG_COUNT=16
    if detect_hls "$URL"; then FRAG_COUNT=1; fi

    # Build flags
    local FLAGS=(
        --concurrent-fragments "$FRAG_COUNT"
        --buffer-size 16K
        --retries 15
        --fragment-retries 15
        --file-access-retries 5
        --socket-timeout 30
        --throttled-rate 100K
        --no-playlist
        --no-overwrites
        --output "$SAVE_PATH/%(title)s.%(ext)s"
    )
    [ "$FRAG_COUNT" -gt 1 ] && FLAGS+=(--http-chunk-size 10M)

    # Settings
    local SPD; SPD=$(get_setting speed_limit)
    [ -n "$SPD" ] && FLAGS+=(--rate-limit "$SPD")

    local PROXY; PROXY=$(get_setting proxy)
    [ -n "$PROXY" ] && FLAGS+=(--proxy "$PROXY")

    [ "$(get_setting save_thumbnail)" = "true" ] && FLAGS+=(--write-thumbnail)
    [ "$(get_setting save_subtitle)"  = "true" ] && FLAGS+=(--write-auto-sub --write-sub --sub-langs en)
    [ "$(get_setting embed_metadata)" = "true" ] && FLAGS+=(--add-metadata)
    [ -s "$COOKIE_FILE" ] && FLAGS+=(--cookies "$COOKIE_FILE")

    local START RET ELAPSED
    START=$(date +%s)

    if [ "$CHOICE" = "7" ]; then
        yt-dlp -f "$FMT" \
            --extract-audio --audio-format mp3 --audio-quality 0 \
            "${FLAGS[@]}" "$URL"
    else
        yt-dlp -f "$FMT" \
            --merge-output-format mp4 \
            "${FLAGS[@]}" "$URL"
    fi

    RET=$?
    ELAPSED=$(( $(date +%s) - START ))

    if [ $RET -eq 0 ]; then
        update_stats "$ELAPSED"
        separator "-"
        success_msg "Saved to: ${SAVE_PATH}"
        separator "-"
        return 0
    else
        # Check for bot detection
        error_msg "Download failed."
        if [ ! -s "$COOKIE_FILE" ]; then
            warn_msg "YouTube bot detected. Fix: add cookie via  cfg > 7"
        fi
        info_msg "Updating yt-dlp and retrying..."
        auto_update_ytdlp
        if [ "$CHOICE" = "7" ]; then
            yt-dlp -f "$FMT" --extract-audio --audio-format mp3 "${FLAGS[@]}" "$URL"
        else
            yt-dlp -f "$FMT" --merge-output-format mp4 "${FLAGS[@]}" "$URL"
        fi
        if [ $? -eq 0 ]; then
            update_stats "$ELAPSED"
            success_msg "Auto fix successful!"
            return 0
        fi
        error_msg "Failed after retry."
        return 1
    fi
}

# ================================================================
# PARALLEL DOWNLOAD
# ================================================================
do_parallel_download() {
    local CHOICE="$1"; shift
    local -a LINKS=("$@")
    local PAR; PAR=$(get_setting parallel); PAR="${PAR:-1}"
    [ "$PAR" -lt 1 ] 2>/dev/null && PAR=1
    [ "$PAR" -gt 5 ] 2>/dev/null && PAR=5

    local TOTAL=${#LINKS[@]} RUNNING=0 IDX=0 SUCCESS=0
    local -a PIDS=()

    info_msg "Parallel: ${PAR} at a time"

    while [ "$IDX" -lt "$TOTAL" ] || [ "$RUNNING" -gt 0 ]; do
        while [ "$RUNNING" -lt "$PAR" ] && [ "$IDX" -lt "$TOTAL" ]; do
            do_download "${LINKS[$IDX]}" "$CHOICE" "$((IDX+1))" "$TOTAL" &
            PIDS+=($!)
            IDX=$(( IDX + 1 ))
            RUNNING=$(( RUNNING + 1 ))
        done
        if [ "$RUNNING" -gt 0 ]; then
            wait "${PIDS[0]}"
            [ $? -eq 0 ] && SUCCESS=$(( SUCCESS + 1 ))
            PIDS=("${PIDS[@]:1}")
            RUNNING=$(( RUNNING - 1 ))
        fi
    done

    separator "="
    success_msg "Success : ${SUCCESS}/${TOTAL}"
    separator "="
}

# ================================================================
# MAIN LOOP
# ================================================================
main_loop() {
    check_and_fix_all
    auto_update_ytdlp
    draw_banner

    while true; do
        echo ""
        echo -e "${DIM}${C}  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -${N}"
        center_text "Enter link(s)" "${BOLD}${W}"
        echo -e "${DIM}  one per line  --  blank line to start${N}" 
        echo -e "${DIM}${C}  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -${N}"

        LINKS=()
        while true; do
            echo -ne "  ${C}>${N} "
            read -r LINE
            if [ -z "$LINE" ]; then
                [ ${#LINKS[@]} -gt 0 ] && break
                echo -e "${DIM}  Tip: enter a link, or type  st  cfg  q${N}"
                continue
            fi
            case "$LINE" in
                q)
                    separator "="
                    center_text "Goodbye!" "${G}"
                    separator "="
                    [ "$OS_TYPE" = "linux" ] && tmux kill-session -t "$TMUX_SESSION" 2>/dev/null
                    exit 0 ;;
                st)  show_stats ;;
                cfg) show_settings; draw_banner ;;
                *)
                    for PART in $(echo "$LINE" | tr ',' ' '); do
                        [[ "$PART" == http* ]] && LINKS+=("$PART")
                    done ;;
            esac
        done

        # Playlist / channel detect
        if [[ "${LINKS[0]}" == *"list="* ]] || [[ "${LINKS[0]}" == *"/channel/"* ]] || \
           [[ "${LINKS[0]}" == *"/c/"* ]]  || [[ "${LINKS[0]}" == *"/@"* ]]; then
            warn_msg "Playlist / Channel detected"
            echo -ne "  ${Y}Download all? (y=all / n=first only): ${N}"
            read -r PA
            [ "$PA" != "y" ] && LINKS[0]="${LINKS[0]}&playlist_items=1"
        fi

        if [ ${#LINKS[@]} -eq 1 ]; then
            fetch_and_show "${LINKS[0]}"
            [ $? -eq 1 ] && continue
        else
            info_msg "${#LINKS[@]} links queued"
            show_menu_simple
        fi

        echo ""
        echo -ne "  ${BOLD}${W}Quality${N} ${DIM}(1-7 / Enter=cancel)${N}: "
        read -r CHOICE
        [ "$CHOICE" = "q" ] && exit 0
        [ -z "$CHOICE" ] && continue
        [[ ! "$CHOICE" =~ ^[1-7]$ ]] && error_msg "Invalid choice" && continue

        PAR=$(get_setting parallel); PAR="${PAR:-1}"
        TOTAL=${#LINKS[@]}

        separator "="
        center_text "DOWNLOADING  ${TOTAL} VIDEO(S)" "${BOLD}${C}"
        dim_msg "Quality: ${CHOICE}   Parallel: ${PAR}"
        separator "="

        if [ "$PAR" -gt 1 ] && [ "$TOTAL" -gt 1 ]; then
            do_parallel_download "$CHOICE" "${LINKS[@]}"
        else
            SUCCESS=0; FAIL_LIST=()
            for i in "${!LINKS[@]}"; do
                do_download "${LINKS[$i]}" "$CHOICE" "$((i+1))" "$TOTAL"
                [ $? -eq 0 ] && SUCCESS=$((SUCCESS+1)) || FAIL_LIST+=("${LINKS[$i]}")
            done
            separator "="
            success_msg "Success : ${SUCCESS} / ${TOTAL}"
            [ ${#FAIL_LIST[@]} -gt 0 ] && error_msg "Failed  : ${#FAIL_LIST[@]}"
            for F in "${FAIL_LIST[@]}"; do dim_msg "- ${F}"; done
            dim_msg "Saved in: ${BASE_SAVE}/[Platform]/"
            separator "="
        fi
    done
}

# ================================================================
# ENTRY POINT
# ================================================================
case "${1:-}" in
    --header-loop)
        header_loop
        ;;
    --main)
        main_loop
        ;;
    *)
        if [ "$OS_TYPE" = "linux" ]; then
            launch_in_tmux
            # Fallback if tmux failed
            main_loop
        else
            # Android — normal run, no tmux
            main_loop
        fi
        ;;
esac
