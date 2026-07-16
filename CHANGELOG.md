# Changelog

本文件只记录本套件可追溯的版本变更；未虚构初始化前的历史。

## [Unreleased]

暂无。

## [2.1.0] - 2026-07-16

### Added

- 新增 Windows 一键启动器“启动科研Agent.cmd”及 scripts\Start-ResearchAgent.ps1：支持新建、打开、最近项目、Skills 检查、图形/控制台回退输入、项目感知启动 Prompt 与安全 Codex 启动。
- 新增启动器配置 scripts\research-launcher-settings.json、桌面快捷方式脚本 scripts\Create-ResearchAgentShortcut.ps1 和使用说明“科研Agent一键启动器说明.md”。
- 新增 --self-test 非交互端到端自检；测试数据使用受控临时目录并在安全边界核验后清理。
- 新增同步与 ZIP 备份的隔离文件内容回归测试，以及 Sol-only 降级、Sol 缺失阻断和 copy-mode 安装回归。
- 评测合同增加 strategic、support、economy、mixed 路由与风险等级覆盖；新增 Draft 2020-12 Schema、实际验证器和 canonical 派生文件同步器。

### Changed

- `shared/MODEL_ROUTING.json` 升级为唯一 canonical JSON，项目模板保留字节一致快照并记录 SHA256。
- 默认改为平衡快速模式，首轮最多询问 2 个阻断问题；质量门分为 L0/L1/L2。
- 运行时验证 Sol/Terra/Luna 的 model slug 与 reasoning；Sol 或模型目录不可验证时 fail-closed，只有 Terra/Luna 缺失时进入 `degraded_sol_only`。
- 路由冲突写入 `blocked_conflict` 并返回非零；启动器仅接受哈希一致的 `ready`，或 Sol 已验证的 `degraded_sol_only`。离线静态检查必须显式使用 `-AllowUnverifiedModelCatalog`。

### Fixed

- 修复 `Copy-Item -LiteralPath` 与通配符组合导致复制模式同步失效的问题。
- 修复 ZIP 备份把 `*` 当作字面路径的问题，并确保隐藏项进入归档。

- 默认启动方式改为 Codex Desktop 图形界面；项目路径与科研启动 Prompt 自动复制到剪贴板，不再进入终端版 Codex CLI 黑色会话。
- 使用 Windows 已注册的 Codex Desktop 应用入口启动，不再把 WindowsApps 内无法作为终端 CLI 运行的 codex.exe 误判为可用 CLI。
- 将“启动科研Agent.cmd”规范为 UTF-8（无 BOM）与 Windows CRLF，修复中文乱码和命令截断。
- 改为从脚本位置解析仓库根目录，并清理外层引号、校验控制字符与目录存在性，修复 GetFullPath() 非法字符异常。
- 捕获 New-ResearchProject.ps1 的消息输出，保证新建流程只返回一个规范化项目路径。
- 修复模板目录重复创建、Windows 保留项目名、尾随点空格和目标路径边界问题。
- 增加配置字段类型校验、原子写入、有效项目识别、大小写无关去重和最近 10 项限制。
- 安全初始化改为原子创建缺失文件，避免竞态覆盖；已有文件保持不变。
- 修正 PowerShell 语法检查，使解析错误不会被误报为 PASS。
- 快捷方式更新时清空旧参数，并回读校验目标、参数和工作目录。

## [2.0.0] - 2026-07-10

### Added

- 初始化正式源仓库的版本、开发规范、反馈、候选修改和回归测试目录。
- 增加安装、同步、检查、备份和新建科研项目的 PowerShell 脚本。
- 增加科研项目模板与 Skill 运行复盘模板。

### Changed

- 将 research-agent-skills-v2 明确为唯一正式源仓库。

### Fixed

- 默认启动方式改为 Codex Desktop 图形界面；项目路径与科研启动 Prompt 自动复制到剪贴板，不再进入终端版 Codex CLI 黑色会话。
- 使用 Windows 已注册的 Codex Desktop 应用入口启动，不再把 WindowsApps 内无法作为终端 CLI 运行的 codex.exe 误判为可用 CLI。

### Deprecated

- 无。

### Removed

- 无。
