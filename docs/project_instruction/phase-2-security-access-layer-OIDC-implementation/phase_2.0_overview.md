# 🌐 **PHASE 2 — Secure Access Layer (SAL)**

**Goal:**
Create a secure, authenticated environment for researchers to access computation and interact with your federated learning system **without touching the Flower federation yet**.

This includes:

* Keycloak for identity & access management (IAM)
* JupyterHub for user workspaces
* nginx as public TLS gateway
* Internal CA to secure service-to-service communication
* Clean separation from Phase 1 (Flower secure core)

This Phase **does NOT** include OIDC-to-SuperLink.
(That becomes Phase 3.)

---

# 🧭 **Phase 2 — High-Level Architecture**

```
                ┌─────────────────────────────┐
                │           Internet           │
                └───────────────┬─────────────┘
                                │
                         [ Public HTTPS ]
                                │
                        ┌───────▼────────┐
                        │     nginx      │
                        └───┬────────┬───┘
                            │        │
            [Internal TLS]  │        │  [Internal TLS]
                       ┌────▼───┐   ┌─▼────────┐
                       │Keycloak│   │JupyterHub│
                       └────┬────┘   └────┬────┘
                            │             │
                      [ User Identity ]   │
                                          │
                                 [ Researcher Workspace ]
```

Everything communicates securely via TLS:

* Public TLS → nginx
* Internal TLS → Keycloak / JupyterHub

---

# 📌 **PHASE 2 — Detailed Plan & Rationale**

## **Stage 1 — Internal Security Foundation**

The services must trust each other before any OIDC or proxies work.

### **1.1 Internal Certificate Authority**

Create a CA dedicated to Phase 2.

### **1.2 Issue TLS certificates**

* `keycloak.internal`
* `jupyterhub.internal`

**Why first?**
Because both Keycloak and JupyterHub will run on HTTPS-only on internal interfaces.

---

## **Stage 2 — Identity Layer (Keycloak)**

This is the foundation for authentication.

### **2.1 Install Keycloak (Ubuntu 24.04)**

Bare-metal installation under `/opt/keycloak`.

### **2.2 Configure Keycloak with internal TLS**

Use certs from Stage 1.

### **2.3 Create Keycloak Realm**

Example: `researcher-access`

### **2.4 Create OIDC Client for JupyterHub**

With:

* Authorization Code Flow
* Groups in ID token
* Redirect URIs for nginx→JHub

### **2.5 Create groups & roles**

* `researcher`
* `admin`

### **2.6 Create initial test user(s)**

### **2.7 Verify Keycloak (internal-only)**

Browser → internal URL
Login → works
Groups → applied

**Why this stage now?**
JupyterHub cannot be configured without these values.

---

## **Stage 3 — Researcher Workspace Layer (JupyterHub)**

### **3.1 Install JupyterHub**

Bare-metal using Python venv.

### **3.2 Install configurable-http-proxy**

Required for Hub routing.

### **3.3 Install DockerSpawner**

Even if not using Docker yet, we prepare for Phase 4+.

### **3.4 Create JupyterHub config**

* Bind only to internal address
* Add internal TLS
* Add OAuth via Keycloak
* Restrict users to the `researcher` group
* Admin = `admin` group

### **3.5 Create workspace directory**

`secure-access-layer/jupyterhub/workspace/`

### **3.6 Test OAuth login locally**

Local browser → internal JHub → redirects to Keycloak → returns → creates session.

**Why here?**
We need JHub fully working internally before exposing it through nginx.

---

## **Stage 4 — Public Access Gateway (nginx)**

### **4.1 Install nginx**

Bare-metal through apt.

### **4.2 Configure Let’s Encrypt or public TLS certificates**

Domains:

* `keycloak.<your-domain>`
* `hub.<your-domain>` (or similar)

### **4.3 Write nginx reverse proxy configs**

* `https://keycloak.<domain>` → internal `keycloak.internal:8443`
* `https://hub.<domain>` → internal `jupyterhub.internal:8000`
* Add security headers & proxy forwarding

### **4.4 Test external flow**

Follow full chain:
Browser → nginx → Keycloak → JupyterHub → notebook session

### **4.5 Cleanup / disable access logs if required**

(Optional)
Useful for production but not essential for MVP.

---

## **Stage 5 — Stabilization & Hardening**

Everything must be robust before Phase 3.

### **5.1 Create systemd services**

For:

* Keycloak
* JupyterHub
* nginx

### **5.2 Verify auto-start & crash recovery**

### **5.3 Add health checks**

### **5.4 Run load test (small scale)**

Test 2–3 simultaneous researcher logins.

---

# 📘 **PHASE 2 — Task List (Coding Agent Ready)**

Here’s a precise list your coding agent can work from.

---

## 📂 **Task Group 1: Directory & CA Setup**

1. Create `secure-access-layer/` structure
2. Implement internal CA
3. Generate certs for keycloak & jupyterhub
4. Trust CA system-wide

---

## 🔐 **Task Group 2: Keycloak Setup**

5. Install Keycloak under `/opt/keycloak`
6. Configure internal TLS
7. Create systemd service
8. Create realm `researcher-access`
9. Create client `jupyterhub-client`
10. Set redirect URIs
11. Create roles & groups
12. Create test users
13. Verify login via internal URL

---

## 📚 **Task Group 3: JupyterHub Setup**

14. Create Python venv
15. Install JupyterHub, oauthenticator, DockerSpawner
16. Install configurable-http-proxy
17. Create `jupyterhub_config.py`
18. Configure Keycloak OIDC
19. Add internal TLS
20. Create systemd service
21. Create workspace directory
22. Verify login redirect via internal address

---

## 🌐 **Task Group 4: nginx Setup**

23. Install nginx
24. Acquire public TLS certificates
25. Create vhosts for Keycloak + Hub
26. Configure reverse proxy rules
27. Test external login flow
28. Add any necessary security headers

---

## 🛠️ **Task Group 5: Stabilization**

29. Ensure all systemd services auto-start
30. Validate logs (nginx, jhub, keycloak)
31. Run small concurrency test
32. Document Phase 2 completion in docs

---

This is the full **Phase 2 Master Plan**.
It is clear, linear, dependency-aware, and simple to maintain.

---
