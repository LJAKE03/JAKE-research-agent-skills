<#
.SYNOPSIS
  Windows launcher for Research Agent Skills projects.
.DESCRIPTION
  Provides safe project creation, opening, recent-project recovery, Skills checks,
  Codex Desktop launch with a copied project-aware prompt, and a D-drive
  non-interactive self-test.
.PARAMETER RepositoryRoot
  Formal repository root. Defaults to the parent of this script.
.PARAMETER ValidateOnly
  Runs self-test without opening GUI or Codex.
.PARAMETER NoGui
  Forces console input.
#>
[CmdletBinding()]
param(
  [string]$RepositoryRoot = '',
  [switch]$ValidateOnly,
  [switch]$NoGui,
  [switch]$PendingCheckOnly,
  [string]$PendingProjectDirectory = '',
  [switch]$RoutingPreflightOnly,
  [string]$RoutingProjectDirectory = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
  if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
    if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) { throw '无法确定正式仓库根目录。' }
    $RepositoryRoot = Split-Path -Parent $PSScriptRoot
  }
  $RepositoryRoot = ([string]$RepositoryRoot).Trim().Trim('"')
  if ([string]::IsNullOrWhiteSpace($RepositoryRoot) -or $RepositoryRoot.Contains([Environment]::NewLine)) {
    throw '正式仓库根目录无效。'
  }
  if (-not (Test-Path -LiteralPath $RepositoryRoot -PathType Container)) {
    throw "正式仓库根目录不存在：$RepositoryRoot"
  }
  $script:RepositoryRoot = (Resolve-Path -LiteralPath $RepositoryRoot).ProviderPath
  $script:ScriptsRoot = Join-Path $script:RepositoryRoot 'scripts'
  $script:RoutingInitializer = Join-Path $script:ScriptsRoot 'Initialize-ResearchProjectRouting.ps1'
  $script:TemplateRoot = Join-Path $script:RepositoryRoot 'project-template'
  $script:SettingsPath = Join-Path $script:ScriptsRoot 'research-launcher-settings.json'
  $script:RequiredFiles = @('AGENTS.md','PROJECT_STATE.md','PROJECT_OVERRIDES.md','SKILL_FEEDBACK.md','RESEARCH_PROJECT_START_PROMPT.md')
  $script:IdentityFiles = @('AGENTS.md','PROJECT_STATE.md')
  $script:GuiAvailable = $false
}
catch {
  Write-Host "科研 Agent 启动器初始化失败：$($_.Exception.Message)" -ForegroundColor Red
  exit 1
}

function Initialize-Ui {
  if ($NoGui -or -not [Environment]::UserInteractive) { return }
  try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    [Windows.Forms.Application]::EnableVisualStyles()
    $script:GuiAvailable = $true
  } catch {
    Write-Warning "图形界面不可用，已回退到控制台：$($_.Exception.Message)"
  }
}

function Show-Message {
  param([string]$Text,[string]$Title='科研 Agent Skills',[switch]$Error)
  if ($script:GuiAvailable) {
    try {
      $icon = if($Error){[Windows.Forms.MessageBoxIcon]::Error}else{[Windows.Forms.MessageBoxIcon]::Information}
      [void][Windows.Forms.MessageBox]::Show($Text,$Title,[Windows.Forms.MessageBoxButtons]::OK,$icon)
      return
    } catch { $script:GuiAvailable = $false }
  }
  if($Error){Write-Host $Text -ForegroundColor Red}else{Write-Host $Text}
}

