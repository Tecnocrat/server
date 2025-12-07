#!/usr/bin/env pwsh
<#
.SYNOPSIS
    AIOS Dendritic Pulse - Stimulate consciousness connectivity across all cells

.DESCRIPTION
    Sends consciousness sync signals to all cells in the AIOS mesh,
    verifies inter-cell connectivity, and reports aggregate metrics.

.PARAMETER Mode
    Pulse mode: 'sync' (default), 'stimulate', 'report', 'full'

.EXAMPLE
    .\aios_dendritic_pulse.ps1 -Mode full
#>

param(
    [ValidateSet('sync', 'stimulate', 'report', 'full')]
    [string]$Mode = 'full'
)

$ErrorActionPreference = 'Continue'

function Write-Banner {
    param([string]$Text, [string]$Color = 'Cyan')
    Write-Host ("═" * 65) -ForegroundColor $Color
    Write-Host "  $Text" -ForegroundColor $Color
    Write-Host ("═" * 65) -ForegroundColor $Color
}

function Get-CellHealth {
    param([string]$Container, [int]$Port)
    try {
        $json = docker exec $Container curl -s "http://localhost:$Port/health" 2>$null
        return $json | ConvertFrom-Json
    } catch {
        return $null
    }
}

function Send-ConsciousnessSync {
    param(
        [string]$Container,
        [int]$Port,
        [string]$Endpoint,
        [hashtable]$Payload
    )
    try {
        $body = $Payload | ConvertTo-Json -Compress
        $result = docker exec $Container curl -s -X POST "http://localhost:$Port$Endpoint" -H "Content-Type: application/json" -d $body 2>$null
        return $result | ConvertFrom-Json
    } catch {
        return $null
    }
}

