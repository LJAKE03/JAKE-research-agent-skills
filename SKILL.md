---
name: research-agent-skills-index
description: Entry index for the coordinated research Agent Skills suite. For any complex research project, start with 00-research-orchestrator/SKILL.md and load other skills only when routed by the orchestrator.
---

# 科研 Agent Skills 总入口

本文件只负责索引，不承载完整工作流。

必须首先读取：

- `00-research-orchestrator/SKILL.md`

由总控按当前阶段选择：

- `01-requirement-elicitation/SKILL.md`
- `02-research-reconnaissance/SKILL.md`
- `03-stage-planning-execution/SKILL.md`
- `04-literature-review/SKILL.md`
- `05-academic-writing/SKILL.md`
- `06-quality-gate/SKILL.md`

协同规则：

1. 复杂任务先澄清、再检索、后拆解。
2. 一次只执行一个工作包。
3. 功能 Skill 必须返回阶段交接包。
4. 每阶段必须经过质量门。
5. 关键节点由用户确认。
6. 更新 `shared/PROJECT_STATE.template.md`。
7. 不得绕过总控直接从一个功能 Skill 跳到另一个。
