#!/bin/bash
# NGINX Reverse Proxy Setup for Secure Access Layer
# Usage: sudo bash install_nginx_proxy.sh

set -euo pipefail

PROJECT_ROOT="/home/ghost/workspace/internship_project/federated_learning_secure_implementation"
SAL_ROOT="${PROJECT_ROOT}/secure-access-layer"

echo "[INFO] Loading environment variables from .env..."

if [ ! -f "${PROJECT_ROOT}/.env" ]; then
  echo "[ERROR] .env file not found at ${PROJECT_ROOT}/.env"
  exit 1
fi

export $(grep -v '^#' "${PROJECT_ROOT}/.env" | xargs)

# REQUIRED VARIABLES in .env:
#   KEYCLOAK_HOST
#   JUPYTERHUB_HOST (optional; fallback jupyterhub.internal)
#   DOMAIN_MODE=internal
#
#   If DOMAIN_MODE="internal", hostnames like *.internal will be used.

echo "[INFO] Installing nginx..."
apt update
apt install -y nginx

echo "[INFO] Enabling nginx service..."
systemctl enable nginx
systemctl start nginx

# Directories for nginx internal certs
NGINX_CERT_DIR="/etc/nginx/certs"
mkdir -p "${NGINX_CERT_DIR}"

echo "[INFO] Copying internal TLS certificates..."

# JupyterHub internal certs
cp "${SAL_ROOT}/jupyterhub/certs/jupyterhub.internal.crt" "${NGINX_CERT_DIR}/"
cp "${SAL_ROOT}/jupyterhub/certs/jupyterhub.internal.key" "${NGINX_CERT_DIR}/"

# Keycloak internal certs
cp "${SAL_ROOT}/keycloak/certs/keycloak.internal.crt" "${NGINX_CERT_DIR}/"
cp "${SAL_ROOT}/keycloak/certs/keycloak.internal.key" "${NGINX_CERT_DIR}/"

chmod 600 "${NGINX_CERT_DIR}"/*.key

echo "[INFO] Writing nginx vhost configs..."

# Ensure config directory exists
mkdir -p "${SAL_ROOT}/nginx/conf.d"

# ----------------------------
# JUPYTERHUB PROXY CONFIG
# ----------------------------
cat > "${SAL_ROOT}/nginx/conf.d/jupyterhub.internal.conf" <<EOF
server {
    listen 443 ssl;
    server_name jupyterhub.internal;

    ssl_certificate     /etc/nginx/certs/jupyterhub.internal.crt;
    ssl_certificate_key /etc/nginx/certs/jupyterhub.internal.key;

    client_max_body_size 50M;

    location / {
        proxy_pass http://127.0.0.1:8000;

        proxy_set_header Host              \$host;
        proxy_set_header X-Real-IP         \$remote_addr;
        proxy_set_header X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

# ----------------------------
# KEYCLOAK PROXY CONFIG
# ----------------------------
cat > "${SAL_ROOT}/nginx/conf.d/keycloak.internal.conf" <<EOF
server {
    listen 443 ssl;
    server_name keycloak.internal;

    ssl_certificate     /etc/nginx/certs/keycloak.internal.crt;
    ssl_certificate_key /etc/nginx/certs/keycloak.internal.key;

    location / {
        proxy_pass https://127.0.0.1:8443;

        proxy_set_header Host              \$host;
        proxy_set_header X-Real-IP         \$remote_addr;
        proxy_set_header X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
EOF

echo "[INFO] Deploying nginx configs..."

cp "${SAL_ROOT}/nginx/conf.d/"*.conf /etc/nginx/conf.d/

echo "[INFO] Testing nginx configuration..."
nginx -t

echo "[INFO] Reloading nginx..."
systemctl reload nginx

echo "[SUCCESS] nginx reverse proxy setup complete."

echo ""
echo "---------------------------------------------------------"
echo "✓ You can now access your services via:"
echo "  → https://jupyterhub.internal/hub/login"
echo "  → https://keycloak.internal/"
echo ""
echo "IMPORTANT: Ensure your workstation's /etc/hosts includes:"
echo "  127.0.1.1 jupyterhub.internal"
echo "  127.0.1.1 keycloak.internal"
echo "---------------------------------------------------------"
