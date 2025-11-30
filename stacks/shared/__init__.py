#!/usr/bin/env python3
"""
AINLP.dendritic Shared Utilities
Common dendritic growth patterns and framework detection utilities
"""

from .dendritic_utils import (
    DendriticFrameworkDetector,
    create_fallback_app,
    get_base_model
)

__all__ = [
    'DendriticFrameworkDetector',
    'create_fallback_app',
    'get_base_model'
]
