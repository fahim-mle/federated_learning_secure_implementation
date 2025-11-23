# How to stop Flower processes and free TLS ports

Use this checklist whenever you need to cleanly stop SuperLink, SuperNodes, or long-running `flwr run` sessions and release ports `9091-9096`.

> **Shortcut:** From the repo root run `./scripts/stop_secure_federation.sh`. The script kills any `flower-super*`/`flwr*` processes and frees the TLS ports automatically. The steps below explain how to do the same manually.

## 1. Activate the project virtual environment

All Flower CLI entrypoints live inside `flower-secure-fl/.venv/`. From the repo root:

```bash
cd flower-secure-fl
source .venv/bin/activate
```

(If you don’t want to activate, prefix commands with `./.venv/bin/`.)

## 2. Check which federations are running

```bash
flwr list . remote-federation
flwr supernode list . remote-federation
```

`flwr list` queries the Control API on `127.0.0.1:9093` and shows every run (including status, elapsed time, etc.). `flwr supernode list` shows which registered nodes are online; make sure they finish or go offline before you kill processes. If you need to stop a specific run gracefully:

```bash
flwr stop . remote-federation --run-id <RUN_ID>
```

## 3. Inspect background Flower processes

List all SuperLink/SuperNode/serverapp processes:

```bash
pgrep -fl 'flower-super|flwr'
```

Typical listeners:

- `flower-superlink` (Control API 9093, Fleet 9092, ServerAppIo 9091)
- `flower-supernode` (ClientAppIo ports such as 9095/9096)
- `flower-superexec` or `[flwr-serverapp]/[flwr-clientapp]` workers spawned by the above

## 4. Stop the processes

*If a process is running in the foreground terminal, press `Ctrl+C`.*

For background jobs, terminate them explicitly (order: SuperNodes first, then SuperLink):

```bash
pkill -f flower-supernode
pkill -f flower-superlink
pkill -f flower-superexec
```

Re-run `pgrep -fl 'flower-super|flwr'` to ensure nothing remains.

## 5. Free the TLS ports (9091–9096)

Double-check that ports are unused:

```bash
lsof -nP -iTCP:9091-9096 -sTCP:LISTEN
```

If something is still bound, identify the PID from `lsof` and kill it, or run:

```bash
for port in 9091 9092 9093 9095 9096; do
  fuser -vk ${port}/tcp
done
```

`fuser` sends `SIGKILL` to any process still holding the port.

## 6. Verify everything is clean

1. `pgrep -fl 'flower-super|flwr'` — should return no running Flower processes.
2. `lsof -nP -iTCP:9091-9096 -sTCP:LISTEN` — should print nothing.
3. `flwr supernode list . remote-federation` — all nodes should show `registered` (offline) rather than `online`.
4. `flwr list . remote-federation` — should still connect (even if no runs are active), confirming the CLI can reach the Control API once you start it again.

Following the steps above ensures the SuperLink/SuperNode stack stops cleanly and the TLS ports are available the next time you run the secure simulation.
