#!/bin/bash
set -e

mkdir -p pki/demoCA/newcerts
touch pki/demoCA/index.txt
echo 1000 > pki/demoCA/serial
echo 1000 > pki/demoCA/crlnumber

cat << 'EOF' > pki/openssl.cnf
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = ./pki/demoCA
certs             = $dir/certs
crl_dir           = $dir/crl
new_certs_dir     = $dir/newcerts
database          = $dir/index.txt
serial            = $dir/serial
crlnumber         = $dir/crlnumber
crl               = $dir/crl.pem
private_key       = ./pki/sub_ca_empleados.key
certificate       = ./pki/sub_ca_empleados.crt
default_days      = 365
default_crl_days  = 30
default_md        = sha256
preserve          = no
policy            = policy_loose

[ policy_loose ]
countryName             = optional
stateOrProvinceName     = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
EOF

echo "1. Generando Root CA..."
openssl genrsa -out pki/root_ca.key 2048 2>/dev/null
openssl req -x509 -new -nodes -key pki/root_ca.key -sha256 -days 3650 \
  -subj "/C=ES/O=Hospital_Insegus/CN=Hospital_Insegus Root CA" \
  -config pki/openssl.cnf -extensions v3_ca -out pki/root_ca.crt

echo "2. Generando Sub-CA Empleados..."
openssl genrsa -out pki/sub_ca_empleados.key 2048 2>/dev/null
openssl req -new -key pki/sub_ca_empleados.key \
  -subj "/C=ES/O=Hospital_Insegus/CN=Sub-CA Empleados" -out pki/sub_ca_empleados.csr
openssl x509 -req -in pki/sub_ca_empleados.csr -CA pki/root_ca.crt -CAkey pki/root_ca.key \
  -CAcreateserial -out pki/sub_ca_empleados.crt -days 1825 -sha256 \
  -extfile pki/openssl.cnf -extensions v3_intermediate_ca 2>/dev/null

echo "3. Generando Sub-CA Dispositivos..."
openssl genrsa -out pki/sub_ca_dispositivos.key 2048 2>/dev/null
openssl req -new -key pki/sub_ca_dispositivos.key \
  -subj "/C=ES/O=Hospital_Insegus/CN=Sub-CA Dispositivos" -out pki/sub_ca_dispositivos.csr
openssl x509 -req -in pki/sub_ca_dispositivos.csr -CA pki/root_ca.crt -CAkey pki/root_ca.key \
  -CAcreateserial -out pki/sub_ca_dispositivos.crt -days 1825 -sha256 \
  -extfile pki/openssl.cnf -extensions v3_intermediate_ca 2>/dev/null

echo "4. Generando Certificado del Servidor ZTNA (localhost)..."
openssl genrsa -out pki/server.key 2048 2>/dev/null
openssl req -new -key pki/server.key \
  -subj "/C=ES/O=Hospital_Insegus/CN=localhost" -out pki/server.csr
openssl x509 -req -in pki/server.csr -CA pki/sub_ca_empleados.crt -CAkey pki/sub_ca_empleados.key \
  -CAcreateserial -out pki/server.crt -days 365 -sha256 \
  -extfile <(printf "subjectAltName=DNS:localhost,IP:127.0.0.1") 2>/dev/null


emitir_empleado() {
  NOMBRE=$1
  CN=$2
  OU=$3
  openssl genrsa -out pki/${NOMBRE}.key 2048 2>/dev/null
  openssl req -new -key pki/${NOMBRE}.key \
    -subj "/C=ES/O=Hospital_Insegus/OU=${OU}/CN=${CN}" -out pki/${NOMBRE}.csr
  openssl ca -batch -config pki/openssl.cnf -in pki/${NOMBRE}.csr \
    -out pki/${NOMBRE}.crt -notext 2>/dev/null
}

echo "5. Emitiendo certificados de empleados..."
emitir_empleado "ana_finanzas" "ana.garcia" "Finanzas"
emitir_empleado "juan_soporte" "juan.perez" "Soporte"
emitir_empleado "pedro_despedido" "pedro.ruiz" "Finanzas"

echo "6. Emitiendo certificado de dispositivo IoT..."
openssl genrsa -out pki/impresora_planta2.key 2048 2>/dev/null
openssl req -new -key pki/impresora_planta2.key \
  -subj "/C=ES/O=Hospital_Insegus/OU=IoT/CN=hp-laserjet" -out pki/impresora_planta2.csr
openssl x509 -req -in pki/impresora_planta2.csr -CA pki/sub_ca_dispositivos.crt -CAkey pki/sub_ca_dispositivos.key \
  -CAcreateserial -out pki/impresora_planta2.crt -days 365 -sha256 2>/dev/null

echo "7. Emitiendo certificado de atacante externo (Autofirmado)..."
openssl genrsa -out pki/atacante_externo.key 2048 2>/dev/null
openssl req -x509 -new -nodes -key pki/atacante_externo.key -sha256 -days 365 \
  -subj "/C=RU/O=EvilCorp/OU=Finanzas/CN=admin" -out pki/atacante_externo.crt

echo "8. Generando cadenas de confianza y CRL inicial vacía..."
cat pki/sub_ca_empleados.crt pki/root_ca.crt > pki/chain_empleados.crt
cat pki/sub_ca_dispositivos.crt pki/root_ca.crt > pki/chain_completa.crt
cat pki/chain_empleados.crt pki/sub_ca_dispositivos.crt > pki/todas_las_cas.crt
cat pki/server.crt pki/sub_ca_empleados.crt > pki/server_fullchain.crt
openssl ca -config pki/openssl.cnf -gencrl -out pki/crl.pem 2>/dev/null

rm -f pki/*.csr
echo "-> PKI generada correctamente en la carpeta ./pki/"
