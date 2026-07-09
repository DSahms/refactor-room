#!/usr/bin/env python3
"""Local Code Audit Tool — single-file CLI for scanning Python projects."""

from __future__ import annotations

import argparse
import ast
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
DEFAULT_OUT = "audit_report.json"
DEFAULT_IGNORE = ["venv", ".venv", "__pycache__", ".git", "node_modules"]
MAX_FILE_LINES = 500
MAX_FUNC_LINES = 50
TODO_RE = re.compile(r"\b(TODO|FIXME|HACK)\b")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _relative(filepath: Path, root: Path) -> str:
    """Return path relative to *root* using forward slashes."""
    return str(filepath.relative_to(root)).replace(os.sep, "/")


def _is_in_ignored_dir(filepath: Path, root: Path, ignore_dirs: set[str]) -> bool:
    """Return ``True`` when *filepath* lives inside an ignored directory."""
    rel_parts = [p for p in filepath.relative_to(root).parts]
    return any(part in ignore_dirs for part in rel_parts[:-1])


# ---------------------------------------------------------------------------
# Checks — each returns a list of issue dicts
# ---------------------------------------------------------------------------

def _check_file_size(filepath: Path, lines: list[str]) -> list[dict]:
    """Flag files exceeding max line count."""
    if len(lines) > MAX_FILE_LINES:
        return [
            {
                "severity": "warning",
                "rule": "file_too_long",
                "line": 1,
                "message": f"File has {len(lines)} lines (max {MAX_FILE_LINES})",
            }
        ]
    return []


def _check_function_length(tree: ast.Module) -> list[dict]:
    """Flag functions / async-functions exceeding max line count."""
    issues: list[dict] = []
    for func in ast.walk(tree):
        if isinstance(func, (ast.FunctionDef, ast.AsyncFunctionDef)):
            start = getattr(func, "lineno", 0)
            end = getattr(func, "end_lineno", 0)
            if end and start and (end - start + 1) > MAX_FUNC_LINES:
                issues.append(
                    {
                        "severity": "warning",
                        "rule": "function_too_long",
                        "line": start,
                        "message": f"Function '{func.name}' is {end - start + 1} lines long (max {MAX_FUNC_LINES})",
                    }
                )
    return issues


def _check_missing_docstrings(tree: ast.Module) -> list[dict]:
    """Flag public functions/classes without docstrings."""
    issues: list[dict] = []

    def _visit(node: ast.AST) -> None:
        for child in ast.iter_child_nodes(node):
            if isinstance(child, (ast.FunctionDef, ast.AsyncFunctionDef)):
                name = child.name
                if not name.startswith("_") and not ast.get_docstring(child):
                    issues.append(
                        {
                            "severity": "warning",
                            "rule": "missing_docstring",
                            "line": child.lineno,
                            "message": f"Public function '{name}' is missing a docstring",
                        }
                    )
            elif isinstance(child, ast.ClassDef):
                name = child.name
                if not name.startswith("_") and not ast.get_docstring(child):
                    issues.append(
                        {
                            "severity": "warning",
                            "rule": "missing_docstring",
                            "line": child.lineno,
                            "message": f"Public class '{name}' is missing a docstring",
                        }
                    )
            _visit(child)

    _visit(tree)
    return issues


def _check_bare_excepts(tree: ast.Module) -> list[dict]:
    """Flag bare ``except:`` clauses."""
    issues: list[dict] = []
    for handler in ast.walk(tree):
        if isinstance(handler, ast.ExceptHandler) and handler.type is None:
            line = getattr(handler, "lineno", 0)
            issues.append(
                {
                    "severity": "error",
                    "rule": "bare_except",
                    "line": line,
                    "message": "Bare 'except:' clause catches all exceptions including KeyboardInterrupt and SystemExit",
                }
            )
    return issues


def _check_print_statements(tree: ast.Module) -> list[dict]:
    """Count ``print()`` calls — info level."""
    count = 0
    for call in ast.walk(tree):
        if isinstance(call, ast.Call):
            func = call.func
            if isinstance(func, ast.Name) and func.id == "print":
                count += 1
    if count > 0:
        return [
            {
                "severity": "info",
                "rule": "print_statement",
                "line": 0,
                "message": f"File contains {count} print() statement(s)",
            }
        ]
    return []


