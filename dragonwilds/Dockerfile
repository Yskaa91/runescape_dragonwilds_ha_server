# Home Assistant add-on wrapper for the official RuneScape: Dragonwilds server
# image. All server logic stays in the upstream image; this only maps add-on
# options onto its environment variables and prepares persistent storage.
#
# The container must start as root: the Supervisor mounts /data and /config as
# root-owned, and the world directory has to be created and chowned before the
# game server runs as the image's unprivileged "steam" user. run.sh drops
# privileges itself before exec'ing /entry.sh.
FROM ghcr.io/runescape/rsdw-dedicated:latest

USER root

COPY run.sh /run.sh
RUN chmod 0755 /run.sh

ENV RSDW_PORT=7777 \
    RSDW_BEACON_PORT=8888

ENTRYPOINT ["/run.sh"]
