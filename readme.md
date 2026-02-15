# FlyCam – World of Warcraft Addon

Automatically adjusts the camera distance when you mount or dismount flying mounts in World of Warcraft (Retail).

## Features

- Smooth camera zoom animation when mounting/dismounting.
- Separate zoom step settings for flying and ground states.
- Dragonriding race detection with optional first-person view.
- Detection of flying mounts via `C_MountJournal` mountTypeID.
- Debug command `/flycamdebug` to inspect active mount and type.
- Modular architecture for easy extension.

## Files

| File | Description |
|------|-------------|
| `FlyCam.lua` | Main entry point, events, defaults |
| `FlyCam_Mounts.lua` | Mount detection, flying type IDs, debug commands |
| `FlyCam_Camera.lua` | Smooth zoom, race first-person handling |
| `FlyCam_Config.lua` | Options panel (Blizzard Settings API) |

## Configuration

- **Flying zoom steps**: How many notches to zoom out when mounting a flying mount.
- **Ground zoom steps**: How many notches to zoom in when dismounting.
- **Race zoom steps**: Camera distance after a dragonriding race.
- **Transition duration**: How long the smooth zoom animation takes.
- **First-person in races**: Optional first-person view during dragonriding races.

## Usage

- Configure under `Esc → Options → AddOns → FlyCam`.
- Use `/flycamdebug` while mounted to see mountTypeID and add new flying mounts.
- Edit `FlyCam_Mounts.lua` to add new mountTypeIDs to the `FLYING_TYPES` table.

## Installation

Copy the `FlyCam` folder into your `World of Warcraft/_retail_/Interface/AddOns/` directory and enable the addon in the character selection AddOns menu.

## Credits

Original: Usires
Refactored: Nix 🐧
