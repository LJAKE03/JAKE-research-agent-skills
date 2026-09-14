# v1.7：项目级模型选择与轻量执行

- 日期：2026-09-14
- 状态：本地待合并
- 配置版本：1.7.0

## 背景与根因

原路由把 Sol、Terra、Luna 直接写成固定角色，并要求命中检索或写作条件后强制委派。该设计无法让用户按预算选择模型，也会让短任务承担不必要的子线程、交接和质量门开销。当前 Codex CLI 0.144.1 的本地模型目录还没有 Astra，因此只改提示词也无法启动 Astra。

## 核心决策

1. 公共 `MODEL_ROUTING.json` 保留默认值和安全边界；项目选择单独写入 `MODEL_ROUTING.selection.json`。
2. 战略总控可选 Astra 或 Sol；support/economy 可选 Sol、Terra 或 Luna，并允许多个角色使用同一模型。
3. 默认仍为 Sol/`xhigh`、Terra/`medium`、Luna/`low`。
4. 委派改为成本判断：任务可独立分离、输入清楚且收益超过交接开销时才创建 Worker。
5. 低风险可逆工作连续推进；质量门和用户确认只放在有实质风险或依赖的边界。

## 主要变更

- 新增选择 Schema、默认选择模板、`Set-ResearchModels.ps1` 和可双击配置入口。
- 初始化器解析项目选择并记录选择哈希、resolved tiers 和运行时目录证据。
- 生成器同步默认选择，不覆盖已存在项目的选择。
- 路由状态从 `degraded_sol_only` 改为 `degraded_strategic_only`。
- 总控、检索、写作、项目 AGENTS、启动提示和 README 改用角色名，移除固定模型假设。
- 缩窄总控触发条件，取消短任务的强制委派和每章节无条件质量门。

## 兼容与数据保护

- 旧项目没有选择文件时继续使用原 Sol/Terra/Luna 默认值。
- 项目 canonical 快照仍与公共 JSON 保持字节一致；用户选择作为 overlay，不伪装成 canonical。
- 配置脚本修改 TOML 前保存备份。
- Astra 选择可先保存；本地模型目录缺失时项目状态明确阻断，不静默回退到未选择模型。
- 已运行的主线程不会动态换模型；选择对新任务生效。

## 验证证据

- `Test-ResearchAppRouting.ps1`：FINAL PASS。
- `Test-ManagedProjectRouting.ps1`：MANAGED_PROJECT_ROUTING_PASS、TEMP_CLEANUP_PASS。
- 临时项目验证：三个角色均选择 Sol 时 status=ready；Astra/xhigh 选择可保存，当前 CLI 中 status=blocked_model_catalog。
- PowerShell 语法解析与 JSON 解析通过。

## Git / PR 追溯

- 工作副本：`D:\LMJ\AI Learning\AI-agent\skills-hub\suite\JAKE-research-agent-skills`
- 当前状态：本地待审阅，尚未推送 GitHub。

- 完整套件检查：`scripts/Test-ResearchSkills.ps1` 返回 `FINAL PASS`。
- UTF-8 检查：Windows PowerShell 5.1 与 PowerShell 7.6.5 均返回 `RESEARCH_ENCODING_PASS`。
