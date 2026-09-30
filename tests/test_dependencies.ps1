# Mock Python so dependency failure checks never download packages.
$ErrorActionPreference = "Stop"
$deps = Join-Path (Split-Path -Parent $PSScriptRoot) "deps.ps1"
$global:BackupPhoneDependencyTest = @{
    InstallCalls = @()
    ImportsAvailable = $true
    InstallExitCode = 0
}

function python {
    if ($args[0] -eq "-c") {
        if ($global:BackupPhoneDependencyTest.ImportsAvailable) {
            $global:LASTEXITCODE = 0
            "ok"
        } else {
            $global:LASTEXITCODE = 1
        }
    } else {
        $global:BackupPhoneDependencyTest.InstallCalls += ,@($args)
        $global:LASTEXITCODE = $global:BackupPhoneDependencyTest.InstallExitCode
    }
}

& $deps
if ($global:BackupPhoneDependencyTest.InstallCalls.Count -ne 0) { throw "Installed packages that were already available" }
$global:BackupPhoneDependencyTest.ImportsAvailable = $false
& $deps
if ($global:BackupPhoneDependencyTest.InstallCalls.Count -ne 2) { throw "Did not install both missing packages" }
foreach ($call in $global:BackupPhoneDependencyTest.InstallCalls) {
    if (($call[0..2] -join " ") -ne "-m pip install") {
        throw "Dependencies must use python -m pip"
    }
}
$global:BackupPhoneDependencyTest.InstallExitCode = 1
$failed = $false
try { & $deps } catch { $failed = $true }
if (-not $failed) { throw "Dependency installation failure must stop setup" }
Write-Host "Dependency checks passed." -ForegroundColor Green
# GitHub Actions propagates LASTEXITCODE even when the expected failure was caught.
$global:LASTEXITCODE = 0
