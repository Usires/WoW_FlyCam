# FlyCam – World of Warcraft Addon (v1.0)

Passt die Kameradistanz automatisch an, wenn du in World of Warcraft (Retail) auf ein Flugreittier auf- oder absteigst.

## Funktionen

- Sanfte Kamerazoom-Animation beim Auf- und Absteigen.
- Unterschiedliche Zoom-Einstellungen für Flug- und Boden-Mounts.
- Dragonriding-Rennen-Erkennung mit optionaler First-Person-Ansicht.
- Erkennung von Flugreittieren über `C_MountJournal` und `mountTypeID`.
- Debug-Befehl `/flycamdebug` um aktuelles Reittier und Typ anzuzeigen.
- Konfigurierbar über Blizzard Optionsmenü.

## Dateien

| Datei | Beschreibung |
|-------|--------------|
| `FlyCam.lua` | Einzelfile-AddOn (alle Module zusammengeführt) |
| `FlyCam.toc` | AddOn-Metadaten |

## Konfiguration

- **Flug-Zoom-Stufen**: Wie viele Stufen herausgezoomt wird beim Aufsteigen auf ein Flugreittier.
- **Boden-Zoom-Stufen**: Wie viele Stufen eingezoomt wird beim Absteigen.
- **Rennen-Zoom-Stufen**: Kameradistanz nach einem Dragonriding-Rennen.
- **Übergangs-Dauer**: Wie lange die sanfte Zoom-Animation dauert.
- **First-Person im Rennen**: Optionale First-Person-Ansicht während Dragonriding-Rennen.

## Verwendung

- Konfiguriere unter `Esc → Optionen → AddOns → FlyCam`.
- Verwende `/flycamdebug` während du auf einem Reittier sitzt, um die `mountTypeID` zu sehen und neue Flugreittiere hinzuzufügen.
- Bearbeite `FlyCam.lua` um neue `mountTypeIDs` zur `FlyCam.Mounts.FLYING_TYPES` Tabelle hinzuzufügen.

## Architektur

```
FlyCam
├── defaults      - Standardeinstellungen
├── Mounts       - Reittier-Erkennung & Typ-Prüfung
├── Camera       - Sanfter Zoom & Rennen-Handling
└── Config       - Optionsmenü
```

## Installation

1. Kopiere den Ordner `FlyCam` in dein Verzeichnis  
   `World of Warcraft/_retail_/Interface/AddOns/`
2. Starte WoW neu (oder lade die UI mit `/reload`) und aktiviere das Addon im AddOn-Menü auf dem Charakterauswahlbildschirm.

## Dank

Original: Usires
Refaktort: Nix 🐧
