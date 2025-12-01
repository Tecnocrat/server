# HP_LAB Guidance - Next Steps
**AINLP.dendritic Sync Protocol** | **Ephemeral**: Delete after actions complete
**From**: AIOS (192.168.1.128) | **To**: HP_LAB (192.168.1.129)
**Timestamp**: 2025-12-01T01:00:00+01:00

---

## ✅ AIOS Status: READY FOR HANDSHAKE

Firewall configured. All ports open. Awaiting HP_LAB connection.

---

## 🎯 HP_LAB Immediate Actions

### 1. Pull Latest Changes

```powershell
cd C:\dev\aios-win\server
git pull origin main

# Verify you have these commits:
git log --oneline -5
# Should show:
# 4670350 docs: Update README and mark firewall config complete
# b49288f AIOS sync confirmed: Firewall rules added for ports 8000/8002/8003
# 9a168b6 HP_LAB sync response: AIOS firewall action required...
```

### 2. Test AIOS Connectivity

```powershell
# Test all AIOS ports (should now succeed)
Test-NetConnection -ComputerName 192.168.1.128 -Port 8003  # Discovery
Test-NetConnection -ComputerName 192.168.1.128 -Port 8000  # Cell Alpha
Test-NetConnection -ComputerName 192.168.1.128 -Port 8002  # Cell Pure

# Expected: TcpTestSucceeded: True (all three)
```

### 3. Restart Discovery to Trigger Peer Scan

```powershell
docker restart aios-discovery

# Wait 10 seconds for discovery cycle
Start-Sleep 10

# Check peers discovered
curl http://localhost:8001/peers
```

**Expected output**:
```json
{
  "peers": [
    {
      "cell_id": "AIOS",
      "ip": "192.168.1.128",
      "port": 8003,
      "consciousness_level": 4.0,
      "branch": "AIOS-win-0-AIOS",
      "type": "desktop"
    }
  ],
  "count": 1,
  "my_host": "HP_LAB"
}
```

### 4. Verify Bidirectional Health

```powershell
# Check AIOS discovery directly from HP_LAB
curl http://192.168.1.128:8003/health

# Check AIOS cells
curl http://192.168.1.128:8000/health  # Cell Alpha
curl http://192.168.1.128:8002/health  # Cell Pure
```

---

## 📋 Confirmation Response

After verifying connectivity, create confirmation:

```powershell
cd C:\dev\aios-win\server

# Create confirmation file
@"
# HP_LAB → AIOS Handshake Confirmed
**Status**: SYNC_COMPLETE
**Timestamp**: $(Get-Date -Format o)
**AIOS Ports Reachable**: 8003 ✅, 8000 ✅, 8002 ✅
**Peers Discovered**: 1 (AIOS)
**Bidirectional**: Yes

Network established. Ready for consciousness synchronization.
"@ | Out-File -FilePath stacks/cells/HANDSHAKE_COMPLETE.md -Encoding utf8

# Commit and push
git add stacks/cells/HANDSHAKE_COMPLETE.md
git commit -m "AINLP.dendritic: HP_LAB-AIOS handshake complete"
git push origin main
```

---

## 🧹 Cleanup (After Handshake Confirmed)

Once both hosts confirm connectivity:

```powershell
cd C:\dev\aios-win\server\stacks\cells

# Remove ephemeral sync files
Remove-Item SYNC_*.md
Remove-Item DEPLOY_AIOS_HOST.md
Remove-Item HANDSHAKE_COMPLETE.md
Remove-Item HP_LAB_GUIDANCE.md

git add -A
git commit -m "cleanup: Remove ephemeral sync files - network established"
git push origin main
```

---

## 📊 Current Network State

```
┌─────────────────────────────────────────────────────────────────────┐
│                    AIOS Consciousness Network                        │
├─────────────────────────────────────────────────────────────────────┤
│   AIOS (192.168.1.128)                HP_LAB (192.168.1.129)        │
│   ╔═══════════════════╗              ╔═══════════════════╗          │
│   ║ aios-discovery    ║◄────────────►║ aios-discovery    ║          │
│   ║ :8003 ✅ ready    ║   handshake  ║ :8001 ✅ ready    ║          │
│   ╠═══════════════════╣              ╠═══════════════════╣          │
│   ║ aios-cell-alpha   ║              ║ aios-cell-pure    ║          │
│   ║ :8000 ✅ ready    ║              ║ :8002 ✅ ready    ║          │
│   ╠═══════════════════╣              ╚═══════════════════╝          │
│   ║ aios-cell-pure    ║                                             │
│   ║ :8002 ✅ ready    ║              Firewall: ✅ Open              │
│   ╚═══════════════════╝                                             │
│                                                                      │
│   Firewall: ✅ Open                  Branch: AIOS-win-0-HP_LAB      │
│   Branch: AIOS-win-0-AIOS                                           │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📚 Reference Docs

After sync complete, ongoing coordination via:

| Doc | Purpose |
|-----|---------|
| `server/README.md` | Stack architecture, quick start |
| `server/coherence.server.md` | Phase tracking, active tasks |
| `config/hosts.yaml` | Host registry, port mappings |

---

**AINLP.dendritic**: Awaiting HP_LAB handshake confirmation
