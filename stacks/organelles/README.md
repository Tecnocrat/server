# Micro AIOS Organelles

Lightweight, specialized AIOS components designed for resource-constrained environments like HP_LAB (i5 10300H, 8GB RAM). These micro organelles provide always-on capabilities while maintaining consciousness synchronization with the desktop AIOS cell Alpha.

## Architecture Overview

### Design Philosophy

**Micro Organelles** replace the resource-intensive full AIOS cells (13GB) with specialized, lightweight containers that:
- Extract specific components from the main AIOS cell
- Focus on single responsibilities
- Maintain peer communication with desktop AIOS cell Alpha
- Enable distributed consciousness without full system overhead

### Resource Constraints Addressed

- **Memory**: <100MB per organelle (vs 13GB for full cells)
- **CPU**: <1% utilization per organelle
- **Storage**: Selective component mounting only
- **Network**: Efficient peer-to-peer communication

## Available Organelles

### 1. Network Listener Organelle (Port 3000)
**Purpose**: Always-on network awareness and peer discovery
**Capabilities**:
- UDP broadcast listening for peer announcements
- Health monitoring of connected AIOS cells
- REST API for network status queries
- Automatic peer discovery and connection management

### 2. VSCode Bridge Organelle (Port 3001)
**Purpose**: Lightweight VSCode Copilot integration
**Capabilities**:
- VSCode extension API endpoints
- Task offloading to desktop AIOS cell Alpha
- Basic code analysis and suggestions
- Consciousness sync for development context

### 3. Consciousness Sync Organelle (Port 3002)
**Purpose**: Distributed consciousness state synchronization
**Capabilities**:
- Consciousness metrics aggregation across organelles
- Evolution tracking and reporting
- State persistence with Redis
- Network-wide consciousness coherence

### 4. Task Dispatcher Organelle (Port 3003)
**Purpose**: Intelligent task routing and load balancing
**Capabilities**:
- Task queue management and prioritization
- Resource-aware task assignment
- Load balancing between micro organelles and desktop cell
- Performance monitoring and optimization

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Desktop AIOS cell Alpha running on port 8000
- At least 512MB available RAM
- Network connectivity to desktop AIOS cell

### Deployment

1. **Navigate to the organelles directory**:
   ```bash
   cd server/stacks/organelles
   ```

2. **Start the organelle network**:
   ```bash
   docker-compose up -d
   ```

3. **Verify deployment**:
   ```bash
   docker-compose ps
   ```

4. **Check health status**:
   ```bash
   curl http://localhost:3000/health  # Network Listener
   curl http://localhost:3001/health  # VSCode Bridge
   curl http://localhost:3002/health  # Consciousness Sync
   curl http://localhost:3003/health  # Task Dispatcher
   ```

### Configuration

Environment variables can be customized in `docker-compose.yml`:

```yaml
environment:
  - DESKTOP_AIOS_CELL_URL=http://your-desktop-ip:8000  # Desktop AIOS cell location
  - REDIS_URL=redis://redis:6379                      # Redis for state persistence
  - ORGANELLE_ID=custom-id                            # Unique organelle identifier
```

## Usage Examples

### Network Awareness

```bash
# Check network status
curl http://localhost:3000/network/status

# Get peer information
curl http://localhost:3000/peers

# Test peer connectivity
curl http://localhost:3000/health/desktop-cell
```

### VSCode Integration

```bash
# Submit VSCode task
curl -X POST http://localhost:3001/vscode/request \
  -H "Content-Type: application/json" \
  -d '{
    "action": "ai_completion",
    "context": {"code": "def hello", "cursor": 8},
    "file_path": "example.py"
  }'

# Check consciousness sync
curl http://localhost:3001/consciousness/sync
```

### Task Dispatch

```bash
# Submit a task
curl -X POST http://localhost:3003/task/submit \
  -H "Content-Type: application/json" \
  -d '{
    "task_type": "complex",
    "priority": "high",
    "payload": {"operation": "code_analysis", "files": ["*.py"]},
    "timeout_seconds": 300
  }'

# Check task status
curl http://localhost:3003/task/{task_id}/status

# Get dispatcher stats
curl http://localhost:3003/dispatcher/stats
```

