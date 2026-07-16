<#
.SYNOPSIS
  Regenerates routing artifacts from shared/MODEL_ROUTING.json.
#>
[CmdletBinding(SupportsShouldProcess)]
param([string]$SourceRoot = '')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if([string]::IsNullOrWhiteSpace($SourceRoot)){$SourceRoot=Split-Path -Parent $PSScriptRoot}
$SourceRoot=(Resolve-Path -LiteralPath $SourceRoot).ProviderPath
$canonicalPath=Join-Path $SourceRoot 'shared\MODEL_ROUTING.json'
$canonicalText=[IO.File]::ReadAllText($canonicalPath)
try{$routing=$canonicalText|ConvertFrom-Json}catch{throw "canonical 路由配置无法解析：$($_.Exception.Message)"}
$utf8=New-Object Text.UTF8Encoding($false)
$changes=New-Object Collections.Generic.List[string]

function Write-TextIfChanged {
  param([string]$Path,[string]$Text,[string]$Label)
  if((Test-Path -LiteralPath $Path -PathType Leaf)-and[IO.File]::ReadAllText($Path)-ceq$Text){return}
  if($PSCmdlet.ShouldProcess($Path,$Label)){[IO.File]::WriteAllText($Path,$Text,$utf8);$changes.Add($Label)}
}

function Update-RequiredLine {
  param([string]$Text,[string]$Pattern,[string]$Replacement,[string]$Label)
  $matches=[regex]::Matches($Text,$Pattern)
  if($matches.Count-ne1){throw "$Label 期望匹配 1 行，实际 $($matches.Count) 行。"}
  return [regex]::Replace($Text,$Pattern,$Replacement)
}

$templateSnapshot=Join-Path $SourceRoot 'project-template\.research-agent\MODEL_ROUTING.json'
Write-TextIfChanged $templateSnapshot $canonicalText 'project routing snapshot'

foreach($agent in @(
  @{File='research-support.toml';Tier='support'},
  @{File='research-output.toml';Tier='economy'}
)){
  $tier=$routing.tiers.($agent.Tier)
  foreach($prefix in @('.codex\agents','project-template\.codex\agents')){
    $path=Join-Path $SourceRoot (Join-Path $prefix $agent.File)
    $text=[IO.File]::ReadAllText($path)
    $updated=Update-RequiredLine $text '(?m)^model[ \t]*=[ \t]*"[^"]+"[ \t]*(?=\r?$)' ('model = "'+[string]$tier.model+'"') "$prefix/$($agent.File) model"
    $updated=Update-RequiredLine $updated '(?m)^model_reasoning_effort[ \t]*=[ \t]*"[^"]+"[ \t]*(?=\r?$)' ('model_reasoning_effort = "'+[string]$tier.reasoning_effort+'"') "$prefix/$($agent.File) reasoning"
    $updated=Update-RequiredLine $updated '(?m)^sandbox_mode[ \t]*=[ \t]*"[^"]+"[ \t]*(?=\r?$)' ('sandbox_mode = "'+[string]$tier.sandbox_mode+'"') "$prefix/$($agent.File) sandbox"
    Write-TextIfChanged $path $updated "$prefix/$($agent.File)"
  }
}

foreach($relative in @('.codex\config.toml','project-template\.codex\config.toml')){
  $path=Join-Path $SourceRoot $relative
  $text=[IO.File]::ReadAllText($path)
  $updated=Update-RequiredLine $text '(?m)^max_threads[ \t]*=[ \t]*\d+[ \t]*(?=\r?$)' ('max_threads = '+[int]$routing.delegation.max_threads) "$relative max_threads"
  $updated=Update-RequiredLine $updated '(?m)^max_depth[ \t]*=[ \t]*\d+[ \t]*(?=\r?$)' ('max_depth = '+[int]$routing.delegation.max_depth) "$relative max_depth"
  Write-TextIfChanged $path $updated $relative
}

$pending=[ordered]@{
  status='pending'
  configuration_version=[string]$routing.configuration_version
  model_mapping_version=[string]$routing.model_mapping_version
  template_version='research-routing-v2'
  canonical_sha256=$null
  snapshot_sha256=$null
  schema_version=[int]$routing.schema_version
  conflict_count=0
  catalog=[ordered]@{
    status='pending'
    command=[string]$routing.runtime_preflight.command
    routing_models=[ordered]@{strategic=$null;support=$null;economy=$null}
    detail=$null
  }
  unavailable_tiers=@()
  last_checked_at=$null
  last_completed_at=$null
}
$pendingText=($pending|ConvertTo-Json -Depth 3)+"`n"
Write-TextIfChanged (Join-Path $SourceRoot 'project-template\.research-agent\routing-version.json') $pendingText 'project routing pending status'
Write-Output "ROUTING_ARTIFACTS_SYNC changes=$($changes.Count)"
