# Quick Start / 快速部署

This is the shortest path for new users.
这是给新用户的最短上手路径。

## 0) Prerequisites / 准备条件
- Codex Desktop installed.
- Python 3 installed.
- Internet access to PyPI on first run.

- 已安装 Codex Desktop。
- 已安装 Python 3。
- 首次运行可访问 PyPI。

## 1) Clone / 下载

```bash
git clone https://github.com/fredgena74/github-codexchajian.git
cd github-codexchajian
```

## 2) Launch / 启动

### macOS
- Double-click `launch-codex-plugin-unlock.command`
- or run:

```bash
chmod +x launch-codex-plugin-unlock.command
./launch-codex-plugin-unlock.command
```

- 双击 `launch-codex-plugin-unlock.command`
- 或命令行运行：

```bash
chmod +x launch-codex-plugin-unlock.command
./launch-codex-plugin-unlock.command
```

### Windows
- Double-click `launch-codex-plugin-unlock.bat`
- or run in cmd:

```bat
launch-codex-plugin-unlock.bat
```

- 双击 `launch-codex-plugin-unlock.bat`
- 或在 cmd 运行：

```bat
launch-codex-plugin-unlock.bat
```

## 3) Success Signals / 成功标志
Logs should contain:
- `[injector] CDP is ready; starting injections.`
- `[injector] injected into ...`

日志出现以下内容即表示注入运行中：
- `[injector] CDP is ready; starting injections.`
- `[injector] injected into ...`

## 4) UI Verify / 界面验证
- Plugin entry (`Plugins/插件/外挂程式/外掛程式`) is clickable.
- Install button is clickable when status is `App unavailable / 应用不可用 / 應用程式無法使用`.

- `Plugins/插件/外挂程式/外掛程式` 入口可点击。
- `App unavailable / 应用不可用 / 應用程式無法使用` 时安装按钮可点击。

## 5) Common Fixes / 常见修复
### `Codex app not found`
- Windows set manual path and rerun:

```bat
set CODEX_APP_PATH=C:\Path\To\Codex.exe
launch-codex-plugin-unlock.bat
```

### `python3 not found`
- Install Python 3 and retry.

### `Timed out waiting for CDP`
- Fully quit Codex and launch again.

## 6) Scope Reminder / 边界提醒
This project only does:
- plugin entry unlock
- force-enable unavailable install button

It does not guarantee plugin backend service availability.

本项目只做：
- 插件入口解锁
- 不可用状态安装按钮强制可点

不保证第三方插件后端服务可用。
