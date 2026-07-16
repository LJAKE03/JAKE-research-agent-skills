<#
.SYNOPSIS
  Isolated regression tests for copy-mode synchronization and ZIP backup contents.
#>
[CmdletBinding()]
param([string]$SourceRoot = '')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($SourceRoot)) { $SourceRoot = Split-Path -Parent $PSScriptRoot }
$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).ProviderPath
$syncScript = Join-Path $SourceRoot 'scripts\Sync-ResearchSkills.ps1'
$backupScript = Join-Path $SourceRoot 'scripts\Backup-ResearchSkills.ps1'
$tempParent = Join-Path ([IO.Path]::GetTempPath()) 'research-agent-file-tests'
$testRoot = Join-Path $tempParent ([Guid]::NewGuid().ToString('N'))
$fixtureRoot = Join-Path $testRoot 'source with spaces'
$installedRoot = Join-Path $testRoot 'installed skills'
$names = @('00-research-orchestrator','01-requirement-elicitation','02-research-reconnaissance','03-stage-planning-execution','04-literature-review','05-academic-writing','06-quality-gate','shared')

function Assert-Test { param([bool]$Condition,[string]$Message); if(-not $Condition){throw "FAIL $Message"}; Write-Output "PASS $Message" }
function Write-TestText {
  param([string]$Path,[string]$Text)
  $parent=Split-Path -Parent $Path
  if(-not(Test-Path -LiteralPath $parent -PathType Container)){New-Item -ItemType Directory -Path $parent -Force|Out-Null}
  [IO.File]::WriteAllText($Path,$Text,(New-Object Text.UTF8Encoding($false)))
}

$failure=$null
New-Item -ItemType Directory -Path $fixtureRoot -Force|Out-Null
try {
  Write-TestText (Join-Path $fixtureRoot 'VERSION') "test`n"
  foreach($name in $names){Write-TestText (Join-Path $fixtureRoot "$name\nested\marker.txt") "v1-$name`n"}
  $hiddenPath=Join-Path $fixtureRoot 'shared\.hidden-marker'
  Write-TestText $hiddenPath "hidden`n"
  [IO.File]::SetAttributes($hiddenPath,[IO.FileAttributes]::Hidden)

  $syncOutput=@(& $syncScript -SourceRoot $fixtureRoot -UserSkillsRoot $installedRoot)
  Assert-Test ($syncOutput.Count -eq $names.Count) 'sync reports every managed directory'
  foreach($name in $names){Assert-Test (Test-Path -LiteralPath (Join-Path $installedRoot "$name\nested\marker.txt") -PathType Leaf) "sync copied $name nested content"}
  Assert-Test (Test-Path -LiteralPath (Join-Path $installedRoot 'shared\.hidden-marker') -PathType Leaf) 'sync copied hidden content'

  Write-TestText (Join-Path $fixtureRoot '00-research-orchestrator\nested\marker.txt') "v2`n"
  $null=@(& $syncScript -SourceRoot $fixtureRoot -UserSkillsRoot $installedRoot)
  $updated=(Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $installedRoot '00-research-orchestrator\nested\marker.txt')).Trim()
  Assert-Test ($updated -eq 'v2') 'sync updates existing content'

  $backupOutput=@(& $backupScript -SourceRoot $fixtureRoot)
  $zip=@(Get-ChildItem -LiteralPath (Join-Path $fixtureRoot 'backups') -Filter '*.zip' -File)
  Assert-Test ($zip.Count -eq 1) 'backup creates one ZIP archive'
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $archive=[IO.Compression.ZipFile]::OpenRead($zip[0].FullName)
  try {$entries=@($archive.Entries|ForEach-Object {$_.FullName.Replace('\','/')})}
  finally {$archive.Dispose()}
  Assert-Test ($entries -contains 'VERSION') 'backup contains VERSION'
  Assert-Test ($entries -contains 'shared/.hidden-marker') 'backup contains hidden content'
  Assert-Test (@($entries|Where-Object {$_ -like '.git/*' -or $_ -like 'backups/*'}).Count -eq 0) 'backup excludes Git data and old backups'
  Write-Output 'RESEARCH_FILE_OPERATIONS_PASS'
}
catch {$failure=$_}
finally {
  $full=[IO.Path]::GetFullPath($testRoot)
  $base=[IO.Path]::GetFullPath($tempParent).TrimEnd('\')+'\'
  if(-not $full.StartsWith($base,[StringComparison]::OrdinalIgnoreCase)){throw "Unsafe cleanup path: $full"}
  if(Test-Path -LiteralPath $full){Remove-Item -LiteralPath $full -Recurse -Force}
  if((Test-Path -LiteralPath $tempParent) -and @(Get-ChildItem -LiteralPath $tempParent -Force).Count -eq 0){Remove-Item -LiteralPath $tempParent -Force}
}
if($null -ne $failure){throw $failure}
