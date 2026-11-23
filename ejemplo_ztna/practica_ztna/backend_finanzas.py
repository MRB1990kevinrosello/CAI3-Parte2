from http.server import BaseHTTPRequestHandler, HTTPServer
import hmac
import json
import os

HOST, PUERTO = "127.0.0.1", 8002
RUTA = "/finanzas"
ROL_REQUERIDO = "finanzas"

DIR = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(DIR, "secretos", "gateway_token")) as f:
    TOKEN_GATEWAY = f.read().strip()


class FinanzasHandler(BaseHTTPRequestHandler):
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
            "servicio": "Estado Financiero (CONFIDENCIAL)",
            "datos": "Balance Q4: +4.2M EUR",
            "usuario_detectado_por_proxy": dn
        })

    do_HEAD = do_GET

    def log_message(self, format, *args):
        pass


if __name__ == '__main__':
    server = HTTPServer((HOST, PUERTO), FinanzasHandler)
    print(f"\nMicroservicio Finanzas escuchando en {HOST}:{PUERTO}...")
    server.serve_forever()