<#
  oops — fix your last shell command with AI (PowerShell edition).
  Dot-source this from your $PROFILE:  . "$env:LOCALAPPDATA\oops\oops.ps1"
  https://github.com/TheSolyboy/oops
#>
param(
  [switch]$Fix,
  [string]$Command,
  [string]$ErrorPath
)

$script:OopsVersion   = '0.1.0'
$script:OopsConfigDir = Join-Path $env:APPDATA 'oops'
$script:OopsConfigFile = Join-Path $script:OopsConfigDir 'config.json'

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

function Get-OopsConfig {
  $cfg = [pscustomobject]@{ Provider=''; Model=''; ApiKey=''; BaseUrl='' }
  if (Test-Path $script:OopsConfigFile) {
    try {
      $j = Get-Content $script:OopsConfigFile -Raw | ConvertFrom-Json
      foreach ($k in 'Provider','Model','ApiKey','BaseUrl') {
        if ($null -ne $j.$k) { $cfg.$k = [string]$j.$k }
      }
    } catch { }
  }
  return $cfg
}

function Save-OopsConfig {
  param([pscustomobject]$Config)
  if (-not (Test-Path $script:OopsConfigDir)) {
    New-Item -ItemType Directory -Path $script:OopsConfigDir -Force | Out-Null
  }
  $Config | ConvertTo-Json | Set-Content -Path $script:OopsConfigFile -Encoding utf8
}

function Read-OopsValue {
  param([string]$Prompt, [string]$Default)
  $suffix = if ($Default) { " [$Default]" } else { '' }
  $ans = Read-Host ($Prompt + $suffix)
  if ([string]::IsNullOrEmpty($ans)) { return $Default }
  return $ans
}

