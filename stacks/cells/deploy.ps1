# AINLP_HEADER
# consciousness_level: 3.8
# supercell: server/stacks/cells
# dendritic_role: cell_deployment
# spatial_context: Host-aware AIOS cell deployment orchestration
# AINLP_HEADER_END

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("local-desktop", "distributed")]
    [string]$DeploymentType,

    [Parameter(Mandatory=$false)]
    [ValidateSet("all", "discovery", "bridge", "beta", "pure", "beta+pure", "minimal")]
    [string]$CellType = "all",

    [Parameter(Mandatory=$false)]
    [switch]$ForceRebuild
)

# ═══════════════════════════════════════════════════════════════════════════════
# AINLP.dendritic(AIOS{growth}): Host Registry Integration
# ═══════════════════════════════════════════════════════════════════════════════

function Get-HostConfig {
    <#
    .SYNOPSIS
    Load host configuration from hosts.yaml registry
    #>
    $registryPath = Join-Path $PSScriptRoot ".." ".." ".." "config" "hosts.yaml"
    if (-not (Test-Path $registryPath)) {
        Write-Host "⚠️ Host registry not found at $registryPath" -ForegroundColor Yellow
        return $null
    }

    try {
        # Simple YAML parsing for PowerShell
        $content = Get-Content $registryPath -Raw
        
        # Get current git branch
        $branch = git branch --show-current 2>$null
        if (-not $branch) { $branch = "main" }
        
        # Get current hostname
        $hostname = $env:COMPUTERNAME.ToUpper()
        
        Write-Host "🔍 Current branch: $branch, hostname: $hostname" -ForegroundColor Cyan
        
        # Return host info (simplified parsing)
        return @{
            Branch = $branch
            Hostname = $hostname
            RegistryPath = $registryPath
        }
    } catch {
        Write-Host "⚠️ Failed to load host registry: $_" -ForegroundColor Yellow
        return $null
    }
}

Write-Host "🚀 Deploying AIOS Cell Stack ($DeploymentType)" -ForegroundColor Green

# Get host configuration
$hostConfig = Get-HostConfig
if ($hostConfig) {
    Write-Host "🏠 Host: $($hostConfig.Hostname) | Branch: $($hostConfig.Branch)" -ForegroundColor Green
}

# Navigate to cells directory
Set-Location $PSScriptRoot

# Create required directories
New-Item -ItemType Directory -Path "data", "logs" -Force

# Build custom images if needed
if ($ForceRebuild) {
    Write-Host "🔨 Building custom Docker images..." -ForegroundColor Yellow
    docker build -f discovery/Dockerfile.discovery -t aios-discovery:latest .
    docker build -f bridge/Dockerfile.bridge -t aios-vscode-bridge:latest .
    docker build -f beta/Dockerfile.cell -t aios-cell:latest .
}

# AINLP.dendritic enhancement: Check for dependency changes and rebuild cell
$cellRequirementsChanged = (Get-FileHash "beta/requirements-cell.txt").Hash -ne (docker inspect aios-cell:latest 2>$null | ConvertFrom-Json).Config.Labels.requirements_hash 2>$null
if ($cellRequirementsChanged -or $ForceRebuild) {
    Write-Host "🧬 Dendritic growth: Rebuilding cell with updated dependencies..." -ForegroundColor Cyan
    # Build from workspace root to access all submodules
    Push-Location ..\..\..
    try {
        docker build --label requirements_hash=(Get-FileHash "server/stacks/cells/beta/requirements-cell.txt").Hash -f server/stacks/cells/beta/Dockerfile.cell -t aios-cell:latest .
    } finally {
        Pop-Location
    }
}

