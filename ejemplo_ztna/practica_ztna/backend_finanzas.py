from http.server import BaseHTTPRequestHandler, HTTPServer
import json

class FinanzasHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        data = {
            "servicio": "Estado Financiero (CONFIDENCIAL)",
            "datos": "Balance Q4: +4.2M EUR",
            "usuario_detectado_por_proxy": self.headers.get("X-Client-DN", "Ninguno (Acceso directo sin proxy)")
        }
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode('utf-8'))

    def log_message(self, format, *args):
        pass

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8002), FinanzasHandler)
    print("\nMicroservicio Finanzas escuchando en puerto 8002...")
    server.serve_forever()
