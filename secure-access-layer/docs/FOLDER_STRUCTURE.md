# Secure Access Layer - Project Folder Structure

The tree below reflects the current Secure Access Layer repository layout (paths are relative to the SAL root `secure-access-layer/`).

```txt
.
├── ca/                          # Certificate Authority for the Secure Access Layer
│   ├── sal-root-ca.crt          # Root CA certificate
│   ├── sal-root-ca.key          # Root CA private key
│   └── sal-root-ca.srl          # CA serial number file
├── docs/                        # Secure Access Layer specific documentation
│   └── FOLDER_STRUCTURE.md      # This file - SAL directory structure documentation
├── jupyterhub/                  # JupyterHub component configuration and certificates
│   ├── certs/                   # JupyterHub TLS certificates
│   │   ├── jupyterhub.internal.crt
│   │   ├── jupyterhub.internal.csr
│   │   ├── jupyterhub.internal.ext
│   │   └── jupyterhub.internal.key
│   ├── conf/                    # JupyterHub configuration files
│   ├── logs/                    # JupyterHub application logs
│   ├── systemd/                 # JupyterHub systemd service files
│   └── workspace/               # JupyterHub workspace directory
├── keycloak/                    # Keycloak OIDC provider configuration and certificates
│   ├── certs/                   # Keycloak TLS certificates
│   │   ├── keycloak.internal.crt
│   │   ├── keycloak.internal.csr
│   │   ├── keycloak.internal.ext
│   │   └── keycloak.internal.key
│   ├── conf/                    # Keycloak configuration files
│   ├── logs/                    # Keycloak application logs
│   └── systemd/                 # Keycloak systemd service files
├── nginx/                       # Nginx reverse proxy configuration
│   ├── certs-public/            # Public-facing certificates
│   ├── conf.d/                  # Nginx configuration files
│   ├── logs/                    # Nginx access and error logs
│   └── systemd/                 # Nginx systemd service files
└── scripts/                     # SAL management and deployment scripts
```

## Directory Highlights

### Core Infrastructure

- **ca/**: Certificate Authority for the Secure Access Layer containing the root CA certificate and private key used to sign all internal service certificates
- **docs/**: Secure Access Layer specific documentation and operational guides

### Service Components

- **jupyterhub/**: JupyterHub instance providing notebook services with OIDC authentication
  - **certs/**: TLS certificates for secure HTTPS communication
  - **conf/**: JupyterHub configuration files for authentication, spawning, and integration
  - **logs/**: Application logs for debugging and monitoring
  - **systemd/**: Service definition files for system management
  - **workspace/**: User workspace and notebook storage

- **keycloak/**: Keycloak OIDC identity provider for authentication and authorization
  - **certs/**: TLS certificates for secure Keycloak communication
  - **conf/**: Keycloak realm and client configurations
  - **logs/**: Keycloak application and authentication logs
  - **systemd/**: Service management files

- **nginx/**: Nginx reverse proxy for load balancing and SSL termination
  - **certs-public/**: Public-facing TLS certificates for external access
  - **conf.d/**: Nginx configuration for routing and proxying
  - **logs/**: Access and error logs for web traffic monitoring
  - **systemd/**: Nginx service management

### Operations

- **scripts/**: Automation scripts for deployment, certificate management, and service operations

## Security Architecture

The Secure Access Layer implements a comprehensive security model:

1. **Certificate Authority**: Root CA (`sal-root-ca`) signs all internal service certificates
2. **Internal TLS**: All services use mTLS for inter-service communication
3. **OIDC Authentication**: Keycloak provides centralized identity management
4. **Reverse Proxy**: Nginx provides external access with SSL termination

## Certificate Management

- **Root CA**: Located in `ca/` directory
- **Service Certificates**: Each service has its own `certs/` subdirectory
- **Certificate Format**: Standard X.509 certificates with RSA private keys
- **Internal Naming**: Uses `.internal` domain for service-to-service communication

## Service Integration

The components work together to provide:

- **Authentication**: Keycloak OIDC provider
- **Authorization**: Role-based access control through Keycloak
- **Secure Access**: Nginx reverse proxy with SSL/TLS
- **Application Services**: JupyterHub for notebook access
- **Certificate Management**: Centralized CA for all services

This structure supports a secure, scalable access layer with proper separation of concerns and comprehensive logging for operations and security monitoring.
