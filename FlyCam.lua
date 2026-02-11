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
-- Camera application logic
-----------------------------------------------------------------------

local function ApplyCameraForState()
    local db = FlyCamDB or defaults

    local flySteps = db.flySteps or defaults.flySteps
    local groundSteps = db.groundSteps or defaults.groundSteps
    local duration = db.duration or defaults.duration

    -- Ensure max zoom factor is wide enough
    SetCVar("cameraDistanceMaxZoomFactor", 2.6)

    if IsOnFlyingMount() then
        SmoothZoom(flySteps, duration)
    else
        SmoothZoom(-groundSteps, duration) -- negative = zoom in
    end
end

-----------------------------------------------------------------------
-- Options panel
-----------------------------------------------------------------------

local function CreateOptionsPanel()
    local panel = CreateFrame("Frame", "FlyCamOptionsPanel", UIParent)
    panel.name = "FlyCam"

    panel:Hide()  -- let Settings UI show it

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
    subtitle:SetText("Camera zoom settings for flying and ground mounts.")

    --------------------------------------------------------------------
    -- Readme / usage text (multiline, wrapped)
    --------------------------------------------------------------------
    local helpText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    helpText:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -12)
    helpText:SetJustifyH("LEFT")
    helpText:SetWidth(500)          -- controls wrapping width
    helpText:SetText(
        "Zoom logic:\n" ..
        "- Flying zoom steps: how many notches the camera zooms out when you mount a flying mount.\n" ..
        "- Ground zoom steps: how many notches the camera zooms in when you dismount.\n" ..
        "- Transition duration: how long the smooth zoom animation takes.\n\n" ..
        "Debugging:\n" ..
        "- Use /flycamdebug while mounted to see your active mount, its mountTypeID, and whether FlyCam treats it as flying.\n" ..
        "- If you find a flying mount that is not recognized, copy the suggested mountTypeID line into the FLYING_TYPES table in FlyCam.lua."
    )

    --------------------------------------------------------------------
    -- Flying steps slider + value label
    --------------------------------------------------------------------
    local flySlider = CreateFrame("Slider", "FlyCamFlyStepsSlider", panel, "OptionsSliderTemplate")
    flySlider:SetWidth(250)
    flySlider:SetHeight(16)
    flySlider:SetPoint("TOPLEFT", helpText, "BOTTOMLEFT", 0, -30)
    flySlider:SetMinMaxValues(5, 40)
    flySlider:SetValueStep(1)
    flySlider:SetObeyStepOnDrag(true)
    flySlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    flySlider:SetValue(defaults.flySteps or 20)  -- initial thumb position

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
    -- Ground steps slider + value label
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
    -- Duration slider + value label
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
    _G[durationSlider:GetName() .. "Text"]:SetText("Transition duration")
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
    -- Footer
    --------------------------------------------------------------------
    local footer = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    footer:SetPoint("BOTTOMLEFT", 20, 20)
    footer:SetJustifyH("LEFT")
    footer:SetText("FlyCam © 2026 TheDirk. Made with love and a little local AI helper called Gemma3. <3")

    --------------------------------------------------------------------
    -- Refresh + registration
    --------------------------------------------------------------------
    panel.refresh = function()
        local db = FlyCamDB or defaults

        local fly = db.flySteps or defaults.flySteps
        flySlider:SetValue(fly)
        flyValueText:SetText(fly)

        local ground = db.groundSteps or defaults.groundSteps
        groundSlider:SetValue(ground)
        groundValueText:SetText(ground)

        local dur = db.duration or defaults.duration
        durationSlider:SetValue(dur)
        durationValueText:SetText(string.format("%.1fs", dur))
    end

    local category, layout = Settings.RegisterCanvasLayoutCategory(panel, "FlyCam")
    category.ID = "FlyCamCategory"
    Settings.RegisterAddOnCategory(category)

    FlyCam.optionsPanel = panel
end



-- Debug slash: shows active mount info and type
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

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        FlyCamDB = CopyDefaults(defaults, FlyCamDB or {})
        CreateOptionsPanel()
        print("FlyCam loaded. Configure under Interface → AddOns → FlyCam.")
    elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        ApplyCameraForState()
    end
end)
