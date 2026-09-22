#!/usr/bin/env bash
# Optional: add the sessionizer convenience command to this HPC account's Bash.
set -euo pipefail
bashrc="$HOME/.bashrc"
marker='# BEGIN hpc-setup (sessionizer)'
if [[ -f "$bashrc" ]] && grep -Fq "$marker" "$bashrc"; then
    echo 'HPC Bash snippet is already present.'
    exit 0
fi
if [[ -f "$bashrc" ]]; then
    cp -p "$bashrc" "$bashrc.before-hpc-setup"
fi
cat >> "$bashrc" <<'SNIPPET'

# BEGIN hpc-setup (sessionizer)
export PATH="$HOME/.local/bin:$PATH"
# Convenient when SSHing in before starting tmux:
alias t='tmux-sessionizer'
# END hpc-setup (sessionizer)
SNIPPET
printf 'Updated %s (existing file backed up as %s.before-hpc-setup).\n' "$bashrc" "$bashrc"
echo 'Run: source ~/.bashrc'
