#!/usr/bin/env bash
# Map Home Assistant add-on options to the official image's environment
# variables, then hand over to its entrypoint.
set -euo pipefail

OPTIONS=/data/options.json

if [[ ! -f "$OPTIONS" ]]; then
    echo "[dragonwilds] ERROR: $OPTIONS not found" >&2
    exit 1
fi

# Supervisor writes /data/options.json as root with mode 0600, and this script
# starts as root (see Dockerfile), so read it now and hand the values down as
# environment variables before dropping to the server user.
if [[ "$(id -u)" -eq 0 ]]; then
    export RSDW_OWNER_ID="$(jq -r '.owner_id // ""' "$OPTIONS")"
    export RSDW_SERVER_NAME="$(jq -r '.server_name // ""' "$OPTIONS")"
    export RSDW_WORLD_NAME="$(jq -r '.world_name // ""' "$OPTIONS")"
    export RSDW_ADMINS="$(jq -r '.admins // ""' "$OPTIONS")"
    export RSDW_ADDITIONAL_ARGS="$(jq -r '.additional_args // ""' "$OPTIONS")"
    export RSDW_PASSWORD="$(jq -r '.password // ""' "$OPTIONS")"
    export RSDW_ADMIN_PASSWORD="$(jq -r '.admin_password // ""' "$OPTIONS")"
    export RSDW_AUTO_STOP_ON_UPDATE="$(jq -r '.auto_stop_on_update // false' "$OPTIONS")"
    if [[ "$(jq -r '.validate_files // false' "$OPTIONS")" == "true" ]]; then
        export STEAMAPPVALIDATE=1
    fi
    # The server must run as the image's steam user, not root. sudo is
    # passwordless for %sudo in the base image, so no extra capability is needed.
    exec sudo -u steam --preserve-env -- "$0" "$@"
fi

owner_id="${RSDW_OWNER_ID:-}"
if [[ -z "$owner_id" ]]; then
    echo "[dragonwilds] ERROR: owner_id is required. Set it in the add-on configuration" \
        "(your Player ID from the in-game Settings menu)." >&2
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
