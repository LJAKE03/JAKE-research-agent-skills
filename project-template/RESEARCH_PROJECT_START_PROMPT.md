# Research Project Start Prompt

请调用 `$research-project-orchestrator`。

按当前任务需要读取：

1. `AGENTS.md`
2. `PROJECT_STATE.md`（仅在恢复、跨阶段追踪或高影响决策时）
3. `PROJECT_OVERRIDES.md`
4. 若当前项目位于已初始化科研工作区中，读取 `../../RESEARCH_WORKBENCH.md` 和 `../../PROJECT_SOP.md`
5. 只按当前任务标签检索 `../../GLOBAL_LESSONS.md` 的相关经验
6. 当前任务直接相关的项目资料

当前任务：

【填写具体任务】

运行一条统一科研流程：Sol 理解、规划、拆解、选择方法并承担关键判断；需要检索、网页查证、文件扫描或证据表时，向 Terra 发送紧凑证据任务卡；需要成稿时，Sol 先锁定提纲、论点和证据包，再向 Luna 发送锁定写作包。只有真实依赖才形成阶段。Worker 不互相转交，不接收完整历史或全部日志。投稿、关键参数、核心方法和最终科学结论由 Sol 做一次紧凑语义验收。按 `PROACTIVE_INQUIRY_AND_MEMORY_PROTOCOL.md`（由总控从已安装的 `shared` 目录加载）先检查材料、调研权威公开事实，再只询问高影响且必须由用户决定的问题，并说明影响；当前明确指令优先于长期记忆。

项目踩坑、有效方法和工作习惯候选先写入项目复盘。项目收尾时完成 `08_质量门与复盘/PROJECT_RETROSPECTIVE.md`，主动生成 A/B 详细、C/D 简要的候选摘要，并询问用户批准全部、指定编号、拒绝或延后。
未经用户明确批准或用户尚未回复，不得写入个人全局记忆或修改公共 Skill；同一候选集无实质变化时不重复询问。
