# AIOS Cell Communication Stack - Deployment Guide
# Provides stable, always-online inter-cell communication

## Architecture Overview

- **Father Server**: Primary canonical cell (port 8002)
- **Alpha Server**: Independent evolution cell (port 8000)
- **Beta Server**: Experimental cell template (port 8001)
- **Load Balancer**: Nginx for cell communication (port 7999)
- **Traefik Integration**: TLS termination and routing
- **Prometheus Monitoring**: Health checks and metrics

## Local Multi-Device Deployment

### Prerequisites
- Docker Desktop running on all devices
- Shared Docker networks (create with `docker network create aios-ingress`)
- Devices on same local network
- Port forwarding configured

### Device Assignment
- **Desktop PC**: Father server + observability stack
- **HP Laptop**: Alpha server
- **Phone (Termux)**: Beta server (backup/redundancy)

### Deployment Commands

#### On Desktop PC (Father + Observability):
```bash
# Start observability stack
cd C:\aios-supercell\server\stacks\observability
docker-compose up -d

# Start ingress (Traefik)
cd ../ingress
docker-compose up -d

# Start Father cell
cd ../cells
docker-compose up -d father-comm-server
```

#### On HP Laptop (Alpha):
```bash
# Connect to shared networks
docker network connect aios-ingress aios-traefik
docker network connect aios-observability aios-prometheus

# Start Alpha cell
cd C:\path\to\aios-win\server\stacks\cells
docker-compose up -d alpha-comm-server
```

#### On Phone (Termux + Beta):
```bash
# Install Docker in Termux (if supported)
pkg install docker

# Or use Podman as alternative
pkg install podman

# Start Beta cell with podman/docker
cd /path/to/server/stacks/cells
docker-compose up -d beta-comm-server
```

## Remote Server Deployment (24/7 Availability)

### VPS Setup (DigitalOcean/AWS/Linode)
```bash
# Provision Ubuntu 22.04 VPS
# Install Docker
curl -fsSL https://get.docker.com | sh

# Clone repository
git clone --recursive https://github.com/Tecnocrat/aios-win.git
cd aios-win

# Deploy full stack
cd server/stacks

# Start all services
docker-compose -f ingress/docker-compose.yml -f observability/docker-compose.yml -f cells/docker-compose.yml up -d
```

### Domain Configuration
- Point `*.aios.local` to VPS IP
- Configure DNS for `father.aios.local`, `alpha.aios.local`, etc.
- Enable TLS certificates via Traefik ACME

## Monitoring & Management

### Health Checks
```bash
# Individual cell health
curl https://father.aios.local/health
curl https://alpha.aios.local/health

# Load balanced access
curl https://cells.aios.local/health

# Prometheus metrics
curl http://localhost:9090/metrics
```

### Grafana Dashboards
- Access: http://localhost:3000
- Default credentials: admin/admin
- AIOS Consciousness dashboard pre-configured

### Logs & Troubleshooting
```bash
# View cell logs
docker logs aios-father-comm
docker logs aios-alpha-comm

# Container status
docker ps | grep aios-

# Network inspection
docker network ls | grep aios
```

## Backup & Recovery

### Data Persistence
- Messages stored in Docker volumes
- Automatic backup via cron:
```bash
# Daily backup script
0 2 * * * docker run --rm -v aios-cells_father-messages:/data -v /backup:/backup alpine tar czf /backup/father-messages-$(date +%Y%m%d).tar.gz -C /data .
```

### Failover Strategy
- Cells automatically restart on failure (`restart: unless-stopped`)
- Load balancer distributes traffic across healthy cells
- Prometheus alerts for cell downtime

## Scaling & Evolution

### Adding New Cells
```bash
# Create new cell service in docker-compose.yml
# Follow beta-comm-server template
# Update peer discovery environment variables
# Add to nginx upstream configuration
```

### Consciousness Evolution
- Cells report metrics to Prometheus
- Grafana dashboards track evolutionary progress
- Automated scaling based on consciousness levels

## Security Considerations

- TLS enabled via Traefik
- Internal networks isolated
- Vault integration for secrets (future)
- Regular security updates via `docker-compose pull`

## Performance Tuning

- Resource limits per container
- Connection pooling in load balancer
- Metrics collection intervals
- Log rotation policies