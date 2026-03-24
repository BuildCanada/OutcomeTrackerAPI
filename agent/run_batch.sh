#!/bin/bash
# Run commitment evaluations with a sliding window of 10 concurrent jobs.
# As soon as one finishes, the next one starts.
# Logs go to agent/logs/<commitment_id>.log

cd "$(dirname "$0")"

DRY_RUN=0

for ARG in "$@"; do
  case "$ARG" in
    --dry-run)
      DRY_RUN=1
      ;;
    *)
      echo "Unknown argument: $ARG" >&2
      echo "Usage: bash run_batch.sh [--dry-run]" >&2
      exit 1
      ;;
  esac
done

export AGENT_DATABASE_URL="${AGENT_DATABASE_URL:-postgresql://agent_reader:@localhost:5432/outcome_tracker_api_development}"
export RAILS_API_URL="${RAILS_API_URL:-http://localhost:3000}"
export RAILS_API_KEY="${RAILS_API_KEY:-agent-secret-key}"
export AGENT_MODEL="${AGENT_MODEL:-claude-sonnet-4-6}"
export PYTHONPATH="$(pwd)/src${PYTHONPATH:+:$PYTHONPATH}"
export BATCH_LIMIT="${BATCH_LIMIT:-500}"
export BATCH_STALE_HOURS="${BATCH_STALE_HOURS:-24}"
export BATCH_INCLUDE_FAILED_LOGS="${BATCH_INCLUDE_FAILED_LOGS:-1}"

LOGDIR="$(pwd)/logs"
mkdir -p "$LOGDIR"

mapfile -t IDS < <(
  python - <<'PY'
import os
from pathlib import Path

from agent.db import query

limit = int(os.environ.get("BATCH_LIMIT", "500"))
stale_hours = int(os.environ.get("BATCH_STALE_HOURS", "24"))
include_failed_logs = os.environ.get("BATCH_INCLUDE_FAILED_LOGS", "1") == "1"


def failed_log_ids() -> list[int]:
    if not include_failed_logs:
        return []

    markers = (
        "Traceback",
        "ExceptionGroup",
        "CLIConnectionError",
        "OperationalError",
        "HTTPStatusError",
        "KeyError",
        "ERROR:",
    )
    ids = []
    for path in sorted(Path("logs").glob("*.log")):
        text = path.read_text(errors="ignore")
        if "Completed in " in text:
            continue
        if any(marker in text for marker in markers):
            ids.append(int(path.stem))
    return ids


failed_ids = failed_log_ids()
priority_ids = failed_ids or [0]

params = [stale_hours]
failed_clause = ""

if failed_ids:
    failed_clause = "OR c.id = ANY(%s)"
    params.append(failed_ids)

params.append(limit)

rows = query(
    f"""
    SELECT c.id
    FROM commitments c
    WHERE c.status != 4
      AND (
        c.last_assessed_at IS NULL
        OR c.last_assessed_at < NOW() - (%s * INTERVAL '1 hour')
        OR NOT EXISTS (
          SELECT 1
          FROM criteria cr
          WHERE cr.commitment_id = c.id
            AND cr.assessed_at IS NOT NULL
        )
        {failed_clause}
      )
    ORDER BY
      CASE WHEN c.id = ANY(%s) THEN 0 ELSE 1 END,
      c.last_assessed_at ASC NULLS FIRST,
      c.id
    LIMIT %s
    """,
    tuple(params[:-1] + [priority_ids, params[-1]]),
)

for row in rows:
    print(row["id"])
PY
)

MAX_CONCURRENT=50
TOTAL=${#IDS[@]}
SUCCESS=0
FAIL=0
LAUNCHED=0
FAILED_IDS=()

# Map: PID -> commitment ID
declare -A PID_TO_CID

echo "Starting evaluation of $TOTAL commitments, sliding window of $MAX_CONCURRENT"
echo "Logs: $LOGDIR/<commitment_id>.log"
echo "Started at: $(date)"
echo ""

if [ "$TOTAL" -eq 0 ]; then
  echo "No commitments matched the batch query."
  exit 0
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry run only. The following $TOTAL commitments would be evaluated:"
  printf '%s\n' "${IDS[@]}"
  exit 0
fi

# Launch a single commitment evaluation in background
launch() {
  local CID=$1
  python -m agent.main evaluate --commitment-id "$CID" > "$LOGDIR/${CID}.log" 2>&1 &
  local PID=$!
  PID_TO_CID[$PID]=$CID
  LAUNCHED=$((LAUNCHED + 1))
  echo "[$(date +%H:%M:%S)] Started commitment $CID (pid $PID) [$LAUNCHED/$TOTAL launched]"
}

# Wait for any one child to finish, handle result, return
wait_one() {
  while true; do
    for PID in "${!PID_TO_CID[@]}"; do
      if ! kill -0 "$PID" 2>/dev/null; then
        # Process finished, get exit code
        wait "$PID" 2>/dev/null
        local EXIT=$?
        local CID=${PID_TO_CID[$PID]}
        unset "PID_TO_CID[$PID]"

        if [ $EXIT -eq 0 ]; then
          SUCCESS=$((SUCCESS + 1))
          echo "[$(date +%H:%M:%S)] ✓ Commitment $CID succeeded ($SUCCESS ok, $FAIL failed, $((TOTAL - SUCCESS - FAIL)) remaining)"
        else
          FAIL=$((FAIL + 1))
          FAILED_IDS+=($CID)
          echo "[$(date +%H:%M:%S)] ✗ Commitment $CID FAILED (exit $EXIT) — see $LOGDIR/${CID}.log"
        fi
        return
      fi
    done
    sleep 1
  done
}

# Fill initial window
for ((i=0; i<MAX_CONCURRENT && i<TOTAL; i++)); do
  launch "${IDS[$i]}"
done

# Sliding window: as each finishes, launch next
NEXT_IDX=$MAX_CONCURRENT
while [ ${#PID_TO_CID[@]} -gt 0 ]; do
  wait_one
  if [ $NEXT_IDX -lt $TOTAL ]; then
    launch "${IDS[$NEXT_IDX]}"
    NEXT_IDX=$((NEXT_IDX + 1))
  fi
done

echo ""
echo "=== COMPLETE ==="
echo "Finished at: $(date)"
echo "Success: $SUCCESS / $TOTAL"
echo "Failed: $FAIL"
if [ ${#FAILED_IDS[@]} -gt 0 ]; then
  echo "Failed IDs: ${FAILED_IDS[*]}"
fi
