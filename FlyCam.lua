-------------------------------------------------------------------------------
-- FlyCam.lua
-- 
-- Automatic camera zoom when mounting/dismounting flying mounts.
-- Features smooth zoom transitions, dragonriding race detection,
-- and configurable settings via the Options panel.
--
-- Author:   Usires
-- Version:  1.0
-- License:  MIT
-------------------------------------------------------------------------------

local ADDON_NAME = ...
local FlyCam = {}
_G.FlyCam = FlyCam

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------
local ZOOM_FACTOR_FLYING = 2.6  -- Max camera zoom for flying

-------------------------------------------------------------------------------
-- NAMESPACE STRUCTURE
-- FlyCam.defaults   - Default settings
-- FlyCam.Mounts    - Mount detection and type checking
-- FlyCam.Camera    - Camera zoom logic
-- FlyCam.Config    - Options panel and settings
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- DEFAULT SETTINGS
-- These values are used when no saved settings exist
-------------------------------------------------------------------------------
FlyCam.defaults = {
    flySteps       = 30,      -- Zoom steps when mounting a flying mount
    groundSteps    = 20,      -- Zoom steps when dismounting
    duration       = 0.7,     -- Smooth zoom transition duration (seconds)
    raceSteps      = 20,      -- Zoom steps after dragonriding race
    raceDuration   = 0.5,     -- Race zoom transition duration
    raceFirstPerson = false,  -- Use first-person view during races
    raceRestoreViewIndex = 5, -- View index to restore after race
}

-- Internal state
local wasZoomedOut = false  -- Track if we zoomed out (for dismount restore)

-------------------------------------------------------------------------------
-- DEFAULTS HANDLER
-- Deep copies defaults into saved variables, preserving user changes
-------------------------------------------------------------------------------
function FlyCam.CopyDefaults(src, dest)
    if type(dest) ~= "table" then dest = {} end
    for k, v in pairs(src) do
        if type(v) == "table" then
            dest[k] = FlyCam.CopyDefaults(v, dest[k])
        elseif dest[k] == nil then
            dest[k] = v
        end
    end
    return dest
end

-------------------------------------------------------------------------------
-- MOUNT DETECTION MODULE
-- Handles detection of flying mounts and dragonriding races
-------------------------------------------------------------------------------
FlyCam.Mounts = {}

-- Mount type IDs that are considered flying
-- 248, 247, 306, 402 = various flying mount types
FlyCam.Mounts.FLYING_TYPES = {
    [248] = true,  -- Standard flying
    [247] = true,  -- Dragonriding
    [306] = true,  -- Flying
    [402] = true,  -- Dragonriding (newer)
    [424] = true,  -- Dragonriding (WoW 10.2+)
}

-- Aura spell IDs that indicate an active dragonriding race
FlyCam.Mounts.RACE_AURAS = {
    [439239] = true,  -- "Rennstart" / Race start
    [369968] = true,  -- "Im Rennen" / In the race
}

--- Get the currently active mount's ID and name
-- @return number? mountID, string? name
function FlyCam.Mounts.GetActiveMountID()
    local mountIDs = C_MountJournal.GetMountIDs()
    if not mountIDs then
        return nil
    end

    for _, mountID in ipairs(mountIDs) do
        local name, _, _, isActive = C_MountJournal.GetMountInfoByID(mountID)
        if isActive then
            return mountID, name
        end
    end
    return nil
end

--- Check if a mount is a flying type by its mount ID
-- @param number? mountID
-- @return boolean isFlying, number? mountTypeID
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

--- Check if player is in an advanced flying area (Dragon Isles)
-- @return boolean
function FlyCam.Mounts.IsInAdvancedFlyingArea()
    if IsAdvancedFlyableArea and IsAdvancedFlyableArea() then
        return true
    end
    return false
end

--- Check if player is currently in a dragonriding race
-- Only runs when player is mounted to avoid enemy aura issues
-- @return boolean
function FlyCam.Mounts.IsInDragonRacingRace()
    -- Only check when mounted
    if not IsMounted() then
        return false
    end
    
    if not AuraUtil or not AuraUtil.ForEachAura then
        return false
    end
    
    -- Use local copies of globals to safely check aura access
    local canaccessvalue = _G.canaccessvalue
    local issecretvalue = _G.isecretvalue
    local inRace = false

    local function CheckAura(auraData)
        -- Safety: skip anything we are not allowed to inspect
        if canaccessvalue and not canaccessvalue(auraData) then
            return
        end
        
        local spellId
        if issecretvalue and issecretvalue(auraData.spellId) then
            -- This aura's spellId is private/secret → we must not touch it
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

