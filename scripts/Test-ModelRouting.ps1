<#
.SYNOPSIS
  Compatibility entry point for the application-first research model-routing test.
#>
[CmdletBinding()]
param([string]$SourceRoot = '')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($SourceRoot)) { $SourceRoot = Split-Path -Parent $PSScriptRoot }
$test = Join-Path $PSScriptRoot 'Test-ResearchAppRouting.ps1'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $test -SourceRoot $SourceRoot
exit $LASTEXITCODE