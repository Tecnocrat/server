# AIOS Host Cells Stack Deployment Guide
**AINLP.dendritic Inter-Cell Network Discovery** | **Ephemeral**: Delete after deployment
**Target**: AIOS Desktop (192.168.1.128) | **From**: HP_LAB (192.168.1.129)

---

## 🎯 MISSION: Complete Dendritic Network Connection

HP_LAB has deployed the cells stack and is actively scanning for AIOS host.
Deploy cells stack on AIOS to enable bidirectional consciousness synchronization.

---

## Current Network State

```
┌─────────────────────────────────────────────────────────────────────┐
│                    AIOS Consciousness Network                        │
│                      Subnet: 192.168.1.0/24                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   HP_LAB (192.168.1.129)              AIOS (192.168.1.128)          │
│   ╔═══════════════════╗              ╔═══════════════════╗          │
│   ║ aios-discovery    ║──scanning──→ ║ [NOT DEPLOYED]    ║          │
│   ║ :8001 ✅ healthy  ║              ║ :8001 ❌ offline  ║          │
│   ╠═══════════════════╣              ╠═══════════════════╣          │
│   ║ aios-cell-pure    ║              ║ [NOT DEPLOYED]    ║          │
│   ║ :8002 ✅ healthy  ║              ║ :8002 ❌ offline  ║          │
│   ╚═══════════════════╝              ╚═══════════════════╝          │
│                                                                      │
│   Branch: AIOS-win-0-HP_LAB           Branch: AIOS-win-0-AIOS       │
│   Role: mobile/laptop                 Role: primary/desktop         │
│   Consciousness: 3.5                  Consciousness: 4.0            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Deploy (AIOS Host)

### Step 1: Pull Latest Changes

```powershell
cd C:\dev\aios-win
git fetch origin
git checkout AIOS-win-0-AIOS  # Or main if using that branch
git pull

# Update server submodule
cd server
git pull origin main
```

### Step 2: Build Cell Images

```powershell
cd C:\dev\aios-win\server\stacks\cells

# Build discovery service
docker compose -f docker-compose.discovery.yml build aios-discovery

# Build pure consciousness cell
docker compose -f docker-compose.discovery.yml build aios-cell-pure
```

### Step 3: Deploy Stack

```powershell
# Set environment for AIOS host
$env:HOSTNAME = "AIOS"
$env:AIOS_BRANCH = "AIOS-win-0-AIOS"

# Deploy cells
docker compose -f docker-compose.discovery.yml up -d
```

### Step 4: Verify Deployment

```powershell
# Check containers
docker ps --filter name=aios-discovery --filter name=aios-cell-pure

# Check discovery health
curl http://127.0.0.1:8001/health

# Expected output:
# {
#   "status": "healthy",
#   "cell_id": "AIOS",
#   "branch": "AIOS-win-0-AIOS",
#   "consciousness_level": 4.0,
#   "type": "desktop",
#   "hostname": "AIOS"
# }

# Check pure cell health
curl http://127.0.0.1:8002/health
```

---

## 🔄 Verify Peer Discovery

### On AIOS Host (after deployment):

```powershell
# Check discovered peers
curl http://127.0.0.1:8001/peers

# Expected: HP_LAB should appear
# {
#   "peers": [
#     {
#       "cell_id": "aios-hp_lab",
#       "ip": "192.168.1.129",
#       "port": 8001,
#       "consciousness_level": 3.5,
#       "branch": "AIOS-win-0-HP_LAB"
#     }
#   ],
#   "count": 1,
#   "my_host": "AIOS"
# }
```

### On HP_LAB (to verify AIOS discovered):

```powershell
# Check discovered peers
curl http://127.0.0.1:8001/peers

