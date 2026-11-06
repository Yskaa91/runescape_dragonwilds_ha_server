#!/usr/bin/env bash
# Map Home Assistant add-on options to the official image's environment
# variables, then hand over to its entrypoint.
set -euo pipefail

OPTIONS=/data/options.json

if [[ ! -f "$OPTIONS" ]]; then
    echo "[dragonwilds] ERROR: $OPTIONS not found" >&2
    exit 1
fi

# The Supervisor writes options.json as root with mode 0600, and this script
# starts as root (see Dockerfile). Read every option here, then re-run this
# script as the server user with the values passed explicitly. Neither
# --preserve-env nor setpriv is used: --preserve-env keeps only a fixed
# allowlist (so RSDW_* would be dropped) and setpriv --clear-groups needs
# CAP_SETGID, which add-on containers do not have.
if [[ "$(id -u)" -eq 0 ]]; then
    exec sudo -u steam -- env \
        RSDW_OWNER_ID="$(jq -r '.owner_id // ""' "$OPTIONS")" \
        RSDW_SERVER_NAME="$(jq -r '.server_name // ""' "$OPTIONS")" \
        RSDW_WORLD_NAME="$(jq -r '.world_name // ""' "$OPTIONS")" \
        RSDW_ADMINS="$(jq -r '.admins // ""' "$OPTIONS")" \
        RSDW_ADDITIONAL_ARGS="$(jq -r '.additional_args // ""' "$OPTIONS")" \
        RSDW_PASSWORD="$(jq -r '.password // ""' "$OPTIONS")" \
        RSDW_ADMIN_PASSWORD="$(jq -r '.admin_password // ""' "$OPTIONS")" \
        RSDW_AUTO_STOP_ON_UPDATE="$(jq -r '.auto_stop_on_update // false' "$OPTIONS")" \
        STEAMAPPVALIDATE="$(jq -r 'if (.validate_files // false) then 1 else 0 end' "$OPTIONS")" \
        RSDW_PORT="${RSDW_PORT:-7777}" \
        RSDW_BEACON_PORT="${RSDW_BEACON_PORT:-8888}" \
        "$0" "$@"
fi

# Fallback for containers started as a non-root user: read the options directly
# if the file is readable.
if [[ -z "${RSDW_OWNER_ID:-}" && -r "$OPTIONS" ]]; then
    RSDW_OWNER_ID="$(jq -r '.owner_id // ""' "$OPTIONS")"
    RSDW_SERVER_NAME="$(jq -r '.server_name // ""' "$OPTIONS")"
    RSDW_WORLD_NAME="$(jq -r '.world_name // ""' "$OPTIONS")"
    RSDW_ADMINS="$(jq -r '.admins // ""' "$OPTIONS")"
    RSDW_ADDITIONAL_ARGS="$(jq -r '.additional_args // ""' "$OPTIONS")"
    RSDW_PASSWORD="$(jq -r '.password // ""' "$OPTIONS")"
    RSDW_ADMIN_PASSWORD="$(jq -r '.admin_password // ""' "$OPTIONS")"
    RSDW_AUTO_STOP_ON_UPDATE="$(jq -r '.auto_stop_on_update // false' "$OPTIONS")"
    if [[ "$(jq -r '.validate_files // false' "$OPTIONS")" == "true" ]]; then
        STEAMAPPVALIDATE=1
    fi
    export RSDW_OWNER_ID RSDW_SERVER_NAME RSDW_WORLD_NAME RSDW_ADMINS \
        RSDW_ADDITIONAL_ARGS RSDW_PASSWORD RSDW_ADMIN_PASSWORD \
        RSDW_AUTO_STOP_ON_UPDATE STEAMAPPVALIDATE
fi

owner_id="${RSDW_OWNER_ID:-}"
if [[ -z "$owner_id" ]]; then
    echo "[dragonwilds] ERROR: owner_id is required. Set it in the add-on configuration" \
        "(your Player ID from the in-game Settings menu)." >&2
    echo "[dragonwilds] DEBUG: running as uid=$(id -u), options file readable=$([[ -r "$OPTIONS" ]] && echo yes || echo no)" >&2
    exit 1
fi

# Empty string is meaningful for the passwords: it disables them. The image
# default is "random", which regenerates on every start.

# Persist the world across add-on restarts/updates.
SERVER_DIR=/home/steam/rsdw-dedicated
mkdir -p /config/rsdw-dedicated
if [[ -d "$SERVER_DIR" && ! -L "$SERVER_DIR" && -z "$(ls -A "$SERVER_DIR" 2>/dev/null)" ]]; then
    rmdir "$SERVER_DIR"
fi
if [[ ! -e "$SERVER_DIR" ]]; then
    ln -s /config/rsdw-dedicated "$SERVER_DIR"
fi

echo "[dragonwilds] Starting server '${RSDW_SERVER_NAME}' (world: ${RSDW_WORLD_NAME})"
exec /entry.sh
