# Project Research Skills Instructions

本项目使用一条统一科研流程。非简单科研任务优先调用 `$research-project-orchestrator`；用户可在启动新任务前配置战略总控、证据 Worker 和输出 Worker 的模型。

## 执行规则

1. 需要恢复、跨阶段追踪或高影响决策时读取 `PROJECT_STATE.md` 和 `PROJECT_OVERRIDES.md`；否则只读取当前任务所需输入。
2. 不重复询问已确认信息；按 `PROACTIVE_INQUIRY_AND_MEMORY_PROTOCOL.md`（由总控从已安装的 `shared` 目录加载）先检查项目材料、再核实权威公开事实，只询问会改变结果且用户独有的信息，并说明影响。
3. 战略总控 自动选择功能 Skill，只有真实依赖才形成阶段。
4. 有界检索、查证、扫描、提取或证据表任务能够独立分离，且委派能明显节省上下文或时间时，可创建专用 Worker；从项目选择与默认路由解析 support 调用参数。短小查证由战略总控直接完成。
5. 锁定输出包完整、剩余工作可独立分离且工作量足以抵消委派开销时，可创建输出 Worker；从项目选择与默认路由解析 economy 调用参数。短篇或局部编辑由战略总控直接完成。
6. 角色调用形态由 TOML 锁定模型和 reasoning；显式模型形态只能使用 canonical 路由值并在任务卡中重申只读边界。若 spawn 无法锁定目标模型，则用官方一次性 `codex exec --disable multi_agent --ephemeral --sandbox read-only` 适配并显式锁定模型/reasoning；不开发常驻 runtime。真实子线程、成功 spawn，或退出码为 0 且返回合规交接包的一次性调用才算运行证据。
7. Worker 不互相转交或递归委派，按紧凑交接 Schema 返回 战略总控。
8. 模型间不传递完整对话、全部日志、全部项目历史或整篇原文。
9. 三种调用形态都不可用、目标模型不可用或一次合规调用失败时使用 canonical 快照的 `runtime_dispatch.failure_status`，由 战略总控 继续有界任务并透明说明；不得假称已调用 Worker。
10. 投稿、关键参数、核心方法、安全/高成本和最终科学结论由 战略总控 紧凑验收。
11. Skill 使用问题写入 `SKILL_FEEDBACK.md`；项目特有规则写入 `PROJECT_OVERRIDES.md`。
12. 公共 Skill 的已授权修改可直接完成并做相关回归检查；发布、不可逆删除或超出既有授权的高影响变更再请求确认。不得虚构文献、数据、实验、结果或完成状态。
13. 跨文件科研代码检索可调用已安装的 `07-code-context`；不得自动安装或初始化 CodeGraph，工具不可用、无索引或陈旧时回退 `rg`、定点读取和已有测试。

## 项目经验与全局晋升

1. 若项目位于已初始化科研工作区的 `projects/project-编号-项目名` 下，读取 `../../RESEARCH_WORKBENCH.md` 和 `../../PROJECT_SOP.md`；只按当前阶段、Skill 和标签检索 `../../GLOBAL_LESSONS.md` 的相关条目，不全文加载全部历史。
2. 当前明确指令优先于项目约束和长期记忆；仅当冲突会实质改变结果时，提出一个聚焦确认，不静默覆盖历史规则。
3. 项目踩坑、失败尝试、有效方法、利好和工作习惯候选先写入 `08_质量门与复盘/PROJECT_RETROSPECTIVE.md`，并保留证据定位与适用边界。
4. 仅在阶段边界、重大异常或项目收尾时总结经验；A/B 级重要习惯与工作流详细记录，C 级低影响经验只保留关键步骤，D 级项目特例不晋升。
5. 用户反复纠正同类问题时，主动合并复现证据并提出更精确的稳定规则候选；重复次数不能替代授权。
6. 项目收尾先生成带编号的候选摘要，再询问批准全部、指定子集、拒绝或延后。未回复不得写入个人全局记忆，同一候选集没有实质变化时不得重复询问。
7. Skill 缺陷继续写入 `SKILL_FEEDBACK.md`；修改公共稳定 Skill 时保留变更记录并运行与改动相关的回归检查。


<!-- research-agent-routing:start -->
## 科研 Skills 托管路由

执行科研 Skill 前，由 `00-research-orchestrator` 读取 `.research-agent/MODEL_ROUTING.json` 和 `.research-agent/MODEL_ROUTING.md`。

- strategic 使用 战略总控，负责需求、规划、方法、证据综合、关键科研判断和最终答复。
- support 使用 证据 Worker、`medium`、只读，负责有界检索、网页查证、文件扫描、提取、证据表和来源完整性核验。
- economy 使用 输出 Worker、`low`、只读；当单一成品的内容、字段、顺序、模板和决策已锁定且只剩低判断组织时，根据锁定输出包生成文本、表格、语言和格式规格。
- 输出 Worker 不得新增事实、引用、公式、计算、分类、优先级、因果关系或科研结论，也不直接编辑文件；证据 Worker 不得裁决来源可靠性、研究路线或最终结论。
- 仅当 `.research-agent/routing-version.json` 为 `ready`，或模型目录已验证且 `status=degraded_strategic_only`、战略总控 可用时才执行；其他状态先运行路由预检。
- `degraded_strategic_only` 时禁止委派 证据 Worker/输出 Worker，由 战略总控 直接完成当前有界任务。
- `ready` 时优先使用 `agent_type=research_support/research_output`；否则使用经过验证的 证据 Worker/输出 Worker 显式模型 spawn；若 spawn 不能锁定目标模型，则使用官方一次性只读 `codex exec`。spawn 形态均以 `fork_turns=none` 创建。
- 只有真实子线程、成功 spawn，或锁定目标模型且退出码为 0、返回合规交接包的一次性 `codex exec` 才算运行证据；正文自述不算。
- Worker 不得递归委派或互相转交；项目限制为 `max_threads=2`、`max_depth=1`。
- 战略总控 只发送紧凑任务卡：目标、输入定位、锁定决定、输出结构、验收和停止条件；Worker 按紧凑交接 Schema 返回。
- 搜索使用 `rg`，差异检查使用 `git diff`；Windows 任务优先 PowerShell，科研计算和数据处理优先 Python。
- Windows PowerShell 读取 UTF-8 文本时显式使用 `Get-Content -Encoding UTF8`；文本修改使用 `apply_patch`。
- 大型结果写入文件，终端只输出状态、路径、数量、摘要和异常。
<!-- research-agent-routing:end -->
