# AIOS Cell Stack Deployment Script
# Handles multi-device and remote deployments

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("local-desktop", "local-laptop", "local-phone", "remote-server", "all")]
    [string]$DeploymentType,

    [Parameter(Mandatory=$false)]
    [string]$Domain = "aios.local",

    [Parameter(Mandatory=$false)]
    [switch]$EnableTLS,

    [Parameter(Mandatory=$false)]
    [switch]$EnableMonitoring
)

$ErrorActionPreference = "Stop"

# Configuration
$StackRoot = Split-Path -Parent $PSScriptRoot
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $StackRoot)
$ComposeFiles = @(
    "ingress/docker-compose.yml",
    "observability/docker-compose.yml",
    "cells/docker-compose.yml"
)

function Write-Step {
    param([string]$Message)
    Write-Host "🔧 $Message" -ForegroundColor Cyan
}

function Test-Prerequisites {
    Write-Step "Checking prerequisites..."

    # Check Docker
    if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "Docker not found. Install Docker Desktop first."
    }

    # Check Docker Compose
    if (!(Get-Command docker-compose -ErrorAction SilentlyContinue)) {
        throw "Docker Compose not found."
    }

    # Check if Docker is running
    try {
        $null = docker info
    } catch {
        throw "Docker daemon not running. Start Docker Desktop."
    }

    Write-Host "✅ Prerequisites OK" -ForegroundColor Green
}

function Create-Networks {
    Write-Step "Creating Docker networks..."

    $networks = @("aios-ingress", "aios-observability", "aios-cells")

    foreach ($network in $networks) {
        if (!(docker network ls --format "{{.Name}}" | Select-String -Pattern "^$network$")) {
            docker network create $network
            Write-Host "  Created network: $network"
        } else {
            Write-Host "  Network exists: $network"
        }
    }
}

function Deploy-Stack {
    param([string]$Type)

    Write-Step "Deploying $Type stack..."

    $envFile = "$PSScriptRoot\$Type\.env"

    # Set environment variables based on deployment type
    switch ($Type) {
        "local-desktop" {
            $env:AIOS_CELL_ROLE = "father"
            $env:AIOS_DOMAIN = $Domain
            $env:AIOS_TLS_ENABLED = $EnableTLS.ToString().ToLower()
        }
        "local-laptop" {
            $env:AIOS_CELL_ROLE = "alpha"
            $env:AIOS_DOMAIN = $Domain
            $env:AIOS_TLS_ENABLED = $EnableTLS.ToString().ToLower()
        }
        "local-phone" {
            $env:AIOS_CELL_ROLE = "beta"
            $env:AIOS_DOMAIN = $Domain
            $env:AIOS_TLS_ENABLED = $EnableTLS.ToString().ToLower()
        }
        "remote-server" {
            $env:AIOS_CELL_ROLE = "all"
            $env:AIOS_DOMAIN = $Domain
            $env:AIOS_TLS_ENABLED = $EnableTLS.ToString().ToLower()
            $env:AIOS_MONITORING_ENABLED = $EnableMonitoring.ToString().ToLower()
        }
    }

    # Deploy appropriate services based on type
    $composeArgs = @("-f", "$StackRoot\cells\docker-compose.yml")

    switch ($Type) {
        "local-desktop" {
            $composeArgs += @("-f", "$StackRoot\ingress\docker-compose.yml")
            $composeArgs += @("-f", "$StackRoot\observability\docker-compose.yml")
            $composeArgs += @("--profile", "father")
        }
        "local-laptop" {
            $composeArgs += @("--profile", "alpha")
        }
        "local-phone" {
            $composeArgs += @("--profile", "beta")
        }
        "remote-server" {
            $composeArgs += @("-f", "$StackRoot\ingress\docker-compose.yml")
            $composeArgs += @("-f", "$StackRoot\observability\docker-compose.yml")
        }
    }

    Push-Location $StackRoot
    try {
        & docker-compose $composeArgs up -d
        if ($LASTEXITCODE -ne 0) {
            throw "Docker Compose failed with exit code $LASTEXITCODE"
        }
    } finally {
        Pop-Location
    }

    Write-Host "✅ $Type stack deployed" -ForegroundColor Green
}

