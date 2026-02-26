#!/usr/bin/env bash
set -euo pipefail
WS="${WORKSPACE:-/tmp/kavia/workspace/code-generation/documentation-draft-236743-236744/Documentation}"
mkdir -p "$WS"
# Ensure pip3 exists
if ! command -v pip3 >/dev/null 2>&1; then
  sudo apt-get update -q >/dev/null && sudo apt-get install -y python3-pip -q >/dev/null
fi
# Record python and pip versions
python3 --version > "$WS/TOOLS_VERSIONS" 2>&1 || true
pip3 --version >> "$WS/TOOLS_VERSIONS" 2>&1 || true
# Prefer system mkdocs if present
if command -v mkdocs >/dev/null 2>&1; then
  command -v mkdocs > "$WS/MKDOCS_PATH" 2>&1 || true
  # capture deterministic mkdocs version via python -m mkdocs
  python3 -m mkdocs --version >> "$WS/TOOLS_VERSIONS" 2>&1 || true
  python3 -m mkdocs --version > "$WS/MKDOCS_VERSION" 2>&1 || true
else
  # Install to user site only when mkdocs is absent
  pip3 install --user mkdocs >/dev/null 2>&1 || true
  USER_BIN="$(python3 -m site --user-base 2>/dev/null || true)/bin"
  if [ -n "${USER_BIN:-}" ] && [ -d "$USER_BIN" ]; then
    export PATH="$USER_BIN:$PATH"
    # create workspace .env to allow engineers to persist this in their shells if desired
    printf 'export PATH="%s:$PATH"\n' "$USER_BIN" > "$WS/.env" || true
  fi
  python3 -m mkdocs --version >> "$WS/TOOLS_VERSIONS" 2>&1 || true
  python3 -m mkdocs --version > "$WS/MKDOCS_VERSION" 2>&1 || true
  command -v mkdocs > "$WS/MKDOCS_PATH" 2>&1 || true
fi
# Record PATH evidence
echo "$PATH" > "$WS/PATH_EVIDENCE" || true
exit 0
