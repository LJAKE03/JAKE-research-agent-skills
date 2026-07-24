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
  Test-Text $configText '(?m)^model\s*=\s*"gpt-5\.6-sol"\s*$' 'root strategic model pinned'
  Test-Text $configText '(?m)^model_reasoning_effort\s*=\s*"xhigh"\s*$' 'root strategic reasoning pinned'
  Test-Text $configText '(?ms)^\[features\].*?^multi_agent\s*=\s*true\s*$' 'multi-agent explicitly enabled'
  Test-Text $configText '(?m)^\[agents\]\s*$' 'agent config section'
  Test-Text $configText '(?m)^max_threads\s*=\s*2\s*$' 'agent concurrency cap'
  Test-Text $configText '(?m)^max_depth\s*=\s*1\s*$' 'agent nesting cap'
  Test-Text $configText '(?ms)^\[agents\.research_support\].*?^config_file\s*=\s*"agents/research-support\.toml"\s*$' 'support role registered'
  Test-Text $configText '(?ms)^\[agents\.research_output\].*?^config_file\s*=\s*"agents/research-output\.toml"\s*$' 'output role registered'
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
    Test-Value ([string]$routing.workflow.default) 'unified' 'routing JSON unified workflow'
    Test-Value ([int]$routing.workflow.max_initial_blocking_questions) 2 'routing JSON blocking-question cap'
    Test-Value ([string]$routing.runtime_dispatch.support_agent_type) 'research_support' 'routing JSON support agent type'
    Test-Value ([string]$routing.runtime_dispatch.economy_agent_type) 'research_output' 'routing JSON output agent type'
    Test-Value ([string]$routing.runtime_dispatch.fork_turns) 'none' 'routing JSON specialized fork mode'
    Test-Value ([string]$routing.runtime_dispatch.preferred_call_shape) 'agent_type' 'routing JSON preferred spawn call shape'
    Test-Value ([string]$routing.runtime_dispatch.compatible_call_shape) 'explicit_model' 'routing JSON compatible spawn call shape'
    Test-Value ([string]$routing.runtime_dispatch.isolated_call_shape) 'codex_exec' 'routing JSON isolated call shape'
    Test-Value ([bool]$routing.runtime_dispatch.require_runtime_evidence) $true 'routing JSON requires runtime evidence'
    Test-Value ([bool]$routing.runtime_dispatch.require_spawn_evidence) $true 'routing JSON requires spawn evidence'
    Test-Value ([bool]$routing.runtime_dispatch.self_report_is_evidence) $false 'routing JSON rejects self-report evidence'
    Test-Value ([string]$routing.runtime_dispatch.failure_status) 'degraded_sol_only' 'routing JSON dispatch failure status'
    Test-Value (@($routing.workflow.sol_semantic_acceptance_when)-join ',') 'publication_or_submission,key_parameter_or_core_method,safety_or_high_cost_decision,scientific_final_acceptance' 'routing JSON Sol acceptance triggers'
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

$handoffSchemaPath = Join-Path $SourceRoot 'shared\STAGE_HANDOFF.schema.json'
$handoffExamplePath = Join-Path $SourceRoot 'shared\STAGE_HANDOFF.example.json'
foreach($contract in @(
  @{ Schema=$handoffSchemaPath; Instance=$handoffExamplePath; Label='research handoff' }
)) {
  if(-not(Test-Path -LiteralPath $contract.Schema -PathType Leaf) -or -not(Test-Path -LiteralPath $contract.Instance -PathType Leaf)) {
    Add-Result FAIL "$($contract.Label) Schema validation" 'schema or instance missing'
    continue
  }
  try {
    $contractSchema=Get-Content -Raw -Encoding UTF8 -LiteralPath $contract.Schema|ConvertFrom-Json
    Test-Value ([string]$contractSchema.'$schema') 'https://json-schema.org/draft/2020-12/schema' "$($contract.Label) schema declaration"
  } catch { Add-Result FAIL "$($contract.Label) schema parse" $_.Exception.Message }
  $contractPython=Get-Command python -ErrorAction SilentlyContinue
  if($null -eq $contractPython -or -not(Test-Path -LiteralPath $schemaValidatorPath -PathType Leaf)) {
    Add-Result $unverifiedStatus "$($contract.Label) Schema validation" 'python/jsonschema validator unavailable'
  } else {
    $contractOutput=@(& $contractPython.Source $schemaValidatorPath $contract.Schema $contract.Instance 2>&1)
    $contractExit=$LASTEXITCODE
    if($contractExit -eq 0){Add-Result PASS "$($contract.Label) Schema validation" ($contractOutput -join '; ')}
    elseif($contractExit -eq 3 -and $AllowUnverifiedModelCatalog){Add-Result WARN "$($contract.Label) Schema validation" ($contractOutput -join '; ')}
    else{Add-Result FAIL "$($contract.Label) Schema validation" ($contractOutput -join '; ')}
  }
}

