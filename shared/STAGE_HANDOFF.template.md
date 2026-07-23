# COMPACT RESEARCH TASK CARD AND HANDOFF

## Sol → Worker task card

只发送完成当前任务所需的最小上下文：

- `objective`：当前唯一目标；
- `input_locators`：文件、页码、URL、数据表或已锁定摘要定位；
- `locked_decisions`：不得改变的范围、方法、参数、论点和术语；
- `output_contract`：证据表、字段、草稿或格式结构；
- `acceptance_checks`：可观察验收条件；
- `stop_conditions`：证据不足、冲突、越界或高风险时停止。

禁止附带完整对话、全部项目历史、全部工具日志或可通过定位读取的整篇原文。

### Terra 任务卡

限定检索范围、资料类型、字段、来源要求和停止条件。Terra 返回证据表、定位、缺口和可观察摘要，不做可靠性裁决或科学综合。

### Luna 写作包

必须包含锁定的目标、提纲、论点顺序、可用事实/数据/公式/引用编号、风格、语言、长度、格式、禁止新增项和占位符规则。

## Worker → Sol handoff

按 `STAGE_HANDOFF.schema.json` 返回：

- `schema_version`：2；
- `status`：complete / partial / blocked；
- `handoff_type`：evidence_pack / writing_draft / stage_result / verification_result；
- `summary`：最多 8 条结论摘要；
- `deliverable`：证据表、提取结果、草稿或验证结果；
- `evidence_locations`：来源或文件定位；
- `uncertainties`：缺口、冲突和待 Sol 决定事项；
- `changed_files`：只读 Worker 必须为空；
- `next_action`：返回 Sol 后的唯一建议动作。

Worker 不得直接联系另一个 Worker，不得自行进入下一阶段。
