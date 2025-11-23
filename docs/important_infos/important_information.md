# Important Information
This document summarizes key elements from the FL_FLWR_OPS operations manual.

## Purpose
Provide secure national infrastructure for federated learning enabling medical research without exposing sensitive data.

## Core Components
- Superlink (central orchestrator)
- Supernodes (on‑prem training nodes)
- VPN for hybrid connectivity
- IAM (Keycloak) for OIDC authentication
- JupyterHub for researcher interface
- TLS/mTLS everywhere
- GPU-enabled training support

## Security Model
- Principle of least trust
- Network segmentation + firewalls
- mTLS between superlink and supernodes
- VPN isolation of org networks
- No data leaves organisation boundaries

## Deployment
- Ubuntu 24.04 LTS
- Systemd-managed services
- Local CA for internal certificates
- Dockerized JupyterHub execution
