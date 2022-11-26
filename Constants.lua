return {
    ["RadiusOfEarth"] = 6371, -- According to real life. (Approx.)
    ["Rocket"] = {
        ["TemperatureChangePerStud"] = -0.0015625,
        ["SpeedIncrement"] = 0.00390625,
        ["MaxOffsetSpeed"] = 9.5, -- Keeps particle emitters stable.
        ["DefaultInternalTemperature"] = 70
    },
    ["Stages"] = {
        ["1stStage"] = {
            ["HasEngines"] = true,
            ["EngineAmount"] = 5,
            ["DefaultFuelAmount"] = 5000,
            ["ConsumptionPerSecond"] = 50
        },
        ["SeparatorStage"] = {
            ["HasEngines"] = false,
            ["EngineAmount"] = 0,
            ["DefaultFuelAmount"] = 0,
            ["ConsumptionPerSecond"] = 0
        },
        ["2ndStage"] = {
            ["HasEngines"] = true,
            ["EngineAmount"] = 5,
            ["DefaultFuelAmount"] = 5000,
            ["ConsumptionPerSecond"] = 50
        },
        ["3rdStage"] = {
            ["HasEngines"] = true,
            ["EngineAmount"] = 5,
            ["DefaultFuelAmount"] = 2500,
            ["ConsumptionPerSecond"] = 20
        },
        ["FinalStage"] = {
            ["HasEngines"] = true,
            ["EngineAmount"] = 1,
            ["DefaultFuelAmount"] = 2500,
            ["ConsumptionPerSecond"] = 20
        }
    },
    ["OxygenTank"] = {
        ["DefaultOxygenAmount"] = 1000,
        ["ConsumptionPerSecond"] = 1
    }
}