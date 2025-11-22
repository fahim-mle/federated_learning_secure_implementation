## 📋 What the errors say

1. From the `openssl s_client` output:

   ```
   CONNECTED(00000003)
   40D7C184DB7E0000:error:0A00010B:SSL routines:ssl3_get_record:wrong version number:../ssl/record/ssl3_record.c:354:
   ---
   no peer certificate available
   ---
   …
   Verify return code: 0 (ok)
   ```

   This indicates your client connected to the port, but the handshake output was “wrong version number”, and “no peer certificate available”. The “Verify return code: 0” is a little misleading — it means the CA file was ok, but the TLS negotiation failed “early”.

2. From the `flwr run . remote-federation` output:

   ```
   Handshake failed with error SSL_ERROR_SSL: error:100000f7:SSL routines:OPENSSL_internal:WRONG_VERSION_NUMBER: Invalid certificate verification context
   Connection to the SuperLink is unavailable.
   ```

So both show “wrong version number” / “Invalid certificate verification context” type errors.

---

## 🧠 What “wrong version number” usually means

According to multiple sources, this error typically arises when the **server is not speaking TLS** (or is speaking an incompatible protocol) but the client expected TLS. For example:

* If the server port is serving plain HTTP but the client attempted TLS. ([Stack Overflow][1])
* If the server uses a protocol the client doesn’t support (e.g., very old SSL, or untagged connection) and the client fails to interpret the first bytes. ([feistyduck.com][2])
* If you connect to a port intended for something else (e.g., non-TLS service, or expecting STARTTLS) using full TLS handshake. ([Super User][3])

In short: **your SuperLink service is not responding with a valid TLS handshake**, so the client bails out with “wrong version number”.

---

## 🧐 Why this is happening in your case

Flower’s CLI enables TLS on the **Control API (port 9093)** and the **Fleet API (port 9092)** whenever you pass `--ssl-{ca-,}certfile`. The ServerAppIo endpoint on **9091 always stays plaintext** today. The `remote-federation` entry in your `pyproject.toml` tells `flwr run` which Control API endpoint to dial. Because it was set to `127.0.0.1:9091`, the CLI tried to perform a TLS handshake against a plaintext socket. That’s why both OpenSSL and `flwr run . remote-federation` surfaced `WRONG_VERSION_NUMBER`.

In short, nothing was wrong with the certificates—the CLI was simply pointing at the wrong port.

---

## 🛠 What to change

1. **Update `pyproject.toml`**
   ```
   [tool.flwr.federations.remote-federation]
   address = "127.0.0.1:9093"  # Control API
   root-certificates = "./certificates/ca/ca.crt"
   ```

2. **Restart SuperLink with the TLS flags**
   Keep using:
   ```bash
   flower-superlink \
     --ssl-ca-certfile ./certificates/ca/ca.crt \
     --ssl-certfile ./certificates/superlink/superlink.crt \
     --ssl-keyfile ./certificates/superlink/superlink.key
   ```
   The logs should now mention `Control API on 0.0.0.0:9093` and `Fleet API ... 0.0.0.0:9092`.

3. **Verify the TLS socket on the Control API**
   ```bash
   openssl s_client -connect 127.0.0.1:9093 -CAfile ./certificates/ca/ca.crt </dev/null
   ```
   You should see `verify return code: 0 (ok)` plus the SuperLink certificate/issuer info.

4. **Run the remote federation again**
   ```bash
   flwr run . remote-federation
   ```
   Expected CLI output:
   ```
   Loading project configuration...
   Success
   🎊 Successfully started run <RUN_ID>
   ```
   At this point the Control API will accept TLS connections and the run will wait for SuperNodes to attach.

---

## ✅ Short answer: What’s causing your error?

Pointing `remote-federation.address` at `127.0.0.1:9091` forces the CLI to perform a TLS handshake against a plaintext ServerAppIo socket. Use the Control API endpoint `127.0.0.1:9093` (with the same certificates) instead, and the “wrong version number”/“invalid certificate verification context” issues disappear.
