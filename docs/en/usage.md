# Usage

Terminal-only setup for X Linux on WSL. Two stages, run from this repository
after importing the rootfs from [xlnux/wsl](https://github.com/xlnux/wsl).

## Stage 1 - System (root)

A fresh WSL import boots as root. Run the wizard there:

```bash
./setup.sh
```

`setup.sh` detects the context (root without `SUDO_USER`) and runs the system
stage. It asks for:

- locale to enable and set as `LANG` (default `en_US.UTF-8`);
- keyboard keymap for the console (default `us`);
- timezone (default `windows-time`, which lets WSL mirror the Windows clock;
  you can pick `UTC` or any IANA zone such as `Europe/Madrid`);
- user to create or ensure (default from `SUDO_USER`, otherwise `x`);
- login shell for the user (`zsh` by default, or `bash`);
- sudo policy: `nopasswd` (recommended on WSL) or `password`.

You can skip the prompts by passing the values directly. Any system option
forwards to the system stage:

```bash
sudo ./stage-root.sh --locale es_ES.UTF-8 --keymap es \
    --timezone Europe/Madrid --user dev --shell zsh --sudo nopasswd
```

The same can be done without arguments through environment variables:

```bash
export X_LOCALE=de_DE.UTF-8 X_KEYMAP=de X_TIMEZONE=Europe/Berlin \
       X_USER=dev X_SUDO=nopasswd
sudo ./stage-root.sh
```

To skip the base-tool install (`sudo git curl wget`, plus `zsh` when it is the
login shell), use `--no-install` or `X_INSTALL=0`.

The stage runs the requested actions only; nothing is applied with `X_DRY=1`,
and with `X_AUTO=1` the defaults are used without any prompt. When the rootfs
does not log in as the new user automatically, close the distro
(`wsl --terminate <distro>`) and open it with `wsl -d <distro> -u <user>`.

## Stage 2 - User

Log in as the created user and run the user stage:

```bash
./setup.sh
```

Running it through sudo also works and targets `SUDO_USER`:

```bash
sudo ./setup.sh
```

The user stage exports the environment from `~/.profile` and `~/.bashrc`
(`~/.zprofile` and `~/.zshrc` when the login shell is zsh), creates
`~/.local/bin`, `~/.config/x` and `~/Projects`, and prints the next steps.

## Options reference (system stage)

| Option            | Env            | Default        | Values                          |
|-------------------|----------------|----------------|---------------------------------|
| `--locale`        | `X_LOCALE`     | `en_US.UTF-8`  | any locale, e.g. `es_ES.UTF-8`  |
| `--keymap`        | `X_KEYMAP`     | `us`           | console keymap                  |
| `--timezone`      | `X_TIMEZONE`   | `windows-time` | `windows-time`, `UTC`, IANA zone|
| `--user`          | `X_USER`       | `SUDO_USER`/`x`| user name                       |
| `--shell`         | `X_SHELL`      | `zsh`          | `zsh`, `bash` or a path         |
| `--sudo`          | `X_SUDO`       | interactive    | `nopasswd`, `password`          |
| `--no-install`    | `X_INSTALL=0`  | install        | -                               |

## Automation flags

- `X_AUTO=1` - use defaults without prompting (requires no tty).
- `X_DRY=1`  - print the plan, apply nothing.

See [configuration.md](configuration.md) for exactly what each stage changes.
