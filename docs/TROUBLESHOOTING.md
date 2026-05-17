# Troubleshooting / 故障排查

## `Codex app not found`
- Windows: set `CODEX_APP_PATH` manually and retry.
- macOS: verify `/Applications/Codex.app` exists.

- Windows：手动设置 `CODEX_APP_PATH` 后重试。
- macOS：确认 `/Applications/Codex.app` 存在。

## `python3 not found`
- Install Python 3 first.
- On Windows, install from [python.org](https://www.python.org/downloads/windows/) and ensure launcher `py` is available.

- 先安装 Python 3。
- Windows 建议从 [python.org](https://www.python.org/downloads/windows/) 安装，并保证 `py` 可用。

## `Timed out waiting for CDP`
- Close Codex completely and rerun launcher.
- Ensure no local security software blocks `127.0.0.1:9229`.

- 完全退出 Codex 后重试。
- 确认本机安全软件未拦截 `127.0.0.1:9229`。

## `websocket-client` install failed
- Check internet connectivity to PyPI.
- Retry later or set an internal PyPI mirror for pip.

- 检查网络是否可访问 PyPI。
- 稍后重试，或为 pip 配置企业内网镜像。

## Button still disabled in UI
- Keep the launcher window open.
- Reopen plugin page to trigger DOM refresh.
- Confirm launcher logs include injector success lines.

- 保持启动器窗口不要关闭。
- 重新进入插件页触发 DOM 刷新。
- 确认日志出现注入成功信息。
