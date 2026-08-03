<#
.SYNOPSIS
  Initializes a personal research workspace without overwriting existing files.
.EXAMPLE
  .\Initialize-ResearchWorkspace.ps1 -WorkspaceRoot 'D:\ResearchWorkspace'
#>
[CmdletBinding(SupportsShouldProcess)]
param(
  [Parameter(Mandatory)][string]$WorkspaceRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$templateRoot = Join-Path $repositoryRoot 'workspace-template'
if (-not (Test-Path -LiteralPath $templateRoot -PathType Container)) { throw "Workspace template not found: $templateRoot" }

$requestedRoot = [IO.Path]::GetFullPath($WorkspaceRoot.Trim().Trim('"'))
if (-not (Test-Path -LiteralPath $requestedRoot -PathType Container)) {
  if ($PSCmdlet.ShouldProcess($requestedRoot, 'Create research workspace directory')) {
    New-Item -ItemType Directory -Path $requestedRoot -Force | Out-Null
  }
}
if (-not (Test-Path -LiteralPath $requestedRoot -PathType Container)) { throw "Workspace directory not available: $requestedRoot" }
$resolvedRoot = (Resolve-Path -LiteralPath $requestedRoot).ProviderPath

foreach ($file in @('RESEARCH_WORKBENCH.md','GLOBAL_LESSONS.md','PROJECT_SOP.md','PROJECT_INDEX.json')) {
  $source = Join-Path $templateRoot $file
  $target = Join-Path $resolvedRoot $file
  if (Test-Path -LiteralPath $target) { Write-Output "SKIP $file"; continue }
  if ($PSCmdlet.ShouldProcess($target, 'Create workspace file')) {
    Copy-Item -LiteralPath $source -Destination $target
    Write-Output "CREATE $file"
  }
}

$projectsRoot = Join-Path $resolvedRoot 'projects'
if (-not (Test-Path -LiteralPath $projectsRoot -PathType Container) -and $PSCmdlet.ShouldProcess($projectsRoot, 'Create projects directory')) {
  New-Item -ItemType Directory -Path $projectsRoot | Out-Null
  Write-Output 'CREATE projects'
}

$indexPath = Join-Path $resolvedRoot 'PROJECT_INDEX.json'
if (Test-Path -LiteralPath $indexPath -PathType Leaf) {
  $index = Get-Content -LiteralPath $indexPath -Raw -Encoding UTF8 | ConvertFrom-Json
  if ([int]$index.schema_version -ne 1 -or [int]$index.next_project_number -lt 1) { throw "Invalid workspace index: $indexPath" }
}

Write-Output "WORKSPACE_READY $resolvedRoot"
