#!/usr/bin/env bash
set -euo pipefail
# Validation script: build site, serve, smoke-check, capture evidence
WS="${WORKSPACE:-/tmp/kavia/workspace/code-generation/documentation-draft-236743-236744/Documentation}"
cd "$WS"
PORT=8000
LOGFILE="$WS/mkdocs-serve.log"
: >"$LOGFILE"
# Build and capture build log
python3 -m mkdocs build >>"$LOGFILE" 2>&1 || (tail -n 200 "$LOGFILE" >&2 && exit 5)
if [ ! -d "$WS/site" ]; then
  echo "ERROR: mkdocs build failed to create site/" >&2
  tail -n 200 "$LOGFILE" >&2 || true
  exit 6
fi
# Start server in background in its own process group
setsid sh -c "python3 -m mkdocs serve --dev-addr=0.0.0.0:${PORT} >>\"$LOGFILE\" 2>&1" &
PID=$!
sleep 0.5
PGID=$(ps -o pgid= $PID 2>/dev/null | tr -d ' ' || true)
cleanup(){
  if [ -n "${PGID:-}" ]; then
    kill -TERM -"$PGID" >/dev/null 2>&1 || true
    sleep 1
    kill -KILL -"$PGID" >/dev/null 2>&1 || true
  else
    kill "$PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT
# Wait for readiness up to 60s
SECS=0
until curl -sSf "http://127.0.0.1:${PORT}/" >/dev/null 2>&1 || [ $SECS -ge 60 ]; do
  sleep 1
  SECS=$((SECS+1))
done
if [ $SECS -ge 60 ]; then
  echo "ERROR: mkdocs serve did not start within timeout; logs:" >&2
  tail -n 200 "$LOGFILE" >&2 || true
  exit 7
fi
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:${PORT}/")
if [ "$HTTP_CODE" != "200" ]; then
  echo "ERROR: expected HTTP 200 from server but got $HTTP_CODE" >&2
  tail -n 200 "$LOGFILE" >&2 || true
  exit 8
fi
# Evidence: deterministic mkdocs version capture via python -m mkdocs
python3 -m mkdocs --version > "$WS/MKDOCS_VERSION" 2>&1 || true
command -v mkdocs > "$WS/MKDOCS_PATH" 2>&1 || true
tail -n 200 "$LOGFILE" > "$WS/mkdocs-serve-tail.log" 2>/dev/null || true
# Mark success
echo "Validation successful: site built at $WS/site and server responded with 200" > "$WS/VALIDATION_OK"
# cleanup handled by trap
exit 0
