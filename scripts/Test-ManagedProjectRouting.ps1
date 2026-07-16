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
$canonicalPath = Join-Path $SourceRoot 'shared\MODEL_ROUTING.json'
$canonicalText = [IO.File]::ReadAllText($canonicalPath)
$canonicalHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $canonicalPath).Hash
$canonical = $canonicalText | ConvertFrom-Json
$expectedSupportModel = [regex]::Escape([string]$canonical.tiers.support.model)
$expectedSupportEffort = [regex]::Escape([string]$canonical.tiers.support.reasoning_effort)
$expectedEconomyModel = [regex]::Escape([string]$canonical.tiers.economy.model)
$expectedEconomyEffort = [regex]::Escape([string]$canonical.tiers.economy.reasoning_effort)
$expectedMaxThreads = [int]$canonical.delegation.max_threads
$expectedMaxDepth = [int]$canonical.delegation.max_depth
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
  Assert-Test ($config -match ("(?m)^max_threads\s*=\s*{0}\s*$" -f $expectedMaxThreads)) "new project max_threads=$expectedMaxThreads"
  Assert-Test ($config -match ("(?m)^max_depth\s*=\s*{0}\s*$" -f $expectedMaxDepth)) "new project max_depth=$expectedMaxDepth"
  $support = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $newProject '.codex\agents\research-support.toml')
  $output = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $newProject '.codex\agents\research-output.toml')
  Assert-Test ($support -match ("(?m)^model\s*=\s*`"{0}`"\s*$" -f $expectedSupportModel) -and $support -match ("(?m)^model_reasoning_effort\s*=\s*`"{0}`"\s*$" -f $expectedSupportEffort)) 'support matches canonical routing'
  Assert-Test ($output -match ("(?m)^model\s*=\s*`"{0}`"\s*$" -f $expectedEconomyModel) -and $output -match ("(?m)^model_reasoning_effort\s*=\s*`"{0}`"\s*$" -f $expectedEconomyEffort)) 'economy matches canonical routing'
  Assert-Test ($support -match '(?m)^sandbox_mode\s*=\s*"read-only"\s*$' -and $output -match '(?m)^sandbox_mode\s*=\s*"read-only"\s*$') 'both agents are read-only'
  $routingPath = Join-Path $newProject '.research-agent\MODEL_ROUTING.json'
  $routing = Get-Content -Raw -Encoding UTF8 -LiteralPath $routingPath | ConvertFrom-Json
  Assert-Test (-not [bool]$routing.delegation.subagents_may_delegate -and [bool]$routing.delegation.main_agent_final_review) 'delegation and final-review boundaries'
  Assert-Test ((Get-FileHash -Algorithm SHA256 -LiteralPath $routingPath).Hash -eq $canonicalHash) 'project routing snapshot is byte-identical to canonical JSON'
  $routingStatus = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $newProject '.research-agent\routing-version.json') | ConvertFrom-Json
  Assert-Test ([string]$routingStatus.status -eq 'ready' -and [int]$routingStatus.conflict_count -eq 0) 'new project routing status is ready'
  Assert-Test ([string]$routingStatus.canonical_sha256 -eq $canonicalHash -and [string]$routingStatus.snapshot_sha256 -eq $canonicalHash) 'new project canonical and snapshot hashes recorded'
  $agents = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $newProject 'AGENTS.md')
  foreach($token in @('Codex','PowerShell','Python','`rg`','`git diff`',"max_threads=$expectedMaxThreads","max_depth=$expectedMaxDepth",'research-agent-routing:start','research-agent-routing:end')) {
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
  Assert-Test ($LASTEXITCODE -ne 0) 'launcher conflict preflight exits nonzero'
  Assert-Test ($conflictOutput -match 'ROUTING_BLOCKED_CONFLICT') 'conflict emits blocked status'
  Assert-Test ($conflictOutput -notmatch 'ROUTING_PROJECT_READY') 'conflict never emits ready'
  Assert-Test ((Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $conflictProject '.codex\config.toml')).Hash -eq $configHash) 'conflicting config is not overwritten'
  Assert-Test ((Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $conflictProject '.codex\agents\research-support.toml')).Hash -eq $agentHash) 'conflicting agent is not overwritten'
  Assert-Test (Test-Path -LiteralPath (Join-Path $conflictProject '.research-agent\routing-conflicts.md') -PathType Leaf) 'conflict report created'
  $blockedStatus = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $conflictProject '.research-agent\routing-version.json') | ConvertFrom-Json
  Assert-Test ([string]$blockedStatus.status -eq 'blocked_conflict' -and [int]$blockedStatus.conflict_count -gt 0) 'conflict status file is fail-closed'
  Assert-Test (@(Get-ChildItem -LiteralPath (Join-Path $conflictProject '.research-agent\candidates') -File).Count -ge 2) 'conflict candidates created'

  function Assert-SharedArtifactsMatchSource {
    param([string]$InstalledShared,[string]$Label,[switch]$VerifyContent)
    $sourceShared = Join-Path $SourceRoot 'shared'
    Assert-Test (Test-Path -LiteralPath $InstalledShared -PathType Container) "$Label shared directory exists"
    $sourceFiles = if($VerifyContent) {
      @(Get-ChildItem -LiteralPath $sourceShared -File | Sort-Object Name)
    } else {
      @('MODEL_ROUTING.json','MODEL_ROUTING.md') | ForEach-Object { Get-Item -LiteralPath (Join-Path $sourceShared $_) }
    }
    $sourceFiles = @($sourceFiles)
    Assert-Test ($sourceFiles.Count -gt 0) 'source shared artifacts found'
    foreach($sourceFile in $sourceFiles) {
      $installedFile = Join-Path $InstalledShared $sourceFile.Name
      Assert-Test (Test-Path -LiteralPath $installedFile -PathType Leaf) "$Label contains shared\$($sourceFile.Name)"
      if($VerifyContent) {
        $sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourceFile.FullName).Hash
        $installedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $installedFile).Hash
        Assert-Test ($installedHash -eq $sourceHash) "$Label shared\$($sourceFile.Name) matches source"
      }
    }
  }

  function Invoke-CatalogScenario {
    param([string]$Name,[string]$CatalogJson)
    $scenarioRoot = Join-Path $testRoot $Name
    $fakeBin = Join-Path $scenarioRoot 'bin'
    $scenarioProject = Join-Path $scenarioRoot 'project'
    New-Item -ItemType Directory -Path $fakeBin,$scenarioProject -Force | Out-Null
    Write-TestText (Join-Path $scenarioProject 'AGENTS.md') '# routing scenario'
    Write-TestText (Join-Path $scenarioProject 'PROJECT_STATE.md') 'status: test'
    $cmd = "@echo off`r`necho $CatalogJson`r`nexit /b 0`r`n"
    [IO.File]::WriteAllText((Join-Path $fakeBin 'codex.cmd'),$cmd,(New-Object Text.ASCIIEncoding))
    $savedPath = $env:PATH
    try {
      $env:PATH = $fakeBin
      $scenarioOutput = @(& $powershellPath -NoProfile -ExecutionPolicy Bypass -File $launcher -RepositoryRoot $SourceRoot -NoGui -RoutingPreflightOnly -RoutingProjectDirectory $scenarioProject 2>&1) -join "`n"
      $scenarioExit = $LASTEXITCODE
    } finally { $env:PATH = $savedPath }
    $scenarioStatus = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $scenarioProject '.research-agent\routing-version.json') | ConvertFrom-Json
    return [pscustomobject]@{ ExitCode=$scenarioExit; Output=$scenarioOutput; Status=$scenarioStatus }
  }

  $powershellPath = (Get-Command powershell.exe -ErrorAction Stop).Source
  $solOnlyJson = '{"models":[{"slug":"gpt-5.6-sol","supported_reasoning_levels":[{"effort":"xhigh"}]}]}'
  $solOnly = Invoke-CatalogScenario -Name 'sol-only scenario' -CatalogJson $solOnlyJson
  Assert-Test ($solOnly.ExitCode -eq 0) 'Sol-only scenario exits zero'
  Assert-Test ([string]$solOnly.Status.status -eq 'degraded_sol_only') 'Sol-only scenario records degraded status'
  Assert-Test ((@($solOnly.Status.unavailable_tiers) -join ',') -eq 'support,economy') 'Sol-only scenario records unavailable tiers'
  Assert-Test ($solOnly.Output -match 'Routing degraded to Sol-only' -and $solOnly.Output -match 'ROUTING_PROJECT_READY') 'Sol-only scenario warns and remains launchable'

  $noSolJson = '{"models":[{"slug":"gpt-5.6-terra","supported_reasoning_levels":[{"effort":"medium"}]},{"slug":"gpt-5.6-luna","supported_reasoning_levels":[{"effort":"low"}]}]}'
  $noSol = Invoke-CatalogScenario -Name 'no-sol scenario' -CatalogJson $noSolJson
  Assert-Test ($noSol.ExitCode -ne 0) 'missing strategic Sol exits nonzero'
  Assert-Test ([string]$noSol.Status.status -eq 'blocked_model_catalog' -and 'strategic' -in @($noSol.Status.unavailable_tiers)) 'missing strategic Sol records blocked status'
  Assert-Test ($noSol.Output -match 'ROUTING_BLOCKED_MODEL_CATALOG' -and $noSol.Output -notmatch 'ROUTING_PROJECT_READY') 'missing strategic Sol never emits ready'
  $installedShared = Join-Path $UserSkillsRoot 'shared'
  Assert-Test (Test-Path -LiteralPath $installedShared -PathType Container) 'installed shared directory exists'
  $installedItem = Get-Item -LiteralPath $installedShared -Force
  $linkTypeProperty = $installedItem.PSObject.Properties['LinkType']
  $installedLinkType = if ($null -eq $linkTypeProperty) { '' } else { [string]$linkTypeProperty.Value }
  $isJunction = $installedLinkType -eq 'Junction'
  $isCopyMode = [string]::IsNullOrWhiteSpace($installedLinkType)
  Assert-Test ($isJunction -or $isCopyMode) 'installed shared uses Junction or copy-mode'
  Assert-SharedArtifactsMatchSource -InstalledShared $installedShared -Label 'installed' -VerifyContent:$isCopyMode

  $copyModeRoot = Join-Path $testRoot 'copy-mode installation'
  $copyModeShared = Join-Path $copyModeRoot 'shared'
  New-Item -ItemType Directory -Path $copyModeShared -Force | Out-Null
  foreach($sourceFile in @(Get-ChildItem -LiteralPath (Join-Path $SourceRoot 'shared') -File)) {
    Copy-Item -LiteralPath $sourceFile.FullName -Destination (Join-Path $copyModeShared $sourceFile.Name)
  }
  $copyModeItem = Get-Item -LiteralPath $copyModeShared -Force
  $copyLinkProperty = $copyModeItem.PSObject.Properties['LinkType']
  $copyLinkType = if ($null -eq $copyLinkProperty) { '' } else { [string]$copyLinkProperty.Value }
  Assert-Test ([string]::IsNullOrWhiteSpace($copyLinkType)) 'copy-mode simulation uses an ordinary directory'
  Assert-SharedArtifactsMatchSource -InstalledShared $copyModeShared -Label 'copy-mode simulation' -VerifyContent
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
