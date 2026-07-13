<#
.SYNOPSIS
    Validates source metadata, references, JSON, installed Skills, scripts and the project template.
#>
[CmdletBinding()]
param(
    [string]$SourceRoot = '',
    [string]$UserSkillsRoot = (Join-Path $env:USERPROFILE '.agents\skills'),
    [string]$ReportPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$rows = New-Object System.Collections.Generic.List[object]
$names = @(
    '00-research-orchestrator',
    '01-requirement-elicitation',
    '02-research-reconnaissance',
    '03-stage-planning-execution',
    '04-literature-review',
    '05-academic-writing',
    '06-quality-gate'
)
if ([string]::IsNullOrWhiteSpace($SourceRoot)) { $SourceRoot = Split-Path -Parent $PSScriptRoot }
if ([string]::IsNullOrWhiteSpace($ReportPath)) { $ReportPath = Join-Path $SourceRoot 'installation-report.md' }

function Add-Result {
    param($Status, $Check, $Detail)
    $rows.Add([pscustomobject]@{
        Status = $Status
        Check  = $Check
        Detail = ([string]$Detail -replace '\|', '/')
    })
}

foreach ($name in $names) {
    $file = Join-Path $SourceRoot "$name\SKILL.md"
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        Add-Result FAIL "$name SKILL.md" 'missing'
        continue
    }
    $text = Get-Content -Encoding UTF8 -Raw -LiteralPath $file
    $metadataOk = $text -match '(?ms)^---\s*\r?\n.*?^name:\s*\S+.*?^description:\s*.+?\r?\n.*?^---'
    Add-Result $(if ($metadataOk) { 'PASS' } else { 'FAIL' }) "$name metadata" 'front matter name/description'
    if ((Get-Item -LiteralPath $file).Length -eq 0) { Add-Result FAIL "$name non-empty" 'empty file' }
}

$skillFiles = @(Get-ChildItem -LiteralPath $SourceRoot -Recurse -Filter SKILL.md)
$foundNames = @()
foreach ($file in $skillFiles) {
    $text = Get-Content -Encoding UTF8 -Raw -LiteralPath $file.FullName
    if ($text -match '(?m)^name:\s*(\S+)') { $foundNames += $Matches[1] }
}
$duplicates = @($foundNames | Group-Object | Where-Object Count -gt 1)
Add-Result $(if ($duplicates.Count -eq 0) { 'PASS' } else { 'FAIL' }) 'unique Skill names' $(if ($duplicates.Count -eq 0) { 'unique' } else { $duplicates.Name -join ', ' })

$evalPath = Join-Path $SourceRoot 'evals\evals.json'
try {
    $null = Get-Content -Encoding UTF8 -Raw -LiteralPath $evalPath | ConvertFrom-Json
    Add-Result PASS 'evals.json' 'valid JSON'
}
catch {
    Add-Result FAIL 'evals.json' $_.Exception.Message
}

foreach ($relativePath in @(
    'shared\PROJECT_STATE.template.md',
    'shared\STAGE_HANDOFF.template.md',
    'shared\QUALITY_RUBRIC.md',
    'shared\ROUTING_EXAMPLES.md'
)) {
    $present = Test-Path -LiteralPath (Join-Path $SourceRoot $relativePath) -PathType Leaf
    Add-Result $(if ($present) { 'PASS' } else { 'FAIL' }) "required $relativePath" $(if ($present) { 'present' } else { 'missing' })
}

foreach ($name in $names) {
    $file = Join-Path $UserSkillsRoot "$name\SKILL.md"
    $visible = Test-Path -LiteralPath $file -PathType Leaf
    Add-Result $(if ($visible) { 'PASS' } else { 'WARNING' }) "installed $name" $(if ($visible) { 'visible' } else { 'not installed' })
}

$scripts = @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.ps1')
foreach ($script in $scripts) {
    $tokens = $null
    $parseErrors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$tokens, [ref]$parseErrors)
    if (@($parseErrors).Count -eq 0) {
        Add-Result PASS "syntax $($script.Name)" 'parsed'
    }
    else {
        $detail = (@($parseErrors) | ForEach-Object { $_.Message }) -join '; '
        Add-Result FAIL "syntax $($script.Name)" $detail
    }
}

$report = @(
    '# Research Agent Skills Installation Report',
    '',
    "Generated: $(Get-Date -Format s)",
    '',
    '| Status | Check | Detail |',
    '|---|---|---|'
)
foreach ($row in $rows) { $report += "| $($row.Status) | $($row.Check) | $($row.Detail) |" }
[IO.File]::WriteAllLines($ReportPath, $report, (New-Object Text.UTF8Encoding($true)))
$rows | Format-Table -AutoSize
Write-Output "REPORT $ReportPath"
if (@($rows | Where-Object Status -eq 'FAIL').Count -gt 0) { exit 1 }

$appTest = Join-Path $PSScriptRoot 'Test-ResearchAppRouting.ps1'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $appTest -SourceRoot $SourceRoot
if ($LASTEXITCODE -ne 0) {
    Write-Output "FINAL FAIL app-routing-exit=$LASTEXITCODE"
    exit $LASTEXITCODE
}

$managedProjectTest = Join-Path $PSScriptRoot 'Test-ManagedProjectRouting.ps1'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $managedProjectTest -SourceRoot $SourceRoot -UserSkillsRoot $UserSkillsRoot
if ($LASTEXITCODE -ne 0) {
    Write-Output "FINAL FAIL managed-project-routing-exit=$LASTEXITCODE"
    exit $LASTEXITCODE
}