$handoffTemplate=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $SourceRoot 'shared\STAGE_HANDOFF.template.md')
foreach($field in @('objective','input_locators','locked_decisions','output_contract','acceptance_checks','stop_conditions','handoff_type','summary','deliverable','evidence_locations','uncertainties','changed_files','next_action')) {
  Test-Text $handoffTemplate ([regex]::Escape($field)) "handoff template $field"
}

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
  Test-Text $templateConfig '(?m)^model\s*=\s*"gpt-5\.6-sol"\s*$' 'template strategic model pinned'
  Test-Text $templateConfig '(?m)^model_reasoning_effort\s*=\s*"xhigh"\s*$' 'template strategic reasoning pinned'
  Test-Text $templateConfig '(?ms)^\[features\].*?^multi_agent\s*=\s*true\s*$' 'template multi-agent enabled'
  Test-Text $templateConfig '(?m)^max_threads\s*=\s*2\s*$' 'template concurrency cap'
  Test-Text $templateConfig '(?m)^max_depth\s*=\s*1\s*$' 'template nesting cap'
  Test-Text $templateConfig '(?m)^\[agents\.research_support\]\s*$' 'template support role registration'
  Test-Text $templateConfig '(?m)^\[agents\.research_output\]\s*$' 'template output role registration'
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
  foreach($field in @('handoff_type','summary','deliverable','evidence_locations','uncertainties','changed_files','next_action')) { Test-Text $templateAgentText ([regex]::Escape($field)) "template $($templateAgent.file) handoff $field" }
  Test-Text $templateAgentText 'Do not contact another worker' "template $($templateAgent.file) single-hop return"
}

$managedRoutingPath = Join-Path $SourceRoot 'project-template\.research-agent\MODEL_ROUTING.json'
if (Test-Path -LiteralPath $managedRoutingPath) {
  $canonicalHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $routingJsonPath).Hash
  $managedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $managedRoutingPath).Hash
  Add-Result $(if($managedHash -eq $canonicalHash){'PASS'}else{'FAIL'}) 'managed routing canonical snapshot' 'must be byte-identical to shared/MODEL_ROUTING.json'
} else { Add-Result FAIL 'managed routing JSON' 'missing' }

$templateAgentsPath = Join-Path $SourceRoot 'project-template\AGENTS.md'
$templateAgentsText = Get-Content -Raw -Encoding UTF8 -LiteralPath $templateAgentsPath
foreach($token in @('research-agent-routing:start','research-agent-routing:end','Sol','Terra','Luna','PowerShell','Python','`rg`','`git diff`','Get-Content -Encoding UTF8','紧凑交接 Schema')) { Test-Text $templateAgentsText ([regex]::Escape($token)) "template AGENTS $token" }

foreach($skillName in @('00-research-orchestrator','01-requirement-elicitation','02-research-reconnaissance','03-stage-planning-execution','04-literature-review','05-academic-writing','06-quality-gate','07-code-context')) {
  $skillText = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $SourceRoot "$skillName\SKILL.md")
  Test-Text $skillText 'routing-preflight:required' "$skillName routing preflight"
  Test-Text $skillText '\.\./shared/MODEL_ROUTING\.json' "$skillName routing reference"
  Test-NoText $skillText '\bFast\b|\bStandard\b|\bStrict\b(?!-)|\bExploratory\b|\bDirect\b|\bFocused\b|Open Research|快速 / 标准 / 严格|推荐运行模式' "$skillName has no public workflow mode"
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
  foreach($field in @('handoff_type','summary','deliverable','evidence_locations','uncertainties','changed_files','next_action')) { Test-Text $text ([regex]::Escape($field)) "$agentName handoff $field" }
  Test-Text $text 'Do not contact another worker' "$agentName single-hop return"
  if($agentName -eq 'research-support') {
    Test-Text $text 'must not select the research direction' 'support judgement boundary'
    Test-Text $text 'evidence table' 'support evidence-table responsibility'
    Test-Text $text 'Do not edit files' 'support edit boundary'
  }
  else {
    Test-Text $text 'locked writing package' 'output locked-package boundary'
    Test-Text $text 'Generate coherent prose' 'output drafting responsibility'
    Test-Text $text 'Never introduce a new fact' 'output no-new-facts boundary'
    Test-Text $text 'Do not edit files' 'output edit boundary'
  }
}

