---
name: run-a2a-java
description: Build, run, and smoke-test the A2A Java SDK helloworld reference server. Use when asked to run, start, test, or verify the app works.
---

A2A Java SDK — multi-module Maven project providing client and server libraries for the Agent2Agent protocol. The runnable artifact is a Quarkus-based helloworld reference server at `examples/helloworld/server/`. All paths below are relative to the repo root.

## Run (agent path) — smoke script

The smoke script builds the SDK, starts the helloworld Quarkus server, hits all JSON-RPC endpoints via curl, and checks responses.

```bash
.claude/skills/run-a2a-java/smoke.sh
```

Pass `--skip-build` if the SDK is already installed to local Maven (`mvn install` was run):

```bash
.claude/skills/run-a2a-java/smoke.sh --skip-build
```

The script starts the server on port 9999, runs 8 checks (agent card, SendMessage, SendStreamingMessage SSE, version validation), prints PASS/FAIL for each, and exits 0 on success. It kills the server on exit.

Server log is written to `/tmp/a2a-helloworld-server.log`.

## Build

```bash
mvn clean install
```

Requires Java 17+. Test output is redirected to files by default.

To build without tests (faster, for iteration):

```bash
mvn install -DskipTests -q
```

## Run (manual — dev mode)

Start the Quarkus server in dev mode with live reload:

```bash
cd examples/helloworld/server
mvn quarkus:dev -Dquarkus.http.port=9999
```

Then interact via curl:

```bash
# Agent card
curl -s http://localhost:9999/.well-known/agent-card.json | python3 -m json.tool

# Send a message (JSON-RPC)
curl -s -X POST http://localhost:9999/ \
  -H "Content-Type: application/json" \
  -H "A2A-Version: 1.0" \
  -d '{
    "jsonrpc":"2.0","id":"1","method":"SendMessage",
    "params":{"message":{"messageId":"m1","role":"ROLE_USER","parts":[{"text":"Hello"}]}}
  }' | python3 -m json.tool

# Streaming (SSE)
curl -s -N -X POST http://localhost:9999/ \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -H "A2A-Version: 1.0" \
  -d '{
    "jsonrpc":"2.0","id":"2","method":"SendStreamingMessage",
    "params":{"message":{"messageId":"m2","role":"ROLE_USER","parts":[{"text":"Hello"}]}}
  }'
```

## Test

```bash
mvn test
```

Run a single module's tests:

```bash
mvn test -pl tests/multiversion/jsonrpc
```

Run a specific test method:

```bash
mvn test -pl tests/multiversion/jsonrpc \
  -Dtest="MultiVersionJSONRPCTest#testRequestScopedBeanAvailableOnAgentExecutorThreadStreaming" \
  -Dsurefire.failIfNoSpecifiedTests=false
```

## Gotchas

- **A2A-Version header is mandatory for v1.0 requests.** Without it, the server defaults to protocol version "0.3" per spec Section 3.6.2, and a v1.0-only server rejects the request with `VERSION_NOT_SUPPORTED`. Always include `-H "A2A-Version: 1.0"`.
- **JSON-RPC method names are PascalCase.** `SendMessage`, `SendStreamingMessage`, `CancelTask`, `GetTask`, `SubscribeToTask` — not camelCase, not snake_case.
- **Role enum uses protobuf names.** Use `ROLE_USER` / `ROLE_AGENT`, not `user` / `agent`.
- **Part format uses protobuf oneof.** Text parts are `{"text": "..."}`, not `{"kind": "text", "text": "..."}`.
- **Quarkus dev mode startup takes ~15-20s.** The smoke script waits up to 60s.
- **Port 9999 is the dev default.** Set via `-Dquarkus.http.port=NNNN`. The smoke script kills any process on port 9999 before starting.
- **`-Dsurefire.failIfNoSpecifiedTests=false` is needed** when running a specific test with `-pl` across multi-module builds, otherwise intermediate modules fail with "no tests matching pattern."
