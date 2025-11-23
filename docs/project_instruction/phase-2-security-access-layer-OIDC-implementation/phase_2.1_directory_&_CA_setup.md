# ✅ **Task Group 1**

## **1. Directory Structure**

> **Project root:** All paths below live inside `/home/ghost/workspace/internship_project/federated_learning_secure_implementation`.

```txt
secure-access-layer/
  keycloak/{conf,certs,systemd,logs}
  jupyterhub/{conf,certs,systemd,workspace,logs}
  nginx/{conf.d,certs-public,systemd,logs}
  ca/
  scripts/
  docs/
```

## **2. Internal CA**

Files in `secure-access-layer/ca/`:

* `sal-root-ca.key`
* `sal-root-ca.crt`
* `sal-root-ca.srl`

Properties:

* RSA 4096 or ECDSA P-256
* 10-year validity
* Self-signed
* No password

## **3. Service Certs**

Paths & filenames:

### Keycloak

`secure-access-layer/keycloak/certs/`

* `keycloak.internal.key`
* `keycloak.internal.csr`
* `keycloak.internal.crt`

### JupyterHub

`secure-access-layer/jupyterhub/certs/`

* `jupyterhub.internal.key`
* `jupyterhub.internal.csr`
* `jupyterhub.internal.crt`

Properties:

* CN = service hostname
* SAN = same hostname
* Signed by `sal-root-ca`
* PEM format, no passphrase

## **4. CA Trust**

Place CA cert at:

```txt
/usr/local/share/ca-certificates/sal-root-ca.crt
sudo update-ca-certificates
```

> _Note:_ System-wide trust installation requires sudo access; run the above on the target hosts once they are provisioned.

---

Everything in Task Group 1 is now coherent, consistent, and aligned with:

* Ubuntu 24.04
* Phase-1 folder layout (per: )
* Future Dockerization
* Industry TLS best practices

---
