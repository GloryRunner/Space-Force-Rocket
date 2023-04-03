local RunService = game:GetService("RunService")

local Part = workspace:WaitForChild("Part")

local RAY_DISTANCE = 100
local BodyPosition = Part.BodyPosition


RunService.Heartbeat:Connect(function()
    local Origin = Part.Position
    local DirectionCF = CFrame.lookAt(Part.Position + -Part.CFrame.UpVector * RAY_DISTANCE, Part.Position)
    local RayParams = RaycastParams.new({Part}, Enum.RaycastFilterType.Exclude, true, nil, true)    -- Need to implement a better solution to getting surface normals immediately.
    local RayResult = workspace:Raycast(Origin, DirectionCF.Position, RayParams)

    if RayResult then
        if RayResult.Instance then
            local SurfaceNorm = RayResult.Normal 
            local NormToPartPos = Part.Position - SurfaceNorm
            local LVDotNorm = SurfaceNorm:Dot(NormToPartPos)
            local Theta = math.deg(math.asin(LVDotNorm / NormToPartPos.Magnitude))
            Part.Orientation = Vector3.new(-Theta, 0, 0)
            BodyPosition.Position = Part.Position + CFrame.fromAxisAngle(SurfaceNorm, math.pi / 2).RightVector * 20
        end
    else
        BodyPosition.Position = Part.Position + Part.CFrame.LookVector * 20
    end
end)
