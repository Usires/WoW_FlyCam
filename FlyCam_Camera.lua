-- FlyCam_Camera.lua — Camera zoom and race handling

local _, FlyCam = ...

-----------------------------------------------------------------------
-- Smooth zoom
-----------------------------------------------------------------------
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

-----------------------------------------------------------------------
-- Race first-person + restore
-----------------------------------------------------------------------
local wasInRaceFP = false

function FlyCam.Camera.UpdateRaceFirstPerson()
    local db = FlyCamDB or FlyCam.defaults
    if not db.raceFirstPerson then
        wasInRaceFP = false
        return
    end

    local inRace = FlyCam.Mounts.IsInDragonRacingRace()

    if inRace and not wasInRaceFP then
        SetView(1)
    elseif not inRace and wasInRaceFP then
        local raceSteps = db.raceSteps or FlyCam.defaults.raceSteps
        local raceDuration = db.raceDuration or FlyCam.defaults.raceDuration
        SetCVar("cameraDistanceMaxZoomFactor", 2.6)
        FlyCam.Camera.SmoothZoom(raceSteps, raceDuration)
    end

    wasInRaceFP = inRace
end

-----------------------------------------------------------------------
-- Main camera application
-----------------------------------------------------------------------
function FlyCam.Camera.ApplyForState()
    local db = FlyCamDB or FlyCam.defaults

    local flySteps      = db.flySteps      or FlyCam.defaults.flySteps
    local groundSteps   = db.groundSteps   or FlyCam.defaults.groundSteps
    local duration      = db.duration       or FlyCam.defaults.duration
    local raceSteps     = db.raceSteps      or FlyCam.defaults.raceSteps
    local raceDuration  = db.raceDuration   or FlyCam.defaults.raceDuration

    SetCVar("cameraDistanceMaxZoomFactor", 2.6)

    if FlyCam.Mounts.IsInDragonRacingRace() then
        FlyCam.Camera.SmoothZoom(raceSteps, raceDuration)
        return
    end

    if FlyCam.Mounts.IsOnFlyingMount() then
        FlyCam.Camera.SmoothZoom(flySteps, duration)
    else
        FlyCam.Camera.SmoothZoom(-groundSteps, duration)
    end
end
