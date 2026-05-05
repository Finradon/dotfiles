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
#alias z="zed ."
#alias c="code ."

function z
    if command -q zed
        zed .
    else
        open -a Zed .
    end
end
function c
    if command -q code
        code .
    else if test (uname) = "Darwin"
        open -a "Visual Studio Code" .
    else
        echo "VS Code command not found."
        return 1
    end
end
# go up fast
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'


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
abbr -a py python3
#abbr -a zed zeditor
abbr -a fw fwupdmgr
#abbr -a pac 'sudo pacman -Syu'

# =========================
# Python / venv
# =========================
alias venv='python3 -m venv .env'
alias va='source .env/bin/activate.fish'


# =========================
# System maintenance
# =========================

alias orphans='sudo pacman -Rns (pacman -Qtdq)'

function pac-clean
    set -l orphans (pacman -Qdtq)
    if test (count $orphans) -gt 0
        sudo pacman -Rns $orphans
    end
    sudo paccache -r
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
function acm
    git add -A
    git commit -m "$argv"
end

function can-merge --description "Check whether another branch can be merged into the current branch without changing anything"
    if test (count $argv) -ne 1
        echo "Usage: can-merge <branch>"
        return 2
    end

    set target_branch $argv[1]
    set current_branch (git branch --show-current 2>/dev/null)

    if test -z "$current_branch"
        echo "✗ Not inside a Git repository, or HEAD is detached."
        return 2
    end

    if not git rev-parse --verify --quiet "$target_branch" >/dev/null
        echo "✗ Branch or ref does not exist: $target_branch"
        return 2
    end

    echo "Checking whether '$target_branch' can be merged into '$current_branch'..."
    echo

    if git merge-tree --write-tree HEAD "$target_branch" >/dev/null 2>&1
        echo "✓ Merge possible"
        echo "  '$target_branch' can be merged into '$current_branch' cleanly."
        return 0
    else
        echo "✗ Merge would have conflicts"
        echo "  '$target_branch' cannot be merged into '$current_branch' cleanly."
        echo
        echo "No files were changed. No commit was created."
        return 1
    end
end
