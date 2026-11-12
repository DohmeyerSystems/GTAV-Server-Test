#!/usr/bin/env bash
# =====================================================================
# vendor-resources.sh
# Lädt alle Fremd-Resources in exakt der Version aus resources.lock
# nach server-data/resources/ und übernimmt Qbox-Daten (items.lua,
# Item-Bilder, SQL). Ergebnis wird ins Git-Repo committet.
#
# Nutzung:
#   ./scripts/vendor-resources.sh            # alle Resources
#   ./scripts/vendor-resources.sh ox_lib     # nur ausgewählte
#
# ACHTUNG: Der Zielordner einer Resource wird komplett ersetzt.
#          Eigene Änderungen an Fremd-Resources gehen dabei verloren –
#          deshalb Anpassungen nur in [local]/ oder per Config-Overrides.
# =====================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK="$ROOT/resources.lock"
RES="$ROOT/server-data/resources"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

FILTER=("$@")

want() {
  [[ ${#FILTER[@]} -eq 0 ]] && return 0
  local n; for n in "${FILTER[@]}"; do [[ "$n" == "$1" ]] && return 0; done
  return 1
}

fetch_git() { # repo sha dir
  git init -q "$3"
  git -C "$3" fetch -q --depth 1 "https://github.com/$1" "$2"
  git -C "$3" -c advice.detachedHead=false checkout -q FETCH_HEAD
  rm -rf "$3/.git"
}

fetch_release() { # repo tag name dir
  local zip="$WORK/$3.zip"
  curl -fsSL --retry 3 -o "$zip" "https://github.com/$1/releases/download/$2/$3.zip"
  mkdir -p "$4"
  unzip -q "$zip" -d "$4"
  # Manche Zips enthalten <name>/..., andere liegen flach -> normalisieren
  if [[ -d "$4/$3" && ! -f "$4/fxmanifest.lua" ]]; then
    mv "$4/$3" "$WORK/_tmp_$3" && rm -rf "$4" && mv "$WORK/_tmp_$3" "$4"
  fi
}

install_dir() { # src dest
  rm -rf "$2"
  mkdir -p "$(dirname "$2")"
  mv "$1" "$2"
}

while read -r type name repo ref dest subpath; do
  [[ -z "${type:-}" || "$type" == \#* ]] && continue
  want "$name" || continue
  echo ">> $name ($repo @ $ref)"
  src="$WORK/$name"

  case "$type" in
    git)     fetch_git "$repo" "$ref" "$src" ;;
    release) fetch_release "$repo" "$ref" "$name" "$src" ;;
    *) echo "Unbekannter Typ: $type" >&2; exit 1 ;;
  esac
  [[ -n "${subpath:-}" ]] && src="$src/$subpath"

  case "$name" in
    cfx-server-data)
      # Chat kommt aus dem FXServer (resources_useSystemChat), Test-/Gamemode-Resources unnötig
      # runcode = Remote-Code-Ausführung -> aus Sicherheitsgründen entfernt
      rm -rf "$src/[gameplay]/chat" "$src/[gameplay]/[examples]" "$src/[gameplay]/chat-theme-example" \
             "$src/[system]/runcode" "$src/[test]" "$src/[gamemodes]" "$src/[local]"
      install_dir "$src" "$RES/$dest"
      ;;
    txAdminRecipe)
      # Nur Daten übernehmen: Qbox-Itemliste + Appearance-Tabellen (illenium-appearance)
      # (qbox.sql enthält zusätzlich Seed-Daten für Banking/Doorlock, die das Basis-Setup nicht braucht)
      mkdir -p "$ROOT/server-data/overrides/ox_inventory/data"
      cp "$src/items.lua" "$ROOT/server-data/overrides/ox_inventory/data/items.lua"
      python3 "$ROOT/scripts/extract-sql-tables.py" "$src/qbox.sql" "$ROOT/sql/01_appearance.sql" \
        playerskins player_outfits player_outfit_codes management_outfits
      ;;
    qbx_invimages)
      mkdir -p "$ROOT/server-data/overrides/ox_inventory/web/images"
      cp -r "$src/images/." "$ROOT/server-data/overrides/ox_inventory/web/images/"
      ;;
    *)
      install_dir "$src" "$RES/$dest/$name"
      ;;
  esac
done < "$LOCK"

# SQL-Dateien der Resources nach sql/ spiegeln (Reihenfolge = Import-Reihenfolge)
copy_sql() { [[ -f "$1" ]] && cp "$1" "$ROOT/sql/$2" || true; }
copy_sql "$RES/[qbx]/qbx_core/qbx_core.sql"       02_qbx_core.sql
copy_sql "$RES/[qbx]/qbx_vehicles/vehicles.sql"   03_qbx_vehicles.sql

# Overrides (items.lua, Bilder, ...) über die frisch geladenen Resources legen
"$ROOT/scripts/apply-overrides.sh"

echo "Fertig. Prüfen mit: git status"
