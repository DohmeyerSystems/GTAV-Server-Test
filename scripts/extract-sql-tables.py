#!/usr/bin/env python3
"""Extrahiert ausgewählte CREATE TABLE-Statements aus einer SQL-Datei.
Nutzung: extract-sql-tables.py <quelle.sql> <ziel.sql> <tabelle> [<tabelle> ...]"""
import re, sys

src, dst, tables = sys.argv[1], sys.argv[2], set(sys.argv[3:])
sql = open(src, encoding="utf-8").read()
out = ["-- Automatisch erzeugt von scripts/extract-sql-tables.py aus Qbox txAdminRecipe/qbox.sql",
       "-- Enthält nur: " + ", ".join(sorted(tables)), ""]
found = set()
for m in re.finditer(r"CREATE TABLE IF NOT EXISTS `([^`]+)`.*?\)\s*ENGINE=[^;]*;", sql, re.S):
    if m.group(1) in tables:
        found.add(m.group(1))
        out.append(m.group(0) + "\n")
missing = tables - found
if missing:
    sys.exit(f"Tabellen nicht gefunden: {', '.join(sorted(missing))}")
open(dst, "w", encoding="utf-8").write("\n".join(out))
