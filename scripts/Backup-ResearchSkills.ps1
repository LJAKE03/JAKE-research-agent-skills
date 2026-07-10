<#
.SYNOPSIS
  Create a timestamped source backup, excluding Git and old backups.
.EXAMPLE
  .\Backup-ResearchSkills.ps1
#>
[CmdletBinding(SupportsShouldProcess)]
param([string]$SourceRoot="")
$ErrorActionPreference='Stop'; if([string]::IsNullOrWhiteSpace($SourceRoot)){$SourceRoot=Split-Path -Parent $PSScriptRoot}; $version=(Get-Content -Encoding UTF8 -Raw -LiteralPath (Join-Path $SourceRoot 'VERSION')).Trim(); $dir=Join-Path $SourceRoot 'backups'; New-Item -ItemType Directory -Force -Path $dir|Out-Null; $stamp=Get-Date -Format 'yyyyMMdd-HHmmss'; $zip=Join-Path $dir "research-agent-skills-v$version-$stamp.zip"; $stage=Join-Path ([IO.Path]::GetTempPath()) "research-agent-skills-backup-$stamp"; New-Item -ItemType Directory -Path $stage|Out-Null; try{Get-ChildItem -LiteralPath $SourceRoot -Force | Where-Object Name -notin @('.git','backups') | Copy-Item -Destination $stage -Recurse -Force; if($PSCmdlet.ShouldProcess($zip,'创建压缩备份')){Compress-Archive -LiteralPath (Join-Path $stage '*') -DestinationPath $zip -CompressionLevel Optimal; Write-Output "BACKUP $zip"} else {Write-Output "WHATIF $zip"}}finally{if(Test-Path -LiteralPath $stage){Remove-Item -LiteralPath $stage -Recurse -Force}}







