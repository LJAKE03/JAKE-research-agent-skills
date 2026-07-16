<#
.SYNOPSIS
  Validates ChatGPT desktop app model routing, custom agents, and tool rules.
.PARAMETER AllowUnverifiedModelCatalog
  Explicitly permits an unavailable Codex model catalog for offline/static development checks.
  CI and release validation should not use this switch.
#>
[CmdletBinding()]
param(
  [string]$SourceRoot = '',
  [switch]$AllowUnverifiedModelCatalog
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($SourceRoot)) { $SourceRoot = Split-Path -Parent $PSScriptRoot }
$results = New-Object System.Collections.Generic.List[object]
function Add-Result { param([string]$Status,[string]$Check,[string]$Detail); $results.Add([pscustomobject]@{ Status=$Status; Check=$Check; Detail=$Detail }) }
function Test-Text { param([string]$Text,[string]$Pattern,[string]$Check); Add-Result $(if($Text -match $Pattern){'PASS'}else{'FAIL'}) $Check $Pattern }
function Test-NoText { param([string]$Text,[string]$Pattern,[string]$Check); Add-Result $(if($Text -notmatch $Pattern){'PASS'}else{'FAIL'}) $Check $Pattern }
function Test-Value { param($Actual,$Expected,[string]$Check); Add-Result $(if($Actual -eq $Expected){'PASS'}else{'FAIL'}) $Check "expected=$Expected actual=$Actual" }
$unverifiedStatus = if($AllowUnverifiedModelCatalog){'WARN'}else{'FAIL'}

$expected = @{
  strategic = @{ model=''; effort='' }
  support   = @{ model=''; effort='' }
  economy   = @{ model=''; effort='' }
}
$projectConfig = Join-Path $SourceRoot '.codex\config.toml'
if (Test-Path -LiteralPath $projectConfig) {
  $configText = Get-Content -Raw -Encoding UTF8 -LiteralPath $projectConfig
  Test-Text $configText '(?m)^\[agents\]\s*$' 'agent config section'
  Test-Text $configText '(?m)^max_threads\s*=\s*2\s*$' 'agent concurrency cap'
  Test-Text $configText '(?m)^max_depth\s*=\s*1\s*$' 'agent nesting cap'
} else { Add-Result FAIL 'project agent config' 'missing' }

$routingJsonPath = Join-Path $SourceRoot 'shared\MODEL_ROUTING.json'
$routing = $null
if (Test-Path -LiteralPath $routingJsonPath) {
  try {
    $routing = Get-Content -Raw -Encoding UTF8 -LiteralPath $routingJsonPath | ConvertFrom-Json
    Test-Value ([int]$routing.schema_version) 2 'routing JSON schema version'
    foreach($tier in @('strategic','support','economy')) {
      $model = [string]$routing.tiers.$tier.model
      $effort = [string]$routing.tiers.$tier.reasoning_effort
      Add-Result $(if([string]::IsNullOrWhiteSpace($model)){'FAIL'}else{'PASS'}) "routing JSON $tier model" $model
      Add-Result $(if([string]::IsNullOrWhiteSpace($effort)){'FAIL'}else{'PASS'}) "routing JSON $tier reasoning" $effort
      $expected[$tier] = @{ model=$model; effort=$effort }
    }
    Test-Value ([string]$routing.tiers.support.sandbox_mode) 'read-only' 'routing JSON support sandbox'
    Test-Value ([string]$routing.tiers.economy.sandbox_mode) 'read-only' 'routing JSON economy sandbox'
    Test-Value ([int]$routing.delegation.max_threads) 2 'routing JSON concurrency cap'
    Test-Value ([int]$routing.delegation.max_depth) 1 'routing JSON nesting cap'
    Test-Value ([bool]$routing.delegation.subagents_may_delegate) $false 'routing JSON nesting boundary'
    Test-Value ([string]$routing.routing_mode.default) 'balanced' 'routing JSON default mode'
    Test-Value ([int]$routing.routing_mode.max_initial_blocking_questions) 2 'routing JSON blocking-question cap'
  }
  catch { Add-Result FAIL 'routing JSON parse' $_.Exception.Message }
} else { Add-Result FAIL 'routing JSON' 'missing' }

$routingSchemaPath = Join-Path $SourceRoot 'shared\MODEL_ROUTING.schema.json'
$schemaValidatorPath = Join-Path $SourceRoot 'scripts\Validate-ResearchRoutingSchema.py'
if(Test-Path -LiteralPath $routingSchemaPath -PathType Leaf){
  try{$schemaDocument=Get-Content -Raw -Encoding UTF8 -LiteralPath $routingSchemaPath|ConvertFrom-Json; Test-Value ([string]$schemaDocument.'$schema') 'https://json-schema.org/draft/2020-12/schema' 'routing JSON schema declaration'}
  catch{Add-Result FAIL 'routing JSON schema parse' $_.Exception.Message}
  $python=Get-Command python -ErrorAction SilentlyContinue
  if($null -eq $python -or -not(Test-Path -LiteralPath $schemaValidatorPath -PathType Leaf)){Add-Result $unverifiedStatus 'routing JSON Schema validation' 'python/jsonschema validator unavailable'}
  else{
    $schemaOutput=@(& $python.Source $schemaValidatorPath $routingSchemaPath $routingJsonPath 2>&1)
    $schemaExit=$LASTEXITCODE
    if($schemaExit -eq 0){Add-Result PASS 'routing JSON Schema validation' ($schemaOutput -join '; ')}
    elseif($schemaExit -eq 3 -and $AllowUnverifiedModelCatalog){Add-Result WARN 'routing JSON Schema validation' ($schemaOutput -join '; ')}
    else{Add-Result FAIL 'routing JSON Schema validation' ($schemaOutput -join '; ')}
  }
}else{Add-Result FAIL 'routing JSON schema' 'missing'}

