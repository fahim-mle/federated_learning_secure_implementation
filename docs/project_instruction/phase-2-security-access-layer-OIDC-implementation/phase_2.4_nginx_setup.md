# 🧩 TASK GROUP 4 — nginx Reverse Proxy (Secure Access Layer)

**Project root:**
`/home/ghost/workspace/internship_project/federated_learning_secure_implementation`

**SAL root:**
`/home/ghost/workspace/internship_project/federated_learning_secure_implementation/secure-access-layer`

nginx will:

* listen on **443**
* terminate HTTPS with your internal certs (for now)
* route:

  * `/` on `jupyterhub.internal` → JupyterHub internal port **8000**
  * `/` on `keycloak.internal` → Keycloak internal port **8443**

### Why this fixes your login issue

Browser sees **HTTPS 443**, Keycloak callback matches HTTPS, no mixed HTTP/HTTPS, so OIDC flow completes.

---

## ✅ Task 4.1 — Install nginx

**Agent (non-sudo):**

* prepare commands for install + enable.

**You (sudo):**

```bash
sudo apt update
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl status nginx
```

---

## ✅ Task 4.2 — Prepare nginx TLS certs (internal-use)

We’ll reuse your SAL CA to issue **nginx-facing certs** for:

* `jupyterhub.internal`
* `keycloak.internal`

### Option A (simple, recommended now)

Use the **same service certs you already generated**:

* JupyterHub cert for hub vhost
* Keycloak cert for keycloak vhost

That’s totally fine for internal dev.

**You (sudo):**

```bash
sudo mkdir -p /etc/nginx/certs

sudo cp /opt/jupyterhub/certs/jupyterhub.internal.crt /etc/nginx/certs/
sudo cp /opt/jupyterhub/certs/jupyterhub.internal.key /etc/nginx/certs/

sudo cp /opt/keycloak/certs/keycloak.internal.crt /etc/nginx/certs/
sudo cp /opt/keycloak/certs/keycloak.internal.key /etc/nginx/certs/

sudo chmod 600 /etc/nginx/certs/*.key
sudo chown root:root /etc/nginx/certs/*
```

*(Later, when you go public, nginx gets Let’s Encrypt certs instead.)*

---

## ✅ Task 4.3 — Create nginx site configs

We will create **two vhosts** under SAL, then symlink into nginx.

**Agent (non-sudo):**
Write these files **inside repo** at:

1. `$SAL_ROOT/nginx/conf.d/jupyterhub.internal.conf`

```nginx
server {
    listen 443 ssl;
    server_name jupyterhub.internal;

    ssl_certificate     /etc/nginx/certs/jupyterhub.internal.crt;
    ssl_certificate_key /etc/nginx/certs/jupyterhub.internal.key;

    # good proxy defaults
    proxy_read_timeout 3600;
    proxy_send_timeout 3600;
    client_max_body_size 50m;

    location / {
        proxy_pass http://127.0.0.1:8000;

        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;

        # websockets for Jupyter
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

2. `$SAL_ROOT/nginx/conf.d/keycloak.internal.conf`

```nginx
server {
    listen 443 ssl;
    server_name keycloak.internal;

    ssl_certificate     /etc/nginx/certs/keycloak.internal.crt;
    ssl_certificate_key /etc/nginx/certs/keycloak.internal.key;

    location / {
        proxy_pass https://127.0.0.1:8443;

        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

**Notes:**

* JHub internal = `http://localhost:8000`
* Keycloak internal = `https://localhost:8443`
* We terminate TLS at nginx but Keycloak already uses TLS too, which is fine.

---

## ✅ Task 4.4 — Enable these configs in nginx

**You (sudo):**

```bash
# copy SAL configs into nginx
sudo cp $SAL_ROOT/nginx/conf.d/*.conf /etc/nginx/conf.d/

# test config
sudo nginx -t

# reload nginx
sudo systemctl reload nginx
sudo systemctl status nginx
```

---

## ✅ Task 4.5 — Hostname resolution (local)

This is required because `.internal` isn’t public DNS.

**You (sudo):**
Edit `/etc/hosts` on **your browser machine**:

```bash
sudo nano /etc/hosts
```

Add:

```
127.0.1.1 jupyterhub.internal
127.0.1.1 keycloak.internal
```

Then verify:

```bash
ping jupyterhub.internal
ping keycloak.internal
```

---

## ✅ Task 4.6 — Final validation (the payoff)

Now browse:

### JupyterHub

```
https://jupyterhub.internal/hub/login
```

Expected:

* redirect to Keycloak
* login works
* returns to JupyterHub
* group filtering works (`researcher`, `admin`)

### Keycloak

```
https://keycloak.internal/
```

Expected:

* admin console loads
* no TLS warnings (SAL CA trusted)

---

## ✅ Task 4.7 — Create automation script

**Agent (non-sudo):**
Write:
`$SAL_ROOT/scripts/install_nginx_proxy.sh`

Script should automate:

* copying certs into `/etc/nginx/certs/`
* copying vhosts into `/etc/nginx/conf.d/`
* nginx test + reload

**But NOT**:

* `apt install nginx`
* editing `/etc/hosts`
  (those stay manual)

---

# 🎯 Expected outcome after Task Group 4

You will be able to access **both services without ports**:

* `https://jupyterhub.internal/`
* `https://keycloak.internal/`

Your OIDC flow will finally work end-to-end.
