# 历史更新目录

这里为每次实质性优化保留一份独立记录，回答“为什么改、改了什么、如何验证、如何追溯”。`CHANGELOG.md` 继续承担版本级摘要；本目录承担面向维护者的详细变更档案。

## 记录规则

- 文件名使用 `YYYY-MM-DD-topic.md`；同日多次更新时在 topic 中区分主题。
- 每条记录至少包含背景与根因、优化内容、兼容与数据保护、验证证据、Git/PR 追溯。
- 原始数据、失败记录、旧版本和项目复盘不因目录整洁而删除；这里只建立索引，不复制或改写证据。
- 尚未合并的记录标记为“待合并”；PR 合并后保留原记录并补充最终链接。

## 更新索引

| 日期 | 主题 | 状态 | 记录 |
|---|---|---|---|
| 2026-09-14 | 项目级模型选择与轻量执行 | 本地待合并 | [查看详情](2026-09-14-configurable-model-routing.md) |
| 2026-08-13 | Luna 单一低判断成品路由 | 待合并 | [查看详情](2026-08-13-luna-single-output-routing.md) |
| 2026-08-05 | 主动关键信息与科研记忆演化 | [PR #15](https://github.com/LJAKE03/JAKE-research-agent-skills/pull/15) | [查看详情](2026-08-05-proactive-inquiry-and-memory-evolution.md) |
| 2026-08-04 | 投稿论断追溯闭环 | [草稿 PR #14](https://github.com/LJAKE03/JAKE-research-agent-skills/pull/14) | [查看详情](2026-08-04-publication-claim-traceability.md) |
| 2026-08-03 | 原生一致性与科研可追溯优化 | [已合并 PR #12](https://github.com/LJAKE03/JAKE-research-agent-skills/pull/12) | [查看详情](2026-08-03-native-consistency-and-traceability.md) |

更早的版本级记录见 [CHANGELOG.md](../CHANGELOG.md)，设计决策见 [DESIGN_NOTES.md](../DESIGN_NOTES.md)。
