# 🔒 Instruction Set: Secure Flower Simulation (SuperLink TLS First)

**Filename for agent to save:** `SECURE-FLOWER-SUPERLINK.md`

````markdown
# Secure Flower Simulation – SuperLink TLS Setup
## Objective
Configure and run your Flower app in **secure mode** by enabling TLS on the SuperLink, using your updated `pyproject.toml`.

## Prerequisites
- You have a functioning Python virtual environment.
- The `pyproject.toml` file has been updated for remote federation (see your uploaded version).
- Directory `flower-secure-fl/certificates/` exists with `ca/`, `superlink/`, etc.
- Your server and client app modules already work in simulation mode (`local-simulation`).

## Step 1: Confirm TLS certificate files exist
1. In the root of your project, run:
   ```bash
   ls flower-secure-fl/certificates/ca/ca.crt flower-secure-fl/certificates/ca/ca.key
   ls flower-secure-fl/certificates/superlink/superlink.crt flower-secure-fl/certificates/superlink/superlink.key
````

2. **Expected result:**

   ```txt
   flower-secure-fl/certificates/ca/ca.crt
   flower-secure-fl/certificates/ca/ca.key
   flower-secure-fl/certificates/superlink/superlink.crt
   flower-secure-fl/certificates/superlink/superlink.key
   ```

   No “No such file or directory” errors.

3. Check certificate validity:

   ```bash
   openssl x509 -in flower-secure-fl/certificates/superlink/superlink.crt -noout -subject -issuer -dates
   ```

   **Expected output sample:**

   ```
   subject= /C=AU/ST=Local/L=Local/O=FlowerSuperLink/OU=Dev/CN=localhost
   issuer= /C=AU/ST=Local/L=Local/O=FlowerLocalCA/OU=Dev/CN=FlowerLocalRootCA
   notBefore=Nov 23 00:00:00 2025 GMT
   notAfter=Nov 22 00:00:00 2026 GMT
   ```

   If issuer ≠ CA’s CN or certificate expired → fix certificate.

## Step 2: Update `pyproject.toml` for remote-TLS federation

1. Open `flower-secure-fl/pyproject.toml`.
2. Locate the section:

   ```toml
   [tool.flwr.federations.remote-federation]
   address = "127.0.0.1:9093"
   root-certificates = "./certificates/ca/ca.crt"
   ```

3. Ensure the file does **not** include `insecure = true`. If present, remove it or change to `insecure = false`.
4. Save the file.

**Expected result:**

* `[tool.flwr.federations.remote-federation]` appears exactly once.
* `address` is set to `127.0.0.1:9093` (the SuperLink Control API, or your actual host:port).
* `root-certificates` path is `./certificates/ca/ca.crt`.
* No extraneous keys like `insecure = true`.

## Step 3: Install the updated project in editable mode

Run:

```bash
pip install --upgrade pip setuptools
pip install -e flower-secure-fl/
```

**Expected result:**

* No installation errors.
* Running `pip list | grep flower-secure-fl` shows `flower-secure-fl 1.0.0`.
* Running `flwr --version` shows something like `1.23.0` (matching your dependency version).

## Step 4: Start SuperLink with TLS settings

In a new terminal with the venv activated, run from project root:

```bash
flower-superlink \
  --ssl-ca-certfile ./certificates/ca/ca.crt \
  --ssl-certfile ./certificates/superlink/superlink.crt \
  --ssl-keyfile ./certificates/superlink/superlink.key
```

**Expected output:**

```
INFO: Starting Flower SuperLink
INFO: Using CA certificate: flower-secure-fl/certificates/ca/ca.crt
INFO: Using certificate: flower-secure-fl/certificates/superlink/superlink.crt
INFO: Using private key: flower-secure-fl/certificates/superlink/superlink.key
INFO: Flower Deployment Runtime: Starting Control API on 0.0.0.0:9093
INFO: Flower Deployment Runtime: Starting Fleet API (gRPC-rere) on 0.0.0.0:9092
INFO: Flower Deployment Runtime: Starting ServerAppIo API on 0.0.0.0:9091
```

> **Note:** TLS currently applies to the Control API (9093) and Fleet API (9092). The ServerAppIo socket on 9091 remains plaintext; that's expected.

No errors like “invalid certificate” or “failed to load key”.

## Step 5: Verify TLS endpoint with `openssl s_client`

In another terminal:

```bash
openssl s_client -connect 127.0.0.1:9093 -CAfile ./certificates/ca/ca.crt </dev/null
```

**Expected key portions:**

```
SSL handshake has read ...
verify return code: 0 (ok)
---
subject= /C=AU/ST=Local/L=Local/O=FlowerSuperLink/OU=Dev/CN=localhost
issuer= /C=AU/ST=Local/L=Local/O=FlowerLocalCA/OU=Dev/CN=FlowerLocalRootCA
```

If `Verify return code` ≠ 0 → TLS not properly configured.

## Step 6: Run secure simulation using remote-federation

In the project root:

```bash
flwr run . remote-federation
```

**Expected output:**

```
Loading project configuration...
Success
🎊 Successfully started run <RUN_ID>
```

No TLS/handshake errors should be printed. Once the run is scheduled, attach SuperNodes (for example by running `flower-supernode`) so the Control API stops waiting for participants.

## Step 7: Validate fallback to local simulation still works

(Optional but recommended):

```bash
flwr run . local-simulation
```

**Expected result:**
Same simulation run as before (non-TLS), confirming your setup still supports both modes.

## Step 8: Update `README.md` documentation

Append a section under `flower-secure-fl/README.md`:

```markdown
### TLS-Enabled SuperLink
To start the SuperLink with TLS:
```

```
flower-superlink \
  --ssl-ca-certfile certificates/ca/ca.crt \
  --ssl-certfile certificates/superlink/superlink.crt \
  --ssl-keyfile certificates/superlink/superlink.key
```

```
**Expected result:**
README includes that section verbatim. Paths are correct.

---

## ✅ Final Verification Checklist
- [x] Certificate files exist and show correct subject + issuer
- [x] `pyproject.toml` remote-federation section updated correctly
- [ ] Package installs correctly (`pip install -e ...`)
- [x] SuperLink starts with TLS logs
- [x] `openssl s_client` confirms handshake `Verify return code: 0 (ok)`
- [x] `flwr run . remote-federation` succeeds without errors
- [x] `flwr run . local-simulation` still succeeds
- [x] README updated with TLS command snippet

---
