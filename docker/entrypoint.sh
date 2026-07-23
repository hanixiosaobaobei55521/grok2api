#!/bin/sh
set -eu

umask 077
mkdir -p /run/grok2api /app/data

CONFIG_DEST=/app/config.yaml
PORT_NUM="${PORT:-8080}"
LISTEN_ADDR="0.0.0.0:${PORT_NUM}"

write_config_from_file() {
  src="$1"
  cp "$src" "$CONFIG_DEST"
  if id grok2api >/dev/null 2>&1; then
    chown grok2api:grok2api "$CONFIG_DEST" 2>/dev/null || true
  fi
  chmod 0600 "$CONFIG_DEST"
}

is_set_nonempty() {
  # Safe under set -u: returns 0 only if var is set and non-empty
  eval "test -n \"\${$1+x}\"" || return 1
  eval "test -n \"\${$1}\"" || return 1
  return 0
}

# --- resolve config ---
if is_set_nonempty GROK2API_CONFIG; then
  # Full YAML injected via env/secret (recommended on PandaStack)
  # shellcheck disable=SC2154
  eval "printf '%s\n' \"\${GROK2API_CONFIG}\" > /run/grok2api/config.yaml"
  write_config_from_file /run/grok2api/config.yaml
elif [ -f /app/config.pandastack.yaml ]; then
  missing=""
  for v in JWT_SECRET CREDENTIAL_KEY ADMIN_USER ADMIN_PASSWORD DATABASE_DSN; do
    if ! is_set_nonempty "$v"; then
      missing="$missing $v"
    fi
  done
  if [ -n "$missing" ]; then
    echo "missing required env vars for config template:$missing" >&2
    echo "set GROK2API_CONFIG (full yaml) OR set JWT_SECRET CREDENTIAL_KEY ADMIN_USER ADMIN_PASSWORD DATABASE_DSN" >&2
    exit 1
  fi
  # shellcheck disable=SC2016
  envsubst '${JWT_SECRET} ${CREDENTIAL_KEY} ${ADMIN_USER} ${ADMIN_PASSWORD} ${DATABASE_DSN}' \
    < /app/config.pandastack.yaml > "$CONFIG_DEST"
  if id grok2api >/dev/null 2>&1; then
    chown grok2api:grok2api "$CONFIG_DEST" 2>/dev/null || true
  fi
  chmod 0600 "$CONFIG_DEST"
elif [ -f "${GROK2API_CONFIG_SOURCE:-/run/grok2api/config.yaml}" ]; then
  write_config_from_file "${GROK2API_CONFIG_SOURCE}"
else
  echo "missing config: set GROK2API_CONFIG env, or template envs, or mount config.yaml to /run/grok2api/config.yaml" >&2
  exit 1
fi

echo "starting grok2api listen=${LISTEN_ADDR}" >&2

if command -v su-exec >/dev/null 2>&1 && id grok2api >/dev/null 2>&1; then
  exec su-exec grok2api:grok2api /app/grok2api --config "$CONFIG_DEST" --listen "$LISTEN_ADDR"
fi

exec /app/grok2api --config "$CONFIG_DEST" --listen "$LISTEN_ADDR"
