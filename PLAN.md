# `github-codexchajian` 跨平台开源发布计划（macOS + Windows）

## Summary
- 在空目录 `/Users/liuyonghua/Documents/chengxu/github-codexchajian` 新建一个可公开发布的跨平台项目，复刻并统一当前“轻量版插件解锁”能力。
- 核心功能严格限定为两项：`插件入口解锁` + `App unavailable/应用不可用/應用程式無法使用` 安装按钮强制可点。
- 按已锁定决策执行发布：GitHub 公开同名仓库 `fredgena74/github-codexchajian`、`MIT` 许可证、README 中英双语、运行时要求用户已安装 Python3（脚本自动建 `.venv`）。

## Implementation Changes
- **项目结构与跨平台策略**
  - 采用“共享核心 + 平台启动器”结构：共享 `inject_plugin_unlock.py` 与 `plugin_unlock.js`，分别提供 macOS `.command` 与 Windows `.bat` 启动入口。
  - 保留现有安全边界：不依赖 `codex_session_delete`、不监听 `57321`、不修改 Codex 安装包、不读写数据库、不注入 `HTTP_PROXY/HTTPS_PROXY/ALL_PROXY` 到 Codex 进程。
  - 增加 `.gitignore`（忽略 `.venv/`、`__pycache__/`、系统临时文件），确保仓库干净可复现。
- **启动与注入接口（对外可用行为）**
  - 统一外部入口接口：
    - macOS：双击 `launch-codex-plugin-unlock.command`
    - Windows：双击 `launch-codex-plugin-unlock.bat`
  - 注入器接口保持稳定：`inject_plugin_unlock.py --port --script --wait-timeout --poll-interval`。
  - Windows 启动器实现自动探测 Codex 安装路径；若 Codex 已运行但未开 `9229`，先正常退出再带 `--remote-debugging-port=9229 --remote-allow-origins=http://127.0.0.1:9229` 重启。
- **文档与“无脑部署”交付**
  - 编写中英双语 `README.md`，包含：功能说明、先决条件（Python3 + Codex Desktop）、mac/win 一键启动步骤、验证步骤、故障排查、已知限制与安全边界。
  - 提供 `LICENSE`（MIT）与最小维护说明（版本更新方式、如何提 issue）。
  - 在文档中明确“自动安装仅解除前端禁用，不保证第三方插件服务端可用”。
- **GitHub 自动发布流程**
  - 本地初始化 Git 仓库并提交完整首版。
  - 使用已登录账户创建公开远端仓库 `fredgena74/github-codexchajian`，配置 `origin` 并自动推送默认分支。
  - 推送后校验：远端可访问、README/License/脚本文件齐全。

## Test Plan
- **自动化/命令验证**
  - 校验脚本语法：`bash -n`（mac 启动器）、`python -m py_compile`（注入器）。
  - 启动后验证 `http://127.0.0.1:9229/json/list` 可返回 page target。
  - 回归验证：无 `57321` 监听、无 `codex_session_delete` 进程依赖。
  - 仓库发布验证：`git status` 干净、`git remote -v` 正确、GitHub 远端仓库可见。
- **UI 人工验收（必须）**
  - API Key 模式下 `插件/Plugins/外挂程式/外掛程式` 入口可见可点。
  - 插件页 `App unavailable/应用不可用/應用程式無法使用` 场景中安装按钮可点击。
  - Codex 退出后 watcher 自动退出。

## Assumptions
- 账户与发布：使用当前已登录 GitHub 账号 `fredgena74`，仓库名固定为 `github-codexchajian`，公开发布。
- 运行环境：目标用户具备 Python3（不提供免 Python 打包产物），网络可访问 PyPI 安装 `websocket-client`。
- 支持范围：优先覆盖当前 Codex Desktop 常见安装形态；Windows 路径探测失败时提供明确报错与手动路径回退指引。
