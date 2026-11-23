1. REQUISITOS DEL SISTEMA

Este entorno está diseñado para ejecutarse en espacio de usuario sobre cualquier
distribución Linux sin necesidad de permisos de root ni docker. Solo necesitas tener instalados:
  - python3 (versión 3.8 o superior)
  - nginx 
  - openssl

Para comprobar o instalar los requisitos en Ubuntu/Debian:
$ sudo apt update && sudo apt install -y nginx openssl python3

Para Windows recomendamos utilizar WSL2 (o maquina virtual):
Si utilizas WSL2 copia la carpeta del proyecto dentro de tu directorio personal de Linux (~/practica_ztna) y evita trabajar desde rutas montadas de Windows (/mnt/c/). Otorga permisos de ejecución para los scripts de control, por ejemplo: chmod +x arrancar_entorno.sh.

2. ESTRUCTURA DE ARCHIVOS

  - generar_pki.sh       -> Script que crea la Root CA, Sub-CAs, certificados y CRL
  - arrancar_entorno.sh  -> Inicia los microservicios Python y el proxy Nginx
  - parar_entorno.sh     -> Detiene los microservicios Python y el proxy Nginx
  - nginx.conf           -> Configuración del Gateway ZTNA / Policy Enforcement Point
  - backend_rrhh.py      -> Microservicio interno de Recursos Humanos (puerto 8001)
  - backend_finanzas.py  -> Microservicio interno de Finanzas (puerto 8002)
  - cliente_ztna.py      -> Cliente interactivo para probar
  - conf/                -> Partes de nginx.conf: tls_mtls.conf (PKI/mTLS), authz.conf (autorización), logging.conf (logs)
  - pdp_autorizacion.py  -> PDP de autorización (127.0.0.1:8003), consultado por nginx con auth_request
  - politicas/roles.json -> Roles de cada usuario y roles exigidos por cada recurso
  - generar_secreto_gateway.sh -> Genera el secreto Gateway<->backends (lo llama arrancar_entorno.sh)
  - ocsp_responder.sh    -> Responder OCSP de la Sub-CA Empleados (127.0.0.1:8888)
  - tests/prueba_autorizacion.sh -> Pruebas de autorización y de acceso directo a los backends
  - tests/demo_roles.sh  -> Demostración: cambiar permisos sin reemitir certificados

3. PUESTA EN MARCHA

Abre una terminal dentro de esta carpeta y ejecuta los siguientes comandos:

$ ./generar_pki.sh (esto creará la carpeta ./pki/ con todos los certificados y claves).
$ ./arrancar_entorno.sh (arranca los microservicios)

Para hacer pruebas 
  $ python3 cliente_ztna.py

$ ./parar_entorno.sh (detiene los microservicios)