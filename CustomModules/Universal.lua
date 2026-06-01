local vapelite, called = ...

local plrs = cloneref(game:GetService('Players'))
local runService = cloneref(game:GetService('RunService'))

local cam = workspace.CurrentCamera
local lplr = plrs.LocalPlayer
local mouse = lplr:GetMouse()

local char = lplr.Character or lplr.CharacterAdded:Wait()
local root = char:FindFirstChild('HumanoidRootPart')
local humanoid = char:WaitForChild('Humanoid')

local function run(func)
    func()
end

local Combat = vapelite:CreateCategory('Combat')
local Utility = vapelite:CreateCategory('Utility')
local Settings = vapelite:CreateCategory('Settings')
--[[
run(function()
    local minCps
    local maxCps
    Combat:CreateModule({
    Name = 'AutoClicker'
    Tooltip = 'Automatically click when holding down'
    })
end)
 ]]--
Utility:CreateModule({
    Name = 'Anti-AFK',
    Tooltip = "Prevents roblox from kicking you when you're AFK.",
    Function = function(call)
        while call do
            repeat task.wait() until isrbxactive()
            mouse1click()
            task.wait(45)
        end
    end
})

local nameHider
run(function()
    local name = false
    local display
    nameHider = Utility:CreateModule({
        Name = 'NameHider',
        Tooltip = 'Hides your name on the client. Useful for streamers.',
        Function = function()
            if name == false then 
                name = lplr.Name
                display = lplr.DisplayName
            end
            lplr.Name = name
            lplr.DisplayName = display

            nameHider:Clean(runService.RenderStepped:Connect(function()
                lplr.Name = 'NickHider'
                lplr.DisplayName = 'NickHider'
            end))
        end
    })
end)

run(function()
    local fov = 120
    local speed = 1

    local function wallCheck(targetPart)
        local origin = cam.CFrame.Position
        local direction = targetPart.Position - origin

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = {
            char,
            targetPart.Parent
        }

        return workspace:Raycast(origin, direction, params) == nil
    end

    local function getNearestPlayer(fovValue)
        local closest = nil
        local closestDist = math.huge

        local mousePos = Vector2.new(mouse.X, mouse.Y)

        for _, v in next, plrs:GetPlayers() do
            if v ~= lplr and v.Character then
                local vRoot = v.Character:FindFirstChild('HumanoidRootPart')
                local humanoid = v.Character:FindFirstChildOfClass('Humanoid')

                if vRoot and humanoid and humanoid.Health > 0 and wallCheck(vRoot) then
                    local pos, visible = cam:WorldToViewportPoint(vRoot.Position)

                    if visible then
                        local targetPos = Vector2.new(pos.X, pos.Y)
                        local dist = (mousePos - targetPos).Magnitude

                        if dist < closestDist and dist <= fovValue then
                            closestDist = dist
                            closest = v
                        end
                    end
                end
            end
        end

        return closest, closestDist
    end

    local AimAssist
    local conn
    local aimassistcall = false
    AimAssist = Combat:CreateModule({
        Name = 'AimAssist',
        Tooltip = 'Assists your aim by snapping to the nearest target.',
        Function = function(call)
            aimassistcall = call
            if not call and conn then conn:Disconnect() conn = nil end
            conn = AimAssist:Clean(runService.RenderStepped:Connect(function(dt)
                if not isrbxactive() then return end

                char = lplr.Character or lplr.CharacterAdded:Wait()
                root = char:FindFirstChild('HumanoidRootPart')
                if not root then return end

                local target = getNearestPlayer(fov)

                if target and target.Character then
                    local targetRoot = target.Character:FindFirstChild('HumanoidRootPart')

                    if targetRoot then
                        local pos = cam:WorldToViewportPoint(targetRoot.Position)

                        local screenCenter = Vector2.new(
                            cam.ViewportSize.X / 2,
                            cam.ViewportSize.Y / 2
                        )

                        local targetPos = Vector2.new(pos.X, pos.Y)
                        local delta = (targetPos - screenCenter)

                        local moveX = delta.X * speed * dt
                        local moveY = delta.Y * speed * dt

                        mousemoverel(moveX, moveY)
                    end
                end
            end))
        end
    })

    AimAssist:CreateSlider({
        Name = 'FOV',
        Min = 1,
        Max = 500,
        Suffix = 1,
        Default = 120,
        Function = function(v)
            fov = v
        end
    })

    --[[
    AimAssist:CreateToggle({
        Name = 'FOV Circle',
        Enabled = false,
        Function = function(call)
            local circle
            local fovConn
            if call then

                
                circle = Drawing.new("Circle")
                warn(type(circle))
                circle.Color = Color3.fromRGB(255, 255, 255)
                circle.Filled = false
                circle.NumSides = 128
                circle.Transparency = 0
                circle.Visible = true


                task.spawn(function()
                    fovConn = runService.RenderStepped:Connect(function()
                        if not call or not aimassistcall then
                            fovConn:Disconnect()
                            fovConn = nil
                        end
                        circle.Position = Vector2.new(mouse.X, mouse.Y)
                        circle.Radius = fov
                        print('Circle Pos: '..circle.Position..'\nMouse Vector: '..tostring(Vector2.new(mouse.X, mouse.Y)..'\nMouse Y: '..mouse.Y..'\nMouse X: '..mouse.X))
                    end)
                    return
                end)
            else
                if circle then
                    circle:Destroy()
                    circle = nil
                end
            end
        end
    })

    ]]-- 

    AimAssist:CreateSlider({
        Name = 'Speed',
        Min = 1,
        Max = 20,
        Default = 5,
        Function = function(val)
            speed = val
        end
    })
end)

