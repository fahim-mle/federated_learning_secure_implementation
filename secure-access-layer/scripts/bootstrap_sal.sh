#!/usr/bin/env bash
set -euo pipefail

# Bootstrap Secure Access Layer directories and certificates.
# Run from anywhere; script locates the repo root automatically.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SAL_DIR="${ROOT_DIR}/secure-access-layer"
CA_DIR="${SAL_DIR}/ca"
KEYCLOAK_CERTS="${SAL_DIR}/keycloak/certs"
JH_CERTS="${SAL_DIR}/jupyterhub/certs"

create_directories() {
  echo "[1/3] Ensuring directory structure exists..."
  mkdir -p \
    "${SAL_DIR}/keycloak"/{conf,certs,systemd,logs} \
    "${SAL_DIR}/jupyterhub"/{conf,certs,systemd,workspace,logs} \
    "${SAL_DIR}/nginx"/{conf.d,certs-public,systemd,logs} \
    "${CA_DIR}" \
    "${SAL_DIR}/scripts" \
    "${SAL_DIR}/docs"
}

ensure_ca() {
  if [[ -f "${CA_DIR}/sal-root-ca.key" && -f "${CA_DIR}/sal-root-ca.crt" ]]; then
    echo "[2/3] CA already present. Skipping generation."
    return
  fi
  echo "[2/3] Generating sal-root-ca (RSA 4096, 10 years)..."
  openssl req -x509 -nodes -new -newkey rsa:4096 -sha256 \
    -days 3650 \
    -keyout "${CA_DIR}/sal-root-ca.key" \
    -out "${CA_DIR}/sal-root-ca.crt" \
    -subj "/C=AU/ST=Local/L=Local/O=SecureAccessLayer/OU=Security/CN=sal-root-ca"
}

issue_cert() {
  local name=$1
  local host=$2
  local out_dir=$3

  if [[ -f "${out_dir}/${name}.crt" && -f "${out_dir}/${name}.key" ]]; then
    echo "  - ${name}.crt already exists. Skipping."
    return
  fi

  echo "  - Creating ${name} key/csr..."
  openssl req -new -nodes -newkey rsa:4096 -sha256 \
    -keyout "${out_dir}/${name}.key" \
    -out "${out_dir}/${name}.csr" \
    -subj "/C=US/ST=Local/L=Local/O=SecureAccessLayer/OU=${name}/CN=${host}"

  cat > "${out_dir}/${name}.ext" <<EOF
subjectAltName=DNS:${host}
EOF

  echo "  - Signing ${name}.crt with sal-root-ca..."
  openssl x509 -req \
    -in "${out_dir}/${name}.csr" \
    -CA "${CA_DIR}/sal-root-ca.crt" \
    -CAkey "${CA_DIR}/sal-root-ca.key" \
    -CAcreateserial \
    -out "${out_dir}/${name}.crt" \
    -days 825 \
    -sha256 \
    -extfile "${out_dir}/${name}.ext"
}

issue_service_certs() {
  echo "[3/3] Ensuring service certificates exist..."
  issue_cert "keycloak.internal" "keycloak.internal" "${KEYCLOAK_CERTS}"
  issue_cert "jupyterhub.internal" "jupyterhub.internal" "${JH_CERTS}"
}

create_directories
ensure_ca
issue_service_certs

echo "Bootstrap complete."
