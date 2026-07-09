"""Check: flag files exceeding maximum line count."""

from __future__ import annotations

import ast
from pathlib import Path

from src.audit.checks.base import BaseCheck, CheckResult
from src.audit.models import AuditIssue


class FileSizeCheck(BaseCheck):
    """Flag Python files that exceed the configured max line count."""

    rule_name = "file_too_long"
    severity = "warning"

    def __init__(self, max_lines: int = 500) -> None:
        self.max_lines = max_lines

    def run(self, tree: ast.Module, source_lines: list[str], filepath: Path) -> CheckResult:
        if len(source_lines) > self.max_lines:
            return CheckResult(
                issues=[
                    AuditIssue(
                        severity=self.severity,
                        rule=self.rule_name,
                        line=1,
                        message=f"File has {len(source_lines)} lines (max {self.max_lines})",
                    )
                ]
            )
        return CheckResult()
