#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_PATH="/Applications/Codex.app"
CDP_PORT="${CDP_PORT:-9229}"
SCRIPT_JS="${SCRIPT_DIR}/plugin_unlock.js"
SCRIPT_PY="${SCRIPT_DIR}/inject_plugin_unlock.py"
VENV_DIR="${SCRIPT_DIR}/.venv"

cdp_ready() {
  /usr/bin/curl --silent --show-error --fail --max-time 1 --noproxy '*' "http://127.0.0.1:${CDP_PORT}/json/list" >/dev/null 2>&1
}

codex_running() {
  /usr/bin/pgrep -x "Codex" >/dev/null 2>&1
}

choose_python() {
  if [[ -x "${VENV_DIR}/bin/python" ]]; then
    echo "${VENV_DIR}/bin/python"
    return
  fi
  if command -v python3 >/dev/null 2>&1; then
    command -v python3
    return
  fi
  if command -v python >/dev/null 2>&1; then
    command -v python
    return
  fi
  return 1
}

ensure_websocket_dependency() {
  local py_bin="$1"
  if "${py_bin}" -c 'import websocket' >/dev/null 2>&1; then
    echo "${py_bin}"
    return
  fi

  echo "[launcher] creating lightweight .venv and installing websocket-client ..."
  /usr/bin/python3 -m venv "${VENV_DIR}"
  "${VENV_DIR}/bin/python" -m pip install --quiet --upgrade pip
  "${VENV_DIR}/bin/python" -m pip install --quiet websocket-client
  echo "${VENV_DIR}/bin/python"
}

if [[ ! -d "${APP_PATH}" ]]; then
  echo "[launcher] Codex app not found: ${APP_PATH}" >&2
  exit 1
fi

if [[ ! -f "${SCRIPT_JS}" || ! -f "${SCRIPT_PY}" ]]; then
  echo "[launcher] required files missing in ${SCRIPT_DIR}" >&2
  exit 1
fi

if codex_running && ! cdp_ready; then
  echo "[launcher] Codex is running without CDP ${CDP_PORT}; quitting for restart ..."
  /usr/bin/osascript -e 'tell application "Codex" to quit' >/dev/null 2>&1 || true
  for _ in {1..80}; do
    if ! codex_running; then
      break
    fi
    sleep 0.5
  done
  if codex_running; then
    echo "[launcher] failed to quit Codex. Please close Codex manually then retry." >&2
    exit 1
  fi
fi

if ! cdp_ready; then
  echo "[launcher] launching Codex with CDP port ${CDP_PORT} ..."
  /usr/bin/open -na "${APP_PATH}" --args \
    "--remote-debugging-port=${CDP_PORT}" \
    "--remote-allow-origins=http://127.0.0.1:${CDP_PORT}"
else
  echo "[launcher] CDP ${CDP_PORT} already available; reusing current Codex process."
fi

PYTHON_BIN="$(choose_python || true)"
if [[ -z "${PYTHON_BIN}" ]]; then
  echo "[launcher] python3 not found." >&2
  exit 1
fi
PYTHON_BIN="$(ensure_websocket_dependency "${PYTHON_BIN}")"

echo "[launcher] starting injector watcher ..."
env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy \
  "${PYTHON_BIN}" "${SCRIPT_PY}" \
  --port "${CDP_PORT}" \
  --script "${SCRIPT_JS}" \
  --wait-timeout 45 \
  --poll-interval 1
