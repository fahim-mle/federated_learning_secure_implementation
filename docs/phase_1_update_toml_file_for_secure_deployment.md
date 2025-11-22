**File:** `UPDATE-pyproject-TLS.md`

````markdown
# Update `pyproject.toml` for TLS-enabled SuperLink Federation
**Based on:**
- Your current `pyproject.toml`
- Flower framework documentation: [Configure `pyproject.toml`](https://flower.ai/docs/framework/main/zh_Hans/how-to-configure-pyproject-toml.html)
- Flower TLS guide: [Enable TLS for Secure Connections](https://flower.ai/docs/framework/main/fr/docker/enable-tls.html)

---

## 1. Backup existing file
**Instruction:**
- Copy the current file:
  ```bash
  cp pyproject.toml pyproject.toml.bak
```

**Expected result:**

* File `pyproject.toml.bak` exists in the same directory.
* No errors during copy.

---

## 2. Locate and update the `[tool.flwr.federations.remote-federation]` section

**Instruction:**

* Open `pyproject.toml`.
* Find:

  ```toml
  [tool.flwr.federations.remote-federation]
  address = "<SUPERLINK-ADDRESS>:<PORT>"
  insecure = true  # Remove this line to enable TLS
  # root-certificates = "<PATH/TO/ca.crt>"
  ```

* Update as follows:

  ```toml
  [tool.flwr.federations.remote-federation]
  address = "127.0.0.1:9093"
  root-certificates = "./certificates/ca/ca.crt"
  ```

* **Remove** or **comment out** the `insecure = true` line.
* Ensure no duplicate `remote-federation` section exists.

**Expected result:**

* The section now reads exactly as above.
* `address` uses `127.0.0.1:9093` (the SuperLink Control API, or your intended address).
* `root-certificates` is present and correct relative path.
* `insecure = true` line is removed or commented.

---

## 3. Validate syntax for `[tool.flwr.federations]` block

**Instruction:**

* Ensure the `[tool.flwr.federations]` block includes:

  ```toml
  default = "local-simulation"
  ```

* Confirm other federation sections (e.g. `local-simulation`) are present and valid.
* Use a TOML validator or just visually inspect.

**Expected result:**

* No syntax errors (e.g., missing `]`, wrong key names).
* `[tool.flwr.federations.local-simulation]` section still exists with `options.num-supernodes = 10`.
* `default` federation remains “local-simulation”.

---

## 4. Save and install package in editable mode

**Instruction:**
Run (in your active virtual environment):

```bash
pip install --upgrade pip setuptools
pip install -e .
```

**Expected result:**

* No installation errors.
* In `pip list`, you see `flower-secure-fl 1.0.0`.
* `flwr --version` prints something like `1.23.0`.

---

## 5. Start SuperLink with TLS enabled

**Instruction:**
From project root, run:

```bash
flower-superlink \
  --ssl-ca-certfile certificates/ca/ca.crt \
  --ssl-certfile certificates/superlink/superlink.crt \
  --ssl-keyfile certificates/superlink/superlink.key
```

**Expected result:**

* Logs include:

  ```
  INFO: Starting Flower SuperLink
  INFO: Using CA certificate: certificates/ca/ca.crt
  INFO: Using certificate: certificates/superlink/superlink.crt
  INFO: Using private key: certificates/superlink/superlink.key
  INFO: Flower Deployment Runtime: Starting Control API on 0.0.0.0:9093
  INFO: Flower Deployment Runtime: Starting Fleet API (gRPC-rere) on 0.0.0.0:9092
  INFO: Flower Deployment Runtime: Starting ServerAppIo API on 0.0.0.0:9091
  ```

* No errors like “invalid certificate” or “failed to load key”. TLS applies to the Control (9093) and Fleet (9092) endpoints; ServerAppIo (9091) currently remains plaintext.

---

## 6. Verify TLS handshake on SuperLink port

**Instruction:**
Run:

  ```bash
  openssl s_client -connect 127.0.0.1:9093 -CAfile certificates/ca/ca.crt </dev/null
  ```

**Expected result:**

* Output includes lines like:

  ```
  SSL-Handshake: TLSv1.3
  verify return code: 0 (ok)
  subject=... CN=localhost
  issuer=... CN=FlowerLocalRootCA
  ```

* No “verify error” or “certificate has expired”.

---

## 7. Document changes in README.md

**Instruction:**

* In `README.md`, append or update a section titled **“TLS-Enabled SuperLink”** with the command used in step 5.
* Example:

  ```
  ## TLS-Enabled SuperLink

  To start SuperLink with TLS:
  flower-superlink \
    --ssl-ca-certfile certificates/ca/ca.crt \
    --ssl-certfile certificates/superlink/superlink.crt \
    --ssl-keyfile certificates/superlink/superlink.key
  ```

**Expected result:**

* The README contains the new section.
* No typos in the file path or command.

---

## ✅ Final check

* `pyproject.toml` is updated correctly.
* SuperLink starts with TLS and no `--insecure` flag.
* TLS handshake succeeds (verify return code is 0).
* README reflects the update.
* You still can run `flwr run . local-simulation` to validate your simulation mode.

---

Once all the steps complete successfully, your `pyproject.toml` is properly updated for TLS on SuperLink, and you’re ready for the next phase: **Add TLS to SuperNode** or **Add SuperNode Authentication**.

```
