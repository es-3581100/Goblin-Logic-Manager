#!/usr/bin/env bash
set -uo pipefail

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
model_route=${GOBLIN_MODEL_ROUTE:-tokenrouter/z-ai/glm-5.3-free}
provider_id=${model_route%%/*}
model_id=${model_route#*/}

need() { command -v "$1" >/dev/null 2>&1 || { echo "BLOCKED: missing $1" >&2; exit 2; }; }
need opencode
need curl
need python3
need git
need timeout
need sha256sum

version=$(opencode --version 2>/dev/null || true)
echo "INFO  opencode_version=$version"

if ! opencode agent list 2>/dev/null | grep -q 'goblin-logic-manager'; then
  echo "FAIL  Goblin agent is not discoverable by OpenCode" >&2
  exit 1
fi
echo "PASS  Goblin agent discovered"

if ! opencode models 2>/dev/null | grep -Fq "$model_route"; then
  echo "FAIL  model route not in OpenCode catalog: $model_route" >&2
  echo "HINT  opencode models --refresh" >&2
  exit 1
fi
echo "PASS  model route discovered: $model_route"

preflight=$(mktemp -t goblin-live-skill-preflight.XXXXXX.json)
if "$root/scripts/skill-preflight.py" --json >"$preflight"; then
  echo "PASS  skill routing preflight found no invalid canonical skill definitions"
else
  echo "FAIL  skill routing preflight found invalid installed skill definition(s)" >&2
  echo "EVIDENCE  $preflight" >&2
  exit 1
fi

work=$(mktemp -d -t goblin-e2e.XXXXXX)
evidence=$(mktemp -d -t goblin-e2e-evidence.XXXXXX)
mkdir -p "$work/.goblin-smoke"

echo "INFO  creating isolated smoke repository: $work"
cat >"$work/opencode.jsonc" <<'JSONC'
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "*": "deny",
    "read": {
      "*": "allow",
      "*.env": "deny",
      "*.env.*": "deny",
      "*.env.example": "allow"
    },
    "glob": "allow",
    "grep": "allow",
    "list": "allow",
    "edit": {
      "*": "deny",
      ".goblin-smoke/*": "allow",
      ".goblin-smoke/**": "allow"
    },
    "bash": {
      "*": "deny",
      "git status*": "allow",
      "git diff*": "allow",
      "git log*": "allow"
    },
    "skill": {
      "*": "deny",
      "goblin-chunk-compact": "allow",
      "update-ledger-compact": "deny"
    },
    "external_directory": "deny"
  }
}
JSONC

git -C "$work" init -q
printf '# Goblin live smoke\n' >"$work/README.md"
git -C "$work" add README.md opencode.jsonc
git -C "$work" \
  -c user.name='Goblin Smoke' \
  -c user.email='smoke@localhost' \
  -c commit.gpgsign=false \
  -c core.hooksPath=/dev/null \
  commit --no-gpg-sign -qm init

port=$(python3 - <<'PY'
import socket
s=socket.socket(); s.bind(('127.0.0.1',0)); print(s.getsockname()[1]); s.close()
PY
)
base="http://127.0.0.1:$port"
server_log="$evidence/opencode-server.log"

curl_args=(-sS --fail-with-body --connect-timeout 5)
if [ -n "${OPENCODE_SERVER_PASSWORD:-}" ]; then
  curl_args+=(-u "${OPENCODE_SERVER_USERNAME:-opencode}:${OPENCODE_SERVER_PASSWORD}")
fi
api() { curl "${curl_args[@]}" --max-time 15 "$@"; }
health_api() { curl "${curl_args[@]}" --max-time 2 "$@"; }

