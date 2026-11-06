#!/usr/bin/env bash
# Home Assistant add-on wrapper for the official RuneScape: Dragonwilds server
# image. Reads add-on options, maps them onto the image's RSDW_* environment
# variables, prepares the persistent data directory, then hands over to the
# image's own entrypoint.
set -euo pipefail

OPTIONS=/data/options.json
SERVER_USER=steam
SERVER_UID=1000
SERVER_GID=1000
SERVER_DIR=/home/steam/rsdw-dedicated
DATA_DIR=/data/rsdw-dedicated

log() { echo "[dragonwilds] $*"; }

# Read the add-on options.
#
# /data/options.json is written by the Supervisor as root with mode 0600, so the
# script must run as root to read it. That is why the container starts as root
# (see Dockerfile) and drops privileges only after the options are parsed.
# The Supervisor API is a fallback for non-root starts; note that "supervisor"
# does not resolve when host_network is enabled, so the file is the primary path.
read_options() {
    if [[ -r "$OPTIONS" ]]; then
        cat "$OPTIONS"
        return 0
    fi
    if [[ -n "${SUPERVISOR_TOKEN:-}" ]] &&
        opts="$(curl -fsSL -m 10 -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
            http://supervisor/addons/self/options/config 2>/dev/null)"; then
        printf '%s' "$opts"
        return 0
    fi
    log "ERROR: cannot read add-on options: $OPTIONS is unreadable and the Supervisor API is unreachable"
    return 1
}

# Read one option from the options JSON. Missing/null becomes empty.
opt() {
    local json="$1" key="$2"
    printf '%s' "$json" | jq -r --arg k "$key" 'if .[$k] == null then "" else .[$k] | tostring end'
}

options="$(read_options)"

owner_id="$(opt "$options" owner_id)"
if [[ -z "$owner_id" ]]; then
    log "ERROR: owner_id is required. Set it in the add-on configuration" \
        "(your Player ID from the in-game Settings menu)."
    exit 1
fi

export RSDW_OWNER_ID="$owner_id"
export RSDW_SERVER_NAME="$(opt "$options" server_name)"
export RSDW_WORLD_NAME="$(opt "$options" world_name)"
export RSDW_ADMINS="$(opt "$options" admins)"
export RSDW_ADDITIONAL_ARGS="$(opt "$options" additional_args)"

# Empty string is meaningful for the passwords: it disables them. The image
# default is "random", which regenerates on every start.
export RSDW_PASSWORD="$(opt "$options" password)"
export RSDW_ADMIN_PASSWORD="$(opt "$options" admin_password)"

export RSDW_AUTO_STOP_ON_UPDATE="$(opt "$options" auto_stop_on_update)"
if [[ "$(opt "$options" validate_files)" == "true" ]]; then
    export STEAMAPPVALIDATE=1
fi

# Keep the world and server files in /data, which the Supervisor always mounts
# read-write and includes in backups. /config and /data are both root-owned on
# the host, so the directory is created and handed to the server user here,
# while this script still runs as root.
mkdir -p "$DATA_DIR"
chown -R "${SERVER_UID}:${SERVER_GID}" "$DATA_DIR"

# Point the image's install directory at the persistent data directory. The
# image creates /home/steam/rsdw-dedicated at build time, so replace it with a
# symlink. Do this as root: /home/steam is writable by the server user, but the
# existing directory is owned by it and must be removed first.
if [[ -e "$SERVER_DIR" && ! -L "$SERVER_DIR" ]]; then
    rm -rf "$SERVER_DIR"
fi
ln -sfn "$DATA_DIR" "$SERVER_DIR"
chown -h "${SERVER_UID}:${SERVER_GID}" "$SERVER_DIR"

log "Starting server '${RSDW_SERVER_NAME}' (world: ${RSDW_WORLD_NAME})"

# Drop to the image's server user, then hand over to its entrypoint. exec keeps
# /entry.sh as PID 1 so the Supervisor's stop signal reaches the game server.
if [[ "$(id -u)" -eq 0 ]]; then
    exec setpriv --reuid="$SERVER_UID" --regid="$SERVER_GID" --init-groups /entry.sh
fi

exec /entry.sh
