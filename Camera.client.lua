local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Mouse = Players.LocalPlayer:GetMouse()
local CurrentCamera = workspace.CurrentCamera

pcall(function()
    game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, false) 
end)
CurrentCamera.CameraType = Enum.CameraType.Scriptable

RunService.RenderStepped:Connect(function()
    local ReferenceCF = workspace["Saturn V Rocket"]:GetPivot()
    local CameraOffset = CFrame.new(0, -800, 800)
    local MouseDirLength = 200
    local CameraCF = ReferenceCF * CameraOffset
    local MousePos = Mouse.Hit.Position
    local MouseDir = (MousePos - CameraCF.Position).Unit * MouseDirLength
    local LookAtCF = CFrame.lookAt(CameraCF.Position, ReferenceCF.Position - Vector3.new(0, 500, 0) + MouseDir)
    CurrentCamera.CFrame = LookAtCF
end)
