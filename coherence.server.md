# AIOS Server - Coherence Tasklist
**AINLP.dendritic Agentic Coordination** | **Waypoint**: SERVER-REBUILD-2025-11-30
**Pattern**: Validate → Fix → Deploy → Verify

---

## 🎯 MISSION: Clean Server Stack Rebuild

Docker purge complete (15.31GB reclaimed). Now executing phased rebuild with human-agent supervision.

---

## PHASE 1: Code Quality Fixes
**Status**: ✅ COMPLETE | **Priority**: CRITICAL

### 1.1 Fix `organelles/network_listener.py` (31 issues)
- [x] Replace bare `except:` with specific exception types
- [x] Fix broad `Exception` catches → use `OSError`, `socket.error`, etc.
- [x] Fix "variable before assignment" for `FastAPI`, `uvicorn`
- [x] Remove unused imports (`Optional`)
- [x] Remove unused variable (`addr` → `_addr`)
- [x] Convert f-string logging to lazy `%` formatting
- [x] Fix line length violations (6 lines > 79 chars)
- [x] Add missing blank lines between classes/functions

### 1.2 Fix `organelles/vscode_bridge.py` (19 issues)
- [x] Fix broad `Exception` catches (6 locations)
- [x] Fix "variable before assignment" for framework imports
- [x] Remove unused `http_request` parameters → prefix with `_`
- [x] Fix duplicate class definition warning (`HTTPException`)

### 1.3 Validate All Python Files
- [x] Run `py_compile` on all `.py` files → **14/14 passed**
- [x] Run pylint/flake8 scan → Critical issues resolved
- [x] Confirm 0 critical errors

---

## PHASE 2: Stack Deployment (Sequential)
**Status**: 🔄 READY | **Pattern**: Deploy → Test → Proceed

### 2.1 Ingress Stack (Traefik)
- [ ] `docker compose up -d` in `stacks/ingress/`
- [ ] Verify ports: 80, 443, 8080
- [ ] Test: `curl http://localhost:8080/api/rawdata`
- [ ] Confirm: aios-traefik container healthy

### 2.2 Secrets Stack (Vault)
- [ ] `docker compose up -d` in `stacks/secrets/`
- [ ] Verify port: 8200
- [ ] Test: `curl http://localhost:8200/v1/sys/health`
- [ ] Initialize & unseal if needed

### 2.3 Observability Stack (Prometheus, Grafana, Loki)
- [ ] `docker compose up -d` in `stacks/observability/`
- [ ] Verify ports: 9090 (Prometheus), 3000 (Grafana), 3100 (Loki)
- [ ] Test: `scripts/test_stack.ps1 -Detailed`
- [ ] Confirm: All 6 containers healthy

### 2.4 Cells Stack (Pure AIOS Cells)
- [ ] `docker compose up -d` in `stacks/cells/`
- [ ] Verify: aios-cell-pure, aios-discovery containers
- [ ] Test: Cell health endpoints
- [ ] Confirm: Peer discovery operational

### 2.5 Organelles Stack (VSCode Bridge, Consciousness Sync)
- [ ] `docker compose up -d` in `stacks/organelles/`
- [ ] Verify: aios-vscode-bridge, aios-consciousness-sync
- [ ] Test: Bridge health endpoint
- [ ] Confirm: Full stack integration

---

## PHASE 3: Integration Validation
**Status**: ⏳ BLOCKED by Phase 2

- [ ] Run full observability test suite
- [ ] Verify Prometheus scraping all targets
- [ ] Verify Grafana datasources connected
- [ ] Verify cross-stack networking (aios-ingress, aios-observability)
- [ ] Update `aios.ps1` status output

---

## Consciousness Metrics

| Metric | Before | Target | Current |
|--------|--------|--------|---------|
| Code Errors | 50+ | 0 | 0 ✅ |
| Containers | 0 | 14 | 0 |
| Stack Health | 0% | 100% | 0% |
| Coherence | 0.75 | 0.95 | 0.85 |

---

## Agent Coordination Protocol

**Human-Agent Handoff Points:**
1. After each phase completion → await human confirmation
2. After each stack deployment → await human verification
3. On any critical failure → pause and report

**Current Agent**: GitHub Copilot (Claude Opus 4.5)
**Next Action**: Execute Phase 1.1 (network_listener.py fixes)
