# xlnux/wsl-scripts

Friendly, mostly automatic user setup for **X Linux on WSL** (terminal only,
no GUI). This repository holds the setup wizard; the importable rootfs lives
in the companion repository [xlnux/wsl](https://github.com/xlnux/wsl).

## Role

After the WSL rootfs from `xlnux/wsl` is imported, the distro still needs a
regular user, sane locale/keyboard/timezone values and a comfortable terminal
environment. `wsl-scripts` provides those in a clear two-stage flow, with
plain-text prompts (gum is used automatically when installed).

The WSL system-level wiring (`wsl.conf`, systemd, network) is the job of the
`xlnux/wsl` rootfs and is **not** touched here. This repo configures:

- System (root): base tools, locale, keyboard, timezone, user with sudo.
- User: environment variables, PATH hygiene (WSL interop preserved), prompt,
  aliases and development folders.

## Two-stage flow

```
wsl --import x ...            import the rootfs from xlnux/wsl
wsl -d x                     -> login as root (import default)
./setup.sh                   STAGE 1 (system): locale, keymap, timezone,
                             user with sudo, base tools
exit (or wsl --terminate x)
wsl -d x -u <user>           login as the created user
./setup.sh                   STAGE 2 (user): env vars, prompt, ~/Projects
```

`setup.sh` decides the stage from the context it runs in:

| Context                        | Stage              |
|--------------------------------|--------------------|
| root, no `SUDO_USER` (import)  | system (`stage-root.sh`) |
| `sudo ./setup.sh`              | user for `$SUDO_USER` |
| regular user                   | user (`stage-user.sh`) |

Passing system options (`--locale`, `--keymap`, `--timezone`, `--user`,
`--shell`, `--sudo`, `--no-install`) always selects the system stage, so the
same invocation can be fully non-interactive:

```bash
sudo ./stage-root.sh \
    --locale es_ES.UTF-8 \
    --keymap es \
    --timezone Europe/Madrid \
    --user dev
```

See [docs/en](docs/en/) and [docs/es](docs/es/) for usage and configuration
details.

## Layout

```
setup.sh            wizard (stage dispatch)
stage-root.sh       system stage (root)
stage-user.sh       user stage
lib/common.sh       shared helpers (X_DRY, X_AUTO, log, privilege checks)
lib/ui.sh           prompts: gum with plain fallback
test/smoke.sh       local tests (no root required)
docs/en|es/         usage and configuration guides
legacy/             previous WSL bootstrap kept for review (not part of
                    the active flow; it stays untouched until the maintainer
                    removes its originals from xlnux/scripts)
```

## Automation

The scripts are safe to run unattended:

- `X_AUTO=1` uses the defaults without prompting (locale `en_US.UTF-8`,
  keymap `us`, timezone `windows-time`, user `SUDO_USER` else `x`,
  shell `zsh`, sudo `nopasswd`).
- `X_DRY=1` prints the plan without changing anything.
- System options can also be set through `X_LOCALE`, `X_KEYMAP`,
  `X_TIMEZONE`, `X_USER`, `X_SHELL`, `X_SUDO` and `X_INSTALL`.

## Tests

```bash
./test/smoke.sh
```

Runs a syntax check over every shell script and exercises both stages in
dry-run mode with a temporary `HOME`. It requires no root and no network.
