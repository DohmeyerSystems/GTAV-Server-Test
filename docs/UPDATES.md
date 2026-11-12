# Updates & Wartung

## Resource aktualisieren

1. Neue Version nachsehen (GitHub → Releases der Resource).
2. In `resources.lock` die `ref` ändern (Tag bei `release`, Commit-SHA bei `git`).
3. Laden:

```bash
./scripts/vendor-resources.sh qbx_core
```

4. Änderungen prüfen:

```bash
git diff --stat
```

5. **SQL prüfen**: Hat sich die `.sql`-Datei der Resource geändert (`git diff sql/`)? Die Dateien nutzen `CREATE TABLE IF NOT EXISTS` – neue Spalten in bestehenden Tabellen werden dadurch **nicht** angelegt. Release-Notes der Resource lesen und ggf. `ALTER TABLE` manuell ausführen (vorher `./scripts/backup-db.sh`).
6. Auf einem Testserver starten, dann committen.

Hinweis: `vendor-resources.sh` ersetzt den Resource-Ordner komplett. Eigene Änderungen gehören nach `server-data/overrides/<resource>/` – diese werden danach automatisch wieder drübergelegt.

## FXServer (Artifacts) aktualisieren

```bash
./scripts/install-fxserver.sh
```

Lädt den aktuell als „recommended“ markierten Build. Mindestens Build **12913** (Vorgabe von oxmysql v2.14.x).

## Game Build

`sv_enforceGameBuild 3258` in `server.cfg`. Höherer Build = neuere DLC-Inhalte, aber alle Spieler müssen ihn laden. Nur ändern, wenn eine Resource es verlangt.

## Overrides von Code-Dateien (bei Updates prüfen!)

Die meisten Overrides betreffen Config-Dateien. Folgender Override ersetzt eine **Code-Datei** und muss nach einem Update der Resource mit dem neuen Original abgeglichen werden (sonst gehen Fixes aus dem Update verloren):

| Override | Grund |
|---|---|
| `overrides/qbx_adminmenu/server/main.lua` | `GiveKeys`-Aufruf nur, wenn qbx_vehiclekeys läuft (Resource entfernt) |

Abgleich nach Änderung der Version in `resources.lock`:

```bash
SKIP_OVERRIDES=1 ./scripts/vendor-resources.sh qbx_adminmenu
```

```bash
diff "server-data/resources/[qbx]/qbx_adminmenu/server/main.lua" server-data/overrides/qbx_adminmenu/server/main.lua
```

Ist der Unterschied mehr als die markierte `OVERRIDE`-Stelle, die neue Originaldatei nach `overrides/` kopieren und die `OVERRIDE`-Stelle dort erneut einbauen. Danach:

```bash
./scripts/apply-overrides.sh
```
