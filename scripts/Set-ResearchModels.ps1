<#
.SYNOPSIS
  Configures the controller, evidence worker, and output worker models for one research project.
.EXAMPLE
  .\Set-ResearchModels.ps1 -ProjectDirectory 'D:\Research\MyProject' -Interactive
.EXAMPLE
  .\Set-ResearchModels.ps1 -ProjectDirectory 'D:\Research\MyProject' -StrategicModel gpt-5.6-sol -StrategicEffort xhigh -SupportModel gpt-5.6-terra -SupportEffort medium -EconomyModel gpt-5.6-luna -EconomyEffort low
#>
[CmdletBinding()]
param(
  [string]$ProjectDirectory = '',
  [string]$RepositoryRoot = '',
  [string]$StrategicModel = '',
  [string]$StrategicEffort = '',
  [string]$SupportModel = '',
  [string]$SupportEffort = '',
  [string]$EconomyModel = '',
  [string]$EconomyEffort = '',
  [switch]$Interactive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Utf8NoBom = New-Object Text.UTF8Encoding($false)

if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$RepositoryRoot = (Resolve-Path -LiteralPath $RepositoryRoot).ProviderPath
if ([string]::IsNullOrWhiteSpace($ProjectDirectory) -and $Interactive) {
  $defaultProject = (Get-Location).ProviderPath
  $answer = Read-Host "请输入科研项目根目录；直接回车使用 $defaultProject"
  $ProjectDirectory = if ([string]::IsNullOrWhiteSpace($answer)) { $defaultProject } else { $answer.Trim().Trim('"') }
}
if ([string]::IsNullOrWhiteSpace($ProjectDirectory)) { $ProjectDirectory = (Get-Location).ProviderPath }
$ProjectDirectory = (Resolve-Path -LiteralPath $ProjectDirectory).ProviderPath
$managedRoot = Join-Path $ProjectDirectory '.research-agent'
$selectionPath = Join-Path $managedRoot 'MODEL_ROUTING.selection.json'
$templateSelectionPath = Join-Path $RepositoryRoot 'project-template\.research-agent\MODEL_ROUTING.selection.json'
$initializer = Join-Path $PSScriptRoot 'Initialize-ResearchProjectRouting.ps1'
if (-not (Test-Path -LiteralPath $templateSelectionPath -PathType Leaf)) { throw "缺少模型选择模板：$templateSelectionPath" }
if (-not (Test-Path -LiteralPath $initializer -PathType Leaf)) { throw "缺少路由初始化脚本：$initializer" }
if (-not (Test-Path -LiteralPath $managedRoot -PathType Container)) { New-Item -ItemType Directory -Path $managedRoot -Force | Out-Null }

$sourceSelection = if (Test-Path -LiteralPath $selectionPath -PathType Leaf) { $selectionPath } else { $templateSelectionPath }
try { $selection = Get-Content -Raw -Encoding UTF8 -LiteralPath $sourceSelection | ConvertFrom-Json }
catch { throw "模型选择文件无法解析：$($_.Exception.Message)" }

$modelsByTier = @{
  strategic = @('gpt-5.6-sol','gpt-6-astra')
  support = @('gpt-5.6-sol','gpt-5.6-terra','gpt-5.6-luna')
  economy = @('gpt-5.6-sol','gpt-5.6-terra','gpt-5.6-luna')
}
$effortsByModel = @{
  'gpt-6-astra' = @('low','medium','high','xhigh','max')
  'gpt-5.6-sol' = @('low','medium','high','xhigh','max','ultra')
  'gpt-5.6-terra' = @('low','medium','high','xhigh','max','ultra')
  'gpt-5.6-luna' = @('low','medium','high','xhigh','max')
}

function Read-MenuChoice {
  param([string]$Label,[string[]]$Choices,[string]$Current)
  Write-Host ''
  Write-Host "$Label（当前：$Current）"
  for($i=0; $i -lt $Choices.Count; $i++) { Write-Host ("{0}. {1}" -f ($i+1),$Choices[$i]) }
  $answer = Read-Host '输入序号；直接回车保留当前值'
  if ([string]::IsNullOrWhiteSpace($answer)) { return $Current }
  $number = 0
  if (-not [int]::TryParse($answer,[ref]$number) -or $number -lt 1 -or $number -gt $Choices.Count) { throw "无效选择：$answer" }
  return [string]$Choices[$number-1]
}

$current = @{
  strategic_model = [string]$selection.tiers.strategic.model
  strategic_effort = [string]$selection.tiers.strategic.reasoning_effort
  support_model = [string]$selection.tiers.support.model
  support_effort = [string]$selection.tiers.support.reasoning_effort
  economy_model = [string]$selection.tiers.economy.model
  economy_effort = [string]$selection.tiers.economy.reasoning_effort
}

function Get-CompatibleEffort {
  param([string]$Model,[string]$Current,[string]$Fallback)
  if ($Current -cin @($effortsByModel[$Model])) { return $Current }
  return $Fallback
}

if ($Interactive) {
  $StrategicModel = Read-MenuChoice '总控模型' $modelsByTier.strategic $current.strategic_model
  $StrategicEffort = Read-MenuChoice '总控推理强度' $effortsByModel[$StrategicModel] (Get-CompatibleEffort $StrategicModel $current.strategic_effort 'xhigh')
  $SupportModel = Read-MenuChoice '检索/证据 Worker 模型' $modelsByTier.support $current.support_model
  $SupportEffort = Read-MenuChoice '检索/证据 Worker 推理强度' $effortsByModel[$SupportModel] (Get-CompatibleEffort $SupportModel $current.support_effort 'medium')
  $EconomyModel = Read-MenuChoice '执行/输出 Worker 模型' $modelsByTier.economy $current.economy_model
  $EconomyEffort = Read-MenuChoice '执行/输出 Worker 推理强度' $effortsByModel[$EconomyModel] (Get-CompatibleEffort $EconomyModel $current.economy_effort 'low')
}

if ([string]::IsNullOrWhiteSpace($StrategicModel)) { $StrategicModel = $current.strategic_model }
if ([string]::IsNullOrWhiteSpace($SupportModel)) { $SupportModel = $current.support_model }
if ([string]::IsNullOrWhiteSpace($EconomyModel)) { $EconomyModel = $current.economy_model }
if ([string]::IsNullOrWhiteSpace($StrategicEffort)) { $StrategicEffort = Get-CompatibleEffort $StrategicModel $current.strategic_effort 'xhigh' }
if ([string]::IsNullOrWhiteSpace($SupportEffort)) { $SupportEffort = Get-CompatibleEffort $SupportModel $current.support_effort 'medium' }
if ([string]::IsNullOrWhiteSpace($EconomyEffort)) { $EconomyEffort = Get-CompatibleEffort $EconomyModel $current.economy_effort 'low' }

$requested = @{
  strategic = @{ model=$StrategicModel; effort=$StrategicEffort }
  support = @{ model=$SupportModel; effort=$SupportEffort }
  economy = @{ model=$EconomyModel; effort=$EconomyEffort }
}
foreach($tier in @('strategic','support','economy')) {
  $model = [string]$requested[$tier].model
  $effort = [string]$requested[$tier].effort
  if ($model -cnotin @($modelsByTier[$tier])) { throw "$tier 不允许使用模型 $model" }
  if ($effort -cnotin @($effortsByModel[$model])) { throw "$model 不支持配置 reasoning_effort=$effort" }
}

$newSelection = [ordered]@{
  schema_version = 1
  tiers = [ordered]@{
    strategic = [ordered]@{ model=$StrategicModel; reasoning_effort=$StrategicEffort }
    support = [ordered]@{ model=$SupportModel; reasoning_effort=$SupportEffort }
    economy = [ordered]@{ model=$EconomyModel; reasoning_effort=$EconomyEffort }
  }
}
$newText = ($newSelection | ConvertTo-Json -Depth 5) + [Environment]::NewLine
$backupRoot = Join-Path $managedRoot 'backups'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmssfff'
function Backup-File {
  param([string]$Path,[string]$Name)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return }
  if (-not (Test-Path -LiteralPath $backupRoot -PathType Container)) { New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null }
  Copy-Item -LiteralPath $Path -Destination (Join-Path $backupRoot "$Name.$stamp.bak")
}
if ((Test-Path -LiteralPath $selectionPath -PathType Leaf) -and [IO.File]::ReadAllText($selectionPath) -ne $newText) { Backup-File $selectionPath 'MODEL_ROUTING.selection.json' }
[IO.File]::WriteAllText($selectionPath,$newText,$Utf8NoBom)

