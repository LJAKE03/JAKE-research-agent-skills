---
name: staged-research-planning-and-execution
description: Use only when a research task has genuine dependencies that cannot be completed safely as one bounded delivery. Sol creates the smallest useful sequence of work packages, activates one core package at a time, sends compact task cards instead of project history, updates state only when persistence matters, and returns every result to the orchestrator for verification and the next decision.
---

# 真实依赖驱动的阶段计划与执行

<!-- routing-preflight:required -->
执行前确认总控已加载 `../shared/MODEL_ROUTING.json`。本 Skill 只处理阶段依赖，不定义模型模式、能力层或独立 Runtime。

## 1. 何时调用

仅在至少满足一项时调用：

- 后续方法必须等待证据、数据、参数或用户决定；
- 实验、仿真、分析、解释和写作存在不可交换的先后关系；
- 当前结果可能改变后续路线；
- 多个交付物共享关键输入，错误会造成明显返工。

单一输出、一次查证、简单文件修改或已锁定内容的写作不创建阶段计划。

## 2. Sol 的拆解原则

- 只按真实依赖拆分，不设置默认阶段数；
- 每个阶段回答一个核心问题并产生一个可验收主交付物；
- 一次只激活一个核心工作包；
- 独立、只读且输出互不冲突的支持任务才可并行；
- 新证据改变前提时可以合并、重排、取消或重写后续阶段；
- 用户只在范围、路线、关键参数、提纲、核心论点或最终版本等高影响节点确认。

## 3. 最小计划

计划只需记录：

| WP | 核心问题 | 依赖 | 交付物 | 验收条件 | 用户检查点 |
|---|---|---|---|---|---|

只有需要跨轮恢复或审计时才把计划写入 `PROJECT_STATE.md`。不为常规进度维护完整状态。

## 4. 活动任务卡

Sol 向功能 Skill、Terra 或 Luna 发送以下紧凑任务卡：

```text
objective: 当前唯一目标
input_locators: 必要文件、页码、URL、数据表或摘要定位
locked_decisions: 已确认且不得改变的范围、方法、参数、论点或术语
output_contract: 预期表格、字段、草稿或文件
acceptance_checks: 可观察的验收条件
stop_conditions: 缺证据、冲突、越界或高风险时停止
```

不发送完整对话、全部项目状态、全部工具日志或可通过定位读取的原始材料。

## 5. 执行与停止

执行当前任务卡，发现以下情况立即返回总控：

- 关键证据、数据或参数缺失；
- 来源冲突且任务卡未授权裁决；
- 方法与资源不匹配；
- 结果违反基本物理或逻辑常识；
- 当前任务卡边界错误；
- 需要改变研究范围、方法、参数、提纲或核心论点。

返回时说明完成到哪里、阻断原因、最小补充信息和可选下一动作，不自行进入下一工作包。

## 6. 阶段交接

按 `../shared/STAGE_HANDOFF.template.md` 和 `../shared/STAGE_HANDOFF.schema.json` 返回：

- 当前交付物或草稿；
- 结论摘要；
- 证据定位；
- 不确定项；
- 改动文件；
- 返回总控后的唯一建议动作。

总控完成最低充分质量检查后，才决定继续、返工、补证据、改向或请求用户确认。
