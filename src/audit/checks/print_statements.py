"""Check: count print() calls per file (info-level)."""

from __future__ import annotations

import ast
from pathlib import Path

from src.audit.checks.base import BaseCheck, CheckResult
from src.audit.models import AuditIssue


class PrintStatementCheck(BaseCheck):
    """Count ``print()`` calls — treated as info, not error."""

    rule_name = "print_statement"
    severity = "info"

    def run(self, tree: ast.Module, source_lines: list[str], filepath: Path) -> CheckResult:
        count = 0
        for call in self._ast_visit(tree, ast.Call):
            func = call.func
            if isinstance(func, ast.Name) and func.id == "print":
                count += 1

        if count > 0:
            return CheckResult(
                issues=[
                    AuditIssue(
                        severity=self.severity,
                        rule=self.rule_name,
                        line=0,
                        message=f"File contains {count} print() statement(s)",
                    )
                ]
            )
        return CheckResult()