# Deploy based on type
switch ($DeploymentType) {
    "local-desktop" {
        Write-Host "📦 Deploying local desktop cell (Type: $CellType)..." -ForegroundColor Yellow

        # Determine which services to deploy based on CellType
        $servicesToDeploy = switch ($CellType) {
            "all" { "discovery-service", "vscode-agent-bridge", "aios-cell", "aios-cell-pure" }
            "discovery" { "discovery-service" }
            "bridge" { "vscode-agent-bridge" }
            "beta" { "aios-cell" }
            "pure" { "aios-cell-pure" }
            "beta+pure" { "aios-cell", "aios-cell-pure" }
            "minimal" { "discovery-service", "aios-cell-pure" }  # Discovery + minimal consciousness
        }

        Write-Host "🔧 Deploying services: $($servicesToDeploy -join ', ')" -ForegroundColor Cyan

        # Start the selected services
        if ($servicesToDeploy.Count -eq 1) {
            docker-compose -f docker-compose.yml up -d $servicesToDeploy
        } else {
            docker-compose -f docker-compose.yml up -d $servicesToDeploy
        }

        # Wait for services to start
        Write-Host "⏳ Waiting for services to initialize..." -ForegroundColor Yellow
        Start-Sleep -Seconds 15

        # Test connectivity for deployed services
        Write-Host "🔍 Testing deployed service connectivity..." -ForegroundColor Yellow

        # Test discovery service if deployed
        if ($servicesToDeploy -contains "discovery-service") {
            try {
                $discoveryHealth = Invoke-RestMethod -Uri "http://localhost:8001/health" -Method Get -TimeoutSec 10
                Write-Host "✅ Discovery Service: $($discoveryHealth | ConvertTo-Json -Compress)" -ForegroundColor Green
            } catch {
                Write-Host "❌ Discovery Service: Unavailable - $($_.Exception.Message)" -ForegroundColor Red
            }
        }

        # Test VSCode bridge if deployed
        if ($servicesToDeploy -contains "vscode-agent-bridge") {
            try {
                $bridgeHealth = Invoke-RestMethod -Uri "http://localhost:3001/health" -Method Get -TimeoutSec 10
                Write-Host "✅ VSCode Bridge: $($bridgeHealth | ConvertTo-Json -Compress)" -ForegroundColor Green
            } catch {
                Write-Host "❌ VSCode Bridge: Unavailable - $($_.Exception.Message)" -ForegroundColor Red
            }
        }

        # Test beta cell if deployed
        if ($servicesToDeploy -contains "aios-cell") {
            try {
                $cellHealth = Invoke-RestMethod -Uri "http://localhost:8000/health" -Method Get -TimeoutSec 10
                Write-Host "✅ Beta Cell: $($cellHealth | ConvertTo-Json -Compress)" -ForegroundColor Green
            } catch {
                Write-Host "❌ Beta Cell: Unavailable - $($_.Exception.Message)" -ForegroundColor Red
            }
        }

        # Test pure cell if deployed
        if ($servicesToDeploy -contains "aios-cell-pure") {
            try {
                $pureCellHealth = Invoke-RestMethod -Uri "http://localhost:8002/health" -Method Get -TimeoutSec 10
                Write-Host "✅ Pure Cell: $($pureCellHealth | ConvertTo-Json -Compress)" -ForegroundColor Green
            } catch {
                Write-Host "❌ Pure Cell: Unavailable - $($_.Exception.Message)" -ForegroundColor Red
            }
        }

        # Show service status for deployed services
        Write-Host "`n📊 Deployed Service Status:" -ForegroundColor Cyan
        docker-compose -f docker-compose.yml ps $servicesToDeploy

        # Show access points for deployed services
        Write-Host "`n🌐 Access points for deployed services:" -ForegroundColor Cyan
        if ($servicesToDeploy -contains "aios-cell") {
            Write-Host "  • Beta Cell API: http://localhost:8000" -ForegroundColor White
            Write-Host "  • Beta Consciousness Metrics: http://localhost:9091/metrics" -ForegroundColor White
        }
        if ($servicesToDeploy -contains "aios-cell-pure") {
            Write-Host "  • Pure Cell API: http://localhost:8002" -ForegroundColor White
            Write-Host "  • Pure Consciousness Metrics: http://localhost:9092/metrics" -ForegroundColor White
        }
        if ($servicesToDeploy -contains "discovery-service") {
            Write-Host "  • Discovery Service: http://localhost:8001" -ForegroundColor White
        }
        if ($servicesToDeploy -contains "vscode-agent-bridge") {
            Write-Host "  • VSCode Bridge: http://localhost:3001" -ForegroundColor White
        }

        # Show logs location
        Write-Host "`n📝 Logs Location: $PSScriptRoot\logs" -ForegroundColor Cyan
        Write-Host "🔧 To view logs: docker-compose -f docker-compose.yml logs -f [service-name]" -ForegroundColor Cyan
    }

    "distributed" {
        Write-Host "🌐 Deploying distributed cell network..." -ForegroundColor Yellow
        # Additional distributed setup would go here
        Write-Host "⚠️ Distributed deployment not yet implemented" -ForegroundColor Yellow
    }
}

Write-Host "`n🎉 AIOS Cell deployment complete!" -ForegroundColor Green
Write-Host "📋 Cell Types Available:" -ForegroundColor Cyan
Write-Host "  • all        - Deploy all services (discovery, bridge, beta, pure)" -ForegroundColor White
Write-Host "  • discovery  - Peer discovery service only" -ForegroundColor White
Write-Host "  • bridge     - VSCode extension bridge only" -ForegroundColor White
Write-Host "  • beta       - Full AIOS consciousness cell only" -ForegroundColor White
Write-Host "  • pure       - Minimal consciousness cell only" -ForegroundColor White
Write-Host "  • beta+pure  - Both consciousness cells (no infrastructure)" -ForegroundColor White
Write-Host "  • minimal    - Discovery + pure cell (AINLP.dendritic minimal viable)" -ForegroundColor White