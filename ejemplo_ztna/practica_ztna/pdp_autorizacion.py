from http.server import BaseHTTPRequestHandler, HTTPServer
from datetime import datetime, timezone
import json
import os
import re

HOST, PUERTO = "127.0.0.1", 8003
DIR = os.path.dirname(os.path.abspath(__file__))
FICHERO_POLITICA = os.path.join(DIR, "politicas", "roles.json")
EMISOR_EMPLEADOS = "CN=Sub-CA Empleados,O=Hospital_Insegus,C=ES"
RE_CN = re.compile(r"^CN=([a-z0-9._-]+),")


def cargar_politica():
    with open(FICHERO_POLITICA, encoding="utf-8") as f:
        return json.load(f)


def decidir(recurso, dn, emisor):
    if emisor != EMISOR_EMPLEADOS:
        return False, "", [], "emisor no es la Sub-CA de Empleados"
    m = RE_CN.match(dn)
    if not m:
        return False, "", [], "DN sin CN válido"
    usuario = m.group(1)
    try:
        politica = cargar_politica()
    except (OSError, ValueError) as e:
        return False, usuario, [], f"política ilegible ({e.__class__.__name__}) -> denegar"
    datos = politica.get("usuarios", {}).get(usuario)
    if datos is None:
        return False, usuario, [], "usuario no dado de alta en la política"
    if datos.get("activo") is not True:
        return False, usuario, [], "usuario desactivado"
    roles = [r for r in datos.get("roles", []) if isinstance(r, str)]
    requeridos = politica.get("recursos", {}).get(recurso)
    if not requeridos:
        return False, usuario, roles, f"recurso '{recurso}' sin política"
    if not set(roles) & set(requeridos):
        return False, usuario, roles, f"requiere uno de {requeridos}"
    return True, usuario, roles, "rol autorizado"


class PDPHandler(BaseHTTPRequestHandler):
    server_version = "PDP"
    sys_version = ""

    def do_GET(self):
        ruta = self.path.split("?", 1)[0]
        if not ruta.startswith("/decidir/"):
            self.send_response(404)
            self.end_headers()
            return
        recurso = ruta[len("/decidir/"):]
        dn = self.headers.get("X-Client-DN", "")
        emisor = self.headers.get("X-Client-Issuer", "")
        permitido, usuario, roles, motivo = decidir(recurso, dn, emisor)

        self.send_response(200 if permitido else 403)
        if permitido:
            self.send_header("X-ZTNA-Usuario", usuario)
            self.send_header("X-ZTNA-Roles", ",".join(roles))
        self.send_header("Content-Length", "0")
        self.end_headers()

        print(json.dumps({
            "fecha": datetime.now(timezone.utc).isoformat(timespec="seconds"),
            "id_peticion": self.headers.get("X-Request-ID", ""),
            "usuario": usuario,
            "recurso": recurso,
            "decision": "PERMITIR" if permitido else "DENEGAR",
            "roles": roles,
            "motivo": motivo,
        }, ensure_ascii=False), flush=True)

    def log_message(self, format, *args):
        pass


if __name__ == "__main__":
    cargar_politica() 
    server = HTTPServer((HOST, PUERTO), PDPHandler)
    print(f"PDP de autorización escuchando en {HOST}:{PUERTO}...", flush=True)
    server.serve_forever()