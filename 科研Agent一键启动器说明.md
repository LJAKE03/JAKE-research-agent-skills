# 科研 Agent 一键启动器

## 日常使用

双击仓库根目录或桌面上的“科研Agent”快捷方式，然后选择：

1. 新建科研项目：输入名称、选择保存目录。启动器调用 scripts\New-ResearchProject.ps1，不会覆盖同名项目。
2. 打开已有科研项目：选择项目根目录。若模板文件不完整，启动器会先列出准备新增的文件；确认后只原子创建缺失文件。
3. 打开最近一次项目：打开最近一个仍存在且包含 AGENTS.md、PROJECT_STATE.md 的有效项目。
4. 仅检查科研 Skills：运行 scripts\Test-ResearchSkills.ps1 并明确显示 PASS、WARNING 或 FAIL。
5. 退出。

选择项目后，可填写本次科研任务，也可留空后在 Codex Desktop 中输入。启动器会打开 Codex Desktop 图形界面，并把项目路径和首条 Prompt 自动复制到剪贴板。请在 Desktop 中打开提示的项目目录作为工作区，新建任务后按 Ctrl+V 粘贴；Prompt 会调用 $research-project-orchestrator 并按项目状态、阶段和质量门恢复工作。

启动器优先使用 Windows 图形界面；任一图形对话框不可用时，会自动回退到控制台输入。

## 首次准备

启动器需要已安装且能从开始菜单打开的 Codex Desktop 图形应用。找不到 Desktop 时，启动器只显示明确错误，不会自行安装软件。

## 配置与安全性

scripts\research-launcher-settings.json 只保存最近项目路径（最多 10 个）、默认项目目录和最后使用时间，不保存账号、密码或 Token。配置损坏、字段类型错误或项目路径失效时，会安全恢复和清理。

启动器通过 Windows 已注册的 Codex Desktop 应用入口打开图形界面，不调用 WindowsApps 中不可作为终端使用的 codex.exe，也不使用 --yolo、--dangerously-bypass-approvals-and-sandbox 或 danger-full-access。Desktop 目前没有可验证的稳定参数可同时预填项目目录和多行 Prompt，因此启动器不猜测深度链接：它只自动复制 Prompt，避免把项目或任务发送到错误位置。

## 非交互自检

在仓库根目录运行：

    .\启动科研Agent.cmd --self-test

自检不会打开图形菜单或启动 Codex Desktop。它覆盖 CMD 编码与路径、新旧项目 Prompt、Desktop 启动入口发现、配置恢复、已有项目安全补齐、新建项目、同名拒绝、最近项目清理和 Skills 检查。

所有测试数据仅写入 D 盘正式仓库的 scripts\.launcher-self-tests 临时目录。脚本在核验绝对路径边界后自动清理，不使用 C 盘临时目录。

## 桌面快捷方式

    powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\Create-ResearchAgentShortcut.ps1"

快捷方式名称为“科研Agent”。更新时会显式清空旧参数，并在保存后回读验证目标、参数和工作目录。

## 维护提示

启动器不会修改公共 Skill、根目录 AGENTS.md、现有科研项目或 Git 配置。检查改动后再自行执行 git commit。
