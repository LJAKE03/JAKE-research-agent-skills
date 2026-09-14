<#
.SYNOPSIS
    Creates a non-overwriting research project from project-template.

.EXAMPLE
    .\New-ResearchProject.ps1 -ProjectName '氨燃料供给系统故障预测' -Destination "$env:USERPROFILE\ResearchProjects"
.EXAMPLE
    .\New-ResearchProject.ps1 -ProjectName 'ammonia-system' -WorkspaceRoot 'D:\ResearchWorkspace'
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$ProjectName,
    [string]$Destination = '',
    [string]$WorkspaceRoot = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-WorkspaceIndex {
    param([string]$Path,[object]$Index)
    $temporaryPath = $Path + '.' + $PID + '.tmp'
    try {
        [IO.File]::WriteAllText($temporaryPath, ($Index | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($false)))
        Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
    } finally {
        if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) { Remove-Item -LiteralPath $temporaryPath -Force }
    }
}

$projectDisplayName = $ProjectName.Trim()
if ([string]::IsNullOrWhiteSpace($projectDisplayName)) { throw '项目名称不能为空。' }
if ($projectDisplayName -in @('.', '..')) { throw '项目名称不能是“.”或“..”。' }
if ($projectDisplayName.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) { throw '项目名称包含 Windows 不允许的字符。' }
if ($projectDisplayName.EndsWith('.') -or $projectDisplayName.EndsWith(' ')) { throw '项目名称不能以点或空格结尾。' }
if ($projectDisplayName -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\..*)?$') { throw '项目名称是 Windows 保留设备名。' }
if ([string]::IsNullOrWhiteSpace($Destination) -eq [string]::IsNullOrWhiteSpace($WorkspaceRoot)) {
    throw '必须且只能指定 -Destination 或 -WorkspaceRoot。'
}

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$template = Join-Path $repositoryRoot 'project-template'
$routingInitializer = Join-Path $PSScriptRoot 'Initialize-ResearchProjectRouting.ps1'
if (-not (Test-Path -LiteralPath $template -PathType Container)) { throw "项目模板不存在：$template" }
if (-not (Test-Path -LiteralPath $routingInitializer -PathType Leaf)) { throw "路由初始化脚本不存在：$routingInitializer" }
$workspaceIndexPath = $null
$workspaceIndex = $null
$projectNumber = $null
$projectId = $projectDisplayName
$name = $projectDisplayName
$workspaceLock = $null
$workspaceProjects = @()
try {
if (-not [string]::IsNullOrWhiteSpace($WorkspaceRoot)) {
    if (-not (Test-Path -LiteralPath $WorkspaceRoot -PathType Container)) { throw "科研工作区不存在：$WorkspaceRoot" }
    $workspacePath = (Resolve-Path -LiteralPath $WorkspaceRoot).ProviderPath
    $workspaceIndexPath = Join-Path $workspacePath 'PROJECT_INDEX.json'
    $projectsPath = Join-Path $workspacePath 'projects'
    foreach ($required in @('RESEARCH_WORKBENCH.md','GLOBAL_LESSONS.md','PROJECT_SOP.md','PROJECT_INDEX.json')) {
        if (-not (Test-Path -LiteralPath (Join-Path $workspacePath $required) -PathType Leaf)) { throw "科研工作区缺少文件：$required" }
    }
    if (-not (Test-Path -LiteralPath $projectsPath -PathType Container)) { throw "科研工作区缺少 projects 目录：$projectsPath" }
    $lockPath = Join-Path $workspacePath '.project-index.lock'
    try {
        $workspaceLock = [IO.File]::Open($lockPath,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    } catch [IO.IOException] {
        throw '另一个科研项目正在创建；请等待其完成后重试。'
    }
    $workspaceIndex = Get-Content -LiteralPath $workspaceIndexPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([int]$workspaceIndex.schema_version -ne 1 -or [int]$workspaceIndex.next_project_number -lt 1) { throw "科研工作区索引无效：$workspaceIndexPath" }
    $projectNumber = [int]$workspaceIndex.next_project_number
    $workspaceProjects = @($workspaceIndex.projects)
    while ($true) {
        $projectId = 'project-{0:D4}' -f $projectNumber
        $name = "$projectId-$projectDisplayName"
        if (-not (Test-Path -LiteralPath (Join-Path $projectsPath $name))) { break }
        $projectNumber++
    }
    $Destination = $projectsPath
}
elseif (-not (Test-Path -LiteralPath $Destination -PathType Container)) {
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
    if ($null -ne $workspaceIndexPath) {
        $entry = [pscustomobject][ordered]@{
            id = $projectId
            name = $projectDisplayName
            folder = ('projects/' + $name)
            status = 'initializing'
            created_at = (Get-Date).ToString('o')
            closed_at = $null
        }
        $workspaceProjects = @($workspaceProjects) + @($entry)
        $reservedIndex = [ordered]@{
            schema_version = 1
            next_project_number = ($projectNumber + 1)
            projects = @($workspaceProjects)
        }
        Write-WorkspaceIndex -Path $workspaceIndexPath -Index $reservedIndex
    }
    Copy-Item -LiteralPath $template -Destination $target -Recurse -Force
    Get-ChildItem -LiteralPath $target -Recurse -File |
        Where-Object { $_.Extension -in @('.md', '.txt', '.json', '.yaml', '.yml') } |
        ForEach-Object {
            $text = Get-Content -Encoding UTF8 -Raw -LiteralPath $_.FullName
            if ($null -ne $text) {
                $updated = $text.Replace('【项目名称】', $projectDisplayName).Replace('【项目 ID】', $projectId).Replace('研究项目名称', $projectDisplayName)
                if ($updated -cne $text) { [IO.File]::WriteAllText($_.FullName, $updated, (New-Object Text.UTF8Encoding($false))) }
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
        '.research-agent\MODEL_ROUTING.selection.json',
        '.research-agent\MODEL_ROUTING.md',
        '.research-agent\routing-version.json'
    )) {
        if (-not (Test-Path -LiteralPath (Join-Path $target $relativePath) -PathType Leaf)) {
            throw "新项目缺少托管路由文件：$relativePath"
        }
    }
    $routingStatus = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $target '.research-agent\routing-version.json') | ConvertFrom-Json
    $canonicalPath = Join-Path $repositoryRoot 'shared\MODEL_ROUTING.json'
    $snapshotPath = Join-Path $target '.research-agent\MODEL_ROUTING.json'
    $canonicalHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $canonicalPath).Hash
    $snapshotHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $snapshotPath).Hash
    if ($snapshotHash -ne $canonicalHash -or [string]$routingStatus.canonical_sha256 -ne $canonicalHash) {
        throw 'New project routing snapshot does not match canonical bytes.'
    }
    if ([int]$routingStatus.conflict_count -ne 0 -or [string]$routingStatus.status -notin @('ready','degraded_strategic_only')) {
        throw "New project routing is not usable: status=$($routingStatus.status) conflicts=$($routingStatus.conflict_count)"
    }
    if ([string]$routingStatus.status -eq 'degraded_strategic_only') {
        if ([string]$routingStatus.catalog.status -ne 'verified' -or -not [bool]$routingStatus.catalog.routing_models.strategic -or 'strategic' -in @($routingStatus.unavailable_tiers)) { throw 'New project has invalid strategic-only status.' }
        Write-Warning "New project uses strategic-only routing; unavailable tiers: $(@($routingStatus.unavailable_tiers) -join ',')"
    }
    if ($null -ne $workspaceIndexPath) {
        $workspaceProjects[-1].status = 'active'
        $updatedIndex = [ordered]@{
            schema_version = 1
            next_project_number = ($projectNumber + 1)
            projects = @($workspaceProjects)
        }
        Write-WorkspaceIndex -Path $workspaceIndexPath -Index $updatedIndex
    }
    Write-Output ('启动：阅读 ' + $target + '\RESEARCH_PROJECT_START_PROMPT.md 并调用 $research-project-orchestrator')
}
} finally {
    if ($null -ne $workspaceLock) { $workspaceLock.Dispose() }
}
