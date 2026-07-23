---
name: research-project-orchestrator
description: Mandatory entry and return point for any nontrivial research project, academic task, literature review, SCI paper, technical report, multi-file analysis, or methodology design. Use it to run one unified research workflow, automatically choose the necessary functional Skills and Sol/Terra/Luna responsibilities, pass only compact task cards and handoff packages, invoke proportionate quality checks, and return high-impact decisions to the user. Users never choose a workflow mode, model, or Agent.
---

# 科研项目总控与统一工作流

<!-- routing-preflight:required -->
开始科研任务前读取 `../shared/MODEL_ROUTING.json`。它只定义 Sol、Terra、Luna 的真实模型映射和委派边界，不定义面向用户的工作模式。

## 1. 核心目标

维持一条连续科研流程，并根据当前工作的性质自动调用功能 Skill 和模型层：

1. Sol 理解需求、确定边界、选择方法、拆解真实依赖并承担科研判断；
2. Terra 在收到有界证据任务卡后完成检索、查证、扫描、提取和证据表整理；
3. Sol 综合证据，锁定论点、方法、提纲和允许写入的事实；
4. Luna 只根据锁定写作包生成文本、格式和语言版本；
5. 投稿、关键参数、核心方法和最终科学结论由 Sol 做一次紧凑语义验收，不重新写全文。

用户不需要选择模型、Agent 或工作模式。是否检索、是否分阶段、是否委派以及质量检查强度都由总控根据任务自动判断。

## 2. 不可委派的 Sol 责任

以下内容始终由 Sol 决定并承担最终责任：

- 需求理解、范围和成功标准；
- 总体计划、任务拆解和方法选择；
- 研究方向、创新性、参数、边界条件和实验/仿真方案；
- 来源可靠性裁决、证据综合、异常诊断和关键结果解释；
- 论点结构、提纲锁定和最终科学结论；
- 高影响用户检查点与最终答复。

Terra 和 Luna 可以指出缺口、冲突和不确定性，但不得替 Sol 做这些判断。

## 3. 启动与恢复

1. 读取当前请求和直接相关文件；仅在任务需要恢复、跨阶段追踪或高影响决策时读取 `PROJECT_STATE.md`。
2. 复用已经确认的范围、数据、证据和决定，不重复询问或重新检索。
3. 只询问 0–2 个真正会改变范围、路线或交付物且无法自行查明的问题。
4. 低影响、可逆假设可以明确记录后继续；不可把推断写成事实。

简单、低风险且无需外部证据的请求可以由 Sol 直接完成，不制造阶段、任务卡或项目状态。进入总控不等于启动复杂治理。

## 4. 功能 Skill 自动选择

根据当前问题直接选择最少的功能 Skill，不增加中间能力层或常驻 Agent：

| 当前需要 | 调用 Skill | 主要模型责任 |
|---|---|---|
| 范围、目标、约束或交付物存在高影响歧义 | `../01-requirement-elicitation/SKILL.md` | Sol 主导，用户只回答其独有信息 |
| 最新资料、论文、标准、网页、文件或数据查证 | `../02-research-reconnaissance/SKILL.md` | Terra 搜集整理，Sol 判断 |
| 存在真实依赖的多阶段方法、实验、仿真或分析 | `../03-stage-planning-execution/SKILL.md` | Sol 拆解和裁决 |
| 文献综述、研究现状或证据综合 | `../04-literature-review/SKILL.md` | Terra 建证据底座，Sol 综合 |
| 论文、报告、提案或研究文本 | `../05-academic-writing/SKILL.md` | Sol 锁定写作包，Luna 起草 |
| 阶段验收、投稿、关键参数或最终结论 | `../06-quality-gate/SKILL.md` | 工具/Terra 核验，Sol 语义验收 |

功能 Skill 完成后必须返回总控。Worker 不得互相转交或递归委派。

## 5. 何时形成阶段

只有存在不可并成一次交付的真实依赖时才调用 `03-stage-planning-execution`，例如：

- 后续方法必须等待证据或数据确认；
- 实验、仿真、分析和写作存在明确先后关系；
- 一个阶段失败会改变下一阶段路线；
- 需要用户确认研究范围、方法、关键参数、提纲或核心结论。

