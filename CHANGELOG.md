# Changelog

本文件只记录本套件可追溯的版本变更；未虚构初始化前的历史。

## [Unreleased]

### Added

- 新增投稿级 PUBLICATION_CLAIM_TRACEABILITY 合同模板和对应行为评测，追溯核心命题、贡献、证据缺口、结果映射、审稿风险与受影响重验位置。
- 新增 `update-history/` 独立历史更新目录，为每次实质性优化记录根因、变更范围、兼容与数据保护、验证证据以及 Git/PR 追溯。
- 新增 `CHANGE_INTEGRITY_PROTOCOL.md`，统一根因修复、唯一权威来源、活动文件收敛、兼容层退出条件与科研追溯保护。
- 新增只读 handoff 负向 fixture 和行为评测，覆盖路由漂移、证据清理边界及违规 `changed_files` 阻断。
- 新增个人科研工作区模板与非覆盖初始化脚本，分离公共 Skills 能力代码和私人长期记忆。
- 新增 `project-编号-项目名` 自动编号、相对路径项目索引和项目级结构化复盘模板。
- 新增科研工作区端到端回归测试，覆盖幂等初始化、内容保留、编号递增、占位符替换和隐私边界。
- 新增共享 `CONTEXT_EFFICIENCY_PROTOCOL.md`：提供逐级上下文获取、任务内交付账本、可逆省略、科研无损区、最小实现阶梯和结构预算。
- 新增跨流程与代码上下文评测，覆盖未变化证据复用、长日志可恢复摘要、符号优先检索、重复源码防护和关键数值/单位无损验证。
- 新增 UTF-8 编码回归测试：严格解码仓库文本、静态检查 PowerShell 显式编码与 5.1 非 ASCII 脚本 BOM、验证中文无 BOM 往返，并在可用时同时运行 PowerShell 5.1/7。
- 新增 UTF-8 首次读取 eval，要求正常中文、零编码重试和摘要输出。
- 新增紧凑任务卡与 `STAGE_HANDOFF.schema.json` v2，分别支持 Terra 证据包、Luna 写作草稿、阶段结果和验证结果。
- 新增统一工作流行为回归测试，覆盖 Sol 主责、Terra 证据支持、Luna 锁定写作包和 Sol 最终验收。
- 新增可选 `07-code-context` Skill：在 CodeGraph MCP 已可用且项目已索引时执行一次有界跨文件代码检索，否则回退 `rg`、定点读取和已有测试。
- 新增科研代码上下文胶囊与正向、无依赖回退、单文件近失配评测，避免把完整图检索输出传回总控。

### Changed

- 学术写作与质量门增加投稿论断追溯闭环；未确认合同不进入实质写作，主要结果必须映射贡献与证据条件，未关闭的重大科学异议会阻断可投稿结论。
- 总控、检索、写作、项目模板和启动提示不再手写模型映射；兼容调用参数从 `MODEL_ROUTING.json` 或项目 canonical 快照读取，CLI profile 也纳入同步脚本。
- README 将目录级兼容入口明确为同一 canonical 路由的替代初始化方式，不再呈现为第二套流程。
- 总控、仓库规则和项目模板统一采用“项目内捕获、去敏晋升、用户批准后进入全局”的两级经验闭环。

- 启动器可安全补齐已有项目缺失的复盘模板，并识别已初始化科研工作区的新建流程。
- 保留原有 `-Destination` 项目创建方式，新增 `-WorkspaceRoot` 模式而不破坏旧用法。
- 总控、外部检索、学术写作、质量门、代码上下文和阶段交接模板统一引用共享上下文效率协议，不增加顶层 Skill 或修改 handoff Schema。
- 代码检索改为符号/提纲优先、按验证目标扩展最小片段，并对未变化内容使用 reused 交付。
- 在根目录、项目模板和共享工具路由中统一最小编码纪律：显式 `Get-Content -Encoding UTF8`，大型文件优先限定读取，禁止乱码后反复 `chcp` 或重读全文。
- 总控改为一条统一科研流程；用户不再选择或看到工作模式、模型或 Agent。
- Sol 负责需求、规划、方法、证据综合和关键科研判断；Terra 负责有界检索、查证、扫描、提取和证据表。
- Luna 从机械格式化扩展为根据锁定提纲、论点、证据编号和格式要求生成科研文本，同时禁止新增事实和判断。
- 只有真实依赖才创建阶段；新证据可触发阶段合并、重排、取消或重写。
- Worker 只接收紧凑任务卡并返回紧凑交接包，不复制完整历史、全部日志或整篇原文。
- 质量检查保留 L0/L1/L2 作为内部强度；投稿、关键参数、核心方法和最终结论由 Sol 做一次紧凑验收。
- 明确代码图仅减少代码发现成本，不替代文献、数据、实验或最终科学证据；关键方法、参数和数据转换必须定点验证。

### Fixed

- `STAGE_HANDOFF.schema.json` 现在会拒绝只读 `evidence_pack`、`writing_draft` 和 `verification_result` 中的非空 `changed_files`。
- 设计说明不再硬编码已过时版本号，当前版本以 `VERSION` 为唯一权威来源。
- 修复科研工作区并发创建可能丢失索引条目，以及初始化失败后项目目录无法从索引恢复的问题。
- 停止跟踪包含本机最近项目路径的启动器运行配置，改为忽略运行文件并提供空白示例配置。
- 清理 PROJECT_STATE 模板残留的旧工作模式字段，并增加隐私边界与统一流程回归断言。
- 修复架构向多工作模式和独立 Runtime 偏移的问题。
- 修复 Luna 只能机械处理、无法承担锁定证据包写作的问题。

### Removed

- 删除 Fast / Standard / Strict / Exploratory 对外路线。
- 删除 `CAPABILITY_MANIFEST`、`RUNTIME_POLICY`、运行事件 Schema/写入器及专用 Runtime 测试。
- 删除尚未证明价值的 WP5 专用 A/B 驱动器、Prompt 和输出 Schema；保留精简诊断记录。

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
