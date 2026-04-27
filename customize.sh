#!/system/bin/sh
MODDIR=${0%/*}
RUNTIME=/sdcard/Android/media/axbeacon
OLD_RUNTIME=/sdcard/Android/media/cf_ipv6_ddns

mkdir -p "$RUNTIME" 2>/dev/null || true

# Migrate old runtime data once, keeping user config/logs when upgrading from
# the previous cf_ipv6_ddns package name.
if [ -d "$OLD_RUNTIME" ]; then
  for f in config.env last_ipv6.txt ddns.log last_api_response.json list_response.json record_ids.txt; do
    if [ -f "$OLD_RUNTIME/$f" ] && [ ! -f "$RUNTIME/$f" ]; then
      cp "$OLD_RUNTIME/$f" "$RUNTIME/$f" 2>/dev/null || true
    fi
  done
fi

if [ -f "$MODDIR/system/bin/ddns.sh" ]; then
  cp "$MODDIR/system/bin/ddns.sh" "$RUNTIME/ddns.sh" 2>/dev/null || true
  chmod 700 "$RUNTIME/ddns.sh" 2>/dev/null || true
fi

if [ ! -f "$RUNTIME/config.env" ] && [ -f "$MODDIR/config.env.example" ]; then
  cp "$MODDIR/config.env.example" "$RUNTIME/config.env" 2>/dev/null || true
  chmod 600 "$RUNTIME/config.env" 2>/dev/null || true
fi
