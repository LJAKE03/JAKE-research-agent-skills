<#
.SYNOPSIS
    Creates a non-overwriting research project from project-template.

.EXAMPLE
    .\New-ResearchProject.ps1 -ProjectName '氨燃料供给系统故障预测' -Destination "$env:USERPROFILE\ResearchProjects"
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$ProjectName,
    [Parameter(Mandatory)][string]$Destination
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$name = $ProjectName.Trim()
if ([string]::IsNullOrWhiteSpace($name)) { throw '项目名称不能为空。' }
if ($name -in @('.', '..')) { throw '项目名称不能是“.”或“..”。' }
if ($name.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) { throw '项目名称包含 Windows 不允许的字符。' }
if ($name.EndsWith('.') -or $name.EndsWith(' ')) { throw '项目名称不能以点或空格结尾。' }
if ($name -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\..*)?$') { throw '项目名称是 Windows 保留设备名。' }

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$template = Join-Path $repositoryRoot 'project-template'
$routingInitializer = Join-Path $PSScriptRoot 'Initialize-ResearchProjectRouting.ps1'
if (-not (Test-Path -LiteralPath $template -PathType Container)) { throw "项目模板不存在：$template" }
if (-not (Test-Path -LiteralPath $routingInitializer -PathType Leaf)) { throw "路由初始化脚本不存在：$routingInitializer" }
if (-not (Test-Path -LiteralPath $Destination -PathType Container)) {
    New-Item -ItemType Directory -Path $Destination | Out-Null
}

$destinationPath = (Resolve-Path -LiteralPath $Destination).ProviderPath
$target = [IO.Path]::GetFullPath((Join-Path $destinationPath $name))
$targetParent = [IO.Path]::GetFullPath((Split-Path -Parent $target))
if (-not $targetParent.Equals([IO.Path]::GetFullPath($destinationPath), [StringComparison]::OrdinalIgnoreCase)) {
    throw '项目目标路径必须是保存目录的直接子目录。'
}
if (Test-Path -LiteralPath $target) { throw "目标项目已存在，为避免覆盖而停止：$target" }

if ($PSCmdlet.ShouldProcess($target, '创建科研项目')) {
    Copy-Item -LiteralPath $template -Destination $target -Recurse -Force
    Get-ChildItem -LiteralPath $target -Recurse -File |
        Where-Object { $_.Extension -in @('.md', '.txt', '.json', '.yaml', '.yml') } |
        ForEach-Object {
            $text = Get-Content -Encoding UTF8 -Raw -LiteralPath $_.FullName
            if ($null -ne $text) {
                $updated = $text.Replace('【项目名称】', $name).Replace('研究项目名称', $name)
                [IO.File]::WriteAllText($_.FullName, $updated, (New-Object Text.UTF8Encoding($true)))
            }
        }

    foreach ($directory in @(
        '01_任务与需求',
        '02_文献资料',
        '03_数据',
        '04_模型与代码',
        '05_图表',
        '06_阶段成果',
        '07_论文与报告',
        '08_质量门与复盘'
    )) {
        $directoryPath = Join-Path $target $directory
        if (-not (Test-Path -LiteralPath $directoryPath -PathType Container)) {
            New-Item -ItemType Directory -Path $directoryPath | Out-Null
        }
    }


    & $routingInitializer -ProjectDirectory $target -RepositoryRoot $repositoryRoot -Quiet
    foreach ($relativePath in @(
        '.codex\config.toml',
        '.codex\agents\research-support.toml',
        '.codex\agents\research-output.toml',
        '.research-agent\MODEL_ROUTING.json',
        '.research-agent\MODEL_ROUTING.md',
        '.research-agent\routing-version.json'
    )) {
        if (-not (Test-Path -LiteralPath (Join-Path $target $relativePath) -PathType Leaf)) {
            throw "新项目缺少托管路由文件：$relativePath"
        }
    }

    Write-Output "项目已创建：$target"
    Write-Output ('启动：阅读 ' + $target + '\RESEARCH_PROJECT_START_PROMPT.md 并调用 $research-project-orchestrator')
}
