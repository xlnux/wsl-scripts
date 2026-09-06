# What it configures

This repository handles the user-facing part of X Linux on WSL. The
system-level WSL wiring is owned by the `xlnux/wsl` rootfs and is left alone:
`/etc/wsl.conf` (systemd, networking, default user), kernel/module handling
and Windows interop enablement are outside the scope of these scripts.

## System stage (`stage-root.sh`, root)

| Area       | File / action                                             |
|------------|-----------------------------------------------------------|
| Locale     | enable the locale in `/etc/locale.gen`, run `locale-gen`, write `LANG` to `/etc/locale.conf` |
| Keyboard   | write `KEYMAP` to `/etc/vconsole.conf`                    |
| Timezone   | link `/usr/share/zoneinfo/<zone>` to `/etc/localtime` and, when systemd is running, call `timedatectl set-timezone`. With `windows-time` nothing is written (WSL mirrors the Windows clock) |
| Tools      | `pacman -S sudo git curl wget` (+ `zsh` when it is the login shell); skipped offline or with `--no-install` |
| User       | create or ensure the user, add it to `wheel`, set its login shell |
| Sudo       | `/etc/sudoers.d/x-wsl-wheel` with `%wheel ALL=(ALL:ALL) NOPASSWD: ALL` (`nopasswd`) or `%wheel ALL=(ALL:ALL) ALL` (`password`); with `password` the user password is set interactively |
| Note file  | `/etc/profile.d/x-wsl.sh` records the system summary          |

The default sudo policy on WSL is `nopasswd`: the distro is a personal,
single-user box and this keeps the flow automatic. Choose `password` when the
user needs a credential boundary (a password is then requested and set).

If `/etc/wsl.conf` does not pin the default user, the stage prints a hint; it
does not edit the file because it belongs to the `xlnux/wsl` rootfs.

## User stage (`stage-user.sh`, regular user)

| Area        | Result                                                       |
|-------------|--------------------------------------------------------------|
| Editor      | `EDITOR`/`VISUAL`: `X_EDITOR` if set, else the first of `vim`, `nano`, `vi` found on the system |
| XDG dirs    | `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME` under `$HOME` |
| PATH        | `$HOME/.local/bin` and `$HOME/bin` prepended without removing existing entries |
| Prompt      | friendly `PROMPT` (zsh) or `PS1` (bash)                      |
| Aliases     | `l`, `ll`, `la`, colored `grep`, `..`, `...`                 |
| Folders     | `~/.local/bin`, `~/.config/x`, `~/Projects` created          |

The whole environment block is written between two markers
(`# >>> xlnux/wsl-scripts: user environment` and its end marker) into
`~/.profile` and `~/.bashrc` (with a zsh login shell the same block goes to
`~/.zprofile` and `~/.zshrc`). Re-running the stage replaces only that block,
so your own edits elsewhere in the rc files survive.

## Windows interop

WSL interop entries already present in `PATH` (for example `/mnt/c/...`)
are never removed: PATH hygiene only prepends the user bins. The `WSL_INTEROP`
and related variables are not touched.

## Files that change

- `/etc/locale.gen`, `/etc/locale.conf`, `/etc/vconsole.conf`, `/etc/localtime`
- `/etc/sudoers.d/x-wsl-wheel`
- `/etc/profile.d/x-wsl.sh`
- `~/.profile`, `~/.bashrc` (or `~/.zprofile`, `~/.zshrc` with zsh)
- `~/.local/bin`, `~/.config/x`, `~/Projects`
