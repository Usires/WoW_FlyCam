# FlyCam Making Of

## Version History

### v1.0 — Feature Complete (2026-03-03)

Simplified mount detection logic and squashed bugs.

**What changed:**
- Removed excluded mounts feature entirely — now uses `IsMountFlyingByType()` to detect flying mounts
- Vendor/ground mounts automatically ignored (no unwanted zoom)
- Added mount type 424 (WoW 10.2+ dragonriding)
- Added `wasZoomedOut` state tracking for proper dismount zoom-back
- Fixed event frame not receiving events (added `f:Show()`)
- Cleaned up options panel UI

**Final feature set:**
- Automatic zoom out on flying mount
- Automatic zoom in on dismount (only if actually zoomed out)
- No zoom for vendor/ground mounts
- Dragonriding race first-person option
- Configurable zoom steps and duration

### v0.3.1 — Single-File Merge (2026-02-17)

Merged all modules back into a single `FlyCam.lua` file.

**Why?**
- WoW addon load order issues with separate Lua files
- Simpler distribution (one file instead of four)
- Easier debugging (everything in one place)

**Changes:**
- Combined `FlyCam.lua`, `FlyCam_Mounts.lua`, `FlyCam_Camera.lua`, `FlyCam_Config.lua` into one
- Added Clean Code improvements:
  - Extracted magic numbers to constants (`ZOOM_FACTOR_FLYING`)
  - Added JSDoc-style comments for all functions
  - Clear section headers and documentation
  - Single responsibility within sections

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
Uses `AuraUtil.ForEachAura` with safety checks for secret/blocked fields (WoW 10.2+ API changes).

### Smooth Zoom
Implements a recursive `C_Timer.After` chain to step through zoom levels with configurable interval.

### Clean Code Principles Applied

| Principle | Implementation |
|-----------|----------------|
| Single Responsibility | Each section (Mounts, Camera, Config) does one thing |
| DRY | Slider factory, CopyDefaults function |
| Meaningful Names | `IsOnFlyingMount()`, `ApplyForState()` |
| Constants | `ZOOM_FACTOR_FLYING = 2.6` |
| Comments | JSDoc-style for all functions |


## FlyCam Future Features

### Completed
- [x] Excluded Mounts - add mount IDs that won't trigger zoom

### Planned
- [ ] i18n Support - English, German, French, Spanish
- [ ] Enable/Disable Toggle - make automatic camera switching optional
