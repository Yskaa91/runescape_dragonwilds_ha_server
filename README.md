# RuneScape Dragonwilds Home Assistant Server

Home Assistant add-on repository that runs a dedicated
[RuneScape: Dragonwilds](https://store.steampowered.com/app/1374490/) server,
built on Jagex's official image
[`ghcr.io/runescape/rsdw-dedicated`](https://github.com/runescape/rsdw-dedicated).

## Installation

1. In Home Assistant, go to **Settings → Add-ons → Add-on Store**.
2. Open the ⋮ menu (top right) and choose **Repositories**.
3. Add `https://github.com/Yskaa91/runescape_dragonwilds_ha_server`.
4. Reload the store, then install **RuneScape Dragonwilds Server** from the
   new repository section.

## Requirements

- Home Assistant OS / Supervised on **x86-64 (amd64)**. Other architectures are
  not supported yet.
- About **4 GB RAM** (2 GB base + 1 GB per player, up to 6 players) and
  **20 GB free disk** for the server files.
- UDP ports **7777** (game) and **8888** (beacon) reachable from the internet.
  The add-on uses host networking, so the ports are bound directly on the host.
  Forward both ports on your router if players join from outside your LAN.

## Configuration

| Option | Required | Description |
| --- | --- | --- |
| `owner_id` | yes | Your Dragonwilds Player ID, shown at the bottom of the in-game Settings menu. The server will not start without it. |
| `server_name` | yes | Name of the server in the Worlds list. |
| `world_name` | yes | Name of the world created on first start. |
| `password` | no | Join password. Leave empty for an open server. |
| `admin_password` | no | Password for the in-game Server Management tab. Leave empty to have the image generate one (check the add-on log). |
| `admins` | no | Comma separated list of Player IDs that are always admins. |
| `additional_args` | no | Extra command line arguments passed to `RSDragonwildsServer.sh`. |
| `auto_stop_on_update` | no | Stop the server when a newer Steam build is detected. The add-on restarts on the next boot or manual start. |
| `validate_files` | no | Validate and re-download the server files with SteamCMD on start. Use after a broken update. |

The server files and world saves are stored in the add-on's config folder
(`/config/rsdw-dedicated` inside the container, `app_configs/*_dragonwilds`
on the host) and are included in Home Assistant backups.

## Updating the server

The server files update through SteamCMD every time the add-on starts. To pull
a new game build, restart the add-on.

To update the add-on itself, bump `version` in `dragonwilds/config.yaml` and
push; the GitHub Actions workflow publishes the image and Home Assistant offers
the update.

## Development

```sh
docker build -t dragonwilds-addon dragonwilds
```

The workflow in `.github/workflows/build.yaml` builds and pushes
`ghcr.io/yskaa91/dragonwilds:<version>` and `:latest` on every push to `main`.
The package must be public in the GitHub Container Registry for Home Assistant
to pull it.
