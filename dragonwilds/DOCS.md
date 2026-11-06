# RuneScape Dragonwilds Server

Runs a dedicated RuneScape: Dragonwilds server using Jagex's official
container image.

## Options

| Option | Required | Description |
| --- | --- | --- |
| `owner_id` | yes | Your Dragonwilds Player ID (in-game Settings menu, bottom). The server will not start without it. |
| `server_name` | yes | Name of the server in the Worlds list. |
| `world_name` | yes | Name of the world created on first start. |
| `password` | no | Join password. Leave empty for an open server. |
| `admin_password` | no | Password for the in-game Server Management tab. Leave empty to auto-generate one (printed in the log). |
| `admins` | no | Comma separated list of Player IDs that are always admins. |
| `additional_args` | no | Extra arguments for `RSDragonwildsServer.sh`. |
| `auto_stop_on_update` | no | Stop the server when a newer Steam build is available. |
| `validate_files` | no | Validate and re-download server files on start. |

## Data

World saves and server files live in `/config/rsdw-dedicated`, which is the
add-on config folder on the host and is included in backups.

## Networking

The add-on uses host networking. UDP 7777 (game) and UDP 8888 (beacon) must be
reachable; forward them on your router for internet play. Players on the same
LAN should use Direct connect to the host's IP.

## Logs

The add-on log shows SteamCMD output, the server console and any auto-generated
passwords.
