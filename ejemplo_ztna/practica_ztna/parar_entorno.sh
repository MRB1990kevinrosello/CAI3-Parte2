#!/bin/bash
pkill -f "python3 backend_rrhh.py" 2>/dev/null || true
pkill -f "python3 backend_finanzas.py" 2>/dev/null || true
pkill -f "python3 pdp_autorizacion.py" 2>/dev/null || true
pkill -f "openssl ocsp" 2>/dev/null || true
/usr/sbin/nginx -p "$(pwd)" -c "$(pwd)/nginx.conf" -s stop 2>/dev/null || true

echo "-> Entorno ZTNA detenido."


