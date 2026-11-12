#!/usr/bin/env bash
# =====================================================================
# start.sh – startet den Server
#
#   ./scripts/start.sh            # mit txAdmin (Web-UI auf Port 40120)
#   ./scripts/start.sh --direct   # ohne txAdmin, direkt mit server.cfg
#
# txAdmin-Ersteinrichtung: im Setup "Existing Server Data" wählen und
# als Pfad <repo>/server-data angeben, CFG-Datei: server.cfg
# =====================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FX="$ROOT/fxserver/run.sh"
DATA="$ROOT/server-data"

[[ -x "$FX" ]] || { echo "FXServer fehlt -> ./scripts/install-fxserver.sh"; exit 1; }
[[ -f "$DATA/secrets.cfg" ]] || { echo "secrets.cfg fehlt -> cp server-data/secrets.cfg.example server-data/secrets.cfg"; exit 1; }

cd "$DATA"
if [[ "${1:-}" == "--direct" ]]; then
  exec "$FX" +exec server.cfg   # mit +exec startet FXServer ohne txAdmin
else
  # txData außerhalb von server-data halten (Laufzeitdaten, nicht im Git)
  exec "$FX" +set txDataPath "$ROOT/txData"
fi