function Confirm-Action {
  param([string]$Text,[string]$Title='确认操作')
  if ($script:GuiAvailable) {
    try {
      return ([Windows.Forms.MessageBox]::Show($Text,$Title,[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Question) -eq [Windows.Forms.DialogResult]::Yes)
    } catch { $script:GuiAvailable = $false }
  }
  return ((Read-Host ($Text+[Environment]::NewLine+'输入 Y 确认')) -match '^[Yy]$')
}

function Read-Text {
  param([string]$Prompt,[string]$Title='科研 Agent Skills',[string]$Default='')
  if ($script:GuiAvailable) {
    try {
      Add-Type -AssemblyName Microsoft.VisualBasic -ErrorAction Stop
      return [Microsoft.VisualBasic.Interaction]::InputBox($Prompt,$Title,$Default)
    } catch { $script:GuiAvailable = $false }
  }
  if([string]::IsNullOrWhiteSpace($Default)){return (Read-Host $Prompt)}
  $value=Read-Host ($Prompt+[Environment]::NewLine+"直接回车使用：$Default")
  if([string]::IsNullOrWhiteSpace($value)){return $Default}
  return $value
}

function Select-Folder {
  param([string]$Description,[string]$Initial='')
  if($script:GuiAvailable){
    $dialog=$null
    try {
      $dialog=New-Object Windows.Forms.FolderBrowserDialog
      $dialog.Description=$Description
      $dialog.ShowNewFolderButton=$true
      if((Test-Path -LiteralPath $Initial -PathType Container)){$dialog.SelectedPath=$Initial}
      if($dialog.ShowDialog() -eq [Windows.Forms.DialogResult]::OK){return $dialog.SelectedPath}
      return $null
    } catch {$script:GuiAvailable=$false}
    finally {if($null -ne $dialog){$dialog.Dispose()}}
  }
  $value=Read-Host ($Description+'（输入路径；直接回车取消）')
  if([string]::IsNullOrWhiteSpace($value)){return $null}
  return $value.Trim().Trim('"')
}

function Show-Menu {
  if($script:GuiAvailable){
    $form=$null
    try {
      $form=New-Object Windows.Forms.Form
      $form.Text='科研 Agent Skills 协同系统'
      $form.StartPosition='CenterScreen'
      $form.ClientSize=New-Object Drawing.Size -ArgumentList 370,270
      $form.FormBorderStyle='FixedDialog'
      $form.MaximizeBox=$false
      $label=New-Object Windows.Forms.Label
      $label.Text='请选择操作：'
      $label.AutoSize=$true
      $label.Location=New-Object Drawing.Point -ArgumentList 24,20
      [void]$form.Controls.Add($label)
      $list=New-Object Windows.Forms.ListBox
      $list.Location=New-Object Drawing.Point -ArgumentList 24,48
      $list.Size=New-Object Drawing.Size -ArgumentList 322,130
      foreach($item in @('1. 新建科研项目','2. 打开已有科研项目','3. 打开最近一次项目','4. 仅检查科研 Skills','5. 退出')){[void]$list.Items.Add($item)}
      $list.SelectedIndex=0
      [void]$form.Controls.Add($list)
      $ok=New-Object Windows.Forms.Button
      $ok.Text='确定';$ok.Location=New-Object Drawing.Point -ArgumentList 190,205;$ok.DialogResult=[Windows.Forms.DialogResult]::OK
      $form.AcceptButton=$ok;[void]$form.Controls.Add($ok)
      $cancel=New-Object Windows.Forms.Button
      $cancel.Text='退出';$cancel.Location=New-Object Drawing.Point -ArgumentList 271,205;$cancel.DialogResult=[Windows.Forms.DialogResult]::Cancel
      $form.CancelButton=$cancel;[void]$form.Controls.Add($cancel)
      if($form.ShowDialog() -eq [Windows.Forms.DialogResult]::OK){return [string]($list.SelectedIndex+1)}
      return '5'
    } catch {$script:GuiAvailable=$false}
    finally {if($null -ne $form){$form.Dispose()}}
  }
  Write-Host ''
  Write-Host '科研 Agent Skills 协同系统'
  Write-Host '1. 新建科研项目'
  Write-Host '2. 打开已有科研项目'
  Write-Host '3. 打开最近一次项目'
  Write-Host '4. 仅检查科研 Skills'
  Write-Host '5. 退出'
  return (Read-Host '请选择 (1-5)')
}

function Resolve-Directory {
  param([object]$Path)
  if($Path -isnot [string] -or [string]::IsNullOrWhiteSpace([string]$Path)){return $null}
  try {
    $value=([string]$Path).Trim().Trim('"')
    if(Test-Path -LiteralPath $value -PathType Container){return (Resolve-Path -LiteralPath $value).ProviderPath}
  } catch {}
  return $null
}

function Test-Project {
  param([object]$Path)
  $dir=Resolve-Directory $Path
  if([string]::IsNullOrWhiteSpace($dir)){return $false}
  foreach($file in $script:IdentityFiles){if(-not(Test-Path -LiteralPath (Join-Path $dir $file) -PathType Leaf)){return $false}}
  return $true
}

function New-DefaultSettings {
  [pscustomobject]@{
    RecentProjectPath=''
    RecentProjects=@()
    DefaultProjectDirectory=(Split-Path -Parent $script:RepositoryRoot)
    LastUsedAt=''
  }
}

function Save-Settings {
  param($Settings)
  $data=[ordered]@{
    RecentProjectPath=[string]$Settings.RecentProjectPath
    RecentProjects=@($Settings.RecentProjects)
    DefaultProjectDirectory=[string]$Settings.DefaultProjectDirectory
    LastUsedAt=[string]$Settings.LastUsedAt
  }
  $tmp=$script:SettingsPath+'.tmp'
  [IO.File]::WriteAllText($tmp,($data|ConvertTo-Json -Depth 3),[Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $tmp -Destination $script:SettingsPath -Force
}

function Get-Settings {
  $default=New-DefaultSettings
  $loaded=$null
  if(Test-Path -LiteralPath $script:SettingsPath -PathType Leaf){
    try{$loaded=Get-Content -LiteralPath $script:SettingsPath -Encoding UTF8 -Raw|ConvertFrom-Json}catch{Write-Warning '启动器配置损坏，已安全恢复默认值。'}
  }
  $candidates=@()
  if($null -ne $loaded -and $null -ne $loaded.PSObject.Properties['RecentProjects']){
    if($loaded.RecentProjects -is [string]){$candidates=@($loaded.RecentProjects)}
    elseif($loaded.RecentProjects -is [Collections.IEnumerable]){$candidates=@($loaded.RecentProjects)}
  }
  $list=[Collections.Generic.List[string]]::new()
  foreach($candidate in $candidates){
    if($candidate -isnot [string] -or -not(Test-Project $candidate)){continue}
    $item=Resolve-Directory $candidate
    if(@($list|Where-Object{$_.Equals($item,[StringComparison]::OrdinalIgnoreCase)}).Count -eq 0){[void]$list.Add($item)}
    if($list.Count -ge 10){break}
  }
  $recent=''
  if($null -ne $loaded -and $null -ne $loaded.PSObject.Properties['RecentProjectPath'] -and $loaded.RecentProjectPath -is [string] -and (Test-Project $loaded.RecentProjectPath)){
    $recent=Resolve-Directory $loaded.RecentProjectPath
    [void]$list.Remove($recent);$list.Insert(0,$recent)
  } elseif($list.Count -gt 0){$recent=$list[0]}
  if($list.Count -gt 10){$list.RemoveAt(10)}
  $destination=$default.DefaultProjectDirectory
  if($null -ne $loaded -and $null -ne $loaded.PSObject.Properties['DefaultProjectDirectory']){
    $candidate=Resolve-Directory $loaded.DefaultProjectDirectory
    if($candidate){$destination=$candidate}
  }
  $last=''
  if($null -ne $loaded -and $null -ne $loaded.PSObject.Properties['LastUsedAt'] -and $loaded.LastUsedAt -is [string]){$last=$loaded.LastUsedAt}
  $settings=[pscustomobject]@{RecentProjectPath=$recent;RecentProjects=@($list.ToArray());DefaultProjectDirectory=$destination;LastUsedAt=$last}
  Save-Settings $settings
  return $settings
}

function Update-Recent {
  param([string]$Project,[object]$Settings)
  if(-not(Test-Project $Project)){throw "不能记录无效科研项目：$Project"}
  $root=Resolve-Directory $Project
  $list=[Collections.Generic.List[string]]::new()
  [void]$list.Add($root)
  foreach($old in @($Settings.RecentProjects)){
    if($old -isnot [string] -or -not(Test-Project $old)){continue}
    $item=Resolve-Directory $old
    if(@($list|Where-Object{$_.Equals($item,[StringComparison]::OrdinalIgnoreCase)}).Count -eq 0){[void]$list.Add($item)}
    if($list.Count -ge 10){break}
  }
  $Settings.RecentProjects=@($list.ToArray())
  $Settings.RecentProjectPath=$root
  $Settings.LastUsedAt=(Get-Date).ToString('o')
  Save-Settings $Settings
}

function Get-MissingFiles {
  param([string]$Project,[string[]]$Files=$script:RequiredFiles)
  return @($Files|Where-Object{-not(Test-Path -LiteralPath (Join-Path $Project $_) -PathType Leaf)})
}

function Write-NewTextFile {
  param([string]$Path,[string]$Content)
  $stream=$null;$writer=$null
  try{
    $stream=[IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    $writer=[IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($true))
    $writer.Write($Content)
  } finally {
    if($writer){$writer.Dispose()}elseif($stream){$stream.Dispose()}
  }
}

function Initialize-MissingFiles {
  param([string]$Project,[switch]$AssumeYes)
  $missing=@(Get-MissingFiles $Project)
  if($missing.Count -eq 0){return $true}
  foreach($file in $missing){if(-not(Test-Path -LiteralPath (Join-Path $script:TemplateRoot $file) -PathType Leaf)){throw "项目模板缺少文件：$file"}}
  $message='将仅新增以下缺失模板文件，不会覆盖已有文件：'+[Environment]::NewLine+[Environment]::NewLine+(($missing|ForEach-Object{'- '+$_})-join [Environment]::NewLine)+[Environment]::NewLine+[Environment]::NewLine+'是否继续安全初始化？'
  if(-not $AssumeYes -and -not(Confirm-Action $message '安全初始化项目')){return $false}
  $name=Split-Path -Leaf $Project
  foreach($file in $missing){
    $target=Join-Path $Project $file
    if(Test-Path -LiteralPath $target){continue}
    $text=Get-Content -LiteralPath (Join-Path $script:TemplateRoot $file) -Encoding UTF8 -Raw
    $text=$text.Replace('【项目名称】',$name).Replace('研究项目名称',$name)
    try{Write-NewTextFile $target $text}catch [IO.IOException]{if(-not(Test-Path -LiteralPath $target)){throw}}
  }
  return (@(Get-MissingFiles $Project).Count -eq 0)
}

function Validate-ProjectName {
  param([string]$Name)
  $value=$Name.Trim()
  if([string]::IsNullOrWhiteSpace($value) -or $value -in @('.','..')){throw '项目名称无效。'}
  if($value.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0 -or $value.EndsWith('.') -or $value.EndsWith(' ')){throw '项目名称包含 Windows 不允许的格式。'}
  if($value -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\..*)?$'){throw '项目名称是 Windows 保留设备名。'}
  return $value
}

function Invoke-NewProject {
  param([string]$Name,[string]$Destination,[switch]$Quiet)
  $name=Validate-ProjectName $Name
  $dest=Resolve-Directory $Destination
  if(-not $dest){throw "项目保存目录不存在：$Destination"}
  $target=[IO.Path]::GetFullPath((Join-Path $dest $name))
  if(-not([IO.Path]::GetFullPath((Split-Path -Parent $target)).Equals([IO.Path]::GetFullPath($dest),[StringComparison]::OrdinalIgnoreCase))){throw '项目目标路径无效。'}
  if(Test-Path -LiteralPath $target){throw "目标项目已存在，为避免覆盖而停止：$target"}
  $scriptPath=Join-Path $script:ScriptsRoot 'New-ResearchProject.ps1'
  $output=@(& $scriptPath -ProjectName $name -Destination $dest)
  if(-not $Quiet){$output|ForEach-Object{Write-Host $_}}
  $missing=@(Get-MissingFiles $target)
  if($missing.Count){throw "项目创建后缺少文件：$($missing -join ', ')"}
  return [string]$target
}

function New-ProjectInteractive {
  param($Settings)
  while($true){
    $input=Read-Text '请输入项目名称：' '新建科研项目'
    if([string]::IsNullOrWhiteSpace($input)){return $null}
    $destination=Select-Folder '请选择科研项目保存目录' $Settings.DefaultProjectDirectory
    if(-not $destination){return $null}
    try{
      $project=Invoke-NewProject $input $destination
      $Settings.DefaultProjectDirectory=Resolve-Directory $destination
      Save-Settings $Settings
      return $project
    }catch{Show-Message ($_.Exception.Message+[Environment]::NewLine+'未覆盖或删除任何已有项目。') '新建科研项目失败' -Error}
  }
}

function Confirm-ProjectReady {
  param([string]$Project,[switch]$AssumeYes)
  $path=Resolve-Directory $Project
  if(-not $path){return $null}
  if(@(Get-MissingFiles $path).Count -gt 0){
    if(-not(Initialize-MissingFiles $path -AssumeYes:$AssumeYes)){return $null}
  }
  if(-not(Test-Project $path)){throw "该目录缺少 AGENTS.md 或 PROJECT_STATE.md：$path"}
  $routingOutput=@(& $script:RoutingInitializer -ProjectDirectory $path -RepositoryRoot $script:RepositoryRoot)
  $routingOutput|ForEach-Object{Write-Host $_}
  $versionPath=Join-Path $path '.research-agent\routing-version.json'
  if(-not(Test-Path -LiteralPath $versionPath -PathType Leaf)){throw "科研路由补齐未完成：$path"}
  try{$routingStatus=Get-Content -Raw -Encoding UTF8 -LiteralPath $versionPath|ConvertFrom-Json}catch{throw "科研路由状态无效：$($_.Exception.Message)"}
  if([int]$routingStatus.conflict_count -ne 0){throw "Routing conflicts remain: $($routingStatus.conflict_count)"}
  $canonicalPath=Join-Path $script:RepositoryRoot 'shared\MODEL_ROUTING.json'
  $canonicalHash=(Get-FileHash -Algorithm SHA256 -LiteralPath $canonicalPath).Hash
  $snapshotPath=Join-Path $path '.research-agent\MODEL_ROUTING.json'
  if(-not(Test-Path -LiteralPath $snapshotPath -PathType Leaf)){throw 'Project routing snapshot is missing.'}
  $snapshotHash=(Get-FileHash -Algorithm SHA256 -LiteralPath $snapshotPath).Hash
  if([string]$routingStatus.canonical_sha256 -ne $canonicalHash -or [string]$routingStatus.snapshot_sha256 -ne $snapshotHash -or $snapshotHash -ne $canonicalHash){throw 'Routing snapshot or status hash mismatch.'}
  $routingState=[string]$routingStatus.status
  $catalogState=[string]$routingStatus.catalog.status
  $unavailable=@($routingStatus.unavailable_tiers)
  if($routingState -eq 'ready'){
    if($catalogState -ne 'verified' -or $unavailable.Count -ne 0){throw 'Ready status has inconsistent catalog evidence.'}
  }elseif($routingState -eq 'degraded_sol_only'){
    if($catalogState -ne 'verified' -or -not [bool]$routingStatus.catalog.routing_models.strategic -or 'strategic' -in $unavailable -or $unavailable.Count -eq 0){throw 'Invalid Sol-only degraded status.'}
    Write-Warning "Routing degraded to Sol-only; unavailable tiers: $($unavailable -join ',')"
  }else{throw "Routing preflight is not ready: status=$routingState catalog=$catalogState"}

  return [string]$path
}
function Assert-NoPendingProjectState {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectDirectory
  )

  $fullProjectDirectory = [System.IO.Path]::GetFullPath($ProjectDirectory)
  $pendingPath = Join-Path -Path $fullProjectDirectory -ChildPath 'PROJECT_STATE.pending.md'
  if (Test-Path -LiteralPath $pendingPath -PathType Leaf) {
    Write-Host ''
    Write-Host 'PROJECT_STATE_PENDING_DETECTED' -ForegroundColor Yellow
    Write-Host '检测到尚未恢复的项目状态文件：' -ForegroundColor Yellow
    Write-Host $pendingPath -ForegroundColor Yellow
    Write-Host ''
    Write-Host '请先将 pending 文件内容恢复或合并到 PROJECT_STATE.md，然后删除 pending 文件。' -ForegroundColor Yellow
    Write-Host '当前启动已停止，不得进入下一工作包。' -ForegroundColor Yellow
    exit 21
  }
}

function Open-ProjectInteractive {
  param($Settings)
  $path=Select-Folder '请选择科研项目根目录' $Settings.RecentProjectPath
  if(-not $path){return $null}
  try{return (Confirm-ProjectReady $path)}catch{Show-Message $_.Exception.Message '打开项目失败' -Error;return $null}
}

function Get-NewPrompt {
  param([string]$Task)
  if([string]::IsNullOrWhiteSpace($Task)){$Task='（未填写；进入 Codex Desktop 后再输入。）'}
  $template=@'
调用 $research-project-orchestrator。

请先读取：

1. AGENTS.md
2. PROJECT_STATE.md
3. PROJECT_OVERRIDES.md
4. RESEARCH_PROJECT_START_PROMPT.md
5. 当前项目目录中的已有资料

本次任务：

【用户输入的任务】

请先检查已有信息和项目状态。

可以通过文件或互联网查明的信息优先自行查明；
只有用户能够决定的高影响问题才向用户提问。

不要立即完成整个大型任务。
运行一条统一科研流程；不要要求用户选择模型、Agent 或工作模式。
Sol 负责需求、规划、拆解、方法、证据综合和关键科研判断。
需要检索、网页查证、文件扫描、提取或证据表且路由状态为 ready 时，必须创建专用 Worker：优先 spawn_agent(agent_type=research_support, fork_turns=none)；若工具不支持 agent_type，则使用 spawn_agent(task_name=research_support, model=gpt-5.6-terra, reasoning_effort=medium, fork_turns=none)。
需要正式章节、多段成稿、表格、语言版本或格式化文本时，Sol 先锁定提纲、论点、证据编号和格式，再优先 spawn_agent(agent_type=research_output, fork_turns=none)；若工具不支持 agent_type，则使用 spawn_agent(task_name=research_output, model=gpt-5.6-luna, reasoning_effort=low, fork_turns=none)。
角色形态由 TOML 锁定模型；显式模型形态只能使用 canonical 值并在任务卡中重申只读、禁止递归委派和紧凑交接。若 spawn 无法锁定目标模型，则用官方一次性 codex --disable multi_agent exec --strict-config --ephemeral --ignore-user-config --json --color never --sandbox read-only，并用 -m 和 model_reasoning_effort 锁定 Terra/Luna；只传紧凑任务卡，完成即退出。真实子线程、成功 spawn，或退出码为 0 且返回合规交接包的一次性调用才算运行证据。
三种调用形态都不可用、模型不可用或一次合规调用失败时标记 degraded_sol_only，由 Sol 完成当前有界任务并透明说明；不得假称已经调用 Terra/Luna。
只有真实依赖才创建阶段；Worker 不互相转交，不接收完整历史、全部日志或整篇原文。
投稿、关键参数、核心方法和最终科学结论由 Sol 做一次紧凑语义验收，不重新写全文。
'@
  return $template.Replace('【用户输入的任务】',$Task)
}

function Get-ExistingPrompt {
  param([string]$Task)
  if([string]::IsNullOrWhiteSpace($Task)){$Task='（未填写；进入 Codex Desktop 后再输入。）'}
  $template=@'
调用 $research-project-orchestrator。

请读取：

1. AGENTS.md
2. PROJECT_STATE.md
3. PROJECT_OVERRIDES.md
4. 当前项目目录中的新增资料

本次任务：

【用户输入的任务】

请从PROJECT_STATE.md恢复项目，核对已完成阶段、未决问题和下一工作包。

不要重复询问已经确认的信息。
不要重复执行已经完成的工作。
可自行检索的信息优先检索。
完成当前工作包后执行最低充分质量门；低风险且可逆时连续推进，到高影响决策、证据不足或不可逆操作前再等待用户确认。
'@
  return $template.Replace('【用户输入的任务】',$Task)
}

function Get-CodexDesktopAppId {
  try {
    $apps = @(Get-StartApps -ErrorAction Stop | Where-Object { [string]$_.AppID -match '^OpenAI\.Codex_.*!App$' })
    if($apps.Count -gt 0){return [string]$apps[0].AppID}
  } catch {}
  return $null
}

function Get-DesktopLaunchPrompt {
  param([string]$Project,[AllowEmptyString()][string]$Prompt)
  return ('当前科研项目根目录（请在 Codex Desktop 中打开此文件夹作为工作区）：'+[Environment]::NewLine+$Project+[Environment]::NewLine+[Environment]::NewLine+'请粘贴并执行以下科研启动 Prompt：'+[Environment]::NewLine+[Environment]::NewLine+$Prompt)
}

function Copy-TextToClipboard {
  param([AllowEmptyString()][string]$Text)
  try {
    if(-not ('Windows.Forms.Clipboard' -as [type])){Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop}
    [Windows.Forms.Clipboard]::SetText($Text)
    return $true
  } catch {
    try {Set-Clipboard -Value $Text -ErrorAction Stop;return $true} catch {return $false}
  }
}

function Start-CodexDesktop {
  param([string]$Project,[AllowEmptyString()][string]$Prompt)
  $appId=Get-CodexDesktopAppId
  if([string]::IsNullOrWhiteSpace($appId)){
    Show-Message ('未找到 Codex Desktop 图形应用。请确认已安装并可从开始菜单打开 Codex，然后再运行本启动器。'+[Environment]::NewLine+[Environment]::NewLine+'启动器不会自行安装软件。') 'Codex Desktop 未找到' -Error
    return $false
  }
  $desktopPrompt=Get-DesktopLaunchPrompt $Project $Prompt
  $copied=Copy-TextToClipboard $desktopPrompt
  try {Start-Process -FilePath ('shell:AppsFolder\'+$appId) -ErrorAction Stop}
  catch {Show-Message ('无法打开 Codex Desktop：'+$_.Exception.Message) 'Codex Desktop 启动失败' -Error;return $false}
  if($copied){
    Show-Message ('已打开 Codex Desktop。科研启动 Prompt 已复制到剪贴板。'+[Environment]::NewLine+[Environment]::NewLine+'请在 Desktop 中打开此项目目录作为工作区：'+[Environment]::NewLine+$Project+[Environment]::NewLine+[Environment]::NewLine+'然后新建任务并按 Ctrl+V 粘贴。') 'Codex Desktop 已打开'
  } else {
    Show-Message ('已打开 Codex Desktop，但无法自动复制启动 Prompt。'+[Environment]::NewLine+[Environment]::NewLine+'请在 Desktop 中打开项目目录后，手动输入本次任务。') 'Codex Desktop 已打开' -Error
  }
  return $true
}

function Invoke-SkillCheck {
  $scriptPath=Join-Path $script:ScriptsRoot 'Test-ResearchSkills.ps1'
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath
  if($LASTEXITCODE -eq 0){Write-Host 'Skills 检查结果：PASS。'}else{Write-Host "Skills 检查结果：FAIL（退出代码：$LASTEXITCODE）。如仅做离线静态检查，请显式运行 Test-ResearchSkills.ps1 -AllowUnverifiedModelCatalog。" -ForegroundColor Red}
  Read-Host '按 Enter 返回启动器'
}

function Assert-Test {
  param([bool]$Condition,[string]$Message)
  if(-not $Condition){throw "自检失败：$Message"}
  Write-Host "PASS $Message"
}

function Invoke-SelfTest {
  Write-Host '开始科研 Agent 启动器自检（测试数据使用受控临时目录）...'
  foreach($file in @('Initialize-ResearchProjectRouting.ps1','New-ResearchProject.ps1','Test-ManagedProjectRouting.ps1','Test-ResearchSkills.ps1','Start-ResearchAgent.ps1')){
    Assert-Test (Test-Path -LiteralPath (Join-Path $script:ScriptsRoot $file) -PathType Leaf) "脚本存在：$file"
  }
  foreach($file in $script:RequiredFiles){Assert-Test (Test-Path -LiteralPath (Join-Path $script:TemplateRoot $file) -PathType Leaf) "模板存在：$file"}
  $cmd=Join-Path $script:RepositoryRoot '启动科研Agent.cmd'
  $bytes=[IO.File]::ReadAllBytes($cmd);$text=[Text.Encoding]::UTF8.GetString($bytes)
  $bom=$bytes.Length -ge 3 -and $bytes[0]-eq 239 -and $bytes[1]-eq 187 -and $bytes[2]-eq 191
  Assert-Test (-not $bom) 'CMD 为 UTF-8 无 BOM'
  Assert-Test ([regex]::Matches($text,'(?<!\r)\n').Count -eq 0) 'CMD 全部使用 CRLF'
  $new=Get-NewPrompt '自检任务 $ 中文';$old=Get-ExistingPrompt '自检任务 $ 中文'
  Assert-Test ($new.Contains('$research-project-orchestrator') -and $old.Contains('$research-project-orchestrator')) 'Prompt 保留 Skill 原文'
  Assert-Test (-not $new.Contains('【用户输入的任务】')) 'Prompt 占位符已替换'
  $sampleProject=Join-Path ([IO.Path]::GetTempPath()) 'sample project'
  $desktopPrompt=Get-DesktopLaunchPrompt $sampleProject $new
  Assert-Test ($desktopPrompt.Contains($sampleProject) -and $desktopPrompt.Contains('$research-project-orchestrator')) '图形界面启动 Prompt 正确'

  $parent=Join-Path $script:ScriptsRoot '.launcher-self-tests'
  $root=Join-Path $parent ([Guid]::NewGuid().ToString('N'))
  $oldSettings=$script:SettingsPath
  New-Item -ItemType Directory -Path $root -Force|Out-Null
  try{
    $script:SettingsPath=Join-Path $root 'settings.json'
    $settings=Get-Settings
    Assert-Test (Test-Path -LiteralPath $script:SettingsPath -PathType Leaf) '首次运行配置创建成功'
    $partial=Join-Path $root '已有项目 中文 空格';New-Item -ItemType Directory -Path $partial|Out-Null
    [IO.File]::WriteAllText((Join-Path $partial 'AGENTS.md'),'KEEP',[Text.UTF8Encoding]::new($true))
    Assert-Test (Initialize-MissingFiles $partial -AssumeYes) '已有项目安全补齐成功'
    Assert-Test ((Get-Content -LiteralPath (Join-Path $partial 'AGENTS.md') -Encoding UTF8 -Raw)-eq 'KEEP') '已有文件未被覆盖'
    $dest=Join-Path $root '新建项目 目录';New-Item -ItemType Directory -Path $dest|Out-Null
    $result=@(Invoke-NewProject '验证项目' $dest -Quiet)
    Assert-Test ($result.Count -eq 1 -and $result[0] -is [string]) '新建流程只返回一个项目路径'
    $project=$result[0]
    Assert-Test (@(Get-MissingFiles $project).Count -eq 0) '新项目五个文件齐全'
    $rejected=$false;try{$null=Invoke-NewProject '验证项目' $dest -Quiet}catch{$rejected=$true}
    Assert-Test $rejected '同名项目拒绝'
    $settings.RecentProjectPath=Join-Path $root '失效项目';$settings.RecentProjects=@($settings.RecentProjectPath,$project);Save-Settings $settings
    $clean=Get-Settings;Assert-Test ($clean.RecentProjectPath -eq $project) '失效最近项目自动清理'
    $report=Join-Path $root 'skills.md'
    $null=& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $script:ScriptsRoot 'Test-ResearchSkills.ps1') -ReportPath $report
    Assert-Test ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $report)) '科研 Skills 检查通过'
    $pendingProject=Join-Path $root 'pending-project';New-Item -ItemType Directory -Path $pendingProject -Force|Out-Null
    [IO.File]::WriteAllText((Join-Path $pendingProject 'PROJECT_STATE.pending.md'),'test: permanent_lock_pending_fallback',[Text.UTF8Encoding]::new($false))
    $pendingOut=Join-Path $root 'pending-check.stdout.txt';$pendingErr=Join-Path $root 'pending-check.stderr.txt'
    $pendingArgs='-NoProfile -ExecutionPolicy Bypass -File "'+$PSCommandPath+'" -RepositoryRoot "'+$script:RepositoryRoot+'" -NoGui -PendingCheckOnly -PendingProjectDirectory "'+$pendingProject+'"'
    $pendingProc=Start-Process -FilePath 'powershell.exe' -ArgumentList $pendingArgs -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput $pendingOut -RedirectStandardError $pendingErr
    $pendingText='';if(Test-Path -LiteralPath $pendingOut){$pendingText=Get-Content -LiteralPath $pendingOut -Raw -Encoding UTF8}
    Assert-Test ($pendingProc.ExitCode -eq 21) 'pending 文件阻止启动并返回退出码21'
    Assert-Test ($pendingText.Contains('PROJECT_STATE_PENDING_DETECTED')) 'pending 检测输出正确'
    Assert-Test ($pendingText.Contains('PROJECT_STATE.pending.md')) 'pending 路径已输出'
    Assert-Test (-not $pendingText.Contains('Codex Desktop')) 'pending 检测未启动 Codex'
    Remove-Item -LiteralPath (Join-Path $pendingProject 'PROJECT_STATE.pending.md') -Force
    $clearProc=Start-Process -FilePath 'powershell.exe' -ArgumentList $pendingArgs -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput (Join-Path $root 'pending-clear.stdout.txt') -RedirectStandardError (Join-Path $root 'pending-clear.stderr.txt')
    Assert-Test ($clearProc.ExitCode -eq 0) '删除 pending 后启动器正常继续'
  }finally{
    $script:SettingsPath=$oldSettings
    $full=[IO.Path]::GetFullPath($root);$base=[IO.Path]::GetFullPath($parent);$scripts=[IO.Path]::GetFullPath($script:ScriptsRoot)
    if(-not $full.StartsWith($base.TrimEnd('\')+'\',[StringComparison]::OrdinalIgnoreCase) -or -not $base.StartsWith($scripts.TrimEnd('\')+'\',[StringComparison]::OrdinalIgnoreCase)){throw "拒绝清理不安全的测试路径：$full"}
    if(Test-Path -LiteralPath $full){Remove-Item -LiteralPath $full -Recurse -Force}
    if((Test-Path -LiteralPath $base) -and @(Get-ChildItem -LiteralPath $base -Force).Count -eq 0){Remove-Item -LiteralPath $base -Force}
  }
  $desktop=Get-CodexDesktopAppId
  if([string]::IsNullOrWhiteSpace($desktop)){Write-Warning 'Codex Desktop 当前不可发现。'}else{Write-Host "PASS Codex Desktop 启动入口可用：$desktop"}
  Write-Host 'LAUNCHER_SELF_TEST_PASS'
}

function Invoke-Launcher {
  foreach($path in @($script:RepositoryRoot,$script:ScriptsRoot,$script:TemplateRoot)){if(-not(Test-Path -LiteralPath $path -PathType Container)){throw "启动器所需目录不存在：$path"}}
  if($RoutingPreflightOnly){
    if([string]::IsNullOrWhiteSpace($RoutingProjectDirectory)){throw 'RoutingPreflightOnly 必须提供 RoutingProjectDirectory。'}
    $ready=Confirm-ProjectReady $RoutingProjectDirectory -AssumeYes
    if(-not $ready){throw '科研项目路由预检未完成。'}
    Write-Output "ROUTING_PROJECT_READY $ready"
    return
  }

  if($PendingCheckOnly){if([string]::IsNullOrWhiteSpace($PendingProjectDirectory)){throw 'PendingCheckOnly 必须提供 PendingProjectDirectory。'};Assert-NoPendingProjectState -ProjectDirectory $PendingProjectDirectory;return}
  if($ValidateOnly){Invoke-SelfTest;return}
  Initialize-Ui
  $settings=Get-Settings
  while($true){
    switch(Show-Menu){
      '1' {$project=New-ProjectInteractive $settings;if($project){Assert-NoPendingProjectState -ProjectDirectory $project;$task=Read-Text '请输入本次要完成的科研任务。可留空，进入 Codex Desktop 后再输入。' '本次科研任务';Update-Recent $project $settings;if(Start-CodexDesktop $project (Get-NewPrompt $task)){return}}}
      '2' {$project=Open-ProjectInteractive $settings;if($project){Assert-NoPendingProjectState -ProjectDirectory $project;$task=Read-Text '请输入本次要完成的科研任务。可留空，进入 Codex Desktop 后再输入。' '本次科研任务';Update-Recent $project $settings;if(Start-CodexDesktop $project (Get-ExistingPrompt $task)){return}}}
      '3' {$settings=Get-Settings;if(-not $settings.RecentProjectPath){Show-Message '没有可用的最近项目。' -Error;continue};$project=Confirm-ProjectReady $settings.RecentProjectPath;if($project){Assert-NoPendingProjectState -ProjectDirectory $project;$task=Read-Text '请输入本次要完成的科研任务。可留空，进入 Codex Desktop 后再输入。' '本次科研任务';Update-Recent $project $settings;if(Start-CodexDesktop $project (Get-ExistingPrompt $task)){return}}}
      '4' {Invoke-SkillCheck}
      '5' {return}
      default {Show-Message '请输入 1 至 5。' -Error}
    }
  }
}

try{Invoke-Launcher;exit 0}catch{Write-Host "科研 Agent 启动器发生错误：$($_.Exception.Message)" -ForegroundColor Red;exit 1}
