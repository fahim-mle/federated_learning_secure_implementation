# 🧩 **Task Group 3 — JupyterHub Setup (Detailed Instruction Set)**

**Project root:**

```
/home/ghost/workspace/internship_project/federated_learning_secure_implementation
```

**Secure Access Layer root (for JupyterHub part):**

```
$SAL_ROOT = /home/ghost/workspace/internship_project/federated_learning_secure_implementation/secure-access-layer
```

We will install JupyterHub bare-metal under Ubuntu 24.04, integrate it with our already configured Keycloak (realm `flower-realm`, client `jupyterhub-client`) via OIDC, and ensure internal TLS and systemd service are ready.

---

## 📍 Task List (for coding agent + your sudo steps)

### **Task 3.1 — Install Dependencies for JupyterHub**

**Agent instructions (non-sudo):**

* Prepare list of packages: `python3-venv`, `nodejs npm`, `python3-pip`, `git`, `curl`
* Outline virtual environment path.

**Your instructions (sudo):**

```bash
sudo apt update
sudo apt install -y python3-venv python3-pip nodejs npm git curl
```

---

### **Task 3.2 — Create JupyterHub Service User & Directory**

**Agent instructions (non-sudo):**

* Define user `jupyterhub` with home `/opt/jupyterhub`
* Define workspace directory.

**Your instructions (sudo):**

```bash
sudo useradd --system --shell /usr/sbin/nologin --home /opt/jupyterhub jupyterhub
sudo mkdir -p /opt/jupyterhub
sudo chown jupyterhub:jupyterhub /opt/jupyterhub
```

---

### **Task 3.3 — Install JupyterHub into Python Virtualenv**

**Agent instructions (non-sudo):**

* Path for venv: `/opt/jupyterhub/venv`
* Packages: `jupyterhub`, `oauthenticator` (GenericOAuthenticator), `jupyterlab`.

**Your instructions (sudo):**

```bash
sudo -u jupyterhub python3 -m venv /opt/jupyterhub/venv
sudo -u jupyterhub /opt/jupyterhub/venv/bin/pip install --upgrade pip
sudo -u jupyterhub /opt/jupyterhub/venv/bin/pip install jupyterhub oauthenticator[jupyterhub] jupyterlab
```

---

### **Task 3.4 — Prepare Internal TLS for JupyterHub**

**Agent instructions (non-sudo):**

* Copy generated JupyterHub certs (`jupyterhub.internal.crt`, `.key`) from `$SAL_ROOT/jupyterhub/certs/` to `/opt/jupyterhub/certs/`

**Your instructions (sudo):**

```bash
sudo mkdir -p /opt/jupyterhub/certs
sudo cp $SAL_ROOT/jupyterhub/certs/jupyterhub.internal.crt /opt/jupyterhub/certs/
sudo cp $SAL_ROOT/jupyterhub/certs/jupyterhub.internal.key /opt/jupyterhub/certs/
sudo chown -R jupyterhub:jupyterhub /opt/jupyterhub/certs
sudo chmod 600 /opt/jupyterhub/certs/jupyterhub.internal.key
```

---

### **Task 3.5 — Create `jupyterhub_config.py`**

**Agent instructions (non-sudo):**
Generate config file at `$SAL_ROOT/jupyterhub/conf/jupyterhub_config.py` with the following template (adjust domain placeholders):

```python
c = get_config()

# Use Generic OpenID Connect via Keycloak
c.JupyterHub.authenticator_class = 'oauthenticator.generic.GenericOAuthenticator'

c.GenericOAuthenticator.client_id = 'jupyterhub-client'
c.GenericOAuthenticator.client_secret = '<KEYCLOAK_CLIENT_SECRET>'
c.GenericOAuthenticator.oauth_callback_url = 'https://jupyterhub.internal/hub/oauth_callback'

c.GenericOAuthenticator.authorize_url = 'https://keycloak.internal/realms/flower-realm/protocol/openid-connect/auth'
c.GenericOAuthenticator.token_url     = 'https://keycloak.internal/realms/flower-realm/protocol/openid-connect/token'
c.GenericOAuthenticator.userdata_url  = 'https://keycloak.internal/realms/flower-realm/protocol/openid-connect/userinfo'

c.GenericOAuthenticator.scope = ['openid', 'profile', 'email', 'groups']
c.GenericOAuthenticator.username_claim = 'preferred_username'
c.GenericOAuthenticator.allowed_groups = ['researcher', 'admin']

# TLS internal
c.ConfigurableHTTPProxy.command = ['/usr/bin/configurable-http-proxy', '--ssl-key=/opt/jupyterhub/certs/jupyterhub.internal.key', '--ssl-cert=/opt/jupyterhub/certs/jupyterhub.internal.crt']

# Basic spawning
c.Spawner.default_url = '/lab'
```

**Note:** Replace `<KEYCLOAK_CLIENT_SECRET>` with the actual secret from your Keycloak client.

---

### **Task 3.6 — Create systemd Service File for JupyterHub**

**Agent instructions (non-sudo):**
Generate `$SAL_ROOT/jupyterhub/systemd/jupyterhub.service` with content:

```ini
[Unit]
Description=JupyterHub Service (Secure Access Layer)
After=network.target

[Service]
User=jupyterhub
Group=jupyterhub
Type=simple
ExecStart=/opt/jupyterhub/venv/bin/jupyterhub -f $SAL_ROOT/jupyterhub/conf/jupyterhub_config.py
Restart=on-failure
WorkingDirectory=/opt/jupyterhub

[Install]
WantedBy=multi-user.target
```

**Your instructions (sudo):**

```bash
sudo cp $SAL_ROOT/jupyterhub/systemd/jupyterhub.service /etc/systemd/system/jupyterhub.service
sudo systemctl daemon-reload
sudo systemctl enable jupyterhub
sudo systemctl start jupyterhub
sudo systemctl status jupyterhub
```

---

### **Task 3.7 — Verify Full Flow**

**Your manual steps:**

* Ensure `jupyterhub.internal` resolves (e.g., via `/etc/hosts` → `127.0.1.1 jupyterhub.internal`)
* Browse to `https://jupyterhub.internal/hub/login`
* Click login → you should get redirected to Keycloak login page (`flower-realm`)
* Login as test user (e.g., in group `researcher`)
* After login you should reach JupyterLab interface
* Confirm that user is allowed or denied based on `allowed_groups`

---

## 🛠 Additional Notes & Web References

* Official docs for JupyterHub with GenericOAuthenticator: see “GenericOAuthenticator – OpenID Connect (Keycloak)” section. ([Zero to JupyterHub with Kubernetes][1])
* The `scope: ['openid','profile','email','groups']` is required so group membership claim is available. ([Jupyter Community Forum][2])

### 📜 `install_jupyterhub.sh` (Place under `secure-access-layer/scripts/`)

**File path:**
`/home/ghost/workspace/internship_project/federated_learning_secure_implementation/secure-access-layer/scripts/install_jupyterhub.sh`

### 🔍 What you must **modify** before running

* Replace `<REPLACE_WITH_KEYCLOAK_CLIENT_SECRET>` with the actual client secret you got from Keycloak for `jupyterhub-client`.
* Update File Path where necessary, based on the project directory.
* If your internal hostname differs from `jupyterhub.internal`, update `CALLBACK_URL` accordingly.
* If your domain will be public and not internal only, update `CALLBACK_URL` to the public domain.

---
