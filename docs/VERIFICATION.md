# Verification Guide / 验证说明

## Command Checks / 命令验证

### 1) Launcher and injector syntax / 启动器和注入器语法

```bash
bash -n launch-codex-plugin-unlock.command
python3 -m py_compile inject_plugin_unlock.py
```

### 2) CDP endpoint reachable / CDP 端点可达
After launcher starts Codex:

```bash
curl --noproxy '*' http://127.0.0.1:9229/json/list
```

预期：返回包含 `"type":"page"` 的 JSON。

### 3) Safety boundaries / 安全边界

```bash
lsof -nP -iTCP:57321 -sTCP:LISTEN
pgrep -fl codex_session_delete
```

预期：无监听、无相关进程。

### 4) Git publish checks / Git 发布检查

```bash
git status --short
git remote -v
```

预期：工作区干净、`origin` 指向 `fredgena74/github-codexchajian`。

## UI Acceptance / UI 人工验收
1. Plugin entry (`Plugins/插件/外挂程式/外掛程式`) is visible and clickable in API key mode.
2. In plugin page, when app status shows `App unavailable / 应用不可用 / 應用程式無法使用`, install button is clickable.
3. After Codex exits, watcher exits automatically.

1. API Key 模式下，`Plugins/插件/外挂程式/外掛程式` 入口可见可点。
2. 插件页出现 `App unavailable / 应用不可用 / 應用程式無法使用` 时，安装按钮可点击。
3. Codex 退出后，watcher 自动退出。
