---
name: research-quality-gate-and-human-review
description: Use after a substantial research stage and whenever publication, key parameters, core methods, safety, high-cost decisions, or final scientific conclusions need acceptance. Apply only the lowest sufficient deterministic, provenance, or Sol semantic check; reuse compact handoffs and source locators; return PASS, CONDITIONAL PASS, REVISE, or BLOCKED without creating a separate Reviewer Agent or rewriting the full deliverable.
---

# 科研质量校核与紧凑验收

<!-- routing-preflight:required -->
执行前确认总控已加载 `../shared/MODEL_ROUTING.json`。质量强度由当前风险自动决定，不形成面向用户的工作模式，也不依赖独立 Runtime。

## 1. 最低充分检查

### L0：确定性检查

适用于格式、语法、Schema、哈希、文件存在性、单位、编号和可重复脚本测试。优先使用工具，不调用 Worker。

### L1：证据完整性检查

由 Terra 或等价只读检查核对：

- 来源定位和元数据；
- 字段、论断和引用覆盖；
- 数值的条件、单位和来源；
- 遗漏、冲突和不确定项。

L1 不裁决来源真实性、权威性、新颖性、方法适用性或科学结论。

### L2：Sol 语义验收

由 Sol 裁决：

- 来源是否真实、权威、可靠且足以支撑论断；
- 方法、参数、边界和解释是否合理；
- 结论是否超出证据，是否遗漏反例或不确定性；
- 写作是否忠实于锁定提纲和证据包。

投稿/申报、安全或高成本决策、关键参数、核心方法和最终科学结论必须使用 L2。

## 2. 上下文纪律

- 涉及大材料或跨阶段验收时遵循 `../shared/CONTEXT_EFFICIENCY_PROTOCOL.md`，先检查上下文账本、新鲜度和恢复定位；
- L1 复用 L0 结果；L2 复用 L0/L1 的摘要和定位；
- 不重复粘贴原始材料，不重新加载完整项目历史；
- Luna 草稿验收只读取锁定写作包、草稿、问题定位和必要证据；
- Sol 只做一次紧凑语义验收，不为验收重新写全文；
- 不新增独立 Reviewer Agent。

公式、单位、数值、工况、参数、异常和支撑最终结论的实现属于科研无损区；缺少精确条件或来源定位时不得用摘要替代验证。

缺少当前检查所必需的输入时返回 `BLOCKED`，说明最小缺口。

## 3. 六类检查

| 质量门 | 核心问题 |
|---|---|
| G0 任务一致性 | 是否回答当前目标、遵守边界并形成可用交付物 |
| G1 信息与证据 | 来源、条件、单位、覆盖和不确定性是否可追溯 |
| G2 方法与执行 | 方法、假设、参数、边界、资源和复现性是否匹配 |
| G3 结果与科学性 | 趋势、数量级、因果、异常和结论边界是否合理 |
| G4 写作与表达 | 是否忠实于锁定论点，术语、结构、图表和引用是否一致 |
| G5 可交接性 | 下一动作、未决项、文件和用户决定是否清楚 |

## 4. 投稿级论断追溯预检

对期刊论文、会议论文、正式投稿材料，以及包含创新性或最终科学结论的成果，读取项目中的 `PUBLICATION_CLAIM_TRACEABILITY.md`；没有项目副本时以 `../shared/PUBLICATION_CLAIM_TRACEABILITY.template.md` 为结构依据。普通内部报告不强制执行。

按最低充分层级核对：

1. 核心命题、贡献声明、所需 / 已有 / 缺失证据、允许声明和禁止外推已经锁定；需要用户决定的高影响边界已有确认记录；
2. 每个主要 Results 单元至少映射一项贡献和一个可恢复的证据定位，并保留工况、样本、单位、不确定性及支持程度；
3. Abstract、Introduction、Results、Discussion 和 Conclusion 的声明强度没有越过合同边界；
4. 已有 L1/L2 发现被整理为创新性、重要性、方法、证据、表达和期刊匹配风险；不为填表重复启动审稿；
5. 任何 CRITICAL 或 MAJOR 异议在宣布可投稿前已解决，或有用户明确接受且不损害科学有效性的依据；
6. 合同变化已经标记受影响产物和重新验证起点，没有无理由重跑完整流程。

核心命题尚待用户决定时返回 `BLOCKED`；结果没有贡献映射、证据条件缺失、声明越界或重大异议未关闭时返回 `REVISE`。否定结果和不支持贡献的证据必须保留，并用于收缩或撤回声明，不能删除或改写成支持。

## 5. 决策

- `PASS`：满足当前层级，关键项没有未决问题；
- `CONDITIONAL PASS`：可以继续，但存在不改变当前路线的明确小问题；
- `REVISE`：存在会显著影响可信度、完整性或可用性的重大问题；
- `BLOCKED`：缺少必要输入，或存在使方法、数据或结论失效的问题。

不得用总分掩盖单项严重问题。

无论输出是否采用完整模板，都必须逐字包含一个且仅一个标准结论词：`PASS`、`CONDITIONAL PASS`、`REVISE` 或 `BLOCKED`；仅表达“暂停”“拒收”或“修复后再继续”不满足机器验收。

## 6. 紧凑输出

```markdown
## Quality Gate
- 对象：
- 检查层级：L0 / L1 / L2
- 结论：PASS / CONDITIONAL PASS / REVISE / BLOCKED
- 关键依据：
- 必须修改：
- 可延后：
- 用户需要决定：
```

仅在用户需要审阅复杂问题时展开六类评分表；常规通过只返回摘要和定位。