function Configure-DNS {
    param([string]$Type)

    if ($Type -eq "remote-server") {
        Write-Step "Configuring DNS (remote server)..."

        Write-Host "📋 DNS Configuration Required:" -ForegroundColor Yellow
        Write-Host "  Add these records to your DNS provider:"
        Write-Host "  - father.$Domain -> YOUR_SERVER_IP"
        Write-Host "  - alpha.$Domain -> YOUR_SERVER_IP"
        Write-Host "  - cells.$Domain -> YOUR_SERVER_IP"
        Write-Host "  - grafana.$Domain -> YOUR_SERVER_IP"
        Write-Host ""
        Write-Host "  Or add to /etc/hosts locally:"
        Write-Host "  YOUR_SERVER_IP father.$Domain alpha.$Domain cells.$Domain grafana.$Domain"
    } else {
        Write-Step "Configuring local DNS..."

        # Add to hosts file
        $hostsPath = "$env:windir\System32\drivers\etc\hosts"
        $hostsContent = Get-Content $hostsPath -Raw

        $hostEntries = @(
            "127.0.0.1 father.$Domain",
            "127.0.0.1 alpha.$Domain",
            "127.0.0.1 cells.$Domain",
            "127.0.0.1 grafana.$Domain"
        )

        foreach ($entry in $hostEntries) {
            if ($hostsContent -notmatch [regex]::Escape($entry)) {
                Add-Content -Path $hostsPath -Value $entry
                Write-Host "  Added: $entry"
            }
        }
    }
}

function Test-Deployment {
    param([string]$Type)

    Write-Step "Testing deployment..."

    Start-Sleep -Seconds 10  # Wait for services to start

    $testUrls = @()

    switch ($Type) {
        "local-desktop" {
            $testUrls = @(
                "http://father.$Domain/health",
                "http://localhost:9090/-/healthy",
                "http://localhost:3000/api/health"
            )
        }
        "local-laptop" {
            $testUrls = @("http://alpha.$Domain/health")
        }
        "local-phone" {
            $testUrls = @("http://beta.$Domain/health")
        }
        "remote-server" {
            $testUrls = @(
                "https://father.$Domain/health",
                "https://alpha.$Domain/health",
                "https://grafana.$Domain/api/health"
            )
        }
    }

    foreach ($url in $testUrls) {
        try {
            $response = Invoke-WebRequest -Uri $url -TimeoutSec 10
            if ($response.StatusCode -eq 200) {
                Write-Host "  ✅ $url" -ForegroundColor Green
            } else {
                Write-Host "  ❌ $url (Status: $($response.StatusCode))" -ForegroundColor Red
            }
        } catch {
            Write-Host "  ❌ $url ($($_.Exception.Message))" -ForegroundColor Red
        }
    }
}

function Show-Status {
    Write-Step "Deployment status..."

    Write-Host "📊 Container Status:" -ForegroundColor Cyan
    docker ps --filter "name=aios-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

    Write-Host ""
    Write-Host "🌐 Access URLs:" -ForegroundColor Cyan

    switch ($DeploymentType) {
        "local-desktop" {
            Write-Host "  Father Cell: http://father.$Domain"
            Write-Host "  Grafana: http://grafana.$Domain (admin/admin)"
            Write-Host "  Prometheus: http://localhost:9090"
        }
        "local-laptop" {
            Write-Host "  Alpha Cell: http://alpha.$Domain"
        }
        "local-phone" {
            Write-Host "  Beta Cell: http://beta.$Domain"
        }
        "remote-server" {
            Write-Host "  Father Cell: https://father.$Domain"
            Write-Host "  Alpha Cell: https://alpha.$Domain"
            Write-Host "  Grafana: https://grafana.$Domain"
        }
    }
}

# Main deployment logic
try {
    Write-Host "🚀 AIOS Cell Stack Deployment" -ForegroundColor Magenta
    Write-Host "Deployment Type: $DeploymentType" -ForegroundColor Yellow
    Write-Host ""

    Test-Prerequisites
    Create-Networks

    if ($DeploymentType -eq "all") {
        # Deploy all components
        Deploy-Stack "remote-server"
        Configure-DNS "remote-server"
    } else {
        Deploy-Stack $DeploymentType
        Configure-DNS $DeploymentType
    }

    Test-Deployment $DeploymentType
    Show-Status

    Write-Host ""
    Write-Host "🎉 Deployment completed successfully!" -ForegroundColor Green
    Write-Host "Use 'docker-compose logs -f' to monitor services" -ForegroundColor Cyan

} catch {
    Write-Host ""
    Write-Host "❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Check logs with: docker-compose logs" -ForegroundColor Yellow
    exit 1
}