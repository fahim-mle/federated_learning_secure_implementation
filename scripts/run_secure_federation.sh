#!/usr/bin/env bash
set -euo pipefail

# Runs the TLS + SuperNode-authenticated federation end to end.
# Requirements:
#   - Run from anywhere; script locates repo root automatically.
#   - flower-secure-fl/.venv exists with Flower installed.
#   - Certificates under flower-secure-fl/certificates/.
#   - SSH-format SuperNode keypairs already generated:
#       keys/supernode1_auth (private) + keys/supernode1_auth.pub (registered)
#       keys/supernode2_auth (private) + keys/supernode2_auth.pub (registered)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${ROOT_DIR}/flower-secure-fl"
VENV_BIN="${APP_DIR}/.venv/bin"
LOG_DIR="${ROOT_DIR}/logs"
mkdir -p "${LOG_DIR}"

check_file() {
  if [[ ! -f "$1" ]]; then
    echo "Required file missing: $1" >&2
    exit 1
  fi
}

check_file "${APP_DIR}/certificates/ca/ca.crt"
check_file "${APP_DIR}/certificates/superlink/superlink.crt"
check_file "${APP_DIR}/certificates/superlink/superlink.key"
check_file "${APP_DIR}/keys/supernode1_auth"
check_file "${APP_DIR}/keys/supernode2_auth"
check_file "${APP_DIR}/keys/supernode1_auth.pub"
check_file "${APP_DIR}/keys/supernode2_auth.pub"

cleanup() {
  for pid in "${SN1_PID:-}" "${SN2_PID:-}" "${SUPERLINK_PID:-}"; do
    if [[ -n "${pid}" ]]; then
      kill "${pid}" >/dev/null 2>&1 || true
    fi
  done
}
trap cleanup EXIT

cd "${APP_DIR}"
PATH="${VENV_BIN}:${PATH}"

echo "[1/4] Starting SuperLink (TLS + auth)…"
"${VENV_BIN}/flower-superlink" \
  --ssl-ca-certfile ./certificates/ca/ca.crt \
  --ssl-certfile ./certificates/superlink/superlink.crt \
  --ssl-keyfile ./certificates/superlink/superlink.key \
  --enable-supernode-auth \
  > "${LOG_DIR}/superlink.log" 2>&1 &
SUPERLINK_PID=$!
sleep 3

register_node() {
  local pub_key="$1"
  local label="$2"
  local log_file="${LOG_DIR}/${label}_register.log"
  echo "[2/4] Registering ${label}..."
  if "${VENV_BIN}/flwr" supernode register "${pub_key}" . remote-federation >"${log_file}" 2>&1; then
    echo "  ${label} registered."
  else
    if grep -qi "already" "${log_file}"; then
      echo "  ${label} already registered (continuing)."
    else
      echo "Failed to register ${label}. See ${log_file} for details." >&2
      cat "${log_file}" >&2
      exit 1
    fi
  fi
}

register_node "./keys/supernode1_auth.pub" "SuperNode #1"
register_node "./keys/supernode2_auth.pub" "SuperNode #2"

echo "[3/4] Starting authenticated SuperNodes…"
"${VENV_BIN}/flower-supernode" \
  --root-certificates ./certificates/ca/ca.crt \
  --superlink 127.0.0.1:9092 \
  --clientappio-api-address 0.0.0.0:9095 \
  --node-config "partition-id=0 num-partitions=2" \
  --auth-supernode-private-key ./keys/supernode1_auth \
  > "${LOG_DIR}/supernode1.log" 2>&1 &
SN1_PID=$!

"${VENV_BIN}/flower-supernode" \
  --root-certificates ./certificates/ca/ca.crt \
  --superlink 127.0.0.1:9092 \
  --clientappio-api-address 0.0.0.0:9096 \
  --node-config "partition-id=1 num-partitions=2" \
  --auth-supernode-private-key ./keys/supernode2_auth \
  > "${LOG_DIR}/supernode2.log" 2>&1 &
SN2_PID=$!

sleep 3

echo "[4/4] Running remote federation (streaming logs)…"
"${VENV_BIN}/flwr" run . remote-federation --stream

echo "Federation complete. Logs available in ${LOG_DIR}/."
