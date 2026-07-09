"""Check: flag bare except clauses."""

from __future__ import annotations

import ast
from pathlib import Path

from src.audit.checks.base import BaseCheck, CheckResult
from src.audit.models import AuditIssue


class BareExceptCheck(BaseCheck):
    """Flag ``except:`` without an exception type — catches KeyboardInterrupt / SystemExit."""

    rule_name = "bare_except"
    severity = "error"

    def run(self, tree: ast.Module, source_lines: list[str], filepath: Path) -> CheckResult:
        issues: list[AuditIssue] = []

        for handler in self._ast_visit(tree, ast.ExceptHandler):
            if handler.type is None:
                line = getattr(handler, "lineno", 0)
                issues.append(
                    AuditIssue(
                        severity=self.severity,
                        rule=self.rule_name,
                        line=line,
                        message="Bare 'except:' clause catches all exceptions including KeyboardInterrupt and SystemExit",
                    )
                )

        return CheckResult(issues=issues)
