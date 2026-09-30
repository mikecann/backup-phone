# File-only installer checks. Use temporary folders and leave the user's PATH alone.
$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("backup-phone-tests-" + [guid]::NewGuid())

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

try {
    $clone = Join-Path $testRoot "clone with spaces"
    $tools = Join-Path $testRoot "shared tools"
    New-Item -ItemType Directory -Path $clone, $tools -Force | Out-Null
    foreach ($name in @("install.ps1", "uninstall.ps1", "install-lib.ps1", "backup-phone.ps1")) {
        Copy-Item -LiteralPath (Join-Path $repo $name) -Destination $clone
    }
    $otherTool = Join-Path $tools "another-tool.bat"
    Set-Content -LiteralPath $otherTool -Value "another tool" -Encoding ASCII
    $bat = Join-Path $tools "backup-phone.bat"
    $bash = Join-Path $tools "backup-phone"

    & (Join-Path $clone "install.ps1") -ToolsDir $tools -SkipDeps -SkipPathUpdate
    Assert-True (Test-Path -LiteralPath $bat) "Missing CMD launcher"
    Assert-True (Test-Path -LiteralPath $bash) "Missing Git Bash launcher"
    $firstBat = Get-Content -LiteralPath $bat -Raw
    $firstBash = Get-Content -LiteralPath $bash -Raw
    $target = Join-Path $clone "backup-phone.ps1"
    Assert-True ($firstBat.Contains('"' + $target + '" %*')) "Launcher must quote this clone's script and forward arguments"
    Assert-True ($firstBash.Contains('exec "$SCRIPT_DIR/backup-phone.bat" "$@"')) "Git Bash must preserve arguments"
    Assert-True (-not $firstBash.Contains("`r")) "Git Bash launcher needs LF line endings"
    Assert-True (@([IO.File]::ReadAllBytes($bat) | Where-Object { $_ -gt 127 }).Count -eq 0) "CMD launcher must be ASCII"

    & (Join-Path $clone "install.ps1") -ToolsDir $tools -SkipDeps -SkipPathUpdate
    Assert-True ((Get-Content -LiteralPath $bat -Raw) -eq $firstBat) "Reinstall changed CMD launcher"
    Assert-True ((Get-Content -LiteralPath $bash -Raw) -eq $firstBash) "Reinstall changed Git Bash launcher"

    # An old clone must not uninstall launchers now owned by a different clone.
    $secondClone = Join-Path $testRoot "second clone"
    Copy-Item -LiteralPath $clone -Destination $secondClone -Recurse
    & (Join-Path $secondClone "install.ps1") -ToolsDir $tools -SkipDeps -SkipPathUpdate
    $secondBat = Get-Content -LiteralPath $bat -Raw
    & (Join-Path $clone "uninstall.ps1") -ToolsDir $tools
    Assert-True ((Get-Content -LiteralPath $bat -Raw) -eq $secondBat) "Old clone deleted another clone's CMD launcher"
    Assert-True (Test-Path -LiteralPath $bash) "Old clone deleted another clone's Git Bash launcher"

    & (Join-Path $secondClone "uninstall.ps1") -ToolsDir $tools
    Assert-True (-not (Test-Path -LiteralPath $bat)) "Uninstall left CMD launcher"
    Assert-True (-not (Test-Path -LiteralPath $bash)) "Uninstall left Git Bash launcher"
    Assert-True ((Get-Content -LiteralPath $otherTool).Trim() -eq "another tool") "Uninstall changed an unrelated tool"
    & (Join-Path $secondClone "uninstall.ps1") -ToolsDir $tools
    Write-Host "Installer lifecycle checks passed." -ForegroundColor Green
} finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}
