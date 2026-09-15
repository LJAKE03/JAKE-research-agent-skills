# 科研 Skills 模型与工具路由

## 配置来源

- `shared/MODEL_ROUTING.json` 保存公共默认值、安全边界、Agent 类型和降级状态。
- 项目级 `.research-agent/MODEL_ROUTING.selection.json` 只覆盖三个角色的模型与 reasoning。
- 默认配置：战略总控 `gpt-5.6-sol/xhigh`、`research_support` 为 `gpt-5.6-terra/medium`、`research_output` 为 `gpt-5.6-luna/low`。
- 战略总控可选 `gpt-6-astra` 或 `gpt-5.6-sol`；两个 Worker 可选 Sol、Terra 或 Luna。允许多个角色使用同一模型。
- 选择对新任务生效。已经运行的主线程不会因项目文件变化而动态换模型。
- `codex debug models` 校验当前模型与 reasoning 是否可用；战略总控不可用时阻断，Worker 不可用时转为 `degraded_strategic_only`。

## 三个角色

| 角色 | 责任 | 边界 |
|---|---|---|
| `strategic` | 需求、规划、方法、证据综合、关键科研判断和最终验收 | 不把最终科研责任委派出去 |
| `research_support` | 有界检索、网页查证、文件扫描、提取和证据表 | 不决定研究路线、参数、来源可靠性或最终结论 |
| `research_output` | 根据锁定输出包组织文本、表格、语言和格式规格 | 不新增事实、引用、公式、计算、分类、优先级或科研判断 |

## 委派原则

- 只有任务可独立分离、输入边界清楚，且收益超过调用与交接开销时才委派。短小查证、局部改写和紧邻当前判断的工作由战略总控直接完成。
- 优先使用 `agent_type=research_support` 或 `agent_type=research_output`；工具不支持 Agent 类型时，使用项目已解析的显式 model 与 reasoning。
- 若 spawn 无法锁定模型，可使用一次性只读 `codex exec`；只传紧凑任务卡，完成即退出。
- 三种调用形态都不可用或目标模型不可用时，标记 `runtime_dispatch.failure_status`，由战略总控完成当前有界任务并透明说明。
- Worker 不递归创建 Worker，也不互相转交。战略总控读取结果、解决冲突并负责最终答复。
- 并行只用于输入只读或互不重叠、输出已分区的独立任务。

## 紧凑上下文

- 战略总控 → `research_support`：目标、定位、锁定决定、输出结构、验收和停止条件。
- `research_support` → 战略总控：证据表、来源定位、事实摘要、冲突和缺口。
- 战略总控 → `research_output`：单一交付物、锁定内容、证据编号、风格、长度、格式、禁止新增项和确定性验收条件。
- `research_output` → 战略总控：草稿、占位符、不确定项和下一动作。
- 不复制完整对话、全部项目历史、全部工具日志或整篇论文原文。

## 质量检查

- L0：确定性工具检查。
- L1：只读核对来源定位、字段和证据覆盖。
- L2：战略总控裁决来源可靠性、方法、参数、解释和最终科学结论。

检查范围与风险相称。修改后先运行最小相关测试；只有共享契约、生成链或发布边界变化时才扩大检查范围。