function Set-TomlValue {
  param([string]$Text,[string]$Name,[string]$Value)
  $pattern = '(?m)^\s*' + [regex]::Escape($Name) + '\s*=\s*"[^"]*"\s*$'
  $replacement = $Name + ' = "' + $Value + '"'
  $regex = [regex]::new($pattern)
  if ($regex.IsMatch($Text)) { return $regex.Replace($Text,$replacement,1) }
  return $replacement + [Environment]::NewLine + $Text
}
function Update-TomlFile {
  param([string]$Path,[string]$Template,[string]$Model,[string]$Effort,[string]$BackupName)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    Copy-Item -LiteralPath $Template -Destination $Path
  }
  $before = [IO.File]::ReadAllText($Path)
  $after = Set-TomlValue (Set-TomlValue $before 'model' $Model) 'model_reasoning_effort' $Effort
  if ($after -ne $before) {
    Backup-File $Path $BackupName
    [IO.File]::WriteAllText($Path,$after,$Utf8NoBom)
  }
}

Update-TomlFile (Join-Path $ProjectDirectory '.codex\config.toml') (Join-Path $RepositoryRoot 'project-template\.codex\config.toml') $StrategicModel $StrategicEffort 'config.toml'
Update-TomlFile (Join-Path $ProjectDirectory '.codex\agents\research-support.toml') (Join-Path $RepositoryRoot 'project-template\.codex\agents\research-support.toml') $SupportModel $SupportEffort 'research-support.toml'
Update-TomlFile (Join-Path $ProjectDirectory '.codex\agents\research-output.toml') (Join-Path $RepositoryRoot 'project-template\.codex\agents\research-output.toml') $EconomyModel $EconomyEffort 'research-output.toml'

$preflightError = $null
try { & $initializer -ProjectDirectory $ProjectDirectory -RepositoryRoot $RepositoryRoot -Quiet }
catch { $preflightError = $_.Exception.Message }
$statusPath = Join-Path $managedRoot 'routing-version.json'
$status = if (Test-Path -LiteralPath $statusPath -PathType Leaf) { Get-Content -Raw -Encoding UTF8 -LiteralPath $statusPath | ConvertFrom-Json } else { $null }

Write-Output "MODEL_SELECTION_SAVED project=$ProjectDirectory"
Write-Output "MODEL_SELECTION strategic=$StrategicModel/$StrategicEffort support=$SupportModel/$SupportEffort economy=$EconomyModel/$EconomyEffort"
if ($null -ne $status) { Write-Output "MODEL_SELECTION_PREFLIGHT status=$($status.status) unavailable=$(@($status.unavailable_tiers) -join ',')" }
if ($preflightError) {
  Write-Warning $preflightError
  Write-Warning '选择已保存，但当前 Codex 模型目录尚不能启动全部所选模型。更新运行时或改回可用模型后再启动新任务。'
}
