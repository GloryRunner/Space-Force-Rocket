-- Written by GloryRunner (gloryy#9397)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RocketRemotes = ReplicatedStorage.RocketRemotes
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

local function ModifyJumpAbility(Character, CanJump)
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local DefaultJumpHeight = 7.2
    if Humanoid then
        if CanJump then
            Humanoid.JumpHeight = DefaultJumpHeight
        else
            Humanoid.JumpHeight = 0
        end
    end
end

local function ListenForPlayerLeave(RocketObject)
    RocketObject.ListenForPlayerLeave = Players.PlayerRemoving:Connect(function(Player)
        local IsPlayerAboard = table.find(RocketObject:GetPlayersAboard(), Player)
        if IsPlayerAboard then
            RocketObject:RemovePlayer(Player) -- <--- Could have issues especially because we're firing remotes on player leave which could error
        end
    end)
end

function Rocket.new()
    local self = setmetatable({}, Rocket)
    self.PlayerData = {}
    self.Temperature = Constants["Rocket"]["DefaultInternalTemperature"]
    self.RocketModel = ReplicatedStorage["Saturn V Rocket"]:Clone()
    self.RocketModel.Parent = workspace
    self.OffsetPerMovement = 0
    self.PlayerLeaveConnection = nil
    self.ProximityPromptConnection = nil
    self.Seats = {
        self.RocketModel.CrewCapsule.Interior.Seat1,
        self.RocketModel.CrewCapsule.Interior.Seat2
    }
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

function Rocket:Destroy()
    -- cleanup event listeners, remove all players
    self = nil
end

function Rocket:Launch()
    ListenForPlayerLeave(self)
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
    local EntrancePrompt = self.RocketModel.LES.EntranceHatch.EntrancePrompt
    self.IsHatchOpen = true
    EntrancePrompt.Enabled = true
    self.ProximityPromptConnection = EntrancePrompt.Triggered:Connect(function(Player)
        local IsAlreadySeated = table.find(self:GetPlayersAboard(), Player)
        local IsAtFullOccupancy = #self:GetPlayersAboard() == Constants["MaxOccupants"]
        if not IsAtFullOccupancy and not IsAlreadySeated then
            RocketRemotes.ModifyPromptVisibility:InvokeClient(Player, false)
            self:AddPlayer(Player)
        end
    end)
end

function Rocket:CloseHatch()
    local EntrancePrompt = self.RocketModel.LES.EntranceHatch.EntrancePrompt
    self.IsHatchOpen = false
    EntrancePrompt.Enabled = false
    if self.ProximityPromptConnection then
        self.ProximityPromptConnection:Disconnect()
    end
end

function Rocket:AddPlayer(AddedPlayer)
    local function GetAvailableSeat()
        for _, Seat in ipairs(self.Seats) do
            if not table.find(self:GetOccupiedSeats(), Seat) then
                return Seat
            end
        end
    end

    if AddedPlayer.Character then
        local Humanoid = AddedPlayer.Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            local AvailableSeat = GetAvailableSeat()
            AvailableSeat:Sit(Humanoid)
            task.defer(function()-- Weird issue where if you anchor the character shortly after calling :sit() it doesn't sit the char.
                repeat       -- Would prefer to check overlapping bounding boxes to be more certain instead of abritrarily yielding the thread
                    Humanoid.Sit = true
                until task.wait(1)
                ModifyJumpAbility(AddedPlayer.Character, false)
            end)
            RocketRemotes.ModifyResetAbility:InvokeClient(AddedPlayer, false)
            RocketRemotes.DisableCapsuleCollisions:InvokeClient(AddedPlayer, self.RocketModel)
            RocketRemotes.ModifyZoomDist:InvokeClient(AddedPlayer, Constants["CameraMaxZoomDist"])
            table.insert(self.PlayerData, {
                Player = AddedPlayer,
                OxygenTank = OxygenTank.new(AddedPlayer),
                Seat = AvailableSeat
            })
        end
    end
end

function Rocket:GetOccupiedSeats()
    local OccupiedSeats = {}
    for _, PlayerData in ipairs(self.PlayerData) do
        table.insert(OccupiedSeats, PlayerData.Seat)
    end
    return OccupiedSeats
end

function Rocket:RemovePlayer(Player)
    local WorldSpawnCF = workspace.SpawnLocation.CFrame
    local Character = Player.Character
    local IsPlayerAboard = table.find(self:GetPlayersAboard(), Player)
    if IsPlayerAboard then
        if Character then
            Character:PivotTo(WorldSpawnCF)
            Character:FindFirstChildOfClass("Humanoid").Sit = false
            ModifyJumpAbility(Character, true)
        end
        RocketRemotes.ModifyResetAbility:InvokeClient(Player, true)
        RocketRemotes.ModifyZoomDist:InvokeClient(Player, game:GetService("StarterPlayer").CameraMaxZoomDistance)
        for Index, PlayerData in ipairs(self.PlayerData) do
            if PlayerData.Player == Player then
                table.remove(self.PlayerData, Index)
            end
        end
    end
end

function Rocket:GetPlayersAboard()
    local PlayersAboard = {}
    for _, PlayerData in ipairs(self.PlayerData) do
        table.insert(PlayersAboard, PlayerData.Player)
    end
    return PlayersAboard
end

function Rocket:GetActiveStage()
    return self.ActiveStage
end

function Rocket:GetTemperature()
    return self.Temperature
end

function Rocket:GetCoordinates()
    -- Broken

    local RocketPos = self.RocketModel:GetPivot().Position
    local RadiusOfEarth = Constants["RadiusOfEarth"]
    local Latitude, Longitude = math.asin(RocketPos.Z/RadiusOfEarth), math.atan2(RocketPos.Y, RocketPos.X)
    --local Latitude, Longitude = math.atan2(RocketPos.Y, math.sqrt(RocketPos.X ^ 2 + RocketPos.Z ^ 2)), math.atan2(RocketPos.X, RocketPos.Z)
    return {
        ["Latitude"] = Latitude,
        ["Longitude"] = Longitude
    }
end

function Rocket:GetAltitude()
    local RocketPosition = self.RocketModel:GetPivot().Position
    return RocketPosition.Y
end

function Rocket:GetVelocity()
    -- Returns the speed of the Rocket in studs per second.
    local CurrentAltitude = self:GetAltitude()
    task.wait(1)
    local AltitudeDelta = math.ceil(math.abs(self:GetAltitude() - CurrentAltitude))
    return AltitudeDelta
end

function Rocket:GetDistFromEarth()
    local Launchpad = workspace.Platform.Main
    local SurfacePos = Vector3.new(Launchpad.Position.X, Launchpad.Position.Y + Launchpad.Size.Y / 2, Launchpad.Position.Z)
    local RocketPosition = self.RocketModel:GetPivot().Position
    local Dist = (RocketPosition - SurfacePos).Magnitude
    return Dist
end

return Rocket
