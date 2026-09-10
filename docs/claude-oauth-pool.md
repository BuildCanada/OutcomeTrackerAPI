# Claude OAuth token pool

Set `CLAUDE_CODE_OAUTH_TOKENS` to a JSON object mapping labels to OAuth tokens:
`{"account-a":"token-a","account-b":"token-b"}`. Labels appear in run metadata;
keep them free of secrets. An empty or unset pool falls back to
`CLAUDE_CODE_OAUTH_TOKEN`. With neither configured, the CLI's existing authentication
continues to work. Production web and worker containers receive both variables.

Each agent attempt randomly chooses one distinct token from the configured pool.
Exact duplicate tokens are deduplicated. Selection does not track usage, reserve
capacity, or enforce a round-robin order; successive attempts can select the same token.
Tokens from the same account share provider quota.

Only the selected token is supplied to the CLI subprocess; the pool variable is removed
from its environment. Token values remain in memory. Run metadata stores the selected
label and SHA256 fingerprint. Trace redaction covers every pool token and the singular
fallback token, including when the pool overrides that fallback.

Rotate or remove secrets in the environment and restart workers to apply the changes.
