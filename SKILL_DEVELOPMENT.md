# Skill Development

## 正式源与项目边界

- 正式 Skill 只位于当前仓库；用户级安装目录是链接或复制出的运行入口，不是编辑源。
- 单个项目的特殊规则不直接写入公共 Skill，应写入项目目录的 `PROJECT_OVERRIDES.md`。
- 项目问题先写入项目目录的 `SKILL_FEEDBACK.md`。
- 通用改进先形成 `skill-development/proposals/` 下的 proposal。

## 修改与发布

- 修改前必须建立或更新回归测试；测试至少覆盖触发、路由、输出边界或安全行为中的相关项。
- 经用户确认后，才可合并为正式版本。
- 小修改升级补丁版本（`2.0.x`）；新能力升级次版本（`2.x.0`）；架构变化升级主版本（`x.0.0`）。
- 禁止因单一项目特例无限扩充公共 Skill；无法泛化的内容留在项目级文件。

## 迭代闭环

1. 记录项目反馈并判断属于项目特例、通用缺陷、路由问题或测试缺口。
2. 通用问题形成 proposal，写明动机、影响范围、拟修改文件、验收标准和回滚方式。
3. 在 `skill-development/regression-tests/` 添加回归场景。
4. 评审通过后修改候选 Skill，运行 `Test-ResearchSkills.ps1`。
5. 用户确认后更新 VERSION、CHANGELOG 并合并正式版本；每次阶段质量门之后可填写 `SKILL_RETROSPECTIVE.template.md`。
