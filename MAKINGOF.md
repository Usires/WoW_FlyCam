# FlyCam Making Of

## Version History

### v0.3 — Modular Refactor (2026-02-15)

Split the monolithic `FlyCam.lua` into logical modules:

**Why?**
- Single file was ~500 lines, hard to navigate
- Options panel code was repetitive (DRY principle)
- Mount detection and camera logic coupled together

**Changes:**
- `FlyCam.lua` — Entry point, events, defaults (60 lines)
- `FlyCam_Mounts.lua` — All mount detection, flying type IDs, debug commands (180 lines)
- `FlyCam_Camera.lua` — Smooth zoom logic, race detection, first-person handling (100 lines)
- `FlyCam_Config.lua` — Options panel with slider factory (220 lines)

**Benefits:**
- Each module has a single responsibility
- Easier to add new mount types (just edit `FLYING_TYPES` table)
- Slider creation now uses a factory function (DRY)
- Future: can add new features without touching main file

### v0.2 — Initial Release

- Smooth zoom on mount/dismount
- Flying mount detection via mountTypeID
- Dragonriding race detection
- First-person mode in races
- Options panel via Blizzard Settings API

## Technical Notes

### Mount Detection
Uses `C_MountJournal.GetMountIDs()` and `C_MountJournal.GetMountInfoExtraByID()` to get `mountTypeID`. Flying types are stored in a lookup table.

### Race Detection
Uses `AuraUtil.ForEachAura` with safety checks for secret/Blocked fields (WoW 10.2+ API changes).

### Smooth Zoom
Implements a recursive `C_Timer.After` chain to step through zoom levels with configurable interval.

## Future Ideas

- [ ] Add support for custom zoom profiles
- [ ] Per-mount-type zoom settings
- [ ] Integration with WeakAuras
- [ ] Telemetry-free analytics (optional)
