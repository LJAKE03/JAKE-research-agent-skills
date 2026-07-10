# Project Agent Instructions

本项目采用科研 Agent Skills 协同体系。

## 强制入口

复杂科研任务优先调用 `$research-project-orchestrator`。

## 执行规则

1. 开始前读取 `PROJECT_STATE.md` 和 `PROJECT_OVERRIDES.md`。
2. 不重复询问已确认信息；可自行检索的事实先自行核实。
3. 大型任务拆成 3–5 个阶段，一次只执行一个工作包。
4. 每阶段完成后进入质量门，并更新 `PROJECT_STATE.md`。
5. Skill 使用问题写入 `SKILL_FEEDBACK.md`；项目特有规则写入 `PROJECT_OVERRIDES.md`。
6. 未经用户确认，不修改公共稳定 Skill。
7. 不得虚构文献、数据、实验、结果或已完成状态。
