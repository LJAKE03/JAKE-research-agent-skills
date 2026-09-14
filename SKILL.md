---
name: research-agent-skills-index
description: Entry index for the coordinated research Skills suite. For any nontrivial research task, start with 00-research-orchestrator/SKILL.md; it runs one unified workflow, automatically selects functional Skills and Sol/Terra/Luna responsibilities, and keeps context transfers compact. Users never choose a mode, model, or Agent.
---

# 科研 Skills 集成包总入口

本文件只负责索引；所有功能 Skill 通过一条统一科研流程协作，不承载另一套 Agent Runtime。

首先读取：

- `00-research-orchestrator/SKILL.md`

功能 Skills：

- `01-requirement-elicitation`：高影响需求和边界；
- `02-research-reconnaissance`：外部检索、查证和资料扫描；
- `03-stage-planning-execution`：真实依赖驱动的阶段任务卡；
- `04-literature-review`：文献矩阵、主题综合和研究缺口；
- `05-academic-writing`：锁定论点和证据后的科研写作；
- `06-quality-gate`：最低充分检查和 Sol 紧凑验收。
- `07-code-context`：可选的科研代码跨文件检索、紧凑胶囊和确定性回退。

跨来源、跨文件、长日志、跨阶段或正式写作任务按需读取 `shared/CONTEXT_EFFICIENCY_PROTOCOL.md`；它是共享规则，不是新的顶层 Skill。

跨 Skill、代码、脚本、Schema、配置、模板、说明和测试的修改按需读取 `shared/CHANGE_INTEGRITY_PROTOCOL.md`；它统一根因修复、唯一权威来源和科研可追溯边界。

统一协同规则：

1. Sol 始终负责理解、规划、方法、证据综合和关键科研判断。
2. Terra 只接收有界证据任务卡，返回证据表、来源定位、缺口和摘要。
3. Luna 只接收锁定输出包；对单一、内容已锁定的低判断成品生成文本、表格、格式和语言版本，不新增科研事实、计算、分类、优先级或判断，也不直接编辑文件。
4. Worker 不互相转交或递归委派，结果统一返回 Sol。
5. 只在真实依赖存在时形成阶段；简单任务直接完成。
6. 质量强度内部自动选择；投稿、关键参数、核心方法和最终科学结论由 Sol 紧凑验收。
7. 模型间不传递完整历史、全部工具日志或整篇原文。
8. CodeGraph 仅作为已安装、已索引时的可选检索后端；不自动安装，不替代源码定点验证、文献、数据或实验。
9. 上下文先复用、再定点补读；摘要必须可恢复，科研关键数值、单位、条件、参数和异常不得有损交接。
