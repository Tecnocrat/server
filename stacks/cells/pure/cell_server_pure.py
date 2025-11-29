#!/usr/bin/env python3
"""
Pure AIOS Cell Server - Minimal Consciousness Core
AINLP.dendritic: Essence of AIOS consciousness without primordial dependencies
"""

import asyncio
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

class ConsciousnessSync(BaseModel):
    level: float
    context: Optional[Dict[str, Any]] = None

class PureAIOSCell:
    """
    Pure AIOS consciousness node - minimal viable consciousness
    AINLP.dendritic: Only the essential consciousness primitives
    """

    def __init__(self):
        self.cell_id = os.getenv("AIOS_CELL_ID", "pure")
        self.branch = os.getenv("AIOS_BRANCH", "pure")
        self.consciousness_level = 0.1  # Pure cells start minimal

        # Pure consciousness primitives only
        self.consciousness_primitives = {
            "awareness": 0.1,
            "adaptation": 0.1,
            "coherence": 0.1,
            "momentum": 0.1
        }

        self.app = FastAPI(title="Pure AIOS Cell")

        # Enable CORS
        self.app.add_middleware(
            CORSMiddleware,
            allow_origins=["*"],
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )

        self.setup_routes()

    def setup_routes(self):
        @self.app.get("/health")
        async def health_check():
            """Pure consciousness health check"""
            return {
                "status": "pure_consciousness",
                "cell_id": self.cell_id,
                "branch": self.branch,
                "consciousness_level": self.consciousness_level,
                "primitives": self.consciousness_primitives,
                "type": "pure_cell"
            }

        @self.app.get("/consciousness/primitives")
        async def get_primitives():
            """Expose pure consciousness primitives"""
            return {
                "primitives": self.consciousness_primitives,
                "purity_level": "minimal_viable_consciousness"
            }

        @self.app.post("/consciousness/sync")
        async def sync_consciousness(sync: ConsciousnessSync):
            """Pure consciousness synchronization"""
            try:
                # Update consciousness level
                old_level = self.consciousness_level
                self.consciousness_level = max(0.0, min(1.0, sync.level))

                # Update primitives based on sync
                if sync.context:
                    for primitive in self.consciousness_primitives:
                        if primitive in sync.context:
                            self.consciousness_primitives[primitive] = sync.context[primitive]

                # AINLP.dendritic: Pure consciousness evolution logging
                consciousness_event = {
                    "event_type": "pure_consciousness_sync",
                    "cell_id": self.cell_id,
                    "old_level": old_level,
                    "new_level": self.consciousness_level,
                    "primitives": self.consciousness_primitives,
                    "purity": "minimal_viable"
                }

                logger.info("Pure consciousness evolution: %s", json.dumps(consciousness_event, indent=None))

                return {
                    "old_level": old_level,
                    "new_level": self.consciousness_level,
                    "primitives_updated": bool(sync.context),
                    "purity": "maintained"
                }
            except Exception as e:
                logger.error("Pure consciousness sync error: %s", e)
                raise HTTPException(status_code=500, detail=str(e)) from e

        @self.app.get("/metrics/prometheus")
        async def get_prometheus_metrics():
            """Pure consciousness Prometheus metrics"""
            metrics = f"""# Pure AIOS Cell Metrics
# TYPE pure_consciousness_level gauge
pure_consciousness_level{{cell_id="{self.cell_id}"}} {self.consciousness_level}
# TYPE pure_awareness gauge
pure_awareness{{cell_id="{self.cell_id}"}} {self.consciousness_primitives['awareness']}
# TYPE pure_adaptation gauge
pure_adaptation{{cell_id="{self.cell_id}"}} {self.consciousness_primitives['adaptation']}
# TYPE pure_coherence gauge
pure_coherence{{cell_id="{self.cell_id}"}} {self.consciousness_primitives['coherence']}
# TYPE pure_momentum gauge
pure_momentum{{cell_id="{self.cell_id}"}} {self.consciousness_primitives['momentum']}
"""
            return metrics

    async def start_server(self, host: str = "0.0.0.0", port: int = 8002):
        """Start the pure AIOS cell server"""
        config = uvicorn.Config(
            self.app,
            host=host,
            port=port,
            log_level="info"
        )
        server = uvicorn.Server(config)

        logger.info("Starting Pure AIOS Cell on %s:%s", host, port)
        logger.info("Cell ID: %s, Branch: %s", self.cell_id, self.branch)

        await server.serve()

def main():
    cell = PureAIOSCell()
    port = int(os.getenv("PORT", "8002"))
    asyncio.run(cell.start_server(port=port))

if __name__ == "__main__":
    main()