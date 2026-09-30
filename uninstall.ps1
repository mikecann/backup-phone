# Remove only backup-phone's launchers, leaving shared PATH and other tools alone.
param([string]$ToolsDir = "C:\dev\tools")

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "install-lib.ps1")
$stubs = Get-BackupPhoneStubs -RepoDir $PSScriptRoot
$batPath = Join-Path $ToolsDir "backup-phone.bat"
if (Test-Path -LiteralPath $batPath) {
    $currentBat = Get-Content -LiteralPath $batPath -Raw
    if ($currentBat.TrimEnd("`r", "`n") -cne $stubs["backup-phone.bat"].TrimEnd("`r", "`n")) {
        Write-Host "Keeping backup-phone launchers: the CMD launcher was changed or belongs to another clone." -ForegroundColor Yellow
        return
    }
}
foreach ($name in $stubs.Keys) {
    $destination = Join-Path $ToolsDir $name
    if (Test-Path -LiteralPath $destination) {
        $content = Get-Content -LiteralPath $destination -Raw
        $expected = $stubs[$name]
        if ($name -eq "backup-phone") { $expected = $expected.Replace("`r`n", "`n") }
        if ($content.TrimEnd("`r", "`n") -ceq $expected.TrimEnd("`r", "`n")) {
            Remove-Item -LiteralPath $destination
            Write-Host "Removed $destination" -ForegroundColor Green
        } else {
            Write-Host "Keeping modified launcher $destination" -ForegroundColor Yellow
        }
    }
}
