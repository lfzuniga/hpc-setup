# HPC setup — portable tmux, sessionizer and clipboard

This is an **orchestrator** repo, not a replacement for your existing repos.
It installs these separate upstreams for each HPC account:

- `https://github.com/lfzuniga/tmux-hpc` → `~/.config/tmux`
- `https://github.com/lfzuniga/nvim` → `~/.config/nvim`
- **Your fork:** `https://github.com/lfzuniga/tmux-sessionizer` → `~/.local/opt/tmux-sessionizer`

It also installs user-level `fzf` when missing, puts a small launcher for your
fork in `~/.local/bin`, seeds a reusable home session, and installs a global
per-project startup hook to open Neovim + a detached `scratch` **shell window**.
Per-machine search paths and remote Neovim OSC 52 live outside the shared Neovim
Git repo. **No root access.**

## On a new HPC machine

Prerequisites: `git`, `bash`, `tmux`; SSH/network access to GitHub. Neovim is
installed **separately** for the machine's OS/architecture. If `fzf` is missing,
its upstream installer also needs access to download its binary. This setup
runs on the remote host; do **not** run it on your laptop.

```bash
# After copying/cloning this repository onto the HPC machine:
cd hpc-setup
bash bootstrap.sh
```

If you want Bash convenience commands, optionally run:

```bash
bash enable-bash.sh
source ~/.bashrc
```

Outside tmux, enter a project with `t` (if you enabled the Bash snippet), or
`~/.local/bin/tmux-sessionizer`. Inside tmux use `Ctrl+B`, then `f`.

The bootstrap **preserves existing Git checkouts** and host-specific search
paths rather than pulling or overwriting them. It backs up an old executable
`~/.local/bin/tmux-sessionizer` to
`~/.local/bin/tmux-sessionizer.before-hpc-setup` once before replacing it with a
wrapper around your fork (an old symlink to the fork is upgraded in place).
It does not edit `.bashrc` unless you explicitly run
`enable-bash.sh`. Running `bootstrap.sh` again is intended to be safe.

## Updating an existing HPC machine

Edit your three repos on your laptop, **commit and push** the changes, then
on each remote machine run:

```bash
git -C ~/hpc-setup pull --ff-only
bash ~/hpc-setup/update.sh
```

The first command updates this orchestrator (including its helper templates).
The second fast-forward pulls `tmux-hpc`, `nvim`, and **your** sessionizer fork,
then updates installed helper scripts only if they have not been edited locally.
It reloads an existing tmux server, but does not start a new one or disrupt
existing project sessions. Restart Neovim to load changed configuration;
run `:Lazy sync` if you updated your plugin declarations or lockfile.

**Safety:** dirty or diverged Git checkouts stop the update rather than being
reset; each checkout updates in sequence, so a later failure can leave earlier
ones updated. Host-specific `~/.config/tmux-sessionizer/tmux-sessionizer.conf`,
`~/.bashrc`, private keys, and Neovim binaries are not changed. A helper file
that differs from the last installed snapshot is preserved and reported for
manual review. The snapshots live under `~/.local/share/hpc-setup/managed/`.

The v2 starter did not have a dedicated update command. If you already ran v2,
run the v3 `bootstrap.sh` **once** after upgrading to initialize helper
snapshots; then use `update.sh` routinely. If you customized any existing
helper, review the bootstrap output before deciding whether to adopt changes.

## Important: fix your existing tmux-hpc repository once

The currently published `tmux-hpc/tmux.conf` has a `q` reload binding pointing
at `~/.tmux.conf`, not `~/.config/tmux/tmux.conf`. Fix this once on Bouchet:

```bash
cd ~/.config/tmux
nvim tmux.conf
# Change only this line:
# bind q source-file ~/.config/tmux/tmux.conf \; display-message "Configuration reloaded"
git add tmux.conf
git commit -m "Fix tmux reload path"
git push
```

