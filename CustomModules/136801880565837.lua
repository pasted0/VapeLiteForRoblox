local vapelite = ...

local plrs = cloneref(game:GetService('Players'))
local runService = cloneref(game:GetService('RunService'))

local cam = workspace.CurrentCamera
local lplr = plrs.LocalPlayer
local mouse = lplr:GetMouse()

local char = lplr.Character or lplr.CharacterAdded:Wait()
local root = char:WaitForChild('HumanoidRootPart')

local function run(func)
    func()
end

vapelite:Load()
print('l')