import ssl
import urllib.request
import urllib.error
import json
import os

IDENTIDADES = {
    "1": ("Sin certificado (Anónimo)", None, None),
    "2": ("Ana García (ana_finanzas)", "pki/ana_finanzas.crt", "pki/ana_finanzas.key"),
    "3": ("Juan Pérez (juan_soporte)", "pki/juan_soporte.crt", "pki/juan_soporte.key"),
    "4": ("Pedro Ruiz (pedro_despedido)", "pki/pedro_despedido.crt", "pki/pedro_despedido.key"),
    "5": ("Impresora Planta 2 (impresora_planta2)", "pki/impresora_planta2.crt", "pki/impresora_planta2.key"),
    "6": ("Atacante Externo (atacante_externo)", "pki/atacante_externo.crt", "pki/atacante_externo.key"),
}

ENDPOINTS = {
    "1": ("Gateway ZTNA -> https://localhost:8443/rrhh", "https://localhost:8443/rrhh", True),
    "2": ("Gateway ZTNA -> https://localhost:8443/finanzas", "https://localhost:8443/finanzas", True),
    "3": ("Microservicio Interno -> http://localhost:8002/finanzas", "http://localhost:8002/finanzas", False),
}

def realizar_peticion(nombre_id, cert_path, key_path, nombre_ep, url, es_https):
    os.system('cls' if os.name == 'nt' else 'clear')
    print("\n" + "="*65)
    print("  INICIANDO TRAZA ZERO TRUST")
    print("="*65)
    print("1. IDENTIFICACIÓN Y AUTENTICACIÓN (Capa TLS/mTLS)")
    print(f"   ├── Destino: {url}")
    print(f"   ├── Identidad presentada: {nombre_id}")

    ctx = ssl.create_default_context(cafile="pki/root_ca.crt")
    if cert_path and key_path:
        ctx.load_cert_chain(certfile=cert_path, keyfile=key_path)

    try:
        req = urllib.request.Request(url)
        if es_https:
            resp = urllib.request.urlopen(req, context=ctx, timeout=3)
        else:
            resp = urllib.request.urlopen(req, timeout=3)

        codigo = resp.getcode()
        cuerpo = json.loads(resp.read().decode('utf-8'))

        print("   └── ✅ AUTENTICACIÓN SUPERADA (Túnel establecido)")
        print("\n2. AUTORIZACIÓN ZTNA (Policy Enforcement Point)")
        print(f"   └── ✅ ACCESO PERMITIDO (HTTP {codigo})")
        print("\n3. RESPUESTA DEL MICROSERVICIO")
        print(f"   └── {json.dumps(cuerpo, ensure_ascii=False)}")

    except urllib.error.HTTPError as e:
        if e.code in (400, 495, 496):
            print(f"   └── ❌ FALLO EN AUTENTICACIÓN (HTTP {e.code} - Certificado rechazado por el servidor)")
            print("\n[2. AUTORIZACIÓN ZTNA]\n   └── ⏸️ No evaluado (Fallo criptográfico previo).")
        elif e.code == 403:
            print("   └── ✅ AUTENTICACIÓN SUPERADA (Certificado válido)")
            print("\n[2. AUTORIZACIÓN ZTNA (Policy Enforcement Point)]")
            print("   └── ❌ ACCESO DENEGADO (HTTP 403 Forbidden - Política ZTNA violada)")
        else:
            print(f"   └── ❌ Error HTTP inesperado: {e.code}")

    except ssl.SSLError as e:
        print("   └── ❌ FALLO EN AUTENTICACIÓN (TLS Handshake Abortado)")
        print(f"       └── Detalle OpenSSL: {e.reason}")
        print("\n[2. AUTORIZACIÓN ZTNA]\n   └── ⏸️ No evaluado (Conexión cerrada en handshake).")

    except Exception as e:
        print("   └── ❌ CONEXIÓN BLOQUEADA / RECHAZADA")
        print(f"       └── Detalle: {e}")

    print("="*65 + "\n")

def main():
    while True:
        print("--- CLIENTE DE PRUEBAS (Hospital_Insegus) ---")
        print("Selecciona Identidad (Certificado):")
        for k, v in IDENTIDADES.items():
            print(f"  {k}. {v[0]}")
        print("  0. Salir")
        op_id = input("Opción identidad > ").strip()
        if op_id == "0":
            break
        if op_id not in IDENTIDADES:
            continue

        print("\nSelecciona Recurso:")
        for k, v in ENDPOINTS.items():
            print(f"  {k}. {v[0]}")
        op_ep = input("Opción recurso > ").strip()
        if op_ep not in ENDPOINTS:
            continue

        nombre_id, cert, key = IDENTIDADES[op_id]
        nombre_ep, url, es_https = ENDPOINTS[op_ep]
        realizar_peticion(nombre_id, cert, key, nombre_ep, url, es_https)

if __name__ == "__main__":
    main()
