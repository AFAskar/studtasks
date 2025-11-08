#!/usr/bin/env bash
set -euo pipefail

# This script runs during the first-time initialization of the Postgres data dir
# It generates a self-signed certificate and enables SSL in postgresql.conf

CERT_DIR="${PGDATA:-/var/lib/postgresql/data}"

# Only run on fresh init (when $PGDATA has just been created by initdb)
if [ ! -f "$CERT_DIR/PG_VERSION" ]; then
  echo "[enable-ssl] PGDATA not initialized yet; skipping (waiting for initdb)."
  exit 0
fi

if [ ! -f "$CERT_DIR/server.key" ] || [ ! -f "$CERT_DIR/server.crt" ]; then
  echo "[enable-ssl] Generating self-signed TLS certificate for Postgres..."

  # Generate a new RSA key and self-signed certificate with SANs for common dev hosts
  openssl req -x509 -newkey rsa:4096 -nodes -days 365 \
    -subj "/CN=postgres" \
    -addext "subjectAltName=DNS:db,DNS:localhost,IP:127.0.0.1" \
    -keyout "$CERT_DIR/server.key" \
    -out "$CERT_DIR/server.crt"

  # Permissions required by Postgres
  chown postgres:postgres "$CERT_DIR/server.key" "$CERT_DIR/server.crt"
  chmod 600 "$CERT_DIR/server.key"
  chmod 644 "$CERT_DIR/server.crt"

  echo "[enable-ssl] Enabling SSL in postgresql.conf"
  { \
    echo "ssl = on"; \
    echo "ssl_cert_file = 'server.crt'"; \
    echo "ssl_key_file = 'server.key'"; \
  } >> "$CERT_DIR/postgresql.conf"
else
  echo "[enable-ssl] Existing TLS materials found; leaving as-is."
fi
