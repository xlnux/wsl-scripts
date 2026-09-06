#!/usr/bin/env bash

# Common helpers for the xlnux/wsl-scripts setup. Sourced by the entry points.

export X_DRY="${X_DRY:-0}"
export X_AUTO="${X_AUTO:-0}"
export X_INSTALL="${X_INSTALL:-1}"

x_color() {
    [[ "${NO_COLOR:-}" != 1 ]] || return 1
    [[ -t 1 ]] || return 1
    return 0
}

x_msg() {
    local tag="$1" code="$2"
    shift 2
    if x_color; then
        printf '\033[%sm[%s]\033[0m %s\n' "$code" "$tag" "$*"
    else
        printf '[%s] %s\n' "$tag" "$*"
    fi
}

log_ok()   { x_msg ok   32 "$*"; }
log_info() { x_msg i    34 "$*"; }
log_warn() { x_msg warn 33 "$*"; }
log_err()  { x_msg error 31 "$*" >&2; }

x_have() { command -v "$1" >/dev/null 2>&1; }

x_is_dry() { [[ "${X_DRY:-0}" == 1 ]]; }
x_is_auto() { [[ "${X_AUTO:-0}" == 1 ]]; }

x_is_tty() { [[ -t 0 && -t 1 ]]; }

x_is_wsl() {
    [[ -f /proc/sys/fs/binfmt_misc/WSLInterop ]] && return 0
    grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null && return 0
    return 1
}

x_step() {
    local desc="$1"
    shift
    log_info "$desc"
    if x_is_dry; then
        return 0
    fi
    if [[ $# -gt 0 ]]; then
        "$@"
    fi
}

# Print a plan line when in dry-run mode.
x_plan() {
    x_is_dry && log_info "plan: $*"
    return 0
}

# Append one unique line to a file (creating it if missing).
x_line_once() {
    local file="$1" line="$2"
    x_is_dry && return 0
    mkdir -p "$(dirname -- "$file")"
    if [[ -f "$file" ]] && grep -qxF -- "$line" "$file"; then
        return 0
    fi
    printf '%s\n' "$line" >>"$file"
}

# Rewrite a file with the content produced by a function, unless dry-run.
x_write_stdin() {
    local file="$1"
    x_is_dry && return 0
    mkdir -p "$(dirname -- "$file")"
    cat >"$file"
}

# Source helpers for privilege handling.
#
# System stage: must run as root. A non-root caller is re-executed through
# sudo (unless in dry-run mode, where a plan is printed without privileges).
x_require_root() {
    if [[ $EUID -eq 0 ]]; then
        return 0
    fi
    if x_is_dry; then
        log_info "not root; dry-run continues without privileges"
        return 0
    fi
    if x_have sudo; then
        log_info "elevating to root with sudo"
        exec sudo env X_DRY="${X_DRY:-0}" X_AUTO="${X_AUTO:-0}" X_INSTALL="${X_INSTALL:-1}" \
            bash "$0" "$@"
    fi
    log_err "this stage must run as root (a fresh WSL import boots as root)"
    exit 1
}

# User stage: must run as a regular user. When invoked as root through sudo,
# drop back to the invoking user before applying anything.
x_require_user() {
    if [[ $EUID -ne 0 ]]; then
        return 0
    fi
    if x_is_dry; then
        log_info "root user; dry-run continues and prints the plan for \$SUDO_USER"
        return 0
    fi
    local u="${SUDO_USER:-}"
    if [[ -n "$u" && "$u" != "root" ]]; then
        local home
        home="$(getent passwd "$u" | cut -d: -f6)"
        [[ -n "$home" ]] || home="/home/$u"
        if x_have runuser; then
            log_info "dropping to $u"
            exec runuser -u "$u" -- env HOME="$home" X_DRY="${X_DRY:-0}" X_AUTO="${X_AUTO:-0}" \
                bash "$0" "$@"
        elif x_have su; then
            log_info "dropping to $u"
            exec su - "$u" -c "X_DRY=${X_DRY:-0} X_AUTO=${X_AUTO:-0} HOME='$home' bash '$0' $*"
        fi
    fi
    log_err "this stage must run as a regular user (not root)"
    exit 1
}
