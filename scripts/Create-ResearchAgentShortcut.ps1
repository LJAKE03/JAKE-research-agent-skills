<#
.SYNOPSIS
    Creates or updates the current user's Research Agent desktop shortcut.

.PARAMETER Force
    Updates an existing shortcut without asking.

.EXAMPLE
    .\Create-ResearchAgentShortcut.ps1
#>
[CmdletBinding()]
param([switch]$Force)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
    $repositoryRoot = (Resolve-Path -LiteralPath (Split-Path -Parent $PSScriptRoot)).ProviderPath
    $launcher = Join-Path $repositoryRoot '启动科研Agent.cmd'
    if (-not (Test-Path -LiteralPath $launcher -PathType Leaf)) { throw "未找到启动器：$launcher" }

    $desktop = [Environment]::GetFolderPath([Environment+SpecialFolder]::DesktopDirectory)
    if ([string]::IsNullOrWhiteSpace($desktop)) { throw '无法确定当前用户桌面目录。' }

    $shortcutPath = Join-Path $desktop '科研Agent.lnk'
    if ((Test-Path -LiteralPath $shortcutPath -PathType Leaf) -and -not $Force) {
        $answer = Read-Host ("快捷方式已存在：$shortcutPath" + [Environment]::NewLine + '是否更新？输入 Y 确认')
        if ($answer -notmatch '^[Yy]$') {
            Write-Host '已取消，未修改现有快捷方式。'
            exit 0
        }
    }

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $launcher
    $shortcut.Arguments = ''
    $shortcut.WorkingDirectory = $repositoryRoot
    $shortcut.Description = '科研 Agent Skills 协同系统启动器'
    $shortcut.Save()

    $verified = $shell.CreateShortcut($shortcutPath)
    $targetMatches = $verified.TargetPath.Equals($launcher, [StringComparison]::OrdinalIgnoreCase)
    $workingMatches = $verified.WorkingDirectory.Equals($repositoryRoot, [StringComparison]::OrdinalIgnoreCase)
    if (-not $targetMatches -or -not $workingMatches -or -not [string]::IsNullOrWhiteSpace($verified.Arguments)) {
        throw '快捷方式回读验证失败：目标、参数或工作目录不正确。'
    }
    Write-Host "桌面快捷方式已创建并验证：$shortcutPath"
}
catch {
    Write-Host "创建桌面快捷方式失败：$($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