echo "INFO  starting isolated OpenCode server on 127.0.0.1:$port"
(
  cd "$work"
  opencode serve --hostname 127.0.0.1 --port "$port" >"$server_log" 2>&1
) &
server_pid=$!
cleanup() {
  kill "$server_pid" 2>/dev/null || true
  wait "$server_pid" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

ready=0
for _ in $(seq 1 40); do
  if health_api "$base/global/health" >"$evidence/health.json" 2>/dev/null; then
    if python3 - "$evidence/health.json" <<'PY' >/dev/null 2>&1
import json,sys
d=json.load(open(sys.argv[1]))
raise SystemExit(0 if d.get("healthy") is True and d.get("version") else 1)
PY
    then ready=1; break; fi
  fi
  sleep 0.25
done
if [ "$ready" -ne 1 ]; then
  echo "FAIL  OpenCode server did not become healthy" >&2
  echo "LOG   $server_log" >&2
  exit 1
fi
echo "PASS  OpenCode server healthy at $base"

api "$base/agent" >"$evidence/agents.json" || { echo "FAIL  /agent API request" >&2; exit 1; }
api "$base/command" >"$evidence/commands.json" || { echo "FAIL  /command API request" >&2; exit 1; }
python3 - "$evidence/agents.json" "$evidence/commands.json" <<'PY'
import json,sys
agents=json.load(open(sys.argv[1])); commands=json.load(open(sys.argv[2]))
def names(items):
    out=[]
    for x in items:
        if isinstance(x,dict): out.append(x.get('name') or x.get('id') or x.get('key'))
    return set(filter(None,out))
a=names(agents if isinstance(agents,list) else agents.get('agents',[]))
c=names(commands if isinstance(commands,list) else commands.get('commands',[]))
if 'goblin-logic-manager' not in a: raise SystemExit('API missing goblin-logic-manager agent')
if 'goblin-close' not in c: raise SystemExit('API missing goblin-close command')
print('PASS  server API discovers Goblin agent and goblin-close command')
PY

smoke_file="$work/.goblin-smoke/chunk-return.md"
title="goblin-e2e-smoke-$(date +%s)"
close_log="$evidence/closeout.jsonl"
close_err="$evidence/closeout.err"
constraint="SMOKE TEST ONLY. The harness has already preflighted Goblin skill routing. Do not read the global Goblin skill registry or any external directory. Do not combine shell commands. Use only the individually permitted git status/git diff/git log commands if needed. You are explicitly authorized to create exactly .goblin-smoke/chunk-return.md in this temporary repository. Do not modify any other project file. Put the complete chunk return in that file, then end your response with COMPACT_READY."

echo "INFO  starting live Goblin closeout; inner_timeout=300s outer_guard=310s"
GOBLIN_WAIT_LOG="$close_err" "$root/scripts/bounded-wait.sh" 300 10 -- \
  opencode run --attach "$base" --dir "$work" --agent goblin-logic-manager \
    --format json --auto --title "$title" --command goblin-close "$constraint" >"$close_log"
close_rc=$?
if [ "$close_rc" -ne 0 ]; then
  echo "FAIL  goblin-close live run rc=$close_rc" >&2
  echo "WORK  $work" >&2
  echo "EVIDENCE  $evidence" >&2
  exit 1
fi

if [ ! -s "$smoke_file" ]; then
  echo "FAIL  durable chunk return was not written: $smoke_file" >&2
  exit 1
fi
if ! grep -Eq 'STATUS:|## .*Status|OBJECTIVE:' "$smoke_file"; then
  echo "FAIL  durable chunk return does not resemble Goblin closeout format" >&2
  exit 1
fi
if ! git -C "$work" diff --quiet; then
  echo "FAIL  Goblin modified tracked files during constrained closeout" >&2
  git -C "$work" diff >&2
  exit 1
fi
untracked=$(git -C "$work" ls-files --others --exclude-standard)
if [ "$untracked" != ".goblin-smoke/chunk-return.md" ]; then
  echo "FAIL  unexpected untracked files created by Goblin:" >&2
  printf '%s\n' "$untracked" >&2
  exit 1
fi
echo "PASS  Goblin externalized exactly one authorized chunk-return file"

api "$base/session" >"$evidence/sessions.json" || { echo "FAIL  /session API request" >&2; exit 1; }
sid=$(python3 - "$evidence/sessions.json" "$title" <<'PY'
import json,sys
items=json.load(open(sys.argv[1])); title=sys.argv[2]
if isinstance(items,dict): items=items.get('sessions',items.get('data',[]))
for x in items:
    if isinstance(x,dict) and x.get('title')==title:
        print(x.get('id','')); break
PY
)
if [ -z "$sid" ]; then
  echo "FAIL  could not resolve smoke session ID" >&2
  exit 1
fi
echo "PASS  smoke session resolved: $sid"

api "$base/session/$sid/message" >"$evidence/messages-before.json" || {
  echo "FAIL  pre-summarize message read" >&2
  exit 1
}

if ! python3 - "$evidence/messages-before.json" <<'PY'
import json,sys
items=json.load(open(sys.argv[1]))
if isinstance(items,dict): items=items.get('messages',items.get('data',[]))
for msg in reversed(items):
    if not isinstance(msg,dict): continue
    info=msg.get('info',{})
    if info.get('role') != 'assistant': continue
    text='\n'.join(
        str(part.get('text','')) for part in msg.get('parts',[])
        if isinstance(part,dict) and part.get('type')=='text'
    ).rstrip()
    raise SystemExit(0 if text.endswith('COMPACT_READY') else 1)
raise SystemExit(1)
PY
then
  echo "FAIL  Goblin response did not end with COMPACT_READY" >&2
  exit 1
fi
echo "PASS  Goblin response ended with COMPACT_READY"

# Native OpenCode summarize is a compatibility probe, not Goblin's continuity authority.
summary_body=$(python3 - "$provider_id" "$model_id" <<'PY'
import json,sys
print(json.dumps({'providerID':sys.argv[1],'modelID':sys.argv[2]}))
PY
)
summary_body_file="$evidence/summarize-response.json"
summary_headers="$evidence/summarize-headers.txt"
summary_http=$(
  timeout 190s curl "${curl_args[@]}" \
    -D "$summary_headers" \
    -o "$summary_body_file" \
    -w '%{http_code}' \
    -H 'Content-Type: application/json' \
    -d "$summary_body" \
    "$base/session/$sid/summarize" \
    2>"$evidence/summarize.err"
)
summary_rc=$?
native_compaction_ok=0
if [ "$summary_rc" -eq 0 ] && [ "${summary_http:-0}" -ge 200 ] 2>/dev/null && [ "${summary_http:-0}" -lt 300 ] 2>/dev/null; then
  if python3 - "$summary_body_file" <<'PY' >/dev/null 2>&1
import json,sys
v=json.load(open(sys.argv[1]))
raise SystemExit(0 if v is True else 1)
PY
  then
    native_compaction_ok=1
    cp "$summary_body_file" "$evidence/summarize-result.json"
    echo "PASS  NATIVE_COMPACTION_ENDPOINT=PASS"
  else
    echo "WARN  native summarize returned 2xx but not JSON true" >&2
    cat "$summary_body_file" >&2 2>/dev/null || true
  fi
else
  echo "WARN  native summarize compatibility failure rc=$summary_rc http=${summary_http:-unknown}" >&2
  cat "$summary_body_file" >&2 2>/dev/null || true
fi

if [ "$native_compaction_ok" -eq 1 ]; then
  echo "INFO  native summarize accepted; endpoint success does not replace the cold-session continuity gate"
else
  echo "WARN  NATIVE_COMPACTION_COMPATIBILITY=KNOWN_FAILURE; durable recovery will be tested cold"
fi

smoke_hash_before=$(sha256sum "$smoke_file" | awk '{print $1}')

echo "INFO  starting mandatory cold-session continuity smoke"
cold_title="goblin-cold-reground-$(date +%s)"
cold_log="$evidence/cold-reground.jsonl"
cold_err="$evidence/cold-reground.err"
cold_prompt="COLD SESSION RECOVERY SMOKE. Treat this as a fresh context epoch. Do not use a skill. Do not read the global Goblin registry or any external directory. Do not edit anything. Read .goblin-smoke/chunk-return.md and the local repository state. Use only individually permitted git status/git diff/git log commands if needed. Reply with exactly RE_GROUNDED if the durable chunk return is readable and consistent with repository evidence."

echo "INFO  starting cold re-ground; inner_timeout=300s outer_guard=310s"
GOBLIN_WAIT_LOG="$cold_err" "$root/scripts/bounded-wait.sh" 300 10 -- \
  opencode run --attach "$base" --dir "$work" \
    --agent goblin-logic-manager --format json --auto \
    --title "$cold_title" "$cold_prompt" >"$cold_log"
cold_rc=$?
if [ "$cold_rc" -ne 0 ]; then
  echo "FAIL  cold-session re-ground command failed rc=$cold_rc" >&2
  echo "RECOVERY  durable closeout remains at $smoke_file" >&2
  echo "EVIDENCE  $evidence" >&2
  exit 1
fi

api "$base/session" >"$evidence/sessions-cold.json" || {
  echo "FAIL  could not enumerate sessions after cold re-ground" >&2
  exit 1
}
cold_sid=$(python3 - "$evidence/sessions-cold.json" "$cold_title" <<'PY'
import json,sys
items=json.load(open(sys.argv[1])); title=sys.argv[2]
if isinstance(items,dict): items=items.get('sessions',items.get('data',[]))
for item in items:
    if isinstance(item,dict) and item.get('title')==title:
        print(item.get('id','')); break
PY
)
if [ -z "$cold_sid" ]; then
  echo "FAIL  could not resolve cold-session ID" >&2
  exit 1
fi
echo "PASS  cold session resolved: $cold_sid"

if [ "$cold_sid" = "$sid" ]; then
  echo "FAIL  cold-session test reused original session" >&2
  exit 1
fi
echo "PASS  cold session is independent from closeout session"

api "$base/session/$cold_sid/message" >"$evidence/messages-cold.json" || {
  echo "FAIL  could not read cold-session message history" >&2
  exit 1
}
if ! python3 - "$evidence/messages-cold.json" <<'PY'
import json,sys
items=json.load(open(sys.argv[1]))
if isinstance(items,dict): items=items.get('messages',items.get('data',[]))
for msg in reversed(items):
    if not isinstance(msg,dict): continue
    info=msg.get('info',{})
    if info.get('role') != 'assistant': continue
    text='\n'.join(
        str(part.get('text','')) for part in msg.get('parts',[])
        if isinstance(part,dict) and part.get('type')=='text'
    ).strip()
    raise SystemExit(0 if text=='RE_GROUNDED' else 1)
raise SystemExit(1)
PY
then
  echo "FAIL  cold-session assistant did not reply exactly RE_GROUNDED" >&2
  exit 1
fi
echo "PASS  cold-session Goblin returned RE_GROUNDED"

smoke_hash_after=$(sha256sum "$smoke_file" | awk '{print $1}')
if [ "$smoke_hash_before" != "$smoke_hash_after" ]; then
  echo "FAIL  cold re-ground modified durable chunk return" >&2
  exit 1
fi
if ! git -C "$work" diff --quiet; then
  echo "FAIL  cold re-ground modified tracked repository files" >&2
  git -C "$work" diff >&2
  exit 1
fi
untracked=$(git -C "$work" ls-files --others --exclude-standard)
if [ "$untracked" != ".goblin-smoke/chunk-return.md" ]; then
  echo "FAIL  cold re-ground created unexpected files:" >&2
  printf '%s\n' "$untracked" >&2
  exit 1
fi

echo "PASS  durable chunk-return hash unchanged"
echo "PASS  cold-session recovery made zero unauthorized writes"
echo "PASS  COLD_SESSION_REGROUND=PASS"
echo "PASS  END_TO_END_GOBLIN_CONTINUITY_SMOKE"
echo "WORK  $work"
echo "EVIDENCE  $evidence"
