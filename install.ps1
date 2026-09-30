# Install just backup-phone from this clone. No API keys are needed.
param(
    [switch]$SkipDeps,
    [string]$ToolsDir = "C:\dev\tools",
    [switch]$SkipPathUpdate
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "install-lib.ps1")

if ($PSScriptRoot -match '[^\x00-\x7F]') {
    throw "Clone backup-phone into a path with only ASCII characters so the CMD launcher can reference it."
}
if (-not $SkipDeps) {
    & (Join-Path $PSScriptRoot "deps.ps1")
}

New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
$stubs = Get-BackupPhoneStubs -RepoDir $PSScriptRoot
foreach ($name in $stubs.Keys) {
    $destination = Join-Path $ToolsDir $name
    if ($name -eq "backup-phone") {
        # Git Bash reads the shebang literally, so CRLF would make it seek bash\r.
        $bashContent = $stubs[$name].Replace("`r`n", "`n") + "`n"
        [IO.File]::WriteAllText($destination, $bashContent, [Text.Encoding]::ASCII)
    } else {
        Set-Content -LiteralPath $destination -Value $stubs[$name] -Encoding ASCII
    }
    Write-Host "  [launcher] $destination" -ForegroundColor Green
}

# This directory is shared by other tools. Offer the same user PATH setup
# as the original installer, without changing machine-wide settings.
if (-not $SkipPathUpdate) {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $onPath = ($machinePath -split ";") + ($userPath -split ";") |
        Where-Object { $_.TrimEnd("\") -ieq $ToolsDir.TrimEnd("\") }
    if (-not $onPath) {
        $answer = Read-Host "Add '$ToolsDir' to your User PATH? [Y/n]"
        if ($answer -eq "" -or $answer -imatch "^y") {
            $newUserPath = (([string]$userPath).TrimEnd(";") + ";$ToolsDir").TrimStart(";")
            [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
            $env:PATH += ";$ToolsDir"
            Write-Host "Added '$ToolsDir' to User PATH. Open a new terminal." -ForegroundColor Green
        } else {
            Write-Host "Add '$ToolsDir' to PATH manually to use backup-phone by name." -ForegroundColor Yellow
        }
    }
}
Write-Host "Installed backup-phone. Keep this clone in place, the launchers point here." -ForegroundColor Cyan
