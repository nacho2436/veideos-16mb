# 🎬 Comprime o divide videos a máximo 16 MB

Aplicación web local para **comprimir o dividir videos** hasta que pesen
máximo 16 MB (ideal para servicios que limitan el peso de archivos, como
envíos de WhatsApp o formularios web).

## Cómo se usa

1. Doble clic en el acceso **"Servidor Videos 16MB"** del escritorio
   (o ejecuta `./servidor-video.sh`)
2. Aparece un menú gráfico (zenity) o de terminal:
   - ▶ Iniciar servidor y abrir la app
   - ⏹ Detener servidor
   - 🌐 Abrir la app en el navegador
3. La app se usa en el navegador en `http://localhost:8000`

## Archivos

- `index.html` — la aplicación completa (compresión/división en el navegador)
- `servidor-video.sh` — menú para iniciar/detener el servidor local
  (python3 http.server, puerto 8000, con PID guardado y detección de
  sesiones anteriores)
- `Servidor Videos 16MB.desktop` — acceso directo para el escritorio

## Requisitos

- `python3` (servidor local)
- `zenity` opcional para el menú gráfico; sin él usa el menú de terminal

Sesión de origen: "Aplicación web para comprimir videos a MP4".
