#!/system/bin/sh
rm -rf /sdcard/Android/media/axbeacon >/dev/null 2>&1 || true
# Also clean legacy runtime data from versions before the AxBeacon rename.
rm -rf /sdcard/Android/media/cf_ipv6_ddns >/dev/null 2>&1 || true
