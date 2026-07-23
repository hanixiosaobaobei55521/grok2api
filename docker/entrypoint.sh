#!/bin/sh
set -eu

umask 077
mkdir -p /run/grok2api

CONFIG_DEST=/app/config.yaml

# PandaStack mode: config template with ${VAR} placeholders
if [ -f /app/config.pandastack.yaml ] && [ -z "${GROK2API_CONFIG:-}" ]; then
  # Use envsubst to replace ${VAR} placeholders with environment variable values
  envsubst < /app/config.pandastack.yaml > "$CONFIG_DEST"
  chown grok2api:grok2api "$CONFIG_DEST"
  chmod 0600 "$CONFIG_DEST"
elif [ -n "${GROK2API_CONFIG:-}" ]; then
  # GROK2API_CONFIG env var contains full YAML content
  printf '%s' "$GROK2API_CONFIG" > /run/grok2api/config.yaml
  GROK2API_CONFIG_SOURCE=/run/grok2api/config.yaml
  cp "${GROK2API_CONFIG_SOURCE}" "$CONFIG_DEST"
  chown grok2api:grok2api "$CONFIG_DEST"
  chmod 0600 "$CONFIG_DEST"
else
  # Original mode: mount config.yaml to /run/grok2api/config.yaml
  if [ ! -f "${GROK2API_CONFIG_SOURCE}" ]; then
    echo "missing config: set GROK2API_CONFIG env or mount config.yaml to /run/grok2api/config.yaml" >&2
    exit 1
  fi
  cp "${GROK2API_CONFIG_SOURCE}" "$CONFIG_DEST"
  chown grok2api:grok2api "$CONFIG_DEST"
  chmod 0600 "$CONFIG_DEST"
fi

exec su-exec grok2api:grok2api "$@"
