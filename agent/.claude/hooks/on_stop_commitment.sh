#!/bin/bash
# Stop hook for commitment evaluation runs.
# No-ops if the agent already called record_evaluation_run this session.

curl -s -X PATCH "${RAILS_API_URL}/api/agent/commitments/${COMMITMENT_ID}/touch_assessed" \
  -H "Authorization: Bearer ${RAILS_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"reasoning\": \"Session ended without evaluation run — fallback timestamp update\"}" \
  > /dev/null 2>&1 || true
