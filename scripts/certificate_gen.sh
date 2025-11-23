#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
CERT_ROOT="${PROJECT_ROOT}/flower-secure-fl/certificates"
CA_DIR="${CERT_ROOT}/ca"
SUPERLINK_DIR="${CERT_ROOT}/superlink"
SUPERNODES_DIR="${CERT_ROOT}/supernodes"
SUPERNODE_NAME="supernode1"

require_openssl() {
    if ! command -v openssl >/dev/null 2>&1; then
        echo "[error] openssl not found in PATH" >&2
        exit 1
    fi
}

prepare_directories() {
    echo "[info] preparing certificate directories under ${CERT_ROOT}"
    mkdir -p "${CA_DIR}" "${SUPERLINK_DIR}" "${SUPERNODES_DIR}"
}

generate_ca() {
    echo "[info] generating Certificate Authority materials"
    openssl genrsa -out "${CA_DIR}/ca.key" 4096 >/dev/null 2>&1
    openssl req -x509 -new -nodes -key "${CA_DIR}/ca.key" -sha256 -days 365 \
        -subj "/C=AU/ST=Local/L=Local/O=FlowerLocalCA/OU=Development/CN=FlowerLocalRootCA" \
        -out "${CA_DIR}/ca.crt" >/dev/null 2>&1
    openssl x509 -in "${CA_DIR}/ca.crt" -noout -subject
}

generate_superlink() {
    echo "[info] generating SuperLink keypair and CSR"
    openssl genrsa -out "${SUPERLINK_DIR}/superlink.key" 4096 >/dev/null 2>&1
    openssl req -new -key "${SUPERLINK_DIR}/superlink.key" -out "${SUPERLINK_DIR}/superlink.csr" \
        -subj "/C=AU/ST=Local/L=Local/O=FlowerSuperLink/OU=Dev/CN=localhost" >/dev/null 2>&1
    openssl req -in "${SUPERLINK_DIR}/superlink.csr" -noout -subject

    echo "[info] signing SuperLink certificate with local CA"
    ( cd "${CERT_ROOT}" && \
        openssl x509 -req \
        -in "superlink/superlink.csr" \
        -CA "ca/ca.crt" -CAkey "ca/ca.key" -CAcreateserial \
        -out "superlink/superlink.crt" \
        -days 365 -sha256 \
        -extfile <(printf "subjectAltName=DNS:localhost,IP:127.0.0.1") ) >/dev/null 2>&1
    openssl x509 -in "${SUPERLINK_DIR}/superlink.crt" -noout -text | grep -E "(Issuer:|DNS:localhost|IP Address:127.0.0.1)"

    echo "supernodes/${SUPERNODE_NAME}.crt" > "${SUPERLINK_DIR}/trusted_supernodes.csv"
}

generate_supernode() {
    echo "[info] generating ${SUPERNODE_NAME} keypair and CSR"
    openssl genrsa -out "${SUPERNODES_DIR}/${SUPERNODE_NAME}.key" 4096 >/dev/null 2>&1
    openssl req -new -key "${SUPERNODES_DIR}/${SUPERNODE_NAME}.key" -out "${SUPERNODES_DIR}/${SUPERNODE_NAME}.csr" \
        -subj "/C=AU/ST=Local/L=Local/O=FlowerSuperNode/OU=Dev/CN=${SUPERNODE_NAME}" >/dev/null 2>&1

    echo "[info] signing ${SUPERNODE_NAME} certificate"
    openssl x509 -req \
        -in "${SUPERNODES_DIR}/${SUPERNODE_NAME}.csr" \
        -CA "${CA_DIR}/ca.crt" -CAkey "${CA_DIR}/ca.key" -CAcreateserial \
        -out "${SUPERNODES_DIR}/${SUPERNODE_NAME}.crt" \
        -days 365 -sha256 \
        -extfile <(printf "subjectAltName=DNS:${SUPERNODE_NAME},IP:127.0.0.1") >/dev/null 2>&1
    openssl x509 -in "${SUPERNODES_DIR}/${SUPERNODE_NAME}.crt" -noout -text | grep -E "(Issuer:|DNS:${SUPERNODE_NAME}|IP Address:127.0.0.1)"
}

verify_chain() {
    echo "[info] verifying generated certificate chains"
    ( cd "${PROJECT_ROOT}/flower-secure-fl" && \
        openssl verify -CAfile certificates/ca/ca.crt certificates/superlink/superlink.crt && \
        openssl verify -CAfile certificates/ca/ca.crt certificates/supernodes/${SUPERNODE_NAME}.crt )
}

main() {
    require_openssl
    prepare_directories
    generate_ca
    generate_superlink
    generate_supernode
    verify_chain
    echo "[info] certificate generation complete"
}

main "$@"
