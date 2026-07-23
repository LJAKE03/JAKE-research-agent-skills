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

- L1 复用 L0 结果；L2 复用 L0/L1 的摘要和定位；
- 不重复粘贴原始材料，不重新加载完整项目历史；
- Luna 草稿验收只读取锁定写作包、草稿、问题定位和必要证据；
- Sol 只做一次紧凑语义验收，不为验收重新写全文；
- 不新增独立 Reviewer Agent。

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

## 4. 决策

- `PASS`：满足当前层级，关键项没有未决问题；
- `CONDITIONAL PASS`：可以继续，但存在不改变当前路线的明确小问题；
- `REVISE`：存在会显著影响可信度、完整性或可用性的重大问题；
- `BLOCKED`：缺少必要输入，或存在使方法、数据或结论失效的问题。

不得用总分掩盖单项严重问题。

## 5. 紧凑输出

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
