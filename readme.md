# :uk: FlyCam – World of Warcraft Addon

FlyCam automatically adjusts the camera distance when you mount or dismount flying mounts in World of Warcraft (Retail).

## Features

- Smooth camera zoom animation when mounting/dismounting.
- Separate zoom step settings for flying and ground states and races.
- Optional: Switch to first person when a race start. Zooms back out when the race is finished.
- Detection of flying mounts via `C_MountJournal` mountTypeID.
- Debug command `/flycamdebug` to inspect active mount and type.

## Usage

- Configure under `Esc → Options → AddOns → FlyCam`.
- Use `/flycam fly <steps>`, `/flycam ground <steps>`, `/flycam duration <seconds>` for quick tweaks.
- Use `/flycamdebug` while mounted to see `mountTypeID` and add it to the `FLYING_TYPES` table if needed.

## Installation

Copy the `FlyCam` folder into your `World of Warcraft/_retail_/Interface/AddOns/` directory and enable the addon in the character selection AddOns menu.

---

# :de: FlyCam – World of Warcraft Addon

FlyCam passt die Kameradistanz automatisch an, wenn du in World of Warcraft (Retail) auf einen Flugreittier auf- oder absteigst.

## Funktionen

- Sanfte Kamerazoom-Animation beim Auf- und Absteigen.
- Unterschiedliche Zoom-Schritte für Flug- und Boden-Zustand, sowie in Rennen.
- Optional: First Person-Sicht beim Start eines Rennens. Kamera zoomt wieder auf den Charakter nach Rennen-Ende.
- Erkennung von Flugreittieren über `C_MountJournal` und `mountTypeID`.
- Debug-Befehl `/flycamdebug`, um das aktive Reittier und den Typ zu prüfen.

## Verwendung

- Konfiguration unter `Esc → Optionen → AddOns → FlyCam`.
- Schnelle Anpassungen per Chat:
  - `/flycam fly <Schritte>` – Zoom-Schritte beim Flugreittier.
  - `/flycam ground <Schritte>` – Zoom-Schritte beim Absteigen / Boden.
  - `/flycam duration <Sekunden>` – Dauer der Übergangsanimation.
- Verwende `/flycamdebug`, während du auf einem Reittier sitzt, um:
  - den Namen des aktiven Reittiers,
  - seine `mountTypeID`
  - und den aktuellen FlyCam-Status (fliegend oder nicht) zu sehen.
- Wenn ein Flugreittier nicht als fliegend erkannt wird, kannst du die ausgegebene `mountTypeID` in der Tabelle `FLYING_TYPES` in `FlyCam.lua` ergänzen.

## Installation

1. Kopiere den Ordner `FlyCam` in dein Verzeichnis  
   `World of Warcraft/_retail_/Interface/AddOns/`
2. Stelle sicher, dass sich darin mindestens folgende Dateien befinden:
   - `FlyCam/FlyCam.toc`
   - `FlyCam/FlyCam.lua`
3. Starte WoW neu (oder lade die UI mit `/reload`) und aktiviere das Addon im AddOn-Menü auf dem Charakterauswahlbildschirm.