def _check_todo_comments(source: str) -> list[dict]:
    """Flag TODO / FIXME / HACK comments."""
    issues: list[dict] = []
    for idx, line in enumerate(source.splitlines(), start=1):
        stripped = line.strip()
        if not stripped.startswith("#"):
            continue
        if TODO_RE.search(stripped):
            issues.append(
                {
                    "severity": "info",
                    "rule": "todo_comment",
                    "line": idx,
                    "message": f"Found '{stripped}'",
                }
            )
    return issues


# ---------------------------------------------------------------------------
# Core scanning logic
# ---------------------------------------------------------------------------

def _parse_file(filepath: Path) -> tuple[ast.Module | None, list[str], Exception | None]:
    """Return (AST tree, raw lines, exception)."""
    try:
        source_bytes = filepath.read_bytes()
        source_str = source_bytes.decode("utf-8", errors="replace")
        lines = source_str.splitlines()
        tree = ast.parse(source_str, filename=str(filepath))
        return tree, lines, None
    except Exception as exc:
        return None, [], exc


def scan_directory(root: Path, ignore_dirs: list[str]) -> dict[str, Any]:
    """Scan *root* and return the full audit report dict."""

    files_scanned = 0
    file_reports: list[dict] = []
    total_issues = 0
    severity_counts = {"error": 0, "warning": 0, "info": 0}

    py_files = sorted(root.rglob("*.py"))

    for filepath in py_files:
        if _is_in_ignored_dir(filepath, root, set(ignore_dirs)):
            continue

        tree, lines, parse_error = _parse_file(filepath)

        file_entry: dict[str, Any] = {
            "path": _relative(filepath, root),
            "lines": len(lines),
            "issues": [],
        }

        if parse_error is not None:
            file_entry["issues"].append(
                {
                    "severity": "warning",
                    "rule": "parse_error",
                    "line": 0,
                    "message": f"Could not parse file: {parse_error}",
                }
            )
            files_scanned += 1
            file_reports.append(file_entry)
            continue

        # Run all checks
        all_issues: list[dict] = []
        all_issues.extend(_check_file_size(filepath, lines))
        all_issues.extend(_check_function_length(tree))
        all_issues.extend(_check_missing_docstrings(tree))
        all_issues.extend(_check_bare_excepts(tree))
        all_issues.extend(_check_print_statements(tree))
        source_text = "\n".join(lines) + "\n" if lines else ""
        all_issues.extend(_check_todo_comments(source_text))

        file_entry["issues"] = all_issues
        files_scanned += 1
        file_reports.append(file_entry)

        for issue in all_issues:
            total_issues += 1
            sev = issue.get("severity")
            if sev in severity_counts:
                severity_counts[sev] += 1

    report = {
        "scanned_at": datetime.now(timezone.utc).isoformat(),
        "root": str(root.resolve()),
        "summary": {
            "files_scanned": files_scanned,
            "total_issues": total_issues,
            "by_severity": severity_counts,
        },
        "files": file_reports,
    }

    return report


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Scan a Python project and produce a JSON code-health report."
    )
    parser.add_argument("path", help="Directory to scan")
    parser.add_argument("--out", default=DEFAULT_OUT, help=f"Output JSON path (default: {DEFAULT_OUT})")
    parser.add_argument(
        "--ignore",
        default=",".join(DEFAULT_IGNORE),
        help="Comma-separated directory names to skip "
             f"(default: {','.join(DEFAULT_IGNORE)})",
    )

    args = parser.parse_args()

    target = Path(args.path).resolve()
    if not target.is_dir():
        print(f"Error: '{target}' is not a directory.", file=sys.stderr)
        sys.exit(1)

    ignore_dirs = [d.strip() for d in args.ignore.split(",") if d.strip()]

    report = scan_directory(target, ignore_dirs)

    out_path = Path(args.out).resolve()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(report, indent=2), encoding="utf-8")

    print(
        f"Scan complete: {report['summary']['files_scanned']} files scanned, "
        f"{report['summary']['total_issues']} issues found."
    )
    print(f"Report written to {out_path}")


if __name__ == "__main__":
    main()
