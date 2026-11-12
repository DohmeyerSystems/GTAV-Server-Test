#!/usr/bin/env bash
# =====================================================================
# apply-overrides.sh
# Kopiert alles aus server-data/overrides/<resource>/... über die
# gleichnamige Resource in server-data/resources/**/<resource>/.
#
# Zweck: Eigene Konfigurationen (z.B. qbx_core/config/*.lua,
# ox_inventory/data/items.lua) getrennt von den Fremd-Resources halten,
# damit ein Update via vendor-resources.sh sie nicht überschreibt.
# =====================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OVR="$ROOT/server-data/overrides"
RES="$ROOT/server-data/resources"

[[ -d "$OVR" ]] || exit 0

for dir in "$OVR"/*/; do
  name="$(basename "$dir")"
  target="$(find "$RES" -type f -name fxmanifest.lua -path "*/$name/fxmanifest.lua" -printf '%h\n' | head -n1)"
  if [[ -z "$target" ]]; then
    echo "WARN: Override für '$name' – Resource nicht gefunden, übersprungen" >&2
    continue
  fi
  cp -r "$dir." "$target/"
  echo ">> Overrides angewendet: $name -> ${target#"$ROOT"/}"
done
