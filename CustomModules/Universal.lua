local vapelite = ...
local plrs = cloneref(game:FindService('Players'))
local runService = cloneref(game:GetService('RunService'))

local lplr = plrs.LocalPlayer


local function run(func)
    func()
end



vapelite:CreateModule({
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
    nameHider = vapelite:CreateModule({
        Name = 'NameHider',
        Tooltip = 'Hides your name on the client. Useful for streamers.',
        Function = function()
            if name == false then 
                name = lplr.Name
                display = lplr.DisplayName
            end
            lplr.Name = name
            lplr.DisplayName = display
            

            nameHider:Clean(runService.RenderStepped:Connect(function() -- idk just kinda wanted to use the clean func
                lplr.Name = 'NickHider'
                lplr.DisplayName = 'NickHider'
            end))
        end
    })
end)



vapelite:CreateModule({
    Name = 'Uninject',
    Tooltip = 'Uninjects the client from Roblox.',
    Function = function(call)
        if call then
            vapelite.Uninject()
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

     vapelite:CreateModule({
        Name = "Reinject",
        Tooltip = "Reinjects the script.",
        Function = function(enabled)
            if enabled then
                vapelite.Uninject()
                task.spawn(tryInjection())
            end
        end
    })
end)
   


vapelite:Load()
