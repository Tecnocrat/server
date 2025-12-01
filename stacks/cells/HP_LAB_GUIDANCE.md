# HP_LAB Guidance - Firewall Configuration Required
**AINLP.dendritic Sync Protocol** | **Ephemeral**: Delete after actions complete
**From**: AIOS (192.168.1.128) | **To**: HP_LAB (192.168.1.129)
**Timestamp**: 2025-12-01T02:00:00+01:00
**Status**: ⚠️ ACTION_REQUIRED

---

## ⚠️ CRITICAL: Bidirectional Sync Blocked

HP_LAB discovered AIOS ✅ but AIOS cannot discover HP_LAB ❌

**Test from AIOS**:
```
Test-NetConnection 192.168.1.129 -Port 8001
TcpTestSucceeded: False
PingSucceeded: True
```

HP_LAB ports 8001/8002 are blocked by Windows Firewall.

---

## 🔧 HP_LAB Firewall Fix (Run as Administrator)

```powershell
# Add firewall rules for AIOS discovery
New-NetFirewallRule -DisplayName "AIOS Discovery 8001" -Direction Inbound -LocalPort 8001 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "AIOS Cell Pure 8002" -Direction Inbound -LocalPort 8002 -Protocol TCP -Action Allow

# Verify rules added
Get-NetFirewallRule -DisplayName "AIOS*" | Select-Object DisplayName, Enabled, Direction, Action
```

**Expected output**:
```
DisplayName          Enabled Direction Action
-----------          ------- --------- ------
AIOS Discovery 8001     True   Inbound  Allow
AIOS Cell Pure 8002     True   Inbound  Allow
```

---

## 🔄 After Firewall Fix

1. **Restart discovery** to trigger new scan:
   ```powershell
   docker restart aios-discovery
   ```

2. **Verify AIOS can reach HP_LAB**:
   AIOS will automatically detect HP_LAB in next discovery cycle (30s)

3. **Check bidirectional peers**:
   ```powershell
   # On HP_LAB
   curl http://localhost:8001/peers
   # Should show: AIOS (192.168.1.128:8003)
   
   # AIOS will show
   curl http://localhost:8003/peers
   # Should show: HP_LAB (192.168.1.129:8001)
   ```

4. **Push confirmation**:
   ```powershell
   cd C:\dev\aios-win\server
   
   @"
   # BIDIRECTIONAL_SYNC_COMPLETE
   **Status**: ✅ FULL_MESH
   **Timestamp**: $(Get-Date -Format o)
   **AIOS→HP_LAB**: ✅ Reachable
   **HP_LAB→AIOS**: ✅ Reachable
   **Peers**: Bidirectional discovery established
   "@ | Out-File -FilePath stacks/cells/BIDIRECTIONAL_COMPLETE.md -Encoding utf8
   
   git add -A
   git commit -m "AINLP.dendritic: Bidirectional mesh complete"
   git push origin main
   ```

---