$orchestrator=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $SourceRoot '00-research-orchestrator\SKILL.md')
Test-Text $orchestrator '一条连续科研流程' 'single research workflow'
Test-Text $orchestrator 'Sol 理解需求.*选择方法' 'Sol strategic responsibility'
Test-Text $orchestrator 'Terra.*检索、查证、扫描、提取和证据表' 'Terra evidence responsibility'
Test-Text $orchestrator 'Luna.*锁定写作包.*生成文本' 'Luna drafting responsibility'
Test-Text $orchestrator '用户不需要选择模型、Agent 或工作模式' 'automatic user-facing routing'
Test-Text $orchestrator 'PowerShell' 'PowerShell boundary'
Test-Text $orchestrator 'Python' 'Python boundary'
Test-Text $orchestrator '`rg`/`rg --files`' 'native search boundary'
Test-Text $orchestrator '`git diff`' 'Git inspection boundary'
Test-Text $orchestrator 'Large results must be written to files\.' 'output control'
Test-Text $orchestrator 'STAGE_HANDOFF\.schema\.json' 'compact handoff schema reference'
Test-Text $orchestrator 'agent_type=research_support.*fork_turns=none' 'orchestrator preferred Terra dispatch'
Test-Text $orchestrator 'agent_type=research_output.*fork_turns=none' 'orchestrator preferred Luna dispatch'
Test-Text $orchestrator 'task_name=research_support, model=gpt-5\.6-terra, reasoning_effort=medium, fork_turns=none' 'orchestrator compatible Terra dispatch'
Test-Text $orchestrator 'task_name=research_output, model=gpt-5\.6-luna, reasoning_effort=low, fork_turns=none' 'orchestrator compatible Luna dispatch'
Test-Text $orchestrator 'codex --disable multi_agent exec.*--ephemeral.*--sandbox read-only -m gpt-5\.6-terra.*reasoning_effort="medium"' 'orchestrator isolated Terra dispatch'
Test-Text $orchestrator 'Luna 使用相同命令但模型为 .*gpt-5\.6-luna.*reasoning 为 .*low' 'orchestrator isolated Luna dispatch'
Test-Text $orchestrator '真实创建的子线程、成功的 spawn 工具结果.*一次性 .*codex exec' 'orchestrator runtime evidence rule'
Test-Text $orchestrator 'degraded_sol_only' 'orchestrator transparent dispatch fallback'
Test-Text $orchestrator '07-code-context/SKILL\.md' 'orchestrator code-context route'
$codeContext = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $SourceRoot '07-code-context\SKILL.md')
foreach($token in @('codegraph_explore','rg --files','Code Context Capsule','freshness','verification_targets','STAGE_HANDOFF.schema.json','changed_files=[]')) {
  Test-Text $codeContext ([regex]::Escape($token)) "code context $token"
}
Test-Text $codeContext '不自动安装|不要安装软件' 'code context never auto-installs backend'
Test-Text $codeContext '回退流程' 'code context native fallback'
Test-Text $codeContext '不是最终科学证据' 'code context scientific evidence boundary'
Test-Text $codeContext '一次收窄重试是上限' 'code context bounded retry'
Test-NoText $codeContext '(?m)^\s*(codegraph|npm|npx)\s+(install|init)' 'code context contains no installation command'
$codeContextEvals = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $SourceRoot '07-code-context\evals\evals.json') | ConvertFrom-Json
Test-Value ([string]$codeContextEvals.skill_name) 'research-code-context' 'code context eval skill name'
Test-Value (@($codeContextEvals.evals).Count) 3 'code context eval count'

