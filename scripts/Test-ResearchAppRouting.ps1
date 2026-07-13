<#
.SYNOPSIS
  Validates ChatGPT desktop app model routing, custom agents, and tool rules.
#>
[CmdletBinding()]
param([string]$SourceRoot = '')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($SourceRoot)) { $SourceRoot = Split-Path -Parent $PSScriptRoot }
$results = New-Object System.Collections.Generic.List[object]
function Add-Result { param([string]$Status,[string]$Check,[string]$Detail); $results.Add([pscustomobject]@{ Status=$Status; Check=$Check; Detail=$Detail }) }
function Test-Text { param([string]$Text,[string]$Pattern,[string]$Check); Add-Result $(if($Text -match $Pattern){'PASS'}else{'FAIL'}) $Check $Pattern }
function Test-NoText { param([string]$Text,[string]$Pattern,[string]$Check); Add-Result $(if($Text -notmatch $Pattern){'PASS'}else{'FAIL'}) $Check $Pattern }
function Test-Value { param($Actual,$Expected,[string]$Check); Add-Result $(if($Actual -eq $Expected){'PASS'}else{'FAIL'}) $Check "expected=$Expected actual=$Actual" }

$expected = @{
  strategic = @{ model='gpt-5.6-sol'; effort='xhigh' }
  support   = @{ model='gpt-5.6-terra'; effort='medium' }
  economy   = @{ model='gpt-5.6-luna'; effort='low' }
}

$projectConfig = Join-Path $SourceRoot '.codex\config.toml'
if (Test-Path -LiteralPath $projectConfig) {
  $configText = Get-Content -Raw -Encoding UTF8 -LiteralPath $projectConfig
  Test-Text $configText '(?m)^\[agents\]\s*$' 'agent config section'
  Test-Text $configText '(?m)^max_threads\s*=\s*2\s*$' 'agent concurrency cap'
  Test-Text $configText '(?m)^max_depth\s*=\s*1\s*$' 'agent nesting cap'
} else { Add-Result FAIL 'project agent config' 'missing' }

$routingJsonPath = Join-Path $SourceRoot 'shared\MODEL_ROUTING.json'
if (Test-Path -LiteralPath $routingJsonPath) {
  try {
    $routing = Get-Content -Raw -Encoding UTF8 -LiteralPath $routingJsonPath | ConvertFrom-Json
    foreach($tier in @('strategic','support','economy')) {
      Test-Value ([string]$routing.tiers.$tier.model) $expected[$tier].model "routing JSON $tier model"
      Test-Value ([string]$routing.tiers.$tier.reasoning_effort) $expected[$tier].effort "routing JSON $tier reasoning"
    }
    Test-Value ([int]$routing.delegation.max_concurrent_subagents) 2 'routing JSON concurrency cap'
    Test-Value ([bool]$routing.delegation.subagents_may_delegate) $false 'routing JSON nesting boundary'
  }
  catch { Add-Result FAIL 'routing JSON parse' $_.Exception.Message }
} else { Add-Result FAIL 'routing JSON' 'missing' }

$routingMarkdownPath = Join-Path $SourceRoot 'shared\MODEL_ROUTING.md'
if (Test-Path -LiteralPath $routingMarkdownPath) {
  $routingMarkdown = Get-Content -Raw -Encoding UTF8 -LiteralPath $routingMarkdownPath
  Test-Text $routingMarkdown '\| `strategic / sol` \| `gpt-5\.6-sol` \| `xhigh`' 'routing Markdown strategic mapping'
  Test-Text $routingMarkdown '\| `support / terra` \| `gpt-5\.6-terra` \| `medium`' 'routing Markdown support mapping'
  Test-Text $routingMarkdown '\| `economy / luna` \| `gpt-5\.6-luna` \| `low`' 'routing Markdown economy mapping'
  Test-Text $routingMarkdown '`max_threads=2`.*`max_depth=1`' 'routing Markdown agent limits'
  Test-Text $routingMarkdown 'Terra/`medium`/\u53EA\u8BFB.*Luna/`low`/\u53EA\u8BFB' 'routing Markdown read-only agents'
  Test-NoText $routingMarkdown '\u4EC5 Sol|\u5C1A\u672A\u521B\u5EFA agents|no Terra or Luna' 'routing Markdown stale state'
} else { Add-Result FAIL 'routing Markdown' 'missing' }

