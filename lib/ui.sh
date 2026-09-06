#!/usr/bin/env bash

# Small interactive helpers used by the setup stages.
#
# gum is used when available; otherwise a plain terminal fallback is used.
# In non-interactive contexts (X_AUTO=1 or no tty) every ask returns its
# default without prompting, so the scripts run unattended.

ui_has_gum() { command -v gum >/dev/null 2>&1; }

# ask_default PROMPT DEFAULT
# Prints the chosen value on stdout. Honors X_AUTO / no-tty.
ask_default() {
    local prompt="$1" default="$2" value
    if [[ "${X_AUTO:-0}" == 1 ]] || ! x_is_tty; then
        printf '%s\n' "$default"
        return 0
    fi
    if ui_has_gum; then
        value="$(gum input --placeholder "$default" --prompt "$prompt: ")"
        printf '%s\n' "${value:-$default}"
    else
        printf '%s [%s]: ' "$prompt" "$default" >&2
        IFS= read -r value || value=""
        printf '%s\n' "${value:-$default}"
    fi
}

# ask_choice PROMPT DEFAULT_INDEX LABEL...
# Picks one of the LABELs and prints it on stdout.
ask_choice() {
    local prompt="$1" defidx="$2"
    shift 2
    local opts=("$@") i n sel value
    n=${#opts[@]}
    if [[ "${X_AUTO:-0}" == 1 ]] || ! x_is_tty; then
        printf '%s\n' "${opts[$((defidx - 1))]}"
        return 0
    fi
    if ui_has_gum; then
        sel="$(gum choose --header "$prompt" --cursor-prefix "> " "${opts[@]}")"
        printf '%s\n' "${sel:-${opts[$((defidx - 1))]}}"
        return 0
    fi
    printf '%s\n' "$prompt" >&2
    for i in "${!opts[@]}"; do
        printf '  %d) %s\n' "$((i + 1))" "${opts[$i]}" >&2
    done
    printf 'choice [1-%d, default %d]: ' "$n" "$defidx" >&2
    IFS= read -r value || value=""
    value="${value:-$defidx}"
    case "$value" in
        *[!0-9]* | '') value="$defidx" ;;
    esac
    ((value < 1)) && value=1
    ((value > n)) && value="$n"
    printf '%s\n' "${opts[$((value - 1))]}"
}

# ask_yesno PROMPT DEFAULT(yes|no)
# Returns 0 for yes, 1 for no.
ask_yesno() {
    local prompt="$1" default="$2"
    if [[ "${X_AUTO:-0}" == 1 ]] || ! x_is_tty; then
        [[ "$default" == "yes" ]]
        return
    fi
    if ui_has_gum; then
        gum confirm --default="$([[ "$default" == yes ]] && printf true || printf false)" \
            --prompt "$prompt"
        return
    fi
    local value
    printf '%s [%s]: ' "$prompt" "$([[ "$default" == yes ]] && printf 'Y/n' || printf 'y/N')" >&2
    IFS= read -r value || value=""
    case "${value,,}" in
        y | yes) return 0 ;;
        n | no) return 1 ;;
        *) [[ "$default" == "yes" ]] ;;
    esac
}
