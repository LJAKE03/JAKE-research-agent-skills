# 科研 Skills 模型与工具路由

## 已验证能力

- `codex-cli 0.144.1` 的模型目录包含 `gpt-5.6-sol`、`gpt-5.6-terra` 和 `gpt-5.6-luna`。
- 项目级 `.codex/config.toml` 固定 Sol/`xhigh`、启用 multi-agent、注册两个专用角色，并限制 `max_threads=2`、`max_depth=1`。
- `research-support` 使用 Terra/`medium`/只读；`research-output` 使用 Luna/`low`/只读。
- `shared/MODEL_ROUTING.json` 是唯一 canonical JSON；项目快照必须与其 SHA256 一致。
- Sol 或模型目录无法验证时阻断启动；仅 Terra/Luna 缺失时进入 `degraded_sol_only`，由 Sol 直接完成对应工作。

## 一条流程中的三种责任

| 内部层 | 模型 | 责任 |
|---|---|---|
| `strategic / sol` | `gpt-5.6-sol` | 需求、规划、拆解、方法、证据综合、关键科研判断和最终验收 |
| `support / terra` | `gpt-5.6-terra` | 有界检索、网页查证、文件扫描、提取、证据表和来源完整性核验 |
| `economy / luna` | `gpt-5.6-luna` | 根据锁定提纲、论点、证据编号和格式要求生成文本、语言和格式 |

这些是内部自动路由，不向用户暴露模型或工作模式选择。

## 委派边界

- 项目配置固定根任务为 `gpt-5.6-sol`/`xhigh`，并显式启用 multi-agent。
- `research_support` 和 `research_output` 必须在 `[agents.<name>]` 中用 `config_file` 注册，确保 spawn 工具能看到角色及其锁定模型。
- 命中 Terra/Luna 条件且状态为 `ready` 时必须实际委派，并先检查当前 `spawn_agent` 参数形态。
- 支持 `agent_type` 时分别使用 `research_support` 或 `research_output`，由角色 TOML 锁定模型和 reasoning；不支持 `agent_type` 时使用 `task_name` 加 canonical 中的 Terra/Luna `model`、`reasoning_effort`，两种形态均设置 `fork_turns=none`。
- 显式模型形态的任务卡必须重申只读、禁止递归委派和紧凑交接边界。
- 若 spawn 无法锁定目标模型，使用官方一次性 `codex exec`：禁用 multi-agent、启用 ephemeral 和 read-only sandbox，并用 `-m` 与 `model_reasoning_effort` 锁定 canonical 模型；只传紧凑任务卡，完成即退出，不建立独立 runtime。
- 只有真实子线程、成功的 spawn 工具结果，或锁定目标模型且退出码为 0 且返回合规交接包的一次性 `codex exec` 才算运行证据；正文自述不算。
- 三种形态都不可用、目标模型不可用或一次合规调用失败时标记 `degraded_sol_only`，由 Sol 完成有界任务并透明说明。
- Sol 先形成紧凑任务卡；命中 Terra/Luna 条件时按上述 Agent 类型实际委派。
- Terra 只返回证据包，不裁决研究方向、方法、参数、来源可靠性或最终结论。
- Luna 只接收完整锁定写作包，可以生成草稿，但不得新增事实、引用、公式、因果关系或科研判断。
- Worker 不得递归创建 Worker，也不得互相转交。
- Sol 阅读所有返回结果、处理冲突并生成用户最终答复。
- 只有任务独立、输入只读或互不重叠、输出已分区时才可并行。

## 紧凑上下文

- Sol → Terra：目标、定位、锁定决定、输出结构、验收和停止条件。
- Terra → Sol：证据表、来源定位、事实摘要、冲突和缺口。
- Sol → Luna：锁定提纲、论点、证据编号、风格、长度、格式和禁止新增项。
- Luna → Sol：草稿、占位符、不确定项和下一动作。
- 不在模型间复制完整对话、全部项目历史、全部工具日志或整篇论文原文。

## 质量检查

- L0：确定性工具检查。
- L1：Terra 只读核对来源定位、字段和证据覆盖。
- L2：Sol 裁决来源可靠性、方法、参数、解释和最终科学结论。

投稿、申报、安全或高成本决策、关键参数、核心方法和最终科学结论自动使用 L2。Sol 只做一次紧凑语义验收，不重新写全文。

## 工具与输出

- 搜索文本和文件使用受限范围的 `rg`/`rg --files`；版本检查使用 `git diff`。
- Windows 启动器、系统路径、环境变量和简单 Windows 文件操作优先 PowerShell。
- CSV/JSON/Excel、数值计算、数据清洗、绘图和可复用批处理优先 Python。
- Windows PowerShell 读取 UTF-8 文本显式使用 `Get-Content -Encoding UTF8`；文本修改优先 `apply_patch`。
- 大型结果写入文件，终端只输出状态、路径、数量、摘要和异常。
- 修改后先运行最小相关测试，再运行全量自检。
