#!/bin/bash
# duckdns_update.sh — update a DuckDNS A record with the host's current public IPv4.
#
# This is the exact approach DuckDNS's own FAQ uses (the /update one-liner),
# parameterised so the SAME script works on any box. Each box sets its own
# DUCKDNS_SUBDOMAIN and DUCKDNS_TOKEN. The token is a secret: keep it in a local
# env file on the Pi, never in this repo.
#
# Cron (hourly):
#   0 * * * * /usr/local/bin/duckdns_update.sh >> /var/log/duckdns_update.log 2>&1
set -euo pipefail

STATE_FILE="${DUCKDNS_STATE_FILE:-/var/lib/duckdns/.last-ip}"
LOG_FILE="${DUCKDNS_LOG_FILE:-/var/log/duckdns_update.log}"

# Load token/subdomain from a local env file if present.
if [[ -f /etc/duckdns/duckdns.env ]]; then
  set -a
  # shellcheck disable=SC1090
  . /etc/duckdns/duckdns.env
  set +a
fi

log() { echo "[$(date '+%F %T')] $*" >> "$LOG_FILE"; }

if [[ -z "${DUCKDNS_TOKEN:-}" || -z "${DUCKDNS_SUBDOMAIN:-}" ]]; then
  log "ERROR: DUCKDNS_TOKEN and DUCKDNS_SUBDOMAIN must be set (in ${DUCKDNS_ENV_FILE:-/etc/duckdns/duckdns.env})"
  exit 1
fi

# --- detect public IPv4 -------------------------------------------------------
IP="$(curl -s --max-time 8 http://ipecho.net/plain)"
if [[ -z "$IP" || "$IP" == "0.0.0.0" ]]; then
  log "ERROR: could not detect a public IPv4 address"
  exit 1
fi

# --- skip when nothing changed (unless forced) --------------------------------
if [[ -f "$STATE_FILE" ]]; then
  PREV="$(cat "$STATE_FILE")"
  if [[ "$PREV" == "$IP" && "${DUCKDNS_FORCE:-0}" != "1" ]]; then
    log "IP unchanged ($IP) for ${DUCKDNS_SUBDOMAIN} — skipping"
    exit 0
  fi
fi

# --- push the new IP to DuckDNS ----------------------------------------------
# Endpoint = DuckDNS's documented update URL (from duckdns.org FAQ).
# params: domains=<subdomain>, token=<token>, ip=<public IPv4>
DUCKDNS_URL="https://www.duckdns.org/update?domains=${DUCKDNS_SUBDOMAIN}\&token=${DUCKDNS_TOKEN}\&ip="
RESP="$(curl -s --max-time 10 -X POST "${DUCKDNS_URL}${IP}" | grep -o '"success":[a-z]*' | head -1)"

if [[ "$RESP" == '"success":true' ]]; then
  printf '%s\n' "$IP" > "$STATE_FILE"
  log "OK: ${DUCKDNS_SUBDOMAIN} -> ${IP}   resp=${RESP}"
else
  log "FAIL: ${DUCKDNS_SUBDOMAIN} -> ${IP}   resp=${RESP}"
  exit 1
fi