$routingMarkdownPath = Join-Path $SourceRoot 'shared\MODEL_ROUTING.md'
if (Test-Path -LiteralPath $routingMarkdownPath) {
  $routingMarkdown = Get-Content -Raw -Encoding UTF8 -LiteralPath $routingMarkdownPath
  foreach($tier in @('strategic','support','economy')) {
    if (-not [string]::IsNullOrWhiteSpace($expected[$tier].model)) { Test-Text $routingMarkdown ([regex]::Escape($expected[$tier].model)) "routing Markdown $tier model" }
  }
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
  @{ file='research-support.toml'; tier='support' },
  @{ file='research-output.toml'; tier='economy' }
)) {
  $templateAgentPath = Join-Path $SourceRoot ('project-template\.codex\agents\' + $templateAgent.file)
  if (-not (Test-Path -LiteralPath $templateAgentPath)) { Add-Result FAIL "template $($templateAgent.file)" 'missing'; continue }
  $templateAgentText = Get-Content -Raw -Encoding UTF8 -LiteralPath $templateAgentPath
  $tierExpected = $expected[$templateAgent.tier]
  Test-Text $templateAgentText (('(?m)^model\s*=\s*"{0}"\s*$' -f [regex]::Escape($tierExpected.model))) "template $($templateAgent.file) model"
  Test-Text $templateAgentText (('(?m)^model_reasoning_effort\s*=\s*"{0}"\s*$' -f [regex]::Escape($tierExpected.effort))) "template $($templateAgent.file) reasoning"
  Test-Text $templateAgentText '(?m)^sandbox_mode\s*=\s*"read-only"\s*$' "template $($templateAgent.file) read-only"
}

$managedRoutingPath = Join-Path $SourceRoot 'project-template\.research-agent\MODEL_ROUTING.json'
if (Test-Path -LiteralPath $managedRoutingPath) {
  $canonicalHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $routingJsonPath).Hash
  $managedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $managedRoutingPath).Hash
  Add-Result $(if($managedHash -eq $canonicalHash){'PASS'}else{'FAIL'}) 'managed routing canonical snapshot' 'must be byte-identical to shared/MODEL_ROUTING.json'
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
$catalogModels = @()
if ($null -eq $codex) { Add-Result $unverifiedStatus 'Codex model catalog' 'codex command not found; use -AllowUnverifiedModelCatalog only for explicit offline/static checks' }
else {
  try {
    $catalog = (& codex debug models 2>$null) | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or $null -eq $catalog.models) { throw 'codex debug models returned no models' }
    $catalogModels=@($catalog.models)
    $available=@($catalogModels | ForEach-Object { [string]$_.slug })
    if($available.Count -eq 0){throw 'codex debug models returned an empty model list'}
    Add-Result PASS 'Codex model catalog' ($available -join ', ')
  }
  catch { Add-Result $unverifiedStatus 'Codex model catalog' $_.Exception.Message }
}

foreach($tierName in @('strategic','support','economy')){
  $tierExpected=$expected[$tierName]
  if($catalogModels.Count -eq 0){Add-Result $unverifiedStatus "$tierName model/effort availability" "$($tierExpected.model)/$($tierExpected.effort)";continue}
  $matches=@($catalogModels|Where-Object {[string]$_.slug -ceq [string]$tierExpected.model})
  $efforts=if($matches.Count -eq 1){@($matches[0].supported_reasoning_levels|ForEach-Object {[string]$_.effort})}else{@()}
  $ok=$matches.Count -eq 1 -and [string]$tierExpected.effort -cin $efforts
  Add-Result $(if($ok){'PASS'}else{'FAIL'}) "$tierName model/effort availability" "$($tierExpected.model)/$($tierExpected.effort)"
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
  if($text -match '(?m)^model\s*=\s*"([^"]+)"\s*$') {
    $model=$Matches[1]
    Add-Result $(if($available.Count -eq 0){$unverifiedStatus}elseif($model -in $available){'PASS'}else{'FAIL'}) "$agentName model availability" $model
  } else { Add-Result FAIL "$agentName model" 'missing' }
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
if($warnings -gt 0){Write-Output "FINAL WARN warnings=$warnings explicit_unverified_catalog=$([bool]$AllowUnverifiedModelCatalog)";exit 0}
Write-Output 'FINAL PASS'
