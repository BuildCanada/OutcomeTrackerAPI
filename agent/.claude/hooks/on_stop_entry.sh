#!/bin/bash
# Stop hook for entry processing runs.
# No-ops if the entry was already marked processed.

curl -s -X PATCH "${RAILS_API_URL}/api/agent/entries/${ENTRY_ID}/mark_processed" \
  -H "Authorization: Bearer ${RAILS_API_KEY}" \
  -H "Content-Type: application/json" \
  > /dev/null 2>&1 || true