function Read-OopsSecret {
  param([string]$Prompt)
  $sec = Read-Host $Prompt -AsSecureString
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
  try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

function Invoke-OopsSetup {
  $cfg = Get-OopsConfig
  Write-Host ''
  Write-Host '  oops setup'
  Write-Host '  ----------'
  Write-Host ''
  Write-Host 'Select an AI provider:'
  Write-Host '  1) Anthropic (Claude)'
  Write-Host '  2) OpenRouter'
  Write-Host '  3) Ollama (local)'
  Write-Host '  4) OpenCode (Go / Zen cloud)'
  $choice = Read-OopsValue 'Provider [1-4]' '1'
  switch ($choice) {
    { $_ -in '1','anthropic'  } { $cfg.Provider = 'anthropic' }
    { $_ -in '2','openrouter' } { $cfg.Provider = 'openrouter' }
    { $_ -in '3','ollama'     } { $cfg.Provider = 'ollama' }
    { $_ -in '4','opencode'   } { $cfg.Provider = 'opencode' }
    default                     { $cfg.Provider = 'anthropic' }
  }

  switch ($cfg.Provider) {
    'anthropic' {
      $cfg.BaseUrl = ''
      $cfg.ApiKey  = Read-OopsSecret 'Anthropic API key'
      $def = if ($cfg.Model) { $cfg.Model } else { 'claude-haiku-4-5-20251001' }
      $cfg.Model   = Read-OopsValue 'Model' $def
    }
    'openrouter' {
      $cfg.BaseUrl = ''
      $cfg.ApiKey  = Read-OopsSecret 'OpenRouter API key'
      $def = if ($cfg.Model) { $cfg.Model } else { 'anthropic/claude-3.5-haiku' }
      $cfg.Model   = Read-OopsValue 'Model' $def
    }
    'ollama' {
      $cfg.ApiKey  = ''
      $bdef = if ($cfg.BaseUrl) { $cfg.BaseUrl } else { 'http://localhost:11434' }
      $cfg.BaseUrl = Read-OopsValue 'Ollama base URL' $bdef
      $def = if ($cfg.Model) { $cfg.Model } else { 'llama3.2' }
      $cfg.Model   = Read-OopsValue 'Model' $def
    }
    'opencode' {
      Write-Host 'opencode Go/Zen is a cloud, OpenAI-compatible API.'
      Write-Host 'Get an API key from https://opencode.ai/auth'
      $bdef = if ($cfg.BaseUrl) { $cfg.BaseUrl } else { 'https://opencode.ai/zen/go/v1' }
      $cfg.BaseUrl = Read-OopsValue 'Base URL' $bdef
      $cfg.ApiKey  = Read-OopsSecret 'opencode API key'
      $def = if ($cfg.Model) { $cfg.Model } else { 'glm-5.1' }
      $cfg.Model   = Read-OopsValue 'Model' $def
    }
  }

  Save-OopsConfig $cfg
  Write-Host ''
  Write-Host "Saved configuration to $script:OopsConfigFile"
}

# ---------------------------------------------------------------------------
# Talking to the AI provider
# ---------------------------------------------------------------------------

function Invoke-OopsRequest {
  param([pscustomobject]$Config, [string]$Command, [string]$ErrorText)

  $sys = 'You are oops, a command-line assistant. The user just ran a shell command that failed. Given the failed command and its error output, reply with ONLY the corrected shell command to run instead. Output a single line: no explanation, no markdown, no code fences, no backticks, no surrounding quotes. If no fix is possible, output the original command unchanged.'
  $user = "Failed command:`n$Command`n`nError output:`n$ErrorText"

  $url = $null; $headers = @{ 'content-type' = 'application/json' }; $payload = $null; $pick = $null

  switch ($Config.Provider) {
    'anthropic' {
      $url = 'https://api.anthropic.com/v1/messages'
      $headers['x-api-key'] = $Config.ApiKey
      $headers['anthropic-version'] = '2023-06-01'
      $payload = @{ model = $Config.Model; max_tokens = 256; system = $sys;
                    messages = @(@{ role = 'user'; content = $user }) }
      $pick = { param($r) $r.content[0].text }
    }
    'openrouter' {
      $url = 'https://openrouter.ai/api/v1/chat/completions'
      $headers['Authorization'] = "Bearer $($Config.ApiKey)"
      $payload = @{ model = $Config.Model;
                    messages = @(@{ role='system'; content=$sys }, @{ role='user'; content=$user }) }
      $pick = { param($r) $r.choices[0].message.content }
    }
    'ollama' {
      $base = if ($Config.BaseUrl) { $Config.BaseUrl } else { 'http://localhost:11434' }
      $url = "$base/api/chat"
      $payload = @{ model = $Config.Model; stream = $false;
                    messages = @(@{ role='system'; content=$sys }, @{ role='user'; content=$user }) }
      $pick = { param($r) $r.message.content }
    }
    'opencode' {
      $base = if ($Config.BaseUrl) { $Config.BaseUrl } else { 'https://opencode.ai/zen/go/v1' }
      $url = "$base/chat/completions"
      if ($Config.ApiKey) { $headers['Authorization'] = "Bearer $($Config.ApiKey)" }
      $payload = @{ model = $Config.Model;
                    messages = @(@{ role='system'; content=$sys }, @{ role='user'; content=$user }) }
      $pick = { param($r) $r.choices[0].message.content }
    }
    default {
      throw "unknown provider '$($Config.Provider)'. Run: oops config"
    }
  }

  $json  = $payload | ConvertTo-Json -Depth 8 -Compress
  $bytes = [Text.Encoding]::UTF8.GetBytes($json)
  $resp  = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $bytes -ContentType 'application/json' -TimeoutSec 30
  return (& $pick $resp)
}

# ---------------------------------------------------------------------------
# Output handling
# ---------------------------------------------------------------------------

function Format-OopsCommand {
  param([string]$Text)
  if ([string]::IsNullOrEmpty($Text)) { return '' }
  $line = ($Text -replace "`r", '') -split "`n" |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -ne '' -and $_ -notmatch '^```' } |
            Select-Object -First 1
  if ($null -eq $line) { return '' }
  $line = ($line -replace '^```[a-zA-Z]*', '' -replace '```$', '').Trim()
  if ($line.Length -ge 2 -and $line.StartsWith('`') -and $line.EndsWith('`')) {
    $line = $line.Trim('`')
  }
  return $line.Trim()
}

# ---------------------------------------------------------------------------
# Finding the last command
# ---------------------------------------------------------------------------

