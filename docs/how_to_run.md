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

## 1. Start the TLS-enabled, auth-enforced SuperLink

> **Quick start:** Run the helper script (`./scripts/run_secure_federation.sh`) from the repo root to automatically perform steps 1–4. The script launches SuperLink, re-registers the two SuperNode keys, starts both authenticated SuperNodes, and then runs `flwr run . remote-federation --stream`. Skip the manual commands below if you use the script.

From `flower-secure-fl/`, start SuperLink with TLS **and** SuperNode authentication enabled (assumes you already generated SSH-format keys under `./keys/` and registered their `.pub` files via `flwr supernode register …`):

```bash
flower-superlink \
  --ssl-ca-certfile ./certificates/ca/ca.crt \
  --ssl-certfile ./certificates/superlink/superlink.crt \
  --ssl-keyfile ./certificates/superlink/superlink.key \
  --enable-supernode-auth
```

Expected log lines:
```
INFO: Starting Flower SuperLink
INFO: SuperNode authentication enabled
INFO: Flower Deployment Runtime: Starting Control API on 0.0.0.0:9093
INFO: Flower Deployment Runtime: Starting Fleet API (gRPC-rere) on 0.0.0.0:9092
INFO: Flower Deployment Runtime: Starting ServerAppIo API on 0.0.0.0:9091
```

## 2. Register SuperNodes with SuperLink

Every time you restart SuperLink, you must re-register the SSH-format public keys that each SuperNode will use:

```bash
flwr supernode register ./keys/supernode1_auth.pub . remote-federation
flwr supernode register ./keys/supernode2_auth.pub . remote-federation
```

If the keys were already present, the CLI simply reports success again. Confirm the whitelist with:

```bash
flwr supernode list . remote-federation
```

Both nodes should appear with status `registered` (they switch to `online` once the SuperNode processes connect).

## 3. Verify TLS on the Control API (optional but recommended)

```bash
cd flower-secure-fl
openssl s_client -connect 127.0.0.1:9093 -CAfile ./certificates/ca/ca.crt </dev/null
```

Look for `verify return code: 0 (ok)` and the SuperLink certificate details.

## 4. Run the secure remote federation
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

Leave the command running; SuperLink will now wait for SuperNodes to attach. When testing locally, launch the registered SuperNodes in separate terminals using their private keys (the run script mentioned above manages this automatically):

```bash
flower-supernode \
  --root-certificates ./certificates/ca/ca.crt \
  --superlink 127.0.0.1:9092 \
  --clientappio-api-address 0.0.0.0:9095 \
  --node-config "partition-id=0 num-partitions=2" \
  --auth-supernode-private-key ./keys/supernode1_auth

flower-supernode \
  --root-certificates ./certificates/ca/ca.crt \
  --superlink 127.0.0.1:9092 \
  --clientappio-api-address 0.0.0.0:9096 \
  --node-config "partition-id=1 num-partitions=2" \
  --auth-supernode-private-key ./keys/supernode2_auth
```

> Replace the key paths with whatever names you used when generating/ registering the OpenSSH-format ECDSA keys.

## 5. Run the local simulation (non-TLS fallback)
Still from `flower-secure-fl/`:

```bash
flwr run . local-simulation
```

You should see the standard three FedAvg rounds complete with aggregated metrics, confirming that the simulation configuration still works alongside the secure federation setup.

## Notes
- Always run these commands with the SuperLink process active; stop it with `Ctrl+C` or `kill <PID>` when done.
- To automate steps 1–4 locally, use `scripts/run_secure_federation.sh` (it launches the SuperLink, two authenticated SuperNodes, and then runs `flwr run . remote-federation --stream` with logs under `logs/`).
- If `pip install -e flower-secure-fl/` fails to fetch build requirements due to restricted networking, ensure the package already shows up in `pip list` from within the venv. The editable install only needs to succeed once per environment.
