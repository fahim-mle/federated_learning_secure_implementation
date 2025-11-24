#!/bin/bash
# Install JupyterHub for Secure Access Layer
# Usage: sudo bash install_jupyterhub.sh

set -euo pipefail

PROJECT_ROOT="/home/ghost/workspace/internship_project/federated_learning_secure_implementation"
SAL_ROOT="${PROJECT_ROOT}/secure-access-layer"

# Load variables from .env
if [ ! -f "${PROJECT_ROOT}/.env" ]; then
  echo "ERROR: .env file not found in ${PROJECT_ROOT}"
  exit 1
fi
export $(grep -v '^#' "${PROJECT_ROOT}/.env" | xargs)

# Variables expected in .env:
# CLIENT_ID
# CLIENT_SECRET
# KEYCLOAK_HOST
# REALM
# CALLBACK_URL

if [ -z "${CLIENT_ID:-}" ] || [ -z "${CLIENT_SECRET:-}" ] || [ -z "${KEYCLOAK_HOST:-}" ] || [ -z "${REALM:-}" ] || [ -z "${CALLBACK_URL:-}" ]; then
  echo "ERROR: One or more required variables not set in .env"
  exit 1
fi

JH_USER="jupyterhub"
JH_HOME="/opt/jupyterhub"
VENV_DIR="${JH_HOME}/venv"
CERT_DIR="${JH_HOME}/certs"
CONFIG_DIR="${SAL_ROOT}/jupyterhub/conf"
SYSTEMD_DIR="${SAL_ROOT}/jupyterhub/systemd"

echo "Installing dependencies..."
apt update
apt install -y python3-venv python3-pip nodejs npm git curl

echo "Creating system user and directories..."
useradd --system --shell /usr/sbin/nologin --home "${JH_HOME}" "${JH_USER}" || true
mkdir -p "${JH_HOME}"
chown "${JH_USER}:${JH_USER}" "${JH_HOME}"

echo "Setting up Python virtual environment..."
sudo -u "${JH_USER}" python3 -m venv "${VENV_DIR}"
sudo -u "${JH_USER}" "${VENV_DIR}/bin/pip" install --upgrade pip
sudo -u "${JH_USER}" "${VENV_DIR}/bin/pip" install jupyterhub oauthenticator[jupyterhub] jupyterlab

echo "Copying TLS certificates..."
mkdir -p "${CERT_DIR}"
cp "${SAL_ROOT}/jupyterhub/certs/jupyterhub.internal.crt" "${CERT_DIR}/"
cp "${SAL_ROOT}/jupyterhub/certs/jupyterhub.internal.key" "${CERT_DIR}/"
chown -R "${JH_USER}:${JH_USER}" "${CERT_DIR}"
chmod 600 "${CERT_DIR}/jupyterhub.internal.key"

echo "Writing JupyterHub config..."
mkdir -p "${CONFIG_DIR}"
cat > "${CONFIG_DIR}/jupyterhub_config.py" <<EOF
c = get_config()

c.JupyterHub.authenticator_class = 'oauthenticator.generic.GenericOAuthenticator'

c.GenericOAuthenticator.client_id = '${CLIENT_ID}'
c.GenericOAuthenticator.client_secret = '${CLIENT_SECRET}'
c.GenericOAuthenticator.oauth_callback_url = '${CALLBACK_URL}'

c.GenericOAuthenticator.authorize_url = 'https://${KEYCLOAK_HOST}/realms/${REALM}/protocol/openid-connect/auth'
c.GenericOAuthenticator.token_url     = 'https://${KEYCLOAK_HOST}/realms/${REALM}/protocol/openid-connect/token'
c.GenericOAuthenticator.userdata_url  = 'https://${KEYCLOAK_HOST}/realms/${REALM}/protocol/openid-connect/userinfo'

c.GenericOAuthenticator.scope = ['openid', 'profile', 'email', 'groups']
c.GenericOAuthenticator.username_claim = 'preferred_username'
c.GenericOAuthenticator.allowed_groups = ['researcher', 'admin']

c.ConfigurableHTTPProxy.command = ['/usr/bin/configurable-http-proxy', '--ssl-key=${CERT_DIR}/jupyterhub.internal.key', '--ssl-cert=${CERT_DIR}/jupyterhub.internal.crt']

c.Spawner.default_url = '/lab'
EOF
chown "${JH_USER}:${JH_USER}" "${CONFIG_DIR}/jupyterhub_config.py"

echo "Creating systemd service file..."
mkdir -p "${SYSTEMD_DIR}"
cat > "${SYSTEMD_DIR}/jupyterhub.service" <<EOF
[Unit]
Description=JupyterHub Service (Secure Access Layer)
After=network.target

[Service]
User=${JH_USER}
Group=${JH_USER}
Type=simple
ExecStart=${VENV_DIR}/bin/jupyterhub -f ${CONFIG_DIR}/jupyterhub_config.py
Restart=on-failure
WorkingDirectory=${JH_HOME}

[Install]
WantedBy=multi-user.target
EOF

cp "${SYSTEMD_DIR}/jupyterhub.service" /etc/systemd/system/jupyterhub.service
systemctl daemon-reload
systemctl enable jupyterhub
systemctl start jupyterhub
systemctl status jupyterhub

echo "Installation complete. Browse to ${CALLBACK_URL%/hub/oauth_callback}/hub/login"
