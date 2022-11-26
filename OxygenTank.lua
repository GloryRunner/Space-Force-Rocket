local Constants = require(script.Parent.Constants)
local DEFAULT_OXYGEN_AMOUNT = Constants["OxygenTank"]["DefaultOxygenAmount"]
local OxygenTank = {}
OxygenTank.__index = OxygenTank

function OxygenTank.new()
    local self = setmetatable({}, OxygenTank)
    self.OxygenAmount = DEFAULT_OXYGEN_AMOUNT
    self.IsTankActive = false
    return self
end

function OxygenTank:Destroy()
    
end

function OxygenTank:Enable()
    self.IsTankActive = true
end

function OxygenTank:Disable()
    self.IsTankActive = false
end

function OxygenTank:UseOxygen(Amount)
    self.OxygenTank -= Amount
end

function OxygenTank:GetOxygenAmount()
    return self.OxygenAmount
end

function OxygenTank:Refill()
    self.OxygenAmount = DEFAULT_OXYGEN_AMOUNT
end

return OxygenTank