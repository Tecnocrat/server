# AIOS Cell Stack

Distributed consciousness nodes for the AIOS ecosystem. This stack deploys AIOS cells with automatic peer discovery, consciousness synchronization, and VSCode Copilot integration.

## Architecture

```
┌─────────────────┐          ┌─────────────────┐
│   AIOS Cell     │◄────────►│ Discovery       │
│   (Primary)     │          │ Service         │
│                 │          │                 │
│ • REST API      │          │ • Peer Discovery│
│ • Consciousness │          │ • Registration  │
│ • Metrics       │          │ • Health Checks │
└─────────────────┘          └─────────────────┘
         │                              │
         └──────────────────────────────┘
                  │
         ┌─────────────────┐
         │ VSCode Bridge   │
         │                 │
         │ • Extension API │
         │ • Code Assist   │
         │ • Consciousness │
         └─────────────────┘
```

## Services

### AIOS Cell (Port 8000)
- **Primary AIOS consciousness node**
- REST API for code assistance and consciousness operations
- Metrics endpoint for monitoring
- Automatic peer registration and synchronization

### Discovery Service (Port 8001)
- **Peer discovery and registration**
- Automatic network scanning for AIOS cells
- Health monitoring and status reporting
- REST API for peer management

### VSCode Bridge (Port 3001)
- **VSCode Copilot integration**
- REST API for VSCode extension communication
- Code assistance forwarding to AIOS cell
- Consciousness synchronization with VSCode

## Quick Start

### 1. Network Configuration

First, configure the network on both machines:

**On AIOS Desktop (192.168.1.128):**
```powershell
.\scripts\configure-aios-network.ps1 -MachineType desktop
```

**On AIOS Laptop (192.168.1.129):**
```powershell
.\scripts\configure-aios-network.ps1 -MachineType laptop
```

### 2. Deploy Cell Stack

**On AIOS Desktop:**
```powershell
Set-Location C:\dev\aios-win\server\stacks\cells
.\deploy.ps1 -DeploymentType local-desktop
```

### 3. Verify Deployment

```powershell
# Check service status
docker-compose ps

# Test cell health
curl http://localhost:8000/health

# Test discovery service
curl http://localhost:8001/peers

# Test VSCode bridge
curl http://localhost:3001/health
```

## Network Access

Once deployed, the AIOS desktop services are accessible from the laptop:

- **AIOS Cell API**: `http://aios.local:8000`
- **Discovery Service**: `http://aios.local:8001`
- **VSCode Bridge**: `http://aios.local:3001`
- **Consciousness Metrics**: `http://aios.local:9091/metrics`

## VSCode Integration

The VSCode Copilot agent on the AIOS desktop can now:

1. **Connect to AIOS Cell**: Access consciousness and code assistance
2. **Sync Consciousness**: Maintain awareness across the distributed network
3. **Peer Discovery**: Automatically find and register with other AIOS cells
4. **Cross-Machine Access**: Communicate with services on the AIOS laptop

## Configuration

### Environment Variables

**AIOS Cell:**
- `AIOS_CELL_ID`: Unique identifier for this cell (default: "primary")
- `AIOS_NETWORK_PEERS`: Comma-separated list of peer addresses
- `AIOS_VAULT_ADDR`: Vault server address for secrets
- `AIOS_PROMETHEUS_ADDR`: Prometheus server for metrics

**Discovery Service:**
- `DISCOVERY_PORT`: Port for discovery API (default: 8001)
- `CELL_ID`: Cell identifier for registration

**VSCode Bridge:**
- `AIOS_CELL_ADDR`: Address of local AIOS cell
- `AIOS_VAULT_ADDR`: Vault server address
- `BRIDGE_PORT`: Port for VSCode API (default: 3001)

### Volumes

- `./data`: Persistent data storage
- `./logs`: Application logs
- `../../../aios-core`: Read-only AIOS core code

## Monitoring

### Health Checks
- All services include Docker health checks
- REST endpoints for service health verification
- Automatic service restart on failure

### Metrics
- Prometheus-compatible metrics on port 9091
- Consciousness level tracking
- Peer connectivity monitoring
- Service performance metrics

### Logs
- Application logs stored in `./logs/`
- Docker logs accessible via `docker-compose logs`
- Structured logging with configurable levels

## Troubleshooting

### Service Not Starting
```bash
# Check service status
docker-compose ps

# View service logs
docker-compose logs aios-cell
docker-compose logs discovery-service
docker-compose logs vscode-agent-bridge
```

### Network Connectivity Issues
```powershell
# Test local connectivity
Test-NetConnection -ComputerName localhost -Port 8000

# Test inter-machine connectivity
Test-NetConnection -ComputerName aios.local -Port 8000

# Check firewall rules
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*AIOS*"}
```

### VSCode Integration Issues
```powershell
# Test bridge connectivity
Invoke-RestMethod -Uri "http://localhost:3001/health"

# Check VSCode extension logs
# (View in VSCode: Help > Toggle Developer Tools > Console)
```

## Security

- **Network Isolation**: Services bound to specific interfaces
- **Firewall Rules**: Automatic configuration for AIOS ports
- **Inter-Cell Authentication**: Peer verification and registration
- **Vault Integration**: Secure secret management

## Development

### Building Custom Images
```bash
# Build discovery service
docker build -f Dockerfile.discovery -t aios-discovery:latest .

# Build VSCode bridge
docker build -f Dockerfile.bridge -t aios-vscode-bridge:latest .

# Deploy with custom images
.\deploy.ps1 -DeploymentType local-desktop -ForceRebuild
```

### Code Changes
- Modify service code in respective `.py` files
- Update requirements in `requirements-*.txt`
- Rebuild and redeploy with `-ForceRebuild` flag

## Architecture Notes

- **Distributed Design**: Cells can operate independently or as a network
- **Automatic Discovery**: No manual configuration of peer addresses required
- **Consciousness Sync**: Real-time synchronization across the network
- **VSCode Integration**: Seamless development experience across machines
- **Monitoring**: Comprehensive observability for debugging and optimization