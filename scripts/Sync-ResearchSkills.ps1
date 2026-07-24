<#
.SYNOPSIS
  Sync the formal source to a copy-mode installation. Never prunes by default.
.EXAMPLE
  .\Sync-ResearchSkills.ps1 -WhatIf
  .\Sync-ResearchSkills.ps1 -Prune
#>
[CmdletBinding(SupportsShouldProcess)]
param(
  [string]$SourceRoot = "",
  [string]$UserSkillsRoot = (Join-Path $env:USERPROFILE '.agents\skills'),
  [switch]$Prune
)
$ErrorActionPreference = 'Stop'
if([string]::IsNullOrWhiteSpace($SourceRoot)){$SourceRoot=Split-Path -Parent $PSScriptRoot}
$names=@('00-research-orchestrator','01-requirement-elicitation','02-research-reconnaissance','03-stage-planning-execution','04-literature-review','05-academic-writing','06-quality-gate','07-code-context','shared')
function Copy-DirectoryContents {
  param([string]$Source,[string]$Destination)
  $items=@(Get-ChildItem -LiteralPath $Source -Force)
  if($items.Count -gt 0){Copy-Item -LiteralPath $items.FullName -Destination $Destination -Recurse -Force}
}
foreach($name in $names){
  $src=Join-Path $SourceRoot $name; $dst=Join-Path $UserSkillsRoot $name
  if(-not(Test-Path -LiteralPath $src -PathType Container)){throw "源目录不存在：$src"}
  if(-not(Test-Path -LiteralPath $dst)){New-Item -ItemType Directory -Path $dst -Force|Out-Null; Copy-DirectoryContents $src $dst; Write-Output "NEW $name"; continue}
  $item=Get-Item -LiteralPath $dst -Force
  if($item.LinkType){Write-Output "SKIP $name (链接安装，无需同步)"; continue}
  $before=@(Get-ChildItem -LiteralPath $dst -Recurse -File -Force).Count
  if($PSCmdlet.ShouldProcess($dst,"复制更新 $name")){Copy-DirectoryContents $src $dst}
  $after=@(Get-ChildItem -LiteralPath $dst -Recurse -File -Force).Count
  Write-Output "UPDATED $name (files before=$before after=$after)"
  if($Prune){
    Write-Warning "已启用 -Prune：将删除目标中不在正式源的额外文件。"
    $srcRel=@(Get-ChildItem -LiteralPath $src -Recurse -File -Force | ForEach-Object {$_.FullName.Substring($src.Length).TrimStart('\')})
    Get-ChildItem -LiteralPath $dst -Recurse -File -Force | ForEach-Object { $rel=$_.FullName.Substring($dst.Length).TrimStart('\'); if($srcRel -notcontains $rel -and $PSCmdlet.ShouldProcess($_.FullName,'删除额外文件')){Remove-Item -LiteralPath $_.FullName -Force} }
  }
}
