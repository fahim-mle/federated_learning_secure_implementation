# 🧩 **TASK GROUP 2 — KEYCLOAK SETUP**

This is the identity layer of the Secure Access Layer (SAL).
Everything happens **inside the project directory**, and **Keycloak itself will run on the host OS**, not inside the repo.

The coding agent MUST NOT install Keycloak into the repo — it must install it under `/opt/keycloak`.

---

# 📍 **Absolute Paths (no confusion allowed)**

To avoid hallucinations and directory mistakes, here are all roots:

```
# Your project root (SAL lives here)
PROJECT_ROOT="/home/ghost/workspace/internship_project/federated_learning_secure_implementation"

# Secure Access Layer root
SAL_ROOT="$PROJECT_ROOT/secure-access-layer"

# Service directories
KEYCLOAK_SAL="$SAL_ROOT/keycloak"
JUPYTERHUB_SAL="$SAL_ROOT/jupyterhub"
NGINX_SAL="$SAL_ROOT/nginx"
```

Certificates already exist at:

```
$SAL_ROOT/keycloak/certs/keycloak.internal.crt
$SAL_ROOT/keycloak/certs/keycloak.internal.key
$SAL_ROOT/jupyterhub/certs/jupyterhub.internal.crt
$SAL_ROOT/jupyterhub/certs/jupyterhub.internal.key
```

---

# 🚀 **TASK GROUP 2 — DETAILED IMPLEMENTATION PLAN**

We break this into 7 sub-tasks:

1. Install system dependencies
2. Create Keycloak system user
3. Install Keycloak under `/opt/keycloak`
4. Configure Keycloak to use your internal TLS certs
5. Create Keycloak systemd service file
6. Start + verify service is reachable at `https://keycloak.internal:8443`
7. Create Keycloak realm, groups, roles, client (JupyterHub OIDC)

Your coding agent will receive **precise instructions** to avoid any directory or context confusion.

---

# 🧠 **TASK 2.1 — Install Keycloak Dependencies**

### Agent Instructions

Install the required packages:

* JDK 21 (runtime + tools)
* unzip
* curl
* systemd utilities

**Command list (do not run commands that require sudo unless explicitly allowed):**

```bash
sudo apt update
sudo apt install -y openjdk-21-jre openjdk-21-jdk unzip curl
```

---

# 🧠 **TASK 2.2 — Create Keycloak System User**

### Agent Instructions

Create a non-login system user for Keycloak:

```bash
sudo useradd --system --shell /usr/sbin/nologin --home /opt/keycloak keycloak
```

Ensure it has permission to read the SAL certificate files later.

---

# 🧠 **TASK 2.3 — Install Keycloak in `/opt/keycloak`**

### Version Recommendation

**Keycloak 26.4.5** (stable + long-term support)

### Agent Instructions

1. Download Keycloak:

```bash
cd /tmp
curl -L -o keycloak.zip \
https://github.com/keycloak/keycloak/releases/download/26.4.5/keycloak-26.4.5.zip
```

2. Create installation dir:

```bash
sudo mkdir -p /opt/keycloak
```

3. Extract:

```bash
sudo unzip keycloak.zip -d /opt/keycloak
```

This produces:

```
/opt/keycloak/keycloak-26.4.5/
```

4. Fix ownership:

```bash
sudo chown -R keycloak:keycloak /opt/keycloak
```

---

# 🧠 **TASK 2.4 — Configure Internal TLS (Critical)**

You already generated TLS certs under SAL:

```
$SAL_ROOT/keycloak/certs/keycloak.internal.crt
$SAL_ROOT/keycloak/certs/keycloak.internal.key
```

### Agent Instructions

1. Create a cert directory for Keycloak runtime:

```bash
sudo mkdir -p /opt/keycloak/certs
sudo cp "$SAL_ROOT/keycloak/certs/keycloak.internal.crt" /opt/keycloak/certs/
sudo cp "$SAL_ROOT/keycloak/certs/keycloak.internal.key" /opt/keycloak/certs/
sudo chown -R keycloak:keycloak /opt/keycloak/certs
```

