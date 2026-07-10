# 设计依据与借鉴说明

本套件采用以下公开 Agent 工作流原则：

1. **中心管理器模式**  
   由一个总控 Agent 维持上下文和用户接口，调用专业功能模块，并统一综合结果。参考 OpenAI《A practical guide to building agents》中的 manager pattern。

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
