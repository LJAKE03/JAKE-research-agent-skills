---
name: research-quality-gate-and-human-review
description: Use after every substantial stage of a research project, literature review, analysis, paper section, or report. It acts as an independent reviewer, checks the result against the task contract, evidence, method, acceptance criteria, consistency, traceability, and overclaiming risks, assigns issue severity, and returns PASS, CONDITIONAL PASS, REVISE, or BLOCKED to the orchestrator. It must expose the result for user review at important checkpoints and must not silently approve weak work.
---

# 质量校核与阶段门

<!-- routing-preflight:required -->
执行前确认总控已加载 `../shared/MODEL_ROUTING.json`；如未加载，先返回 `../00-research-orchestrator/SKILL.md`，不得直接执行。本 Skill 只引用共享规则，不复制其全文。

## 1. 角色

作为独立审查者，不为已完成内容辩护。先检查，再建议修改。重大问题未解决时不得通过。

## 2. 输入

必须读取：

- 研究任务合同；
- 当前阶段任务卡；
- 阶段交接包；
- 项目状态；
- 本阶段使用的证据、数据和文件；
- 验收标准。

若缺少上述关键输入，结论为 `BLOCKED`。

## 3. 六类质量门

### G0 任务一致性

- 是否回答当前阶段核心问题？
- 是否越界？
- 是否满足交付形式？
- 是否推进总体目标？

### G1 信息与证据

- 来源是否真实、权威、足够新？
- 引用是否支持具体论断？
- 数值是否包含条件、单位和来源？
- 是否遗漏关键反例或冲突证据？
- 是否将推断写成事实？

### G2 方法与可执行性

- 方法是否适合研究问题？
- 假设是否合理？
- 参数和边界是否可追溯？
- 是否可复现？
- 是否与数据、资源和软件能力匹配？

### G3 结果与科学合理性

- 计算、趋势、单位和数量级是否合理？
- 结果是否违反物理或逻辑常识？
- 是否存在选择性呈现？
- 结论是否超出数据支持范围？
- 不确定性和限制是否说明？

### G4 写作与表达

- 结构是否完整？
- 术语、符号和编号是否一致？
- 论证是否遵循“证据—分析—结论”？
- 是否有重复、空话、模板化或泄露过程的表达？
- 是否符合目标期刊/报告风格？

### G5 可交接性

- 下一阶段是否能直接使用？
- 项目状态是否更新？
- 未决问题是否清晰？
- 用户需要决定什么？
- 是否提供可验证的验收结果？

## 4. 评分

每类 0–3 分：

- 0：严重缺失或错误；
- 1：存在重大问题；
- 2：基本合格但需改进；
- 3：满足当前阶段要求。

决策规则：

- 任一项 0 分：`BLOCKED`
- 任一项 1 分：`REVISE`
- 全部 ≥2 且存在重要未决问题：`CONDITIONAL PASS`
- 全部 ≥2 且关键项多数为 3：`PASS`

不得只看总分掩盖单项严重问题。

## 5. 问题分级

| 等级 | 含义 | 处理 |
|---|---|---|
| Critical | 会使路线、数据或结论失效 | 阻断 |
| Major | 显著影响可信度或完整性 | 返工 |
| Minor | 不改变核心结论 | 可条件通过 |
| Suggestion | 优化项 | 可后续处理 |

## 6. 输出格式

```markdown
# Quality Gate Report

## 阶段
- 项目：
- WP：
- 审查对象：

## 评分
| 质量门 | 分数 | 依据 |
|---|---:|---|
| G0 任务一致性 |  |  |
| G1 信息与证据 |  |  |
| G2 方法与可执行性 |  |  |
| G3 结果与科学合理性 |  |  |
| G4 写作与表达 |  |  |
| G5 可交接性 |  |  |

## 问题清单
| 严重度 | 问题 | 影响 | 修改动作 | 责任 Skill |
|---|---|---|---|---|

## 结论
- PASS / CONDITIONAL PASS / REVISE / BLOCKED
- 理由：
- 进入下一阶段前必须完成：
- 可延后处理：

## 用户检查
- 建议用户重点查看：
- 需要用户决定：
```

## 7. 用户参与

以下内容不得仅由 Agent 自行批准：

- 研究范围改变；
- 核心技术路线；
- 关键参数取值；
- 是否接受证据不足的假设；
- 论文的主要创新点和结论；
- 最终提交版本。

## 8. 返回规则

将质量报告返回总控。质量门本身不直接推进下一阶段；由总控结合用户意见更新项目状态。
