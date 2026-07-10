<#
.SYNOPSIS
  Validate source metadata, references, JSON, installation, scripts and project template.
.EXAMPLE
  .\Test-ResearchSkills.ps1
#>
[CmdletBinding()]
param(
  [string]$SourceRoot = "",
  [string]$UserSkillsRoot = (Join-Path $env:USERPROFILE '.agents\skills'),
  [string]$ReportPath = ""
)
$ErrorActionPreference='Stop'; $rows=[System.Collections.Generic.List[object]]::new(); $names=@('00-research-orchestrator','01-requirement-elicitation','02-research-reconnaissance','03-stage-planning-execution','04-literature-review','05-academic-writing','06-quality-gate')

if([string]::IsNullOrWhiteSpace($SourceRoot)){$SourceRoot=Split-Path -Parent $PSScriptRoot}
if([string]::IsNullOrWhiteSpace($ReportPath)){$ReportPath=Join-Path (Split-Path -Parent $PSScriptRoot) 'installation-report.md'}
function Add-Result($status,$check,$detail){$rows.Add([pscustomobject]@{Status=$status;Check=$check;Detail=($detail -replace '\|','/')})}
foreach($name in $names){$f=Join-Path $SourceRoot "$name\SKILL.md"; if(-not(Test-Path -LiteralPath $f)){Add-Result FAIL "$name SKILL.md" 'missing';continue}; $t=Get-Content -Encoding UTF8 -Raw -LiteralPath $f; $ok=($t -match '(?ms)^---\s*\r?\n.*?^name:\s*\S+.*?^description:\s*.+?\r?\n.*?^---'); Add-Result ($(if($ok){'PASS'}else{'FAIL'})) "$name metadata" 'front matter name/description'; if((Get-Item -LiteralPath $f).Length -eq 0){Add-Result FAIL "$name non-empty" 'empty file'}}
$all=@(Get-ChildItem -LiteralPath $SourceRoot -Recurse -Filter SKILL.md); $namesFound=@(); foreach($f in $all){$t=Get-Content -Encoding UTF8 -Raw -LiteralPath $f.FullName; if($t -match '(?m)^name:\s*(\S+)'){$namesFound+=$Matches[1]}}; $dupes=@($namesFound|Group-Object|Where-Object Count -gt 1); Add-Result ($(if($dupes.Count -eq 0){'PASS'}else{'FAIL'})) 'unique Skill names' ($(if($dupes.Count -eq 0){'unique'}else{$dupes.Name -join ', '}))
$eval=Join-Path $SourceRoot 'evals\evals.json'; try{$null=Get-Content -Encoding UTF8 -Raw -LiteralPath $eval|ConvertFrom-Json;Add-Result PASS 'evals.json' 'valid JSON'}catch{Add-Result FAIL 'evals.json' $_.Exception.Message}
foreach($p in @('shared\PROJECT_STATE.template.md','shared\STAGE_HANDOFF.template.md','shared\QUALITY_RUBRIC.md','shared\ROUTING_EXAMPLES.md')){Add-Result ($(if(Test-Path (Join-Path $SourceRoot $p)){'PASS'}else{'FAIL'})) "required $p" ($(if(Test-Path (Join-Path $SourceRoot $p)){'present'}else{'missing'}))}
foreach($name in $names){$f=Join-Path $UserSkillsRoot "$name\SKILL.md"; Add-Result ($(if(Test-Path -LiteralPath $f){'PASS'}else{'WARNING'})) "installed $name" ($(if(Test-Path -LiteralPath $f){'visible'}else{'not installed'}))}
$scripts=@(Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.ps1'); foreach($s in $scripts){try{$null=[System.Management.Automation.Language.Parser]::ParseFile($s.FullName,[ref]$null,[ref]$null);Add-Result PASS "syntax $($s.Name)" 'parsed'}catch{Add-Result FAIL "syntax $($s.Name)" $_.Exception.Message}}
$report=@('# Research Agent Skills Installation Report','',"Generated: $(Get-Date -Format s)",'', '| Status | Check | Detail |','|---|---|---|'); foreach($r in $rows){$report += "| $($r.Status) | $($r.Check) | $($r.Detail) |"}; Set-Content -Encoding UTF8 -LiteralPath $ReportPath -Value $report; $rows|Format-Table -AutoSize; Write-Output "REPORT $ReportPath"; if(@($rows|Where-Object Status -eq 'FAIL').Count -gt 0){exit 1}



