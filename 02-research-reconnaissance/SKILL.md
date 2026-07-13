---
name: research-reconnaissance-and-pattern-learning
description: Use whenever a research project needs current or niche information, literature, standards, benchmark ranges, comparable projects, established workflows, open-source examples, or evidence about how others solved a similar problem. It must search proactively before asking the user for public facts, prioritize authoritative and primary sources, compare multiple approaches, extract transferable patterns, identify what can be copied conceptually, what must be adapted, and what should be avoided, then return an evidence-backed reconnaissance pack to the orchestrator.
---

# 外部检索、案例学习与证据构建

<!-- routing-preflight:required -->
执行前确认总控已加载 `../shared/MODEL_ROUTING.json`；如未加载，先返回 `../00-research-orchestrator/SKILL.md`，不得直接执行。本 Skill 只引用共享规则，不复制其全文。

## 1. 目标

不仅“找资料”，还要回答：

- 别人如何完成类似任务？
- 哪些步骤已经形成成熟范式？
- 哪些方法可以迁移？
- 哪些条件不同，不能直接照搬？
- 当前项目能够从中得到什么可执行改进？

## 2. 必须联网的情况

- 用户要求搜索、核实、最新信息或文献支撑；
- 信息可能随时间变化；
- 专业事实、参数范围、法规、标准或软件能力存在不确定性；
- 需要判断研究创新性或行业现状；
- 提到不熟悉或可能有歧义的术语；
- 需要查看特定网页、论文、报告、数据集或 GitHub 项目。

## 3. 检索层次

按需要组合，不机械凑数：

1. **官方与标准层**：标准组织、政府、学会、厂商官方文档、软件官方帮助。
2. **综述与框架层**：系统综述、领域综述、方法指南，用于理解分类和主流流程。
3. **原始研究层**：与当前对象、工况、方法最接近的论文和实验研究。
4. **相似案例层**：其他行业或对象中结构相似、问题机制相似的项目。
5. **工程实现层**：开源仓库、技术报告、真实项目工作流、评价指标和失败经验。

## 4. 搜索前定义问题

先写检索问题：

```markdown
- 事实核查问题：
- 方法学习问题：
- 相似案例问题：
- 参数范围问题：
- 创新性问题：
- 风险与失败问题：
```

避免只搜索用户原句。为每个核心概念设计同义词、上位词、下位词和英文关键词。

## 5. 来源优先级

优先：

- 官方标准、官方文档、原始论文、公开数据；
- 高质量综述；
- 可信研究机构或企业技术报告；
- 可复现的开源项目。

谨慎：

- 未署名网页；
- 聚合转载；
- 营销材料；
- 无法追溯原始数据的二手结论；
- 只提供结论而没有方法和条件的内容。

## 6. 学习迁移矩阵

| 案例/来源 | 原任务与条件 | 使用方法 | 成功证据 | 可直接借鉴 | 必须适配 | 不应照搬 | 对本项目建议 |
|---|---|---|---|---|---|---|---|

“借鉴”指学习其结构、方法、评价体系和验证逻辑，不是复制文本、数据或结论。

## 7. 证据标记

所有关键结论标记为：

- **事实**：来源直接支持；
- **综合结论**：多个来源共同支持；
- **推断**：基于来源但非原文结论；
- **建议**：针对当前项目的方案；
- **待验证**：证据不足或条件不匹配。

涉及数值时同时记录：数值、单位、测试条件、适用范围、来源、是否可直接用于当前项目。

## 8. 文档和 PDF

- 对 PDF 中的图、表、流程图和扫描内容，必须查看对应页面图像，不能只依赖文本提取。
- 对论文方法、实验条件和结论要同时核对，禁止脱离工况引用单一数值。
- 对软件帮助文档，优先查官方版本和对应版本号。

## 9. 输出：Research Reconnaissance Pack

```markdown
# Research Reconnaissance Pack

## 检索目标与范围
- 核心问题：
- 时间范围：
- 来源类型：
- 关键词：

## 关键发现
1. 发现：
   - 证据：
   - 适用条件：
   - 对本项目影响：

## 相似项目与成熟工作流
| 项目 | 工作步骤 | 可借鉴部分 | 需要调整部分 | 风险 |
|---|---|---|---|---|

## 方法与方案比较
| 方法 | 优势 | 局限 | 数据/资源要求 | 与当前项目匹配度 |
|---|---|---|---|---|

## 可迁移做法
- 可直接采用：
- 适配后采用：
- 暂不采用：
- 明确避免：

## 证据缺口
- 尚未找到：
- 证据冲突：
- 建议如何补充：

## 对项目拆解的建议
- 推荐阶段：
- 推荐验收指标：
- 建议下一 Skill：
```

## 10. 返回规则

完成证据包后返回总控。不要替总控决定最终技术路线；应给出有证据的推荐和备选项。
