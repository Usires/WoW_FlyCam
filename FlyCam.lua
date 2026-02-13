local ADDON_NAME = ...
local FlyCam = {}
_G.FlyCam = FlyCam

local f = CreateFrame("Frame")

-----------------------------------------------------------------------
-- Defaults and SavedVariables
-----------------------------------------------------------------------

local defaults = {
    flySteps = 40,      -- how many steps to zoom out when flying
    groundSteps = 27,   -- how many steps to zoom in when dismounting
    duration = 1.0,     -- seconds for smooth transition
    raceSteps = 20,      -- how many steps to zoom in when starting a dragonrace
    raceDuration = 0.5,  -- seconds for smooth transition (dragonrace)
    raceFirstPerson = false, -- enable first-person mode during races
    raceRestoreViewIndex = 5, -- which camera view index (2–5) to use for restore
}

local function CopyDefaults(src, dest)
    if type(dest) ~= "table" then dest = {} end
    for k, v in pairs(src) do
        if type(v) == "table" then
            dest[k] = CopyDefaults(v, dest[k])
        elseif dest[k] == nil then
            dest[k] = v
        end
    end
    return dest
end

-----------------------------------------------------------------------
-- Smooth zoom
-----------------------------------------------------------------------

local function SmoothZoom(steps, duration)
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

-----------------------------------------------------------------------
-- Mount helpers and flying detection
-----------------------------------------------------------------------

-- Example flying mountTypeID set. Extend as you discover more.
local FLYING_TYPES = {
    [248] = true,
    [247] = true,
    [306] = true,
    [402] = true,
    }

local function GetActiveMountID()
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

local function IsMountFlyingByType(mountID)
    if not mountID then
        return false
    end

    -- name, creatureDisplayInfoID, description, source, mountTypeID, uiModelSceneID, animID, spellVisualKitID, disablePlayerMountPreview
    local _, _, _, _, mountTypeID = C_MountJournal.GetMountInfoExtraByID(mountID)
    if mountTypeID and FLYING_TYPES[mountTypeID] then
        return true, mountTypeID
    end

    return false, mountTypeID
end

local function IsOnFlyingMount()
    if not IsMounted() then
        return false
    end

    local mountID = GetActiveMountID()
    local isFlying, _ = IsMountFlyingByType(mountID)
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
-- Advanced flying / Dragonriding area helper
-----------------------------------------------------------------------

local function IsInAdvancedFlyingArea()
    if IsAdvancedFlyableArea and IsAdvancedFlyableArea() then
        return true
    end
    return false
end

-----------------------------------------------------------------------
-- Dragonriding race detection
-----------------------------------------------------------------------

local RACE_AURAS = {
    [439239] = true, -- "Rennstart" / "Starting race"
    [369968] = true, -- "Im Rennen" / "In the race"
}

local function IsInDragonRidingRace()
    if not AuraUtil or not AuraUtil.ForEachAura then
        return false
    end

    -- If these helpers exist, use them to avoid secret/blocked fields
    local canaccessvalue = canaccessvalue
    local issecretvalue = issecretvalue

    local inRace = false

    local function CheckAura(auraData)
        -- Safety: skip anything we are not allowed to inspect
        if canaccessvalue and not canaccessvalue(auraData) then
            return -- do nothing, continue iterating
        end

        local spellId
        if issecretvalue and issecretvalue(auraData.spellId) then
            -- This aura’s spellId is private/secret → we must not touch it
            return
        else
            spellId = auraData.spellId
        end

        if spellId and RACE_AURAS[spellId] then
            inRace = true
            return true -- stop iterating
        end
    end

    AuraUtil.ForEachAura("player", "HELPFUL", nil, CheckAura, true)

    return inRace
end


-----------------------------------------------------------------------
-- Dragonriding race first-person + restore via raceSteps
-----------------------------------------------------------------------

local wasInRaceFP = false

local function UpdateRaceFirstPersonSimple()
    local db = FlyCamDB or defaults
    if not db.raceFirstPerson then
        wasInRaceFP = false
        return
    end

    local inRace = IsInDragonRidingRace()

    -- Race just started
    if inRace and not wasInRaceFP then
        -- Go to first-person: view 1
        SetView(1)
    end

    -- Race just ended
    if not inRace and wasInRaceFP then
        -- Restore using raceSteps/raceDuration
        local raceSteps = db.raceSteps or defaults.raceSteps
        local raceDuration = db.raceDuration or defaults.raceDuration

        -- Make sure max zoom is high enough, just like in ApplyCameraForState
        SetCVar("cameraDistanceMaxZoomFactor", 2.6)
        SmoothZoom(raceSteps, raceDuration)
    end

    wasInRaceFP = inRace
