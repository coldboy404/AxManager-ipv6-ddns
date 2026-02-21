#!/system/bin/sh
RUNTIME_DIR=/sdcard/Android/media/cf_ipv6_ddns
CFG_FILE="$RUNTIME_DIR/config.env"
DDNS_SH_RUNTIME="$RUNTIME_DIR/ddns.sh"
DDNS_SH_MODULE="${0%/*}/system/bin/ddns.sh"
LOG_FILE="$RUNTIME_DIR/ddns.log"

mkdir -p "$RUNTIME_DIR"
if [ -f "$DDNS_SH_MODULE" ] && [ ! -f "$DDNS_SH_RUNTIME" ]; then
  cp "$DDNS_SH_MODULE" "$DDNS_SH_RUNTIME" 2>/dev/null || true
  chmod 700 "$DDNS_SH_RUNTIME" 2>/dev/null || true
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