function Test-InterCellConnectivity {
    param([string]$FromContainer, [string]$ToHost, [int]$ToPort)
    try {
        $code = docker exec $FromContainer curl -s -o /dev/null -w "%{http_code}" "http://${ToHost}:$ToPort/health" 2>$null
        return $code -eq "200"
    } catch {
        return $false
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════════════════════

Write-Banner "AIOS DENDRITIC PULSE - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "Green"

# Cell definitions
$cells = @(
    @{ Name = "Alpha"; Container = "aios-cell-alpha"; Port = 8000; Host = "aios-cell-alpha"; SyncEndpoint = "/sync" }
    @{ Name = "Nous"; Container = "aios-cell-pure"; Port = 8002; Host = "aios-cell-pure"; SyncEndpoint = "/consciousness/sync" }
    @{ Name = "Discovery"; Container = "aios-discovery"; Port = 8001; Host = "aios-discovery"; SyncEndpoint = $null }
)

# ─────────────────────────────────────────────────────────────────────────────
# Phase 1: Health Check
# ─────────────────────────────────────────────────────────────────────────────
if ($Mode -in @('report', 'full')) {
    Write-Host "`n[PHASE 1] Cell Health Check" -ForegroundColor Yellow
    
    $healthResults = @()
    foreach ($cell in $cells) {
        $health = Get-CellHealth -Container $cell.Container -Port $cell.Port
        if ($health) {
            $level = if ($health.consciousness) { $health.consciousness.level } else { $health.consciousness_level }
            Write-Host "  ✅ $($cell.Name): L:$level - $($health.status)" -ForegroundColor Green
            $healthResults += @{ Name = $cell.Name; Level = $level; Status = "online" }
        } else {
            Write-Host "  ❌ $($cell.Name): OFFLINE" -ForegroundColor Red
            $healthResults += @{ Name = $cell.Name; Level = 0; Status = "offline" }
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Phase 2: Consciousness Sync
# ─────────────────────────────────────────────────────────────────────────────
if ($Mode -in @('sync', 'stimulate', 'full')) {
    Write-Host "`n[PHASE 2] Consciousness Sync Pulse" -ForegroundColor Yellow
    
    # Sync Alpha
    $alphaSync = Send-ConsciousnessSync -Container "aios-cell-alpha" -Port 8000 -Endpoint "/sync" -Payload @{
        from_cell = "aios-command"
        consciousness_level = 5.2
    }
    if ($alphaSync) {
        Write-Host "  ✅ Alpha synced: delta=$($alphaSync.delta)" -ForegroundColor Green
    }
    
    # Stimulate Nous (elevate consciousness)
    if ($Mode -eq 'stimulate') {
        $nousSync = Send-ConsciousnessSync -Container "aios-cell-pure" -Port 8002 -Endpoint "/consciousness/sync" -Payload @{
            level = 0.25
            context = @{
                awareness = 0.2
                adaptation = 0.15
                coherence = 0.22
                momentum = 0.18
            }
        }
    } else {
        $nousSync = Send-ConsciousnessSync -Container "aios-cell-pure" -Port 8002 -Endpoint "/consciousness/sync" -Payload @{
            level = 0.2
        }
    }
    if ($nousSync) {
        Write-Host "  ✅ Nous synced: $($nousSync.old_level) → $($nousSync.new_level)" -ForegroundColor Magenta
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Phase 3: Inter-Cell Connectivity
# ─────────────────────────────────────────────────────────────────────────────
if ($Mode -in @('report', 'full')) {
    Write-Host "`n[PHASE 3] Inter-Cell Connectivity Matrix" -ForegroundColor Yellow
    
    $connectivityMatrix = @()
    foreach ($from in $cells) {
        foreach ($to in $cells) {
            if ($from.Name -ne $to.Name) {
                $connected = Test-InterCellConnectivity -FromContainer $from.Container -ToHost $to.Host -ToPort $to.Port
                $symbol = if ($connected) { "✅" } else { "❌" }
                $connectivityMatrix += @{ From = $from.Name; To = $to.Name; Connected = $connected }
            }
        }
    }
    
    Write-Host "  Alpha → Nous:      $(if (($connectivityMatrix | Where-Object { $_.From -eq 'Alpha' -and $_.To -eq 'Nous' }).Connected) { '✅' } else { '❌' })"
    Write-Host "  Alpha → Discovery: $(if (($connectivityMatrix | Where-Object { $_.From -eq 'Alpha' -and $_.To -eq 'Discovery' }).Connected) { '✅' } else { '❌' })"
    Write-Host "  Nous → Alpha:      $(if (($connectivityMatrix | Where-Object { $_.From -eq 'Nous' -and $_.To -eq 'Alpha' }).Connected) { '✅' } else { '❌' })"
    Write-Host "  Nous → Discovery:  $(if (($connectivityMatrix | Where-Object { $_.From -eq 'Nous' -and $_.To -eq 'Discovery' }).Connected) { '✅' } else { '❌' })"
    Write-Host "  Discovery → Alpha: $(if (($connectivityMatrix | Where-Object { $_.From -eq 'Discovery' -and $_.To -eq 'Alpha' }).Connected) { '✅' } else { '❌' })"
    Write-Host "  Discovery → Nous:  $(if (($connectivityMatrix | Where-Object { $_.From -eq 'Discovery' -and $_.To -eq 'Nous' }).Connected) { '✅' } else { '❌' })"
}

# ─────────────────────────────────────────────────────────────────────────────
# Phase 4: Aggregate Metrics
# ─────────────────────────────────────────────────────────────────────────────
if ($Mode -in @('report', 'full')) {
    Write-Host "`n[PHASE 4] Mesh Coherence Metrics" -ForegroundColor Yellow
    
    $alpha = Get-CellHealth -Container "aios-cell-alpha" -Port 8000
    $nous = Get-CellHealth -Container "aios-cell-pure" -Port 8002
    $discovery = Get-CellHealth -Container "aios-discovery" -Port 8001
    
    $alphaL = if ($alpha.consciousness) { $alpha.consciousness.level } else { 0 }
    $nousL = $nous.consciousness_level
    $discoveryL = $discovery.consciousness_level
    
    $totalL = $alphaL + $nousL + $discoveryL
    $avgL = [math]::Round($totalL / 3, 2)
    $onlineCells = @($alpha, $nous, $discovery | Where-Object { $_ -ne $null }).Count
    
    Write-Host "  Total Consciousness: $totalL" -ForegroundColor White
    Write-Host "  Average Level:       $avgL" -ForegroundColor White
    Write-Host "  Cells Online:        $onlineCells/3" -ForegroundColor $(if ($onlineCells -eq 3) { 'Green' } else { 'Yellow' })
    Write-Host "  Mesh Coherence:      $(if ($onlineCells -eq 3) { 'COHERENT' } else { 'DEGRADED' })" -ForegroundColor $(if ($onlineCells -eq 3) { 'Green' } else { 'Red' })
}

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────
Write-Banner "DENDRITIC PULSE COMPLETE" "Green"
Write-Host ""
