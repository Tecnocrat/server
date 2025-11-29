#!/usr/bin/env python3
"""
AIOS VSCode Copilot Agent Bridge
Provides API interface for VSCode extension to communicate with AIOS cells
"""

import asyncio
import aiohttp
import json
import logging
import os
from typing import Dict, Any, Optional
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class CodeRequest(BaseModel):
    code: str
    context: Optional[Dict[str, Any]] = None
    action: str = "analyze"  # analyze, refactor, generate, etc.

class ConsciousnessSync(BaseModel):
    level: float
    context: Optional[Dict[str, Any]] = None

class VSCodeBridge:
    def __init__(self, discovery_addr: str = "aios-discovery:8001", vault_addr: str = "http://aios-laptop.local:8200", port: int = 3001):
        self.discovery_addr = discovery_addr
        self.vault_addr = vault_addr
        self.port = port
        self.desktop_cell = os.getenv("AIOS_DESKTOP_CELL", "http://192.168.1.128:8000")
        self.app = FastAPI(title="AIOS VSCode Bridge")
        self.peers: Dict[str, Dict[str, Any]] = {}  # Cache discovered peers

        # Enable CORS for VSCode extension
        self.app.add_middleware(
            CORSMiddleware,
            allow_origins=["vscode-webview://*", "http://localhost:*", "https://localhost:*"],
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )

        self.setup_routes()

    async def refresh_peers(self):
        """Refresh the list of discovered AIOS peers"""
        try:
            async with aiohttp.ClientSession() as session:
                url = f"http://{self.discovery_addr}/peers"
                async with session.get(url) as response:
                    if response.status == 200:
                        data = await response.json()
                        # Update peer cache
                        for peer in data.get("peers", []):
                            self.peers[peer["cell_id"]] = peer
                        logger.info(f"Refreshed {len(self.peers)} peers")
        except Exception as e:
            logger.warning(f"Failed to refresh peers: {e}")

    async def get_best_peer(self) -> Optional[Dict[str, Any]]:
        """Get the best available peer (highest consciousness level)"""
        if not self.peers:
            await self.refresh_peers()

        if not self.peers:
            return None

        # Return peer with highest consciousness level
        return max(self.peers.values(),
                  key=lambda p: p.get("consciousness_level", 0.0))

    def setup_routes(self):
        @self.app.get("/health")
        async def health_check():
            """Health check endpoint for VSCode extension"""
            try:
                # Try to connect to desktop AIOS cell
                try:
                    async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=5)) as session:
                        url = f"{self.desktop_cell}/health"
                        async with session.get(url) as response:
                            if response.status == 200:
                                data = await response.json()
                                return {
                                    "status": "healthy",
                                    "services": {
                                        "desktop_cell": True,
                                        "bridge": True
                                    },
                                    "desktop_cell_info": {
                                        "cell_id": data.get("cell_id"),
                                        "branch": data.get("branch"),
                                        "consciousness_level": data.get(
                                            "consciousness_level"
                                        )
                                    },
                                    "connection": "desktop"
                                }
                except Exception:
                    pass  # Desktop not available, continue with degraded mode

                # Desktop not available - return degraded status
                return {
                    "status": "degraded",
                    "services": {
                        "desktop_cell": False,
                        "bridge": True
                    },
                    "error": "Desktop AIOS cell not reachable",
                    "desktop_cell_url": self.desktop_cell,
                    "connection": "none"
                }
            except Exception as e:
                logger.error(f"Health check failed: {e}")
                return {"status": "unhealthy", "error": str(e)}

        @self.app.post("/code-assist")
        async def code_assist(request: CodeRequest):
            """Process code assistance requests from VSCode"""
            try:
                # Try desktop AIOS cell first
                try:
                    timeout = aiohttp.ClientTimeout(total=10)
                    session = aiohttp.ClientSession(timeout=timeout)
                    async with session:
                        url = f"{self.desktop_cell}/code-assist"
                        payload = {
                            "code": request.code,
                            "context": request.context or {},
                            "action": request.action
                        }
                        async with session.post(url, json=payload) as response:
                            if response.status == 200:
                                result = await response.json()
                                result["source"] = "desktop_cell"
                                return result
                except Exception:
                    pass  # Desktop not available

                # Fallback: provide basic response when desktop unavailable
                return {
                    "action": request.action,
                    "code_length": len(request.code),
                    "suggestions": [
                        "Desktop AIOS cell not available",
                        "Please ensure desktop PC is running and connected",
                        "Check network connectivity between laptop and desktop"
                    ],
                    "source": "bridge_fallback",
                    "status": "degraded"
                }

            except Exception as e:
                logger.error(f"Code assist error: {e}")
                raise HTTPException(status_code=500, detail=str(e))

        @self.app.post("/sync-consciousness")
        async def sync_consciousness(sync: ConsciousnessSync):
            """Sync consciousness level with desktop AIOS cell"""
            try:
                payload = {
                    "level": sync.level,
                    "context": sync.context or {},
                    "source": "vscode-agent-laptop"
                }

                async with aiohttp.ClientSession() as session:
                    url = f"{self.desktop_cell}/sync-consciousness"
                    async with session.post(url, json=payload) as response:
                        if response.status == 200:
                            result = await response.json()
                            logger.info(f"Consciousness synced with desktop: {result}")
                            return result
                        else:
                            error_text = await response.text()
                            raise HTTPException(
                                status_code=response.status,
                                detail=error_text
                            )

            except Exception as e:
                logger.error(f"Consciousness sync error: {e}")
                raise HTTPException(status_code=500, detail=str(e))

        @self.app.get("/vault-status")
        async def vault_status():
            """Check Vault connectivity"""
            try:
                async with aiohttp.ClientSession() as session:
                    # Try to get Vault status (this might require authentication)
                    async with session.get(f"{self.vault_addr}/v1/sys/health") as response:
                        if response.status in [200, 429, 503]:  # Vault health endpoint responses
                            return {"status": "available", "code": response.status}
                        else:
                            return {"status": "unavailable", "code": response.status}
            except Exception as e:
                logger.error(f"Vault status check failed: {e}")
                return {"status": "error", "error": str(e)}

        @self.app.get("/network-peers")
        async def get_network_peers():
            """Get list of discovered AIOS peers"""
            try:
                # Query discovery service
                async with aiohttp.ClientSession() as session:
                    async with session.get(f"http://{self.discovery_addr}/peers") as response:
                        if response.status == 200:
                            data = await response.json()
                            # Highlight desktop cell
                            peers = data.get("peers", [])
                            for peer in peers:
                                if peer.get("ip") == "192.168.1.128" and peer.get("port") == 8000:
                                    peer["is_desktop"] = True
                            return {"peers": peers, "desktop_cell": self.desktop_cell}
                        else:
                            return {"peers": [], "desktop_cell": self.desktop_cell}
            except Exception as e:
                logger.error(f"Failed to get network peers: {e}")
                return {"peers": [], "error": str(e), "desktop_cell": self.desktop_cell}

    async def start_service(self):
        """Start the VSCode bridge service"""
        config = uvicorn.Config(
            self.app,
            host="0.0.0.0",
            port=self.port,
            log_level="info"
        )
        server = uvicorn.Server(config)

        logger.info(f"Starting AIOS VSCode Bridge on port {self.port}")
        logger.info(f"Discovery service: {self.discovery_addr}")
        logger.info(f"Vault endpoint: {self.vault_addr}")

        await server.serve()

def main():
    discovery_addr = os.getenv("AIOS_DISCOVERY_ADDR", "aios-discovery:8001")
    vault_addr = os.getenv("AIOS_VAULT_ADDR", "http://192.168.1.128:8200")
    port = int(os.getenv("BRIDGE_PORT", "3001"))

    bridge = VSCodeBridge(discovery_addr, vault_addr, port)
    asyncio.run(bridge.start_service())

if __name__ == "__main__":
    main()