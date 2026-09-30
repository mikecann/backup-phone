# Agent guidance for backup-phone

This is a Windows command-line iPhone backup tool. PowerShell uses the Windows
Shell COM MTP interface to copy media over USB. Python handles photo metadata,
HEIC conversion, and organizing existing backups. There is no macOS phone
backup launcher.

## Working on this repo

- Keep source files in this clone. `C:\dev\tools` only holds generated launchers
  and any separately managed binaries, never source files.
- Never commit large `.exe` or `.dll` binaries.
- Use test-first development for non-trivial changes. If there's no clean test
  seam, extract one before adding the test.
- When behavior or tested expectations change, update and rerun the relevant
  tests after implementing the change.
- Test before committing. Run the automated checks, then run the affected script
  directly with PowerShell on Windows and check its exit code. Phone backup
  smoke tests need a connected, unlocked, trusted iPhone.
- Write `.bat` files and generated stubs with ASCII encoding. Keep installer
  paths quoted so a clone can live in a directory containing spaces.
- This is a console CLI. Keep its prompts and progress output visible.
- `install.ps1` points launchers at `$PSScriptRoot`. Editing source doesn't need
  a reinstall, moving the clone or changing launcher setup does.
- The launcher directory is shared. Installation and removal must only affect
  backup-phone's own launchers, never other tools or shared registry menus.

## Dependencies

- `deps.ps1` must work directly from any current directory, be self-contained,
  and check before installing packages so rerunning it is safe.
- Use clear `Write-Host` output to show what happened.
- Check Python with `Get-Command`; install missing packages with `python -m pip`
  so dependencies go into the same interpreter used by the tool.
- Runtime packages are listed in `requirements.txt`. No API keys are required.
- `install.ps1 -SkipDeps` skips dependency setup. `-ToolsDir` chooses the launcher
  directory and `-SkipPathUpdate` avoids changing the user's PATH.

## Files and behavior

- `backup-phone.ps1` is the backup logic; `backup-phone.bat` runs it directly.
- `get_media_ym.py` reads EXIF dates. Keep its image extensions and month names
  in sync with `backup-phone.ps1`.
- `organize-existing-backup.ps1` runs `organize_flat_to_ym.py`. Preserve its
  `-WhatIf` preview and collision handling when changing it.
- Backups use `YYYY/mmm` subfolders and source-folder-prefixed filenames.
- Existing files are checked recursively. Preserve rerun and conversion fallback
  behavior; do not delete backups or original phone media.
- Staging files use fixed names in `%TEMP%`, so don't run concurrent phone backups.

## Verification

```powershell
python -m pip install -r requirements.txt
python -m unittest discover -s tests -v
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test_installers.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test_dependencies.ps1
```

The installer test uses temporary folders and skips dependencies and PATH changes.
The workflow in `.github/workflows/ci.yml` also parses every `.ps1` script with
`[System.Management.Automation.Language.Parser]::ParseFile` and compiles Python.
PowerShell parsing and file-only installer checks can run with `pwsh` on macOS.
Actual CMD/Git Bash launching, user PATH setup, Shell COM, and USB/MTP copying
must be verified on Windows.
