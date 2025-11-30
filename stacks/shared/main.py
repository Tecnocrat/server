#!/usr/bin/env python3
"""
AIOS Shared Main Entry Point
Generic entry point that can be extended by specific components
"""

import logging
import os
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def main():
    """Main entry point - should be overridden by specific components"""
    logger.info("AIOS Shared Main - Override this method in your component")

    # Get component type from environment or arguments
    component_type = os.getenv('AIOS_COMPONENT_TYPE', 'unknown')

    logger.info(f"Starting AIOS component: {component_type}")

    # Import and run the appropriate component
    try:
        if component_type == 'cell':
            from ..cells.beta.cell_server import main as cell_main
            cell_main()
        elif component_type == 'bridge':
            from ..cells.bridge.bridge import main as bridge_main
            bridge_main()
        elif component_type == 'discovery':
            from ..cells.discovery.discovery import main as discovery_main
            discovery_main()
        elif component_type == 'pure':
            from ..cells.pure.cell_server_pure import main as pure_main
            pure_main()
        elif component_type == 'network-listener':
            from ..organelles.network_listener import main as nl_main
            nl_main()
        elif component_type == 'vscode-bridge':
            from ..organelles.vscode_bridge import main as vb_main
            vb_main()
        elif component_type == 'consciousness-sync':
            from ..organelles.consciousness_sync import main as cs_main
            cs_main()
        elif component_type == 'task-dispatcher':
            from ..organelles.task_dispatcher import main as td_main
            td_main()
        else:
            logger.error(f"Unknown component type: {component_type}")
            sys.exit(1)

    except ImportError as e:
        logger.error(f"Failed to import component {component_type}: {e}")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Failed to start component {component_type}: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()