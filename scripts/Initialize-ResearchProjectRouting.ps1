<#
.SYNOPSIS
  Adds or reconciles managed research routing files without overwriting conflicting user content.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$ProjectDirectory,
  [string]$RepositoryRoot = '',
  [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TemplateVersion = 'research-routing-v5'
$ManagedStart = '<!-- research-agent-routing:start -->'
$ManagedEnd = '<!-- research-agent-routing:end -->'
$Utf8NoBom = New-Object Text.UTF8Encoding($false)
$changes = New-Object Collections.Generic.List[string]
$conflicts = New-Object Collections.Generic.List[string]
$backedUpFiles = @{}

if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$RepositoryRoot = (Resolve-Path -LiteralPath $RepositoryRoot).ProviderPath
$ProjectDirectory = (Resolve-Path -LiteralPath $ProjectDirectory).ProviderPath
$TemplateRoot = Join-Path $RepositoryRoot 'project-template'
$ManagedRoot = Join-Path $ProjectDirectory '.research-agent'
$CandidateRoot = Join-Path $ManagedRoot 'candidates'
$BackupRoot = Join-Path $ManagedRoot 'backups'
$CanonicalRoutingPath = Join-Path $RepositoryRoot 'shared\MODEL_ROUTING.json'
if (-not (Test-Path -LiteralPath $CanonicalRoutingPath -PathType Leaf)) { throw "缺少 canonical 路由配置：$CanonicalRoutingPath" }
try { $CanonicalRouting = Get-Content -Raw -Encoding UTF8 -LiteralPath $CanonicalRoutingPath | ConvertFrom-Json }
catch { throw "canonical 路由配置无法解析：$($_.Exception.Message)" }
$CanonicalRoutingText = [IO.File]::ReadAllText($CanonicalRoutingPath)
$CanonicalRoutingHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $CanonicalRoutingPath).Hash
function Assert-HasProperties {
  param([object]$Object,[string]$Path,[string[]]$Names)
  if ($null -eq $Object) { throw "canonical contract missing object: $Path" }
  $actual = @($Object.PSObject.Properties.Name)
  foreach($name in $Names) {
    if ($name -notin $actual) { throw "canonical contract missing property: $Path.$name" }
  }
  $unexpected = @($actual | Where-Object { $_ -notin $Names })
  if ($unexpected.Count -gt 0) { throw "canonical contract has unexpected properties at ${Path}: $($unexpected -join ',')" }
}

