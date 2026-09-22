#!/usr/bin/env bash
# Synchronize generated helper files without overwriting host-specific edits.
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
: "${HOME:?HOME must be set}"
state_dir="$HOME/.local/share/hpc-setup/managed"
mkdir -p "$state_dir"

sync_file() {
    local name=$1 template=$2 target=$3 state="$state_dir/$1"
    mkdir -p "$(dirname "$target")"

    # A symlink may belong to an existing personal setup; never replace it.
    if [[ -L "$target" ]]; then
        printf 'Keeping symlink: %s\n' "$target"
        return 0
    fi

    if [[ ! -e "$target" ]]; then
        cp "$template" "$target"
        cp "$template" "$state"
        printf 'Installed helper: %s\n' "$target"
        return 0
    fi

    if [[ -e "$state" ]]; then
        if ! cmp -s "$target" "$state"; then
            printf 'Keeping locally edited helper: %s (review manually)\n' "$target"
            return 0
        fi
    elif ! cmp -s "$target" "$template"; then
        # An existing unmanaged file might contain changes the user wants.
        printf 'Keeping existing unmanaged helper: %s (review manually)\n' "$target"
        return 0
    fi

    if ! cmp -s "$target" "$template"; then
        cp "$template" "$target"
        printf 'Updated helper: %s\n' "$target"
    fi
    cp "$template" "$state"
}

sync_file sessionizer-launcher "$ROOT/templates/tmux-sessionizer-wrapper.sh" "$HOME/.local/bin/tmux-sessionizer"
sync_file project-startup "$ROOT/templates/project-startup.sh" "$HOME/.tmux-sessionizer"
sync_file clipboard "$ROOT/templates/hpc-clipboard.lua" "$HOME/.local/share/nvim/site/after/plugin/hpc-clipboard.lua"
chmod u+x "$HOME/.local/bin/tmux-sessionizer" 2>/dev/null || true
