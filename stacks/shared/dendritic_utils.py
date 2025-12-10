#!/usr/bin/env python3
"""
AIOS Shared Dendritic Utilities
Centralized framework detection and fallback utilities for AIOS components

AINLP.dendritic[shared]{framework_detection,os_distillation,fallback_patterns}

Provides:
- Framework availability detection (pydantic, fastapi, redis, etc.)
- OS distillation for cross-platform cell populations (win32, linux, darwin)
- Graceful fallback patterns when dependencies unavailable
"""

import importlib.util
import logging
import os
import sys
import tempfile
from pathlib import Path
from typing import Any, Dict, List, Optional, Type

logger = logging.getLogger(__name__)

# AINLP.dendritic: Top-level optional import with graceful fallback
try:
    from pydantic import BaseModel as PydanticBaseModel
    PYDANTIC_AVAILABLE = True
except ImportError:
    PydanticBaseModel = None  # type: ignore
    PYDANTIC_AVAILABLE = False


class DendriticFrameworkDetector:
    """AINLP.dendritic growth: Centralized framework availability detection"""

    def __init__(self) -> None:
        self._cache: Dict[str, bool] = {}

    def is_available(self, framework_name: str) -> bool:
        """Check if a framework is available using enhanced dendritic logic"""
        if framework_name in self._cache:
            return self._cache[framework_name]

        try:
            spec = importlib.util.find_spec(framework_name)
            available = spec is not None
            self._cache[framework_name] = available
            return available
        except (ModuleNotFoundError, ValueError, ImportError) as exc:
            logger.debug("Framework %s unavailable: %s", framework_name, exc)
            self._cache[framework_name] = False
            return False

    def get_available_frameworks(self, frameworks: list) -> Dict[str, bool]:
        """Check availability of multiple frameworks"""
        return {fw: self.is_available(fw) for fw in frameworks}


def create_fallback_app(title: str = "AIOS Fallback App") -> Dict[str, Any]:
    """AINLP.dendritic: Create fallback app when FastAPI unavailable"""
    logger.warning("AINLP.dendritic: Using pure Python fallback app")
    return {
        "type": "fallback",
        "framework": "none",
        "title": title,
        "routes": []
    }


class FallbackBaseModel:
    """AINLP.dendritic: Fallback BaseModel when pydantic unavailable"""

    def __init__(self, **data: Any) -> None:
        for key, value in data.items():
            setattr(self, key, value)


def get_base_model() -> Type:
    """AINLP.dendritic: Get BaseModel class with fallback"""
    if PYDANTIC_AVAILABLE and PydanticBaseModel is not None:
        return PydanticBaseModel
    logger.warning("AINLP.dendritic: Pydantic unavailable, using fallback")
    return FallbackBaseModel


# =============================================================================
# OS DISTILLATION FOR CELL POPULATIONS
# =============================================================================

