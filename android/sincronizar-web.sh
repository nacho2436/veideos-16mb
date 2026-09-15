#!/usr/bin/env bash
# ============================================================
#  Sincroniza la web (index.html) con la versión Android (APK)
#  Uso:  ./sincronizar-web.sh   (y luego compila con Gradle)
# ============================================================
CARPETA="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
ORIGEN="$CARPETA/../index.html"
DESTINO="$CARPETA/app/src/main/assets/web/index.html"

if [ ! -f "$ORIGEN" ]; then
  echo "Error: no se encontró $ORIGEN"
  exit 1
fi
mkdir -p "$(dirname "$DESTINO")"
cp "$ORIGEN" "$DESTINO"
echo "✔ index.html sincronizado con el APK"
echo "  Origen : $ORIGEN"
echo "  Destino: $DESTINO"
