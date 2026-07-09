"""Data models for the audit report."""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
DEFAULT_OUT = "audit_report.json"
DEFAULT_IGNORE: list[str] = ["venv", ".venv", "__pycache__", ".git", "node_modules"]
MAX_FILE_LINES = 500
MAX_FUNC_LINES = 50
TODO_RE = re.compile(r"\b(TODO|FIXME|HACK)\b")


# ---------------------------------------------------------------------------
# Issue model
# ---------------------------------------------------------------------------

@dataclass(slots=True)
class AuditIssue:
    """Represents a single code-health issue."""

    severity: str  # "error" | "warning" | "info"
    rule: str
    line: int
    message: str

    def to_dict(self) -> dict[str, Any]:
        return {
            "severity": self.severity,
            "rule": self.rule,
            "line": self.line,
            "message": self.message,
        }


# ---------------------------------------------------------------------------
# File report model
# ---------------------------------------------------------------------------

@dataclass(slots=True)
class FileReport:
    """Per-file audit results."""

    path: str
    lines: int
    issues: list[AuditIssue] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return {
            "path": self.path,
            "lines": self.lines,
            "issues": [i.to_dict() for i in self.issues],
        }


# ---------------------------------------------------------------------------
# Summary model
# ---------------------------------------------------------------------------

@dataclass(slots=True)
class SeveritySummary:
    """Severity counts."""

    error: int = 0
    warning: int = 0
    info: int = 0

    def to_dict(self) -> dict[str, Any]:
        return {"error": self.error, "warning": self.warning, "info": self.info}


@dataclass(slots=True)
class Summary:
    """Top-level summary of the audit."""

    files_scanned: int = 0
    total_issues: int = 0
    by_severity: SeveritySummary = field(default_factory=SeveritySummary)

    def to_dict(self) -> dict[str, Any]:
        return {
            "files_scanned": self.files_scanned,
            "total_issues": self.total_issues,
            "by_severity": self.by_severity.to_dict(),
        }


# ---------------------------------------------------------------------------
# Full report model
# ---------------------------------------------------------------------------

@dataclass(slots=True)
class AuditReport:
    """Complete audit report."""

    scanned_at: str = ""
    root: str = ""
    summary: Summary = field(default_factory=Summary)
    files: list[FileReport] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return {
            "scanned_at": self.scanned_at,
            "root": self.root,
            "summary": self.summary.to_dict(),
            "files": [f.to_dict() for f in self.files],
        }

    @classmethod
    def empty(cls, root: Path) -> AuditReport:
        return cls(
            scanned_at=datetime.now(timezone.utc).isoformat(),
            root=str(root.resolve()),
        )


# ---------------------------------------------------------------------------
# Configuration model
# ---------------------------------------------------------------------------

@dataclass(slots=True)
class Config:
    """CLI configuration."""

    target_dir: Path = field(default_factory=Path.cwd)
    output_path: Path = field(default_factory=lambda: Path(DEFAULT_OUT))
    ignore_dirs: list[str] = field(default_factory=lambda: list(DEFAULT_IGNORE))
    max_file_lines: int = MAX_FILE_LINES
    max_func_lines: int = MAX_FUNC_LINES
