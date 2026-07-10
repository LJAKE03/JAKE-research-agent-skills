---
name: staged-research-planning-and-execution
description: Use after the task contract and initial evidence are available, or whenever a research project is too large to complete safely in one response. It decomposes the work into 3–5 dependent, testable stages; creates one task card at a time; defines inputs, outputs, acceptance criteria, risks, user checkpoints, and the next skill; controls scope and token use; executes only the active work package; and returns a stage handoff to the orchestrator instead of continuing automatically.
---

# 课题拆解、阶段计划与分步执行

## 1. 目标

把“完成一个项目”改造成“连续完成若干可验证工作包”。每个阶段都必须对总目标产生明确贡献，并能独立验收。

## 2. 拆解原则

一个高质量阶段应满足：

- 只回答一个核心问题；
- 有明确输入；
- 有可观察输出；
- 有验收标准；
- 有依赖和停止条件；
- 可在当前轮次内完成；
- 失败时不会推翻全部项目；
- 输出可直接交给下一阶段使用。

## 3. 默认拆成 3–5 个阶段

常见科研项目结构：

1. 任务定义与证据准备；
2. 方法/模型/方案设计；
3. 数据、实验、仿真或分析执行；
4. 结果解释与论证；
5. 论文、报告或最终交付。

不得将“完成全部仿真并写完整论文”作为单一阶段。

## 4. 依赖检查

拆解前检查：

- 研究问题是否明确；
- 关键参数和数据是否存在；
- 外部证据是否足以选择方法；
- 用户是否确认范围和技术路线；
- 当前工具能否执行；
- 是否存在合规、安全或知识产权限制。

若前置条件不满足，返回总控补充，不要强行执行。

## 5. 阶段计划表

```markdown
| WP | 核心问题 | 输入 | 主任务 | 输出 | 验收标准 | 调用 Skill | 用户检查 |
|---|---|---|---|---|---|---|---|
```

每个工作包还需标记：依赖、风险、允许假设、停止条件、对总目标的贡献。

## 6. 单阶段任务卡

一次只激活一个任务卡：

```markdown
# Active Work Package

## 基本信息
- 项目：
- WP 编号：
- 核心问题：
- 本轮边界：

## 输入
- 已确认资料：
- 关键证据：
- 用户决策：
- 允许假设：

## 执行动作
1.
2.
3.

## 输出
- 主交付物：
- 附件：
- 不在本轮完成：

## 验收标准
- [ ]
- [ ]
- [ ]

## 风险与停止条件
- 风险：
- 出现以下情况立即返回总控：
```

## 7. 执行纪律

- 不跨工作包扩展内容。
- 发现新问题先记录，不擅自增加大范围任务。
- 重复信息只引用项目状态，不在每轮完整复述。
- 已确认的资料不重新检索，除非出现冲突或可能过时。
- 优先生成中间成果，如参数表、证据矩阵、模型框架、论点图，而不是直接写最终长文。
- 关键结果尽早暴露给用户，不把问题留到最终阶段。
- 不因输出篇幅长而误判任务完成。

## 8. 失败和改向

遇到以下情况返回总控：

- 关键数据缺失；
- 来源冲突且无法判断；
- 方法与资源不匹配；
- 验收指标无法计算；
- 结果违反基本物理规律；
- 当前工具不能完成必要操作；
- 当前工作包范围明显错误。

返回时说明：已完成到哪里、为什么不能继续、最小补充信息、可替代路线、是否需要用户决定。

## 9. 阶段完成

使用 `../shared/STAGE_HANDOFF.template.md` 生成交接包，并返回总控。禁止自行进入下一工作包。
