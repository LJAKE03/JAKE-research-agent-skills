<#
.SYNOPSIS
  Create a non-overwriting research project from project-template.
.EXAMPLE
  .\New-ResearchProject.ps1 -ProjectName '氨燃料供给系统故障预测' -Destination 'D:\科研项目'
#>
[CmdletBinding(SupportsShouldProcess)]
param([Parameter(Mandatory)][ValidatePattern('^[^<>:"/\\|?*]+$')][string]$ProjectName,[Parameter(Mandatory)][string]$Destination)
$ErrorActionPreference='Stop'; $template=Join-Path (Split-Path -Parent $PSScriptRoot) 'project-template'; if(-not(Test-Path -LiteralPath $Destination)){New-Item -ItemType Directory -Path $Destination -Force|Out-Null}; $target=Join-Path ([IO.Path]::GetFullPath($Destination)) $ProjectName
if(-not(Test-Path -LiteralPath $Destination)){New-Item -ItemType Directory -Path $Destination -Force|Out-Null}; if(Test-Path -LiteralPath $target){throw "目标项目已存在，为避免覆盖而停止：$target"}; if($PSCmdlet.ShouldProcess($target,'创建科研项目')){Copy-Item -LiteralPath $template -Destination $target -Recurse; Get-ChildItem -LiteralPath $target -Recurse -File | ForEach-Object { $t=Get-Content -Encoding UTF8 -Raw -LiteralPath $_.FullName; if($null -ne $t){Set-Content -Encoding UTF8 -LiteralPath $_.FullName -Value ($t.Replace('【项目名称】',$ProjectName).Replace('研究项目名称',$ProjectName))} }; foreach($d in @('01_任务与需求','02_文献资料','03_数据','04_模型与代码','05_图表','06_阶段成果','07_论文与报告','08_质量门与复盘')){New-Item -ItemType Directory -Path (Join-Path $target $d) -Force|Out-Null}; Write-Output "项目已创建：$target"; Write-Output "启动：阅读 $target\RESEARCH_PROJECT_START_PROMPT.md 并调用 `$research-project-orchestrator"}




