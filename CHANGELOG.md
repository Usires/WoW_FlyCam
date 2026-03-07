## Changelog

### 1.0.1 - 07.03.2026
- **Bugfix**: Sliders now read from SavedVariables (FlyCamDB) instead of always using defaults
- **Bugfix**: Added panel.okay callback to ensure settings are saved when closing options

### 1.0 - 03.03.2026
- **Release**: Feature complete!
- **Cleanup**: Removed dead code (IsOnFlyingMount function, excluded mounts references)
- **Feature**: Automatic zoom out when mounting flying mounts (dragonriding, standard flying)
- **Feature**: Zoom back in when dismounting
- **Feature**: Vendor/ground mounts ignored (no unwanted zoom)
- **Feature**: Dragonriding race first-person view option
- **Feature**: Configurable zoom steps and transition duration
- **Feature**: Debug command /flycamdebug for troubleshooting
- **Bugfix**: Mount type 424 support (WoW 10.2+ dragonriding)
- **Bugfix**: Event frame properly receives events
- **Bugfix**: Fixed dismount zoom-back logic (only zooms back if actually zoomed out)

### 0.4.5 - 03.03.2026
- **Bugfix**: Only zoom back on dismount if we actually zoomed out before (tracks state with `wasZoomedOut`)

### 0.4.2 - 03.03.2026
- **Bugfix**: Zoom back in when dismounting

### 0.4.1 - 03.03.2026
- **Bugfix**: Added mount type 424 to flying types (WoW 10.2+ dragonriding)
- **Bugfix**: Added f:Show() to ensure event frame receives events

### 0.3.6 - 03.03.2026
- **Cleanup**: Removed excluded mounts settings UI (no longer needed with simplified detection)
- **UI**: Sliders now aligned left under race FP checkbox

### 0.3.5 - 03.03.2026
- **Refactor**: Simplified mount detection - only zoom for flying mounts. Vendor/ground mounts (IsMountFlyingByType = false) are now ignored entirely.

### 0.3.4 - 03.03.2026
- **Bugfix**: Fixed excluded mount detection failing when saved variables had empty `excludedMounts` table (used `next()` to properly check for existing entries)

### 0.3.3 - 03.03.2026
- **Bugfix**: Vendor mounts now properly leave camera unchanged (was switching to first-person)
- **Bugfix**: Sliders in options panel now correctly save settings (were saving to wrong keys)

### 0.3.2 - 17.02.2026
- **Feature**: Excluded Mounts - add mount IDs that won't trigger zoom (e.g., vendor mounts)
- **Feature**: "Add Common Vendor Mounts" preset button
- **Feature**: Excluded mounts shown in /flycamdebug output
- **Bugfix**: Fixed secret aura error in dragon racing detection (only scan when mounted)
- **Improvement**: Options panel layout tidy-up

### 0.3.1 - 17.02.2026
- **Bugfix**: Fixed nil reference for `canaccessvalue`/`issecretvalue` in dragon racing detection
- **Bugfix**: Fixed nil table errors in modular structure (load order issues)
- **Refactor**: Merged all modules back into single FlyCam.lua (WoW addon best practice)
- **Clean Code**: Added constants, JSDoc comments, section headers
- **Improvement**: Added OnShow/OnHide scripts to event frame for better event lifecycle
- **Improvement**: Named event frame (FlyCamFrame) for better debugging
- **Cleanup**: Extracted magic numbers to named constants

### 0.3 - 15.02.2026
- **Modular refactor**: Split into 4 modules (Mounts, Camera, Config, Main)
- Added slider factory for DRY options panel code
- Added new flying mount type IDs (306, 402)
- Updated documentation with file structure overview
- Added MAKINGOF.md with technical notes

### 0.2 - 13.02.2026
- Added optional first-person view during dragonriding races
- Camera zooms back out when race finishes

### 0.1 - 11.02.2026
- Initial release
- Smooth camera transitions and options panel
- Flying mount detection via C_MountJournal
- Debug command /flycamdebug
