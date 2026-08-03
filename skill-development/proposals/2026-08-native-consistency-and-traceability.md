# 原生一致性与科研可追溯改造提案

## 动机

当前套件已经要求最小实现、紧凑交接和科研证据可追溯，但跨 Skill、脚本、Schema、文档和测试的修改尚缺少一个统一变更契约。静态审计还发现两类具体漂移风险：模型路由值在 canonical JSON 之外被多处手写；只读 Worker 的 `changed_files=[]` 只有文字约束，Schema 没有拒绝违规交接。

## 原则

正式活动文件应像一次正确设计完成般一致，修改优先修复根因并收敛到唯一权威来源；原始数据、来源定位、失败记录、关键参数、决策依据、版本历史和复盘不得因“整洁”而删除或伪装。

## 影响范围

- 新增 `shared/CHANGE_INTEGRITY_PROTOCOL.md` 作为唯一共享变更契约；
- 总控、开发规范、质量量规和套件索引只引用该契约，不复制全文；
- Skills 和启动提示从 `shared/MODEL_ROUTING.json` 读取兼容委派值，不再手写模型映射；
- `STAGE_HANDOFF.schema.json` 对只读类型的非空 `changed_files` 做机器拒绝；
- 增加负向 fixture、回归断言和行为评测；
- 澄清 README 中兼容入口属于同一 canonical 路由，不是第二套流程。

## 验收标准

1. 活动 Skill 与启动提示不再包含 Sol/Terra/Luna 的模型 ID 或 reasoning 字面量；生成 TOML、canonical JSON、历史记录和测试 fixture 除外。
2. `evidence_pack`、`writing_draft` 和 `verification_result` 的非空 `changed_files` 无法通过 Schema。
3. 新协议有且仅有一个权威定义；消费者通过相对路径引用。
4. 最小测试、全量静态测试、UTF-8/BOM 检查和旧版/候选版行为对照均可运行。
5. 不覆盖正式仓库的既有未提交修改，不删除原始证据、历史记录或备份残留。

## 回滚

本轮先在候选副本实施。若评测或用户审阅不通过，丢弃候选副本即可；正式源仓库保持不变。

