#!/usr/bin/env bash
# =====================================================================
# install-fxserver.sh – lädt die FXServer-Linux-Artifacts nach ./fxserver
#
#   ./scripts/install-fxserver.sh                 # "recommended" Build
#   FX_CHANNEL=latest ./scripts/install-fxserver.sh
#   FX_URL=<direkter fx.tar.xz-Link> ./scripts/install-fxserver.sh
#
# Hinweis: oxmysql v2.14.x benötigt mindestens Server-Build 12913,
#          qbx_core mindestens 10731. Ältere Builds starten nicht sauber.
# =====================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$ROOT/fxserver"
CHANNEL="${FX_CHANNEL:-recommended}"   # recommended | latest | optional
MIN_BUILD=12913

for bin in curl tar xz python3; do
  command -v "$bin" >/dev/null || { echo "Fehlt: $bin  (apt install curl tar xz-utils python3)"; exit 1; }
done

if [[ -z "${FX_URL:-}" ]]; then
  json="$(curl -fsSL https://changelogs-live.fivem.net/api/changelog/versions/linux/server)"
  read -r BUILD FX_URL < <(python3 -c '
import json,sys
d=json.loads(sys.argv[1]); c=sys.argv[2]
print(d[c], d[c+"_download"])' "$json" "$CHANNEL")
  echo "Kanal: $CHANNEL  ->  Build $BUILD"
  if (( BUILD < MIN_BUILD )); then
    echo "WARNUNG: Build $BUILD < $MIN_BUILD (oxmysql-Minimum). Ggf. FX_CHANNEL=latest nutzen."
  fi
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
echo "Lade $FX_URL"
curl -fL --retry 3 -o "$tmp/fx.tar.xz" "$FX_URL"

rm -rf "$DEST.new" && mkdir -p "$DEST.new"
tar -xJf "$tmp/fx.tar.xz" -C "$DEST.new"
rm -rf "$DEST.old"; [[ -d "$DEST" ]] && mv "$DEST" "$DEST.old"
mv "$DEST.new" "$DEST"
rm -rf "$DEST.old"

echo "FXServer installiert in $DEST"
echo "${BUILD:-custom}" > "$DEST/.build"
