#!/bin/sh
set -eu

umask 077
mkdir -p /run/grok2api

# 优先从 GROK2API_CONFIG 环境变量写入配置（适用于 PandaStack 等无法挂载文件的平台）
if [ -n "${GROK2API_CONFIG:-}" ]; then
  printf '%s' "$GROK2API_CONFIG" > /run/grok2api/config.yaml
  GROK2API_CONFIG_SOURCE=/run/grok2api/config.yaml
fi

if [ ! -f "${GROK2API_CONFIG_SOURCE}" ]; then
  echo "missing config: set GROK2API_CONFIG env or mount config.yaml to /run/grok2api/config.yaml" >&2
  exit 1
fi

cp "${GROK2API_CONFIG_SOURCE}" /app/config.yaml
chown grok2api:grok2api /app/config.yaml
chmod 0600 /app/config.yaml

exec su-exec grok2api:grok2api "$@"
