"""Base class for all audit checks."""

from __future__ import annotations

import ast
import logging
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from pathlib import Path

from src.audit.models import AuditIssue


logger = logging.getLogger(__name__)


@dataclass(slots=True)
class CheckResult:
    """Container for check results."""

    issues: list[AuditIssue] = field(default_factory=list)
    extra_info: dict | None = None

    @property
    def has_issues(self) -> bool:
        return len(self.issues) > 0


class BaseCheck(ABC):
    """Abstract base for all audit checks.

    Subclasses implement ``run()`` which receives the parsed AST, raw source
    lines, and the file path.  The default implementation returns an empty
    result so subclasses can override only what they need.
    """

    rule_name: str = "unknown"
    severity: str = "warning"

    @abstractmethod
    def run(self, tree: ast.Module, source_lines: list[str], filepath: Path) -> CheckResult:
        """Run this check and return results."""

    # -- convenience helpers --------------------------------------------------

    @staticmethod
    def _ast_visit(node: ast.AST, predicate: type | tuple[type, ...]) -> list[ast.AST]:
        """Return all descendants matching *predicate*."""
        matches: list[ast.AST] = []
        for child in ast.walk(node):
            if isinstance(child, predicate):
                matches.append(child)
        return matches

    @staticmethod
    def _has_docstring(node: ast.FunctionDef | ast.AsyncFunctionDef | ast.ClassDef) -> bool:
        docstring = ast.get_docstring(node)
        return docstring is not None and len(docstring.strip()) > 0
