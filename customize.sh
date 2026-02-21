#!/system/bin/sh
MODDIR=${0%/*}
RUNTIME=/sdcard/Android/media/cf_ipv6_ddns

mkdir -p "$RUNTIME" 2>/dev/null || true

if [ -f "$MODDIR/system/bin/ddns.sh" ]; then
  cp "$MODDIR/system/bin/ddns.sh" "$RUNTIME/ddns.sh" 2>/dev/null || true
  chmod 700 "$RUNTIME/ddns.sh" 2>/dev/null || true
fi

if [ ! -f "$RUNTIME/config.env" ] && [ -f "$MODDIR/config.env.example" ]; then
  cp "$MODDIR/config.env.example" "$RUNTIME/config.env" 2>/dev/null || true
  chmod 600 "$RUNTIME/config.env" 2>/dev/null || true
fi
