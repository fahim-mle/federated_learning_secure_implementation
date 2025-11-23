# Project Completion Tracker – Entry 1

## Secure Federation Milestones

- **TLS configuration**: Certificates for CA, SuperLink, and SuperNodes live under `flower-secure-fl/certificates/`; `pyproject.toml` points `remote-federation` at `127.0.0.1:9093` with `root-certificates = "./certificates/ca/ca.crt"`.
- **SuperLink hardening**: `how_to_run.md` documents running `flower-superlink` with `--enable-supernode-auth`, and we’ve verified the “auth disabled” warning is gone in current logs.
- **SuperNode authentication**: SSH-format ECDSA keypairs (`keys/supernode{1,2}_auth`) are generated, registered via `flwr supernode register …`, and used with `--auth-supernode-private-key`. `flwr supernode list . remote-federation` shows only the registered nodes online.
- **End-to-end secure run**: Running `flwr run . remote-federation --stream` after launching two authenticated SuperNodes completes all three FedAvg rounds; `flwr list . remote-federation` now lists multiple finished run IDs (e.g., `6229199373289233691`, `8195067376823002495`).

## Automation Scripts

- `scripts/run_secure_federation.sh`: Starts the TLS+auth SuperLink, re-registers both SuperNode keys, spawns two authenticated SuperNodes (ports 9095/9096), and kicks off the remote federation with live log streaming. Logs land under `logs/`.
- `scripts/stop_secure_federation.sh`: Stops any `flower-supernode`, `flower-superlink`, `flwr run`, `flwr-serverapp`, and `flwr-clientapp` processes, then frees ports 9091–9096 using `lsof`/`fuser`.

## Documentation Updates

- `docs/how_to_run.md` covers manual and scripted workflows, including the new “Register SuperNodes” step and references to the helper scripts.
- `docs/how_to_stop.md` highlights the stop script and reiterates the manual checklist for verifying that all Flower processes and TLS ports are clear.
- Phase docs (`phase_1.x`) capture the detailed procedure for TLS, SuperNode launch, and authentication troubleshooting; `project_completion_tracker` will track ongoing progress.
