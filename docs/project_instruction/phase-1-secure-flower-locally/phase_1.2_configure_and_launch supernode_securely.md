# Launch & Verify Two SuperNodes with TLS for Secure Flower Simulation

## Prerequisites

- `flower-superlink` is running with TLS flags, listening at address `127.0.0.1:9093` (Control API) and clients connect via SuperLink fleet port (9091/9092) as configured.
- Certificate directory exists at `flower-secure-fl/certificates/` with valid `ca/ca.crt`, `superlink/superlink.crt`, and `supernodes/` directory prepared.
- `pyproject.toml` is updated to point `remote-federation` address to `127.0.0.1:9093` and `root-certificates = "./certificates/ca/ca.crt"`.

> **Working directory:** Unless stated otherwise, run every command from the `flower-secure-fl/` directory so that relative paths like `./certificates/...` resolve correctly. The Flower CLI installs console scripts (`flower-superlink`, `flower-supernode`, `flwr`) into your virtual environment, so make sure the venv is activated (or on your `PATH`) before running the commands below.

---

## Step 1: Launch SuperNode #1

**Command:**

```bash
flower-supernode \
  --root-certificates ./certificates/ca/ca.crt \
  --superlink 127.0.0.1:9092 \
  --clientappio-api-address 0.0.0.0:9095 \
  --node-config="partition-id=0 num-partitions=2"
````

**Expected result:**

- Terminal displays something like:

  ```
  INFO: SuperNode starting...
  INFO: TLS enabled
  INFO: Connecting to SuperLink at 127.0.0.1:9093
  INFO: Root certificates: flower-secure-fl/certificates/ca/ca.crt
  INFO: Node-config: partition-id=0 num-partitions=2
  ```

- No handshake errors, no “cannot verify peer” errors.
- After a short moment, the SuperLink log should show:

  ```
  INFO: New SuperNode connected: Node-ID 12345
  ```

  (or similar)

---

## Step 2: Launch SuperNode #2

**Command:**

```bash
flower-supernode \
  --root-certificates ./certificates/ca/ca.crt \
  --superlink 127.0.0.1:9092 \
  --clientappio-api-address 0.0.0.0:9096 \
  --node-config="partition-id=1 num-partitions=2"
```

**Expected result:**

- Similar logs as Step 1 with partition-id=1.
- SuperLink log again confirms a second node connected.

---

## Step 3: Verify both nodes are connected

**Command (on SuperLink terminal):**
Check for logs from SuperLink saying:

```
Waiting for nodes to connect: 2 connected (minimum required: 2).
```

Or run via CLI:

```bash
flwr list . remote-federation
```

**Expected output:**

```
Node-ID │ Status    │ Elapsed
12345   │ online    │ 00:00:10
67890   │ online    │ 00:00:08
```

Both nodes show status `online`.

---

## Step 4: Start the federated learning run

**Command (from project root):**

```bash
flwr run . remote-federation --stream
```

**Expected result:**

- Logs print:

  ```
  [ServerApp] Starting round 1/3
  [Client 0] fit() called
  [Client 1] fit() called
  …
  [ServerApp] Finished round 3/3
  🎉 Run completed successfully
  ```

- No errors about “Waiting for nodes” anymore.
- Exit code 0 (successful run).

---

## Step 5: Validate results

**Commands:**

```bash
flwr list . remote-federation
```

Output should include the run with status `finished`.
You can also pull artifacts:

```bash
flwr pull . remote-federation --run-id <run-id>
```

**Expected result:**

- Downloaded folder with model weights, metrics file.
- Metrics show training completed (e.g., loss decreased, accuracy improved).

---

## ✅ End-to-end success criteria

- Two SuperNode processes running and connected.
- SuperLink shows “nodes connected (minimum required: 2)”.
- `flwr run . remote-federation --stream` executes rounds without errors.
- CLI `flwr list` shows run status = `finished`.
- Artifacts available after `flwr pull`.

```
