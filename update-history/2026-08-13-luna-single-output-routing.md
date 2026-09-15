# Luna 单一低判断成品路由

状态：已上传，待合并

## 背景与根因

旧规则把 Luna 限定为“锁定科研写作包”的文本、语言和格式 Worker。它能避免 Luna 越过科研判断边界，但没有覆盖内容已经核对完、只需组织成一份 PDF、Word、Excel 或 PPT 的单一输出任务。因此，考公选调材料这类任务即使最终只剩确定性的成品组织，也可能只调用 Terra 做资料工作，未在输出阶段调用 Luna。

历史任务审计显示：相关考公选调 PDF 任务实际由 Sol 主线程和两个 Terra 证据子任务完成，没有 Luna 调用证据。Terra 用于岗位与待遇证据核验是正确的；缺口在于结论锁定后的低判断输出阶段没有明确 Luna 路由。

## 优化内容

- 将 canonical economy purpose 从锁定科研写作包扩展为锁定输出包。
- 当主要交付物只有一个、内容/字段/顺序/模板/决策已锁定、剩余工作只是改写/排版/制表/摘要化/语言转换且可确定性验收时，优先使用 Luna。
- 明确 PDF、Word、Excel、PPT 后缀本身不是路由依据。
- 外部检索和文件事实提取继续由 Terra；计算、公式推导、方法选择、分类排序、优先级与关键解释继续由 Sol。
- Luna 保持只读，只生成草稿、结构化内容和格式规格；专用文档、表格、PDF 或演示工具负责实际落盘、渲染和验证。

## 兼容与数据保护

- 模型映射、reasoning、sandbox、并发和降级机制不变。
- 保留现有 `writing_draft` handoff 类型，锁定写作包作为锁定输出包的子集，避免破坏现有 Schema 和消费者。
- 未修改或删除任何用户项目数据、历史失败记录或旧版本记录。

## 验证证据

- 先添加 4 个正反行为评测，旧测试因评测数量仍为 28 而失败，证明回归会捕获未同步状态。
- 新增已锁定考公 PDF 和固定模板 Excel 两个 Luna 正例。
- 新增未完成资格判断的招录 PDF/Excel 和仍需工程计算的 PDF 两个反例。
- 路由测试同时检查锁定输出包、文件后缀非判据、专用工具落盘边界和禁止 Luna 新增计算/分类/优先级。

## Git / PR 追溯

- 发布分支：[agent/v2.5-configurable-model-routing](https://github.com/LJAKE03/JAKE-research-agent-skills/tree/agent/v2.5-configurable-model-routing)
- 功能提交：[fac32db](https://github.com/LJAKE03/JAKE-research-agent-skills/commit/fac32db21bb381f0d57a72361851a6c3dc9acf97)
- Pull Request：[#16](https://github.com/LJAKE03/JAKE-research-agent-skills/pull/16)
- 本项更新与项目级模型选择一同上传，可通过上述 PR 的文件差异追溯。
