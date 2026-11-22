from http.server import BaseHTTPRequestHandler, HTTPServer
import json

class RRHHHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        data = {
            "servicio": "RRHH Información General",
            "datos": "Calendario de vacaciones 2026 aprobado para toda la plantilla.",
            "usuario_detectado_por_proxy": self.headers.get("X-Client-DN", "Ninguno (Acceso directo sin proxy)")
        }
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode('utf-8'))

    def log_message(self, format, *args):
        pass

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8001), RRHHHandler)
    print("\nMicroservicio RRHH escuchando en puerto 8001...")
    server.serve_forever()