Then update the checkout on other machines with `git -C ~/.config/tmux pull`
when you're ready. The orchestrator deliberately does **not** edit the
version-controlled tmux config itself.

For tmux versions that support XDG configuration paths (including Bouchet's
3.2a), `~/.config/tmux/tmux.conf` loads at new tmux-server startup as long as
nothing in an older `~/.tmux.conf` interferes. Existing servers need an explicit
reload:

```bash
tmux source-file ~/.config/tmux/tmux.conf
```

## Default session layout: home + project + scratch

When you invoke `tmux-sessionizer` for the first time, its launcher creates
`home` (working directory `$HOME`) **if and only if** no session named `home`
exists. It then runs your fork's regular picker. Newly selected projects get
Neovim in their first tmux window and a second window named `scratch` containing
a shell in the same project directory. Once you quit Neovim, the first window
returns to its shell. Existing sessions are not reset or duplicated.

The hook is tracked as `templates/project-startup.sh` in THIS setup repository,
but installed at `~/.tmux-sessionizer` because that is the path your fork sources.
A project-specific `.tmux-sessionizer` takes priority; the installer preserves an
existing global hook rather than overwriting it. `home` starts as a plain shell
and is intentionally not opened in Neovim. `scratch` is a tmux shell window, not
a temporary Neovim file.

The wrapper seeds `home` before starting the first *new* project session when
invoked from an ordinary SSH shell using `t`. If you've already launched tmux
manually, its current session already exists; the wrapper will still create
`home` once but cannot retroactively make it the oldest session.

If your tmux binding runs `~/.local/bin/tmux-sessionizer`, it already uses the
wrapper. You need no additional tmux or Neovim keybindings.

## Project paths differ by machine

Edit only this machine's file:

```bash
nvim ~/.config/tmux-sessionizer/tmux-sessionizer.conf
```

Example: `TS_SEARCH_PATHS=("$HOME/.config:1" "$HOME/projects:1")`.
This file isn't changed on subsequent bootstrap runs and is not committed to
your shared repo. Avoid a recursive search over shared HPC filesystems.

## Clipboard (remote → laptop)

Your **laptop** stays as it is; on your existing local tmux you already verified
`set-clipboard on` and the `Ms` terminal capability. Other laptop/terminal
setups may need to allow OSC 52 separately. For any new **remote** host:

```bash
tmux show -s set-clipboard
tmux info | grep 'Ms:'
printf 'HPC_CLIP_TEST' | tmux load-buffer -w -
```

Paste on the laptop. Once that works, in *remote* Neovim use `"+yy`, then
paste on the laptop. OSC 52 clipboard **writing** is the intended workflow;
`"+p` on remote Neovim may not be supported through nested tmux. A failed
`Ms` check or clipboard test means inspect that host's tmux/terminal setup,
not your shared Neovim configuration.

Clipboard contents are controlled by applications in that remote session;
avoid using this functionality for sensitive material on shared hosts.

## Not covered yet

Installing a compatible Neovim binary and LSP/Tree-sitter/Node/Rust toolchain
on an unfamiliar HPC OS, SSH keys, VPN, and Slurm allocation policies remain
machine-specific. Keep tmux on the login node and launch heavy jobs on allocated
compute nodes according to that cluster's policies.

## Publish this orchestration repo once

Unzip the starter on your laptop, rename its folder to `hpc-setup`, and create
an **empty** GitHub repository named `lfzuniga/hpc-setup`. Then:

```bash
cd hpc-setup
git init -b master
git add .
git commit -m "Add portable HPC bootstrap"
git remote add origin git@github.com:lfzuniga/hpc-setup.git
git push -u origin master
```

On a new HPC host, after confirming GitHub HTTPS is reachable:

```bash
git clone https://github.com/lfzuniga/hpc-setup.git ~/hpc-setup
cd ~/hpc-setup
bash bootstrap.sh
```

The new GitHub repository will **not** be created by running bootstrap; this
is a one-time publication step you perform from your laptop.
