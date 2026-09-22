#!/usr/bin/env bash
# Sourced by your sessionizer fork ONLY when it creates a new project session.
# The fork prefers a project's own .tmux-sessionizer file over this global hook.

# A persistent shell window for commands/jobs; the original window stays active.
tmux new-window -d -n scratch -c "$PWD"

# Open the project in the original window; return to its shell when Neovim exits.
if command -v nvim >/dev/null 2>&1; then
    nvim .
else
    printf 'Neovim not found; leaving this project window at a shell.\n' >&2
fi

