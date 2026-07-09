"""Check: extract TODO / FIXME / HACK comments with line numbers."""

from __future__ import annotations

import re
from pathlib import Path

from src.audit.checks.base import BaseCheck, CheckResult
from src.audit.models import AuditIssue, TODO_RE


class TodoCommentCheck(BaseCheck):
    """Flag TODO / FIXME / HACK comments in source code."""

    rule_name = "todo_comment"
    severity = "info"

    def run(self, tree: object, source_lines: list[str], filepath: Path) -> CheckResult:  # noqa: ARG002 — tree unused; signature matches BaseCheck
        issues: list[AuditIssue] = []

        for idx, line in enumerate(source_lines, start=1):
            stripped = line.strip()
            if not stripped.startswith("#"):
                continue
            if TODO_RE.search(stripped):
                issues.append(
                    AuditIssue(
                        severity=self.severity,
                        rule=self.rule_name,
                        line=idx,
                        message=f"Found '{stripped}'",
                    )
                )

        return CheckResult(issues=issues)
