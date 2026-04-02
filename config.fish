# =========================
# Interactive guard
# =========================
if status is-interactive
    # Commands to run in interactive sessions can go here
end


# =========================
# Prompt / env hooks
# =========================
starship init fish | source
# direnv hook fish | source
source "$HOME/.cargo/env.fish"


# =========================
# Shell behavior
# =========================
set fish_greeting ""


# =========================
# Quick navigation / open
# =========================
alias n="gio open ."
alias z="zeditor ."
alias c="code ."

# go up fast
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# =========================
# Servers
# =========================
# abbr -a gondolin ssh finradon@gondolin.whydah-truck.ts.net
abbr -a gondolin ssh finradon@100.73.220.71
abbr -a workstation "ssh 'ADS\ga27guz'@10.152.49.108"
# =========================
# Editor / config shortcuts
# =========================
alias fishconfig="micro ~/repos/dotfiles/config.fish"
alias kittyconf="micro ~/repos/dotfiles/kitty.conf"


# =========================
# Command replacements (interactive-only)
# =========================
abbr -a ls eza
abbr -a ll 'eza -la'
abbr -a cat bat
abbr -a nano micro
abbr -a py python
abbr -a zed zeditor
abbr -a fw fwupdmgr
abbr -a pac 'sudo pacman -Syu'
abbr -a dsa 'codex resume 019ced71-2717-7ed0-95c3-6224c45430c0'
# =========================
# Python / venv
# =========================
alias venv='python -m venv .env'
alias va='source .env/bin/activate.fish'


# =========================
# System maintenance
# =========================

#alias orphans='sudo pacman -Rns (pacman -Qtdq)'

#function pac-clean
#    set -l orphans (pacman -Qdtq)
#    if test (count $orphans) -gt 0
#        sudo pacman -Rns $orphans
#    end
#    sudo paccache -r
#end
function pac-clean --description "Deep Arch cleanup (pacman, AUR, flatpak, journal)"

    echo "==> Removing orphaned packages..."
    set orphans (pacman -Qtdq 2>/dev/null)

    if test -n "$orphans"
        sudo pacman -Rns $orphans
    else
        echo "No orphaned packages found."
    end

    echo ""

    # Pacman cache pre-clean: remove temp download files
    echo "==> Removing pacman temp download files..."
    sudo find /var/cache/pacman/pkg -maxdepth 1 -type f \( -name 'download-*' -o -name '*.part' \) -print -delete
    
    # Pacman cache cleanup
    if test "$argv[1]" = "--full"
        echo "==> Removing ALL pacman cached packages..."
        sudo paccache -ruk0
    else
        echo "==> Cleaning pacman cache (keeping last 3 versions)..."
        sudo paccache -r
    end

    echo ""

    # AUR cache
    if type -q paru
        echo "==> Cleaning paru cache..."
        if test "$argv[1]" = "--full"
            paru -Sc --noconfirm
        else
            paru -Sc
        end
    else if type -q yay
        echo "==> Cleaning yay cache..."
        if test "$argv[1]" = "--full"
            yay -Sc --noconfirm
        else
            yay -Sc
        end
    else
        echo "No AUR helper (paru/yay) detected."
    end

    echo ""

    # Flatpak cleanup
    if type -q flatpak
        echo "==> Removing unused flatpak runtimes..."
        flatpak uninstall --unused -y
    else
        echo "Flatpak not installed."
    end

    echo ""

    # Journal cleanup (older than 2 weeks)
    echo "==> Vacuuming journal logs (older than 2 weeks)..."
    sudo journalctl --vacuum-time=2weeks

    echo ""
    echo "==> Cleanup complete."
end

# =========================
# Functions
# =========================
function remindme
    if test (count $argv) -lt 2
        echo "Usage: remindme <minutes> <message>"
        return 1
    end

    set -l minutes $argv[1]
    if not string match -qr '^[0-9]+$' -- $minutes
        echo "minutes must be an integer"
        return 1
    end

    set -l message (string join " " $argv[2..-1])
    echo "Reminder set for $minutes minute(s): $message"

    set -l seconds (math "$minutes * 60")
    begin
        sleep $seconds
        notify-send 'Reminder' "$message"
    end &
end

function mkcd
    if test (count $argv) -ne 1
        echo "usage: mkcd <dir>"
        return 1
    end
    mkdir -p "$argv"
    and cd "$argv"
end

function push
    if test (count $argv) -lt 1
        echo "usage: push <message>"
        return 1
    end

    if not set -q PUSHOVER_USER; or not set -q PUSHOVER_TOKEN
        echo "Pushover not configured. Set PUSHOVER_USER and PUSHOVER_TOKEN."
        return 1
    end

    set -l msg (string join " " $argv)

    curl -s \
        -F "token=$PUSHOVER_TOKEN" \
        -F "user=$PUSHOVER_USER" \
        -F "message=$msg" \
        https://api.pushover.net/1/messages.json \
        >/dev/null
end

function mkvenv
    python -m venv .env
    source .env/bin/activate.fish
end

function up
    set -l n 1
    if test (count $argv) -eq 1
        set n $argv[1]
    end
    for i in (seq $n)
        cd ..
    end
end

function ytmp3
    if test (count $argv) -ne 2
        echo "Usage: ytmp3 <youtube_link> <name>"
        return 1
    end

    set url $argv[1]
    set name $argv[2]

    set target_dir ~/Music/Audio_Projects/$name
    set output_file "$target_dir/$name.%(ext)s"

    # create directory if it doesn't exist
    mkdir -p $target_dir

    # download and convert to mp3
    yt-dlp \
        --extract-audio \
        --audio-format mp3 \
        --audio-quality 0 \
        -o $output_file \
        $url

    if test $status -eq 0
        echo "Downloaded to $target_dir/$name.mp3"
    else
        echo "Download failed"
        return 1
    end
end

function audio2mp4
    # defaults
    set thumbnail "cover.png"
    set audio "input.mp3"

    # override if provided
    if test (count $argv) -ge 1
        set thumbnail $argv[1]
    end
    if test (count $argv) -ge 2
        set audio $argv[2]
    end

    # basic checks
    if not test -f $thumbnail
        echo "Thumbnail not found: $thumbnail"
        return 1
    end

    if not test -f $audio
        echo "Audio file not found: $audio"
        return 1
    end

    # output file = same name as audio, but .mp4
    set output (string replace -r '\.[^.]+$' '.mp4' $audio)

    ffmpeg -y \
        -loop 1 -i $thumbnail \
        -i $audio \
        -c:v libx264 \
        -tune stillimage \
        -c:a aac \
        -b:a 192k \
        -pix_fmt yuv420p \
        -shortest \
        $output

    if test $status -eq 0
        echo "Created: $output"
    else
        echo "ffmpeg failed"
        return 1
    end
end
