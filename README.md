# 🎬 Comprime o divide videos a máximo 16 MB

[![Ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/F1F81BZQDW)

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

## Versión Android (APK, Kotlin)

- Proyecto en `android/`: app Kotlin con WebView que empaqueta la misma web
  (`index.html`) y guarda los videos procesados en **Descargas/Videos16MB**
  mediante un puente nativo (`AndroidPuente.guardarDescarga`).
- Requisitos para compilar: JDK 17 y Android SDK (plataforma 34).

```bash
cd android
./sincronizar-web.sh      # copia index.html del repositorio al APK
gradle assembleDebug      # genera app/build/outputs/apk/debug/app-debug.apk
```

- Tras cambiar `index.html`, ejecuta `sincronizar-web.sh` y recompila:
  así la web y el APK quedan siempre sincronizados.

Sesión de origen: "Aplicación web para comprimir videos a MP4".
