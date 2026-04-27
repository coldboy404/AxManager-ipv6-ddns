#!/system/bin/sh
RUNTIME_DIR=/sdcard/Android/media/axbeacon
OLD_RUNTIME_DIR=/sdcard/Android/media/cf_ipv6_ddns
CFG_FILE="$RUNTIME_DIR/config.env"
DDNS_SH_RUNTIME="$RUNTIME_DIR/ddns.sh"
DDNS_SH_MODULE="${0%/*}/system/bin/ddns.sh"
LOG_FILE="$RUNTIME_DIR/ddns.log"

mkdir -p "$RUNTIME_DIR"

# Preserve existing user config/logs when upgrading from the old cf_ipv6_ddns name.
if [ -d "$OLD_RUNTIME_DIR" ]; then
  for f in config.env last_ipv6.txt ddns.log last_api_response.json list_response.json record_ids.txt; do
    if [ -f "$OLD_RUNTIME_DIR/$f" ] && [ ! -f "$RUNTIME_DIR/$f" ]; then
      cp "$OLD_RUNTIME_DIR/$f" "$RUNTIME_DIR/$f" 2>/dev/null || true
    fi
  done
fi
if [ -f "$DDNS_SH_MODULE" ]; then
  MODULE_SUM="$(cksum "$DDNS_SH_MODULE" 2>/dev/null | awk '{print $1":"$2}')"
  RUNTIME_SUM=""
  [ -f "$DDNS_SH_RUNTIME" ] && RUNTIME_SUM="$(cksum "$DDNS_SH_RUNTIME" 2>/dev/null | awk '{print $1":"$2}')"
  if [ ! -f "$DDNS_SH_RUNTIME" ] || [ "$MODULE_SUM" != "$RUNTIME_SUM" ]; then
    cp "$DDNS_SH_MODULE" "$DDNS_SH_RUNTIME" 2>/dev/null || true
    chmod 700 "$DDNS_SH_RUNTIME" 2>/dev/null || true
  fi
fi
[ -f "$CFG_FILE" ] || cat "${0%/*}/config.env.example" > "$CFG_FILE"

echo "[$(date '+%F %T')] service start" >> "$LOG_FILE"

INTERVAL=300
if [ -f "$CFG_FILE" ]; then
  # shellcheck disable=SC1090
  . "$CFG_FILE"
  [ -n "${CHECK_INTERVAL:-}" ] && INTERVAL="$CHECK_INTERVAL"
fi
case "$INTERVAL" in ''|*[!0-9]*) INTERVAL=300 ;; esac
[ "$INTERVAL" -lt 60 ] && INTERVAL=60

while true; do
  if [ -f "$DDNS_SH_RUNTIME" ]; then
    sh "$DDNS_SH_RUNTIME" >> "$LOG_FILE" 2>&1
  else
    sh "$DDNS_SH_MODULE" >> "$LOG_FILE" 2>&1
  fi
  sleep "$INTERVAL"
done
