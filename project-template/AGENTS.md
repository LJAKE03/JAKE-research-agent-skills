# Project Agent Instructions

本项目采用科研 Agent Skills 协同体系。

## 强制入口

复杂科研任务优先调用 `$research-project-orchestrator`。

## 执行规则

1. 复杂或高风险任务开始前读取 `PROJECT_STATE.md` 和 `PROJECT_OVERRIDES.md`；简单快车道只读取当前任务所需输入。
2. 不重复询问已确认信息；可自行检索的事实先自行核实。
3. 大型任务根据 complexity、risk、deliverables、evidence、dependencies 和 validation 动态确定阶段数量，一次只执行一个工作包；阶段数量不设固定上下限，简单任务可少于 3 个阶段，常规复杂任务通常可采用 3–5 个阶段，高复杂度任务可超过 5 个阶段。
4. 按风险执行最低充分质量门；只在阶段切换或高影响状态变化时完整更新 `PROJECT_STATE.md`。
5. Skill 使用问题写入 `SKILL_FEEDBACK.md`；项目特有规则写入 `PROJECT_OVERRIDES.md`。
6. 未经用户确认，不修改公共稳定 Skill。
7. 不得虚构文献、数据、实验、结果或已完成状态。
<!-- research-agent-routing:start -->
## 科研 Agent 托管路由

执行任何科研 Skill 前，先由 `00-research-orchestrator` 读取 `.research-agent/MODEL_ROUTING.json` 和 `.research-agent/MODEL_ROUTING.md`。

- strategic 使用 Sol，由主代理负责研究路线、关键参数、证据审核和最终科研判断。
- support 使用 Terra、`medium`、只读，只提供边界明确的提取、扫描和候选证据。
- economy 使用 Luna、`low`、只读，只处理输入完整且已确认内容的机械输出。
- 仅当 `.research-agent/routing-version.json` 为 `ready`，或模型目录已验证且 `status=degraded_sol_only`、Sol 可用时才可执行；`pending`、`blocked_model_catalog`、`blocked_conflict` 及未知状态必须停止并先运行路由预检。
- `degraded_sol_only` 时禁止委派 support/economy；全部任务由 strategic Sol 完成，直至预检恢复为 `ready`。
- 子代理不得递归委派；项目限制为 `max_threads=2`、`max_depth=1`；所有子代理结果必须由主代理复核。
- 优先使用 Codex 内置读取、搜索和精确补丁；仓库搜索使用 `rg`，差异检查使用 `git diff`。
- Windows 启动器、系统路径、环境变量和 CMD/PowerShell 兼容任务优先 PowerShell；数据清洗、科研计算、CSV/JSON/Excel、绘图和可复用跨平台批处理优先 Python。
- 搜索限制目录、关键词和文件类型；大型结果写入文件，终端只输出状态、路径、数量、摘要和异常；默认关闭详细日志。
- 先运行最小相关测试，最后运行全量自检；连续两次同类失败后必须改变诊断方法，不得盲目重试。
<!-- research-agent-routing:end -->
