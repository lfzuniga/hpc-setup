#!/usr/bin/env bash
# Install user-level HPC tmux + sessionizer + Neovim clipboard setup.
# Run from an extracted copy of this repository ON the target HPC host.
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
: "${HOME:?HOME must be set}"

for command_name in git tmux bash; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Missing prerequisite: %s (ask your HPC admin or load a module).\n' "$command_name" >&2
        exit 1
    }
done

mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/opt"
export PATH="$HOME/.local/bin:$PATH"

# Clone on new machines; never pull over an existing installation.
clone_if_missing() {
    local url=$1 target=$2
    if [[ -d "$target/.git" ]]; then
        printf 'Keeping existing Git checkout: %s\n' "$target"
    elif [[ -e "$target" || -L "$target" ]]; then
        printf 'Refusing to replace existing non-Git path: %s\n' "$target" >&2
        exit 1
    else
        git clone "$url" "$target"
    fi
}

# These three repositories remain independent, so you can update them separately.
clone_if_missing https://github.com/lfzuniga/tmux-hpc.git "$HOME/.config/tmux"
clone_if_missing https://github.com/lfzuniga/nvim.git "$HOME/.config/nvim"
clone_if_missing https://github.com/lfzuniga/tmux-sessionizer.git "$HOME/.local/opt/tmux-sessionizer"

fork_script="$HOME/.local/opt/tmux-sessionizer/tmux-sessionizer"
[[ -f "$fork_script" ]] || { echo "Fork does not contain $fork_script" >&2; exit 1; }
chmod u+x "$fork_script"

# The launcher is a small wrapper around YOUR fork. It creates a detached
# "home" session before the first project session, without editing the fork.
launcher="$HOME/.local/bin/tmux-sessionizer"
wrapper_template="$ROOT/templates/tmux-sessionizer-wrapper.sh"
if [[ -L "$launcher" || -e "$launcher" ]]; then
    if [[ -f "$launcher" ]] && cmp -s "$wrapper_template" "$launcher"; then
        printf 'Sessionizer launcher already installed: %s\n' "$launcher"
    elif [[ -f "$HOME/.local/share/hpc-setup/managed/sessionizer-launcher" ]]; then
        # Managed helpers are updated by sync-managed.sh after bootstrap.
        printf 'Keeping existing managed launcher for synchronization: %s\n' "$launcher"
    elif [[ -L "$launcher" && "$(readlink "$launcher")" == "$fork_script" ]]; then
        # Upgrade from v1, which linked ~/.local/bin directly to the fork.
        # The fork remains intact; an earlier backup, if any, is left alone.
        rm "$launcher"
        cp "$wrapper_template" "$launcher"
        chmod u+x "$launcher"
        printf 'Upgraded fork symlink to the home-session launcher: %s\n' "$launcher"
    else
        backup="${launcher}.before-hpc-setup"
        if [[ -e "$backup" || -L "$backup" ]]; then
            printf 'Keeping existing launcher: %s (backup already exists; review manually)\n' "$launcher"
        else
            mv "$launcher" "$backup"
            cp "$wrapper_template" "$launcher"
            chmod u+x "$launcher"
            printf 'Saved previous sessionizer launcher as %s\n' "$backup"
        fi
    fi
else
    cp "$wrapper_template" "$launcher"
    chmod u+x "$launcher"
fi

# Global startup hook for newly created project sessions. The fork sources
# ~/.tmux-sessionizer; it does NOT source a hook inside ~/.config by default.
project_hook="$HOME/.tmux-sessionizer"
if [[ ! -e "$project_hook" && ! -L "$project_hook" ]]; then
    cp "$ROOT/templates/project-startup.sh" "$project_hook"
    printf 'Created global project-session startup hook: %s\n' "$project_hook"
else
    printf 'Keeping existing project-session startup hook: %s\n' "$project_hook"
fi

# Use the system fzf if present; otherwise install it without root or shell-keybind changes.
if ! command -v fzf >/dev/null 2>&1; then
    fzf_dir="$HOME/.local/opt/fzf"
    clone_if_missing https://github.com/junegunn/fzf.git "$fzf_dir"
    "$fzf_dir/install" --bin
    [[ -x "$fzf_dir/bin/fzf" ]] || { echo 'fzf installation did not create a binary.' >&2; exit 1; }
    if [[ ! -e "$HOME/.local/bin/fzf" && ! -L "$HOME/.local/bin/fzf" ]]; then
        ln -s "$fzf_dir/bin/fzf" "$HOME/.local/bin/fzf"
    fi
fi
command -v fzf >/dev/null 2>&1 || { echo 'fzf is still missing from PATH.' >&2; exit 1; }

# Do not overwrite search paths already tailored to this host.
sessionizer_config="$HOME/.config/tmux-sessionizer/tmux-sessionizer.conf"
mkdir -p "$(dirname "$sessionizer_config")"
if [[ ! -e "$sessionizer_config" ]]; then
    cp "$ROOT/templates/tmux-sessionizer.conf" "$sessionizer_config"
    printf 'Created %s; edit its project paths for this HPC host.\n' "$sessionizer_config"
else
    printf 'Keeping host-specific search paths: %s\n' "$sessionizer_config"
fi

# Keep clipboard provider outside the Git-managed Neovim configuration.
clipboard_file="$HOME/.local/share/nvim/site/after/plugin/hpc-clipboard.lua"
mkdir -p "$(dirname "$clipboard_file")"
if [[ ! -e "$clipboard_file" ]]; then
    cp "$ROOT/templates/hpc-clipboard.lua" "$clipboard_file"
else
    printf 'Keeping existing clipboard config: %s\n' "$clipboard_file"
fi

# Record the installed helper versions, enabling safe subsequent updates.
bash "$ROOT/sync-managed.sh"

# A tmux server that is already running will not automatically reread its configuration.
if [[ -n "${TMUX:-}" ]]; then
    echo 'Inside tmux: reload when ready with: tmux source-file ~/.config/tmux/tmux.conf'
else
    echo 'Start a new tmux server to load ~/.config/tmux/tmux.conf.'
fi

if grep -Fq 'source-file ~/.tmux.conf' "$HOME/.config/tmux/tmux.conf"; then
    echo 'ACTION NEEDED: tmux-hpc still has a reload binding pointing at ~/.tmux.conf.'
    echo 'Change that line to ~/.config/tmux/tmux.conf in your tmux-hpc repo, commit and push.'
fi

if ! command -v nvim >/dev/null 2>&1; then
    echo 'ACTION NEEDED: Neovim binary not found. Install Neovim separately for this HPC OS.'
fi

printf '\nInstalled your tmux config, sessionizer fork + home launcher, project startup hook, fzf, and remote clipboard.\n'
echo 'Before the first use: ensure your laptop tmux and terminal permit OSC 52; see README.md.'