function Get-OopsLastCommand {
  $h = Get-History -ErrorAction SilentlyContinue |
         Where-Object { $_.CommandLine -notmatch '^\s*oops(\s|$)' } |
         Select-Object -Last 1
  if ($h) { return $h.CommandLine }
  return ''
}

# ---------------------------------------------------------------------------
# Main run
# ---------------------------------------------------------------------------

function Invoke-OopsRun {
  $cfg = Get-OopsConfig
  if (-not $cfg.Provider) {
    Write-Error 'oops: not configured yet. Run: oops config'; return
  }
  $cmd = Get-OopsLastCommand
  if (-not $cmd) {
    Write-Error 'oops: could not find a previous command in history.'; return
  }

  Write-Host "oops: re-running `"$cmd`" to capture the error..." -ForegroundColor DarkGray
  $err = ''
  try { $err = (Invoke-Expression $cmd 2>&1 | Out-String) } catch { $err = $_ | Out-String }
  if ($err.Length -gt 4000) { $err = $err.Substring($err.Length - 4000) }

  Write-Host "oops: asking $($cfg.Provider) ($($cfg.Model))..." -ForegroundColor DarkGray
  $fix = $null
  try { $fix = Invoke-OopsRequest -Config $cfg -Command $cmd -ErrorText $err }
  catch { Write-Error "oops: $($_.Exception.Message)"; return }

  $fix = Format-OopsCommand $fix
  if (-not $fix) { Write-Error 'oops: no suggestion returned.'; return }

  Write-Host "oops: $fix" -ForegroundColor Yellow
  $ans = Read-Host 'Run it? [Y/n]'
  if ($ans -eq '' -or $ans -match '^(y|yes)$') {
    Invoke-Expression $fix
  } else {
    Write-Host 'oops: cancelled.'
  }
}

function Show-OopsHelp {
  @'
oops - fix your last shell command with AI

usage:
  oops                  fix the last command that failed
  oops config           re-run the interactive setup
  oops model <name>     switch the model
  oops provider <name>  switch provider (anthropic|openrouter|ollama|opencode)
  oops help             show this help
  oops version          show the version
'@ | Write-Host
}

function Set-OopsField {
  param([string]$Field, [string]$Value)
  if ([string]::IsNullOrEmpty($Value)) {
    Write-Error "usage: oops $Field <value>"; return
  }
  $cfg = Get-OopsConfig
  switch ($Field) {
    'model' { $cfg.Model = $Value }
    'provider' {
      if ($Value -notin 'anthropic','openrouter','ollama','opencode') {
        Write-Error "oops: unknown provider '$Value' (anthropic|openrouter|ollama|opencode)"; return
      }
      $cfg.Provider = $Value
    }
  }
  Save-OopsConfig $cfg
  Write-Host "oops: $Field set to $Value"
}

function oops {
  $sub = if ($args.Count -gt 0) { [string]$args[0] } else { '' }
  switch ($sub) {
    'config'   { Invoke-OopsSetup }
    'model'    { Set-OopsField 'model' ([string]$args[1]) }
    'provider' { Set-OopsField 'provider' ([string]$args[1]) }
    { $_ -in '-h','--help','help' }       { Show-OopsHelp }
    { $_ -in '-v','--version','version' } { Write-Host "oops $script:OopsVersion" }
    default    { Invoke-OopsRun }
  }
}

# ---------------------------------------------------------------------------
# -Fix mode: used by oops.cmd so CMD users reuse this network/JSON logic.
# Prints only the corrected command to stdout.
# ---------------------------------------------------------------------------
if ($Fix) {
  $cfg = Get-OopsConfig
  $err = ''
  if ($ErrorPath -and (Test-Path $ErrorPath)) { $err = Get-Content $ErrorPath -Raw }
  try {
    $out = Format-OopsCommand (Invoke-OopsRequest -Config $cfg -Command $Command -ErrorText $err)
  } catch {
    [Console]::Error.WriteLine("oops: $($_.Exception.Message)")
    exit 1
  }
  if ($out) { Write-Output $out; exit 0 } else { exit 1 }
}
