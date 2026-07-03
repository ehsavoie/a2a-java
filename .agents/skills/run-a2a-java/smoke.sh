#!/usr/bin/env bash
# Smoke test for the A2A Java SDK helloworld reference server.
# Builds the SDK, starts the Quarkus server, hits JSON-RPC endpoints, checks responses.
#
# Usage:
#   .claude/skills/run-a2a-java/smoke.sh          # full build + test
#   .claude/skills/run-a2a-java/smoke.sh --skip-build  # skip mvn install, just start + test
#
# Exit codes: 0 = all checks passed, 1 = a check failed, 2 = server didn't start

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PORT=9999
SERVER_DIR="$REPO_ROOT/examples/helloworld/server"
LOG="/tmp/a2a-helloworld-server.log"
SKIP_BUILD=false

for arg in "$@"; do
  case "$arg" in
    --skip-build) SKIP_BUILD=true ;;
  esac
done

cleanup() {
  local pids
  pids=$(lsof -ti :"$PORT" 2>/dev/null || true)
  if [ -n "$pids" ]; then
    kill $pids 2>/dev/null || true
    sleep 1
    kill -9 $pids 2>/dev/null || true
  fi
}
trap cleanup EXIT

# --- Build ---
if [ "$SKIP_BUILD" = false ]; then
  echo ">>> Building SDK (mvn install -DskipTests)..."
  (cd "$REPO_ROOT" && mvn install -DskipTests -q)
  echo "    Build OK"
fi

# --- Start server ---
cleanup  # kill any leftover from a previous run
echo ">>> Starting helloworld server on port $PORT..."
(cd "$SERVER_DIR" && mvn quarkus:dev \
  -Dquarkus.http.port="$PORT" \
  -Dquarkus.analytics.disabled=true \
  -Dquarkus.log.level=INFO \
  > "$LOG" 2>&1) &

echo "    Waiting for server..."
for i in $(seq 1 60); do
  if curl -sf "http://localhost:$PORT/.well-known/agent-card.json" > /dev/null 2>&1; then
    echo "    Server ready (${i}s)"
    break
  fi
  if [ "$i" -eq 60 ]; then
    echo "FAIL: server did not start within 60s. Log tail:"
    tail -20 "$LOG"
    exit 2
  fi
  sleep 1
done

PASS=0
FAIL=0

check() {
  local label="$1" expected="$2" actual="$3"
  if echo "$actual" | grep -qF "$expected"; then
    echo "  PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $label"
    echo "    expected to contain: $expected"
    echo "    got: $actual"
    FAIL=$((FAIL + 1))
  fi
}

# --- Test 1: Agent card ---
echo ">>> Test: GET agent card"
CARD=$(curl -sf "http://localhost:$PORT/.well-known/agent-card.json")
check "agent card name" '"name":"Hello World Agent"' "$CARD"
check "agent card streaming" '"streaming":true' "$CARD"

# --- Test 2: SendMessage (non-streaming JSON-RPC) ---
echo ">>> Test: SendMessage (JSON-RPC)"
RESP=$(curl -sf -X POST "http://localhost:$PORT/" \
  -H "Content-Type: application/json" \
  -H "A2A-Version: 1.0" \
  -d '{
    "jsonrpc":"2.0","id":"smoke-1","method":"SendMessage",
    "params":{"message":{"messageId":"smoke-msg-1","role":"ROLE_USER","parts":[{"text":"Hello"}]}}
  }')
check "response has result" '"result"' "$RESP"
check "response contains Hello World" '"Hello World"' "$RESP"
check "role is ROLE_AGENT" '"role":"ROLE_AGENT"' "$RESP"

# --- Test 3: SendStreamingMessage (SSE) ---
echo ">>> Test: SendStreamingMessage (SSE)"
SSE_FILE=$(mktemp)
curl -sf -N -X POST "http://localhost:$PORT/" \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -H "A2A-Version: 1.0" \
  -d '{
    "jsonrpc":"2.0","id":"smoke-2","method":"SendStreamingMessage",
    "params":{"message":{"messageId":"smoke-msg-2","role":"ROLE_USER","parts":[{"text":"Stream"}]}}
  }' > "$SSE_FILE" 2>/dev/null &
SSE_PID=$!
sleep 3
kill $SSE_PID 2>/dev/null || true
wait $SSE_PID 2>/dev/null || true
SSE_CONTENT=$(cat "$SSE_FILE")
rm -f "$SSE_FILE"
check "SSE has data line" 'data:' "$SSE_CONTENT"
check "SSE contains Hello World" '"Hello World"' "$SSE_CONTENT"

# --- Test 4: Version validation (missing header → 0.3 → rejected) ---
echo ">>> Test: version validation (no A2A-Version header)"
VERR=$(curl -sf -X POST "http://localhost:$PORT/" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0","id":"smoke-3","method":"SendMessage",
    "params":{"message":{"messageId":"smoke-msg-3","role":"ROLE_USER","parts":[{"text":"Hi"}]}}
  }')
check "rejects version 0.3" 'VERSION_NOT_SUPPORTED' "$VERR"

# --- Summary ---
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "All checks passed."
