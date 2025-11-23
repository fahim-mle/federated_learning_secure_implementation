#!/usr/bin/env bash
set -euo pipefail

# Stops SuperLink, SuperNodes, and related Flower processes.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${ROOT_DIR}/flower-secure-fl"
VENV_BIN="${APP_DIR}/.venv/bin"

kill_if_running() {
  local pattern="$1"
  if pgrep -f "${pattern}" >/dev/null; then
    echo "Stopping processes matching '${pattern}'..."
    pkill -f "${pattern}" || true
  fi
}

echo "[1/3] Stopping SuperNodes and server-side helpers…"
kill_if_running "flower-supernode"
kill_if_running "flower-superexec"

echo "[2/3] Stopping SuperLink / flwr run processes…"
kill_if_running "flower-superlink"
kill_if_running "flwr run"
kill_if_running "flwr-serverapp"
kill_if_running "flwr-clientapp"

echo "[3/3] Verifying ports 9091-9096 are free…"
if command -v lsof >/dev/null; then
  if lsof -nP -iTCP:9091-9096 -sTCP:LISTEN >/dev/null; then
    echo "Ports still in use, forcing release with fuser..."
    for port in 9091 9092 9093 9095 9096; do
      fuser -vk "${port}"/tcp >/dev/null 2>&1 || true
    done
  fi
fi

echo "Remaining Flower processes:"
pgrep -fl 'flower-super|flwr' || echo "  none"

echo "Done. You can now restart the federation safely."
