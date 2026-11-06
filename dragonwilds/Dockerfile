# Thin wrapper over the official Jagex image. All server logic lives there;
# this only maps Home Assistant options onto its environment variables.
FROM ghcr.io/runescape/rsdw-dedicated:latest

USER root
COPY run.sh /ha-run.sh
RUN chmod 0755 /ha-run.sh
USER 1000:1000

ENV RSDW_PORT=7777 \
    RSDW_BEACON_PORT=8888

ENTRYPOINT ["/ha-run.sh"]
