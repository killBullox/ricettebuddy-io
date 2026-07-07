# Deploy del backend Beet-It sulla VPS (Windows), esposto su IP:porta.
# Da lanciare SULLA VPS (RDP o SSH), in PowerShell come amministratore.
#
# Sicurezza: tocca SOLO C:\BeetIt, una porta dedicata e una regola firewall.
# NON tocca altri servizi. NON usa mai taskkill /F su python o altri processi.
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File deploy-vps.ps1 -Port 8090
param(
  [int]$Port = 8090,
  [string]$Root = "C:\BeetIt",
  [string]$RepoUrl = "https://github.com/killBullox/ricettebuddy-io.git"
)

$ErrorActionPreference = "Stop"
Write-Host "== Beet-It backend deploy (porta $Port) =="

# 1. Cartella dedicata + repo
New-Item -ItemType Directory -Force -Path $Root | Out-Null
$repoDir = Join-Path $Root "ricettebuddy-io"
if (Test-Path (Join-Path $repoDir ".git")) {
  Write-Host "git pull..."; git -C $repoDir pull --ff-only
} else {
  Write-Host "git clone..."; git clone $RepoUrl $repoDir
}
$srv = Join-Path $repoDir "tools\local-server"
Set-Location $srv

# 2. Dipendenze
Write-Host "npm install..."; npm install --no-audit --no-fund
Write-Host "playwright chromium..."; npx --yes playwright install chromium

# 3. Chiave API (una volta): crea .env se manca
$envFile = Join-Path $srv ".env"
if (-not (Test-Path $envFile)) {
  $key = Read-Host "Incolla la ANTHROPIC_API_KEY"
  "ANTHROPIC_API_KEY=$key" | Set-Content $envFile -Encoding utf8
  Write-Host ".env creato."
} else { Write-Host ".env già presente." }

# 4. Firewall: apre SOLO questa porta in ingresso
$ruleName = "BeetIt-API-$Port"
if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
  New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow `
    -Protocol TCP -LocalPort $Port | Out-Null
  Write-Host "Regola firewall creata: $ruleName"
}

# 5. Build web (per servire anche la PWA dallo stesso URL) — opzionale, se c'è flutter
$webRoot = Join-Path $repoDir "app\build\web"

# 6. Scheduled Task: avvia il server a ogni boot (HOST=0.0.0.0, sopravvive al logoff)
$node = (Get-Command node).Source
$argLine = "`"$srv\app_server.js`""
$action = New-ScheduledTaskAction -Execute $node -Argument $argLine -WorkingDirectory $srv
$trigger = New-ScheduledTaskTrigger -AtStartup
$envHint = "HOST=0.0.0.0;PORT=$Port" + $(if (Test-Path $webRoot) { ";WEB_ROOT=$webRoot" } else { "" })
Write-Host "NB: imposta le variabili d'ambiente per il task: $envHint"
# (Le env per lo Scheduled Task si impostano meglio con un piccolo wrapper .cmd)
$wrapper = Join-Path $srv "run-beetit.cmd"
@"
@echo off
set HOST=0.0.0.0
set PORT=$Port
$(if (Test-Path $webRoot) { "set WEB_ROOT=$webRoot" })
"$node" "$srv\app_server.js"
"@ | Set-Content $wrapper -Encoding ascii
Register-ScheduledTask -TaskName "BeetIt-API" -Action (New-ScheduledTaskAction -Execute $wrapper) `
  -Trigger $trigger -RunLevel Highest -Force | Out-Null
Write-Host "Scheduled Task 'BeetIt-API' registrato (avvio al boot)."

# 7. Avvia subito
Start-Process -FilePath $wrapper -WindowStyle Hidden
Start-Sleep -Seconds 3
$ip = (Invoke-RestMethod -Uri "https://api.ipify.org").Trim()
Write-Host ""
Write-Host "== FATTO =="
Write-Host "Backend pubblico:  http://$ip`:$Port"
Write-Host "Test:              http://$ip`:$Port/api/recipes"
Write-Host "Usa questo come API_BASE nella build iOS."
