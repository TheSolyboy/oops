<#
  oops installer for Windows (PowerShell + CMD).
  Run locally:  .\install.ps1
  Or remote:    irm https://raw.githubusercontent.com/TheSolyboy/oops/main/install.ps1 | iex
  https://github.com/TheSolyboy/oops
#>
$ErrorActionPreference = 'Stop'

$repo    = 'TheSolyboy/oops'
$branch  = 'main'
$rawBase = "https://raw.githubusercontent.com/$repo/$branch"
$dir     = Join-Path $env:LOCALAPPDATA 'oops'

Write-Host ''
Write-Host '  oops - fix your last shell command with AI'
Write-Host '  ------------------------------------------'
Write-Host ''

New-Item -ItemType Directory -Path $dir -Force | Out-Null

# 1. Install oops.ps1 + oops.cmd (copy from a local checkout if present, else download).
$srcRoot = $PSScriptRoot
foreach ($f in 'oops.ps1', 'oops.cmd') {
  $dest = Join-Path $dir $f
  $localSrc = if ($srcRoot) { Join-Path $srcRoot $f } else { '' }
  if ($localSrc -and (Test-Path $localSrc)) {
    Copy-Item $localSrc $dest -Force
    Write-Host "Installed $f from local checkout."
  } else {
    Write-Host "Downloading $f..."
    Invoke-WebRequest -Uri "$rawBase/$f" -OutFile $dest
  }
  # Clear the "downloaded from internet" mark so RemoteSigned will load it.
  Unblock-File $dest -ErrorAction SilentlyContinue
}
Write-Host "  -> $dir"

# 2. Dot-source oops.ps1 from the PowerShell profile (idempotent).
$ps1 = Join-Path $dir 'oops.ps1'
$profilePath = $PROFILE.CurrentUserAllHosts
if (-not (Test-Path $profilePath)) { New-Item -ItemType File -Path $profilePath -Force | Out-Null }
if (Select-String -Path $profilePath -SimpleMatch $ps1 -Quiet -ErrorAction SilentlyContinue) {
  Write-Host "Already sourced in $profilePath"
} else {
  Add-Content -Path $profilePath -Value "`n# oops shell assistant`n. `"$ps1`""
  Write-Host "Added source line to $profilePath"
}

# 3. Add the install dir to the user PATH so `oops` works in CMD too.
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (-not $userPath) { $userPath = '' }
if (($userPath -split ';') -notcontains $dir) {
  $newPath = if ($userPath) { "$userPath;$dir" } else { $dir }
  [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
  $env:Path = "$env:Path;$dir"
  Write-Host "Added $dir to your user PATH (for CMD)."
} else {
  Write-Host "$dir already on PATH."
}

# 4. Run the interactive setup (provider, key, model).
#    Dot-sourcing a .ps1 from disk obeys the execution policy, so bail out with
#    clear instructions if local scripts are blocked.
$policy = Get-ExecutionPolicy
if ($policy -eq 'Restricted' -or $policy -eq 'AllSigned') {
  Write-Host ''
  Write-Host "  Your PowerShell execution policy is '$policy', which blocks local scripts."
  Write-Host '  Allow them once (safe, user-scoped) and finish setup with:'
  Write-Host ''
  Write-Host '      Set-ExecutionPolicy -Scope CurrentUser RemoteSigned'
  Write-Host '      oops config'
  Write-Host ''
} else {
  . $ps1
  Invoke-OopsSetup

  Write-Host ''
  Write-Host '  Done!'
  Write-Host '   - PowerShell: open a new window (or run the dot-source line) and type: oops'
  Write-Host '   - CMD: open a new window so the PATH change takes effect, then type: oops'
  Write-Host ''
}