$cliTemplatePath = Join-Path $SourceRoot 'config\research.config.toml.template'
if (Test-Path -LiteralPath $cliTemplatePath) {
  $cliTemplate = Get-Content -Raw -Encoding UTF8 -LiteralPath $cliTemplatePath
  Test-Text $cliTemplate 'Sol, Terra, and Luna were verified' 'CLI template verified catalog'
  Test-NoText $cliTemplate 'contains gpt-5\.6-sol only|no Terra or Luna' 'CLI template stale state'
} else { Add-Result FAIL 'CLI compatibility template' 'missing' }

$templateConfigPath = Join-Path $SourceRoot 'project-template\.codex\config.toml'
if (Test-Path -LiteralPath $templateConfigPath) {
  $templateConfig = Get-Content -Raw -Encoding UTF8 -LiteralPath $templateConfigPath
  Test-Text $templateConfig '(?m)^max_threads\s*=\s*2\s*$' 'template concurrency cap'
  Test-Text $templateConfig '(?m)^max_depth\s*=\s*1\s*$' 'template nesting cap'
} else { Add-Result FAIL 'template agent config' 'missing' }

foreach($templateAgent in @(
  @{ file='research-support.toml'; model='gpt-5.6-terra'; effort='medium' },
  @{ file='research-output.toml'; model='gpt-5.6-luna'; effort='low' }
)) {
  $templateAgentPath = Join-Path $SourceRoot ('project-template\.codex\agents\' + $templateAgent.file)
  if (-not (Test-Path -LiteralPath $templateAgentPath)) { Add-Result FAIL "template $($templateAgent.file)" 'missing'; continue }
  $templateAgentText = Get-Content -Raw -Encoding UTF8 -LiteralPath $templateAgentPath
  Test-Text $templateAgentText (('(?m)^model\s*=\s*"{0}"\s*$' -f [regex]::Escape($templateAgent.model))) "template $($templateAgent.file) model"
  Test-Text $templateAgentText (('(?m)^model_reasoning_effort\s*=\s*"{0}"\s*$' -f $templateAgent.effort)) "template $($templateAgent.file) reasoning"
  Test-Text $templateAgentText '(?m)^sandbox_mode\s*=\s*"read-only"\s*$' "template $($templateAgent.file) read-only"
}

$managedRoutingPath = Join-Path $SourceRoot 'project-template\.research-agent\MODEL_ROUTING.json'
if (Test-Path -LiteralPath $managedRoutingPath) {
  $managedRouting = Get-Content -Raw -Encoding UTF8 -LiteralPath $managedRoutingPath | ConvertFrom-Json
  Test-Value ([string]$managedRouting.tiers.strategic.model) $expected.strategic.model 'managed routing strategic model'
  Test-Value ([string]$managedRouting.tiers.support.model) $expected.support.model 'managed routing support model'
  Test-Value ([string]$managedRouting.tiers.economy.model) $expected.economy.model 'managed routing economy model'
  Test-Value ([int]$managedRouting.delegation.max_threads) 2 'managed routing max threads'
  Test-Value ([int]$managedRouting.delegation.max_depth) 1 'managed routing max depth'
  Test-Value ([bool]$managedRouting.delegation.subagents_may_delegate) $false 'managed routing no recursion'
  Test-Value ([bool]$managedRouting.delegation.main_agent_final_review) $true 'managed routing final review'
} else { Add-Result FAIL 'managed routing JSON' 'missing' }

$templateAgentsPath = Join-Path $SourceRoot 'project-template\AGENTS.md'
$templateAgentsText = Get-Content -Raw -Encoding UTF8 -LiteralPath $templateAgentsPath
foreach($token in @('research-agent-routing:start','research-agent-routing:end','Codex','PowerShell','Python','`rg`','`git diff`')) { Test-Text $templateAgentsText ([regex]::Escape($token)) "template AGENTS $token" }

foreach($skillName in @('00-research-orchestrator','01-requirement-elicitation','02-research-reconnaissance','03-stage-planning-execution','04-literature-review','05-academic-writing','06-quality-gate')) {
  $skillText = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $SourceRoot "$skillName\SKILL.md")
  Test-Text $skillText 'routing-preflight:required' "$skillName routing preflight"
  Test-Text $skillText '\.\./shared/MODEL_ROUTING\.json' "$skillName routing reference"
}


