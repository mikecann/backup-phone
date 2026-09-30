# deps.ps1
# Installs Python packages needed for HEIC -> WebP conversion.
# Idempotent: checks each package before installing.

$ErrorActionPreference = "Stop"
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    throw "Python is missing. Install Python 3.10 or newer with pip and add python to PATH."
}

Write-Host "  [backup-phone] Checking dependencies..." -ForegroundColor Cyan

$packages = @(
    @{ Import = "PIL";          Pip = "Pillow"       },
    @{ Import = "pillow_heif";  Pip = "pillow-heif"  }
)

foreach ($pkg in $packages) {
    # A missing import is an expected probe result. Avoid writing a traceback to
    # stderr, which Windows PowerShell can turn into a terminating native error.
    $importCheck = @"
try:
    import $($pkg.Import)
except ImportError:
    raise SystemExit(1)
print('ok')
"@
    $ok = & python -c $importCheck 2>$null
    if ($LASTEXITCODE -eq 0 -and $ok -eq "ok") {
        Write-Host "    OK  $($pkg.Pip) is already installed" -ForegroundColor Green
    } else {
        Write-Host "    Installing $($pkg.Pip) via pip..." -ForegroundColor Yellow
        & python -m pip install $pkg.Pip
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to install $($pkg.Pip). Make sure python -m pip works for your Python installation."
        } else {
            Write-Host "    OK  $($pkg.Pip) installed" -ForegroundColor Green
        }
    }
}