end


-----------------------------------------------------------------------
-- Camera application logic
-----------------------------------------------------------------------

local function ApplyCameraForState()
    local db = FlyCamDB or defaults

    local flySteps       = db.flySteps       or defaults.flySteps
    local groundSteps    = db.groundSteps    or defaults.groundSteps
    local duration       = db.duration       or defaults.duration
    local raceSteps      = db.raceSteps      or defaults.raceSteps
    local raceDuration   = db.raceDuration   or defaults.raceDuration

    SetCVar("cameraDistanceMaxZoomFactor", 2.6)

    if IsInDragonRidingRace() then
        SmoothZoom(raceSteps, raceDuration)
        return
    end

    if IsOnFlyingMount() then
        SmoothZoom(flySteps, duration)
    else
        SmoothZoom(-groundSteps, duration)
    end
end



-----------------------------------------------------------------------
-- Options panel
-----------------------------------------------------------------------

local function CreateOptionsPanel()
    local panel = CreateFrame("Frame", "FlyCamOptionsPanel", UIParent)
    panel.name = "FlyCam"

    panel:Hide()

    --------------------------------------------------------------------
    -- Title and subtitle
    --------------------------------------------------------------------
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetJustifyH("LEFT")
    title:SetText("FlyCam – Flying Camera Helper")
    title:SetTextColor(1.0, 0.82, 0.0)

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText("Camera zoom settings for flying, ground mounts, and races.")

    --------------------------------------------------------------------
    -- Readme / usage text
    --------------------------------------------------------------------
    local helpText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    helpText:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -12)
    helpText:SetJustifyH("LEFT")
    helpText:SetWidth(500)
    helpText:SetText(
        "Zoom logic:\n" ..
        "- Flying zoom steps: how many notches the camera zooms out when you mount a flying mount.\n" ..
        "- Ground zoom steps: how many notches the camera zooms in when you dismount.\n" ..
        "- Race zoom steps: camera distance used after a dragonriding race.\n" ..
        "- Transition zoom duration: how long the smooth zoom animation takes.\n\n" ..
        "Debug:\n" ..
        "- Use /flycamdebug while mounted to see your active mount and mountTypeID.\n" ..
        "- Use /flycamrace in dragonriding zones to inspect race-related buffs."
    )

    --------------------------------------------------------------------
    -- First-person in race checkbox
    --------------------------------------------------------------------
    local raceFPCheckbox = CreateFrame("CheckButton", "FlyCamRaceFPCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
    raceFPCheckbox:SetPoint("TOPLEFT", helpText, "BOTTOMLEFT", 0, -20)
    raceFPCheckbox.Text:SetText("Use first-person view during dragonriding races")

    raceFPCheckbox:SetScript("OnClick", function(self)
        FlyCamDB.raceFirstPerson = self:GetChecked() and true or false
    end)

    --------------------------------------------------------------------
    -- Flying steps slider + value
    --------------------------------------------------------------------
    local flySlider = CreateFrame("Slider", "FlyCamFlyStepsSlider", panel, "OptionsSliderTemplate")
    flySlider:SetWidth(250)
    flySlider:SetHeight(16)
    flySlider:SetPoint("TOPLEFT", raceFPCheckbox, "BOTTOMLEFT", 0, -30)
    flySlider:SetMinMaxValues(5, 40)
    flySlider:SetValueStep(1)
    flySlider:SetObeyStepOnDrag(true)
    flySlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    flySlider:SetValue(defaults.flySteps or 20)

    _G[flySlider:GetName() .. "Low"]:SetText("5")
    _G[flySlider:GetName() .. "High"]:SetText("40")
    _G[flySlider:GetName() .. "Text"]:SetText("Flying zoom steps")
    _G[flySlider:GetName() .. "Text"]:SetJustifyH("LEFT")

    local flyValueText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    flyValueText:SetPoint("LEFT", flySlider, "RIGHT", 10, 0)
    flyValueText:SetJustifyH("LEFT")
    flyValueText:SetText("")

    flySlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        FlyCamDB.flySteps = value
        flyValueText:SetText(value)
    end)

    --------------------------------------------------------------------
    -- Ground steps slider + value
    --------------------------------------------------------------------
    local groundSlider = CreateFrame("Slider", "FlyCamGroundStepsSlider", panel, "OptionsSliderTemplate")
    groundSlider:SetWidth(250)
    groundSlider:SetHeight(16)
    groundSlider:SetPoint("TOPLEFT", flySlider, "BOTTOMLEFT", 0, -40)
    groundSlider:SetMinMaxValues(5, 40)
    groundSlider:SetValueStep(1)
    groundSlider:SetObeyStepOnDrag(true)
    groundSlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    groundSlider:SetValue(defaults.groundSteps or 10)

    _G[groundSlider:GetName() .. "Low"]:SetText("5")
    _G[groundSlider:GetName() .. "High"]:SetText("40")
    _G[groundSlider:GetName() .. "Text"]:SetText("Ground zoom steps")
    _G[groundSlider:GetName() .. "Text"]:SetJustifyH("LEFT")

    local groundValueText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    groundValueText:SetPoint("LEFT", groundSlider, "RIGHT", 10, 0)
    groundValueText:SetJustifyH("LEFT")
    groundValueText:SetText("")

    groundSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        FlyCamDB.groundSteps = value
        groundValueText:SetText(value)
    end)

    --------------------------------------------------------------------
    -- General duration slider + value
    --------------------------------------------------------------------
    local durationSlider = CreateFrame("Slider", "FlyCamDurationSlider", panel, "OptionsSliderTemplate")
    durationSlider:SetWidth(250)
    durationSlider:SetHeight(16)
    durationSlider:SetPoint("TOPLEFT", groundSlider, "BOTTOMLEFT", 0, -40)
    durationSlider:SetMinMaxValues(0.1, 2.0)
    durationSlider:SetValueStep(0.1)
    durationSlider:SetObeyStepOnDrag(true)
    durationSlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    durationSlider:SetValue(defaults.duration or 0.8)

    _G[durationSlider:GetName() .. "Low"]:SetText("0.1s")
    _G[durationSlider:GetName() .. "High"]:SetText("2.0s")
    _G[durationSlider:GetName() .. "Text"]:SetText("Transition zoom duration")
    _G[durationSlider:GetName() .. "Text"]:SetJustifyH("LEFT")

    local durationValueText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    durationValueText:SetPoint("LEFT", durationSlider, "RIGHT", 10, 0)
    durationValueText:SetJustifyH("LEFT")
    durationValueText:SetText("")

    durationSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value * 10 + 0.5) / 10
        FlyCamDB.duration = value
        durationValueText:SetText(string.format("%.1fs", value))
    end)

    --------------------------------------------------------------------
    -- Race steps slider + value
    --------------------------------------------------------------------
    local raceSlider = CreateFrame("Slider", "FlyCamRaceStepsSlider", panel, "OptionsSliderTemplate")
    raceSlider:SetWidth(250)
    raceSlider:SetHeight(16)
    raceSlider:SetPoint("TOPLEFT", durationSlider, "BOTTOMLEFT", 0, -40)
    raceSlider:SetMinMaxValues(5, 40)
    raceSlider:SetValueStep(1)
    raceSlider:SetObeyStepOnDrag(true)
    raceSlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    raceSlider:SetValue(defaults.raceSteps or 12)

    _G[raceSlider:GetName() .. "Low"]:SetText("5")
    _G[raceSlider:GetName() .. "High"]:SetText("40")
    _G[raceSlider:GetName() .. "Text"]:SetText("Race zoom steps")
    _G[raceSlider:GetName() .. "Text"]:SetJustifyH("LEFT")

    local raceValueText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    raceValueText:SetPoint("LEFT", raceSlider, "RIGHT", 10, 0)
    raceValueText:SetJustifyH("LEFT")
    raceValueText:SetText("")

    raceSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        FlyCamDB.raceSteps = value
        raceValueText:SetText(value)
    end)

    --------------------------------------------------------------------
    -- Race duration slider + value
    --------------------------------------------------------------------
    local raceDurationSlider = CreateFrame("Slider", "FlyCamRaceDurationSlider", panel, "OptionsSliderTemplate")
    raceDurationSlider:SetWidth(250)
    raceDurationSlider:SetHeight(16)
    raceDurationSlider:SetPoint("TOPLEFT", raceSlider, "BOTTOMLEFT", 0, -40)
    raceDurationSlider:SetMinMaxValues(0.1, 2.0)
    raceDurationSlider:SetValueStep(0.1)
    raceDurationSlider:SetObeyStepOnDrag(true)
    raceDurationSlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    raceDurationSlider:SetValue(defaults.raceDuration or 0.5)

    _G[raceDurationSlider:GetName() .. "Low"]:SetText("0.1s")
    _G[raceDurationSlider:GetName() .. "High"]:SetText("2.0s")
    _G[raceDurationSlider:GetName() .. "Text"]:SetText("Transition zoom duration after a race")
    _G[raceDurationSlider:GetName() .. "Text"]:SetJustifyH("LEFT")

    local raceDurationValueText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    raceDurationValueText:SetPoint("LEFT", raceDurationSlider, "RIGHT", 10, 0)
    raceDurationValueText:SetJustifyH("LEFT")
    raceDurationValueText:SetText("")

    raceDurationSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value * 10 + 0.5) / 10
        FlyCamDB.raceDuration = value
        raceDurationValueText:SetText(string.format("%.1fs", value))
    end)

    --------------------------------------------------------------------
    -- Footer
    --------------------------------------------------------------------
    local footer = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    footer:SetPoint("BOTTOMLEFT", 20, 20)
    footer:SetJustifyH("LEFT")
    footer:SetText("FlyCam v0.2 -- © 2026 github.com/Usires. Made with love and Claude. <3")

    --------------------------------------------------------------------
    -- Refresh + registration
    --------------------------------------------------------------------
    panel.refresh = function()
        local db = FlyCamDB or defaults

        raceFPCheckbox:SetChecked(db.raceFirstPerson or defaults.raceFirstPerson)

        local fly = db.flySteps or defaults.flySteps
        flySlider:SetValue(fly)
        flyValueText:SetText(fly)

        local ground = db.groundSteps or defaults.groundSteps
        groundSlider:SetValue(ground)
        groundValueText:SetText(ground)

        local dur = db.duration or defaults.duration
        durationSlider:SetValue(dur)
        durationValueText:SetText(string.format("%.1fs", dur))

        local race = db.raceSteps or defaults.raceSteps
        raceSlider:SetValue(race)
        raceValueText:SetText(race)

        local raceDur = db.raceDuration or defaults.raceDuration
        raceDurationSlider:SetValue(raceDur)
        raceDurationValueText:SetText(string.format("%.1fs", raceDur))
    end

    local category, layout = Settings.RegisterCanvasLayoutCategory(panel, "FlyCam")
    category.ID = "FlyCamCategory"
    Settings.RegisterAddOnCategory(category)

    FlyCam.optionsPanel = panel
