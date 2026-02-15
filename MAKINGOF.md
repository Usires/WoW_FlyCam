# Making of: FlyCam

This document is a behind-the-scenes look at how the FlyCam addon was designed and implemented.  
It is meant as a learning resource for other humans and AI assistants working with the WoW addon API.

## Goals

FlyCam started with three simple goals:

- Smoothly zoom the camera out when mounting a flying mount.
- Smoothly zoom the camera back in when dismounting.
- Add special behavior for dragonriding races (first-person view during the race, then restore).

From the beginning, we aimed for:

- Minimal UI: one options panel with a few sliders and a checkbox.
- Small, readable code (single file, no external libraries).
- Behavior that “feels right” in regular gameplay without micro-managing it.

## Architecture Overview

The addon is structured into a few focused sections:

### Configuration and defaults

- A `defaults` table holds all tunable values (zoom steps, durations, race behavior).
- `CopyDefaults` merges saved variables with defaults on load.
- Small helpers `GetDB()` and `GetOption(key)` centralize config access, so the rest of the code does not repeat the “`FlyCamDB or defaults`” pattern everywhere.

### Camera logic

- `SmoothZoom(steps, duration, opts)` handles smooth incremental zooming using:
  - `CameraZoomIn(1)` / `CameraZoomOut(1)`  
  - `C_Timer.After(interval, callback)` for timing.
- `ApplyCameraForState()` decides how to zoom based on:
  - Whether the player is in a dragonriding race.
  - Whether the player is on a flying mount.

Camera-related constants (like max zoom factor and slider ranges) are grouped in a `CAMERA` table to avoid magic numbers scattered throughout the code.

### Mount detection

- `GetActiveMountID()` iterates `C_MountJournal.GetMountIDs()` and returns the currently active mount’s ID and name.
- `IsMountFlyingByType(mountID)` calls `C_MountJournal.GetMountInfoExtraByID` and checks the `mountTypeID` against a `FLYING_TYPES` table.
- `IsOnFlyingMount()` combines:
  - `IsMounted()`
  - `IsMountFlyingByType(mountID)`
  - and a fallback `IsFlyableArea()` check.

This keeps the addon robust against localization and avoids hardcoding mount names.

### Dragonriding area and race detection

- `IsInAdvancedFlyingArea()` is a tiny helper that wraps `IsAdvancedFlyableArea()` if available.
- `RACE_AURAS` is a map of known spell IDs for dragonriding races:
  - e.g. “Starting race” and “In the race”.

#### Private / secret auras and packed AuraData

Modern WoW (The War Within and later) uses **private auras** and **secret values** to limit what addons can read about some buffs and debuffs.

- We use `AuraUtil.ForEachAura("player", "HELPFUL", nil, callback, true)` to iterate player buffs.
- With `usePackedAura = true`, the callback receives an `AuraData` struct instead of unpacked parameters.
- Some of these auras are “secret”; trying to read certain fields (like `spellId`) directly can cause errors such as:
  - `bad argument #1 to 'unpack' (table expected, got secret)`
  - `table index is secret`

To handle this safely, FlyCam:

- Caches two global helpers (when available):
  - `canaccessvalue(value)` – checks whether the addon is allowed to access a value.
  - `issecretvalue(value)` – checks whether a value is marked as secret.
- Skips any aura the addon is not allowed to inspect.
- Skips secret `spellId` values.
- Only compares `spellId` for allowed, non-secret auras.

The final detection pattern looks like this (simplified):

```lua
local canaccessvalue = _G.canaccessvalue
local issecretvalue  = _G.issecretvalue

local RACE_AURAS = {
     = true,
     = true,
}

local function IsInDragonRidingRace()
    if not AuraUtil or not AuraUtil.ForEachAura then
        return false
    end

    local inRace = false

    local function CheckAura(auraData)
        if canaccessvalue and not canaccessvalue(auraData) then
            return
        end

        local spellId = auraData.spellId
        if issecretvalue and issecretvalue(spellId) then
            return
        end

        if spellId and RACE_AURAS[spellId] then
            inRace = true
            return true
        end
    end

    AuraUtil.ForEachAura("player", "HELPFUL", nil, CheckAura, true)

    return inRace
end
