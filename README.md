# 科研 Agent Skills 协同套件 v2.1

本套件不是若干彼此独立的提示词，而是一套由**总控 Skill 统一编排、功能 Skill 分阶段执行、质量门 Skill 回收验收**的科研工作系统。

## 一、核心架构

```mermaid
flowchart TD
    U[用户提出科研任务] --> O[00 总控编排]
    O --> I[01 需求澄清与关键信息索取]
    I --> O
    O --> R[02 外部检索、案例学习与证据构建]
    R --> O
    O --> P[03 课题拆解、阶段计划与分步执行]
    P --> O
    O --> L[04 文献综述与研究现状综合]
    L --> O
    O --> W[05 SCI论文与技术报告写作]
    W --> O
    O --> Q[06 质量校核与阶段门]
    Q --> H{高影响检查点?}
    H -->|否，连续执行| O
    H -->|是| D{用户检查/决策}
    D -->|通过| O
    D -->|修改| O
    D -->|暂停或改向| O
```

总控 Skill 是唯一默认入口和阶段返回点。功能 Skill 不自行把项目推进到底，每完成一个阶段都必须提交统一的“阶段交接包”，再由总控调用质量门进行检查。

## 二、目录说明

| 目录 | 功能 |
|---|---|
| `00-research-orchestrator` | 接收任务、管理状态、拆解分工、调用其他 Skill、组织用户验收 |
| `01-requirement-elicitation` | 主动提问、索要关键信息、减少错误假设 |
| `02-research-reconnaissance` | 联网检索、学习相似项目、建立证据链、提炼可迁移做法 |
| `03-stage-planning-execution` | 根据任务复杂度和风险动态拆分阶段，并控制一次只完成一个可验收工作包 |
| `04-literature-review` | 文献检索策略、文献矩阵、主题综合、研究缺口与综述写作 |
| `05-academic-writing` | SCI 小论文、课程论文、技术报告、项目总结等成果写作 |
| `06-quality-gate` | 独立审查、阶段评分、问题分级、通过/返工/阻断决策 |
| `shared` | 项目状态、交接包、质量标准、路由案例等公共模板 |
| `evals` | 用于测试整套 Skill 是否按预期触发和协同的案例 |

## 三、推荐用法

### 1. 新任务必须从总控开始

可直接输入：

> 调用科研项目总控 Skill。我要完成【任务】。先检查已有信息、主动检索能够自行查明的内容，只询问真正阻断执行的关键信息；随后按复杂度、风险、交付物和验证需求动态拆分并执行。低风险、可逆工作通过所需质量门后连续推进，直到高影响决策、证据不足或不可逆操作前再让我确认。

### 2. 默认运行模式

- **平衡快速模式（默认）**：先判断风险，首轮只问 0–2 个阻断问题；低风险工作包可连续执行，到高影响决策、证据不足或不可逆操作前再请用户确认。
- **简单任务快车道**：单一、低风险、无需外部证据的任务直接完成，不创建多余阶段或完整项目状态。
- **严格模式**：建立完整检索记录、证据矩阵和 L2 科学质量门；适用于 SCI 投稿、项目申报、安全、高成本决策和最终科研结论。

### 3. 中断后恢复

把 `shared/PROJECT_STATE.template.md` 的最新内容交给总控，并说明：

> 根据该项目状态恢复任务。先核对已完成内容和未决问题，不要重复已完成工作。

## 四、协同原则

1. **能检索的不问用户**：公开事实、标准、论文方法和相似案例先自行搜索。
2. **必须由用户决定的才提问**：研究边界、目标期刊、核心偏好、是否采用某项技术路线。
3. **不一口气完成大任务**：一次只处理一个有明确输入、输出和验收标准的工作包。
4. **证据与推断分开**：明确区分资料事实、模型推断、工程建议和用户决策。
5. **每阶段必须回总控**：功能 Skill 不得自行跨越质量门。
6. **按需加载**：总控只加载当前需要的 Skill 和参考文件，避免反复灌入完整上下文。
7. **形成可追溯状态**：重要决策、参数来源、假设、版本和待办必须写入项目状态。
8. **不伪造**：不得编造文献、参数、数据、仿真结果、标准条款或已完成的操作。

## 五、推荐安装结构

```text
research-agent-skills/
├── AGENTS.md
├── README.md
├── SKILL.md
├── 00-research-orchestrator/SKILL.md
├── 01-requirement-elicitation/SKILL.md
├── 02-research-reconnaissance/SKILL.md
├── 03-stage-planning-execution/SKILL.md
├── 04-literature-review/SKILL.md
├── 05-academic-writing/SKILL.md
├── 06-quality-gate/SKILL.md
├── shared/
│   ├── PROJECT_STATE.template.md
│   ├── STAGE_HANDOFF.template.md
│   ├── QUALITY_RUBRIC.md
│   └── ROUTING_EXAMPLES.md
└── evals/evals.json
```

## 六、版本说明

v2.0 建立了“1 个总控 + 6 个功能 Skill”、阶段交接、项目状态和质量门架构；v2.1 重点更新：

- 路由冲突和 Sol/模型目录不可验证均 fail-closed；仅 `ready`，或 Sol 已验证且明确为 `degraded_sol_only`，并且无冲突、快照哈希一致时才能启动。
- `shared/MODEL_ROUTING.json` 成为唯一配置源；项目模板仅保留字节一致的生成快照。
- 默认采用平衡快速模式和 L0/L1/L2 分层质量门，减少低风险任务的重复上下文。
- 修复复制模式同步和 ZIP 备份的通配符问题，并增加实际文件内容、降级和阻断回归测试。
## 应用版模型与工具路由

Windows 版 ChatGPT 桌面应用是本项目的主要入口。项目用 `.codex/config.toml` 限制子代理并发/深度，并用 `.codex/agents/research-support.toml` 与 `.codex/agents/research-output.toml` 定义支持和低风险输出代理。`shared/MODEL_ROUTING.json` 是唯一 canonical 配置源，项目模板快照必须与它字节一致；实际模型映射、回退条件、工具边界和自检命令见 `shared/MODEL_ROUTING.md`。CMD/PowerShell 启动器负责 canonical、快照哈希和本地模型目录预检；实际任务分派仍由应用版项目级路由执行。

## 验证与 Token 控制

日常静态检查不调用 Agent，因此不产生模型 Token：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-ResearchSkills.ps1 -AllowUnverifiedModelCatalog
```

发布前严格检查省略离线开关；此时无法读取 `codex debug models`，或缺少 Python `jsonschema` 而无法执行 Draft 2020-12 Schema 验证，都会直接失败，避免假绿。真实 strategic/support/economy/mixed 性能评测应单独按需运行并记录路由、模型、首响、总耗时、输入/输出 Token 和质量评分；在获得基线数据前，不宣称具体节省比例。

## 关于 GitHub 的“主要语言”

[GitHub Linguist](https://docs.github.com/zh/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-repository-languages) 通常不把 Markdown 文档当作可统计的编程语言，因此仓库会显示 PowerShell 为主要语言。这是合理结果：Skills 的业务逻辑主要写在 Markdown/JSON 中，PowerShell 是 Windows 安装、启动、同步和回归测试层。项目不通过 `.gitattributes` 人为改写语言占比，避免误导。
