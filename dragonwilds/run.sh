#!/usr/bin/env bash
# Map Home Assistant add-on options to the official image's environment
# variables, then hand over to its entrypoint.
set -euo pipefail

OPTIONS=/data/options.json

if [[ ! -f "$OPTIONS" ]]; then
    echo "[dragonwilds] ERROR: $OPTIONS not found" >&2
    exit 1
fi

# Read one option as a JSON string. Missing/null becomes empty.
opt() {
    jq -r --arg k "$1" 'if .[$k] == null then "" else .[$k] | tostring end' "$OPTIONS"
}

owner_id="$(opt owner_id)"
if [[ -z "$owner_id" ]]; then
    echo "[dragonwilds] ERROR: owner_id is required. Set it in the add-on configuration" \
        "(your Player ID from the in-game Settings menu)." >&2
    exit 1
fi

export RSDW_OWNER_ID="$owner_id"
export RSDW_SERVER_NAME="$(opt server_name)"
export RSDW_WORLD_NAME="$(opt world_name)"
export RSDW_ADMINS="$(opt admins)"
export RSDW_ADDITIONAL_ARGS="$(opt additional_args)"

# Empty string is meaningful here: it disables the password. The image default
# is "random", which regenerates on every start.
export RSDW_PASSWORD="$(opt password)"
export RSDW_ADMIN_PASSWORD="$(opt admin_password)"

export RSDW_AUTO_STOP_ON_UPDATE="$(opt auto_stop_on_update)"
if [[ "$(opt validate_files)" == "true" ]]; then
    export STEAMAPPVALIDATE=1
fi

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