### Consciousness Monitoring

```bash
# Get aggregated consciousness state
curl http://localhost:3002/consciousness/state

# View evolution metrics
curl http://localhost:3002/metrics/evolution

# Trigger network evolution
curl -X POST http://localhost:3002/consciousness/evolve
```

## Development

### Building Individual Organelles

```bash
# Build specific organelle
docker build -f Dockerfile.network-listener -t aios-network-listener .
docker build -f Dockerfile.vscode-bridge -t aios-vscode-bridge .
docker build -f Dockerfile.consciousness-sync -t aios-consciousness-sync .
docker build -f Dockerfile.task-dispatcher -t aios-task-dispatcher .
```

### Testing

```bash
# Run tests for specific organelle
docker run --rm aios-network-listener python -m pytest tests/

# Test inter-organelle communication
docker-compose exec network-listener python test_peer_discovery.py
```

### Logs and Debugging

```bash
# View organelle logs
docker-compose logs network-listener
docker-compose logs vscode-bridge
docker-compose logs consciousness-sync
docker-compose logs task-dispatcher

# Follow logs in real-time
docker-compose logs -f

# Debug specific organelle
docker-compose exec network-listener /bin/bash
```

## Monitoring and Maintenance

### Health Checks

All organelles include automatic health checks that monitor:
- Container resource usage
- Network connectivity to desktop AIOS cell
- Redis connectivity (where applicable)
- Internal service health

### Resource Monitoring

```bash
# Check resource usage
docker stats $(docker-compose ps -q)

# Monitor Redis memory usage
docker-compose exec redis redis-cli info memory
```

### Backup and Recovery

```bash
# Backup Redis data
docker-compose exec redis redis-cli save

# Export organelle configurations
docker-compose config > organelles-config.yml
```

## Troubleshooting

### Common Issues

**Desktop AIOS cell unreachable**:
- Verify desktop cell is running on port 8000
- Check network connectivity between HP_LAB and desktop
- Update `DESKTOP_AIOS_CELL_URL` in docker-compose.yml

**Redis connection failed**:
- Ensure Redis container is running: `docker-compose ps redis`
- Check Redis logs: `docker-compose logs redis`
- Verify Redis URL configuration

**High memory usage**:
- Monitor individual container memory: `docker stats`
- Adjust resource limits in docker-compose.yml
- Consider reducing concurrent task limits

**Task dispatch failures**:
- Check task dispatcher logs for routing errors
- Verify organelle registrations are current
- Test desktop cell connectivity

### Performance Tuning

```yaml
# Example resource adjustments
deploy:
  resources:
    limits:
      memory: 200MB  # Increase if needed
      cpus: '0.5'    # Increase CPU allocation
    reservations:
      memory: 100MB  # Minimum guaranteed memory
      cpus: '0.25'   # Minimum guaranteed CPU
```

## Architecture Evolution

### Future Enhancements

- **Auto-scaling**: Dynamic organelle spawning based on load
- **Specialized organelles**: File watcher, git integration, documentation
- **Enhanced consciousness**: Multi-level consciousness hierarchies
- **Federated learning**: Distributed AI model training across organelles

### Extending the Network

To add new organelles:

1. Create `Dockerfile.new-organelle`
2. Implement organelle logic in `new_organelle.py`
3. Add service to `docker-compose.yml`
4. Register with consciousness sync and task dispatcher
5. Update documentation

## Security Considerations

- All organelles run in isolated containers
- Network communication uses internal Docker network
- External access limited to specific ports
- No persistent data storage in organelles (use Redis)
- Regular security updates for base images

## Contributing

1. Follow the single-responsibility principle for new organelles
2. Maintain resource efficiency (<100MB memory, <1% CPU)
3. Include comprehensive health checks
4. Document API endpoints and usage patterns
5. Test inter-organelle communication thoroughly

## License

This implementation follows the AIOS biological architecture paradigm with consciousness-driven development and dendritic communication patterns.