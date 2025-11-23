# Enable SuperNode Authentication (Flower 1.23+) — Coding Agent Instructions

## Goal

Remove the warning:
“SuperNode authentication is disabled. The SuperLink will accept connections from any SuperNode.”
by enabling CLI-managed SuperNode authentication and registering allowed nodes.

Reference: Flower “Authenticate SuperNodes” guide + 1.23 changelog. :contentReference[oaicite:2]{index=2}

---

## Phase 0 — Preconditions

- TLS already works between SuperLink and SuperNodes.
- Your federation config includes `root-certificates = "./certificates/ca/ca.crt"`.
- SuperLink ports:
  - Control API: 9093
  - Fleet API: 9092
- You can already run a TLS federation successfully.

Expected: running SuperLink currently shows the auth-disabled warning.

---

## Phase 1 — Create auth keypairs (EC keys)

Flower requires unique EC keypairs per SuperNode for authentication. :contentReference[oaicite:3]{index=3}

### Step 1.1: Create keys directory

Run:

```bash
mkdir -p flower-secure-fl/keys
````

Expected result:

- Directory `flower-secure-fl/keys/` exists.

### Step 1.2: Generate SuperNode keypair #1

Run:

```bash
openssl ecparam -name prime256v1 -genkey -noout -out flower-secure-fl/keys/supernode1.key
openssl ec -in flower-secure-fl/keys/supernode1.key -pubout -out flower-secure-fl/keys/supernode1.pub
```

Expected result:

- Files exist:

  - `keys/supernode1.key` (private)
  - `keys/supernode1.pub` (public)

Verify:

```bash
openssl ec -in flower-secure-fl/keys/supernode1.key -check -noout
```

Expected output includes:

```
EC key ok
```

### Step 1.3: Generate SuperNode keypair #2

Run:

```bash
openssl ecparam -name prime256v1 -genkey -noout -out flower-secure-fl/keys/supernode2.key
openssl ec -in flower-secure-fl/keys/supernode2.key -pubout -out flower-secure-fl/keys/supernode2.pub
```

Expected result:

- Files exist:

  - `keys/supernode2.key`
  - `keys/supernode2.pub`

Verify:

```bash
openssl ec -in flower-secure-fl/keys/supernode2.key -check -noout
```

Expected:

```
EC key ok
```

---

## Phase 2 — Restart SuperLink with auth enabled

CLI-managed auth is enabled by adding `--enable-supernode-auth` to SuperLink. ([Flower][1])

### Step 2.1: Stop current SuperLink

Agent should stop the running SuperLink terminal/process (Ctrl+C).

Expected:

- SuperLink exits cleanly.

### Step 2.2: Start SuperLink with TLS + auth

From project root, run:

```bash
flower-superlink \
  --ssl-ca-certfile certificates/ca/ca.crt \
  --ssl-certfile certificates/superlink/superlink.crt \
  --ssl-keyfile certificates/superlink/superlink.key \
  --enable-supernode-auth
```

Expected log change:

- You **should NOT** see the old warning anymore.
- You **should** see something like:

  ```
  INFO: SuperNode authentication enabled
  ```

If old warning still appears → auth flag not applied.

---

## Phase 3 — Register SuperNodes with SuperLink (whitelist)

In Flower 1.23+, registration is done via CLI and stored in SuperLink’s whitelist. ([Flower][1])

### Step 3.1: Register SuperNode #1 public key

Run:

```bash
flwr supernode register flower-secure-fl/keys/supernode1.pub . remote-federation
```

Expected output:

- A confirmation message, e.g.:

  ```
  Successfully registered SuperNode public key
  ```

### Step 3.2: Register SuperNode #2 public key

Run:

```bash
flwr supernode register flower-secure-fl/keys/supernode2.pub . remote-federation
```

Expected output:

- Same success confirmation.

### Step 3.3: List registered SuperNodes

Run:

```bash
flwr supernode list . remote-federation
```

Expected output:

- Two entries shown (IDs may be generated/derived).
- Status can be “registered/offline” before connection.

If list is empty → registration failed.

---

## Phase 4 — Start SuperNodes using their private keys

SuperNodes must present their private key when connecting to an auth-enabled SuperLink. ([Flower][1])
Note: In 1.23, public-key flag may be optional/derived, but private-key flag is required. ([Flower][2])

### Step 4.1: Start SuperNode #1 with auth

Run:

```bash
flower-supernode \
  --root-certificates ./certificates/ca/ca.crt \
  --superlink 127.0.0.1:9092 \
  --clientappio-api-address 0.0.0.0:9095 \
  --node-config="partition-id=0 num-partitions=2" \
  --auth-supernode-private-key flower-secure-fl/keys/supernode1.key
```

Expected logs:

```
INFO: TLS enabled
INFO: SuperNode authentication enabled
INFO: Connected to SuperLink
```

If you see UNAUTHENTICATED errors → key not registered or wrong key.

### Step 4.2: Start SuperNode #2 with auth

Run:

```bash
flower-supernode \
  --root-certificates ./certificates/ca/ca.crt \
  --superlink 127.0.0.1:9092 \
  --clientappio-api-address 0.0.0.0:9096 \
  --node-config="partition-id=1 num-partitions=2" \
  --auth-supernode-private-key flower-secure-fl/keys/supernode2.key
```

Expected logs mirror node #1.

---

## Phase 5 — Verify auth is enforced

### Step 5.1: Check SuperLink no longer warns

SuperLink startup log should NOT include:

```
SuperNode authentication is disabled...
```

Expected: no such warning.

### Step 5.2: Confirm nodes connect and are “online”

Run:

```bash
flwr supernode list . remote-federation
```

Expected:

- both nodes show status “online/connected”.

### Step 5.3: Negative test (optional)

Try starting a SuperNode **without** a registered key:

```bash
openssl ecparam -name prime256v1 -genkey -noout -out /tmp/bad.key
flower-supernode \
  --root-certificates ./certificates/ca/ca.crt \
  --superlink 127.0.0.1:9092 \
  --auth-supernode-private-key /tmp/bad.key
```

Expected:

- Connection is rejected with UNAUTHENTICATED / not registered.

If it connects → auth not actually enabled.

---

## Phase 6 — Run secure federation again

Run:

```bash
flwr run . remote-federation --stream
```

Expected:

- rounds proceed normally
- SuperLink logs show only registered node_ids participating
- run finishes successfully

---

## Completion Criteria

- SuperLink starts with TLS + `--enable-supernode-auth`.
- Auth disabled warning is gone.
- `flwr supernode list` shows only registered nodes online.
- Unregistered nodes are rejected.
- Secure run completes.

```
