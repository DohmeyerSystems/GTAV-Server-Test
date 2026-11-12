# GTA V Server – Qbox Basis-Setup

Kompletter, versionierter FiveM-Server auf Basis von **[Qbox](https://docs.qbox.re/)** (moderner QBCore-Fork, ox-basiert).
Alle Resources liegen **fest gepinnt im Repo** – ein `git clone` + 4 Befehle ergeben einen lauffähigen Server.

> Status: **Basis-Framework** (Charaktererstellung, Spawn, Inventar, Target, Fahrzeuge/Schlüssel, Adminmenü).
> Keine Jobs, kein Voice, kein Handy – das wird schrittweise ergänzt.

---

## Inhalt

| Ordner / Datei | Zweck |
|---|---|
| `resources.lock` | **Single Source of Truth**: welche Fremd-Resource in welcher Version |
| `server-data/` | FXServer-Datenordner (`server.cfg`, Configs, `resources/`) |
| `server-data/resources/[cfx-default]` | CFX-Basis (mapmanager, spawnmanager, …) |
| `server-data/resources/[ox]` | oxmysql, ox_lib, ox_target, ox_inventory |
| `server-data/resources/[qbx]` | qbx_core, qbx_spawn, qbx_vehicles, qbx_vehiclekeys, qbx_idcard, qbx_adminmenu |
| `server-data/resources/[standalone]` | illenium-appearance, bob74_ipl, MugShotBase64 |
| `server-data/resources/[local]` | **eigene Scripts** (wird nie überschrieben) |
| `server-data/overrides/` | eigene Anpassungen an Fremd-Resources (überleben Updates) |
| `sql/` | Datenbankschema (Import-Reihenfolge = Dateiname) |
| `scripts/` | Installation, Start, Backup, Resource-Updates |
| `deploy/fivem.service` | systemd-Unit |

### Enthaltene Resources

| Resource | Version | Warum |
|---|---|---|
| oxmysql | v2.14.3 | DB-Treiber |
| ox_lib | v3.42.2 | UI/Utility-Library (Pflicht für Qbox) |
| ox_target | v1.18.1 | Interaktion (Third-Eye) |
| ox_inventory | v2.48.1 | Inventar (Qbox-Standard) |
| qbx_core | v1.24.1 | Framework-Kern inkl. Multicharacter & qb-core-Bridge |
| qbx_spawn | v0.1.1 | Spawn-Auswahl |
| qbx_vehicles | v1.4.2 | Fahrzeug-Datenhaltung |
| qbx_vehiclekeys | v1.0.2 | Schlüssel – von qbx_core-Config aufgerufen |
| qbx_idcard | Commit `6462f33` | **Pflicht**: qbx_core gibt neuen Charakteren Ausweis/Führerschein |
| qbx_adminmenu | v0.1.0 | Adminmenü (`/admin`) |
| illenium-appearance | v5.7.0 | Charakter-Editor/Kleidung |
| bob74_ipl | Commit `037dd6c` | Interiors/IPLs |
| MugShotBase64 | Commit `9fac1e8` | Abhängigkeit von qbx_idcard |

Zusätzlich übernommen: Qbox-Itemliste (`items.lua`) und Item-Bilder → `server-data/overrides/ox_inventory/`.

---

## Installation (Ubuntu 22.04/24.04 oder Debian 12)

**Voraussetzungen:** 4+ vCPU, 8 GB RAM, ~10 GB Platz, offene Ports **30120 TCP+UDP** (Spiel) und **40120 TCP** (txAdmin), ein License Key von [portal.cfx.re](https://portal.cfx.re).

1. Pakete installieren:

```bash
sudo apt update && sudo apt install -y git curl xz-utils python3 unzip mariadb-server
```

2. Repo klonen (Beispielpfad `/opt/gtav-server`, passt zur systemd-Unit):

```bash
sudo git clone https://github.com/DohmeyerSystems/GTAV-Server-Test.git /opt/gtav-server
```

3. FXServer-Artifacts laden (landen in `fxserver/`, nicht im Git):

```bash
cd /opt/gtav-server && ./scripts/install-fxserver.sh
```

4. Datenbank anlegen + Schema importieren (Passwort selbst wählen):

```bash
sudo DB_PASS='EIN-STARKES-PASSWORT' ./scripts/setup-database.sh
```

5. Geheimnisse eintragen (License Key, DB-Passwort, Admin-Identifier):

```bash
cp server-data/secrets.cfg.example server-data/secrets.cfg && nano server-data/secrets.cfg
```

6. Starten:

```bash
./scripts/start.sh
```

Beim ersten Start mit txAdmin: Web-UI `http://<server-ip>:40120` öffnen, PIN aus der Konsole eingeben, **„Existing Server Data“** wählen, Pfad `/opt/gtav-server/server-data`, CFG `server.cfg`.
Ohne txAdmin: `./scripts/start.sh --direct`.

Optional als Dienst (User `fivem` vorher anlegen und Besitzer von `/opt/gtav-server` machen):

```bash
sudo cp deploy/fivem.service /etc/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl enable --now fivem
```

### Ersten Admin festlegen

Nach dem ersten Join die eigene ID aus txAdmin bzw. der Konsole holen und in `secrets.cfg` eintragen:

```
add_principal identifier.fivem:1234567 group.admin
```

---

## Arbeiten mit dem Repo

- **Eigene Scripts** → `server-data/resources/[local]/<name>/` und in `server.cfg` `ensure [local]` aktivieren.
- **Fremd-Resource hinzufügen** → Zeile in `resources.lock` ergänzen, `./scripts/vendor-resources.sh <name>`, in `server.cfg` sicherstellen, dass sie gestartet wird, SQL ggf. nach `sql/` legen.
- **Config einer Fremd-Resource ändern** (z.B. `qbx_core/config/shared.lua`) → Datei nach `server-data/overrides/qbx_core/config/shared.lua` kopieren, dort ändern, `./scripts/apply-overrides.sh`. So überlebt die Änderung Updates.
- **Updates** → siehe [docs/UPDATES.md](docs/UPDATES.md).
- **Backups** → `./scripts/backup-db.sh` (Dumps in `backups/`, nicht im Git).

### Was NIE ins Repo gehört

`secrets.cfg` (License Key, DB-Passwort), `txData/`, `cache/`, Datenbank-Dumps. Ist per `.gitignore` abgesichert – trotzdem vor jedem Commit `git status` prüfen.
