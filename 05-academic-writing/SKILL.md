---
name: academic-paper-and-report-writing
description: Use to plan, draft, revise, or integrate SCI papers, short academic papers, course papers, technical reports, project reports, research summaries, proposals, and other formal research outputs. It must write from approved evidence, data, methods, figures, and claims; work section by section; maintain a claims-to-evidence map and cross-section consistency; avoid invented results or references; and return each substantial section to the orchestrator and quality gate before continuing.
---

# SCI 论文与技术报告写作

<!-- routing-preflight:required -->
执行前确认总控已加载 `../shared/MODEL_ROUTING.json`；如未加载，先返回 `../00-research-orchestrator/SKILL.md`，不得直接执行。本 Skill 只引用共享规则，不复制其全文。

## 1. 角色

将已通过前序阶段确认的研究内容转化为正式成果。写作不能替代研究设计、数据分析或证据检索。

## 2. 开始条件

写作前确认：

- 目标读者、期刊或模板；
- 文档类型；
- 研究问题；
- 已批准的方法和数据；
- 关键结论；
- 图表清单；
- 引用格式；
- 字数和语言；
- 哪些内容仍是计划而不是已完成结果。

若核心证据未准备好，返回总控，不得用占位式虚构内容补齐。

## 3. 执行身份与委派

- 如果当前 Agent 是 `research_output`，只根据收到的锁定写作包起草并返回 `writing_draft`，不得新增科研事实或判断，也不得创建 Worker。
- 如果当前 Agent 是 Sol，先检查并锁定目标、提纲、论点顺序、允许事实/数据/公式/引用、语言、长度、格式、禁止新增项、验收和停止条件。
- 写作包完整且目标是正式章节、多个段落、表格、语言版本、格式化文本或可直接替换成稿时，必须创建专用 Worker；Sol 不得为节省一次调用而自己重写整段交付物。
- 当前工具支持 `agent_type` 时调用 `spawn_agent(agent_type=research_output, fork_turns=none)`；不支持 `agent_type` 但支持显式模型参数时，调用 `spawn_agent(task_name=research_output, model=gpt-5.6-luna, reasoning_effort=low, fork_turns=none)`，并在锁定写作包中重申只读、无递归委派和禁止新增事实。
- 两种 spawn 形态都不能锁定 Luna 时，若 `codex` 和经验证的 Luna 模型可用，则以 `--disable multi_agent`、`--ephemeral`、`--sandbox read-only`、`-m gpt-5.6-luna`、`model_reasoning_effort="low"` 启动一次性 `codex exec`，只传锁定写作包并要求 `writing_draft`。
- 只有单句、短标签、标题候选或少量局部措辞调整可以由 Sol 直接完成。
- 只有三种调用形态都不可用、目标模型不可用或一次合规调用明确失败时，才返回 `degraded_sol_only` 后由 Sol 完成当前有界写作，不得声称已经调用 Luna。

## 4. 先建立论点—证据图

| 论点 | 数据/图表 | 文献 | 推理方式 | 可信度 | 可写入章节 |
|---|---|---|---|---|---|

只有有证据支撑的论点才能进入结果和结论。

## 5. 分段写作，不一次写完整稿

建议顺序：

1. 论文/报告结构和图表安排；
2. 方法；
3. 结果与分析；
4. 讨论；
5. 引言；
6. 结论；
7. 摘要、关键词、题目；
8. 全文一致性检查。

每完成一个主要章节，返回总控进入质量门。

## 6. SCI 小论文结构

### Title

准确反映对象、方法和核心问题，不夸大创新。

### Abstract

按需要包含：背景/问题、方法、最重要的定量结果、机制或意义。不得写正文没有出现的结论。

### Introduction

使用四段式：

1. 背景；
2. 研究进展与缺口；
3. 研究目标与假设/科学问题；
4. 研究意义与主要贡献。

### Methodology

必须可复现：

- 系统或对象；
- 模型和假设；
- 参数来源；
- 边界与初始条件；
- 实验/仿真流程；
- 验证方法；
- 指标和统计方法；
- 软件版本和关键设置。

### Results and Discussion

默认使用：

```text
现象
→ 定量证据
→ 原因/机理
→ 与已有研究比较
→ 工程或科学意义
→ 限制条件
```

不得只写“升高、降低、改善”。必须说明幅度、条件和不确定性。

### Conclusion

包括：直接回答研究问题、主要定量发现、机制认识、工程意义、适用边界、后续工作。不引入新数据。

## 7. 文献综述文章

若最终成果为综述论文，先调用 `../04-literature-review/SKILL.md` 完成证据矩阵和主题综合，再在本 Skill 中完成：摘要、引言、分类框架、主题章节、综合比较、研究空白、未来方向和结论。

## 8. 技术/项目报告

推荐结构：

1. 执行摘要；
2. 任务背景和目标；
3. 工作范围；
4. 技术路线；
5. 数据、方法和依据；
6. 完成工作；
7. 结果和发现；
8. 问题与风险；
9. 结论；
10. 建议和下一步；
11. 附录与证据。

“完成工作”与“建议工作”必须分开，不能把计划写成已经完成。

## 9. 写作质量规则

- 术语、符号、单位和缩写前后一致；
- 图表先于文字编号并在正文中引用；
- 定量结论可追溯到数据；
- 参考文献真实存在且支持论点；
- 区分实验、仿真、推断和建议；
- 避免绝对化、宣传化和无证据创新表述；
- 不泄露“根据用户文件拼接”“从大论文摘取”等过程性表达；
- 不为增加篇幅重复同一观点；
- 用户要求可直接替换文本时，提供完整、连贯、可粘贴版本。
- 路由或工作流说明中不得写成由用户显式选择模型、Agent 或模式；若草稿出现此类表述，Sol 紧凑验收必须判为 `REVISE`。

## 10. 章节交接

每个章节返回：

```markdown
## 本轮完成
- 章节：
- 依据：
- 主要论点：
- 使用图表：
- 使用文献：

## 尚未完成
- 内容：
- 所需输入：

## 自检
- 与研究目标一致：
- 数据可追溯：
- 无新增虚构：
- 术语一致：
```

随后生成标准阶段交接包，返回总控。
