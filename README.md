# HPC setup — portable tmux, sessionizer and clipboard

This is an **orchestrator** repo, not a replacement for your existing repos.
It installs these separate upstreams for each HPC account:

- `https://github.com/lfzuniga/tmux-hpc` → `~/.config/tmux`
- `https://github.com/lfzuniga/nvim` → `~/.config/nvim`
- `https://github.com/lfzuniga/tmux-sessionizer` → `~/.local/opt/tmux-sessionizer`

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


