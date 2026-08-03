# 2026-08-03：原生一致性与科研可追溯优化

## 背景与根因

- 模型路由值曾分散在总控、功能 Skill、模板、配置和启动器中，存在多点手工同步与漂移风险。
- 只读 Worker 的 handoff 虽有文字边界，但 Schema 未确定性拒绝非空 `changed_files`。
- 活动文档中的兼容说明和历史说明边界不够清楚，容易把“整洁最终状态”误解为删除失败记录或版本证据。

## 本次优化

1. 新增 `shared/CHANGE_INTEGRITY_PROTOCOL.md`，统一根因修复、唯一权威来源、活动/生成/历史/临时文件分类、兼容层退出和安全清理边界。
2. 将 `shared/MODEL_ROUTING.json` 明确为模型路由唯一权威来源；总控与功能 Skill 引用 canonical 键，配置、模板和启动器作为生成或解析校验的消费者。
3. 同步脚本覆盖 CLI 配置模板，回归测试扫描活动消费者中的重复模型映射并核对生成产物。
4. `STAGE_HANDOFF.schema.json` 对只读 evidence、writing 和 verification handoff 强制 `changed_files=[]`，并增加负向 fixture。
5. 质量门必须逐字输出 `PASS`、`CONDITIONAL PASS`、`REVISE` 或 `BLOCKED`，便于机器验收。
6. README 将目录级入口明确为同一 canonical 工作流的兼容入口，并新增独立历史更新目录。

## 兼容、数据与历史保护

- 未删除原始数据、失败实验、异常工况、参数变化、项目复盘或 Git 历史。
- 未清理仓库中既有 `.bak` 文件；其去留需单独完成引用核验和用户授权。
- 用户本地已有的 `installation-report.md` 修改不属于本次优化，不进入本次提交。
- 生成型配置保留具体模型值，但必须由 canonical JSON 同步并通过解析式漂移测试。

## 验证证据

- `scripts/Test-ResearchAppRouting.ps1 -AllowUnverifiedModelCatalog`：FINAL PASS。
- `scripts/Sync-ResearchRoutingArtifacts.ps1 -WhatIf`：changes=0。
- `scripts/Test-ResearchSkills.ps1 -AllowUnverifiedModelCatalog`：FINAL PASS。
- 行为评测：候选版 12/12，原版 10/12。
- 独立质量门：PASS，无正式合并前必须修改项。

## Git 与评审追溯

- 发布分支：`agent/native-consistency-history`
- GitHub PR：创建后补充
- 设计提案：[2026-08-native-consistency-and-traceability.md](../skill-development/proposals/2026-08-native-consistency-and-traceability.md)
- 版本摘要：[CHANGELOG.md](../CHANGELOG.md)

