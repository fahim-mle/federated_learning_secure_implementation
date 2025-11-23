# How to Run the Secure Flower Simulation

This guide summarizes the exact commands needed to run the Flower app in both TLS-enabled remote mode (via SuperLink) and plain local simulation mode.

## Prerequisites
- Python virtual environment at the repo root (`.venv/`) is activated.
- Certificates already exist under `flower-secure-fl/certificates/` with subfolders `ca/`, `superlink/`, and `supernodes/`.
- `flower-secure-fl/pyproject.toml` contains:

  ```toml
  [tool.flwr.federations.remote-federation]
  address = "127.0.0.1:9093"
  root-certificates = "./certificates/ca/ca.crt"
  ```

- `flower-secure-fl` is installed in editable mode inside the venv (run from repo root):

  ```bash
  .venv/bin/pip install -e flower-secure-fl/
  ```

## 1. Start the TLS-enabled SuperLink
From `flower-secure-fl/` (where the certificates folder lives), start SuperLink with TLS:

```bash
flower-superlink \
  --ssl-ca-certfile ./certificates/ca/ca.crt \
  --ssl-certfile ./certificates/superlink/superlink.crt \
  --ssl-keyfile ./certificates/superlink/superlink.key
```

Expected log lines:
```
INFO: Starting Flower SuperLink
INFO: Flower Deployment Runtime: Starting Control API on 0.0.0.0:9093
INFO: Flower Deployment Runtime: Starting Fleet API (gRPC-rere) on 0.0.0.0:9092
INFO: Flower Deployment Runtime: Starting ServerAppIo API on 0.0.0.0:9091
```

## 2. Verify TLS on the Control API (optional but recommended)

```bash
cd flower-secure-fl
openssl s_client -connect 127.0.0.1:9093 -CAfile ./certificates/ca/ca.crt </dev/null
```

Look for `verify return code: 0 (ok)` and the SuperLink certificate details.

## 3. Run the secure remote federation
In another terminal (venv active) from `flower-secure-fl/`:

```bash
flwr run . remote-federation
```

Successful output:
```
Loading project configuration...
Success
🎊 Successfully started run <RUN_ID>
```

Leave the command running; SuperLink will now wait for SuperNodes to attach. If you want to test with a local SuperNode, run `flower-supernode` in additional terminals, pointing them to the Control API certificate bundle.

## 4. Run the local simulation (non-TLS fallback)
Still from `flower-secure-fl/`:

```bash
flwr run . local-simulation
```

You should see the standard three FedAvg rounds complete with aggregated metrics, confirming that the simulation configuration still works alongside the secure federation setup.

## Notes
- Always run these commands with the SuperLink process active; stop it with `Ctrl+C` or `kill <PID>` when done.
- If `pip install -e flower-secure-fl/` fails to fetch build requirements due to restricted networking, ensure the package already shows up in `pip list` from within the venv. The editable install only needs to succeed once per environment.
