#!/usr/bin/env bash
# Update code shared across HPC accounts. Preserve per-host project paths and edits.
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
: "${HOME:?HOME must be set}"

update_checkout() {
    local name=$1 target=$2
    if [[ ! -d "$target/.git" ]]; then
        printf 'Missing %s checkout: %s\nRun bash %s/bootstrap.sh first.\n' "$name" "$target" "$ROOT" >&2
        exit 1
    fi
    if [[ -n "$(git -C "$target" status --porcelain)" ]]; then
        printf 'Uncommitted/untracked changes in %s (%s); keeping them untouched. Commit, stash or review before updating.\n' "$name" "$target" >&2
        exit 1
    fi
    printf '\nUpdating %s...\n' "$name"
    git -C "$target" pull --ff-only
}

update_checkout tmux-hpc "$HOME/.config/tmux"
update_checkout nvim "$HOME/.config/nvim"
update_checkout tmux-sessionizer "$HOME/.local/opt/tmux-sessionizer"

bash "$ROOT/sync-managed.sh"

# Reload config even when this command was run from an ordinary SSH shell,
# but only if a tmux server is already running. Never start a server here.
if tmux list-sessions >/dev/null 2>&1; then
    tmux source-file "$HOME/.config/tmux/tmux.conf"
    echo 'Reloaded the running tmux server.'
else
    echo 'No running tmux server; the config will load on next tmux start.'
fi

echo 'Updated shared HPC setup. Running Neovim instances may need a restart; sync Neovim plugins separately if its lockfile changed.'
