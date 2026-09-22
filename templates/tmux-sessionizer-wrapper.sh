#!/usr/bin/env bash
# Portable entry point for your sessionizer fork.
# Seed a detached home session before the first project-picker session.
set -euo pipefail

fork="$HOME/.local/opt/tmux-sessionizer/tmux-sessionizer"
if [[ ! -x "$fork" ]]; then
    printf 'Missing sessionizer fork: %s\n' "$fork" >&2
    exit 1
fi

# Do not start sessions just to display help, version or run session commands.
if [[ $# -eq 0 || ( $# -eq 1 && "$1" != -* ) ]]; then
    if ! tmux has-session -t '=home' 2>/dev/null; then
        tmux new-session -ds home -c "$HOME"
    fi
fi

exec "$fork" "$@"
