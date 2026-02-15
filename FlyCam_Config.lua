-- FlyCam_Config.lua — Options panel

local _, FlyCam = ...

-----------------------------------------------------------------------
-- Options panel
-----------------------------------------------------------------------
function FlyCam.Config.CreateOptionsPanel()
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
    -- Help text
    --------------------------------------------------------------------
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
        "- Use /flycamdebug while mounted to see mountTypeID.\n" ..
        "- Use /flycamrace in dragonriding zones to inspect race buffs."
    )

    --------------------------------------------------------------------
    -- Race first-person checkbox
    --------------------------------------------------------------------
    local raceFPCheckbox = CreateFrame("CheckButton", "FlyCamRaceFPCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
    raceFPCheckbox:SetPoint("TOPLEFT", helpText, "BOTTOMLEFT", 0, -20)
    raceFPCheckbox.Text:SetText("Use first-person view during dragonriding races")

    raceFPCheckbox:SetScript("OnClick", function(self)
        FlyCamDB.raceFirstPerson = self:GetChecked() and true or false
    end)

    --------------------------------------------------------------------
    -- Flying steps slider
    --------------------------------------------------------------------
    local flySlider = FlyCam.Config.CreateSlider(panel, "FlyCamFlyStepsSlider", 5, 40, "Flying zoom steps", raceFPCheckbox, -30)
    flySlider:SetValue(FlyCam.defaults.flySteps)

    --------------------------------------------------------------------
    -- Ground steps slider
    --------------------------------------------------------------------
    local groundSlider = FlyCam.Config.CreateSlider(panel, "FlyCamGroundStepsSlider", 5, 40, "Ground zoom steps", flySlider, -40)
    groundSlider:SetValue(FlyCam.defaults.groundSteps)

    --------------------------------------------------------------------
    -- General duration slider
    --------------------------------------------------------------------
    local durationSlider = FlyCam.Config.CreateSlider(panel, "FlyCamDurationSlider", 0.1, 2.0, "Transition zoom duration", groundSlider, -40, true)
    durationSlider:SetValue(FlyCam.defaults.duration)

    --------------------------------------------------------------------
    -- Race steps slider
    --------------------------------------------------------------------
    local raceSlider = FlyCam.Config.CreateSlider(panel, "FlyCamRaceStepsSlider", 5, 40, "Race zoom steps", durationSlider, -40)
    raceSlider:SetValue(FlyCam.defaults.raceSteps)

    --------------------------------------------------------------------
    -- Race duration slider
    --------------------------------------------------------------------
    local raceDurationSlider = FlyCam.Config.CreateSlider(panel, "FlyCamRaceDurationSlider", 0.1, 2.0, "Race transition duration", raceSlider, -40, true)
    raceDurationSlider:SetValue(FlyCam.defaults.raceDuration)

    --------------------------------------------------------------------
    -- Footer
    --------------------------------------------------------------------
    local footer = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    footer:SetPoint("BOTTOMLEFT", 20, 20)
    footer:SetJustifyH("LEFT")
    footer:SetText("FlyCam v0.3 -- Modular refactor. Originally by Usires.")

    --------------------------------------------------------------------
    -- Refresh
    --------------------------------------------------------------------
    panel.refresh = function()
        local db = FlyCamDB or FlyCam.defaults

        raceFPCheckbox:SetChecked(db.raceFirstPerson or FlyCam.defaults.raceFirstPerson)
        flySlider:SetValue(db.flySteps or FlyCam.defaults.flySteps)
        groundSlider:SetValue(db.groundSteps or FlyCam.defaults.groundSteps)
        durationSlider:SetValue(db.duration or FlyCam.defaults.duration)
        raceSlider:SetValue(db.raceSteps or FlyCam.defaults.raceSteps)
        raceDurationSlider:SetValue(db.raceDuration or FlyCam.defaults.raceDuration)
    end

    local category = Settings.RegisterCanvasLayoutCategory(panel, "FlyCam")
    category.ID = "FlyCamCategory"
    Settings.RegisterAddOnCategory(category)

    FlyCam.Config.panel = panel
end

-----------------------------------------------------------------------
-- Slider factory
-----------------------------------------------------------------------
function FlyCam.Config.CreateSlider(panel, name, min, max, label, anchor, offset, isDuration)
    local slider = CreateFrame("Slider", name, panel, "OptionsSliderTemplate")
    slider:SetWidth(250)
    slider:SetHeight(16)
    slider:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, offset)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(isDuration and 0.1 or 1)
    slider:SetObeyStepOnDrag(true)
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")

    _G[slider:GetName() .. "Low"]:SetText(isDuration and string.format("%.1fs", min) or min)
    _G[slider:GetName() .. "High"]:SetText(isDuration and string.format("%.1fs", max) or max)
    _G[slider:GetName() .. "Text"]:SetText(label)
    _G[slider:GetName() .. "Text"]:SetJustifyH("LEFT")

    local valueText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    valueText:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    valueText:SetJustifyH("LEFT")

    slider:SetScript("OnValueChanged", function(self, value)
        if isDuration then
            value = math.floor(value * 10 + 0.5) / 10
        else
            value = math.floor(value + 0.5)
        end
        FlyCamDB[name] = value
        valueText:SetText(isDuration and string.format("%.1fs", value) or value)
    end)

    return slider
end
