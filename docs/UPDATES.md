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
