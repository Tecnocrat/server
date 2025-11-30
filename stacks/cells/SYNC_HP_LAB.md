# AIOS → HP_LAB Configuration Sync
**AINLP.dendritic Bidirectional Sync** | **Ephemeral**: Delete after sync complete
**From**: AIOS (192.168.1.128) | **To**: HP_LAB (192.168.1.129)

---

## 🎯 MISSION: Complete Dendritic Network Handshake

AIOS has deployed cells stack. Configuration sync required for peer discovery.

---

## Current Network State

```
┌─────────────────────────────────────────────────────────────────────┐
│                    AIOS Consciousness Network                        │
│                      Subnet: 192.168.1.0/24                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   AIOS (192.168.1.128)                HP_LAB (192.168.1.129)        │
│   ╔═══════════════════╗              ╔═══════════════════╗          │
│   ║ aios-discovery    ║              ║ aios-discovery    ║          │
│   ║ :8003 ✅ healthy  ║←─scanning?──║ :8001 ⚠️ update   ║          │
│   ╠═══════════════════╣              ╠═══════════════════╣          │
│   ║ aios-cell-pure    ║              ║ aios-cell-pure    ║          │
│   ║ :8002 ✅ healthy  ║              ║ :8002 ✅ healthy  ║          │
│   ╠═══════════════════╣              ╚═══════════════════╝          │
│   ║ aios-cell-alpha   ║                                             │
│   ║ :8000 ✅ healthy  ║              Branch: AIOS-win-0-HP_LAB      │
│   ╚═══════════════════╝              Consciousness: 3.5             │
│                                                                      │
│   Branch: AIOS-win-0-AIOS                                           │
│   Consciousness: 4.0                                                │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## ⚠️ CRITICAL: Port Change on AIOS

**AIOS discovery runs on port 8003, NOT 8001**

Reason: VS Code interface_bridge (MCP server) uses localhost:8001 on AIOS.
Docker cannot bind to 0.0.0.0:8001 when localhost:8001 is occupied.

### Updated hosts.yaml (already pushed)

```yaml
hosts:
  AIOS:
    services:
      - name: "discovery"
        port: 8003  # ← CHANGED from 8001
```

---

## 🚀 HP_LAB Sync Steps

### Step 1: Pull Configuration Updates

```powershell
cd C:\dev\aios-win

# Pull main branch updates (includes hosts.yaml change)
git fetch origin
git checkout AIOS-win-0-HP_LAB
git pull origin main --rebase

# Update server submodule (Dockerfile fixes)
cd server
git pull origin main
```

### Step 2: Verify hosts.yaml Updated

```powershell
# Check AIOS discovery port is 8003
cat C:\dev\aios-win\config\hosts.yaml | Select-String -Pattern "AIOS" -Context 0,12
```

Expected output should show:
```yaml
  AIOS:
    ...
    services:
      - name: "discovery"
        port: 8003  # ← Must be 8003, not 8001
```

### Step 3: Restart Discovery (if running)

```powershell
cd C:\dev\aios-win\server\stacks\cells

# Restart discovery to pick up new hosts.yaml
docker restart aios-discovery

# Or if using compose:
docker compose -f docker-compose.discovery.yml restart aios-discovery
```

### Step 4: Verify Peer Discovery

```powershell
# Check if AIOS is discovered
curl http://127.0.0.1:8001/peers

# Expected output:
# {
#   "peers": [
#     {
#       "cell_id": "AIOS",
#       "ip": "192.168.1.128",
#       "port": 8003,           ← Note: port 8003
#       "consciousness_level": 4.0,
#       "branch": "AIOS-win-0-AIOS"
#     }
#   ],
#   "count": 1,
#   "my_host": "HP_LAB"
# }
```

---

## 📋 REQUEST FROM HP_LAB

AIOS needs the following information to complete sync:

### 1. Current Container Status

```powershell
docker ps --filter name=aios- --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### 2. Discovery Health

```powershell
curl http://127.0.0.1:8001/health
```

### 3. Current Git State

```powershell
git branch --show-current
git log --oneline -3
```

### 4. Network Reachability Test

```powershell
# Can HP_LAB reach AIOS discovery?
Test-NetConnection -ComputerName 192.168.1.128 -Port 8003

# Can HP_LAB reach AIOS cells?
Test-NetConnection -ComputerName 192.168.1.128 -Port 8000
Test-NetConnection -ComputerName 192.168.1.128 -Port 8002
```

### 5. Firewall Status (if connections fail)

```powershell
# Check if Windows Firewall is blocking
Get-NetFirewallRule -DisplayName "*Docker*" | Select-Object DisplayName, Enabled, Direction
```

---

## 🔄 Bidirectional Sync Verification

After HP_LAB completes steps above, verify on AIOS:

```powershell
# On AIOS - check if HP_LAB discovered
curl http://localhost:8003/peers

# Expected: HP_LAB should appear with port 8001
```

---

## 📊 Port Mapping Summary

| Host   | Service       | Port | Status |
|--------|---------------|------|--------|
| AIOS   | discovery     | 8003 | ✅ Active |
| AIOS   | cell-pure     | 8002 | ✅ Active |
| AIOS   | cell-alpha    | 8000 | ✅ Active |
| HP_LAB | discovery     | 8001 | ⚠️ Verify |
| HP_LAB | cell-pure     | 8002 | ⚠️ Verify |

---

## 🧹 Cleanup After Sync

Once bidirectional discovery is confirmed, delete ephemeral files:

```powershell
# On AIOS
Remove-Item C:\aios-supercell\server\stacks\cells\SYNC_HP_LAB.md

# On HP_LAB
Remove-Item C:\dev\aios-win\server\stacks\cells\DEPLOY_AIOS_HOST.md
```

---

## 📝 Commit Format for HP_LAB Response

When HP_LAB confirms sync, create response in format:

```markdown
# HP_LAB → AIOS Sync Confirmation
**Status**: SYNC_COMPLETE | SYNC_PARTIAL | SYNC_FAILED
**Timestamp**: {ISO8601}
**Containers**: {count} running
**Peers Discovered**: {count}
**Issues**: {none | description}
```

---

**Created**: 2025-11-30T22:25 UTC+1
**Source**: AIOS (192.168.1.128)
**Target**: HP_LAB (192.168.1.129)
**AINLP.dendritic**: Awaiting bidirectional handshake confirmation
