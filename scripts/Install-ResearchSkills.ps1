<#
.SYNOPSIS
  Install the research Skill suite as directory junctions, with safe copy fallback.
.EXAMPLE
  .\Install-ResearchSkills.ps1 -WhatIf
  .\Install-ResearchSkills.ps1
#>
[CmdletBinding(SupportsShouldProcess)]
param(
  [string]$SourceRoot = "",
  [string]$UserSkillsRoot = (Join-Path $env:USERPROFILE '.agents\skills'),
  [switch]$Copy
)
$ErrorActionPreference = 'Stop'
if([string]::IsNullOrWhiteSpace($SourceRoot)){$SourceRoot=Split-Path -Parent $PSScriptRoot}
$skillDirs = @('00-research-orchestrator','01-requirement-elicitation','02-research-reconnaissance','03-stage-planning-execution','04-literature-review','05-academic-writing','06-quality-gate','shared')
if (-not (Test-Path -LiteralPath $SourceRoot -PathType Container)) { throw "正式源目录不存在：$SourceRoot" }
New-Item -ItemType Directory -Force -Path $UserSkillsRoot | Out-Null
foreach ($name in $skillDirs) {
  $source = Join-Path $SourceRoot $name
  $target = Join-Path $UserSkillsRoot $name
  if (-not (Test-Path -LiteralPath $source -PathType Container)) { throw "源目录不存在：$source" }
  if (Test-Path -LiteralPath $target) {
    $item = Get-Item -LiteralPath $target -Force
    $resolved = try { (Resolve-Path -LiteralPath $target -ErrorAction Stop).Path } catch { '' }
    $sourceResolved = (Resolve-Path -LiteralPath $source).Path
    if ($item.LinkType -and $resolved -eq $sourceResolved) { Write-Output "SKIP $name (已链接到正式源)"; continue }
    Write-Warning "CONFLICT $target 已存在且不是本套件确认的链接；为避免覆盖，跳过。"
    continue
  }
  if ($Copy) {
    if ($PSCmdlet.ShouldProcess($target, "复制 $name")) { Copy-Item -LiteralPath $source -Destination $target -Recurse; Write-Output "COPY $name" }
  } else {
    try {
      if ($PSCmdlet.ShouldProcess($target, "创建指向正式源的目录 Junction")) { New-Item -ItemType Junction -Path $target -Target $source | Out-Null; Write-Output "LINK $name" }
    } catch {
      Write-Warning "Junction 创建失败，改用安全复制：$name；原因：$($_.Exception.Message)"
      if ($PSCmdlet.ShouldProcess($target, "复制 $name")) { Copy-Item -LiteralPath $source -Destination $target -Recurse; Write-Output "COPY-FALLBACK $name" }
    }
  }
}
Write-Output '完成：链接模式下无需同步，正式源文件修改会直接生效。复制模式请使用 Sync-ResearchSkills.ps1。'




