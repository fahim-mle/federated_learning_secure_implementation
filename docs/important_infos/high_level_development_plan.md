# High-Level Development Plan for Secure Flower Federated Learning Platform

This guide provides a clear, high-level roadmap for coding agents (e.g., Codex, autonomous dev agents) to understand the architecture, objectives, boundaries, and required deliverables of the Secure Federated Learning (FL) project built on Flower, with OIDC authentication and operational hardening.

---

## 1. Project Purpose
Develop a **secure, production-grade Federated Learning platform** based on the Flower framework, capable of:
- Training machine learning models **without moving data** from organisation boundaries.
- Enforcing **mTLS**, **SuperNode authentication**, and **OIDC user authentication**.
- Supporting **hybrid cloud deployment** (Nectar cloud ↔ organisation networks) via VPN.
- Running FL workloads with both CPU and GPU acceleration.

---

## 2. System Architecture Overview
### 2.1 Core Components
- **Superlink (Server)**  
  Central aggregation server located in Nectar cloud.

- **Supernodes (Clients)**  
  Organisation-hosted training nodes with local datasets.

- **Keycloak IAM**  
  Provides OIDC authentication + role-based access control.

- **VPN Layer**  
  Secure network connectivity between org servers and Nectar.

- **JupyterHub**  
  Researcher UI with restricted containers and OAuth login.

- **Reverse Proxy (Nginx)**  
  Public HTTPS ingress + routing to internal services.

- **Monitoring (Optional)**  
  Prometheus + Grafana.

All components and configuration details originate from the official FL FLWR OPS manual. fileciteturn0file0

---

## 3. Project Deliverables

### 3.1 Core Deliverables (Primary)
1. **Secure Flower federation**
   - Functional Superlink + N Supernodes cluster.
   - Fully configured mTLS.
   - SuperNode public-key authentication.
   - Proper certificate authority management.
2. **User authentication integration**
   - OIDC authentication (Keycloak) for JupyterHub + optional Superlink integration.
3. **End-to-end deployment scripts**
   - Automated provisioning for:
     - Certificates  
     - Python venvs  
     - Docker/Jupyter  
     - Systemd services  
4. **Operational documentation**
   - Deployment manual  
   - Operations support manual  
   - Network diagram  
   - Port mapping documentation  
   - Security model description  

### 3.2 Secondary Deliverables (Optional/Phase 2)
- GPU-enabled Docker images
- Monitoring dashboards
- Windows + Mac-compatible Supernode containers

---

## 4. High-Level Workflow

### Step 1 — Foundation Setup
- Prepare Ubuntu 24.04 base environment.
- Install prerequisites: Docker, Python venvs, system users.
- Initialise local Certificate Authority.

### Step 2 — Network + VPN Layer
- Deploy OpenVPN server (Nectar).
- Configure VPN client for each Supernode.
- Validate routing + firewall rules.

### Step 3 — IAM + Authentication Layer
- Install Keycloak + Postgres.
- Configure realm, roles, client, redirect URIs.
- Enable OIDC for JupyterHub.

### Step 4 — Researcher Interface
- Deploy JupyterHub with DockerSpawner.
- Connect it to Keycloak.
- Configure persistent workspaces and isolated containers.

### Step 5 — Flower Layer
- Deploy Python venv & install FL components.
- Generate mTLS certificates for:
  - Superlink
  - Each Supernode
- Configure superlink & supernode systemd services.
- Register Supernode public keys for authentication.
- Validate FL job lifecycle.

### Step 6 — Multi-org Support
- Add additional supernodes (OrgA, OrgB…).
- Validate partitioning + per-tenant VPNs.

### Step 7 — Monitoring (Optional)
- Install Prometheus, Grafana, GPU exporters.
- Configure alerting + dashboards.

### Step 8 — Documentation + Hardening
- Produce final operational documentation.
- Backup strategy: configs, certs, DBs, logs.
- Security review checklist.

---

## 5. Coding Agent Guidelines

### 5.1 Behavioral Expectations
A coding agent should:
- Always maintain consistency with FL FLWR OPS manual. fileciteturn0file0
- Avoid reinventing architecture; follow documented folder structures.
- Automate processes only where manual steps are deterministic.
- Never alter network topologies or protocols without explicit instruction.

### 5.2 Priorities for Automation
1. Certificate creation + distribution  
2. Systemd service generation templates  
3. Docker image generation for Supernode GPU/CPU  
4. Scripted environment provisioning  

### 5.3 Items Agents Should Not Modify
- IAM security model  
- Network segmentation  
- VPN flow  
- Port mapping tables  
- Any cryptographic operations beyond automation  

---

## 6. Development Milestones

### Milestone 1 — Secure Base Infrastructure
- VPN operational
- Keycloak + Nginx + JupyterHub deployed
- Superlink + 1 Supernode with mTLS

### Milestone 2 — Multi-node FL federation
- Additional supernodes added
- SuperNode key authentication enabled
- Sample FL training confirmed

### Milestone 3 — Complete Security Integration
- JupyterHub OIDC authentication validated
- Optional Superlink OIDC wrapped (device flow)

### Milestone 4 — Documentation + Tooling
- All .md documents created
- Backup scripts delivered
- Systemd services validated

---

## 7. Success Criteria
The project is considered successful when:
- Researchers authenticate via OIDC and can run FL workloads.
- Supernodes connect securely via VPN + mTLS + key auth.
- Superlink aggregates results correctly without data replication.
- Full lifecycle from provisioning → execution → monitoring is documented.

---

## 8. Future Enhancements
- Kubernetes-based deployment (Helm)
- Multi-tenant Keycloak realm automation
- SLA-based autoscaling of nodes
- Encrypted-at-rest datasets
- Hardware TEEs (Trusted Execution Environments)

---

# End of High-Level Plan
