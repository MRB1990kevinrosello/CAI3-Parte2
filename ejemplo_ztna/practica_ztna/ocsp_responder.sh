#!/bin/bash
# Responder OCSP de la Sub-CA Empleados (lee la base de datos de la CA en tiempo real)
openssl ocsp -index pki/demoCA/index.txt -port 8888 \
  -CA pki/sub_ca_empleados.crt \
  -rsigner pki/sub_ca_empleados.crt -rkey pki/sub_ca_empleados.key \
  -nmin 5 > ocsp.log 2>&1 &
echo "-> Responder OCSP en http://127.0.0.1:8888"