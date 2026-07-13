---
name: research-requirement-elicitation
description: Use when a research task, project, paper, review, report, experiment, simulation, or analysis has unclear objectives, scope, constraints, inputs, deliverables, or success criteria. It must first inspect existing context and research what can be discovered independently, then ask a compact batch of only high-impact questions that the user is uniquely positioned to answer. It returns a Research Task Contract to the orchestrator and must not begin the full project itself.
---

# 需求澄清与关键信息索取

<!-- routing-preflight:required -->
执行前确认总控已加载 `../shared/MODEL_ROUTING.json`；如未加载，先返回 `../00-research-orchestrator/SKILL.md`，不得直接执行。本 Skill 只引用共享规则，不复制其全文。

## 1. 目标

通过少量、高价值问题消除会显著影响研究质量的歧义。不要把需求访谈变成问卷轰炸。

## 2. 先查后问

提问前依次检查：

1. 当前对话和长期上下文；
2. 用户已上传文件；
3. 已有项目状态；
4. 可通过互联网、数据库、标准或论文直接查明的信息。

只询问以下内容：

- 只有用户知道；
- 用户必须做价值判断；
- 不同答案会改变研究路线或交付物；
- 错误假设会造成明显返工。

## 3. 问题分级

| 等级 | 定义 | 是否询问 |
|---|---|---|
| 阻断性 | 不回答就无法选择正确路线 | 必须问 |
| 高影响 | 会显著影响范围、方法或质量 | 应问 |
| 可优化 | 有助于个性化但不影响主路线 | 最多问 1–2 个 |
| 可检索 | 可从资料或网络查明 | 不问，自己查 |
| 低影响 | 可采用合理默认且易修改 | 不问，声明假设 |

## 4. 提问规则

- 默认一次提出 3–7 个问题。
- 将问题按“目标—对象—数据—方法—交付”排序。
- 尽量给出选项、推荐默认值和影响说明。
- 不重复询问已经回答的问题。
- 用户只回答部分问题时，基于已有信息继续，并列出假设。
- 不为了形式而提问。
- 不在一个问题中混入多个互不相关的决定。

## 5. 常用问题池

### 研究目标

- 最终要解决的科学问题或工程问题是什么？
- 预期成果是探索机制、比较方案、建立模型、优化控制，还是形成工程规范？
- 成功标准是什么：准确率、误差、效率、压降、响应时间、论文录用或项目验收？

### 研究边界

- 研究对象和系统边界是什么？
- 哪些变量可控，哪些是扰动，哪些必须保持不变？
- 哪些内容明确不做？

### 数据与资源

- 已有实验、仿真、文献或代码有哪些？
- 数据规模、采样条件、格式和质量如何？
- 可用软件、实验条件、时间和计算资源有哪些限制？

### 学术输出

- 目标是 SCI 小论文、综述、课程论文、技术报告还是项目总结？
- 目标期刊、模板、字数、语言、截止日期和引用格式是什么？
- 是否允许提出超出当前证据范围的后续研究方案？

### 决策偏好

- 更强调创新性、工程可实施性、完成速度还是证据严谨性？
- 用户希望每阶段确认，还是只确认关键节点？

## 6. 输出：研究任务合同

完成提问后，返回总控：

```markdown
# Research Task Contract

## 任务目标
- 核心问题：
- 应用场景：
- 最终交付物：
- 成功标准：

## 范围
- 包含：
- 不包含：
- 关键变量：
- 约束：

## 已有资源
- 文件：
- 数据：
- 模型/代码：
- 可用工具：

## 用户决策
- 已确认：
- 尚未确认：

## 允许的假设
- 假设：
- 影响：
- 后续验证方式：

## 推荐运行模式
- 快速 / 标准 / 严格
- 理由：

## 建议下一 Skill
- Skill：
- 原因：
```

## 7. 返回规则

生成任务合同后立即返回总控。不得直接写完整论文、完成全部检索或自行推进后续阶段。
