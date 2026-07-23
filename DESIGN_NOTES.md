# 设计依据与借鉴说明

本套件采用以下科研工作流与 Skills 设计原则。下列 Agent 资料只用于借鉴工作流交接、验证和人工检查方法，不意味着引入 Agents SDK、独立 Agent Runtime 或面向用户的多 Agent 框架。

1. **单一总控 Skill**
   由一个总控 Skill 维持科研流程和用户接口，按当前阶段调用功能 Skills 与模型，并统一综合结果；不增加独立的中间管理 Agent。

2. **多步骤工作流与显式数据契约**  
   每个阶段定义输入、输出和验收标准，使用统一交接包连接上下游。参考 OpenAI Agent Builder 对 workflow、typed input/output 和 evaluation 的描述。

3. **人工在环和审批节点**  
   对研究范围、技术路线、关键参数和最终结论保留用户审批。参考 OpenAI workspace agents 关于 approval 与 safeguards 的设计。

4. **渐进式披露和按需加载**  
   总控只加载当前需要的 Skill；主 Skill 保持精炼，公共模板放入 shared。参考 Anthropic 官方 skill-creator 对 metadata、SKILL.md 和 bundled resources 三层加载的建议。

5. **先访谈和研究，再执行工作**  
   主动询问边界、输出、成功标准和依赖，同时先使用可用工具查找最佳实践。参考 Anthropic skill-creator 的 Interview and Research 流程。

6. **持续评估与迭代**  
   通过测试案例、质量门和用户检查不断修订，而不是假设第一版已经可靠。参考 OpenAI agent evals 和 Anthropic skill-creator 的 draft—test—review—improve 循环。

参考入口：

- OpenAI, A practical guide to building agents  
  https://openai.com/business/guides-and-resources/a-practical-guide-to-building-ai-agents/
- OpenAI, Agents SDK  
  https://developers.openai.com/api/docs/guides/agents
- OpenAI, Evaluate agent workflows  
  https://developers.openai.com/api/docs/guides/agent-evals
- OpenAI, Introducing workspace agents in ChatGPT  
  https://openai.com/index/introducing-workspace-agents-in-chatgpt/
- Anthropic, Agent Skills repository and skill-creator  
  https://github.com/anthropics/skills

## 统一科研工作流取舍

本套件只保留一条由 Sol 总控的科研流程。功能 Skills 是可按需调用的专业步骤，不再映射为面向用户的模式，也不建立中间 Agent 层或独立 Runtime。

模型分工直接服务于上下文和成本控制：

- Sol 负责需求、拆解、方法、证据综合和关键科研判断；
- Terra 接收紧凑证据任务卡，返回证据表、定位、缺口和摘要；
- Luna 接收锁定写作包，生成文本、语言和格式，不新增科研事实和判断；
- 高影响结论由 Sol 复用已有交接包做一次紧凑验收。

阶段由真实依赖产生，不预设数量。简单任务直接完成；只有后续方法确实依赖证据、数据、参数、实验结果或用户决定时才持久化阶段和项目状态。

## WP5 诊断结论

早期 WP5 A/B 中，候选与基线质量断言通过率相同，候选总耗时、输入 Token 和输出 Token 均未显示改善。由于样本很小且传输重试混杂，这些数字只用于否定“复杂度已经证明有价值”，不用于证明新架构优越。

因此保留精简诊断记录，删除专用 A/B Runtime，并先通过结构测试和人工验收确认统一工作流方向。当前 `VERSION` 保持 `2.1.0`，不发布 `v2.2.0`。
