# Project Research Skills Instructions

本项目使用一条统一科研流程。复杂科研任务优先调用 `$research-project-orchestrator`；用户不选择模型、Agent 或工作模式。

## 执行规则

1. 需要恢复、跨阶段追踪或高影响决策时读取 `PROJECT_STATE.md` 和 `PROJECT_OVERRIDES.md`；否则只读取当前任务所需输入。
2. 不重复询问已确认信息；按 `PROACTIVE_INQUIRY_AND_MEMORY_PROTOCOL.md`（由总控从已安装的 `shared` 目录加载）先检查项目材料、再核实权威公开事实，只询问会改变结果且用户独有的信息，并说明影响。
3. Sol 自动选择功能 Skill，只有真实依赖才形成阶段。
4. 需要有界检索、查证、扫描、提取或证据表且路由状态为 `ready` 时，必须创建专用 Worker；从 `.research-agent/MODEL_ROUTING.json` 的 `runtime_dispatch.support_agent_type`、`runtime_dispatch.fork_turns` 和 `tiers.support` 读取调用参数，不在项目规则中复制模型映射。
5. 写作包完整且需要正式章节、多段成稿、表格、语言版本或格式化文本时，必须创建专用 Worker；从项目 canonical 快照的 `runtime_dispatch.economy_agent_type`、`runtime_dispatch.fork_turns` 和 `tiers.economy` 读取调用参数。
6. 角色调用形态由 TOML 锁定模型和 reasoning；显式模型形态只能使用 canonical 路由值并在任务卡中重申只读边界。若 spawn 无法锁定目标模型，则用官方一次性 `codex exec --disable multi_agent --ephemeral --sandbox read-only` 适配并显式锁定模型/reasoning；不开发常驻 runtime。真实子线程、成功 spawn，或退出码为 0 且返回合规交接包的一次性调用才算运行证据。
7. Worker 不互相转交或递归委派，按紧凑交接 Schema 返回 Sol。
8. 模型间不传递完整对话、全部日志、全部项目历史或整篇原文。
9. 三种调用形态都不可用、目标模型不可用或一次合规调用失败时使用 canonical 快照的 `runtime_dispatch.failure_status`，由 Sol 继续有界任务并透明说明；不得假称已调用 Worker。
10. 投稿、关键参数、核心方法、安全/高成本和最终科学结论由 Sol 紧凑验收。
11. Skill 使用问题写入 `SKILL_FEEDBACK.md`；项目特有规则写入 `PROJECT_OVERRIDES.md`。
12. 未经用户确认，不修改公共稳定 Skill；不得虚构文献、数据、实验、结果或完成状态。
13. 跨文件科研代码检索可调用已安装的 `07-code-context`；不得自动安装或初始化 CodeGraph，工具不可用、无索引或陈旧时回退 `rg`、定点读取和已有测试。

## 项目经验与全局晋升

1. 若项目位于已初始化科研工作区的 `projects/project-编号-项目名` 下，读取 `../../RESEARCH_WORKBENCH.md` 和 `../../PROJECT_SOP.md`；只按当前阶段、Skill 和标签检索 `../../GLOBAL_LESSONS.md` 的相关条目，不全文加载全部历史。
2. 当前明确指令优先于项目约束和长期记忆；仅当冲突会实质改变结果时，提出一个聚焦确认，不静默覆盖历史规则。
3. 项目踩坑、失败尝试、有效方法、利好和工作习惯候选先写入 `08_质量门与复盘/PROJECT_RETROSPECTIVE.md`，并保留证据定位与适用边界。
4. 仅在阶段边界、重大异常或项目收尾时总结经验；A/B 级重要习惯与工作流详细记录，C 级低影响经验只保留关键步骤，D 级项目特例不晋升。
5. 用户反复纠正同类问题时，主动合并复现证据并提出更精确的稳定规则候选；重复次数不能替代授权。
6. 项目收尾先生成带编号的候选摘要，再询问批准全部、指定子集、拒绝或延后。未回复不得写入个人全局记忆，同一候选集没有实质变化时不得重复询问。
7. Skill 缺陷继续写入 `SKILL_FEEDBACK.md`；修改公共稳定 Skill 还必须经过用户确认和回归测试。


<!-- research-agent-routing:start -->
## 科研 Skills 托管路由

执行科研 Skill 前，由 `00-research-orchestrator` 读取 `.research-agent/MODEL_ROUTING.json` 和 `.research-agent/MODEL_ROUTING.md`。

- strategic 使用 Sol，负责需求、规划、方法、证据综合、关键科研判断和最终答复。
- support 使用 Terra、`medium`、只读，负责有界检索、网页查证、文件扫描、提取、证据表和来源完整性核验。
- economy 使用 Luna、`low`、只读，根据锁定提纲、论点、证据编号和格式要求生成文本、语言和格式。
- Luna 不得新增事实、引用、公式、因果关系或科研结论；Terra 不得裁决来源可靠性、研究路线或最终结论。
- 仅当 `.research-agent/routing-version.json` 为 `ready`，或模型目录已验证且 `status=degraded_sol_only`、Sol 可用时才执行；其他状态先运行路由预检。
- `degraded_sol_only` 时禁止委派 Terra/Luna，由 Sol 直接完成当前有界任务。
- `ready` 时优先使用 `agent_type=research_support/research_output`；否则使用经过验证的 Terra/Luna 显式模型 spawn；若 spawn 不能锁定目标模型，则使用官方一次性只读 `codex exec`。spawn 形态均以 `fork_turns=none` 创建。
- 只有真实子线程、成功 spawn，或锁定目标模型且退出码为 0、返回合规交接包的一次性 `codex exec` 才算运行证据；正文自述不算。
- Worker 不得递归委派或互相转交；项目限制为 `max_threads=2`、`max_depth=1`。
- Sol 只发送紧凑任务卡：目标、输入定位、锁定决定、输出结构、验收和停止条件；Worker 按紧凑交接 Schema 返回。
- 搜索使用 `rg`，差异检查使用 `git diff`；Windows 任务优先 PowerShell，科研计算和数据处理优先 Python。
- Windows PowerShell 读取 UTF-8 文本时显式使用 `Get-Content -Encoding UTF8`；文本修改使用 `apply_patch`。
- 大型结果写入文件，终端只输出状态、路径、数量、摘要和异常。
<!-- research-agent-routing:end -->
