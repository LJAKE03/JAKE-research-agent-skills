<#
.SYNOPSIS
  Validates UTF-8 source files and PowerShell text I/O discipline.
#>
[CmdletBinding()]
param([string]$SourceRoot = '')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($SourceRoot)) { $SourceRoot = Split-Path -Parent $PSScriptRoot }
$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).ProviderPath
$failures = New-Object System.Collections.Generic.List[string]
$strictUtf8 = New-Object Text.UTF8Encoding($false, $true)
$utf8NoBom = New-Object Text.UTF8Encoding($false)
$textExtensions = @('.md','.json','.toml','.ps1','.psm1','.py','.cmd','.txt','.yaml','.yml')

function Add-Failure { param([string]$Message); $failures.Add($Message) }
function Decode-Utf8Base64 {
  param([string]$Value)
  [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Value))
}

$textFiles = @(Get-ChildItem -LiteralPath $SourceRoot -Recurse -Force -File | Where-Object {
  $_.FullName -notmatch '[\\/]\.git[\\/]' -and
  $_.FullName -notmatch '[\\/]backups[\\/]' -and
  ($_.Name -eq 'VERSION' -or $_.Extension.ToLowerInvariant() -in $textExtensions)
})

foreach ($file in $textFiles) {
  $bytes = [IO.File]::ReadAllBytes($file.FullName)
  try { $null = $strictUtf8.GetString($bytes) }
  catch { Add-Failure "invalid UTF-8: $($file.FullName)" }
  if ($file.Extension -in @('.ps1','.psm1')) {
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $payloadStart = if ($hasBom) { 3 } else { 0 }
    $hasNonAscii = $false
    for ($i = $payloadStart; $i -lt $bytes.Length; $i++) {
      if ($bytes[$i] -gt 0x7F) { $hasNonAscii = $true; break }
    }
    if ($hasNonAscii -and -not $hasBom) {
      Add-Failure "PowerShell 5.1 requires UTF-8 BOM for non-ASCII script: $($file.FullName)"
    }
  }
}

$powerShellFiles = @($textFiles | Where-Object { $_.Extension -in @('.ps1','.psm1') })
foreach ($file in $powerShellFiles) {
  $tokens = $null
  $parseErrors = $null
  $ast = [Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors)
  if (@($parseErrors).Count -gt 0) { Add-Failure "PowerShell parse error: $($file.FullName)"; continue }
  $commands = $ast.FindAll({ param($node) $node -is [Management.Automation.Language.CommandAst] }, $true)
  foreach ($command in $commands) {
    $name = $command.GetCommandName()
    if ([string]::IsNullOrWhiteSpace($name)) { continue }
    if ($name -in @('gc','cat','type')) {
      Add-Failure "ambiguous Get-Content alias '$name': $($file.FullName):$($command.Extent.StartLineNumber)"
      continue
    }
    if ($name -ieq 'Get-Content' -and $command.Extent.Text -notmatch '(?i)(?:^|\s)-Encoding(?:\s|:|$)') {
      Add-Failure "Get-Content missing -Encoding: $($file.FullName):$($command.Extent.StartLineNumber)"
    }
    if ($name -in @('Set-Content','Add-Content','Out-File') -and $command.Extent.Text -notmatch '(?i)(?:^|\s)-Encoding(?:\s|:|$)') {
      Add-Failure "$name missing -Encoding: $($file.FullName):$($command.Extent.StartLineNumber)"
    }
  }
}

$orchestratorPath = Join-Path $SourceRoot '00-research-orchestrator/SKILL.md'
$orchestratorText = Get-Content -Raw -Encoding UTF8 -LiteralPath $orchestratorPath
$expectedHeading = Decode-Utf8Base64 '56eR56CU6aG555uu5oC75o6n5LiO57uf5LiA5bel5L2c5rWB'
if ($orchestratorText -notmatch [regex]::Escape($expectedHeading)) { Add-Failure 'Chinese UTF-8 source read produced unexpected text' }

$launcherFiles = @(Get-ChildItem -LiteralPath $SourceRoot -Filter '*.cmd' -File)
if ($launcherFiles.Count -ne 1) { Add-Failure "expected one CMD launcher; found $($launcherFiles.Count)" }
else {
  $launcherBytes = [IO.File]::ReadAllBytes($launcherFiles[0].FullName)
  $launcherText = Get-Content -Raw -Encoding UTF8 -LiteralPath $launcherFiles[0].FullName
  $launcherHasBom = $launcherBytes.Length -ge 3 -and $launcherBytes[0] -eq 0xEF -and $launcherBytes[1] -eq 0xBB -and $launcherBytes[2] -eq 0xBF
  if ($launcherHasBom) { Add-Failure 'CMD launcher must remain UTF-8 without BOM' }
  if ($launcherText -match '(?<!\r)\n') { Add-Failure 'CMD launcher must use CRLF line endings' }
  $chcpCount = [regex]::Matches($launcherText, '(?im)^\s*chcp\s+65001\b').Count
  if ($chcpCount -ne 1) { Add-Failure "CMD launcher must set code page once; found $chcpCount" }
}

$tempParent = Join-Path ([IO.Path]::GetTempPath()) 'research-agent-encoding-tests'
$testRoot = Join-Path $tempParent ([Guid]::NewGuid().ToString('N'))
$testName = Decode-Utf8Base64 '5Lit5paHIFVURi04IOaXoCBCT00ubWQ='
$testPath = Join-Path $testRoot $testName
$roundTripText = Decode-Utf8Base64 '56eR56CUIEFnZW5077ya5rip5bqmIDY1MCDihIPvvJvljovlt64gMTIuNSBrUGHvvJvOlHAg5Y+v6L+95rqv44CC'
$roundTripOk = $false
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
try {
  [IO.File]::WriteAllText($testPath, $roundTripText, $utf8NoBom)
  $roundTripBytes = [IO.File]::ReadAllBytes($testPath)
  $roundTripHasBom = $roundTripBytes.Length -ge 3 -and $roundTripBytes[0] -eq 0xEF -and $roundTripBytes[1] -eq 0xBB -and $roundTripBytes[2] -eq 0xBF
  $roundTripRead = Get-Content -Raw -Encoding UTF8 -LiteralPath $testPath
  $roundTripOk = -not $roundTripHasBom -and $roundTripRead -ceq $roundTripText
  if (-not $roundTripOk) { Add-Failure 'UTF-8 no-BOM round-trip failed' }
}
finally {
  $full = [IO.Path]::GetFullPath($testRoot)
  $base = [IO.Path]::GetFullPath($tempParent).TrimEnd('\') + '\'
  if (-not $full.StartsWith($base, [StringComparison]::OrdinalIgnoreCase)) { throw "Unsafe cleanup path: $full" }
  if (Test-Path -LiteralPath $full) { Remove-Item -LiteralPath $full -Recurse -Force }
  if ((Test-Path -LiteralPath $tempParent) -and @(Get-ChildItem -LiteralPath $tempParent -Force).Count -eq 0) { Remove-Item -LiteralPath $tempParent -Force }
}

if ($failures.Count -gt 0) {
  $failures | ForEach-Object { Write-Output "FAIL $_" }
  Write-Output "RESEARCH_ENCODING_FAIL count=$($failures.Count)"
  exit 1
}

Write-Output "RESEARCH_ENCODING_PASS runtime=$($PSVersionTable.PSVersion) files=$($textFiles.Count) scripts=$($powerShellFiles.Count) roundtrip=$roundTripOk encoding_retries=0 chcp_count=$chcpCount"
