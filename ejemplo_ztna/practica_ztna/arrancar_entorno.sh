#!/bin/bash
pkill -f "python3 backend_rrhh.py" 2>/dev/null || true
pkill -f "python3 backend_finanzas.py" 2>/dev/null || true
/usr/sbin/nginx -p "$(pwd)" -c "$(pwd)/nginx.conf" -s stop 2>/dev/null || true

python3 backend_rrhh.py > rrhh.log 2>&1 &
python3 backend_finanzas.py > finanzas.log 2>&1 &
/usr/sbin/nginx -p "$(pwd)" -e "$(pwd)/nginx_error.log" -c "$(pwd)/nginx.conf"

echo "-> Entorno ZTNA arrancado"
echo "   - Gateway Nginx en https://localhost:8443"
echo "   - Ejecuta 'python3 cliente_ztna.py' para iniciar las pruebas."

