# Keep the launcher definitions together so uninstall can check ownership.
function Get-BackupPhoneStubs {
    param([string]$RepoDir)

    $scriptPath = Join-Path $RepoDir "backup-phone.ps1"
    # CMD expands percent signs even in quoted paths. Double them in the stub.
    $scriptPath = $scriptPath.Replace('%', '%%')
    $batContent = @"
@echo off
setlocal DisableDelayedExpansion
powershell -NoProfile -ExecutionPolicy Bypass -File "$scriptPath" %*
"@
    $bashContent = @'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/backup-phone.bat" "$@"
'@
    return [ordered]@{
        "backup-phone.bat" = $batContent
        "backup-phone" = $bashContent
    }
}
