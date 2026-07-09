"""Async Python source file reader."""

from __future__ import annotations

import ast
import logging
from pathlib import Path
from typing import Any

logger = logging.getLogger(__name__)


class AsyncFileReader:
    """Reads and parses Python files asynchronously using ``asyncio.to_thread``.

    Wraps the synchronous ``ast.parse`` + file I/O in a thread-pool so that
    multiple files can be read concurrently without blocking the event loop.
    """

    def __init__(self, max_concurrent: int = 8) -> None:
        self._semaphore: asyncio.Semaphore | None = None
        self.max_concurrent = max_concurrent

    async def _ensure_semaphore(self) -> asyncio.Semaphore:
        if self._semaphore is None:
            import asyncio

            self._semaphore = asyncio.Semaphore(self.max_concurrent)
        return self._semaphore

    @staticmethod
    def _parse_sync(filepath: Path) -> tuple[ast.Module, list[str]]:
        """Synchronous parse — runs inside a thread."""
        source_bytes = filepath.read_bytes()
        source_str = source_bytes.decode("utf-8", errors="replace")
        lines = source_str.splitlines()
        tree = ast.parse(source_str, filename=str(filepath))
        return tree, lines

    async def read(self, filepath: Path) -> dict[str, Any]:
        """Read and parse a single Python file.

        Returns ``{"tree": ..., "lines": ..., "error": None}`` on success or
        ``{"tree": None, "lines": [], "error": <exception>}`` on failure.
        """
        import asyncio

        sem = await self._ensure_semaphore()
        try:
            async with sem:
                tree, lines = await asyncio.to_thread(self._parse_sync, filepath)
                return {"tree": tree, "lines": lines, "error": None}
        except Exception as exc:
            logger.warning("Failed to read %s: %s", filepath, exc)
            return {"tree": None, "lines": [], "error": exc}
