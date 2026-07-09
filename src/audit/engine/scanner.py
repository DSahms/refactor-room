"""Async audit scanner — reads files and runs all registered checks."""

from __future__ import annotations

import logging
from pathlib import Path
from typing import Any, Type

from src.audit.checks.base import BaseCheck
from src.audit.engine.file_reader import AsyncFileReader
from src.audit.models import AuditIssue, FileReport, ScanSummary

logger = logging.getLogger(__name__)


class AuditScanner:
    """Orchestrates concurrent file reading and check execution."""

    def __init__(
        self,
        checks: list[BaseCheck],
        ignore_dirs: list[str] | None = None,
        max_concurrent: int = 8,
    ) -> None:
        self.checks = checks
        self.ignore_dirs = set(ignore_dirs or [])
        self._reader = AsyncFileReader(max_concurrent=max_concurrent)

    # -- file discovery -------------------------------------------------------

    @staticmethod
    def _is_in_ignored_dir(filepath: Path, root: Path, ignore_dirs: set[str]) -> bool:
        """Return ``True`` when *filepath* lives inside an ignored directory."""
        rel_parts = [p for p in filepath.relative_to(root).parts]
        # Check all parent directories (not the file name itself)
        return any(part in ignore_dirs for part in rel_parts[:-1])

    def _discover_files(self, root: Path) -> list[Path]:
        """Return sorted ``.py`` files under *root*, excluding ignored dirs."""
        py_files = sorted(root.rglob("*.py"))
        return [f for f in py_files if not self._is_in_ignored_dir(f, root, self.ignore_dirs)]

    # -- per-file processing --------------------------------------------------

    async def _process_file(self, filepath: Path, root: Path) -> FileReport | None:
        """Read one file and run all checks. Returns a ``FileReport``."""
        result = await self._reader.read(filepath)
        tree = result["tree"]
        lines = result["lines"]
        error = result["error"]

        rel_path = str(filepath.relative_to(root)).replace(Path.sep, "/")

        if error is not None:
            # Syntax or read error — record and skip further checks
            return FileReport(
                path=rel_path,
                lines=len(lines),
                issues=[
                    AuditIssue(
                        severity="warning",
                        rule="parse_error",
                        line=0,
                        message=f"Could not parse file: {error}",
                    )
                ],
            )

        # Run every registered check
        all_issues: list[AuditIssue] = []
        for check in self.checks:
            try:
                cr = check.run(tree, lines, filepath)  # type: ignore[arg-type] — tree is ast.Module here
                all_issues.extend(cr.issues)
            except Exception as exc:
                logger.error("Check '%s' failed on %s: %s", check.rule_name, filepath, exc)

        return FileReport(path=rel_path, lines=len(lines), issues=all_issues)

    # -- public API -----------------------------------------------------------

    async def scan(self, root: Path) -> dict[str, Any]:
        """Scan *root* and return the full audit report dict."""
        files = self._discover_files(root)

        if not files:
            logger.info("No Python files found in %s", root)

        # Run all file reads + checks concurrently
        tasks = [self._process_file(fp, root) for fp in files]
        reports = await asyncio.gather(*tasks, return_exceptions=True)  # type: ignore[name-defined]

        # Flatten results
        file_reports: list[dict[str, Any]] = []
        total_issues = 0
        severity_counts = {"error": 0, "warning": 0, "info": 0}

        for item in reports:
            if isinstance(item, Exception):
                logger.error("Unhandled error during scan: %s", item)
                continue
            if item is None:
                continue
            file_reports.append(item.model_dump())
            total_issues += len(item.issues)
            for issue in item.issues:
                sev = issue.severity
                if sev in severity_counts:
                    severity_counts[sev] += 1

        from datetime import datetime, timezone

        summary = ScanSummary(
            files_scanned=len(file_reports),
            total_issues=total_issues,
            by_severity=severity_counts,
        )

        return {
            "scanned_at": datetime.now(timezone.utc).isoformat(),
            "root": str(root.resolve()),
            "summary": summary.model_dump(),
            "files": file_reports,
        }
