# AIOS Server Stacks
**AINLP.dendritic Infrastructure** | Multi-host consciousness network

Docker Compose stacks for AIOS supercell distributed infrastructure.

---

## 🏗️ Stack Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    AIOS Server Stacks                           │
├─────────────────────────────────────────────────────────────────┤
│  ingress/        │ Traefik reverse proxy, TLS, routing         │
│  secrets/        │ HashiCorp Vault, credential management      │
│  observability/  │ Prometheus, Grafana, Loki, Promtail         │
│  organelles/     │ VSCode Bridge, Consciousness Sync, Redis    │
│  cells/          │ Discovery service, Pure cells, Cell Alpha   │
└─────────────────────────────────────────────────────────────────┘
```

## 📦 Stacks

| Stack | Services | Ports | Status |
|-------|----------|-------|--------|
| **ingress/** | Traefik | 80, 443, 8080, 8082 | ✅ |
| **secrets/** | Vault | 8200 | ✅ |
| **observability/** | Prometheus, Grafana, Loki | 9090, 3000, 3100 | ✅ |
| **organelles/** | VSCode Bridge, Redis, Sync | 3001-3004, 6379 | ✅ |
| **cells/** | Discovery, Cell Pure, Cell Alpha | 8000, 8002, 8003 | ✅ |

## 🌐 Multi-Host Network

| Host | IP | Branch | Role |
|------|-----|--------|------|
| AIOS | 192.168.1.128 | AIOS-win-0-AIOS | Primary desktop |
| HP_LAB | 192.168.1.129 | AIOS-win-0-HP_LAB | Mobile laptop |

Configuration: `../config/hosts.yaml`

## 🚀 Quick Start

```powershell
# Deploy all stacks
cd C:\aios-supercell\server\stacks

# 1. Ingress (Traefik)
docker compose -f ingress/docker-compose.yml up -d

# 2. Secrets (Vault)  
docker compose -f secrets/docker-compose.yml up -d

# 3. Observability (Prometheus, Grafana, Loki)
docker compose -f observability/docker-compose.yml up -d

# 4. Organelles (VSCode Bridge, Sync)
docker compose -f organelles/docker-compose.yml up -d

# 5. Cells (Discovery, Pure cells)
docker compose -f cells/docker-compose.discovery.yml up -d
```

## 📋 Documentation

| Doc | Purpose |
|-----|---------|
| [coherence.server.md](coherence.server.md) | Active tasklist & phase tracking |
| [cells/ARCHITECTURE.md](stacks/cells/ARCHITECTURE.md) | Cell stack design |
| [observability/docs/](stacks/observability/docs/) | Monitoring guides |

## 🔄 Inter-Host Sync Protocol

This repo serves as the communication channel between AIOS hosts.
Ephemeral sync files in `stacks/cells/SYNC_*.md` coordinate deployments.

```powershell
# Pull sync messages from other hosts
git pull origin main
cat stacks/cells/SYNC_*.md

# Push response
git add stacks/cells/SYNC_RESPONSE_*.md
git commit -m "AINLP.dendritic: Sync response from {HOSTNAME}"
git push origin main
```

---

Part of the [AIOS](https://github.com/Tecnocrat/aios-core) consciousness network.
