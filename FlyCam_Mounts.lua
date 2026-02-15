-- FlyCam_Mounts.lua — Mount detection and helpers

local _, FlyCam = ...

-----------------------------------------------------------------------
-- Flying mount type IDs
-----------------------------------------------------------------------
FlyCam.Mounts.FLYING_TYPES = {
    [248] = true,
    [247] = true,
    [306] = true,
    [402] = true,
}

-----------------------------------------------------------------------
-- Dragonriding race aura IDs
-----------------------------------------------------------------------
FlyCam.Mounts.RACE_AURAS = {
    [439239] = true, -- "Rennstart" / "Starting race"
    [369968] = true, -- "Im Rennen" / "In the race"
}

-----------------------------------------------------------------------
-- Get active mount ID
-----------------------------------------------------------------------
function FlyCam.Mounts.GetActiveMountID()
    local mountIDs = C_MountJournal.GetMountIDs()
    if not mountIDs then
        return nil
    end

    for _, mountID in ipairs(mountIDs) do
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite,
              isFactionSpecific, faction, shouldHideOnChar, isCollected =
              C_MountJournal.GetMountInfoByID(mountID)

        if isActive then
            return mountID, name
        end
    end
    return nil
end

-----------------------------------------------------------------------
-- Check if mount is flying type
-----------------------------------------------------------------------
function FlyCam.Mounts.IsMountFlyingByType(mountID)
    if not mountID then
        return false
    end

    local _, _, _, _, mountTypeID = C_MountJournal.GetMountInfoExtraByID(mountID)
    if mountTypeID and FlyCam.Mounts.FLYING_TYPES[mountTypeID] then
        return true, mountTypeID
    end

    return false, mountTypeID
end

-----------------------------------------------------------------------
-- Check if currently on a flying mount
-----------------------------------------------------------------------
function FlyCam.Mounts.IsOnFlyingMount()
    if not IsMounted() then
        return false
    end

    local mountID = FlyCam.Mounts.GetActiveMountID()
    local isFlying = FlyCam.Mounts.IsMountFlyingByType(mountID)
    if isFlying then
        return true
    end

    -- Fallback: if area is flyable and we're mounted
    if IsFlyableArea() then
        return true
    end

    return false
end

-----------------------------------------------------------------------
-- Advanced flying area check
-----------------------------------------------------------------------
function FlyCam.Mounts.IsInAdvancedFlyingArea()
    if IsAdvancedFlyableArea and IsAdvancedFlyableArea() then
        return true
    end
    return false
end

-----------------------------------------------------------------------
-- Dragonriding race detection
-----------------------------------------------------------------------
function FlyCam.Mounts.IsInDragonRacingRace()
    if not AuraUtil or not AuraUtil.ForEachAura then
        return false
    end

    local canaccessvalue = canaccessvalue
    local issecretvalue = issecretvalue
    local inRace = false

    local function CheckAura(auraData)
        if canaccessvalue and not canaccessvalue(auraData) then
            return
        end

        local spellId
        if issecretvalue and issecretvalue(auraData.spellId) then
            return
        else
            spellId = auraData.spellId
        end

        if spellId and FlyCam.Mounts.RACE_AURAS[spellId] then
            inRace = true
            return true
        end
    end

    AuraUtil.ForEachAura("player", "HELPFUL", nil, CheckAura, true)
    return inRace
end

-----------------------------------------------------------------------
-- Debug slash commands
-----------------------------------------------------------------------
function FlyCam.Mounts.RegisterDebugCommands()
    SLASH_FLYCAMDEBUG1 = "/flycamdebug"
    SlashCmdList["FLYCAMDEBUG"] = function(msg)
        if not IsMounted() then
            print("FlyCam debug: You are not mounted.")
            return
        end

        local mountID, name = FlyCam.Mounts.GetActiveMountID()
        if not mountID then
            print("FlyCam debug: Could not detect active mount.")
            return
        end

        local isFlying, mountTypeID = FlyCam.Mounts.IsMountFlyingByType(mountID)

        print("FlyCam debug:")
        print("  Mount name: " .. (name or "unknown"))
        print("  Mount ID: " .. mountID)
        print("  mountTypeID: " .. tostring(mountTypeID))
        print("  IsOnFlyingMount(): " .. (FlyCam.Mounts.IsOnFlyingMount() and "true" or "false"))
        print("  IsMountFlyingByType(): " .. (isFlying and "true" or "false"))

        if mountTypeID and not FlyCam.Mounts.FLYING_TYPES[mountTypeID] then
            print("  Note: mountTypeID " .. mountTypeID .. " is not in FLYING_TYPES yet.")
            print("  If this mount should be treated as flying, add:")
            print("    [ " .. mountTypeID .. " ] = true,")
        end
    end
end
