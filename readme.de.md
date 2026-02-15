# FlyCam – World of Warcraft Addon

Passt die Kameradistanz automatisch an, wenn du in World of Warcraft (Retail) auf ein Flugreittier auf- oder absteigst.

## Funktionen

- Sanfte Kamerazoom-Animation beim Auf- und Absteigen.
- Unterschiedliche Zoom-Einstellungen für Flug- und Boden-Mounts.
- Dragonriding-Rennen-Erkennung mit optionaler First-Person-Ansicht.
- Erkennung von Flugreittieren über `C_MountJournal` und `mountTypeID`.
- Debug-Befehl `/flycamdebug` um aktuelles Reittier und Typ anzuzeigen.
- Modulare Architektur für einfache Erweiterungen.

## Dateien

| Datei | Beschreibung |
|-------|--------------|
| `FlyCam.lua` | Haupteinstiegspunkt, Events, Standardwerte |
| `FlyCam_Mounts.lua` | Reittier-Erkennung, Flugtypen, Debug-Befehle |
| `FlyCam_Camera.lua` | Sanfter Zoom, Rennen-First-Person-Logik |
| `FlyCam_Config.lua` | Optionsmenü (Blizzard Settings API) |

## Konfiguration

- **Flug-Zoom-Stufen**: Wie viele Stufen herausgezoomt wird beim Aufsteigen auf ein Flugreittier.
- **Boden-Zoom-Stufen**: Wie viele Stufen eingezoomt wird beim Absteigen.
- **Rennen-Zoom-Stufen**: Kameradistanz nach einem Dragonriding-Rennen.
- **Übergangs-Dauer**: Wie lange die sanfte Zoom-Animation dauert.
- **First-Person im Rennen**: Optionale First-Person-Ansicht während Dragonriding-Rennen.

## Verwendung

- Konfiguriere unter `Esc → Optionen → AddOns → FlyCam`.
- Verwende `/flycamdebug` während du auf einem Reittier sitzt, um die `mountTypeID` zu sehen und neue Flugreittiere hinzuzufügen.
- Bearbeite `FlyCam_Mounts.lua` um neue `mountTypeIDs` zur `FLYING_TYPES` Tabelle hinzuzufügen.

## Installation

1. Kopiere den Ordner `FlyCam` in dein Verzeichnis  
   `World of Warcraft/_retail_/Interface/AddOns/`
2. Stelle sicher, dass sich folgende Dateien im Ordner befinden:
   - `FlyCam/FlyCam.toc`
   - `FlyCam/FlyCam.lua`
   - `FlyCam_FlyCam_Mounts.lua`
   - `FlyCam_FlyCam_Camera.lua`
   - `FlyCam_FlyCam_Config.lua`
3. Starte WoW neu (oder lade die UI mit `/reload`) und aktiviere das Addon im AddOn-Menü auf dem Charakterauswahlbildschirm.

## Dank

Original: Usires
Refaktort: Nix 🐧
