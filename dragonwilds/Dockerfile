# Thin wrapper over the official Jagex image. All server logic lives there;
# this only maps Home Assistant options onto its environment variables.
FROM ghcr.io/runescape/rsdw-dedicated:latest

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY run.sh /ha-run.sh
RUN chmod 0755 /ha-run.sh

ENV RSDW_PORT=7777 \
    RSDW_BEACON_PORT=8888

CMD ["/ha-run.sh"]
