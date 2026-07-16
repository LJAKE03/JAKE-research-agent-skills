<#
.SYNOPSIS
  Create a timestamped source backup, excluding Git and old backups.
.EXAMPLE
  .\Backup-ResearchSkills.ps1
#>
[CmdletBinding(SupportsShouldProcess)]
param([string]$SourceRoot="")
$ErrorActionPreference='Stop'; if([string]::IsNullOrWhiteSpace($SourceRoot)){$SourceRoot=Split-Path -Parent $PSScriptRoot}; $version=(Get-Content -Encoding UTF8 -Raw -LiteralPath (Join-Path $SourceRoot 'VERSION')).Trim(); $dir=Join-Path $SourceRoot 'backups'; New-Item -ItemType Directory -Force -Path $dir|Out-Null; $stamp=Get-Date -Format 'yyyyMMdd-HHmmss'; $zip=Join-Path $dir "research-agent-skills-v$version-$stamp.zip"; $stage=Join-Path ([IO.Path]::GetTempPath()) "research-agent-skills-backup-$stamp"; New-Item -ItemType Directory -Path $stage|Out-Null; try{Get-ChildItem -LiteralPath $SourceRoot -Force | Where-Object Name -notin @('.git','backups') | Copy-Item -Destination $stage -Recurse -Force; if($PSCmdlet.ShouldProcess($zip,'创建压缩备份')){$archiveItems=@(Get-ChildItem -LiteralPath $stage -Force); if($archiveItems.Count -eq 0){throw '备份暂存目录为空。'}; Add-Type -AssemblyName System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::CreateFromDirectory($stage,$zip,[IO.Compression.CompressionLevel]::Optimal,$false); Write-Output "BACKUP $zip"} else {Write-Output "WHATIF $zip"}}finally{if(Test-Path -LiteralPath $stage){Remove-Item -LiteralPath $stage -Recurse -Force}}
