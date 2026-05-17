# github-codexchajian

跨平台（macOS + Windows）Codex 插件页面轻量解锁工具，只做两件事：
- 插件入口解锁（`Plugins/插件/外挂程式/外掛程式` 可点）
- `App unavailable / 应用不可用 / 應用程式無法使用` 场景下安装按钮强制可点

A cross-platform (macOS + Windows) lightweight unlock tool for Codex plugin UI, with exactly two features:
- Unlock plugin entry visibility/clickability
- Force-enable install button under `App unavailable / 应用不可用 / 應用程式無法使用`

## Scope And Safety Boundary / 功能与安全边界
- No `codex_session_delete` dependency.
- No listener on `57321`.
- No modification of Codex installation package internals.
- No DB read/write.
- No `HTTP_PROXY/HTTPS_PROXY/ALL_PROXY` injection into Codex process.

- 不依赖 `codex_session_delete`。
- 不监听 `57321`。
- 不修改 Codex 安装包内部文件。
- 不读写数据库。
- 不向 Codex 进程注入 `HTTP_PROXY/HTTPS_PROXY/ALL_PROXY`。

## Repository Layout / 仓库结构

```text
.
├── launch-codex-plugin-unlock.command   # macOS launcher
├── launch-codex-plugin-unlock.bat       # Windows launcher
├── inject_plugin_unlock.py              # shared Python injector
├── plugin_unlock.js                     # injected UI patch script
├── docs/
│   ├── USAGE.md
│   ├── VERIFICATION.md
│   └── TROUBLESHOOTING.md
├── LICENSE
└── README.md
```

## Prerequisites / 前置条件
- Codex Desktop installed.
- Python 3 installed.
- First run can access PyPI for installing `websocket-client`.

- 已安装 Codex Desktop。
- 已安装 Python 3。
- 首次运行可访问 PyPI 安装 `websocket-client`。

## Quick Start / 一键启动

### macOS
Double-click:

```text
launch-codex-plugin-unlock.command
```

### Windows
Double-click:

```text
launch-codex-plugin-unlock.bat
```

The launcher will:
- ensure Codex runs with `--remote-debugging-port=9229`
- create `.venv` only when needed
- install `websocket-client` automatically if missing
- run a watcher that injects script into current/new Codex pages

启动器会自动：
- 确保 Codex 带 `--remote-debugging-port=9229`
- 仅在需要时创建 `.venv`
- 缺依赖时自动安装 `websocket-client`
- 运行 watcher，持续注入当前/新打开的 Codex 页面

## Validation / 验证
See:
- [docs/VERIFICATION.md](docs/VERIFICATION.md)

## Troubleshooting / 故障排查
See:
- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

## Usage Details / 使用说明
See:
- [docs/USAGE.md](docs/USAGE.md)

## Known Limits / 已知限制
- This tool only unlocks frontend disabled states.
- It does not guarantee third-party plugin backend availability.

- 本工具只解除前端禁用态。
- 不保证第三方插件后端服务一定可用。

## Issue And Maintenance / 反馈与维护
- Open an issue with OS, Codex version, and launcher logs.
- PRs are welcome for compatibility improvements without expanding feature scope.

- 提 issue 时请附 OS、Codex 版本、启动日志。
- 欢迎提交兼容性改进 PR，但不要扩展功能边界。
