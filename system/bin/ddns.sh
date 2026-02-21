#!/system/bin/sh
# Cloudflare IPv6 DDNS for AxManager (network-switch robust)

RUNTIME_DIR=/sdcard/Android/media/cf_ipv6_ddns
CFG_FILE="$RUNTIME_DIR/config.env"
LOG_FILE="$RUNTIME_DIR/ddns.log"
LAST_IP_FILE="$RUNTIME_DIR/last_ipv6.txt"
LAST_RESP_FILE="$RUNTIME_DIR/last_api_response.json"

mkdir -p "$RUNTIME_DIR"
chmod 700 "$RUNTIME_DIR" 2>/dev/null || true

log(){ echo "[$(date '+%F %T')] $*" >> "$LOG_FILE"; }

load_cfg(){
  if [ -f "$CFG_FILE" ]; then
    # shellcheck disable=SC1090
    . "$CFG_FILE"
    return 0
  fi
  return 1
}

require_bin(){ command -v "$1" >/dev/null 2>&1; }

is_ipv6(){
  echo "$1" | grep -Eq '^[0-9A-Fa-f:]+$' && echo "$1" | grep -q ':'
}

ipv6_public(){
  # Real public egress IPv6
  curl -6 -sS --max-time 6 https://api64.ipify.org 2>/dev/null | tr -d '\r\n '
}

ipv6_route(){
  ip -6 route get 2606:4700:4700::1111 2>/dev/null \
    | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}'
}

ipv6_fallback(){
  ip -6 addr show scope global 2>/dev/null \
    | awk '/inet6/{print $2}' \
    | cut -d/ -f1 \
    | grep -v '^fe80:' \
    | head -n1
}

ipv6_pick(){
  local ip

  ip="$(ipv6_public)"
  if [ -n "$ip" ] && is_ipv6 "$ip"; then
    echo "$ip"
    return 0
  fi

  ip="$(ipv6_route)"
  if [ -n "$ip" ] && is_ipv6 "$ip"; then
    echo "$ip"
    return 0
  fi

  ip="$(ipv6_fallback)"
  if [ -n "$ip" ] && is_ipv6 "$ip"; then
    echo "$ip"
    return 0
  fi

  return 1
}

main(){
  if ! require_bin curl; then log "ERROR: curl not found"; echo "ERROR: curl not found"; exit 1; fi
  if ! load_cfg; then log "ERROR: missing $CFG_FILE"; echo "ERROR: missing config"; exit 1; fi

  if [ -z "${CF_API_TOKEN:-}" ] || [ -z "${CF_ZONE_ID:-}" ] || [ -z "${CF_RECORD_NAME:-}" ]; then
    log "ERROR: config fields missing"
    echo "ERROR: config fields missing"
    exit 1
  fi

  IPV6="$(ipv6_pick)"
  if [ -z "$IPV6" ]; then
    log "ERROR: cannot detect global IPv6"
    echo "ERROR: cannot detect global IPv6"
    exit 1
  fi

  LAST=""
  [ -f "$LAST_IP_FILE" ] && LAST="$(cat "$LAST_IP_FILE" 2>/dev/null)"
  if [ "$LAST" = "$IPV6" ]; then
    log "No change: $IPV6"
    echo "No change: $IPV6"
    exit 0
  fi

  log "Using IPv6: $IPV6"

  LIST_URL="https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records?type=AAAA&name=$CF_RECORD_NAME"
  LIST_RESP="$RUNTIME_DIR/list_response.json"
  LIST_CODE=$(curl -sS -o "$LIST_RESP" -w "%{http_code}" "$LIST_URL" -H "Authorization: Bearer $CF_API_TOKEN" -H "Content-Type: application/json")
  if [ "$LIST_CODE" != "200" ]; then
    log "ERROR: list record HTTP=$LIST_CODE"
    echo "ERROR: list record HTTP=$LIST_CODE"
    exit 2
  fi

  RECORD_ID=$(grep -o '"id":"[^"]*"' "$LIST_RESP" | head -n1 | cut -d: -f2 | tr -d '"')

  PROXIED=false
  [ "${CF_PROXIED:-0}" = "1" ] && PROXIED=true
  TTL="${CF_TTL:-120}"

  PAYLOAD="{\"type\":\"AAAA\",\"name\":\"$CF_RECORD_NAME\",\"content\":\"$IPV6\",\"ttl\":$TTL,\"proxied\":$PROXIED}"

  if [ -z "$RECORD_ID" ]; then
    CREATE_URL="https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records"
    CODE=$(curl -sS -o "$LAST_RESP_FILE" -w "%{http_code}" -X POST "$CREATE_URL" -H "Authorization: Bearer $CF_API_TOKEN" -H "Content-Type: application/json" --data "$PAYLOAD")
    if [ "$CODE" = "200" ] && grep -q '"success":true' "$LAST_RESP_FILE"; then
      echo "$IPV6" > "$LAST_IP_FILE"
      log "CREATE OK: $CF_RECORD_NAME -> $IPV6"
      echo "CREATE OK: $CF_RECORD_NAME -> $IPV6"
      exit 0
    fi
    ERR=$(grep -o '"message":"[^"]*"' "$LAST_RESP_FILE" | head -n1 | cut -d: -f2- | tr -d '"')
    log "CREATE FAIL HTTP=$CODE ${ERR:+msg=$ERR}"
    echo "CREATE FAIL HTTP=$CODE ${ERR:+msg=$ERR}"
    exit 2
  fi

  PUT_URL="https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$RECORD_ID"
  CODE=$(curl -sS -o "$LAST_RESP_FILE" -w "%{http_code}" -X PUT "$PUT_URL" -H "Authorization: Bearer $CF_API_TOKEN" -H "Content-Type: application/json" --data "$PAYLOAD")

  if [ "$CODE" = "200" ] && grep -q '"success":true' "$LAST_RESP_FILE"; then
    echo "$IPV6" > "$LAST_IP_FILE"
    log "UPDATE OK: $CF_RECORD_NAME -> $IPV6"
    echo "UPDATE OK: $CF_RECORD_NAME -> $IPV6"
    exit 0
  fi

  ERR=$(grep -o '"message":"[^"]*"' "$LAST_RESP_FILE" | head -n1 | cut -d: -f2- | tr -d '"')
  log "UPDATE FAIL HTTP=$CODE ${ERR:+msg=$ERR}"
  echo "UPDATE FAIL HTTP=$CODE ${ERR:+msg=$ERR}"
  exit 3
}

main "$@"
