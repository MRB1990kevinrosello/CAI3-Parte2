#!/bin/bash
# Genera el secreto compartido entre el Gateway y los microservicios.
# Se rota en cada arranque. Los ficheros generados NO se suben al repo.
set -e
cd "$(dirname "$0")"
umask 077
mkdir -p secretos
TOKEN=$(openssl rand -hex 32)
printf '%s\n' "$TOKEN" > secretos/gateway_token
cat > conf/secreto_gateway.conf <<FIN
# FICHERO GENERADO por generar_secreto_gateway.sh - NO SUBIR AL REPO
map \$host \$ztna_gateway_token {
    default "$TOKEN";
}
FIN
chmod 600 secretos/gateway_token conf/secreto_gateway.conf
echo "-> Secreto Gateway<->backends generado"
