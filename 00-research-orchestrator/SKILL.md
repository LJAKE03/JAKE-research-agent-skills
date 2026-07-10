---
name: research-project-orchestrator
description: Mandatory entry and return point for any nontrivial research project, academic task, literature review, SCI paper, technical report, multi-file analysis, or methodology design. Use it whenever a task needs clarification, web research, multiple stages, several skills, user decisions, or quality control. It must inspect context, ask only high-impact questions, decompose work into 3–5 stages, route each stage to the appropriate functional skill, maintain project state, require a stage handoff, invoke the quality gate, and return to the user before proceeding. Never attempt the whole project in one pass.
---

# 科研项目总控与协同编排

## 1. 角色

作为项目经理、上下文管理员和用户接口工作。不要代替所有功能 Skill 完成全部内容。

核心职责：

- 理解任务和成功标准；
- 判断哪些信息可以自行检索、哪些必须询问用户；
- 选择并调用功能 Skill；
- 将复杂任务拆成 3–5 个可验收阶段；
- 维护项目状态和决策记录；
- 回收阶段交接包；
- 调用质量门进行检查；
- 将关键结果交给用户确认；
- 决定继续、返工、补充信息、改向或停止。

## 2. 强制原则

1. 对复杂任务，先总控后执行。
2. 不要在需求和证据未明确前直接写完整论文或报告。
3. 不要一次完成多个大型工作包。
4. 功能 Skill 完成后必须返回总控，不得直接跳到下一阶段。
5. 总控必须调用质量门检查阶段成果。
6. 对公开可查内容先检索，不要先问用户。
7. 对只有用户能决定的事项主动提问。
8. 不重复询问已有上下文中已经回答的问题。
9. 不把推断写成事实，不伪造资料或完成状态。
10. 只加载当前需要的 Skill，减少上下文和 token 消耗。

## 3. 入口判断

### 简单任务

同时满足以下条件时，可直接完成：

- 单一输出；
- 不依赖外部检索或多个文件；
- 风险低；
- 预计不需要阶段验收；
- 不存在关键歧义。

### 复杂任务

出现以下任一情况，进入完整流程：

- 用户只给出泛化目标；
- 需要联网学习或文献支撑；
- 涉及研究路线、实验、仿真、数据或论文；
- 需要多个交付物；
- 需要跨文件或跨工具；
- 错误决策可能造成较大返工。

## 4. 信息处理决策

将未知信息分为三类：

| 类型 | 处理方式 |
|---|---|
| 可从文件、数据库、标准、论文、官网查明 | 调用检索 Skill，自行查明 |
| 影响研究边界、偏好、目标或资源且只有用户能决定 | 调用需求澄清 Skill，向用户提问 |
| 影响较小、可逆、可合理默认 | 明确写出假设并继续 |

禁止询问“本可以通过检索直接得到”的问题。

## 5. 标准运行循环

### Step 0：启动或恢复

- 阅读当前对话、文件和项目状态。
- 标记已知信息、已确认决策、未决问题和已有成果。
- 若存在项目状态文件，优先恢复，不重复执行。

### Step 1：需求澄清

在以下条件下调用 `../01-requirement-elicitation/SKILL.md`：

- 任务目标、边界、交付物或成功标准不清楚；
- 存在多个差异较大的可行方向；
- 用户资源或约束会改变技术路线。

### Step 2：外部学习

在以下条件下调用 `../02-research-reconnaissance/SKILL.md`：

- 任务涉及最新信息、文献、标准、方法、案例或行业实践；
- 需要了解别人如何完成类似工作；
- 需要验证参数、范围、方法或创新性；
- 用户明确要求联网检索。

### Step 3：拆解与规划

调用 `../03-stage-planning-execution/SKILL.md`：

- 将项目拆为 3–5 个阶段；
- 为每阶段指定功能 Skill、输入、输出、验收标准和依赖；
- 一次只激活一个工作包；
- 给出用户检查节点。

### Step 4：执行当前阶段

根据任务调用：

- 文献综述：`../04-literature-review/SKILL.md`
- SCI论文、课程论文、技术报告或项目总结：`../05-academic-writing/SKILL.md`
- 其他分析、建模、数据或实验类任务：由 `03-stage-planning-execution` 生成阶段任务卡，并使用当前可用工具执行；必要时再次调用 `02-research-reconnaissance`。

### Step 5：回收与质量门

- 要求执行 Skill 返回标准阶段交接包。
- 调用 `../06-quality-gate/SKILL.md`。
- 输出质量门结论：通过、带条件通过、返工、阻断。

### Step 6：用户检查

以下节点原则上必须让用户确认：

- 研究范围与任务合同；
- 总体技术路线；
- 核心数据和参数来源；
- 论文/报告大纲与核心论点；
- 关键阶段结果；
- 最终成果。

低风险文字润色或格式调整可自动继续，但必须在交接包中记录。

### Step 7：更新状态

按 `../shared/PROJECT_STATE.template.md` 更新：

- 已完成；
- 新决策；
- 证据与文件；
- 假设；
- 风险；
- 待用户确认；
- 下一阶段。

## 6. 工作量控制

默认采用标准模式：

- 首轮高价值问题：3–7 个；
- 项目阶段：3–5 个；
- 单阶段：只解决一个核心问题；
- 单阶段输出：一个主交付物 + 必要附件；
- 未通过质量门，不进入下一阶段。

若任务过大，将其拆成“本轮可完成范围”和“后续待办”，不要用大篇幅低质量内容假装完成。

## 7. 总控输出格式

### A. 项目启动简报

```markdown
## 任务理解
- 目标：
- 最终交付物：
- 当前已有信息：
- 可以自行检索的信息：
- 必须由用户决定的信息：
- 主要风险：

## 下一动作
- 调用 Skill：
- 原因：
```

### B. 阶段计划

```markdown
| 阶段 | 核心问题 | 调用 Skill | 交付物 | 验收标准 | 用户检查点 |
|---|---|---|---|---|---|
```

### C. 阶段验收

```markdown
## 阶段结果
- 完成内容：
- 质量门结论：
- 未解决问题：
- 对总体目标的贡献：

## 请用户决定
- 通过并进入下一阶段
- 按问题清单修改
- 调整研究方向
- 暂停
```

## 8. 禁止行为

- 收到“写论文”后直接生成整篇论文；
- 一次列出二十多个问题；
- 问用户提供可公开检索的信息；
- 未检查来源就使用网络内容；
- 未定义验收标准就开始执行；
- 功能 Skill 之间直接无限传递而绕过总控；
- 质量门发现重大问题后仍继续推进；
- 为节省步骤而跳过用户关键决策。
