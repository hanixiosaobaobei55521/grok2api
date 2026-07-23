FROM alpine:3.21
ENV TZ=Asia/Shanghai \
    PORT=8080 \
    GROK2API_CONFIG_SOURCE=/run/grok2api/config.yaml
RUN apk add --no-cache ca-certificates su-exec tzdata wget && \
    addgroup -S -g 10001 grok2api && \
    adduser -S -D -H -u 10001 -G grok2api grok2api && \
    mkdir -p /app/data /run/grok2api /app/frontend && \
    chown -R grok2api:grok2api /app/data /run/grok2api
WORKDIR /app
COPY deploy/grok2api /app/grok2api
COPY deploy/frontend/dist /app/frontend/dist
COPY deploy/VERSION /app/VERSION
COPY docker/entrypoint.sh /usr/local/bin/grok2api-entrypoint
RUN chmod 0755 /app/grok2api /usr/local/bin/grok2api-entrypoint
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=5 \
    CMD wget -qO- http://127.0.0.1:8080/healthz >/dev/null || exit 1
ENTRYPOINT ["/usr/local/bin/grok2api-entrypoint"]
CMD ["/app/grok2api", "--config", "/app/config.yaml", "--listen", "0.0.0.0:8080"]