$academicWriting = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $SourceRoot '05-academic-writing\SKILL.md')
Test-Text $academicWriting '不得写成由用户显式选择模型、Agent 或模式' 'Luna routing wording acceptance'
foreach($field in @('objective','input_locators','locked_decisions','output_contract','acceptance_checks','stop_conditions')) { Test-Text $orchestrator ([regex]::Escape($field)) "orchestrator task-card $field" }
Test-NoText $orchestrator '\bFast\b|\bStandard\b|\bStrict\b(?!-)|\bExploratory\b|\bDirect\b|\bFocused\b|Open Research|CAPABILITY_MANIFEST|RUNTIME_POLICY|Write-ResearchRuntimeEvent' 'no public lanes or runtime framework'
$qualityGate=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $SourceRoot '06-quality-gate\SKILL.md')
foreach($gate in @('L0','L1','L2')) { Test-Text $qualityGate ([regex]::Escape($gate)) "quality gate $gate" }
Test-Text $qualityGate 'Sol 只做一次紧凑语义验收' 'compact Sol acceptance'
Test-Text $qualityGate '不新增独立 Reviewer Agent' 'quality gate no extra reviewer'
$stagePlanning=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $SourceRoot '03-stage-planning-execution\SKILL.md')
Test-Text $stagePlanning '真实依赖' 'dependency-driven planning'
Test-Text $stagePlanning '不设置默认阶段数' 'no fixed stage count'
Test-Text $stagePlanning '完整对话、全部项目状态、全部工具日志' 'bounded planning context'
$suiteIndex=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $SourceRoot 'SKILL.md')
$routingExamples=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $SourceRoot 'shared\ROUTING_EXAMPLES.md')
$evals=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $SourceRoot 'evals\evals.json')|ConvertFrom-Json
Test-Value ([string]$evals.runtime_assertions.support_agent_type) 'research_support' 'eval support agent type'
Test-Value ([string]$evals.runtime_assertions.economy_agent_type) 'research_output' 'eval output agent type'
Test-Value ([string]$evals.runtime_assertions.fork_turns) 'none' 'eval specialized fork mode'
Test-Value ([string]$evals.runtime_assertions.preferred_call_shape) 'agent_type' 'eval preferred spawn call shape'
Test-Value ([string]$evals.runtime_assertions.compatible_call_shape) 'explicit_model' 'eval compatible spawn call shape'
Test-Value ([string]$evals.runtime_assertions.isolated_call_shape) 'codex_exec' 'eval isolated call shape'
Test-Value ([bool]$evals.runtime_assertions.require_runtime_evidence) $true 'eval requires runtime evidence'
Test-Value ([bool]$evals.runtime_assertions.require_spawn_evidence) $true 'eval requires spawn evidence'
Test-Value ([bool]$evals.runtime_assertions.self_report_is_evidence) $false 'eval rejects self-report evidence'
Test-Text $suiteIndex '一条统一科研流程' 'suite index unified workflow'
Test-Text $routingExamples '同一流程' 'routing examples unified workflow'
Test-NoText ($suiteIndex + $routingExamples) '\bFast\b|\bStandard\b|\bStrict\b(?!-)|\bExploratory\b|\bDirect\b|\bFocused\b|Open Research' 'index and examples have no public modes'
$qualityRubric=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $SourceRoot 'shared\QUALITY_RUBRIC.md')
Test-Text $qualityRubric '完整历史、全部日志或整篇原文' 'quality rubric compact context'
$launcherText=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $SourceRoot 'scripts\Start-ResearchAgent.ps1')
Test-Text $launcherText '一条统一科研流程' 'launcher unified workflow'
Test-Text $launcherText '(?s)Sol.*Terra.*Luna' 'launcher automatic model responsibilities'
Test-Text $launcherText 'Worker 不互相转交' 'launcher single-hop boundary'
Test-Text $launcherText 'agent_type=research_support, fork_turns=none' 'launcher preferred Terra spawn instruction'
Test-Text $launcherText 'agent_type=research_output, fork_turns=none' 'launcher preferred Luna spawn instruction'
Test-Text $launcherText 'task_name=research_support, model=gpt-5\.6-terra, reasoning_effort=medium, fork_turns=none' 'launcher compatible Terra spawn instruction'
Test-Text $launcherText 'task_name=research_output, model=gpt-5\.6-luna, reasoning_effort=low, fork_turns=none' 'launcher compatible Luna spawn instruction'
Test-Text $launcherText 'codex --disable multi_agent exec --strict-config --ephemeral --ignore-user-config --json --color never --sandbox read-only' 'launcher isolated Codex instruction'
Test-Text $launcherText '用 -m 和 model_reasoning_effort 锁定 Terra/Luna' 'launcher isolated model lock'
Test-Text $launcherText '真实子线程、成功 spawn.*退出码为 0' 'launcher runtime evidence rule'
Test-NoText $launcherText '\bFast\b|\bStandard\b|\bStrict\b(?!-)|\bExploratory\b|\bDirect\b|\bFocused\b|Open Research|CAPABILITY_MANIFEST|RUNTIME_POLICY' 'launcher has no public modes or runtime framework'

$results | Format-Table -AutoSize
$failures=@($results|Where-Object Status -eq 'FAIL').Count
$warnings=@($results|Where-Object Status -eq 'WARN').Count
if($failures -gt 0){Write-Output "FINAL FAIL failures=$failures warnings=$warnings";exit 1}
if($warnings -gt 0){Write-Output "FINAL WARN warnings=$warnings explicit_unverified_catalog=$([bool]$AllowUnverifiedModelCatalog)";exit 0}
Write-Output 'FINAL PASS'