阶段数量由依赖决定，不设置默认数量。一次只激活一个核心工作包；独立、只读且输出互不冲突的支持任务才可并行。

## 6. 紧凑任务卡与交接

需要委派时，只发送当前 Worker 完成任务所需的信息：

```text
objective: 当前唯一目标
input_locators: 相关文件、页面、URL、数据表或已锁定摘要的位置
locked_decisions: 不得改变的范围、方法、论点或术语
output_contract: 返回字段、表格或文本结构
acceptance_checks: 可观察验收条件
stop_conditions: 证据不足、冲突或越界时何时停止
```

不得传递完整对话、全部项目历史、全部工具日志或整篇论文原文。详细规则见 `../shared/STAGE_HANDOFF.template.md`，返回结构遵循 `../shared/STAGE_HANDOFF.schema.json`。

### Terra 证据包

Terra 只返回：

- 证据表或提取结果；
- 来源定位和必要元数据；
- 可直接观察到的事实摘要；
- 冲突、缺口和不确定项；
- 建议 Sol 决定的下一动作。

### Luna 写作包

Sol 交给 Luna 的输入必须已经锁定：

- 目标章节或交付物；
- 提纲和论点顺序；
- 可使用的事实、数据、公式和引用编号；
- 风格、语言、长度和格式；
- 禁止新增的主张及占位符规则。

Luna 可以组织语言和生成完整草稿，但不得新增事实、引用、数值、公式、因果关系或科研判断。

## 7. 质量检查

质量强度是内部决策，不向用户暴露成工作模式：

- L0：语法、Schema、哈希、文件、单位、格式和确定性测试；
- L1：Terra 对来源定位、字段完整性、证据覆盖、遗漏和冲突做只读核验；
- L2：Sol 对来源可靠性、方法、参数、解释、过度推断和科学结论做语义验收。

投稿/申报、安全或高成本决策、关键参数、核心方法和最终科学结论必须执行 L2。L2 复用已有 L0/L1 摘要和定位，不重新加载全部原始材料，也不重写全文。

## 8. 用户检查点

以下高影响事项原则上交用户确认：

- 研究范围和最终交付物；
- 总体技术路线与资源约束；
- 核心数据、参数和证据不足的假设；
- 论文/报告提纲与核心论点；
- 最终提交版本。

低风险、可逆工作在验证后可以连续推进，直到出现高影响决策、证据不足或不可逆操作。

## 9. Token、成本与时间纪律

- 优先降低 Sol token 和总成本，而不是机械追求原始 token 最少；
- Sol 只向 Terra 发送紧凑证据任务卡；Terra 只回证据表、定位和摘要；
- Sol 只向 Luna 发送锁定写作包；Luna 不接收完整研究历史；
- 不为每个小动作重复规划、状态更新或质量报告；
- 大型结果写入文件，对话只显示结论、定位、未决项和下一动作；
- 评价路由时同时记录 Sol token、总成本、有效交付时间和科研质量。

## 10. 工具纪律

按最少交互、最小输出、最低失败率和最易验证选择工具：优先 Codex 内置读取、搜索和精确补丁，其次 `rg`、`git` 和已有验证脚本，再按任务选择 PowerShell 或 Python。

- Windows 启动器、环境变量、注册表、系统路径和简单 Windows 文件操作优先 PowerShell；
- CSV/JSON/Excel、数值计算、数据清洗、绘图和可复用批处理优先 Python；
- 搜索使用 `rg`/`rg --files`，版本检查使用 `git diff`；
- Windows PowerShell 读取仓库文本显式使用 `Get-Content -Encoding UTF8`；
- 修改后先跑最小相关测试，再跑全量静态自检；
- 连续两次同类失败后改变诊断方法；
- Large results must be written to files.

## 11. 禁止行为

- 要求用户选择模型、Agent 或工作模式；
- 为功能分类再增加一层 Agent、Reviewer Agent 或独立 Runtime；
- 把完整对话、全部日志或整篇原文复制给 Worker；
- 让 Terra 决定来源可靠性、研究路线或最终结论；
- 让 Luna 在未锁定论点和证据时自由生成科研内容；
- 对同一交付物重复启动计划和审查；
- 质量门发现重大问题后仍继续推进。
