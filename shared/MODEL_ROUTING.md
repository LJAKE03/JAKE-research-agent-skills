# 科研 Agent 模型与工具路由

## 已验证的本机能力

- `codex-cli 0.144.1` 的 `codex debug models` 返回 `gpt-5.6-sol`、`gpt-5.6-terra` 和 `gpt-5.6-luna`；Sol/Terra 支持 `low` 至 `ultra`，Luna 支持 `low` 至 `max`。
- Terra 与 Luna 均已在本机目录中验证，可用于项目级自定义子代理。
- 项目级 `.codex/config.toml` 与 `.codex/agents/*.toml` 已存在并通过严格配置和路由测试：`max_threads=2`、`max_depth=1`；`research-support` 使用 Terra/`medium`/只读，`research-output` 使用 Luna/`low`/只读。
- Windows 应用版以项目级配置为主要路由机制；CLI 的 `--profile research` 仅作为兼容入口。本仓库只提供 `config/research.config.toml.template`，不覆盖用户的 `~/.codex/config.toml`。
- `shared/MODEL_ROUTING.json` 是唯一 canonical JSON；Draft 2020-12 Schema 和运行时安全契约共同校验它。项目快照必须与 canonical 的 SHA256 一致。
- 默认采用平衡快速模式：首轮 0–2 个阻断问题；投稿、申报、安全、高成本决策和科学最终验收切换严格模式。`codex debug models` 无法核验或 Sol 不可用时阻断启动；仅 Terra/Luna 缺失时提示并进入 Sol-only。

## 三层逻辑路由

| 层 | 当前映射 | 默认 reasoning | 允许的工作 |
|---|---|---|---|
| `strategic / sol` | `gpt-5.6-sol` | `xhigh`（可降至 `high`） | 计划、路线、关键判断、证据审核、最终验收 |
| `support / terra` | `gpt-5.6-terra` | `medium` | 边界明确的提取、扫描、汇总、脚本测试；只给候选结果 |
| `economy / luna` | `gpt-5.6-luna` | `low` | 已确认内容的机械格式化、字段重排、目录和索引 |

低成本层不得决定研究方向、任务拆解、技术路线、模型/参数/边界条件、异常诊断、文献可靠性、公式和数值、实验方案、工程安全或最终科研结论。发现不确定内容时必须标记“待主代理确认”。

## 委派约束

- A 类关键任务仅由 `strategic` 主代理完成；最终责任不可委派。
- B 类支持任务可以由 `support` 执行，主代理必须核查来源、数据和候选结论。
- C 类仅在输入完整、格式明确、无需新判断且可机械验收时才可交给 `economy`；主代理仍需抽检。
- D 类混合任务先由主代理确定框架，再委派明确部分，最后由主代理合并验收。
- 默认并发不超过 2；子代理不得递归创建子代理；主代理必须阅读每一份结果并生成面对用户的最终答复。
- 模型映射变更前必须重新运行 `codex debug models`；先修改 canonical JSON，再让 agent TOML、项目快照和测试从 canonical 派生或接受一致性检查。

## 工具路由与输出控制

先选能以最少交互、最小输出、最低失败率完成任务的工具：Codex 内置读取/搜索/精确补丁，其次 `rg`、`git` 和已验证脚本，再按任务选择 Python 或 PowerShell。

- Windows 启动器、快捷方式、注册表、环境变量、系统路径、CMD/PowerShell 兼容性和简单 Windows 文件操作优先 PowerShell。
- CSV/JSON/Excel、数值计算、数据清洗、统计绘图、跨平台批处理及可单测的重复逻辑优先 Python。预计重复两次以上的复杂处理应沉淀为带参数、退出码和 `--quiet`/`--json` 的脚本。
- 搜索文本或文件使用受限范围的 `rg`/`rg --files`；查看改动使用 `git diff`。不要用 Python 重写 Git，也不要用 Python 替代单条可靠的 PowerShell 或 `rg` 命令。
- 大型结果写入文件，终端只输出状态、路径、数量、摘要和异常。搜索限制目录、关键词和文件类型；默认关闭详细日志。错误先分析根因，连续两次同类失败后必须改变诊断方法。

## 使用、兼容与回退

1. Windows 应用版主线程选择 Sol 和 `high`/`xhigh`/`max`；项目级 agent TOML 分别为 Terra 支持代理和 Luna 输出代理指定模型、reasoning 与只读权限。
2. 需要手动指定任务层时，使用 `strategic=Sol`、`support=Terra/medium`、`economy=Luna/low`；最终输出仍由主代理审核。
3. 关闭子代理时，由主代理直接执行 B/C 类任务；不得把关键科研判断交给低 reasoning 任务。
4. CLI 用户可选地将模板复制为 `$CODEX_HOME/research.config.toml` 并运行 `codex --profile research`；该兼容方式不参与应用版项目级子代理路由，也不修改用户默认配置。
5. 调整模型或 reasoning 前先运行 `codex debug models`；配置变更后执行应用路由专项自检和全量 Skills 自检。
6. 路由记录见 `shared/MODEL_ROUTING.json`；发布前严格运行 `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-ResearchSkills.ps1`，并保证 Python `jsonschema` 可用。仅做离线静态检查时显式追加 `-AllowUnverifiedModelCatalog`；不得在发布验收中使用该开关。
7. 如需回退 CLI 兼容 profile，只删除用户自行复制的 `research.config.toml`；这不会影响项目级 `.codex/agents` 或用户原有默认配置。