--- Register debug slash command /flycamdebug
-- Shows mount detection info while mounted
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
        print("  IsMountFlyingByType(): " .. (isFlying and "true" or "false"))
        
        if mountTypeID and not FlyCam.Mounts.FLYING_TYPES[mountTypeID] then
            print("  Note: mountTypeID " .. mountTypeID .. " not in FLYING_TYPES.")
            print("  Add [ " .. mountTypeID .. " ] = true to enable flying detection.")
        end
    end
end

-------------------------------------------------------------------------------
-- CAMERA MODULE
-- Handles smooth camera zoom transitions
-------------------------------------------------------------------------------
FlyCam.Camera = {}

--- Perform a smooth camera zoom over multiple steps
-- @param number steps - Number of zoom steps (positive = zoom out, negative = zoom in)
-- @param number duration - Total duration in seconds
function FlyCam.Camera.SmoothZoom(steps, duration)
    if steps == 0 or duration <= 0 then
        return
    end

    local totalSteps = math.abs(steps)
    local directionOut = steps > 0
    local interval = duration / totalSteps
    local currentStep = 0

    local function doStep()
        currentStep = currentStep + 1

        if directionOut then
            CameraZoomOut(1)
        else
            CameraZoomIn(1)
        end

        if currentStep < totalSteps then
            C_Timer.After(interval, doStep)
        end
    end

    doStep()
end

-- Track previous race first-person state
local wasInRaceFP = false

--- Update camera for dragonriding race first-person view
-- Automatically switches to first-person when race starts,
-- and restores zoom when race ends
function FlyCam.Camera.UpdateRaceFirstPerson()
    local db = FlyCamDB or FlyCam.defaults
    if not db.raceFirstPerson then
        wasInRaceFP = false
        return
    end

    -- Check if player is even mounted
    if not IsMounted() then
        wasInRaceFP = false
        return
    end

    -- Check if mount is a flying type (vendor/ground mounts = no race FP)
    local mountID = FlyCam.Mounts.GetActiveMountID()
    if not mountID then
        wasInRaceFP = false
        return
    end
    
    local isFlying = FlyCam.Mounts.IsMountFlyingByType(mountID)
    if not isFlying then
        wasInRaceFP = false
        return
    end

    local inRace = FlyCam.Mounts.IsInDragonRacingRace()

    if inRace and not wasInRaceFP then
        -- Race started: switch to first-person
        SetView(1)
    elseif not inRace and wasInRaceFP then
        -- Race ended: restore zoom
        local raceSteps = db.raceSteps or FlyCam.defaults.raceSteps
        local raceDuration = db.raceDuration or FlyCam.defaults.raceDuration
        SetCVar("cameraDistanceMaxZoomFactor", ZOOM_FACTOR_FLYING)
        FlyCam.Camera.SmoothZoom(raceSteps, raceDuration)
    end

    wasInRaceFP = inRace
end

--- Apply camera settings based on current mount state
-- Called when player mounts/dismounts
function FlyCam.Camera.ApplyForState()
    local db = FlyCamDB or FlyCam.defaults

    local flySteps      = db.flySteps      or FlyCam.defaults.flySteps
    local groundSteps   = db.groundSteps   or FlyCam.defaults.groundSteps
    local duration      = db.duration       or FlyCam.defaults.duration
    local raceSteps     = db.raceSteps      or FlyCam.defaults.raceSteps
    local raceDuration  = db.raceDuration   or FlyCam.defaults.raceDuration

    SetCVar("cameraDistanceMaxZoomFactor", ZOOM_FACTOR_FLYING)

    -- Get mount info (only if actually mounted)
    local mountID = nil
    local isFlying = false
    if IsMounted() then
        mountID = FlyCam.Mounts.GetActiveMountID()
        isFlying = FlyCam.Mounts.IsMountFlyingByType(mountID)
    end
    
    -- Priority 1: Dragonriding race
    if FlyCam.Mounts.IsInDragonRacingRace() then
        FlyCam.Camera.SmoothZoom(raceSteps, raceDuration)
        return
    end

    -- Priority 2: Zoom for flying mounts, zoom back for ground/dismount
    if isFlying then
        FlyCam.Camera.SmoothZoom(flySteps, duration)
        wasZoomedOut = true
    elseif not IsMounted() and wasZoomedOut then
        -- Only zoom back if we previously zoomed out
        FlyCam.Camera.SmoothZoom(-groundSteps, duration)
        wasZoomedOut = false
    elseif not IsMounted() then
        -- Was never zoomed out, just reset state
        wasZoomedOut = false
    end
    -- No zoom for ground mounts (vendor mounts, etc.)
