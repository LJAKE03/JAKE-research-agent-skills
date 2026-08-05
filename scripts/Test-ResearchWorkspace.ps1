<#
.SYNOPSIS
  End-to-end tests for the personal research workspace and project experience loop.
#>
[CmdletBinding()]
param(
  [string]$SourceRoot = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($SourceRoot)) { $SourceRoot = Split-Path -Parent $PSScriptRoot }
$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).ProviderPath
$initializer = Join-Path $SourceRoot 'scripts\Initialize-ResearchWorkspace.ps1'
$creator = Join-Path $SourceRoot 'scripts\New-ResearchProject.ps1'
$powershellPath = (Get-Command powershell.exe -ErrorAction Stop).Source
$tempParent = Join-Path ([IO.Path]::GetTempPath()) 'research-agent-workspace-tests'
$testRoot = Join-Path $tempParent ([Guid]::NewGuid().ToString('N'))
$workspace = Join-Path $testRoot 'workspace'
$failure = $null
$cleanupPass = $false

function Assert-Test {
  param([bool]$Condition,[string]$Message)
  if (-not $Condition) { throw "FAIL $Message" }
  Write-Output "PASS $Message"
}

New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
try {
  Assert-Test (-not $testRoot.StartsWith($SourceRoot,[StringComparison]::OrdinalIgnoreCase)) 'temporary root is outside repository'
  $null = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $initializer -WorkspaceRoot $workspace
  Assert-Test ($LASTEXITCODE -eq 0) 'workspace initializer exits zero'
  foreach ($relative in @('RESEARCH_WORKBENCH.md','GLOBAL_LESSONS.md','PROJECT_SOP.md','PROJECT_INDEX.json','projects')) {
    Assert-Test (Test-Path -LiteralPath (Join-Path $workspace $relative)) "workspace contains $relative"
  }

  $workbench = Join-Path $workspace 'RESEARCH_WORKBENCH.md'
  [IO.File]::AppendAllText($workbench,"`nUSER_CONTENT_KEEP`n",[Text.UTF8Encoding]::new($false))
  $null = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $initializer -WorkspaceRoot $workspace
  Assert-Test ((Get-Content -LiteralPath $workbench -Raw -Encoding UTF8).Contains('USER_CONTENT_KEEP')) 'workspace reinitialization preserves user content'
  $lockPath = Join-Path $workspace '.project-index.lock'
  $lock = [IO.File]::Open($lockPath,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
  $previousErrorAction = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    $null = @(& $powershellPath -NoProfile -ExecutionPolicy Bypass -File $creator -ProjectName 'locked' -WorkspaceRoot $workspace 2>&1)
    $lockedExit = $LASTEXITCODE
  } finally { $ErrorActionPreference = $previousErrorAction; $lock.Dispose() }
  Assert-Test ($lockedExit -ne 0) 'workspace lock rejects concurrent creation'
  $lockedIndex = Get-Content -LiteralPath (Join-Path $workspace 'PROJECT_INDEX.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  Assert-Test ([int]$lockedIndex.next_project_number -eq 1 -and @($lockedIndex.projects).Count -eq 0) 'lock rejection leaves index unchanged'


  $null = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $creator -ProjectName 'alpha' -WorkspaceRoot $workspace
  Assert-Test ($LASTEXITCODE -eq 0) 'first workspace project exits zero'
  $null = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $creator -ProjectName 'beta' -WorkspaceRoot $workspace
  Assert-Test ($LASTEXITCODE -eq 0) 'second workspace project exits zero'

  $alpha = Join-Path $workspace 'projects\project-0001-alpha'
  $beta = Join-Path $workspace 'projects\project-0002-beta'
  Assert-Test (Test-Path -LiteralPath $alpha -PathType Container) 'first project uses numbered name'
  Assert-Test (Test-Path -LiteralPath $beta -PathType Container) 'second project uses incremented name'

  $index = Get-Content -LiteralPath (Join-Path $workspace 'PROJECT_INDEX.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  Assert-Test ([int]$index.next_project_number -eq 3 -and @($index.projects).Count -eq 2) 'workspace index advances deterministically'
  Assert-Test ([string]$index.projects[0].folder -eq 'projects/project-0001-alpha') 'workspace index stores a relative project path'

  $retrospectives = @(Get-ChildItem -LiteralPath $alpha -Recurse -Filter 'PROJECT_RETROSPECTIVE.md' -File)
  Assert-Test ($retrospectives.Count -eq 1) 'new project contains one retrospective'
  $retrospective = Get-Content -LiteralPath $retrospectives[0].FullName -Raw -Encoding UTF8
  Assert-Test ($retrospective.Contains('project-0001') -and $retrospective.Contains('alpha')) 'retrospective placeholders are populated'
  Assert-Test ($retrospective.Contains('记忆检查点状态') -and $retrospective.Contains('候选集摘要')) 'retrospective contains proactive memory checkpoint'
  $projectState = Get-Content -LiteralPath (Join-Path $alpha 'PROJECT_STATE.md') -Raw -Encoding UTF8
  Assert-Test ($projectState.Contains('记忆检查点') -and $projectState.Contains('awaiting_user')) 'project state tracks memory checkpoint lifecycle'
  $globalLessons = Get-Content -LiteralPath (Join-Path $workspace 'GLOBAL_LESSONS.md') -Raw -Encoding UTF8
  $researchWorkbench = Get-Content -LiteralPath $workbench -Raw -Encoding UTF8
  Assert-Test ($globalLessons.Contains('查看、修改、废弃或删除') -and $researchWorkbench.Contains('查看、修改、废弃或删除')) 'global memory stores expose user controls'
  Assert-Test (-not (Test-Path -LiteralPath (Join-Path $alpha 'GLOBAL_LESSONS.md'))) 'personal global memory is not copied into project'
  $quotedCreator = $creator.Replace("'","''")
  $quotedWorkspace = $workspace.Replace("'","''")
  $failureCommand = "`$env:PATH=''; & '$quotedCreator' -ProjectName 'gamma' -WorkspaceRoot '$quotedWorkspace'; exit `$LASTEXITCODE"
  $previousErrorAction = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    $failedOutput = @(& $powershellPath -NoProfile -ExecutionPolicy Bypass -Command $failureCommand 2>&1)
    $failedExit = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorAction
  }
  Assert-Test ($failedExit -ne 0 -and ($failedOutput -join ' ') -match 'ROUTING_BLOCKED_MODEL_CATALOG') 'initialization failure is observable'
  $pendingIndex = Get-Content -LiteralPath (Join-Path $workspace 'PROJECT_INDEX.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  $pendingEntry = @($pendingIndex.projects) | Select-Object -Last 1
  Assert-Test ([int]$pendingIndex.next_project_number -eq 4 -and @($pendingIndex.projects).Count -eq 3) 'failed initialization remains indexed'
  Assert-Test ([string]$pendingEntry.status -eq 'initializing' -and [string]$pendingEntry.folder -eq 'projects/project-0003-gamma') 'failed project has a recoverable initializing record'
  Assert-Test (Test-Path -LiteralPath (Join-Path $workspace ([string]$pendingEntry.folder)) -PathType Container) 'initializing record points to the partial project'

  $destination = Join-Path $testRoot 'legacy'
  New-Item -ItemType Directory -Path $destination | Out-Null
  $bothFailed = $false
  try { $null = & $creator -ProjectName 'invalid' -Destination $destination -WorkspaceRoot $workspace } catch { $bothFailed = $true }
  Assert-Test $bothFailed 'creator rejects ambiguous destination and workspace root'
  Write-Output 'RESEARCH_WORKSPACE_PASS'
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