function Assert-CanonicalRoutingContract {
  param([object]$Routing)
  Assert-HasProperties $Routing 'root' @('schema_version','configuration_version','model_mapping_version','provider','primary_surface','verified_with','workflow','runtime_preflight','runtime_dispatch','tiers','fallback','delegation','quality_gates')
  Assert-HasProperties $Routing.verified_with 'verified_with' @('command','codex_cli_version')
  Assert-HasProperties $Routing.workflow 'workflow' @('default','max_initial_blocking_questions','continue_low_risk_work_packages','sol_semantic_acceptance_when')
  Assert-HasProperties $Routing.runtime_preflight 'runtime_preflight' @('command','strategic_unavailable_status','support_or_economy_unavailable_status')
  Assert-HasProperties $Routing.runtime_dispatch 'runtime_dispatch' @('support_agent_type','economy_agent_type','fork_turns','preferred_call_shape','compatible_call_shape','isolated_call_shape','require_runtime_evidence','require_spawn_evidence','self_report_is_evidence','failure_status')
  Assert-HasProperties $Routing.tiers 'tiers' @('strategic','support','economy')
  foreach($tierName in @('strategic','support','economy')) {
    Assert-HasProperties $Routing.tiers.$tierName "tiers.$tierName" @('model','reasoning_effort','sandbox_mode','purpose')
  }
  Assert-HasProperties $Routing.fallback 'fallback' @('same_model_reasoning_tiers','status','when_support_or_economy_is_unavailable')
  Assert-HasProperties $Routing.delegation 'delegation' @('max_threads','max_depth','subagents_may_delegate','main_agent_reads_every_result','main_agent_final_review')
  Assert-HasProperties $Routing.quality_gates 'quality_gates' @('L0','L1','L2')

  if ([int]$Routing.schema_version -ne 2) { throw 'canonical contract requires schema_version=2' }
  if ([string]::IsNullOrWhiteSpace([string]$Routing.configuration_version) -or [string]::IsNullOrWhiteSpace([string]$Routing.model_mapping_version)) { throw 'canonical contract requires version fields' }
  if ([string]$Routing.provider -ne 'ChatGPT Windows desktop app and Codex' -or [string]$Routing.primary_surface -ne 'project-scoped .codex agents') { throw 'canonical provider/surface contract is invalid' }
  if ([string]$Routing.verified_with.command -ne 'codex debug models' -or [string]::IsNullOrWhiteSpace([string]$Routing.verified_with.codex_cli_version)) { throw 'canonical verification contract is invalid' }
  $acceptanceWhen = @($Routing.workflow.sol_semantic_acceptance_when)
  $expectedAcceptanceWhen = @('publication_or_submission','key_parameter_or_core_method','safety_or_high_cost_decision','scientific_final_acceptance')
  if ([string]$Routing.workflow.default -ne 'unified' -or [int]$Routing.workflow.max_initial_blocking_questions -lt 0 -or [int]$Routing.workflow.max_initial_blocking_questions -gt 2 -or -not [bool]$Routing.workflow.continue_low_risk_work_packages -or (($acceptanceWhen -join '|') -ne ($expectedAcceptanceWhen -join '|'))) { throw 'canonical workflow contract is invalid' }
  if ([string]$Routing.runtime_preflight.command -ne 'codex debug models' -or [string]$Routing.runtime_preflight.strategic_unavailable_status -ne 'blocked_model_catalog' -or [string]$Routing.runtime_preflight.support_or_economy_unavailable_status -ne 'degraded_sol_only') { throw 'canonical runtime_preflight contract is invalid' }
  if ([string]$Routing.runtime_dispatch.support_agent_type -ne 'research_support' -or [string]$Routing.runtime_dispatch.economy_agent_type -ne 'research_output' -or [string]$Routing.runtime_dispatch.fork_turns -ne 'none' -or [string]$Routing.runtime_dispatch.preferred_call_shape -ne 'agent_type' -or [string]$Routing.runtime_dispatch.compatible_call_shape -ne 'explicit_model' -or [string]$Routing.runtime_dispatch.isolated_call_shape -ne 'codex_exec' -or -not [bool]$Routing.runtime_dispatch.require_runtime_evidence -or -not [bool]$Routing.runtime_dispatch.require_spawn_evidence -or [bool]$Routing.runtime_dispatch.self_report_is_evidence -or [string]$Routing.runtime_dispatch.failure_status -ne 'degraded_sol_only') { throw 'canonical runtime_dispatch contract is invalid' }

  $expectedTierContract = @{
    strategic = @{ effort='xhigh'; sandbox='workspace-write' }
    support = @{ effort='medium'; sandbox='read-only' }
    economy = @{ effort='low'; sandbox='read-only' }
  }
  $models = New-Object Collections.Generic.List[string]
  foreach($tierName in @('strategic','support','economy')) {
    $tier = $Routing.tiers.$tierName
    if ([string]::IsNullOrWhiteSpace([string]$tier.model) -or [string]::IsNullOrWhiteSpace([string]$tier.purpose)) { throw "canonical tier is incomplete: $tierName" }
    if ([string]$tier.reasoning_effort -ne [string]$expectedTierContract[$tierName].effort -or [string]$tier.sandbox_mode -ne [string]$expectedTierContract[$tierName].sandbox) { throw "canonical tier safety contract is invalid: $tierName" }
    $models.Add([string]$tier.model)
  }
  if (@($models | Select-Object -Unique).Count -ne 3) { throw 'canonical routing models must be distinct' }
  if ([bool]$Routing.fallback.same_model_reasoning_tiers -or [string]$Routing.fallback.status -ne 'degraded_sol_only' -or [string]$Routing.fallback.when_support_or_economy_is_unavailable -ne 'return the bounded task to strategic Sol; do not substitute an unverified model') { throw 'canonical fallback contract is invalid' }
  if ([int]$Routing.delegation.max_threads -ne 2 -or [int]$Routing.delegation.max_depth -ne 1 -or [bool]$Routing.delegation.subagents_may_delegate -or -not [bool]$Routing.delegation.main_agent_reads_every_result -or -not [bool]$Routing.delegation.main_agent_final_review) { throw 'canonical delegation safety contract is invalid' }
  if ([string]$Routing.quality_gates.L0 -ne 'deterministic tool checks' -or [string]$Routing.quality_gates.L1 -ne 'read-only provenance and evidence-completeness checks' -or [string]$Routing.quality_gates.L2 -ne 'strategic scientific judgement and final acceptance') { throw 'canonical quality-gate contract is invalid' }
}

