# Uso

Configuracion de X Linux para WSL solo desde terminal. Dos fases, ejecutadas
desde este repositorio tras importar el rootfs de
[xlnux/wsl](https://github.com/xlnux/wsl).

## Fase 1 - Sistema (root)

Una importacion nueva de WSL arranca como root. Ejecuta el asistente ahi:

```bash
./setup.sh
```

`setup.sh` detecta el contexto (root sin `SUDO_USER`) y ejecuta la fase de
sistema. Pregunta por:

- locale a activar y usar como `LANG` (por defecto `en_US.UTF-8`);
- mapa de teclado de consola (por defecto `us`);
- zona horaria (por defecto `windows-time`, que deja que WSL refleje el reloj
  de Windows; puedes elegir `UTC` o cualquier zona IANA como `Europe/Madrid`);
- usuario a crear o asegurar (por defecto el de `SUDO_USER`, si no `x`);
- shell de login para el usuario (`zsh` por defecto, o `bash`);
- politica de sudo: `nopasswd` (recomendada en WSL) o `password`.

Puedes saltarte las preguntas pasando los valores directamente. Cualquier
opcion de sistema se reenvia a la fase de sistema:

```bash
sudo ./stage-root.sh --locale es_ES.UTF-8 --keymap es \
    --timezone Europe/Madrid --user dev --shell zsh --sudo nopasswd
```

Tambien se puede hacer sin argumentos mediante variables de entorno:

```bash
export X_LOCALE=de_DE.UTF-8 X_KEYMAP=de X_TIMEZONE=Europe/Berlin \
       X_USER=dev X_SUDO=nopasswd
sudo ./stage-root.sh
```

Para saltar la instalacion de herramientas base (`sudo git curl wget`, mas
`zsh` cuando es el shell de login), usa `--no-install` o `X_INSTALL=0`.

La fase solo aplica las acciones pedidas; con `X_DRY=1` no se aplica nada y
con `X_AUTO=1` se usan los valores por defecto sin preguntar. Si el rootfs no
inicia sesion con el usuario nuevo automaticamente, cierra la distro
(`wsl --terminate <distro>`) y abrela con `wsl -d <distro> -u <usuario>`.

## Fase 2 - Usuario

Entra con el usuario creado y ejecuta la fase de usuario:

```bash
./setup.sh
```

Ejecutarla con sudo tambien funciona y apunta a `SUDO_USER`:

```bash
sudo ./setup.sh
```

La fase de usuario exporta el entorno desde `~/.profile` y `~/.bashrc`
(`~/.zprofile` y `~/.zshrc` si el shell de login es zsh), crea
`~/.local/bin`, `~/.config/x` y `~/Projects`, y muestra los siguientes pasos.

## Referencia de opciones (fase de sistema)

| Opcion         | Env            | Por defecto    | Valores                           |
|----------------|----------------|----------------|-----------------------------------|
| `--locale`     | `X_LOCALE`     | `en_US.UTF-8`  | cualquier locale, p.ej. `es_ES.UTF-8` |
| `--keymap`     | `X_KEYMAP`     | `us`           | mapa de consola                   |
| `--timezone`   | `X_TIMEZONE`   | `windows-time` | `windows-time`, `UTC`, zona IANA  |
| `--user`       | `X_USER`       | `SUDO_USER`/`x`| nombre de usuario                 |
| `--shell`      | `X_SHELL`      | `zsh`          | `zsh`, `bash` o una ruta          |
| `--sudo`       | `X_SUDO`       | interactivo    | `nopasswd`, `password`            |
| `--no-install` | `X_INSTALL=0`  | instalar       | -                                 |

## Banderas de automatizacion

- `X_AUTO=1` - usa los valores por defecto sin preguntar (requiere no tty).
- `X_DRY=1`  - imprime el plan sin aplicar nada.

Ver [configuration.md](configuration.md) para ver exactamente que cambia cada
fase.
