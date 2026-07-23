# PandaStack-friendly image: pull official prebuilt binary+frontend.
# Free tier (0.5GB) cannot reliably build the multi-stage Node+Go Dockerfile.
FROM ghcr.io/chenyme/grok2api:latest

USER root

# gettext provides envsubst for config template substitution
RUN apk add --no-cache gettext

COPY --chmod=0755 docker/entrypoint.sh /usr/local/bin/grok2api-entrypoint
COPY docker/config.pandastack.yaml /app/config.pandastack.yaml

# Default internal port; override with PORT env (PandaStack requires this)
ENV PORT=8000 \
    TZ=Asia/Shanghai \
    GROK2API_CONFIG_SOURCE=/run/grok2api/config.yaml

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=5 \
    CMD wget -qO- "http://127.0.0.1:${PORT:-8000}/healthz" >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/grok2api-entrypoint"]
# listen address is rewritten by entrypoint from $PORT
CMD ["/app/grok2api", "--config", "/app/config.yaml", "--listen", "0.0.0.0:8000"]