2. Create a config file:

```
/opt/keycloak/conf/keycloak.conf
```

### Content (agent must write exactly)

```
https-certificate-file=/opt/keycloak/certs/keycloak.internal.crt
https-certificate-key-file=/opt/keycloak/certs/keycloak.internal.key
https-port=8443
proxy=reencrypt
hostname=keycloak.internal
```

**Why these settings?**

* TLS is enabled automatically because cert files exist.
* `proxy=reencrypt` is required for nginx reverse proxy later.
* hostname must match your internal cert.

---

# 🧠 **TASK 2.5 — Create Keycloak systemd Unit**

Write to:

```
$SAL_ROOT/keycloak/systemd/keycloak.service
```

Agent must place this file there.
Later, **you** will copy it to `/etc/systemd/system/keycloak.service`.

### systemd Unit Template

```
[Unit]
Description=Keycloak Service (Secure Access Layer)
After=network.target

[Service]
User=keycloak
Group=keycloak
Type=simple
ExecStart=/opt/keycloak/keycloak/bin/kc.sh start --config-file=/opt/keycloak/conf/keycloak.conf
Restart=on-failure
Environment=KEYCLOAK_ADMIN=admin
Environment=KEYCLOAK_ADMIN_PASSWORD=admin

[Install]
WantedBy=multi-user.target
```

Notes:

* simple startup
* admin/bootstrap user defined via env
* mirrors official Keycloak recommendations

---

# 🧠 **TASK 2.6 — Start Keycloak and Verify Internal HTTPS**

### You will run

```bash
sudo cp $SAL_ROOT/keycloak/systemd/keycloak.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable keycloak
sudo systemctl start keycloak
sudo systemctl status keycloak
```

Then test from your host machine:

```
https://keycloak.internal:8443
```

Your browser must NOT show CA warnings because we installed the CA earlier.

---

# 🧠 **TASK 2.7 — Configure Keycloak Realm, Groups, OIDC Client**

This step happens from the browser UI on:

```
https://keycloak.internal:8443
```

### Realm Name

```
flower-secure-access
```

### Client Name

```
jupyterhub-client
```

### Client Config Required

* Access Type: **confidential**
* Redirect URIs:

  * `https://hub.<your-domain>/hub/oauth_callback`
* Web Origins: `*`
* Client Scopes:

  * email
  * profile
  * groups (must be enabled!)

### Create Groups

```
researcher
admin
```

### Create Roles

```
jupyter_user
jupyter_admin
```

### Assign roles → groups

* `researcher` → `jupyter_user`
* `admin` → `jupyter_user`, `jupyter_admin`

### Create test users

* test_researcher
* test_admin

## SPECIAL NOTE

⚠️ A few checks / recommended updates

Ensure certs’ SAN includes keycloak.internal — the hostname setting must fully match the certificate.

Check context path / proxy header
If nginx will forward to Keycloak, ensure X-Forwarded-For, X-Forwarded-Proto, etc. are forwarded and proxy=reencrypt is correct. Docs: when behind proxy, you may also set proxy-headers.

Production vs dev mode
Docs for 26.4 specify that production mode expects both HTTPS and hostname set. Without that you may get startup errors.

Admin bootstrap user
If you haven’t already set KEYCLOAK_ADMIN and KEYCLOAK_ADMIN_PASSWORD environment vars or via config, ensure they’re present so you can login first time.

Port binding and firewall
If you run 3244 etc, ensure port 8443 is open and keycloak.internal resolves in /etc/hosts or via DNS.

🛠 Suggested minor modification in keycloak.conf

Add the following lines (or ensure they exist) to align to latest doc:

hostname-strict=true
proxy-headers=x-forwarded

If you expect to use forwarded headers via nginx, proxy-headers=x-forwarded helps.
But only add if you’re sure nginx will pass those headers.

---

# 🟢 **NEXT STEP AFTER THIS**

Once Keycloak is running correctly, we move to:

👉 **Task Group 3 — JupyterHub Setup**
