# 2026-08-04：投稿论断追溯闭环

## 背景与根因

现有流程已经具备论点—证据图、分段写作和 L0/L1/L2 质量门，但投稿级成果缺少一个跨章节共享的明确合同：贡献声明、证明它所需的证据、主要结果、声明边界和审稿风险分别存在于不同阶段，容易出现“结果很多但没有验证贡献”“语言已经完善但重大方法异议仍未关闭”的断链。

## 外部模式学习

本轮核对了 [PaperSpine 官方仓库](https://github.com/WUBING2023/PaperSpine)，抽取其贡献优先、结果—贡献映射、审稿视角预检和受影响阶段恢复等抽象机制。实现采用 clean-room 方式重新设计，没有复制其代码、提示词或固定 12 阶段工作流；项目仍保持统一科研流程和按真实依赖分阶段。

## 优化内容

- 新增唯一共享模板 `shared/PUBLICATION_CLAIM_TRACEABILITY.template.md`，记录核心命题、贡献声明、所需 / 已有 / 缺失证据、允许声明和禁止外推。
- 投稿级实质写作前必须确认合同；确认前不把正文写作交给 Luna。
- 每个主要 Results 单元必须回指贡献 ID、证据定位、工况 / 样本 / 单位 / 不确定性及允许解释。
- 投稿预检复用已有 L1/L2 发现形成审稿与编辑风险登记，不新增常驻 Reviewer Agent。
- CRITICAL / MAJOR 科学异议未关闭时返回 REVISE 或 BLOCKED；否定结果和反例用于收缩或撤回声明，不得删除。
- 合同变化只让受影响产物退回最早必要位置，未变化证据继续复用。
- 增加 4 个统一流程行为评测和确定性回归断言，覆盖投稿合同缺失、结果无贡献映射、重大异议未关闭和内部周报近失配。

## 兼容与数据保护

- 仅期刊论文、会议论文、正式投稿材料及包含创新性或最终科学结论的成果启用；内部周报和一般过程报告不强制增加治理。
- 不改变现有 Sol / Terra / Luna 路由，不新增顶层 Skill、常驻 Agent、独立运行时或固定阶段数。
- 原始证据、异常、失败记录、否定结果和旧版本继续保留；模板只保存定位和合同状态，不复制或清理原始材料。

## 验证证据

- JSON 合同解析：PASS，统一流程评测合同共 22 条。
- 最小应用路由回归：FINAL PASS。
- 全量静态与集成检查：FINAL PASS；PowerShell 5.1 UTF-8 回归通过，PowerShell 7 因本机不可用按既有规则跳过。
- 旧版 / 候选版配对语义评测：旧版 3/4，候选版 4/4；候选版明确补齐“所需 / 已有 / 缺失证据”三分法，且更可执行、未过度阻断。
- Git diff / 编码检查：PASS；原仓库用户修改 `installation-report.md` 未触碰。

## Git / PR 追溯

- 分支：`agent/publication-claim-traceability`
- 提交：[c4d3655](https://github.com/LJAKE03/JAKE-research-agent-skills/commit/c4d3655cc391013e14a6ad7e7a873c5a34f091ba)
- Pull Request：[草稿 PR #14](https://github.com/LJAKE03/JAKE-research-agent-skills/pull/14)
- 上游历史：PR #13 已合并；本分支已安全快进到最新 `master`，新 PR 直接以 `master` 为基线。