#!/usr/bin/env bash
set -euo pipefail
WS="${WORKSPACE:-/tmp/kavia/workspace/code-generation/documentation-draft-236743-236744/Documentation}"
mkdir -p "$WS/docs"
cd "$WS"
# mkdocs.yml
cat > mkdocs.yml <<'YML'
site_name: Documentation
nav:
  - Home: index.md
  - Getting Started: getting-started.md
  - Installation: installation.md
  - Configuration: configuration.md
  - Usage: usage.md
  - API: api.md
  - Architecture: architecture.md
  - Troubleshooting: troubleshooting.md
  - FAQ: faq.md
  - Contributing: contributing.md
  - License: license.md
YML
# titleize helper
titleize(){ echo "$1" | sed -E 's/-/ /g; s/(^| )([a-z])/\1\U\2/g' ; }
files=(index getting-started installation configuration usage api architecture troubleshooting faq contributing license)
for f in "${files[@]}"; do
  fp="$WS/docs/$f.md"
  if [ ! -f "$fp" ]; then
    heading="$(titleize "$f")"
    cat > "$fp" <<EOF
# $heading

Placeholder content for $f. Replace with real documentation.
EOF
  fi
done
# .gitignore
cat > .gitignore <<'G'
site/
.DS_Store
__pycache__/
G
# README (only create if missing)
if [ ! -f README.md ]; then
  cat > README.md <<R
# Documentation (MkDocs)

Run from the project workspace: cd "$WS" then:

Build: make build  (Makefile cd's into workspace and runs: python3 -m mkdocs build)
Serve: make serve  (Makefile cd's into workspace and runs: python3 -m mkdocs serve --dev-addr=0.0.0.0:8000)

If a user-site mkdocs was installed, a workspace/.env was created to prepend the user bin; source it to add to your shell: source .env

Evidence files written to the workspace: TOOLS_VERSIONS, MKDOCS_VERSION, MKDOCS_PATH, PATH_EVIDENCE, BUILD_LOG, TEST_LINT, TEST_OK, VALIDATION_OK, mkdocs-serve.log
R
fi
# Makefile with deterministic cd into workspace
cat > Makefile <<'MK'
.PHONY: build serve
build:
	cd "${WORKSPACE}" && python3 -m mkdocs build
serve:
	cd "${WORKSPACE}" && python3 -m mkdocs serve --dev-addr=0.0.0.0:8000
MK
# helper scripts
cat > build.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
WS="${WORKSPACE:-/tmp/kavia/workspace/code-generation/documentation-draft-236743-236744/Documentation}"
cd "$WS"
python3 -m mkdocs build
SH
chmod +x build.sh
cat > serve.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
WS="${WORKSPACE:-/tmp/kavia/workspace/code-generation/documentation-draft-236743-236744/Documentation}"
cd "$WS"
python3 -m mkdocs serve --dev-addr=0.0.0.0:8000
SH
chmod +x serve.sh
# workspace .env guidance: do not modify global shells; provide sourceable helper if user did --user installs
cat > .env <<'ENV'
# If you installed Python packages with --user, your user base bin directory
# (usually $(python3 -m site --user-base)/bin) may need to be prepended to PATH.
# To persist for your shell session, run: source .env
# Example:
# export PATH="${HOME}/.local/bin:$PATH"
ENV
# Initialize git safely and set local config to avoid commit failures
if [ ! -d .git ]; then
  git init -q || true
fi
if [ -z "$(git config user.email || true)" ]; then
  git config user.email "ci@example.com"
fi
if [ -z "$(git config user.name || true)" ]; then
  git config user.name "ci"
fi
git add -A >/dev/null 2>&1 || true
git commit -m "scaffold: initial mkdocs site" >/dev/null 2>&1 || true
exit 0
