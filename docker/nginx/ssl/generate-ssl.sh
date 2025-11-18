#!/bin/bash

echo "Generando certificados SSL self-signed..."

mkdir -p docker/nginx/ssl

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout docker/nginx/ssl/localhost.key \
  -out docker/nginx/ssl/localhost.crt \
  -subj "/C=CO/ST=Valle/L=Cali/O=UAO/OU=Telematicos/CN=localhost"

chmod 644 docker/nginx/ssl/localhost.crt
chmod 600 docker/nginx/ssl/localhost.key

echo "✅ Certificados SSL generados exitosamente"
echo "   - localhost.crt"
echo "   - localhost.key"