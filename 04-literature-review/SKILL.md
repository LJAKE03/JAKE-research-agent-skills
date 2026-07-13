---
name: literature-review-and-evidence-synthesis
description: Use for literature reviews, research-status sections, evidence maps, state-of-the-art analyses, review papers, or the literature component of an SCI paper or project. It combines systematic searching with thematic synthesis, builds a traceable literature matrix, distinguishes established findings from disagreement and gaps, learns from comparable review structures, and produces staged outputs rather than immediately drafting a long review. It must return to the orchestrator for evidence and quality checks.
---

# 文献综述与研究现状综合

<!-- routing-preflight:required -->
执行前确认总控已加载 `../shared/MODEL_ROUTING.json`；如未加载，先返回 `../00-research-orchestrator/SKILL.md`，不得直接执行。本 Skill 只引用共享规则，不复制其全文。

## 1. 目标

形成“可追溯证据库 + 主题综合 + 研究缺口 + 可用于后续研究的结论”，而不是逐篇罗列摘要。

## 2. 开始条件

优先确认：

- 综述问题；
- 研究对象和边界；
- 时间范围；
- 文献类型；
- 语言和数据库；
- 最终用途；
- 是否要求系统综述规范。

信息不足时返回总控调用需求澄清。

## 3. 综述类型

### 叙述性综述

适合课程论文、SCI 引言、项目背景。强调主题逻辑和代表性文献。

### 范围综述

适合领域分类、方法谱系、研究空白和术语梳理。需明确检索范围与筛选原则。

### 系统综述

只有实际执行可复核检索、筛选、纳排和质量评价时，才能使用“系统综述”表述。不得仅因文献较多而宣称符合 PRISMA 或其他规范。

## 4. 分阶段完成

### WP-A：问题和检索策略

输出：综述问题、概念框架、数据库和关键词、纳入/排除标准、时间与语言范围。

### WP-B：证据矩阵

| 文献 | 对象/工况 | 方法 | 数据 | 核心结果 | 局限 | 与本研究关系 | 可信度 |
|---|---|---|---|---|---|---|---|

### WP-C：主题综合

按以下维度组织，而不是按作者顺序：

- 研究对象；
- 方法路线；
- 机理解释；
- 工况/数据；
- 评价指标；
- 共识；
- 分歧；
- 局限；
- 演化趋势。

### WP-D：研究缺口和借鉴

将“缺口”写成可研究的问题：

- 哪个对象尚未研究；
- 哪种条件尚未覆盖；
- 哪个机理尚不明确；
- 哪个方法尚未验证；
- 哪种工程约束尚未解决。

### WP-E：综述文本

证据矩阵和缺口经质量门通过后，再写正式文本。

## 5. SCI 引言模式

默认采用连续四段式：

1. **背景与重要性**：问题为何重要；
2. **研究进展与缺口**：已有研究做了什么，哪里不足；
3. **研究目标与假设/问题**：本文准备解决什么；
4. **研究意义与贡献**：方法和工程价值。

要求：

- 文献按首次出现顺序编号；
- 同一论点不堆砌过多文献；
- 同类文献较多时分组说明差异；
- 引用必须能支持相邻论断；
- 不用“鲜有研究”“首次”等绝对表述，除非检索充分。

## 6. 综合写作逻辑

每个主题至少包含：

```text
现有共识
→ 代表性证据
→ 方法或条件差异
→ 尚存分歧/局限
→ 对本研究的启发
```

禁止：

- 只改写摘要；
- 以文献数量代替分析；
- 将不同工况数值直接横向比较；
- 把综述论文的二手结论当作原始数据；
- 引用与论点不匹配；
- 编造 DOI、卷期、页码或题名。

## 7. 输出

```markdown
# Literature Review Pack

## 综述问题与边界
## 检索与筛选方法
## 文献矩阵
## 主题综合
## 共识与争议
## 研究缺口
## 可借鉴的方法和评价体系
## 对当前项目的建议
## 待补文献
## 建议下一 Skill
```

随后生成阶段交接包并返回总控。