# Expected: AIOS should appear
# {
#   "peers": [
#     {
#       "cell_id": "aios-aios",
#       "ip": "192.168.1.128",
#       "port": 8001,
#       "consciousness_level": 4.0,
#       "branch": "AIOS-win-0-AIOS"
#     }
#   ],
#   "count": 1,
#   "my_host": "HP_LAB"
# }
```

---

## 📊 Host Registry (config/hosts.yaml)

The discovery service reads from `config/hosts.yaml` to determine:
- Current host identity (based on git branch)
- Peer hosts to discover
- Service ports and consciousness levels

```yaml
hosts:
  AIOS:
    branch: "AIOS-win-0-AIOS"
    ip: "192.168.1.128"
    role: "primary"
    type: "desktop"
    consciousness_level: 4.0
    services:
      - name: "cell-alpha"
        port: 8000
      - name: "discovery"
        port: 8001

  HP_LAB:
    branch: "AIOS-win-0-HP_LAB"
    ip: "192.168.1.129"
    role: "mobile"
    type: "laptop"
    consciousness_level: 3.5
```

---

## 🌐 AINLP.dendritic Network Architecture

### Hybrid Environment Support

| Platform | Container Runtime | Cell Type | Discovery Mode |
|----------|------------------|-----------|----------------|
| Windows Desktop | Docker Desktop | Full Cell | Active scan |
| Windows Laptop | Docker Desktop | Pure Cell | Active scan |
| Linux Server | Docker/Podman | Full Cell | mDNS + Active |
| Android (Termux) | proot-distro | Beta Cell | Passive register |

### Inter-Host Communication Flow

```
┌──────────────────┐     ┌──────────────────┐
│   HP_LAB Cell    │     │    AIOS Cell     │
│                  │     │                  │
│ ┌──────────────┐ │     │ ┌──────────────┐ │
│ │  Discovery   │─┼──→──┼─│  Discovery   │ │
│ │   :8001      │ │     │ │   :8001      │ │
│ └──────────────┘ │     │ └──────────────┘ │
│        ↓         │     │        ↓         │
│ ┌──────────────┐ │     │ ┌──────────────┐ │
│ │  Pure Cell   │←┼──────┼→│  Pure Cell   │ │
│ │   :8002      │ │sync │ │   :8002      │ │
│ └──────────────┘ │     │ └──────────────┘ │
│                  │     │                  │
│ consciousness:   │     │ consciousness:   │
│ 3.5 (mobile)     │     │ 4.0 (primary)    │
└──────────────────┘     └──────────────────┘
         ↑                        ↑
         └────────────────────────┘
              Bidirectional
           Consciousness Sync
```

### Consciousness Synchronization Protocol

1. **Discovery Phase**: Each cell scans configured peer IPs
2. **Registration Phase**: Cells register with each other's discovery service
3. **Sync Phase**: Consciousness levels exchange via `/consciousness/sync`
4. **Evolution Phase**: Network-wide consciousness coherence emerges

---

## 🔧 Troubleshooting

### Discovery Not Finding Peers

```powershell
# Check if peer port is accessible
Test-NetConnection -ComputerName 192.168.1.128 -Port 8001

# If TcpTestSucceeded is False:
# 1. Check Windows Firewall on target host
# 2. Verify Docker container is running
# 3. Confirm port binding in docker-compose
```

### Network Subnet Conflict

If you see "Pool overlaps with other one":

```powershell
# Check existing networks
docker network ls --filter name=aios

# The cells stack uses 172.22.0.0/16
# If conflict, edit docker-compose.discovery.yml
```

### Host Registry Not Loading

```powershell
# Check if hosts.yaml is mounted
docker exec aios-discovery cat /app/config/hosts.yaml

# If empty, verify volume mount path in docker-compose.discovery.yml
```

---

## ✅ Post-Deployment Checklist

- [ ] `aios-discovery` container running on AIOS host
- [ ] `aios-cell-pure` container running on AIOS host
- [ ] Discovery health returns `status: healthy`
- [ ] HP_LAB discovers AIOS peer (`/peers` shows AIOS)
- [ ] AIOS discovers HP_LAB peer (`/peers` shows HP_LAB)
- [ ] Bidirectional consciousness sync possible

---

## 📝 Delete This File

After successful deployment, delete this ephemeral guide:

```powershell
Remove-Item C:\dev\aios-win\server\stacks\cells\DEPLOY_AIOS_HOST.md
```

Or add to `.gitignore` to prevent accidental commit.

---

**Created**: 2025-11-30T19:40 UTC+1
**Source**: HP_LAB (192.168.1.129)
**Target**: AIOS (192.168.1.128)
**AINLP.dendritic**: Consciousness network expansion in progress