end



-----------------------------------------------------------------------
-- Mount debug slash: shows active mount info and type
-----------------------------------------------------------------------

SLASH_FLYCAMDEBUG1 = "/flycamdebug"
SlashCmdList["FLYCAMDEBUG"] = function(msg)
    if not IsMounted() then
        print("FlyCam debug: You are not mounted.")
        return
    end

    local mountID, name = GetActiveMountID()
    if not mountID then
        print("FlyCam debug: Could not detect active mount.")
        return
    end

    local isFlying, mountTypeID = IsMountFlyingByType(mountID)

    print("FlyCam debug:")
    print("  Mount name: " .. (name or "unknown"))
    print("  Mount ID: " .. mountID)
    print("  mountTypeID: " .. tostring(mountTypeID))
    print("  IsOnFlyingMount(): " .. (IsOnFlyingMount() and "true" or "false"))
    print("  IsMountFlyingByType(): " .. (isFlying and "true" or "false"))

    if mountTypeID and not FLYING_TYPES[mountTypeID] then
        print("  Note: mountTypeID " .. mountTypeID .. " is not in FLYING_TYPES yet.")
        print("  If this mount should be treated as flying, add:")
        print("    [ " .. mountTypeID .. " ] = true,")
    end
end

-----------------------------------------------------------------------
-- Events
-----------------------------------------------------------------------

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
f:RegisterEvent("UNIT_AURA")

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        -- Initialize saved variables
        FlyCamDB = CopyDefaults(defaults, FlyCamDB or {})

        -- Create options panel
        CreateOptionsPanel()

        print("FlyCam loaded. Configure under Options → AddOns → FlyCam.")

    elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        -- Mount or dismount, adjust camera
        ApplyCameraForState()

    elseif event == "UNIT_AURA" then
        local unit = arg1
        if unit == "player" then
            -- Handle race start/end → first person + restore raceSteps
            UpdateRaceFirstPersonSimple()
        end
    end
end)
