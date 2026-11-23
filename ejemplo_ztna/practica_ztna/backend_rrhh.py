from http.server import BaseHTTPRequestHandler, HTTPServer
import hmac
import json
import os

HOST, PUERTO = "127.0.0.1", 8001
RUTA = "/rrhh"
ROL_REQUERIDO = "empleado"

DIR = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(DIR, "secretos", "gateway_token")) as f:
    TOKEN_GATEWAY = f.read().strip()


class RRHHHandler(BaseHTTPRequestHandler):
    server_version = "Backend"
    sys_version = ""

    def _responder(self, codigo, data):
        cuerpo = json.dumps(data, ensure_ascii=False).encode('utf-8')
        self.send_response(codigo)
        self.send_header('Content-type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(cuerpo)))
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        if self.command != 'HEAD':
            self.wfile.write(cuerpo)

    def do_GET(self):
        token = self.headers.get("X-Gateway-Token", "")
        if not hmac.compare_digest(token.encode(), TOKEN_GATEWAY.encode()):
            return self._responder(403, {"error": "Acceso directo no permitido. Use el Gateway ZTNA."})
        if self.path.split("?", 1)[0] != RUTA:
            return self._responder(404, {"error": "Recurso no encontrado"})
        dn = self.headers.get("X-Client-DN", "")
        roles = [r.strip() for r in self.headers.get("X-Client-Roles", "").split(",") if r.strip()]
        if not dn or ROL_REQUERIDO not in roles:
            return self._responder(403, {"error": "Rol no autorizado"})
        self._responder(200, {
            "servicio": "RRHH Información General",
            "datos": "Calendario de vacaciones 2026 aprobado para toda la plantilla.",
            "usuario_detectado_por_proxy": dn
        })

    do_HEAD = do_GET

    def log_message(self, format, *args):
        pass


if __name__ == '__main__':
    server = HTTPServer((HOST, PUERTO), RRHHHandler)
    print(f"\nMicroservicio RRHH escuchando en {HOST}:{PUERTO}...")
    server.serve_forever()