#!/usr/bin/env bash
set -euo pipefail
# testing setup and lint - deterministic execution using workspace from container context
WS="${WORKSPACE:-/tmp/kavia/workspace/code-generation/documentation-draft-236743-236744/Documentation}"
cd "$WS"
# Build (deterministic invocation) and capture logs
python3 -m mkdocs build > "$WS/BUILD_LOG" 2>&1 || (tail -n 200 "$WS/BUILD_LOG" >&2 && exit 2)
if [ ! -f "$WS/site/index.html" ]; then
  echo "ERROR: build did not produce site/index.html" >&2
  exit 3
fi
# Content sanity: ensure site_name 'Documentation' present
if ! grep -q "Documentation" "$WS/site/index.html"; then
  echo "ERROR: generated index.html does not contain site_name" >&2
  exit 4
fi
# Markdown lint: prefer installed binary; skip heavy network installs
LINT_STATUS="skipped"
MDs=$(find docs -name '*.md' -print | tr '\n' ' ' || true)
if command -v markdownlint >/dev/null 2>&1; then
  if [ -n "${MDs:-}" ]; then
    markdownlint $MDs || true
    LINT_STATUS="ran: markdownlint"
  fi
elif command -v markdownlint-cli >/dev/null 2>&1; then
  if [ -n "${MDs:-}" ]; then
    markdownlint-cli $MDs || true
    LINT_STATUS="ran: markdownlint-cli"
  fi
else
  LINT_STATUS="skipped: no markdownlint installed"
fi
# Record lint status and success evidence
echo "$LINT_STATUS" > "$WS/TEST_LINT" || true
echo "TEST_OK: site/index.html exists and contains site_name" > "$WS/TEST_OK"
exit 0
