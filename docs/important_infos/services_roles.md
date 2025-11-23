# Services and Their Roles

## Superlink
- Central aggregation server in Nectar cloud.
- Distributes model scripts to supernodes.
- Aggregates model weights.
- Enforces mTLS + supernode authentication.
- Can integrate with OIDC for user-level auth.

## Supernode
- On‑premise training node inside organisation network.
- Executes FL client code against sensitive data.
- Never transmits raw data; only model parameters return.
- Connects to superlink through VPN + mTLS.

## VPN (OpenVPN)
- Connects organisations to Nectar securely.
- Provides network isolation, non-bridged routing.
- Client certificates required.

## IAM – Keycloak
- Provides OIDC authentication for researchers and services.
- Stores identities, roles, groups.
- Integrates with JupyterHub and optionally Superlink.

## JupyterHub
- Researcher UI for submitting training tasks.
- Authenticated via OIDC (Keycloak).
- Runs notebooks inside non-privileged Docker containers.

## Reverse Proxy – Nginx
- Public HTTPS entry.
- Terminates public TLS.
- Proxies to internal Keycloak + JupyterHub.

## Monitoring (Prometheus/Grafana)
- Optional for ops.
- Collects CPU, RAM, disk, GPU metrics.
- Provides alerting for node failures.

## Local Certificate Authority
- Issues internal TLS/mTLS certificates.
- Used by Superlink, Supernodes, Keycloak (internal), VPN.
