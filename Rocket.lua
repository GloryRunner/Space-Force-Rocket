-- Written by GloryRunner (gloryy#9397)
local OxygenTank = require(script.Parent.OxygenTank)
local Stage = require(script.Parent.Stage)
local Constants = require(script.Parent.Constants)
local Rocket = {}
Rocket.__index = Rocket


--[[
TODO:
- Figure out how the rocket is going to be destroyed and created. (self.RocketModel)
- Don't forget that people will be able to control when the stages are released.
- Get Hatches done. Figure out a system for how people will enter the rocket to begin with.
- Add Sound FX
- Create mission control UI
]]

local function BeginStage(StageObject, RocketObject)
    if StageObject.HasEngines then
        task.defer(function()
            if RocketObject.IsRocketInitializing then
                StageObject:UpdateThrustFXVisibility(true)
            else
                task.wait(2)
                StageObject:UpdateThrustFXVisibility(true)
            end
        end)
    end
    task.defer(function()
        StageObject:EngageEngines()
    end)
    while StageObject:GetFuelAmount() > 0 do
        RocketObject.RocketModel:PivotTo(RocketObject.RocketModel:GetPivot() * CFrame.new(0, RocketObject.OffsetPerMovement, 0) * CFrame.Angles(math.rad(0.0025), 0, 0))
        RocketObject.Temperature = Constants["Rocket"]["TemperatureChangePerStud"] * RocketObject:GetAltitude()
        if RocketObject.OffsetPerMovement < Constants["Rocket"]["MaxOffsetSpeed"] then
            RocketObject.OffsetPerMovement += Constants["Rocket"]["SpeedIncrement"]
        end
        task.wait()
    end
end

local function RemoveLES(RocketObject)
    RocketObject.RocketModel.MainPart.LESWeld:Destroy()
    for i = 1, 170 do
        if not RocketObject.RocketModel:FindFirstChild("LES") then break end
        RocketObject.RocketModel.LES:PivotTo(RocketObject.RocketModel.LES:GetPivot() * CFrame.new(0, 5, 2) * CFrame.Angles(math.rad(0.3), 0, math.rad(0.3)))
        task.wait()
    end
end

local function EnableRocketBlastoffFX(RocketObject)
    if RocketObject.ActiveStage.StageModel.Name == "1stStage" then
        for _, Emitter in ipairs(RocketObject.ActiveStage.StageModel:GetDescendants()) do
            if Emitter:IsA("ParticleEmitter") and Emitter.Name == "BlastEffect" then
                Emitter.Enabled = true
                task.wait(10)
                Emitter.Enabled = false
            end
        end
    end
end

function Rocket.new()
    local self = setmetatable({}, Rocket)
    self.PlayerData = {}
    self.Temperature = Constants["Rocket"]["DefaultInternalTemperature"]
    self.RocketModel = workspace["Saturn V Rocket"] -- TEMPORARY
    self.OffsetPerMovement = 0
    self.Stages = {
        ["1stStage"] = Stage.new(self.RocketModel["1stStage"]),
        ["SeparatorStage"] = Stage.new(self.RocketModel["SeparatorStage"]),
        ["2ndStage"] = Stage.new(self.RocketModel["2ndStage"]),
        ["3rdStage"] = Stage.new(self.RocketModel["3rdStage"]),
        ["FinalStage"] = Stage.new(self.RocketModel["FinalStage"])
    }
    self.ActiveStage = nil
    self.IsRocketInitializing = false
    self.IsHatchOpen = false
    self.IsRocketActive = false
    return self
end

function Rocket:Launch()
    self:CloseHatch()
    self.ActiveStage = self.Stages["1stStage"]
    self.IsRocketInitializing = true
    EnableRocketBlastoffFX(self) -- YIELDS LAUNCH
    BeginStage(self.ActiveStage, self)
    self.IsRocketActive = true
    self.IsRocketInitializing = false
    self.ActiveStage:Release()
    task.defer(function()
        task.wait(1)
        self.Stages["SeparatorStage"]:Release()
        task.wait(1)
        RemoveLES(self)
    end)
    self.ActiveStage = self.Stages["2ndStage"]
    BeginStage(self.ActiveStage, self)
    self.ActiveStage:Release()
    self.ActiveStage = self.Stages["3rdStage"]
    BeginStage(self.ActiveStage, self)
    self.ActiveStage:Release()
    self.ActiveStage = self.Stages["FinalStage"]
    BeginStage(self.ActiveStage, self)
    self.ActiveStage:Release()
    self.ActiveStage:UpdateThrustFXVisibility(false)
    self.ActiveStage = nil
end

function Rocket:OpenHatch()

    -- GOING TO INVOLVE MAKING CERTAIN PARTS UNCOLLIDABLE

    local Hatch = self.RocketModel.CrewCapsule.Hatch
end

function Rocket:CloseHatch()

    -- GOING TO INVOLVE MAKING CERTAIN PARTS UNCOLLIDABLE

    local Hatch = self.RocketModel.CrewCapsule.Hatch
end

function Rocket:SeatPlayer(SeatedPlayer)
    local PlayerOxygenTank = OxygenTank.new()
    table.insert(self.PlayerData, {Player = SeatedPlayer, Tank = PlayerOxygenTank})
end

function Rocket:GetPlayersAboard()
    local PlayersAboard = {}
    for _, Dict in ipairs(self.PlayerData) do
        table.insert(PlayersAboard, Dict["Player"])
    end
    return PlayersAboard
end

function Rocket:GetActiveStage()
    return self.ActiveStage
end

function Rocket:GetTemperature()
    return self.Temperature
end

function Rocket:GetPosition()
    return self.RocketModel:GetPivot().Position
end

function Rocket:GetCoordinates()
    local RocketPos = self:GetPosition()
    local RadiusOfEarth = Constants["RadiusOfEarth"]
    local Latitude, Longitude = math.asin(RocketPos.Z/RadiusOfEarth), math.atan2(RocketPos.Y, RocketPos.X)
    --local Latitude, Longitude = math.atan2(RocketPos.Y, math.sqrt(RocketPos.X ^ 2 + RocketPos.Z ^ 2)), math.atan2(RocketPos.X, RocketPos.Z)
    return {
        ["Latitude"] = Latitude,
        ["Longitude"] = Longitude
    }
end

function Rocket:GetAltitude()
    return self:GetPosition().Y
end

function Rocket:GetSpeed()
    -- Returns the speed of the Rocket in studs per second.
    local CurrentPosY = self:GetPosition().Y
    task.wait(1)
    local RateOfChange = math.ceil(math.abs(self:GetPosition().Y - CurrentPosY))
    return RateOfChange
end

function Rocket:GetDistFromEarth()
    local LaunchpadPos = Vector3.new(3888.574, 539.532, -2782.891)
    local Dist = (self:GetPosition() - LaunchpadPos).Magnitude
    return Dist
end

function Rocket:KickPlayer(Player)
    -- Teleports player to the area around the Launchpad.
    local CFAroundLaunchpad = CFrame.new(3835.238, 269.762, -2842.648)
    local Character = Player.Character
    if Character then
        Character:PivotTo(CFAroundLaunchpad)
    end
end

return Rocket