run(function()
    local Interval = 0.2
    local fakelag
    local randomize = false

    fakelag = Combat:CreateModule({
        Name = 'FakeLag',
        Tooltip = "Makes you seem like you're lagging.",
        Function = function(call)
            fakelag:Clean(lplr.OnTeleport:Connect(function()
                setfflag('PhysicsSenderMaxBandwidthBps', '38760')
            end))

            while true do
                if not call then break end
                if randomize then
                    setfflag('PhysicsSenderMaxBandwidthBps', '38760')
                    task.wait(math.random(Interval - 0.4, Interval + 0.4))
                    setfflag('PhysicsSenderMaxBandwidthBps', '0')
                    task.wait(math.random(Interval - 0.4, Interval + 0.4))
                else
                    setfflag('PhysicsSenderMaxBandwidthBps', '38760')
                    task.wait(Interval)
                    setfflag('PhysicsSenderMaxBandwidthBps', '0')
                    task.wait(Interval)
                end
            end
        end
    })

    fakelag:CreateSlider({
        Name = 'Interval',
        Min = 0,
        Max = 1,
        Suffix = 0.01,
        Default = 0.25,
        Function = function(val)
            Interval = val
        end
    })

    fakelag:CreateToggle({
        Name = 'Randomize',
        Enabled = true,
        Function = function(call)
            randomize = call
        end
    })
end)

Settings:CreateModule({
    Name = 'Uninject',
    Tooltip = 'Uninjects the client from Roblox.',
    Function = function(call)
        if call then
            vapelite:Uninject()
        end
    end
})

run(function()
    local function tryInjection()
        task.spawn(function()
            repeat task.wait() until isfile('vapelite.injectable.txt')
            if isfile('vapelite.injectable.txt') then
                delfile("vapelite.injectable.txt")
                loadstring(readfile("VapeLite/MainScript.lua"))()
                return
            else
                tryInjection()
                return
            end
        end)
    end

    Settings:CreateModule({
        Name = "Reinject",
        Tooltip = "Reinjects the script.",
        Function = function(enabled)
            if enabled then
                vapelite:Uninject()
                task.spawn(tryInjection)
            end
        end
    })
end)

if not called then
    vapelite:Load()
end