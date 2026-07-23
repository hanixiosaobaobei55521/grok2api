ARG NODE_VERSION=22
ARG GO_VERSION=1.26
ARG ALPINE_VERSION=3.23

FROM node:${NODE_VERSION}-alpine AS frontend-builder
WORKDIR /src/frontend
RUN corepack enable
COPY frontend/package.json frontend/pnpm-lock.yaml ./
RUN --mount=type=cache,id=grok2api-pnpm,target=/pnpm/store \
    pnpm config set store-dir /pnpm/store && \
    pnpm fetch --frozen-lockfile && \
    pnpm install --offline --frozen-lockfile
COPY frontend/index.html frontend/vite.config.ts frontend/tsconfig.json frontend/tsconfig.app.json frontend/tsconfig.node.json ./
COPY frontend/public ./public
COPY frontend/src ./src
RUN --mount=type=cache,id=grok2api-tsc,target=/src/frontend/.cache,sharing=locked \
    pnpm build

FROM golang:${GO_VERSION}-alpine AS backend-builder
WORKDIR /src/backend
RUN apk add --no-cache ca-certificates git
COPY backend/go.mod backend/go.sum ./
RUN --mount=type=cache,id=grok2api-go-mod,target=/go/pkg/mod,sharing=locked \
    go mod download
COPY backend/cmd ./cmd
COPY backend/internal ./internal
COPY backend/docs/docs.go ./docs/docs.go
RUN --mount=type=cache,id=grok2api-go-mod,target=/go/pkg/mod,sharing=locked \
    --mount=type=cache,id=grok2api-go-build,target=/root/.cache/go-build,sharing=locked \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -buildvcs=false -trimpath -ldflags="-s -w" -o /out/grok2api ./cmd/grok2api

FROM alpine:${ALPINE_VERSION}
ENV TZ=Asia/Shanghai \
    PORT=8080 \
    GROK2API_CONFIG_SOURCE=/run/grok2api/config.yaml
RUN apk add --no-cache ca-certificates su-exec tzdata wget && \
    addgroup -S -g 10001 grok2api && \
    adduser -S -D -H -u 10001 -G grok2api grok2api && \
    mkdir -p /app/data /run/grok2api && \
    chown -R grok2api:grok2api /app/data /run/grok2api
WORKDIR /app
COPY --from=backend-builder --chmod=0755 /out/grok2api /app/grok2api
COPY --from=frontend-builder /src/frontend/dist /app/frontend/dist
COPY VERSION /app/VERSION
COPY --chmod=0755 docker/entrypoint.sh /usr/local/bin/grok2api-entrypoint
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=5 \
    CMD wget -qO- http://127.0.0.1:8080/healthz >/dev/null || exit 1
ENTRYPOINT ["/usr/local/bin/grok2api-entrypoint"]
CMD ["/app/grok2api", "--config", "/app/config.yaml", "--listen", "0.0.0.0:8080"]
