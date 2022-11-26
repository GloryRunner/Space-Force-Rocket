local Constants = require(script.Parent.Constants)
local STAGE_CONSTANTS = Constants["Stages"]
local Stage = {}
Stage.__index = Stage

local function ModifyStageCollision(StageModel, ShouldCollide)
    for _, Part in ipairs(StageModel:GetDescendants()) do
        if Part:IsA("BasePart") then
            Part.CanCollide = ShouldCollide
        end
    end
end

function Stage.new(StageModel)
    local self = setmetatable({}, Stage)
    self.StageModel = StageModel
    self.RocketModel = StageModel.Parent
    self.HasReleased = false
    self.HasEngines = STAGE_CONSTANTS[StageModel.Name]["HasEngines"]
    self.FuelAmount = STAGE_CONSTANTS[StageModel.Name]["DefaultFuelAmount"]
    return self
end

function Stage:EngageEngines()
    local DefFuelAmount = STAGE_CONSTANTS[self.StageModel.Name]["DefaultFuelAmount"]
    local ConsumptionPerSecond = STAGE_CONSTANTS[self.StageModel.Name]["ConsumptionPerSecond"]
    -- Ex: 1000 fuel total / 50 used per second = Has enough fuel for 20 seconds of propulsion
    for i = 1, DefFuelAmount/ConsumptionPerSecond do
        task.wait(1)
        self.FuelAmount -= ConsumptionPerSecond
    end
end

function Stage:UpdateThrustFXVisibility(ShouldBeVisible)
    for _, ParticleEmitter in ipairs(self.StageModel:GetDescendants()) do
        if ParticleEmitter:IsA("ParticleEmitter") and ParticleEmitter.Name == "EngineEmitter" then
            ParticleEmitter.Enabled = ShouldBeVisible
        end
    end
end

function Stage:Release()
    local Weld = self.RocketModel.MainPart:FindFirstChild(self.StageModel.Name.. "Weld")
    if Weld then
        task.defer(function()
            if self.HasEngines then
                self:UpdateThrustFXVisibility(false)
            end

            ModifyStageCollision(self.StageModel, false)
            Weld:Destroy()
            task.wait(2)
            ModifyStageCollision(self.StageModel, true)
            self.HasReleased = true
        end)
    end
end

function Stage:GetFuelAmount()
    return self.FuelAmount
end

function Stage:GetMaxFuelAmount()
    return STAGE_CONSTANTS[self.StageModel.Name]["DefaultFuelAmount"]
end

function Stage:HasStageReleased()
    return self.HasReleased
end

return Stage