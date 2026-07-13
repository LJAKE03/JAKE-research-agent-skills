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

## 3. 先建立论点—证据图

| 论点 | 数据/图表 | 文献 | 推理方式 | 可信度 | 可写入章节 |
|---|---|---|---|---|---|

只有有证据支撑的论点才能进入结果和结论。

## 4. 分段写作，不一次写完整稿

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

## 5. SCI 小论文结构

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

## 6. 文献综述文章

若最终成果为综述论文，先调用 `../04-literature-review/SKILL.md` 完成证据矩阵和主题综合，再在本 Skill 中完成：摘要、引言、分类框架、主题章节、综合比较、研究空白、未来方向和结论。

## 7. 技术/项目报告

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

## 8. 写作质量规则

- 术语、符号、单位和缩写前后一致；
- 图表先于文字编号并在正文中引用；
- 定量结论可追溯到数据；
- 参考文献真实存在且支持论点；
- 区分实验、仿真、推断和建议；
- 避免绝对化、宣传化和无证据创新表述；
- 不泄露“根据用户文件拼接”“从大论文摘取”等过程性表达；
- 不为增加篇幅重复同一观点；
- 用户要求可直接替换文本时，提供完整、连贯、可粘贴版本。

## 9. 章节交接

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
