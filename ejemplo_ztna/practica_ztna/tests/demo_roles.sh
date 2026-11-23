#!/bin/bash
cd "$(dirname "$0")/.." || exit 1
POL=politicas/roles.json
BAK=$(mktemp)
cp "$POL" "$BAK"
trap 'cp "$BAK" "$POL"; rm -f "$BAK"; echo "(política original restaurada)"' EXIT

codigo() {
  curl -s -o /dev/null -w "%{http_code}" --cacert pki/root_ca.crt \
       --cert pki/$1.crt --key pki/$1.key https://localhost:8443/$2
}
editar() {
  python3 - "$POL" "$1" <<'PY'
import json, sys
f, codigo = sys.argv[1], sys.argv[2]
p = json.load(open(f, encoding="utf-8"))
exec(codigo)
json.dump(p, open(f, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
PY
}
serie() { openssl x509 -in pki/$1.crt -noout -serial; }

echo "1) Estado inicial"
echo "   Juan (cert OU=Soporte, $(serie juan_soporte)) -> /finanzas : $(codigo juan_soporte finanzas)"
echo "   Ana  (cert OU=Finanzas, $(serie ana_finanzas)) -> /finanzas : $(codigo ana_finanzas finanzas)"

echo "2) Juan se traslada a Finanzas: RRHH le asigna el rol en la política"
editar 'p["usuarios"]["juan.perez"]["roles"] = ["empleado", "finanzas"]'
echo "   Juan -> /finanzas : $(codigo juan_soporte finanzas)   (mismo certificado: $(serie juan_soporte))"

echo "3) Ana deja Finanzas: se le quita el rol"
editar 'p["usuarios"]["ana.garcia"]["roles"] = ["empleado"]'
echo "   Ana  -> /finanzas : $(codigo ana_finanzas finanzas)"
echo "   Ana  -> /rrhh     : $(codigo ana_finanzas rrhh)"

echo "4) Baja inmediata de Juan (activo=false) sin esperar a la CRL/OCSP"
editar 'p["usuarios"]["juan.perez"]["activo"] = False'
echo "   Juan -> /rrhh     : $(codigo juan_soporte rrhh)"

echo "5) Política corrupta -> se deniega todo (fallo en cerrado)"
echo '{ roto' > "$POL"
echo "   Ana  -> /rrhh     : $(codigo ana_finanzas rrhh)"

echo
echo "Últimas decisiones del PDP (pdp.log):"
tail -n 6 pdp.log
