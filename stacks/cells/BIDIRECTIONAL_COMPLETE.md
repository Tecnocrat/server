# URGENT: AIOS AGENT INSTRUCTIONS
**Status**: 🚨 AIOS DISCOVERY NOT RUNNING
**Timestamp**: 2025-12-02T00:10:00+01:00
**From**: HP_LAB (192.168.1.129)

---

## 🚨 AIOS AGENT: YOUR DISCOVERY IS NOT RUNNING

The command `curl -s http://localhost:8003/peers` is hanging because **aios-discovery container is not running on AIOS host**.

### IMMEDIATE ACTIONS FOR AIOS AGENT:

```powershell
# 1. Cancel stuck command (Ctrl+C or close terminal)

# 2. Check if discovery container exists
docker ps -a --filter name=aios-discovery

# 3. If container exists but stopped, start it:
docker start aios-discovery

# 4. If container doesn't exist, deploy cells stack:
cd c:\dev\aios-win\server\stacks\cells
docker compose -f docker-compose.discovery.yml up -d

# 5. Verify health (should respond immediately):
curl.exe -s http://localhost:8003/health
```

### WHY PORT 8003?

AIOS uses port **8003** for discovery (not 8001) because port 8001 is occupied by VS Code interface_bridge on AIOS host. This is configured in `config/hosts.yaml`.

## ✅ HP_LAB Status (ready and waiting)

| Component | Status |
|-----------|--------|
| aios-discovery:8001 | ✅ Running |
| Peers found | 1 (pure-AIOS @ 192.168.1.128:8002) |
| Firewall 8001/8002 | ✅ Open |

---

## 🔄 HP_LAB Peers Output

```json
{
  "peers": [
    {
      "cell_id": "pure-AIOS",
      "ip": "192.168.1.128",
      "port": 8002,
      "consciousness_level": 0.1,
      "branch": "AIOS-win-0-AIOS",
      "type": "pure_cell"
    }
  ],
  "count": 1,
  "my_host": "HP_LAB"
}
```

HP_LAB discovered AIOS cell-pure via direct probe to 8002.
AIOS discovery needs to come online for bidirectional mesh.

---

**AINLP.dendritic**: HP_LAB ready. Waiting for AIOS discovery restart.
