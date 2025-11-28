param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("local-desktop", "distributed")]
    [string]$DeploymentType,

    [Parameter(Mandatory=$false)]
    [switch]$ForceRebuild
)

Write-Host "🚀 Deploying AIOS Cell Stack ($DeploymentType)" -ForegroundColor Green

# Navigate to cells directory
Set-Location $PSScriptRoot

# Create required directories
New-Item -ItemType Directory -Path "data", "logs" -Force

# Build custom images if needed
if ($ForceRebuild) {
    Write-Host "🔨 Building custom Docker images..." -ForegroundColor Yellow
    docker build -f Dockerfile.discovery -t aios-discovery:latest .
    docker build -f Dockerfile.bridge -t aios-vscode-bridge:latest .
}

# Deploy based on type
switch ($DeploymentType) {
    "local-desktop" {
        Write-Host "📦 Deploying local desktop cell..." -ForegroundColor Yellow

        # Start the stack
        docker-compose -f docker-compose.yml up -d

        # Wait for services to start
        Write-Host "⏳ Waiting for services to initialize..." -ForegroundColor Yellow
        Start-Sleep -Seconds 15

        # Test connectivity
        Write-Host "🔍 Testing service connectivity..." -ForegroundColor Yellow

        # Test cell health
        try {
            $cellHealth = Invoke-RestMethod -Uri "http://localhost:8000/health" -Method Get -TimeoutSec 10
            Write-Host "✅ AIOS Cell: $($cellHealth | ConvertTo-Json -Compress)" -ForegroundColor Green
        } catch {
            Write-Host "❌ AIOS Cell: Unavailable - $($_.Exception.Message)" -ForegroundColor Red
        }

        # Test discovery service
        try {
            $discoveryHealth = Invoke-RestMethod -Uri "http://localhost:8001/health" -Method Get -TimeoutSec 10
            Write-Host "✅ Discovery Service: $($discoveryHealth | ConvertTo-Json -Compress)" -ForegroundColor Green
        } catch {
            Write-Host "❌ Discovery Service: Unavailable - $($_.Exception.Message)" -ForegroundColor Red
        }

        # Test VSCode bridge
        try {
            $bridgeHealth = Invoke-RestMethod -Uri "http://localhost:3001/health" -Method Get -TimeoutSec 10
            Write-Host "✅ VSCode Bridge: $($bridgeHealth | ConvertTo-Json -Compress)" -ForegroundColor Green
        } catch {
            Write-Host "❌ VSCode Bridge: Unavailable - $($_.Exception.Message)" -ForegroundColor Red
        }

        # Show service status
        Write-Host "`n📊 Service Status:" -ForegroundColor Cyan
        docker-compose -f docker-compose.yml ps

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
Write-Host "🌐 Access points:" -ForegroundColor Cyan
Write-Host "  • AIOS Cell API: http://localhost:8000" -ForegroundColor White
Write-Host "  • Discovery Service: http://localhost:8001" -ForegroundColor White
Write-Host "  • VSCode Bridge: http://localhost:3001" -ForegroundColor White
Write-Host "  • Consciousness Metrics: http://localhost:9091/metrics" -ForegroundColor White