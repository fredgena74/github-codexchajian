#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

import websocket


PROXY_ENV_KEYS = (
    "HTTP_PROXY",
    "HTTPS_PROXY",
    "ALL_PROXY",
    "http_proxy",
    "https_proxy",
    "all_proxy",
)


def local_json_get(url: str, timeout: float = 2.0) -> Any:
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    request = urllib.request.Request(url, headers={"Accept": "application/json"})
    try:
        with opener.open(request, timeout=timeout) as response:
            payload = response.read().decode("utf-8", errors="replace")
    except urllib.error.URLError as exc:
        raise RuntimeError(f"request failed: {exc}") from exc
    try:
        return json.loads(payload)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"invalid json from {url}") from exc


def clear_proxy_for_self() -> None:
    for key in PROXY_ENV_KEYS:
        os.environ.pop(key, None)
    os.environ.setdefault("NO_PROXY", "127.0.0.1,localhost")
    os.environ.setdefault("no_proxy", "127.0.0.1,localhost")


def list_targets(port: int) -> list[dict[str, Any]]:
    for endpoint in (f"http://127.0.0.1:{port}/json/list", f"http://127.0.0.1:{port}/json"):
        payload = local_json_get(endpoint, timeout=2.0)
        if isinstance(payload, list):
            return payload
    raise RuntimeError("CDP targets endpoint returned unexpected payload")


def codex_page_targets(targets: list[dict[str, Any]]) -> list[dict[str, Any]]:
    pages = [item for item in targets if item.get("type") == "page" and item.get("webSocketDebuggerUrl")]
    codex_pages: list[dict[str, Any]] = []
    for target in pages:
        title = str(target.get("title", ""))
        url = str(target.get("url", ""))
        haystack = f"{title} {url}".lower()
        if "codex" in haystack or url.startswith("app://"):
            codex_pages.append(target)
    return codex_pages or pages


def wait_for_cdp(port: int, timeout_seconds: float, poll_seconds: float = 0.5) -> None:
    deadline = time.monotonic() + timeout_seconds
    last_error = ""
    while time.monotonic() < deadline:
        try:
            list_targets(port)
            return
        except Exception as exc:  # noqa: BLE001
            last_error = str(exc)
            time.sleep(poll_seconds)
    raise TimeoutError(f"Timed out waiting for CDP on 127.0.0.1:{port}: {last_error}")


def is_codex_running() -> bool:
    if sys.platform == "win32":
        result = subprocess.run(
            ["tasklist", "/FI", "IMAGENAME eq Codex.exe", "/NH"],
            capture_output=True,
            text=True,
            check=False,
        )
        output = (result.stdout or "").strip().lower()
        return "codex.exe" in output

    result = subprocess.run(["pgrep", "-x", "Codex"], capture_output=True, text=True, check=False)
    return result.returncode == 0


def cdp_call(ws: websocket.WebSocket, method: str, params: dict[str, Any], message_id: int) -> dict[str, Any]:
    payload = {"id": message_id, "method": method, "params": params}
    ws.send(json.dumps(payload))
    while True:
        message = json.loads(ws.recv())
        if message.get("id") != message_id:
            continue
        if "error" in message:
            raise RuntimeError(f"CDP {method} failed: {message['error']}")
        return message


def connect_cdp_socket(websocket_url: str) -> websocket.WebSocket:
    return websocket.create_connection(
        websocket_url,
        timeout=5,
        http_proxy_host=None,
        http_proxy_port=None,
    )


def inject_into_target(target: dict[str, Any], script: str) -> str:
    websocket_url = str(target["webSocketDebuggerUrl"])
    ws = connect_cdp_socket(websocket_url)
    try:
        cdp_call(ws, "Page.enable", {}, 1)
        cdp_call(ws, "Runtime.enable", {}, 2)
        cdp_call(ws, "Page.addScriptToEvaluateOnNewDocument", {"source": script}, 3)
        cdp_call(
            ws,
            "Runtime.evaluate",
            {"expression": script, "awaitPromise": False, "allowUnsafeEvalBlockedByCSP": True},
            4,
        )
    finally:
        ws.close()
    return str(target.get("id") or websocket_url)


def inject_once_into_available_pages(port: int, script: str, injected: set[str]) -> int:
    targets = codex_page_targets(list_targets(port))
    count = 0
    for target in targets:
        key = str(target.get("id") or target.get("webSocketDebuggerUrl") or "")
        if not key or key in injected:
            continue
        inject_into_target(target, script)
        injected.add(key)
        count += 1
    return count


def watch_targets_until_codex_exit(port: int, script: str, poll_seconds: float) -> None:
    injected: set[str] = set()
    missing_cdp_checks = 0

    while True:
        try:
            new_count = inject_once_into_available_pages(port, script, injected)
            if new_count > 0:
                print(f"[injector] injected into {new_count} target(s), total={len(injected)}", flush=True)
            missing_cdp_checks = 0
        except Exception as exc:  # noqa: BLE001
            missing_cdp_checks += 1
            print(f"[injector] CDP poll failed: {exc}", flush=True)
            if not is_codex_running() and missing_cdp_checks >= 2:
                print("[injector] Codex not running; watcher exiting.", flush=True)
                return

        if not is_codex_running():
            try:
                codex_pages = codex_page_targets(list_targets(port))
            except Exception:  # noqa: BLE001
                codex_pages = []
            if not codex_pages:
                print("[injector] Codex process exited and no CDP targets left; watcher exiting.", flush=True)
                return

        time.sleep(poll_seconds)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Lightweight Codex plugin unlock injector")
    parser.add_argument("--port", type=int, default=9229, help="CDP port (default: 9229)")
    parser.add_argument("--script", type=Path, default=Path(__file__).with_name("plugin_unlock.js"), help="Injected JS file")
    parser.add_argument("--wait-timeout", type=float, default=45.0, help="Seconds to wait for CDP startup")
    parser.add_argument("--poll-interval", type=float, default=1.0, help="Watcher poll interval seconds")
    return parser.parse_args()


def main() -> int:
    clear_proxy_for_self()
    args = parse_args()

    script_path = args.script.resolve()
    if not script_path.exists():
        print(f"[injector] script not found: {script_path}", file=sys.stderr)
        return 1

    script = script_path.read_text(encoding="utf-8")
    if not script.strip():
        print(f"[injector] script is empty: {script_path}", file=sys.stderr)
        return 1

    print(f"[injector] waiting for CDP on 127.0.0.1:{args.port} ...", flush=True)
    wait_for_cdp(args.port, args.wait_timeout)
    print("[injector] CDP is ready; starting injections.", flush=True)

    watch_targets_until_codex_exit(args.port, script, args.poll_interval)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("\n[injector] interrupted by user; exiting.", flush=True)
        raise SystemExit(0)
