# Usage Guide / 使用说明

Quick path for new users:
- [QUICKSTART.md](QUICKSTART.md)

新用户快速路径：
- [QUICKSTART.md](QUICKSTART.md)

## Overview / 功能概览
- This project only includes 2 features:
- `Plugin entry unlock`.
- Force-enable install buttons for `App unavailable / 应用不可用 / 應用程式無法使用`.

- 本项目只包含 2 项功能：
- `插件入口解锁`。
- `App unavailable / 应用不可用 / 應用程式無法使用` 场景下安装按钮强制可点。

## Prerequisites / 前置条件
- Codex Desktop installed.
- Python 3 installed.
- Network access to PyPI for `websocket-client` installation during first run.

- 已安装 Codex Desktop。
- 已安装 Python 3。
- 首次运行时可访问 PyPI 安装 `websocket-client`。

## macOS
1. Double-click `launch-codex-plugin-unlock.command`.
2. Wait for logs:
- `[launcher] launching Codex with CDP port 9229 ...` or `[launcher] CDP 9229 already available`.
- `[injector] CDP is ready; starting injections.`
3. Keep the terminal window open while Codex is running.

1. 双击 `launch-codex-plugin-unlock.command`。
2. 等待日志出现：
- `[launcher] launching Codex with CDP port 9229 ...` 或 `[launcher] CDP 9229 already available`。
- `[injector] CDP is ready; starting injections.`
3. Codex 运行期间保持该终端窗口打开。

## Windows
1. Double-click `launch-codex-plugin-unlock.bat`.
2. Wait for logs:
- `[launcher] using Codex app: ...`
- `[injector] CDP is ready; starting injections.`
3. Keep the cmd window open while Codex is running.

1. 双击 `launch-codex-plugin-unlock.bat`。
2. 等待日志出现：
- `[launcher] using Codex app: ...`
- `[injector] CDP is ready; starting injections.`
3. Codex 运行期间保持该 cmd 窗口打开。

## Manual App Path on Windows / Windows 手动指定 Codex 路径
If auto-detection fails:

```bat
set CODEX_APP_PATH=C:\Path\To\Codex.exe
launch-codex-plugin-unlock.bat
```

若自动探测失败：

```bat
set CODEX_APP_PATH=C:\Path\To\Codex.exe
launch-codex-plugin-unlock.bat
```