function Test-RoutingModelCatalog {
  param([object]$Routing)
  $availability = [ordered]@{ strategic=$false; support=$false; economy=$false }
  $unavailable = New-Object Collections.Generic.List[string]
  $command = Get-Command codex -ErrorAction SilentlyContinue
  if ($null -eq $command) {
    foreach($tierName in @('strategic','support','economy')) { $unavailable.Add($tierName) }
    return [pscustomobject]@{ Status='unavailable'; Command='codex debug models'; RoutingModels=$availability; UnavailableTiers=@($unavailable); Detail='codex command not found' }
  }
  try {
    $raw = @(& $command.Source debug models 2>$null) -join [Environment]::NewLine
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($raw)) { throw 'catalog command failed' }
    $catalog = $raw | ConvertFrom-Json
    $models = @($catalog.models)
    if ($models.Count -eq 0) { throw 'catalog is empty' }
    foreach($tierName in @('strategic','support','economy')) {
      $tier = $Routing.tiers.$tierName
      $matches = @($models | Where-Object { [string]$_.slug -ceq [string]$tier.model })
      if ($matches.Count -eq 1) {
        $efforts = @($matches[0].supported_reasoning_levels | ForEach-Object { [string]$_.effort })
        $availability[$tierName] = ([string]$tier.reasoning_effort -cin $efforts)
      }
      if (-not [bool]$availability[$tierName]) { $unavailable.Add($tierName) }
    }
    return [pscustomobject]@{ Status='verified'; Command='codex debug models'; RoutingModels=$availability; UnavailableTiers=@($unavailable); Detail='configured model/effort pairs checked' }
  }
  catch {
    foreach($tierName in @('strategic','support','economy')) { $unavailable.Add($tierName) }
    return [pscustomobject]@{ Status='unavailable'; Command='codex debug models'; RoutingModels=$availability; UnavailableTiers=@($unavailable); Detail='catalog command failed or returned invalid JSON' }
  }
}

Assert-CanonicalRoutingContract $CanonicalRouting
$ConfigurationVersion = [string]$CanonicalRouting.configuration_version
$ModelMappingVersion = [string]$CanonicalRouting.model_mapping_version
$MaxThreads = [int]$CanonicalRouting.delegation.max_threads
$MaxDepth = [int]$CanonicalRouting.delegation.max_depth
$StrategicModel = [string]$CanonicalRouting.tiers.strategic.model
$StrategicEffort = [string]$CanonicalRouting.tiers.strategic.reasoning_effort
$SupportAgentType = [string]$CanonicalRouting.runtime_dispatch.support_agent_type
$EconomyAgentType = [string]$CanonicalRouting.runtime_dispatch.economy_agent_type
$BlockedModelCatalogStatus = [string]$CanonicalRouting.runtime_preflight.strategic_unavailable_status
$DegradedStatus = [string]$CanonicalRouting.runtime_preflight.support_or_economy_unavailable_status
$CatalogCheck = Test-RoutingModelCatalog $CanonicalRouting

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

function Backup-ManagedFile {
  param([string]$Path,[string]$Name)
  $backupKey = [IO.Path]::GetFullPath($Path)
  if ($backedUpFiles.ContainsKey($backupKey)) { return }
  if (-not (Test-Path -LiteralPath $BackupRoot -PathType Container)) { New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null }
  $stamp = Get-Date -Format 'yyyyMMdd-HHmmssfff'
  Copy-Item -LiteralPath $Path -Destination (Join-Path $BackupRoot "$Name.$stamp.bak")
  $backedUpFiles[$backupKey] = $true
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
  if ($start -lt 0) { $updated = $text.TrimEnd("`r","`n") + $newline + $newline + $canonicalForFile + $newline }
  else { $updated = $text.Substring(0,$start) + $canonicalForFile + $text.Substring($end + $ManagedEnd.Length) }
  if ($updated -ne $text) {
    Write-Utf8Text $agentsPath $updated
    $changes.Add('AGENTS.md managed block')
  }
}

