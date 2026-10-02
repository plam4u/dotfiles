# Codex account status

`bin/codex_status` extracts the account usage query used by SketchyBar into a
standalone command. It requires Bash 4+ (Homebrew bash), `codex`, and `jq` on
`PATH`, and uses the existing Codex login and `CODEX_HOME` configuration.
Source `~/.zshrc.d/codex.sh` or start a new shell to add the package's `bin/`
directory to `PATH`.

```sh
codex_status
codex_status | jq '.fiveHour | {remainingPercent, resetsAt, resetInSeconds}'
codex_status | jq '.weekly | {remainingPercent, resetsAt, resetInSeconds}'
```

Output is one JSON object, also available explicitly with `--json`:

- `fiveHour` and `weekly`: usage windows with `usedPercent`, `remainingPercent`
  (clamped to 0–100), `windowDurationMins`, `resetsAt` (Unix seconds), and
  `resetInSeconds` (nonnegative seconds from `updatedAt`).
- `planType`, `credits`, and `manualResets`: the plan, workspace credit details,
  and available manual reset count.
- `rateLimits` and `rateLimitsByLimitId`: the selected Codex bucket and all
  returned buckets, with the same derived fields on each window.
- `updatedAt`: query time in Unix seconds.

Unavailable windows and fields are `null`, not zero. A failed query writes a
diagnostic to stderr and exits nonzero without JSON. The total response timeout
is 30 seconds; override it with `CODEX_STATUS_TIMEOUT=10 codex_status`.
Each call starts an ephemeral app server and terminates it on exit.
The protocol is documented in the
[official OpenAI app-server documentation](https://learn.chatgpt.com/docs/app-server).

Cron does not source interactive shell configuration. Set its `PATH` explicitly
to include the package and dependencies, for example on Apple Silicon:

```cron
PATH=/opt/homebrew/bin:/usr/bin:/bin:/Users/plam/dotfiles/packages/codex/bin
```

A scheduling script can query `resetsAt` and check `remainingPercent` with `jq`.
Fetch a fresh status when it runs, and handle `null` and query failures before
scheduling work. This package does not install a cron job.

Run the isolated protocol tests with `python3 -m unittest discover -s tests`.
