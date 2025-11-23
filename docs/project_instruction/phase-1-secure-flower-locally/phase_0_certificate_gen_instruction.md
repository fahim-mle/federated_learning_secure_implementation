# **“Generate TLS Certificates for the Local, Secure Flower Simulation”**

### *– includes exact commands, folder layout, and expected outputs –*

---

## 🔧 **Phase 1 — Create the certificate directory**

### **Instruction to agent**

Create this directory structure inside the Flower project:

```txt
flower-secure-fl/
    certificates/
        ca/
        superlink/
        supernodes/
```

### **Expected result**

* A directory named `certificates` exists directly under `flower-secure-fl/` (this location matches Flower docs and keeps certs local to the app).
* Subfolders `ca`, `superlink`, `supernodes` exist and are empty.

If missing, the agent must retry creation.

---

## 🔧 **Phase 2 — Generate CA (Certificate Authority)**

*(Used to sign SuperLink + SuperNode certificates)*

### **Instruction to agent**

Run:

```bash
cd flower-secure-fl/certificates/ca
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 365 \
    -subj "/C=AU/ST=Local/L=Local/O=FlowerLocalCA/OU=Development/CN=FlowerLocalRootCA" \
    -out ca.crt
```

### **Expected result**

Files inside `certificates/ca/`:

```
ca.key   (size ~3–4 KB, private RSA key)
ca.crt   (size ~1–2 KB, X.509 certificate)
```

Agent should verify:

* Running `openssl x509 -in ca.crt -noout -subject` prints CN=FlowerLocalRootCA
* No error messages.

---

# 🔧 **Phase 3 — Generate SuperLink keypair and certificate signing request (CSR)**

### **Instruction to agent**

Run:

```bash
cd flower-secure-fl/certificates/superlink
openssl genrsa -out superlink.key 4096

# create CSR with SAN for local testing
openssl req -new -key superlink.key -out superlink.csr \
  -subj "/C=AU/ST=Local/L=Local/O=FlowerSuperLink/OU=Dev/CN=localhost"
```

### **Expected result**

Files in `certificates/superlink/`:

```
superlink.key  (~3–4 KB)
superlink.csr  (~1–2 KB)
```

Agent verifies by running:

```bash
openssl req -in superlink.csr -noout -subject
```

Should display CN=localhost.

---

# 🔧 **Phase 4 — Sign the SuperLink certificate using CA**

### **Instruction to agent**

Run:

```bash
cd flower-secure-fl/certificates
openssl x509 -req \
  -in superlink/superlink.csr \
  -CA ca/ca.crt -CAkey ca/ca.key -CAcreateserial \
  -out superlink/superlink.crt \
  -days 365 -sha256 \
  -extfile <(printf "subjectAltName=DNS:localhost,IP:127.0.0.1")
```

### **Expected result**

Files now include:

```txt
superlink.crt  (~1–2 KB)
ca.srl         (serial file auto-generated)
```

Agent validates:

```bash
openssl x509 -in certificates/superlink/superlink.crt -noout -text
```

Must show:

* **Issuer:** FlowerLocalRootCA (from your CA)
* **X509v3 SAN:** DNS:localhost, IP Address:127.0.0.1

If not present, the agent must regenerate.

---

# 🔧 **Phase 5 — Generate SuperNode keypairs + certificates**

### **Instruction to agent**

For now generate **one** SuperNode certificate.
Later you can scale to N nodes.

Run:

```bash
cd flower-secure-fl/certificates/supernodes

openssl genrsa -out supernode1.key 4096

openssl req -new -key supernode1.key \
  -out supernode1.csr \
  -subj "/C=AU/ST=Local/L=Local/O=FlowerSuperNode/OU=Dev/CN=supernode1"
```

Sign using CA:

```bash
openssl x509 -req \
  -in supernode1.csr \
  -CA ../ca/ca.crt -CAkey ../ca/ca.key -CAcreateserial \
  -out supernode1.crt \
  -days 365 -sha256 \
  -extfile <(printf "subjectAltName=DNS:supernode1,IP:127.0.0.1")
```

### **Expected result**

Directory contains:

```
supernode1.key     (private key)
supernode1.csr
supernode1.crt
```

Agent verifies with:

```
openssl x509 -in supernodes/supernode1.crt -noout -text
```

Look for:

* Issuer = FlowerLocalRootCA
* SAN = DNS:supernode1

---

# 🔧 **Phase 6 — Create “trust bundles” required by Flower**

### **Instruction to agent**

Create a file:

```
flower-secure-fl/certificates/superlink/trusted_supernodes.csv
```

With content:

```
supernodes/supernode1.crt
```

*(Flower allows CSV list of client public keys or certs depending on mode. We'll extend later.)*

### **Expected result**

* File exists and includes **exactly one line**, no broken paths.
* Agent verifies its presence.

---

# 🔧 **Phase 7 — Verification script for the agent**

### **Instruction to agent**

Run:

```bash
# Validate all certificate chains
openssl verify -CAfile certificates/ca/ca.crt \
    certificates/superlink/superlink.crt

openssl verify -CAfile certificates/ca/ca.crt \
    certificates/supernodes/supernode1.crt
```

### **Expected output**

```
certificates/superlink/superlink.crt: OK
certificates/supernodes/supernode1.crt: OK
```

If ANY output contains “unable to verify”, “depth=0”, or “self-signed”, the agent must repair the chain.

---

# 🔧 **Phase 8 — Expected Final Directory Tree**

The coding agent should verify it matches EXACTLY:

```
flower-secure-fl/
└── certificates/
    ├── ca/
    │   ├── ca.key
    │   ├── ca.crt
    │   └── ca.srl
    ├── superlink/
    │   ├── superlink.key
    │   ├── superlink.csr
    │   ├── superlink.crt
    │   └── trusted_supernodes.csv
    └── supernodes/
        ├── supernode1.key
        ├── supernode1.csr
        └── supernode1.crt
```

This structure aligns with the SuperLink/SuperNode cert directories described in the operations manual (e.g. `/etc/flwr/superlink/certs/server.key`, `/etc/flwr/supernode/certs/client_credentials_n` etc.)

---