function Update-AgentConfig {
  $source = Join-Path $TemplateRoot '.codex\config.toml'
  $target = Join-Path $ProjectDirectory '.codex\config.toml'
  if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { Copy-IfMissing $source $target '.codex/config.toml created'; return }
  $text = [IO.File]::ReadAllText($target)
  $newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
  $sectionMatches = [regex]::Matches($text,'(?m)^\s*\[agents\]\s*$')
  if ($sectionMatches.Count -gt 1) { Add-Conflict '.codex/config.toml' '存在多个 [agents] 区块，无法安全合并' $source; return }
  $updated = $text
  $conflict = $false
  if ($sectionMatches.Count -eq 0) {
    $updated = $text.TrimEnd("`r","`n") + $newline + $newline + '[agents]' + $newline + "max_threads = $MaxThreads" + $newline + "max_depth = $MaxDepth" + $newline
  } else {
    $sectionStart = $sectionMatches[0].Index
    $afterHeader = $sectionStart + $sectionMatches[0].Length
    $nextSection = [regex]::Match($text.Substring($afterHeader),'(?m)^\s*\[[^\]]+\]\s*$')
    $sectionEnd = if ($nextSection.Success) { $afterHeader + $nextSection.Index } else { $text.Length }
    $body = $text.Substring($afterHeader,$sectionEnd-$afterHeader)
    $missing = New-Object Collections.Generic.List[string]
    foreach($item in @(@{Name='max_threads';Value=[string]$MaxThreads},@{Name='max_depth';Value=[string]$MaxDepth})) {
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
    Backup-ManagedFile $target 'config.toml'
    Write-Utf8Text $target $updated
    $changes.Add('.codex/config.toml merged')
  }
}

function Update-ExecutableAgentConfig {
  $source = Join-Path $TemplateRoot '.codex\config.toml'
  $target = Join-Path $ProjectDirectory '.codex\config.toml'
  if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { return }
  $raw = [IO.File]::ReadAllText($target)
  if (@($conflicts | Where-Object { $_ -like '.codex/config.toml：*' }).Count -gt 0) { return }
  $newline = if ($raw.Contains("`r`n")) { "`r`n" } else { "`n" }
  $text = $raw -replace "`r`n","`n"
  $changed = $false
  $localConflict = $false

  $firstSection = [regex]::Match($text,'(?m)^\s*\[')
  $prefixEnd = if ($firstSection.Success) { $firstSection.Index } else { $text.Length }
  $prefix = $text.Substring(0,$prefixEnd)
  $prepend = New-Object Collections.Generic.List[string]
  foreach($item in @(
    @{Name='model';Value='"' + $StrategicModel + '"'},
    @{Name='model_reasoning_effort';Value='"' + $StrategicEffort + '"'}
  )) {
    $match = [regex]::Match($prefix,('(?m)^\s*{0}\s*=\s*([^#\r\n]+)' -f [regex]::Escape([string]$item.Name)))
    if (-not $match.Success) { $prepend.Add("$($item.Name) = $($item.Value)"); continue }
    if ($match.Groups[1].Value.Trim() -ne $item.Value) {
      $localConflict = $true
      $conflicts.Add(".codex/config.toml：$($item.Name) 期望 $($item.Value)，现有值 $($match.Groups[1].Value.Trim())")
      Write-Warning ".codex/config.toml：$($item.Name) 与托管路由冲突。未覆盖现有值。"
    }
  }
  if ($prepend.Count -gt 0) { $text = ($prepend -join "`n") + "`n`n" + $text; $changed = $true }

  $features = [regex]::Match($text,'(?m)^\s*\[features\]\s*$')
  if (-not $features.Success) {
    $text = $text.TrimEnd("`n") + "`n`n[features]`nmulti_agent = true`n"
    $changed = $true
  } else {
    $after = $features.Index + $features.Length
    $next = [regex]::Match($text.Substring($after),'(?m)^\s*\[[^\]]+\]\s*$')
    $end = if ($next.Success) { $after + $next.Index } else { $text.Length }
    $body = $text.Substring($after,$end-$after)
    $setting = [regex]::Match($body,'(?m)^\s*multi_agent\s*=\s*([^#\r\n]+)')
    if (-not $setting.Success) { $text = $text.Substring(0,$end).TrimEnd("`n") + "`nmulti_agent = true`n" + $text.Substring($end); $changed = $true }
    elseif ($setting.Groups[1].Value.Trim() -ne 'true') {
      $localConflict = $true
      $conflicts.Add('.codex/config.toml：features.multi_agent 期望 true')
      Write-Warning '.codex/config.toml：features.multi_agent 与托管路由冲突。未覆盖现有值。'
    }
  }

  foreach($role in @(
    @{Name=$SupportAgentType;File='agents/research-support.toml';Description='Read-only Terra worker for bounded evidence work.'},
    @{Name=$EconomyAgentType;File='agents/research-output.toml';Description='Read-only Luna worker for locked-package writing.'}
  )) {
    $header = '[agents.' + [string]$role.Name + ']'
    $match = [regex]::Match($text,('(?m)^\s*\[agents\.{0}\]\s*$' -f [regex]::Escape([string]$role.Name)))
    if (-not $match.Success) {
      $text = $text.TrimEnd("`n") + "`n`n$header`ndescription = `"$($role.Description)`"`nconfig_file = `"$($role.File)`"`n"
      $changed = $true
      continue
    }
    $after = $match.Index + $match.Length
    $next = [regex]::Match($text.Substring($after),'(?m)^\s*\[[^\]]+\]\s*$')
    $end = if ($next.Success) { $after + $next.Index } else { $text.Length }
    $body = $text.Substring($after,$end-$after)
    $configFile = [regex]::Match($body,'(?m)^\s*config_file\s*=\s*"([^"]+)"')
    if (-not $configFile.Success) { $text = $text.Substring(0,$end).TrimEnd("`n") + "`nconfig_file = `"$($role.File)`"`n" + $text.Substring($end); $changed = $true }
    elseif ($configFile.Groups[1].Value -ne [string]$role.File) {
      $localConflict = $true
      $conflicts.Add(".codex/config.toml：$header.config_file 期望 $($role.File)，现有值 $($configFile.Groups[1].Value)")
      Write-Warning ".codex/config.toml：$header.config_file 与托管路由冲突。未覆盖现有值。"
    }
  }

  if ($localConflict) { Add-Conflict '.codex/config.toml' '可执行模型或 Agent 注册存在冲突' $source }
  $updated = $text -replace "`n",$newline
  if (-not $localConflict -and $changed -and $updated -ne $raw) {
    Backup-ManagedFile $target 'config.toml'
    Write-Utf8Text $target $updated
    $changes.Add('.codex/config.toml executable routing merged')
  }
}

function Test-AgentFile {
  param([string]$Text,[string]$Name,[string]$Model,[string]$Effort,[string]$Sandbox)
  return $Text -match ('(?m)^name\s*=\s*"{0}"\s*$' -f [regex]::Escape($Name)) -and
    $Text -match ('(?m)^model\s*=\s*"{0}"\s*$' -f [regex]::Escape($Model)) -and
    $Text -match ('(?m)^model_reasoning_effort\s*=\s*"{0}"\s*$' -f [regex]::Escape($Effort)) -and
    $Text -match ('(?m)^sandbox_mode\s*=\s*"{0}"\s*$' -f [regex]::Escape($Sandbox))
}

function Test-CompatibleRoutingSnapshot {
  param([string]$Path)
  try { $snapshot = Get-Content -Raw -Encoding UTF8 -LiteralPath $Path | ConvertFrom-Json } catch { return $false }
  foreach($tier in @('strategic','support','economy')) {
    if ([string]$snapshot.tiers.$tier.model -ne [string]$CanonicalRouting.tiers.$tier.model) { return $false }
    if ([string]$snapshot.tiers.$tier.reasoning_effort -ne [string]$CanonicalRouting.tiers.$tier.reasoning_effort) { return $false }
  }
  foreach($tier in @('support','economy')) {
    if ([string]$snapshot.tiers.$tier.sandbox_mode -ne 'read-only') { return $false }
  }
  $threadsProperty = $snapshot.delegation.PSObject.Properties['max_threads']
  if ($null -eq $threadsProperty -or [int]$threadsProperty.Value -ne $MaxThreads) { return $false }
  $depthProperty = $snapshot.delegation.PSObject.Properties['max_depth']
  if ($null -eq $depthProperty -or [int]$depthProperty.Value -ne $MaxDepth) { return $false }
  return -not [bool]$snapshot.delegation.subagents_may_delegate -and [bool]$snapshot.delegation.main_agent_final_review -and [string]$snapshot.runtime_dispatch.support_agent_type -eq 'research_support' -and [string]$snapshot.runtime_dispatch.economy_agent_type -eq 'research_output' -and [string]$snapshot.runtime_dispatch.fork_turns -eq 'none' -and [string]$snapshot.runtime_dispatch.preferred_call_shape -eq 'agent_type' -and [string]$snapshot.runtime_dispatch.compatible_call_shape -eq 'explicit_model' -and [string]$snapshot.runtime_dispatch.isolated_call_shape -eq 'codex_exec' -and [bool]$snapshot.runtime_dispatch.require_runtime_evidence -and [bool]$snapshot.runtime_dispatch.require_spawn_evidence -and -not [bool]$snapshot.runtime_dispatch.self_report_is_evidence
}

Update-AgentConfig
Update-ExecutableAgentConfig

foreach($agent in @(
  @{File='research-support.toml';Name='research_support';Tier='support'},
  @{File='research-output.toml';Name='research_output';Tier='economy'}
)) {
  $tier = $CanonicalRouting.tiers.($agent.Tier)
  $relative = '.codex/agents/' + $agent.File
  $source = Join-Path $TemplateRoot ('.codex\agents\' + $agent.File)
  $target = Join-Path $ProjectDirectory ('.codex\agents\' + $agent.File)
  if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { Copy-IfMissing $source $target "$relative created"; continue }
  $text = [IO.File]::ReadAllText($target)
  if (-not (Test-AgentFile $text $agent.Name ([string]$tier.model) ([string]$tier.reasoning_effort) ([string]$tier.sandbox_mode))) { Add-Conflict $relative '模型、reasoning 或只读边界与 canonical 配置不一致' $source }
}

$routingTarget = Join-Path $ManagedRoot 'MODEL_ROUTING.json'
if (-not (Test-Path -LiteralPath $routingTarget -PathType Leaf)) { Copy-IfMissing $CanonicalRoutingPath $routingTarget '.research-agent/MODEL_ROUTING.json created' }
elseif ((Get-FileHash -Algorithm SHA256 -LiteralPath $routingTarget).Hash -ne $CanonicalRoutingHash) {
  if (Test-CompatibleRoutingSnapshot $routingTarget) {
    Backup-ManagedFile $routingTarget 'MODEL_ROUTING.json'
    Write-Utf8Text $routingTarget $CanonicalRoutingText
    $changes.Add('.research-agent/MODEL_ROUTING.json canonicalized')
  } else { Add-Conflict '.research-agent/MODEL_ROUTING.json' '项目路由快照与 canonical 配置冲突' $CanonicalRoutingPath }
}
$ProjectRoutingHash = if (Test-Path -LiteralPath $routingTarget -PathType Leaf) { (Get-FileHash -Algorithm SHA256 -LiteralPath $routingTarget).Hash } else { '' }

$markdownSource = Join-Path $TemplateRoot '.research-agent\MODEL_ROUTING.md'
$markdownTarget = Join-Path $ManagedRoot 'MODEL_ROUTING.md'
if (-not (Test-Path -LiteralPath $markdownTarget -PathType Leaf)) { Copy-IfMissing $markdownSource $markdownTarget '.research-agent/MODEL_ROUTING.md created' }
elseif ([IO.File]::ReadAllText($markdownSource) -ne [IO.File]::ReadAllText($markdownTarget)) { Add-Conflict '.research-agent/MODEL_ROUTING.md' '项目路由说明与当前模板不一致' $markdownSource }

Update-AgentsManagedBlock

$reportPath = Join-Path $ManagedRoot 'routing-conflicts.md'
if ($conflicts.Count -gt 0) {
  $report = @('# Research Agent Routing Conflicts','','启动器未覆盖以下现有配置：','') + @($conflicts | ForEach-Object { '- ' + $_ })
  [void](Write-IfChanged $reportPath (($report -join "`r`n") + "`r`n"))
} elseif (Test-Path -LiteralPath $reportPath -PathType Leaf) {
  Remove-Item -LiteralPath $reportPath -Force
  $changes.Add('.research-agent/routing-conflicts.md cleared')
}

$versionPath = Join-Path $ManagedRoot 'routing-version.json'
$versionCurrent = $null
if (Test-Path -LiteralPath $versionPath -PathType Leaf) {
  try { $versionCurrent = Get-Content -Raw -Encoding UTF8 -LiteralPath $versionPath | ConvertFrom-Json } catch { $versionCurrent = $null }
}
$UnavailableTiers = @($CatalogCheck.UnavailableTiers)
if (-not [bool]$CatalogCheck.RoutingModels.strategic) { $status = $BlockedModelCatalogStatus }
elseif ($conflicts.Count -gt 0) { $status = 'blocked_conflict' }
elseif ($UnavailableTiers.Count -gt 0) { $status = $DegradedStatus }
else { $status = 'ready' }
$launchAllowed = $status -in @('ready',$DegradedStatus)
$versionMatches = $false
if ($null -ne $versionCurrent) {
  try {
    $versionMatches =
      [string]$versionCurrent.status -eq $status -and
      [string]$versionCurrent.configuration_version -eq $ConfigurationVersion -and
      [string]$versionCurrent.model_mapping_version -eq $ModelMappingVersion -and
      [string]$versionCurrent.template_version -eq $TemplateVersion -and
      [string]$versionCurrent.canonical_sha256 -eq $CanonicalRoutingHash -and
      [string]$versionCurrent.snapshot_sha256 -eq $ProjectRoutingHash -and
      [int]$versionCurrent.conflict_count -eq $conflicts.Count -and
      [string]$versionCurrent.catalog.status -eq [string]$CatalogCheck.Status -and
      [string]$versionCurrent.catalog.command -eq [string]$CatalogCheck.Command -and
      [string]$versionCurrent.catalog.detail -eq [string]$CatalogCheck.Detail -and
      [bool]$versionCurrent.catalog.routing_models.strategic -eq [bool]$CatalogCheck.RoutingModels.strategic -and
      [bool]$versionCurrent.catalog.routing_models.support -eq [bool]$CatalogCheck.RoutingModels.support -and
      [bool]$versionCurrent.catalog.routing_models.economy -eq [bool]$CatalogCheck.RoutingModels.economy -and
      ((@($versionCurrent.unavailable_tiers) -join '|') -eq ($UnavailableTiers -join '|')) -and
      ((-not $launchAllowed) -or -not [string]::IsNullOrWhiteSpace([string]$versionCurrent.last_completed_at))
  } catch { $versionMatches = $false }
}
if (-not $versionMatches -or $changes.Count -gt 0) {
  $now = (Get-Date).ToUniversalTime().ToString('o')
  $version = [ordered]@{
    status = $status
    configuration_version = $ConfigurationVersion
    model_mapping_version = $ModelMappingVersion
    template_version = $TemplateVersion
    canonical_sha256 = $CanonicalRoutingHash
    snapshot_sha256 = $ProjectRoutingHash
    schema_version = [int]$CanonicalRouting.schema_version
    conflict_count = $conflicts.Count
    catalog = [ordered]@{
      status = [string]$CatalogCheck.Status
      command = [string]$CatalogCheck.Command
      routing_models = [ordered]@{
        strategic = [bool]$CatalogCheck.RoutingModels.strategic
        support = [bool]$CatalogCheck.RoutingModels.support
        economy = [bool]$CatalogCheck.RoutingModels.economy
      }
      detail = [string]$CatalogCheck.Detail
    }
    unavailable_tiers = @($UnavailableTiers)
    last_checked_at = $now
    last_completed_at = if($launchAllowed){$now}else{$null}
  }
  Write-Utf8Text $versionPath (($version | ConvertTo-Json -Depth 5) + [Environment]::NewLine)
  $changes.Add('.research-agent/routing-version.json updated')
}

if (-not $Quiet) {
  Write-Output "ROUTING_PREFLIGHT status=$status catalog=$($CatalogCheck.Status) unavailable=$($UnavailableTiers -join ',') changes=$($changes.Count) conflicts=$($conflicts.Count)"
  foreach($change in $changes) { Write-Output "ROUTING_CHANGE $change" }
}
if ($status -eq $BlockedModelCatalogStatus) { throw "ROUTING_BLOCKED_MODEL_CATALOG catalog=$($CatalogCheck.Status) unavailable=$($UnavailableTiers -join ',')" }
if ($conflicts.Count -gt 0) { throw "ROUTING_BLOCKED_CONFLICT count=$($conflicts.Count); resolve routing-conflicts.md and retry." }
