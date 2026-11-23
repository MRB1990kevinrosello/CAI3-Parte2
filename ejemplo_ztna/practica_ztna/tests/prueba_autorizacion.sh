cd "$(dirname "$0")/.." || exit 1
GW=https://localhost:8443

peticion() {
  local id=$1 desc=$2 esperado=$3; shift 3
  local obtenido
  obtenido=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$@")
  [ "$obtenido" = "000" ] && obtenido="sin conexión"
  local ok="OK"; [ "$obtenido" != "$esperado" ] && ok="FALLO"
  printf "%-4s %-52s esperado=%-4s obtenido=%-12s %s\n" "$id" "$desc" "$esperado" "$obtenido" "$ok"
}
como() { echo --cacert pki/root_ca.crt --cert pki/$1.crt --key pki/$1.key; }

echo "=== Autorización por identidad (vía Gateway) ==="
peticion A01 "Ana (Finanzas) -> /rrhh"                     200 $(como ana_finanzas) $GW/rrhh
peticion A02 "Ana (Finanzas) -> /finanzas"                 200 $(como ana_finanzas) $GW/finanzas
peticion A03 "Juan (Soporte) -> /rrhh"                     200 $(como juan_soporte) $GW/rrhh
peticion A04 "Juan (Soporte) -> /finanzas"                 403 $(como juan_soporte) $GW/finanzas
peticion A05 "Juan + cabecera X-Client-Roles falsa"        403 $(como juan_soporte) -H "X-Client-Roles: empleado,finanzas" $GW/finanzas
peticion A06 "Juan + cabecera X-Client-DN falsa"           403 $(como juan_soporte) -H "X-Client-DN: CN=ana.garcia,OU=Finanzas,O=Hospital_Insegus,C=ES" $GW/finanzas

echo "=== Otros fallos del Gateway ==="
peticion G01 "Ana -> /finanzasXYZ (antes: prefijo)"         404 $(como ana_finanzas) $GW/finanzasXYZ
peticion G02 "Ana -> /rrhh/../finanzas (normalización)"     200 $(como ana_finanzas) --path-as-is $GW/rrhh/../finanzas
peticion G03 "Juan -> /rrhh/../finanzas (traversal)"        403 $(como juan_soporte) --path-as-is $GW/rrhh/../finanzas
peticion G04 "Ana -> / (ruta no publicada)"                 404 $(como ana_finanzas) $GW/
peticion G05 "Ana -> POST /finanzas (método)"               403 $(como ana_finanzas) -X POST $GW/finanzas
peticion G06 "Ana -> DELETE /rrhh (método)"                 403 $(como ana_finanzas) -X DELETE $GW/rrhh
echo "     Cabecera Server devuelta: $(curl -sI $(como ana_finanzas) $GW/rrhh | grep -i '^server:' | tr -d '\r')"

echo "=== Acceso directo a los backends (saltarse el Gateway) ==="
peticion B01 "Directo :8002/finanzas"                       403 http://127.0.0.1:8002/finanzas
peticion B02 "Directo :8001/rrhh"                           403 http://127.0.0.1:8001/rrhh
peticion B03 "Directo :8002 + X-Client-DN/Roles falsos"     403 -H "X-Client-DN: CN=ana.garcia,OU=Finanzas,O=Hospital_Insegus,C=ES" -H "X-Client-Roles: empleado,finanzas" http://127.0.0.1:8002/finanzas
peticion B04 "Directo :8002 + X-Gateway-Token inventado"    403 -H "X-Gateway-Token: 1234" http://127.0.0.1:8002/finanzas
echo "     Interfaces en escucha de los backends:"
ss -ltn 2>/dev/null | grep -E ':800[123] ' | awk '{print "       " $4}'
