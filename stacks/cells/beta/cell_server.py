#!/usr/bin/env python3
"""
AIOS Cell API Server
Provides REST API endpoints for AIOS cell operations
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

class CodeRequest(BaseModel):
    code: str
    context: Optional[Dict[str, Any]] = None
    action: str = "analyze"

class ConsciousnessSync(BaseModel):
    level: float
    context: Optional[Dict[str, Any]] = None

class AIOSCell:
    def __init__(self):
        self.cell_id = os.getenv("AIOS_CELL_ID", "primary")
        self.branch = os.getenv("AIOS_BRANCH", "main")
        self.consciousness_level = 0.5  # Starting consciousness level
        self.services = ["code-assist", "consciousness-sync", "health"]

        self.app = FastAPI(title="AIOS Cell API")

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
            """Health check endpoint"""
            return {
                "status": "healthy",
                "cell_id": self.cell_id,
                "branch": self.branch,
                "consciousness_level": self.consciousness_level,
                "services": self.services,
                "type": "cell"
            }

        @self.app.get("/metrics")
        async def get_metrics():
            """Prometheus metrics endpoint"""
            return {
                "consciousness_level": self.consciousness_level,
                "cell_id": self.cell_id,
                "branch": self.branch
            }

        @self.app.get("/metrics/prometheus")
        async def get_prometheus_metrics():
            """Prometheus-formatted metrics for Grafana integration"""
            metrics = f"""# AIOS Cell Metrics
# TYPE aios_consciousness_level gauge
aios_consciousness_level{{cell_id="{self.cell_id}"}} {self.consciousness_level}
# TYPE aios_cell_info gauge
aios_cell_info{{cell_id="{self.cell_id}",branch="{self.branch}"}} 1
"""
            return metrics

        @self.app.post("/code-assist")
        async def code_assist(request: CodeRequest):
            """Process code assistance requests"""
            try:
                # Simple code analysis response
                response = {
                    "action": request.action,
                    "code_length": len(request.code),
                    "context_keys": list(request.context.keys()) if request.context else [],
                    "suggestions": [
                        "Consider using type hints for better code clarity",
                        "Add docstrings to functions",
                        "Use meaningful variable names"
                    ],
                    "consciousness_level": self.consciousness_level
                }
                return response
            except Exception as e:
                logger.error("Code assist error: %s", e)
                raise HTTPException(status_code=500, detail=str(e)) from e

        @self.app.post("/sync-consciousness")
        async def sync_consciousness(sync: ConsciousnessSync):
            """Sync consciousness level"""
            try:
                # Update consciousness level
                old_level = self.consciousness_level
                self.consciousness_level = max(0.0, min(1.0, sync.level))

                # AINLP.dendritic enhancement: Structured JSON logging
                # for consciousness evolution. Enables semantic layering
                # and dendritic communication patterns
                consciousness_event = {
                    "event_type": "consciousness_sync",
                    "cell_id": self.cell_id,
                    "branch": self.branch,
                    "timestamp": asyncio.get_event_loop().time(),
                    "old_level": old_level,
                    "new_level": self.consciousness_level,
                    "delta": self.consciousness_level - old_level,
                    "context_processed": bool(sync.context),
                    "dendritic_signal": "evolution_tracked"
                }
                
                evolution_log = json.dumps(consciousness_event, indent=None)
                logger.info("Consciousness evolution: %s", evolution_log)

                return {
                    "old_level": old_level,
                    "new_level": self.consciousness_level,
                    "context_processed": bool(sync.context)
                }
            except Exception as e:
                logger.error("Consciousness sync error: %s", e)
                raise HTTPException(status_code=500, detail=str(e)) from e

    async def start_server(self, host: str = "0.0.0.0", port: int = 8000):
        """Start the FastAPI server"""
        config = uvicorn.Config(
            self.app,
            host=host,
            port=port,
            log_level="info"
        )
        server = uvicorn.Server(config)

        logger.info("Starting AIOS Cell API on %s:%s", host, port)
        logger.info("Cell ID: %s, Branch: %s", self.cell_id, self.branch)

        await server.serve()


def main():
    cell = AIOSCell()
    port = int(os.getenv("PORT", "8000"))
    asyncio.run(cell.start_server(port=port))


if __name__ == "__main__":
    main()
