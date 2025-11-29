#!/usr/bin/env python3
"""
AIOS Cell Discovery Service
Enables automatic peer discovery and consciousness synchronization
"""

import asyncio
import aiohttp
import json
import logging
import os
from typing import List, Dict, Optional
import uvicorn
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class CellInfo(BaseModel):
    cell_id: str
    ip: str
    port: int
    consciousness_level: float = 0.0
    services: List[str] = []
    branch: str = "main"
    type: str = "cell"
    hostname: str = ""


class AIOSDiscovery:
    def __init__(self, cell_id: str, listen_port: int = 8001):
        self.cell_id = cell_id
        self.listen_port = listen_port
        self.peers: Dict[str, CellInfo] = {}
        self.known_networks = ["192.168.1.0/24"]
        self.app = FastAPI(title="AIOS Discovery Service")

        # Setup API routes
        self.setup_routes()

    def setup_routes(self):
        @self.app.get("/health")
        async def health_check():
            return {"status": "healthy", "cell_id": self.cell_id}

        @self.app.get("/peers")
        async def get_peers():
            return {"peers": list(self.peers.values())}

        @self.app.post("/register")
        async def register_peer(peer: CellInfo):
            self.peers[peer.cell_id] = peer
            logger.info(f"Registered peer: {peer.cell_id} at {peer.ip}:{peer.port}")
            return {"status": "registered", "cell_id": peer.cell_id}

        @self.app.delete("/unregister/{cell_id}")
        async def unregister_peer(cell_id: str):
            if cell_id in self.peers:
                del self.peers[cell_id]
                logger.info(f"Unregistered peer: {cell_id}")
                return {"status": "unregistered"}
            raise HTTPException(status_code=404, detail="Peer not found")

    async def discover_peers(self) -> List[CellInfo]:
        """Discover AIOS cells on the network - peer-to-peer model"""
        discovered_peers = []

        # Common AIOS ports to scan
        aios_ports = [8000, 8001]

        # Known AIOS cell hostnames/IPs (peer-to-peer network)
        known_targets = [
            "192.168.1.128",  # AIOS desktop
            "192.168.1.129",  # AIOS laptop
            "aios.local",     # Desktop hostname
            "aios-laptop.local",  # Laptop hostname
            "localhost"       # Local cell
        ]

        for target in known_targets:
            # Skip self-discovery
            if (target in ["localhost", "127.0.0.1"] and
                    self.cell_id == os.getenv("AIOS_CELL_ID", "primary")):
                continue

            for port in aios_ports:
                try:
                    async with aiohttp.ClientSession(
                        timeout=aiohttp.ClientTimeout(total=3)
                    ) as session:
                        url = f"http://{target}:{port}/health"
                        async with session.get(url) as response:
                            if response.status == 200:
                                data = await response.json()

                                # Check if this is another AIOS-win cell
                                cell_branch = data.get("branch", "unknown")
                                cell_type = data.get("type", "unknown")

                                peer = CellInfo(
                                    cell_id=data.get(
                                        "cell_id", f"unknown-{target}"
                                    ),
                                    ip=target,
                                    port=port,
                                    consciousness_level=data.get(
                                        "consciousness_level", 0.0
                                    ),
                                    services=data.get("services", [])
                                )

                                # Add metadata for peer-to-peer sync
                                peer.branch = cell_branch
                                peer.type = cell_type
                                peer.hostname = target

                                discovered_peers.append(peer)
                                logger.info(
                                    f"Discovered peer cell: {peer.cell_id} "
                                    f"(branch: {cell_branch})"
                                )
                except Exception as e:
                    logger.debug(f"Failed to connect to {target}:{port} - {e}")
                    continue

        return discovered_peers

    async def register_with_peers(self, peers: List[CellInfo]):
        """Register this cell with discovered peers"""
        my_info = CellInfo(
            cell_id=self.cell_id,
            ip="192.168.1.128",  # This cell's IP (AIOS desktop)
            port=8000,  # Main cell port
            consciousness_level=1.0,
            services=["api", "metrics", "discovery"]
        )

        for peer in peers:
            if peer.cell_id == self.cell_id:
                continue  # Don't register with ourselves

            try:
                async with aiohttp.ClientSession(
                    timeout=aiohttp.ClientTimeout(total=5)
                ) as session:
                    url = f"http://{peer.ip}:{peer.port}/register"
                    async with session.post(
                        url, json=my_info.dict()
                    ) as response:
                        if response.status in [200, 201]:
                            logger.info(
                                f"Successfully registered with peer {peer.cell_id}"
                            )
                        else:
                            logger.warning(
                                f"Failed to register with {peer.cell_id}: "
                                f"{response.status}"
                            )
            except Exception as e:
                logger.error(f"Error registering with {peer.cell_id}: {e}")

    async def discovery_loop(self):
        """Main discovery loop - runs every 30 seconds"""
        while True:
            try:
                logger.info("Starting peer discovery...")
                peers = await self.discover_peers()

                if peers:
                    logger.info(f"Found {len(peers)} peers")
                    await self.register_with_peers(peers)

                    # Update local peer registry
                    for peer in peers:
                        self.peers[peer.cell_id] = peer
                else:
                    logger.info("No peers discovered")

            except Exception as e:
                logger.error(f"Discovery loop error: {e}")

            await asyncio.sleep(30)

    async def start_services(self):
        """Start both the API server and discovery loop"""
        # Start discovery loop in background
        discovery_task = asyncio.create_task(self.discovery_loop())

        # Start API server
        config = uvicorn.Config(
            self.app,
            host="0.0.0.0",
            port=self.listen_port,
            log_level="info"
        )
        server = uvicorn.Server(config)

        try:
            logger.info(
                f"Starting AIOS Discovery Service on port {self.listen_port}"
            )
            await server.serve()
        finally:
            discovery_task.cancel()
            try:
                await discovery_task
            except asyncio.CancelledError:
                pass


def main():
    cell_id = os.getenv("CELL_ID", "primary")
    port = int(os.getenv("DISCOVERY_PORT", "8001"))

    discovery = AIOSDiscovery(cell_id, port)

    # Run the services
    asyncio.run(discovery.start_services())


if __name__ == "__main__":
    main()