$codex = Get-Command codex -ErrorAction SilentlyContinue
$available = @()
if ($null -eq $codex) { Add-Result WARN 'Codex model catalog' 'codex command not found; model IDs cannot be verified' }
else {
  try { $catalog = (& codex debug models 2>$null) | ConvertFrom-Json; if ($LASTEXITCODE -ne 0 -or $null -eq $catalog.models) { throw 'codex debug models returned no models' }; $available=@($catalog.models | ForEach-Object { [string]$_.slug }); Add-Result PASS 'Codex model catalog' ($available -join ', ') }
  catch { Add-Result WARN 'Codex model catalog' $_.Exception.Message }
}

$agentExpectations = @{
  'research-support' = @{ name='research_support'; tier='support' }
  'research-output'  = @{ name='research_output'; tier='economy' }
}
foreach($agentName in @('research-support','research-output')) {
  $path=Join-Path $SourceRoot ('.codex\agents\'+$agentName+'.toml')
  if(-not(Test-Path -LiteralPath $path)){Add-Result FAIL "$agentName agent file" 'missing';continue}
  $text=Get-Content -Raw -Encoding UTF8 -LiteralPath $path
  $agentExpected = $agentExpectations[$agentName]
  $tierExpected = $expected[$agentExpected.tier]
  Test-Text $text (('(?m)^name\s*=\s*"{0}"\s*$' -f [regex]::Escape($agentExpected.name))) "$agentName name"
  Test-Text $text '(?m)^description\s*=\s*"[^"]+"\s*$' "$agentName description"
  Test-Text $text '(?m)^developer_instructions\s*=\s*"""' "$agentName instructions"
  Test-Text $text (('(?m)^model\s*=\s*"{0}"\s*$' -f [regex]::Escape($tierExpected.model))) "$agentName model mapping"
  Test-Text $text (('(?m)^model_reasoning_effort\s*=\s*"{0}"\s*$' -f [regex]::Escape($tierExpected.effort))) "$agentName reasoning mapping"
  Test-Text $text '(?m)^sandbox_mode\s*=\s*"read-only"\s*$' "$agentName read-only sandbox"
  Test-NoText $text 'exposes gpt-5\.6-sol only|Replace this with|only after local verification' "$agentName stale model comment"
  if($text -match '(?m)^model\s*=\s*"([^"]+)"\s*$') { $model=$Matches[1]; Add-Result $(if($available.Count -eq 0){'WARN'}elseif($model -in $available){'PASS'}else{'FAIL'}) "$agentName model availability" $model }
  else { Add-Result FAIL "$agentName model" 'missing' }
  if($agentName -eq 'research-support') { Test-Text $text 'must not select a research direction' 'support judgement boundary'; Test-Text $text 'Do not edit\s+files' 'support edit boundary' }
  else { Test-Text $text 'Never introduce a fact' 'output no-new-facts boundary'; Test-Text $text 'Do not edit\s+files' 'output edit boundary'; Test-Text $text 'Mark uncertainty as' 'output uncertainty boundary' }
}

$orchestrator=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $SourceRoot '00-research-orchestrator\SKILL.md')
Test-Text $orchestrator '\| A .*strategic' 'strategic routing'
Test-Text $orchestrator '\| B .*support' 'support routing'
Test-Text $orchestrator '\| C .*economy' 'economy routing'
Test-Text $orchestrator 'D .*strategic.*B/C.*strategic' 'mixed-task routing'
Test-Text $orchestrator 'PowerShell' 'PowerShell boundary'
Test-Text $orchestrator 'Python' 'Python boundary'
Test-Text $orchestrator '`rg`/`rg --files`' 'native search boundary'
Test-Text $orchestrator '`git diff`' 'Git inspection boundary'
Test-Text $orchestrator 'Large results must be written to files\.' 'output control'

$results | Format-Table -AutoSize
$failures=@($results|Where-Object Status -eq 'FAIL').Count
$warnings=@($results|Where-Object Status -eq 'WARN').Count
if($failures -gt 0){Write-Output "FINAL FAIL failures=$failures warnings=$warnings";exit 1}
if($warnings -gt 0){Write-Output "FINAL WARN warnings=$warnings";exit 0}
Write-Output 'FINAL PASS'
