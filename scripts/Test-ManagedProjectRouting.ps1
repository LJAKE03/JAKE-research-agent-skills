<#
.SYNOPSIS
  End-to-end tests for managed routing propagation to new and existing projects.
#>
[CmdletBinding()]
param(
  [string]$SourceRoot = '',
  [string]$UserSkillsRoot = (Join-Path $env:USERPROFILE '.agents\skills')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($SourceRoot)) { $SourceRoot = Split-Path -Parent $PSScriptRoot }
$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).ProviderPath
$initializer = Join-Path $SourceRoot 'scripts\Initialize-ResearchProjectRouting.ps1'
$launcher = Join-Path $SourceRoot 'scripts\Start-ResearchAgent.ps1'
$creator = Join-Path $SourceRoot 'scripts\New-ResearchProject.ps1'
$tempParent = Join-Path ([IO.Path]::GetTempPath()) 'research-agent-managed-tests'
$testRoot = Join-Path $tempParent ([Guid]::NewGuid().ToString('N'))
$unicode = ([string][char]0x79D1) + ([string][char]0x7814)

function Assert-Test {
  param([bool]$Condition,[string]$Message)
  if (-not $Condition) { throw "FAIL $Message" }
  Write-Output "PASS $Message"
}

function Write-TestText {
  param([string]$Path,[string]$Text)
  $parent = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
  [IO.File]::WriteAllText($Path,$Text,(New-Object Text.UTF8Encoding($false)))
}

