"""Check: flag public functions/classes missing docstrings."""

from __future__ import annotations

import ast
from pathlib import Path

from src.audit.checks.base import BaseCheck, CheckResult
from src.audit.models import AuditIssue


class MissingDocstringCheck(BaseCheck):
    """Flag public (non-underscore-prefixed) functions and classes without docstrings."""

    rule_name = "missing_docstring"
    severity = "warning"

    def run(self, tree: ast.Module, source_lines: list[str], filepath: Path) -> CheckResult:
        issues: list[AuditIssue] = []

        for func in self._ast_visit(tree, (ast.FunctionDef, ast.AsyncFunctionDef)):
            if not func.name.startswith("_") and not self._has_docstring(func):
                issues.append(
                    AuditIssue(
                        severity=self.severity,
                        rule=self.rule_name,
                        line=func.lineno,
                        message=f"Public function '{func.name}' is missing a docstring",
                    )
                )

        for cls in self._ast_visit(tree, ast.ClassDef):
            if not cls.name.startswith("_") and not self._has_docstring(cls):
                issues.append(
                    AuditIssue(
                        severity=self.severity,
                        rule=self.rule_name,
                        line=cls.lineno,
                        message=f"Public class '{cls.name}' is missing a docstring",
                    )
                )

        return CheckResult(issues=issues)