end

-------------------------------------------------------------------------------
-- CONFIG MODULE
-- Options panel for user settings
-------------------------------------------------------------------------------
FlyCam.Config = {}

--- Create the main options panel in WoW's Interface Options
function FlyCam.Config.CreateOptionsPanel()
    local panel = CreateFrame("Frame", "FlyCamOptionsPanel", UIParent)
    panel.name = "FlyCam"
    panel:Hide()

    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetJustifyH("LEFT")
    title:SetText("FlyCam – Flying Camera Helper")
    title:SetTextColor(1.0, 0.82, 0.0)

    -- Subtitle
    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText("Camera zoom settings for flying, ground mounts, and races.")

    -- Help text
    local helpText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    helpText:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -12)
    helpText:SetJustifyH("LEFT")
    helpText:SetWidth(500)
    helpText:SetText(
        "Zoom logic:\n" ..
        "- Flying zoom steps: camera zoom when mounting a flying mount.\n" ..
        "- Ground zoom steps: camera zoom when dismounting.\n" ..
        "- Race zoom steps: camera distance after a dragonriding race.\n" ..
        "- Transition duration: how long the smooth zoom animation takes.\n\n" ..
        "Debug:\n" ..
        "- Use /flycamdebug while mounted to see mountTypeID."
    )

    -- Race first-person checkbox
    local raceFPCheckbox = CreateFrame("CheckButton", "FlyCamRaceFPCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
    raceFPCheckbox:SetPoint("TOPLEFT", helpText, "BOTTOMLEFT", 0, -20)
    raceFPCheckbox.Text:SetText("Use first-person view during dragonriding races")

    raceFPCheckbox:SetScript("OnClick", function(self)
        FlyCamDB.raceFirstPerson = self:GetChecked() and true or false
    end)

    -- Sliders (aligned left after race FP checkbox)
    local db = FlyCamDB or FlyCam.defaults
    local flySlider = FlyCam.Config.CreateSlider(panel, "FlyCamFlyStepsSlider", 5, 40, "Flying zoom steps", raceFPCheckbox, -30)
    flySlider:SetValue(db.flySteps or FlyCam.defaults.flySteps)

    local groundSlider = FlyCam.Config.CreateSlider(panel, "FlyCamGroundStepsSlider", 5, 40, "Ground zoom steps", flySlider, -40)
    groundSlider:SetValue(db.groundSteps or FlyCam.defaults.groundSteps)

    local durationSlider = FlyCam.Config.CreateSlider(panel, "FlyCamDurationSlider", 0.1, 2.0, "Transition zoom duration", groundSlider, -40, true)
    durationSlider:SetValue(db.duration or FlyCam.defaults.duration)

    local raceSlider = FlyCam.Config.CreateSlider(panel, "FlyCamRaceStepsSlider", 5, 40, "Race zoom steps", durationSlider, -40)
    raceSlider:SetValue(db.raceSteps or FlyCam.defaults.raceSteps)

    local raceDurationSlider = FlyCam.Config.CreateSlider(panel, "FlyCamRaceDurationSlider", 0.1, 2.0, "Race transition duration", raceSlider, -40, true)
    raceDurationSlider:SetValue(db.raceDuration or FlyCam.defaults.raceDuration)

    -- Footer with credits
    local footer = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    footer:SetPoint("BOTTOMLEFT", 20, 20)
    footer:SetJustifyH("LEFT")
    footer:SetText("FlyCam v0.3.2 | by Usires & Nix | \"It's dangerous to go alone!\" - Hyrule Baldwin")

    -- Refresh settings when panel is shown
    panel.refresh = function()
        local db = FlyCamDB or FlyCam.defaults

        raceFPCheckbox:SetChecked(db.raceFirstPerson or FlyCam.defaults.raceFirstPerson)
        flySlider:SetValue(db.flySteps or FlyCam.defaults.flySteps)
        groundSlider:SetValue(db.groundSteps or FlyCam.defaults.groundSteps)
        durationSlider:SetValue(db.duration or FlyCam.defaults.duration)
        raceSlider:SetValue(db.raceSteps or FlyCam.defaults.raceSteps)
        raceDurationSlider:SetValue(db.raceDuration or FlyCam.defaults.raceDuration)
    end

    -- Save settings when "Okay" is clicked
    panel.okay = function()
        -- Values are already saved in FlyCamDB via OnValueChanged, 
        -- but we ensure they're synced
        local db = FlyCamDB or FlyCam.defaults
        db.flySteps = flySlider:GetValue()
        db.groundSteps = groundSlider:GetValue()
        db.duration = durationSlider:GetValue()
        db.raceSteps = raceSlider:GetValue()
        db.raceDuration = raceDurationSlider:GetValue()
    end

    -- Register with WoW settings system
    local category = Settings.RegisterCanvasLayoutCategory(panel, "FlyCam")
    category.ID = "FlyCamCategory"
    Settings.RegisterAddOnCategory(category)

    FlyCam.Config.panel = panel
end

--- Factory function to create a slider widget
-- @param Frame panel - Parent panel
-- @param string name - Unique slider name
-- @param number min - Minimum value
-- @param number max - Maximum value
-- @param string label - Display label
-- @param Frame anchor - Parent widget to anchor to
-- @param number offset - Y offset from anchor
-- @param boolean isDuration - Whether this is a duration slider (0.1 step)
-- @return Slider
function FlyCam.Config.CreateSlider(panel, name, min, max, label, anchor, offset, isDuration)
    local slider = CreateFrame("Slider", name, panel, "OptionsSliderTemplate")
    slider:SetWidth(250)
    slider:SetHeight(16)
    slider:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, offset)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(isDuration and 0.1 or 1)
    slider:SetObeyStepOnDrag(true)
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")

    -- Label bounds
    _G[slider:GetName() .. "Low"]:SetText(isDuration and string.format("%.1fs", min) or min)
    _G[slider:GetName() .. "High"]:SetText(isDuration and string.format("%.1fs", max) or max)
    _G[slider:GetName() .. "Text"]:SetText(label)
    _G[slider:GetName() .. "Text"]:SetJustifyH("LEFT")

    -- Value display
    local valueText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    valueText:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    valueText:SetJustifyH("LEFT")

    -- Map slider names to actual setting keys
    local settingKey = nil
    if name == "FlyCamFlyStepsSlider" then settingKey = "flySteps"
    elseif name == "FlyCamGroundStepsSlider" then settingKey = "groundSteps"
    elseif name == "FlyCamDurationSlider" then settingKey = "duration"
    elseif name == "FlyCamRaceStepsSlider" then settingKey = "raceSteps"
    elseif name == "FlyCamRaceDurationSlider" then settingKey = "raceDuration"
    end

    -- Value change handler
    slider:SetScript("OnValueChanged", function(self, value)
        if isDuration then
            value = math.floor(value * 10 + 0.5) / 10
        else
            value = math.floor(value + 0.5)
        end
        if settingKey then
            FlyCamDB[settingKey] = value
        end
        valueText:SetText(isDuration and string.format("%.1fs", value) or value)
    end)

    return slider