function Get-TreeSnapshot {
  param([string]$Root)
  return @(Get-ChildItem -LiteralPath $Root -Recurse -File | Sort-Object FullName | ForEach-Object {
    $relative = $_.FullName.Substring($Root.Length).TrimStart('\')
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
    "$relative=$hash"
  }) -join "`n"
}

$failure = $null
$cleanupPass = $false
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
try {
  Assert-Test (-not $testRoot.StartsWith($SourceRoot,[StringComparison]::OrdinalIgnoreCase)) 'temporary root is outside repository'

  $destination = Join-Path $testRoot ($unicode + ' projects with spaces')
  New-Item -ItemType Directory -Path $destination | Out-Null
  $projectName = $unicode + ' new project'
  $null = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $creator -ProjectName $projectName -Destination $destination
  Assert-Test ($LASTEXITCODE -eq 0) 'new project command exits zero'
  $newProject = Join-Path $destination $projectName
  foreach($relative in @(
    '.codex\config.toml',
    '.codex\agents\research-support.toml',
    '.codex\agents\research-output.toml',
    '.research-agent\MODEL_ROUTING.json',
    '.research-agent\MODEL_ROUTING.md',
    '.research-agent\routing-version.json'
  )) { Assert-Test (Test-Path -LiteralPath (Join-Path $newProject $relative) -PathType Leaf) "new project contains $relative" }

  $config = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $newProject '.codex\config.toml')
  Assert-Test ($config -match '(?m)^max_threads\s*=\s*2\s*$') 'new project max_threads=2'
  Assert-Test ($config -match '(?m)^max_depth\s*=\s*1\s*$') 'new project max_depth=1'
  $support = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $newProject '.codex\agents\research-support.toml')
  $output = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $newProject '.codex\agents\research-output.toml')
  Assert-Test ($support -match '(?m)^model\s*=\s*"gpt-5\.6-terra"\s*$' -and $support -match '(?m)^model_reasoning_effort\s*=\s*"medium"\s*$') 'support uses Terra medium'
  Assert-Test ($output -match '(?m)^model\s*=\s*"gpt-5\.6-luna"\s*$' -and $output -match '(?m)^model_reasoning_effort\s*=\s*"low"\s*$') 'economy uses Luna low'
  Assert-Test ($support -match '(?m)^sandbox_mode\s*=\s*"read-only"\s*$' -and $output -match '(?m)^sandbox_mode\s*=\s*"read-only"\s*$') 'both agents are read-only'
  $routing = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $newProject '.research-agent\MODEL_ROUTING.json') | ConvertFrom-Json
  Assert-Test (-not [bool]$routing.delegation.subagents_may_delegate -and [bool]$routing.delegation.main_agent_final_review) 'delegation and final-review boundaries'
  $agents = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $newProject 'AGENTS.md')
  foreach($token in @('Codex','PowerShell','Python','`rg`','`git diff`','max_threads=2','max_depth=1','research-agent-routing:start','research-agent-routing:end')) {
    Assert-Test ($agents.Contains($token)) "AGENTS contains $token"
  }

  $skillNames = @('00-research-orchestrator','01-requirement-elicitation','02-research-reconnaissance','03-stage-planning-execution','04-literature-review','05-academic-writing','06-quality-gate')
  foreach($name in $skillNames) {
    $skillPath = Join-Path $SourceRoot "$name\SKILL.md"
    $skillText = Get-Content -Raw -Encoding UTF8 -LiteralPath $skillPath
    Assert-Test ($skillText.Contains('routing-preflight:required') -and $skillText.Contains('../shared/MODEL_ROUTING.json')) "$name has routing preflight"
    Assert-Test (Test-Path -LiteralPath (Join-Path (Split-Path -Parent $skillPath) '..\shared\MODEL_ROUTING.json') -PathType Leaf) "$name relative routing reference resolves"
  }
  foreach($relative in @('.research-agent\MODEL_ROUTING.json','.research-agent\MODEL_ROUTING.md')) {
    Assert-Test (Test-Path -LiteralPath (Join-Path $newProject $relative) -PathType Leaf) "project relative reference resolves $relative"
  }

  $existing = Join-Path $testRoot ($unicode + ' existing project')
  New-Item -ItemType Directory -Path $existing | Out-Null
  Write-TestText (Join-Path $existing 'AGENTS.md') "# User project`r`n`r`nUSER_SECTION_KEEP`r`n"
  Write-TestText (Join-Path $existing 'PROJECT_STATE.md') "status: keep`r`n"
  Write-TestText (Join-Path $existing '.codex\config.toml') "# USER_CONFIG_KEEP`r`n[features]`r`ncustom_feature = true`r`n`r`n[agents]`r`nmax_threads = 2`r`n"
  $null = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $launcher -RepositoryRoot $SourceRoot -NoGui -RoutingPreflightOnly -RoutingProjectDirectory $existing
  Assert-Test ($LASTEXITCODE -eq 0) 'launcher existing-project preflight exits zero'
  $existingConfig = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $existing '.codex\config.toml')
  Assert-Test ($existingConfig.Contains('USER_CONFIG_KEEP') -and $existingConfig.Contains('custom_feature = true')) 'existing config content preserved'
  Assert-Test ($existingConfig -match '(?m)^max_depth\s*=\s*1\s*$') 'missing config field added'
  Assert-Test (@(Get-ChildItem -LiteralPath (Join-Path $existing '.research-agent\backups') -Filter 'config.toml.*.bak').Count -eq 1) 'config backup created before merge'
  $existingAgents = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $existing 'AGENTS.md')
  Assert-Test ($existingAgents.Contains('USER_SECTION_KEEP')) 'user AGENTS content preserved'
  Assert-Test ([regex]::Matches($existingAgents,'research-agent-routing:start').Count -eq 1) 'managed AGENTS block appended once'
  $beforeRepeat = Get-TreeSnapshot $existing
  $null = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $launcher -RepositoryRoot $SourceRoot -NoGui -RoutingPreflightOnly -RoutingProjectDirectory $existing
  Assert-Test ($LASTEXITCODE -eq 0) 'repeated launcher preflight exits zero'
  $afterRepeat = Get-TreeSnapshot $existing
  Assert-Test ($beforeRepeat -eq $afterRepeat) 'repeated preflight is idempotent'

  $conflictProject = Join-Path $testRoot 'conflict project'
  New-Item -ItemType Directory -Path $conflictProject | Out-Null
  Write-TestText (Join-Path $conflictProject 'AGENTS.md') "# Conflict project`r`n"
  Write-TestText (Join-Path $conflictProject 'PROJECT_STATE.md') "status: keep`r`n"
  Write-TestText (Join-Path $conflictProject '.codex\config.toml') "# CONFLICT_CONFIG_KEEP`r`n[agents]`r`nmax_threads = 9`r`nmax_depth = 1`r`n"
  Write-TestText (Join-Path $conflictProject '.codex\agents\research-support.toml') "name = `"research_support`"`r`nmodel = `"gpt-5.6-sol`"`r`nmodel_reasoning_effort = `"high`"`r`nsandbox_mode = `"workspace-write`"`r`n"
  $configHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $conflictProject '.codex\config.toml')).Hash
  $agentHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $conflictProject '.codex\agents\research-support.toml')).Hash
  $conflictOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $launcher -RepositoryRoot $SourceRoot -NoGui -RoutingPreflightOnly -RoutingProjectDirectory $conflictProject 2>&1) -join "`n"
  Assert-Test ($LASTEXITCODE -eq 0) 'launcher conflict preflight exits zero'
  Assert-Test ($conflictOutput -match 'WARNING') 'conflict emits WARNING'
  Assert-Test ((Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $conflictProject '.codex\config.toml')).Hash -eq $configHash) 'conflicting config is not overwritten'
  Assert-Test ((Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $conflictProject '.codex\agents\research-support.toml')).Hash -eq $agentHash) 'conflicting agent is not overwritten'
  Assert-Test (Test-Path -LiteralPath (Join-Path $conflictProject '.research-agent\routing-conflicts.md') -PathType Leaf) 'conflict report created'
  Assert-Test (@(Get-ChildItem -LiteralPath (Join-Path $conflictProject '.research-agent\candidates') -File).Count -ge 2) 'conflict candidates created'

  $installedShared = Join-Path $UserSkillsRoot 'shared'
  $installedItem = Get-Item -LiteralPath $installedShared -Force
  Assert-Test ($installedItem.LinkType -eq 'Junction') 'installed shared is a Junction'
  Assert-Test (Test-Path -LiteralPath (Join-Path $installedShared 'MODEL_ROUTING.json') -PathType Leaf) 'Junction exposes MODEL_ROUTING.json'
  Assert-Test (Test-Path -LiteralPath (Join-Path $installedShared 'MODEL_ROUTING.md') -PathType Leaf) 'Junction exposes MODEL_ROUTING.md'

  Write-Output 'MANAGED_PROJECT_ROUTING_PASS'
}
catch { $failure = $_ }
finally {
  $full = [IO.Path]::GetFullPath($testRoot)
  $base = [IO.Path]::GetFullPath($tempParent).TrimEnd('\') + '\'
  if (-not $full.StartsWith($base,[StringComparison]::OrdinalIgnoreCase)) { throw "Unsafe cleanup path: $full" }
  if (Test-Path -LiteralPath $full) { Remove-Item -LiteralPath $full -Recurse -Force }
  if ((Test-Path -LiteralPath $tempParent) -and @(Get-ChildItem -LiteralPath $tempParent -Force).Count -eq 0) { Remove-Item -LiteralPath $tempParent -Force }
  $cleanupPass = -not (Test-Path -LiteralPath $full)
}

if (-not $cleanupPass) { throw 'FAIL temporary directory cleanup' }
Write-Output 'TEMP_CLEANUP_PASS'
if ($null -ne $failure) { throw $failure }
