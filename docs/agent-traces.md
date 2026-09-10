# Claude agent traces

Each invocation creates an `AgentRun`, independent of the agent-submitted `EvaluationRun` summary. Retries get separate records. `active_job_id` and `provider_job_id` link back to ActiveJob and GoodJob; these IDs remain after GoodJob's own retention expires.

In Rails console:

```ruby
run = AgentRun.where(commitment_id: 123).order(started_at: :desc).first
run.attributes
run.events.each { |event| puts [event.sequence, event.stream, event.payload].inspect }
AgentRun.where(active_job_id: "job-uuid").order(:started_at)
```

Stdout contains Claude's verbose stream-json events, including tool calls and results. Stderr and malformed stdout are retained as typed text payloads. Events are inserted as lines arrive; sequence preserves observed order (relative ordering between separate stdout/stderr pipes is not guaranteed). Failed attempts retain partial output. A worker killed abruptly may leave a `running` record with no finish time.

Known API keys and all configured Claude OAuth tokens are replaced with `[REDACTED]` in prompts, event payloads, exception messages, and streamed log output. This does not sanitize arbitrary secrets the agent discovers from other sources. Each run records the selected token's label and SHA256 fingerprint; see [pool configuration](claude-oauth-pool.md).

`AgentRunCleanupJob` runs daily at 03:00 in production and deletes runs started more than 60 days ago, including abandoned runs. The database cascades deletion to their events. Run `AgentRunCleanupJob.perform_now` for manual cleanup. Apply the database migration before deploying workers using tracing.
