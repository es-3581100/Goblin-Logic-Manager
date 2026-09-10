#!/usr/bin/env bash
set -uo pipefail

usage() {
  cat <<'USAGE'
usage: bounded-wait.sh INNER_SECONDS [CUSHION_SECONDS] -- COMMAND [ARG...]

Runs COMMAND under GNU timeout, waits on the background PID without agent-side
polling, and returns as soon as it exits. The surrounding wait guard defaults
to INNER_SECONDS + 10 seconds.

Exit classification is printed to stderr:
  COMPLETE       command returned 0
  FAILED         command returned non-zero before inner timeout
  TIMED_OUT      GNU timeout returned 124
  TERMINATED     command/timeout process was killed
  UNKNOWN_RESULT outer wait expired or another ambiguous condition occurred
USAGE
}

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required runtime utility: $1" >&2
    exit 69
  }
}

need timeout
need tail
need mktemp

if [ "$#" -lt 3 ]; then usage >&2; exit 64; fi
inner=$1
shift
cushion=10
if [ "${1:-}" != "--" ]; then
  cushion=$1
  shift
fi
if [ "${1:-}" != "--" ]; then usage >&2; exit 64; fi
shift
if [ "$#" -eq 0 ]; then usage >&2; exit 64; fi

case "$inner:$cushion" in
  *[!0-9:]*|:*|*:) echo "seconds must be non-negative integers" >&2; exit 64 ;;
esac
outer=$((inner + cushion))
log_file=${GOBLIN_WAIT_LOG:-"$(mktemp -t goblin-wait.XXXXXX.log)"}
cleanup_log=1
if [ -n "${GOBLIN_WAIT_LOG:-}" ]; then cleanup_log=0; fi

timeout --kill-after=5s "${inner}s" "$@" >"$log_file" 2>&1 &
pid=$!

timeout "${outer}s" tail --pid="$pid" -f /dev/null >/dev/null 2>&1
wait_guard_rc=$?

if kill -0 "$pid" 2>/dev/null; then
  echo "GOBLIN_WAIT_STATUS=UNKNOWN_RESULT inner=${inner}s outer=${outer}s pid=$pid log=$log_file" >&2
  kill "$pid" 2>/dev/null || true
  sleep 1
  kill -KILL "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  [ "$cleanup_log" -eq 1 ] && cat "$log_file" && rm -f "$log_file"
  exit 125
fi

wait "$pid"
rc=$?
case "$rc" in
  0) status=COMPLETE ;;
  124) status=TIMED_OUT ;;
  137) status=TERMINATED ;;
  *) status=FAILED ;;
esac

if [ "$wait_guard_rc" -eq 124 ]; then
  status=UNKNOWN_RESULT
  rc=125
fi

echo "GOBLIN_WAIT_STATUS=$status inner=${inner}s outer=${outer}s rc=$rc log=$log_file" >&2
cat "$log_file"
[ "$cleanup_log" -eq 1 ] && rm -f "$log_file"
exit "$rc"
