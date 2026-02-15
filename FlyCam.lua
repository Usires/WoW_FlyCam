-- FlyCam.lua — Main entry point
-- World of Warcraft addon: automatic camera zoom on mount/dismount

local ADDON_NAME = ...
local FlyCam = {}
_G.FlyCam = FlyCam

-----------------------------------------------------------------------
-- Load modules
-----------------------------------------------------------------------
FlyCam.Config = {}
FlyCam.Camera = {}
FlyCam.Mounts = {}

-----------------------------------------------------------------------
-- Defaults and SavedVariables
-----------------------------------------------------------------------
FlyCam.defaults = {
    flySteps = 40,
    groundSteps = 27,
    duration = 1.0,
    raceSteps = 20,
    raceDuration = 0.5,
    raceFirstPerson = false,
    raceRestoreViewIndex = 5,
}

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

-----------------------------------------------------------------------
-- Events
-----------------------------------------------------------------------
local f = CreateFrame("Frame")

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
f:RegisterEvent("UNIT_AURA")

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        FlyCamDB = FlyCam.CopyDefaults(FlyCam.defaults, FlyCamDB or {})
        
        FlyCam.Config.CreateOptionsPanel()
        FlyCam.Mounts.RegisterDebugCommands()
        
        print("FlyCam loaded. Configure under Options → AddOns → FlyCam.")
    
    elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        FlyCam.Camera.ApplyForState()
    
    elseif event == "UNIT_AURA" and arg1 == "player" then
        FlyCam.Camera.UpdateRaceFirstPerson()
    end
end)
