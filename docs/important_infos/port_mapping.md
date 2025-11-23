# Port Mapping Table

| Component | Port | Protocol | Purpose |
|----------|-------|----------|---------|
| SSH | 22 | TCP | Admin & researcher terminal |
| Nginx reverse proxy | 443 | TCP | Public HTTPS ingress |
| JupyterHub | 443 | TCP | UI access (internal) |
| Keycloak | 8443 | TCP | IAM / OIDC |
| Postgres | 5432 | TCP | IAM DB |
| Superlink – ServerAppIO | 9091 | TCP | FL server application API |
| Superlink – Fleet API | 9092 | TCP | FL coordination |
| Superlink – Deployment Engine | 9093 | TCP | Task distribution |
| Supernode – Client App IO | 9094–9099 | TCP | FL training communication |
| OpenVPN | 1194 | UDP | VPN tunnel |
| OpenVPN (fallback) | 443 | TCP | VPN over TLS |
| Prometheus Node Exporter | 9900 | TCP | Metrics |
| Grafana | 3000 | TCP | Dashboards |
| Prometheus | 9090/9091/9093 | TCP | Monitoring |

## Notes
- All superlink ↔ supernode communication uses mTLS.
- VPN isolates organisation networks from public exposure.
- Monitoring ports should not be publicly exposed.
