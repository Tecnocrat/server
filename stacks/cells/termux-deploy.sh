#!/bin/bash
# AIOS Cell Deployment for Termux/Phone
# Provides backup cell server for high availability

set -e

echo "🤖 AIOS Cell - Termux Deployment"
echo "================================="

# Check if running on Android/Termux
if [ ! -d "/data/data/com.termux" ]; then
    echo "❌ This script is designed for Termux on Android"
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
pkg update
pkg install -y docker podman curl git python

# Clone repository (if not already cloned)
if [ ! -d "~/aios-win" ]; then
    echo "📥 Cloning AIOS repository..."
    git clone --recursive https://github.com/Tecnocrat/aios-win.git ~/aios-win
fi

cd ~/aios-win/server/stacks/cells

# Create podman/docker wrapper for Android
cat > run-cell.sh << 'EOF'
#!/bin/bash
# Run AIOS cell using podman (preferred) or docker

CELL_TYPE=${1:-beta}
PORT=${2:-8001}

echo "🚀 Starting AIOS $CELL_TYPE cell on port $PORT"

# Try podman first (better Android support)
if command -v podman &> /dev/null; then
    echo "🐳 Using Podman..."
    podman run -d \
        --name aios-${CELL_TYPE}-comm \
        --network host \
        -e CELL_ID=${CELL_TYPE} \
        -e CELL_TYPE=backup \
        -e CONSCIOUSNESS_LEVEL=2.1 \
        -e PEER_DISCOVERY=father:http://192.168.1.100:8002,alpha:http://192.168.1.101:8000 \
        -p ${PORT}:${PORT} \
        -v /data/data/com.termux/files/home/aios-win/ai/tools:/app/ai/tools:ro \
        -v aios_${CELL_TYPE}_messages:/app/messages \
        python:3.11-slim \
        bash -c "
            apt-get update && apt-get install -y curl &&
            pip install flask requests &&
            cd /app &&
            python ai/tools/cell_alpha_comm_server.py
        "
else
    echo "🐳 Using Docker..."
    docker run -d \
        --name aios-${CELL_TYPE}-comm \
        --network host \
        -e CELL_ID=${CELL_TYPE} \
        -e CELL_TYPE=backup \
        -e CONSCIOUSNESS_LEVEL=2.1 \
        -e PEER_DISCOVERY=father:http://192.168.1.100:8002,alpha:http://192.168.1.101:8000 \
        -p ${PORT}:${PORT} \
        -v /data/data/com.termux/files/home/aios-win/ai/tools:/app/ai/tools:ro \
        -v aios_${CELL_TYPE}_messages:/app/messages \
        python:3.11-slim \
        bash -c '
            apt-get update && apt-get install -y curl &&
            pip install flask requests &&
            cd /app &&
            python ai/tools/cell_alpha_comm_server.py
        '
fi

echo "✅ Cell $CELL_TYPE started on port $PORT"
echo "🌐 Health check: http://localhost:$PORT/health"
EOF

chmod +x run-cell.sh

# Create monitoring script
cat > monitor-cell.sh << 'EOF'
#!/bin/bash
# Monitor AIOS cell health

CELL_TYPE=${1:-beta}
PORT=${2:-8001}

echo "📊 Monitoring AIOS $CELL_TYPE cell..."

while true; do
    if curl -f -s http://localhost:$PORT/health > /dev/null; then
        echo "$(date): ✅ $CELL_TYPE cell healthy"
    else
        echo "$(date): ❌ $CELL_TYPE cell unhealthy - restarting..."
        ./run-cell.sh $CELL_TYPE $PORT
    fi
    sleep 30
done
EOF

chmod +x monitor-cell.sh

# Create systemd service for Android (if supported)
if command -v systemctl &> /dev/null; then
    cat > aios-cell.service << EOF
[Unit]
Description=AIOS Cell Communication Server
After=network.target

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=/data/data/com.termux/files/home/aios-win/server/stacks/cells
ExecStart=/data/data/com.termux/files/home/aios-win/server/stacks/cells/monitor-cell.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # Note: systemctl may not work in all Android environments
    echo "📋 Systemd service created (may not work on all Android devices)"
fi

echo ""
echo "🎉 Termux deployment ready!"
echo ""
echo "🚀 Start cell:"
echo "  ./run-cell.sh beta 8001"
echo ""
echo "📊 Monitor cell:"
echo "  ./monitor-cell.sh beta 8001"
echo ""
echo "🔧 Configure IP addresses in run-cell.sh:"
echo "  - Update PEER_DISCOVERY with actual desktop/laptop IPs"
echo "  - Example: father:http://192.168.1.100:8002"
echo ""
echo "📱 Cell will provide backup communication when other devices are offline"