end

-------------------------------------------------------------------------------
-- EVENT HANDLING
-------------------------------------------------------------------------------
local f = CreateFrame("Frame", ADDON_NAME .. "Frame")
f:Show()  -- Ensure frame is visible to receive events

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
f:RegisterEvent("UNIT_AURA")

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        -- Initialize saved variables with defaults
        FlyCamDB = FlyCam.CopyDefaults(FlyCam.defaults, FlyCamDB or {})
        
        -- Create UI and register commands
        FlyCam.Config.CreateOptionsPanel()
        FlyCam.Mounts.RegisterDebugCommands()
        
        print("FlyCam loaded. Configure under Options → AddOns → FlyCam.")
    
    elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        -- Mount/dismount event: apply camera state
        FlyCam.Camera.ApplyForState()
    
    elseif event == "UNIT_AURA" and arg1 == "player" then
        -- Aura changed: check for dragonriding race
        FlyCam.Camera.UpdateRaceFirstPerson()
    end
end)

-- Unregister events when frame is hidden to save resources
f:SetScript("OnHide", function(self)
    self:UnregisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    self:UnregisterEvent("UNIT_AURA")
end)

-- Re-register events when frame is shown
f:SetScript("OnShow", function(self)
    self:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    self:RegisterEvent("UNIT_AURA")
end)
