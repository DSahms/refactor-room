"""Check: flag functions exceeding maximum line count."""

from __future__ import annotations

import ast
from pathlib import Path

from src.audit.checks.base import BaseCheck, CheckResult
from src.audit.models import AuditIssue


class FunctionLengthCheck(BaseCheck):
    """Flag functions / async-functions that exceed the configured max line count."""

    rule_name = "function_too_long"
    severity = "warning"

    def __init__(self, max_lines: int = 50) -> None:
        self.max_lines = max_lines

    def run(self, tree: ast.Module, source_lines: list[str], filepath: Path) -> CheckResult:
        issues: list[AuditIssue] = []

        for func in self._ast_visit(tree, (ast.FunctionDef, ast.AsyncFunctionDef)):
            start = getattr(func, "lineno", 0)
            end = getattr(func, "end_lineno", 0)
            if end and start and (end - start + 1) > self.max_lines:
                issues.append(
                    AuditIssue(
                        severity=self.severity,
                        rule=self.rule_name,
                        line=start,
                        message=f"Function '{func.name}' is {end - start + 1} lines long (max {self.max_lines})",
                    )
                )

        return CheckResult(issues=issues)
