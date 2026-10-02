# Codex Rate Limit Reset Notifier

Checks the Codex 5-hour rate-limit window every 5 minutes and sends a `ping` message to a configured Codex thread when the window resets.

## Prerequisites

The following commands must be installed and available:

```bash
codex
codex_status
jq
bash
```

The script requires Bash 4+. On macOS, use the Homebrew version of Bash rather than `/bin/bash`.

Check the paths with:

```bash
which bash
which codex
which codex_status
which jq
```

For Apple Silicon Macs, Homebrew Bash is typically:

```text
/opt/homebrew/bin/bash
```

## Create the state directory

The script stores the last observed 5-hour reset timestamp under `~/.local/state`.

Create the directory:

```bash
mkdir -p ~/.local/state/codex-rate-limit
```

The script will use:

```text
~/.local/state/codex-rate-limit/last-5h-reset
```

for its state and:

```text
~/.local/state/codex-rate-limit/cron.log
```

for cron output.

## Make the script executable

For example, if the script is:

```text
~/dotfiles/packages/codex/bin/codex-check-reset
```

run:

```bash
chmod +x ~/dotfiles/packages/codex/bin/codex-check-reset
```

## Test manually

Before configuring cron, run the script manually:

```bash
~/dotfiles/packages/codex/bin/codex-check-reset \
  '01a0ede6-4f4d-7320-81b4-9dad1c047465'
```

The first execution initializes the state file and does not send a notification.

When the 5-hour window changes, the script sends:

```text
ping
```

to the configured Codex thread.

## Configure cron

Open the current user's crontab:

```bash
crontab -e
```

Cron has a limited environment, so configure `SHELL` and `PATH` explicitly.

For example:

```cron
SHELL=/opt/homebrew/bin/bash
PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/Users/plam/dotfiles/packages/codex/bin

*/5 * * * * /Users/plam/dotfiles/packages/codex/bin/codex-check-reset '01a0ede6-4f4d-7320-81b4-9dad1c047465' >> /Users/plam/.local/state/codex-rate-limit/cron.log 2>&1
```

The schedule:

```text
*/5 * * * *
```

means the command runs every 5 minutes.

The Codex thread ID is configured directly in the crontab, making it easy to change without modifying the script.

A full Codex URI may also be used if supported by the script:

```text
codex://threads/01a0ede6-4f4d-7320-81b4-9dad1c047465
```

## Verify the crontab

Show the currently installed cron jobs:

```bash
crontab -l
```

To edit them again:

```bash
crontab -e
```

Do **not** use `crontab -r` unless you intend to remove the entire crontab.

## Watch the log

Stream cron output in real time:

```bash
tail -F ~/.local/state/codex-rate-limit/cron.log
```

Press `Ctrl+C` to stop watching.

To display only output written after `tail` starts:

```bash
tail -n 0 -F ~/.local/state/codex-rate-limit/cron.log
```

## Reset the notifier state

To make the next execution initialize its state again:

```bash
rm ~/.local/state/codex-rate-limit/last-5h-reset
```

The next execution will record the current reset timestamp without sending a `ping`.

## Codex active-writer conflicts

Codex may refuse to resume a thread if that thread already has an active writer:

```text
thread-store conflict: thread ... already has an active writer
```

This can happen when the same thread is open in another Codex process or Codex Desktop.

The notification script should only update its state file after `codex exec resume` succeeds. If sending the message fails, the state remains unchanged and cron can retry on its next 5-minute run.

For maximum reliability, consider using a dedicated Codex thread for rate-limit notifications.
