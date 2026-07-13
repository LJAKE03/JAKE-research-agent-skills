<#
.SYNOPSIS
  Adds or reconciles managed research routing files without overwriting user content.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$ProjectDirectory,
  [string]$RepositoryRoot = '',
  [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ConfigurationVersion = '1.0.0'
$ModelMappingVersion = 'sol-terra-luna-v1'
$TemplateVersion = 'research-routing-v1'
$ManagedStart = '<!-- research-agent-routing:start -->'
$ManagedEnd = '<!-- research-agent-routing:end -->'
$Utf8NoBom = New-Object Text.UTF8Encoding($false)
$changes = New-Object Collections.Generic.List[string]
$conflicts = New-Object Collections.Generic.List[string]

if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$RepositoryRoot = (Resolve-Path -LiteralPath $RepositoryRoot).ProviderPath
$ProjectDirectory = (Resolve-Path -LiteralPath $ProjectDirectory).ProviderPath
$TemplateRoot = Join-Path $RepositoryRoot 'project-template'
$ManagedRoot = Join-Path $ProjectDirectory '.research-agent'
$CandidateRoot = Join-Path $ManagedRoot 'candidates'
$BackupRoot = Join-Path $ManagedRoot 'backups'

function Write-Utf8Text {
  param([string]$Path,[string]$Text)
  $parent = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
  [IO.File]::WriteAllText($Path,$Text,$Utf8NoBom)
}

function Write-IfChanged {
  param([string]$Path,[string]$Text)
  if ((Test-Path -LiteralPath $Path -PathType Leaf) -and ([IO.File]::ReadAllText($Path) -eq $Text)) { return $false }
  Write-Utf8Text $Path $Text
  return $true
}

function Copy-IfMissing {
  param([string]$Source,[string]$Target,[string]$Label)
  if (Test-Path -LiteralPath $Target -PathType Leaf) { return }
  $parent = Split-Path -Parent $Target
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
  Copy-Item -LiteralPath $Source -Destination $Target
  $changes.Add($Label)
}

function Add-Conflict {
  param([string]$RelativePath,[string]$Message,[string]$CandidateSource)
  if (-not (Test-Path -LiteralPath $CandidateRoot -PathType Container)) { New-Item -ItemType Directory -Path $CandidateRoot -Force | Out-Null }
  $candidateName = ($RelativePath -replace '[\\/]', '__') + '.candidate'
  $candidatePath = Join-Path $CandidateRoot $candidateName
  $candidateText = [IO.File]::ReadAllText($CandidateSource)
  [void](Write-IfChanged $candidatePath $candidateText)
  $conflicts.Add("$RelativePath：$Message；候选文件 .research-agent/candidates/$candidateName")
  Write-Warning "$RelativePath：$Message。未覆盖现有文件。"
}

function Get-CanonicalManagedBlock {
  $templateAgents = Join-Path $TemplateRoot 'AGENTS.md'
  $text = [IO.File]::ReadAllText($templateAgents)
  $start = $text.IndexOf($ManagedStart,[StringComparison]::Ordinal)
  $end = $text.IndexOf($ManagedEnd,[StringComparison]::Ordinal)
  if ($start -lt 0 -or $end -lt $start) { throw 'project-template/AGENTS.md 缺少完整托管区块。' }
  return $text.Substring($start,$end + $ManagedEnd.Length - $start)
}

function Update-AgentsManagedBlock {
  $agentsPath = Join-Path $ProjectDirectory 'AGENTS.md'
  $canonical = Get-CanonicalManagedBlock
  if (-not (Test-Path -LiteralPath $agentsPath -PathType Leaf)) {
    Write-Utf8Text $agentsPath ($canonical + [Environment]::NewLine)
    $changes.Add('AGENTS.md created')
    return
  }
  $text = [IO.File]::ReadAllText($agentsPath)
  $start = $text.IndexOf($ManagedStart,[StringComparison]::Ordinal)
  $lastStart = $text.LastIndexOf($ManagedStart,[StringComparison]::Ordinal)
  $end = $text.IndexOf($ManagedEnd,[StringComparison]::Ordinal)
  $lastEnd = $text.LastIndexOf($ManagedEnd,[StringComparison]::Ordinal)
  if (($start -lt 0) -xor ($end -lt 0) -or $start -ne $lastStart -or $end -ne $lastEnd -or $end -lt $start) {
    Add-Conflict 'AGENTS.md' '托管区块标记不完整或重复' (Join-Path $TemplateRoot 'AGENTS.md')
    return
  }
  $newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
  $canonicalForFile = $canonical -replace "`r?`n",$newline
  if ($start -lt 0) {
    $updated = $text.TrimEnd("`r","`n") + $newline + $newline + $canonicalForFile + $newline
  } else {
    $updated = $text.Substring(0,$start) + $canonicalForFile + $text.Substring($end + $ManagedEnd.Length)
  }
  if ($updated -ne $text) {
    Write-Utf8Text $agentsPath $updated
    $changes.Add('AGENTS.md managed block')
  }
}

function Update-AgentConfig {
  $source = Join-Path $TemplateRoot '.codex\config.toml'
  $target = Join-Path $ProjectDirectory '.codex\config.toml'
  if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
    Copy-IfMissing $source $target '.codex/config.toml created'
    return
  }
  $text = [IO.File]::ReadAllText($target)
  $newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
  $sectionMatches = [regex]::Matches($text,'(?m)^\s*\[agents\]\s*$')
  if ($sectionMatches.Count -gt 1) {
    Add-Conflict '.codex/config.toml' '存在多个 [agents] 区块，无法安全合并' $source
    return
  }
  $updated = $text
  $conflict = $false
  if ($sectionMatches.Count -eq 0) {
    $updated = $text.TrimEnd("`r","`n") + $newline + $newline + '[agents]' + $newline + 'max_threads = 2' + $newline + 'max_depth = 1' + $newline
  } else {
    $sectionStart = $sectionMatches[0].Index
    $afterHeader = $sectionStart + $sectionMatches[0].Length
    $nextSection = [regex]::Match($text.Substring($afterHeader),'(?m)^\s*\[[^\]]+\]\s*$')
    $sectionEnd = if ($nextSection.Success) { $afterHeader + $nextSection.Index } else { $text.Length }
    $body = $text.Substring($afterHeader,$sectionEnd-$afterHeader)
    $missing = New-Object Collections.Generic.List[string]
    foreach($item in @(@{Name='max_threads';Value='2'},@{Name='max_depth';Value='1'})) {
      $pattern = '(?m)^\s*{0}\s*=\s*([^#\r\n]+)' -f [regex]::Escape([string]$item.Name)
      $match = [regex]::Match($body,$pattern)
      if (-not $match.Success) { $missing.Add("$($item.Name) = $($item.Value)"); continue }
      if ($match.Groups[1].Value.Trim() -ne $item.Value) {
        $conflict = $true
        $conflicts.Add(".codex/config.toml：$($item.Name) 期望 $($item.Value)，现有值 $($match.Groups[1].Value.Trim())")
        Write-Warning ".codex/config.toml：$($item.Name) 与托管值冲突。未覆盖现有值。"
      }
    }
    if ($missing.Count -gt 0) {
      $insert = $newline + (($missing.ToArray()) -join $newline) + $newline
      $updated = $text.Substring(0,$sectionEnd).TrimEnd("`r","`n") + $insert + $text.Substring($sectionEnd)
    }
  }
  if ($conflict) { Add-Conflict '.codex/config.toml' '必要字段存在冲突' $source }
  if ($updated -ne $text) {
    if (-not (Test-Path -LiteralPath $BackupRoot -PathType Container)) { New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmssfff'
    Copy-Item -LiteralPath $target -Destination (Join-Path $BackupRoot "config.toml.$stamp.bak")
    Write-Utf8Text $target $updated
    $changes.Add('.codex/config.toml merged')
  }
}

function Test-AgentFile {
  param([string]$Text,[string]$Name,[string]$Model,[string]$Effort)
  return $Text -match ('(?m)^name\s*=\s*"{0}"\s*$' -f [regex]::Escape($Name)) -and
    $Text -match ('(?m)^model\s*=\s*"{0}"\s*$' -f [regex]::Escape($Model)) -and
    $Text -match ('(?m)^model_reasoning_effort\s*=\s*"{0}"\s*$' -f [regex]::Escape($Effort)) -and
    $Text -match '(?m)^sandbox_mode\s*=\s*"read-only"\s*$'
}

Update-AgentConfig

foreach($agent in @(
  @{File='research-support.toml';Name='research_support';Model='gpt-5.6-terra';Effort='medium'},
  @{File='research-output.toml';Name='research_output';Model='gpt-5.6-luna';Effort='low'}
)) {
  $relative = '.codex/agents/' + $agent.File
  $source = Join-Path $TemplateRoot ('.codex\agents\' + $agent.File)
  $target = Join-Path $ProjectDirectory ('.codex\agents\' + $agent.File)
  if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { Copy-IfMissing $source $target "$relative created"; continue }
  $text = [IO.File]::ReadAllText($target)
  if (-not (Test-AgentFile $text $agent.Name $agent.Model $agent.Effort)) { Add-Conflict $relative '模型、reasoning 或只读边界与托管配置不一致' $source }
}

foreach($file in @('MODEL_ROUTING.json','MODEL_ROUTING.md')) {
  $source = Join-Path $TemplateRoot ('.research-agent\' + $file)
  $target = Join-Path $ManagedRoot $file
  if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { Copy-IfMissing $source $target ".research-agent/$file created"; continue }
  if ([IO.File]::ReadAllText($source) -ne [IO.File]::ReadAllText($target)) { Add-Conflict ".research-agent/$file" '项目路由副本与当前模板不一致' $source }
}

Update-AgentsManagedBlock

$reportPath = Join-Path $ManagedRoot 'routing-conflicts.md'
if ($conflicts.Count -gt 0) {
  $report = @('# Research Agent Routing Conflicts','','启动器未覆盖以下现有配置：','') + @($conflicts | ForEach-Object { '- ' + $_ })
  [void](Write-IfChanged $reportPath (($report -join "`r`n") + "`r`n"))
}

$versionPath = Join-Path $ManagedRoot 'routing-version.json'
$versionCurrent = $null
if (Test-Path -LiteralPath $versionPath -PathType Leaf) {
  try { $versionCurrent = Get-Content -Raw -Encoding UTF8 -LiteralPath $versionPath | ConvertFrom-Json } catch { $versionCurrent = $null }
}
$versionMatches = $null -ne $versionCurrent -and
  [string]$versionCurrent.configuration_version -eq $ConfigurationVersion -and
  [string]$versionCurrent.model_mapping_version -eq $ModelMappingVersion -and
  [string]$versionCurrent.template_version -eq $TemplateVersion -and
  -not [string]::IsNullOrWhiteSpace([string]$versionCurrent.last_completed_at)
if (-not $versionMatches -or $changes.Count -gt 0) {
  $version = [ordered]@{
    configuration_version = $ConfigurationVersion
    model_mapping_version = $ModelMappingVersion
    template_version = $TemplateVersion
    last_completed_at = (Get-Date).ToUniversalTime().ToString('o')
  }
  Write-Utf8Text $versionPath (($version | ConvertTo-Json -Depth 3) + "`r`n")
  if ($changes -notcontains '.research-agent/routing-version.json updated') { $changes.Add('.research-agent/routing-version.json updated') }
}

if (-not $Quiet) {
  Write-Output "ROUTING_PREFLIGHT changes=$($changes.Count) warnings=$($conflicts.Count)"
  foreach($change in $changes) { Write-Output "ROUTING_CHANGE $change" }
}
