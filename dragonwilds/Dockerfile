# Thin wrapper over the official Jagex image. All server logic lives there;
# this only maps Home Assistant options onto its environment variables.
FROM ghcr.io/runescape/rsdw-dedicated:latest

USER root
COPY run.sh /ha-run.sh
RUN chmod 0755 /ha-run.sh

ENV RSDW_PORT=7777 \
    RSDW_BEACON_PORT=8888

# Deliberately no USER directive: the Supervisor writes /data/options.json as
# root with mode 0600, so run.sh must start as root to read it, then drops to
# the image's steam user before exec'ing /entry.sh.
ENTRYPOINT ["/ha-run.sh"]
