#!/usr/bin/env bash
# ============================================================
#  Servidor local — app "Comprime o divide videos a máximo 16 MB"
#  Menú para iniciar o detener el servidor que sirve index.html
#  Interfaz: ventana gráfica (zenity) o menú de texto en terminal
# ============================================================
CARPETA="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
PIDFILE="$CARPETA/.servidor-video.pid"
PUERTO="${SERVIDOR_PUERTO:-8000}"
URL="http://localhost:$PUERTO"

# ---- elegir interfaz ----
if [ -n "$SERVIDOR_UI" ]; then UI="$SERVIDOR_UI"
elif command -v zenity >/dev/null 2>&1 && [ -n "$DISPLAY$WAYLAND_DISPLAY" ]; then UI=zenity
else UI=texto
fi

if [ "$UI" = "zenity" ]; then
  verde()   { echo "$*"; }
  rojo()    { echo "$*"; }
  amarillo(){ echo "$*"; }
else
  verde()   { printf '\033[1;32m%s\033[0m\n' "$*"; }
  rojo()    { printf '\033[1;31m%s\033[0m\n' "$*"; }
  amarillo(){ printf '\033[1;33m%s\033[0m\n' "$*"; }
fi

pid_guardado() { [ -f "$PIDFILE" ] && cat "$PIDFILE" 2>/dev/null; }

proceso_vivo() {
  local pid; pid="$(pid_guardado)"
  [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

responde() { curl -s -o /dev/null --max-time 2 "$URL"; }

servidor_ok() { proceso_vivo && responde; }

estado() {
  if servidor_ok; then
    verde "● Servidor EN MARCHA (PID $(pid_guardado)) — app disponible en $URL"
    return 0
  fi
  rojo "○ Servidor DETENIDO"
  return 1
}

estado_texto() {
  if servidor_ok; then
    echo "● Servidor EN MARCHA — app disponible en $URL"
  else
    echo "○ Servidor DETENIDO"
  fi
}

abrir_navegador() {
  if [ -n "$SERVIDOR_SIN_NAVEGADOR" ]; then
    echo "(apertura del navegador omitida)"
    return
  fi
  echo "Abriendo $URL en tu navegador…"
  xdg-open "$URL" >/dev/null 2>&1 || amarillo "No se pudo abrir el navegador: visita $URL a mano."
}

iniciar() {
  if servidor_ok; then
    amarillo "El servidor ya está en marcha."
    abrir_navegador
    return 0
  fi
  if ! command -v python3 >/dev/null; then
    rojo "Error: no se encontró python3 en el sistema."
    return 1
  fi
  if responde; then
    # ¿ya hay un servidor http.server en el puerto? (iniciado a mano o en otra sesión)
    local pids
    pids="$(pgrep -f "python3 -m http.server $PUERTO" 2>/dev/null | head -n1)"
    if [ -n "$pids" ]; then
      echo "$pids" > "$PIDFILE"
      amarillo "El servidor ya estaba en marcha: ahora queda bajo control de este menú."
      abrir_navegador
      return 0
    fi
    rojo "El puerto $PUERTO ya lo usa otro programa distinto. Ciérralo o cambia el puerto en este script."
    return 1
  fi
  echo "Iniciando servidor desde: $CARPETA"
  (
    cd "$CARPETA" || exit 1
    nohup python3 -m http.server "$PUERTO" >/dev/null 2>&1 &
    echo $! > "$PIDFILE"
  )
  local i
  for i in 1 2 3 4 5; do
    responde && break
    sleep 1
  done
  if responde; then
    verde "✔ Servidor iniciado (PID $(pid_guardado))"
    echo "Puedes cerrar esta ventana: el servidor sigue activo en segundo plano."
    echo "Para detenerlo, abre este acceso otra vez y elige «Detener servidor»."
    abrir_navegador
    return 0
  fi
  rojo "No se pudo iniciar el servidor."
  rm -f "$PIDFILE"
  return 1
}

detener() {
  local pid pids
  pid="$(pid_guardado)"
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null
    sleep 1
    kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null
    rm -f "$PIDFILE"
    verde "✔ Servidor detenido."
    return 0
  fi
  # sin pidfile: recoger procesos sueltos de este puerto (de sesiones anteriores)
  pids="$(pgrep -f "python3 -m http.server $PUERTO" 2>/dev/null)"
  if [ -n "$pids" ]; then
    echo "$pids" | xargs -r kill 2>/dev/null
    rm -f "$PIDFILE"
    verde "✔ Servidor detenido."
    return 0
  fi
  rm -f "$PIDFILE"
  amarillo "El servidor ya estaba detenido."
  return 0
}

# ================= interfaz gráfica (zenity) =================
run_accion() {
  local out rc
  out="$("$1" 2>&1)"; rc=$?
  if [ -n "$out" ]; then
    if [ $rc -eq 0 ]; then
      zenity --info --title 'Servidor Videos 16MB' --text "$out" --width 400 2>/dev/null
    else
      zenity --error --title 'Servidor Videos 16MB' --text "$out" --width 400 2>/dev/null
    fi
  fi
  return $rc
}

ui_zenity() {
  while true; do
    local sel
    sel="$(zenity --list \
      --title 'Servidor · App de videos 16 MB' \
      --text "$(estado_texto)" \
      --width 460 --height 330 \
      --hide-header --column 'Acción' \
      '▶   Iniciar servidor y abrir la app' \
      '⏹   Detener servidor' \
      '🌐   Abrir la app en el navegador' \
      '🔄   Actualizar estado' \
      '✖   Salir' 2>/dev/null)" || exit 0
    case "$sel" in
      *Iniciar*)  run_accion iniciar ;;
      *Detener*)  run_accion detener ;;
      *Abrir*)
        if servidor_ok; then abrir_navegador; else
          zenity --error --title 'Servidor Videos 16MB' \
            --text 'El servidor está detenido: usa «Iniciar servidor» primero.' 2>/dev/null
        fi ;;
      *Actualizar*) : ;;
      *Salir*) exit 0 ;;
    esac
  done
}

# ================= interfaz de texto (terminal) =================
ui_texto() {
  while true; do
    echo ""
    echo "══════════════════════════════════════════════════"
    echo "   APP DE VIDEOS · SERVIDOR LOCAL (puerto $PUERTO)"
    echo "══════════════════════════════════════════════════"
    estado
    echo ""
    echo "  1) ▶   Iniciar servidor y abrir la app"
    echo "  2) ⏹   Detener servidor"
    echo "  3) 🌐   Abrir la app en el navegador (ya iniciada)"
    echo "  4) 🔄   Actualizar estado"
    echo "  5) ✖   Salir de este menú"
    echo ""
    printf "Elige una opción [1-5]: "
    read -r opt || break
    case "$opt" in
      1) iniciar ;;
      2) detener ;;
      3) if servidor_ok; then abrir_navegador; else rojo "El servidor está detenido: usa la opción 1 primero."; fi ;;
      4) : ;;
      5) exit 0 ;;
      *) amarillo "Opción no válida." ;;
    esac
  done
}

# Adoptar automáticamente un servidor ya en marcha (iniciado a mano o en
# otra sesión) para que el estado del menú sea correcto desde el inicio.
if ! proceso_vivo && responde; then
  pids="$(pgrep -f "python3 -m http.server $PUERTO" 2>/dev/null | head -n1)"
  [ -n "$pids" ] && echo "$pids" > "$PIDFILE"
fi

if [ "$UI" = "zenity" ]; then ui_zenity; else ui_texto; fi