class OSDistillation:
    """
    AINLP.dendritic: OS-specific runtime adaptations for cell populations.
    
    Handles platform differences that cause issues like:
    - Case sensitivity (MNEME vs mneme collision on Windows)
    - Path separators (\\ vs /)
    - File locking (mandatory vs advisory)
    - Line endings (CRLF vs LF)
    
    Usage:
        from shared.dendritic_utils import OSDistillation
        distill = OSDistillation()
        safe_path = distill.normalize_path("some/path")
        if distill.would_collide("MNEME", "mneme"):
            # Handle case collision
    """
    
    _instance: Optional['OSDistillation'] = None
    
    def __new__(cls) -> 'OSDistillation':
        """Singleton pattern - one distillation per process"""
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance
    
    def __init__(self) -> None:
        if self._initialized:
            return
        self._initialized = True
        
        self.platform = sys.platform  # 'win32', 'linux', 'darwin'
        self.case_sensitive = self._detect_case_sensitivity()
        self.path_sep = '\\' if self.platform == 'win32' else '/'
        
        logger.info(
            "AINLP.os_distillation: %s (case_sensitive=%s)",
            self.platform, self.case_sensitive
        )
    
    def _detect_case_sensitivity(self) -> bool:
        """Detect filesystem case sensitivity at runtime"""
        if self.platform == 'win32':
            return False  # NTFS is case-insensitive by default
        if self.platform == 'darwin':
            return False  # macOS HFS+/APFS case-insensitive by default
        
        # Linux: test actual filesystem
        try:
            with tempfile.NamedTemporaryFile(
                delete=False, suffix='_CaSe'
            ) as f:
                test_path = f.name
            upper_path = test_path.replace('_CaSe', '_CASE')
            is_sensitive = not os.path.exists(upper_path)
            os.unlink(test_path)
            return is_sensitive
        except OSError:
            return True  # Assume case-sensitive on error
    
    def normalize_path(self, path: str) -> Path:
        """
        Normalize path for current OS.
        
        - Converts separators to OS-native
        - On case-insensitive systems, preserves original case but
          enables case-insensitive comparison via would_collide()
        """
        # Normalize separators
        normalized = path.replace('\\', '/').replace('//', '/')
        return Path(normalized)
    
    def would_collide(self, name_a: str, name_b: str) -> bool:
        """
        Check if two names would collide on this filesystem.
        
        Example: would_collide("MNEME", "mneme") → True on Windows
        """
        if self.case_sensitive:
            return name_a == name_b
        return name_a.lower() == name_b.lower()
    
    def find_case_collisions(self, names: List[str]) -> List[tuple]:
        """
        Find all case-collision pairs in a list of names.
        
        Returns list of (name_a, name_b) tuples that would collide.
        """
        if self.case_sensitive:
            return []
        
        collisions = []
        seen: Dict[str, str] = {}  # lowercase -> original
        
        for name in names:
            lower = name.lower()
            if lower in seen and seen[lower] != name:
                collisions.append((seen[lower], name))
            else:
                seen[lower] = name
        
        return collisions
    
    def safe_filename(
        self, name: str, existing: Optional[List[str]] = None
    ) -> str:
        """
        Create OS-safe filename, avoiding collisions with existing names.
        
        If collision detected, appends suffix: MNEME → MNEME_upper
        """
        if existing is None:
            return name
        
        for existing_name in existing:
            collides = self.would_collide(name, existing_name)
            if collides and name != existing_name:
                # Collision! Add disambiguating suffix
                base, ext = os.path.splitext(name)
                if name.isupper():
                    return f"{base}_upper{ext}"
                elif name.islower():
                    return f"{base}_lower{ext}"
                else:
                    return f"{base}_mixed{ext}"
        
        return name
    
    def git_config_recommendations(self) -> Dict[str, str]:
        """
        Return recommended git config for this OS.
        
        Helps prevent issues like the MNEME/mneme collision.
        """
        if self.platform == 'win32':
            return {
                'core.ignorecase': 'true',
                'core.autocrlf': 'true',
                'core.longpaths': 'true',
            }
        elif self.platform == 'darwin':
            return {
                'core.ignorecase': 'true',
                'core.autocrlf': 'input',
            }
        else:  # Linux
            return {
                'core.ignorecase': 'false',
                'core.autocrlf': 'input',
            }
    
    @property
    def is_windows(self) -> bool:
        return self.platform == 'win32'
    
    @property
    def is_linux(self) -> bool:
        return self.platform == 'linux'
    
    @property
    def is_macos(self) -> bool:
        return self.platform == 'darwin'


# Module-level singleton for easy access
_os_distillation: Optional[OSDistillation] = None


def get_os_distillation() -> OSDistillation:
    """Get the singleton OSDistillation instance"""
    global _os_distillation
    if _os_distillation is None:
        _os_distillation = OSDistillation()
    return _os_distillation
