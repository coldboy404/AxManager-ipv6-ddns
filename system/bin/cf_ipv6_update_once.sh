#!/system/bin/sh
# Cloudflare IPv6 DDNS updater v1.2.2 (better compatibility)

MODDIR=${0%/*}
MODDIR=${MODDIR%/system/bin}
LOG_DIR="$MODDIR/output"
LOG_FILE="$LOG_DIR/cf_ipv6_ddns.log"
LAST_IP_FILE="$LOG_DIR/last_ipv6.txt"
CFG_FILE="$MODDIR/config.env"

mkdir -p "$LOG_DIR"

log() {
  echo "[$(date '+%F %T')] $*" | tee -a "$LOG_FILE"
}

get_ipv6_route() {
  ip -6 route get 2606:4700:4700::1111 2>/dev/null \
    | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}'
}

get_ipv6_global() {
  ip -6 addr show scope global 2>/dev/null \
    | awk '/inet6/{print $2}' \
    | cut -d/ -f1 \
    | grep -v '^fe80:' \
    | grep -v '^fd' \
    | grep -v '^fc' \
    | head -n1
}

if [ ! -f "$CFG_FILE" ]; then
  log "ERROR: missing config file: $CFG_FILE"
  exit 1
fi

# shellcheck disable=SC1090
. "$CFG_FILE"

if [ -z "${CF_API_TOKEN:-}" ] || [ -z "${CF_ZONE_ID:-}" ] || [ -z "${CF_RECORD_NAME:-}" ]; then
  log "ERROR: missing required config (CF_API_TOKEN / CF_ZONE_ID / CF_RECORD_NAME)"
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  log "ERROR: curl not found"
  exit 1
fi

IPV6="$(get_ipv6_route)"
[ -z "$IPV6" ] && IPV6="$(get_ipv6_global)"

if [ -z "$IPV6" ]; then
  log "ERROR: cannot detect global IPv6"
  exit 1
fi

LAST_IP=""
[ -f "$LAST_IP_FILE" ] && LAST_IP="$(cat "$LAST_IP_FILE" 2>/dev/null)"
if [ "$LAST_IP" = "$IPV6" ]; then
  log "No change. IPv6=$IPV6"
  exit 0
fi

# Resolve record id (auto)
RECORD_ID="${CF_RECORD_ID:-}"
if [ -z "$RECORD_ID" ]; then
  LIST_URL="https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records?type=AAAA&name=$CF_RECORD_NAME"
  RESP_LIST="$LOG_DIR/list_response.json"
  HTTP_LIST=$(curl -sS -o "$RESP_LIST" -w "%{http_code}" -X GET "$LIST_URL" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json")

  if [ "$HTTP_LIST" != "200" ]; then
    log "ERROR: query record failed HTTP=$HTTP_LIST"
    exit 3
  fi

  RECORD_ID=$(sed -n 's/.*"result"\s*:\s*\[\s*{\s*"id":"\([^"]*\)".*/\1/p' "$RESP_LIST" | head -n1)
  [ -z "$RECORD_ID" ] && RECORD_ID=$(grep -o '"id":"[^"]*"' "$RESP_LIST" | head -n1 | cut -d: -f2 | tr -d '"')

  if [ -z "$RECORD_ID" ]; then
    log "ERROR: AAAA record not found for $CF_RECORD_NAME (please create one first)"
    exit 3
  fi
fi

PROXIED_BOOL=false
[ "${CF_PROXIED:-0}" = "1" ] && PROXIED_BOOL=true
TTL_VAL="${CF_TTL:-120}"

JSON_PAYLOAD="{\"type\":\"AAAA\",\"name\":\"$CF_RECORD_NAME\",\"content\":\"$IPV6\",\"ttl\":$TTL_VAL,\"proxied\":$PROXIED_BOOL}"
API_URL="https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$RECORD_ID"
RESP_FILE="$LOG_DIR/last_api_response.json"
HTTP_CODE=$(curl -sS -o "$RESP_FILE" -w "%{http_code}" -X PUT "$API_URL" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data "$JSON_PAYLOAD")

if [ "$HTTP_CODE" = "200" ] && grep -q '"success":true' "$RESP_FILE"; then
  echo "$IPV6" > "$LAST_IP_FILE"
  log "UPDATE OK: $CF_RECORD_NAME -> $IPV6"
  exit 0
fi

ERR_MSG="$(grep -o '"message":"[^"]*"' "$RESP_FILE" | head -n1 | cut -d: -f2- | tr -d '"')"
log "UPDATE FAIL: HTTP=$HTTP_CODE ${ERR_MSG:+msg=$ERR_MSG}"
exit 2
