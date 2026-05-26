local run = function(func)
    func()
end

local cloneref = cloneref or function(obj)
    return obj
end

shared.vapelite = nil
local vapelite = shared.vapelite
local playersService = cloneref(game:GetService("Players"))
local runService = cloneref(game:GetService("RunService"))
local httpService = cloneref(game:GetService("HttpService"))

local lplr = playersService.LocalPlayer

--// WebSocket
local suc, web = pcall(function()
    return WebSocket.connect("ws://127.0.0.1:6892/")
end)

if not suc or type(web) == "boolean" then
    repeat
        suc, web = pcall(function()
            return WebSocket.connect("ws://127.0.0.1:6892/")
        end)

        if not suc or type(web) == "boolean" then
            warn("websocket error:", web)
        else
            break
        end

        task.wait(1)
    until suc and type(web) ~= "boolean"
end



run(function()
    vapelite = {
        Connections = {},
        Loaded = false,
        Modules = {}
    }
    local function getTableSize(tab)
        local ind = 0

        for _ in pairs(tab) do
            ind += 1
        end

        return ind
    end

    function vapelite:UpdateTextGUI()
        print("=== Enabled Modules ===")

        for name, module in pairs(vapelite.Modules) do
            if module.Enabled then
                print("•", name)
            end
        end
    end

    function vapelite:CreateModule(settings)
        local moduleapi = {
            Enabled = false,
            Options = {},
            Connections = {},
            Name = settings.Name,
            Tooltip = settings.Tooltip
        }

        function moduleapi:CreateToggle(optionSettings)
            local optionapi = {
                Type = "Toggle",
                Enabled = false,
                Index = getTableSize(moduleapi.Options)
            }

            optionSettings.Function = optionSettings.Function or function() end

            function optionapi:Toggle()
                optionapi.Enabled = not optionapi.Enabled
                optionSettings.Function(optionapi.Enabled)
            end

            if optionSettings.Default then
                optionapi:Toggle()
            end

            moduleapi.Options[optionSettings.Name] = optionapi
            return optionapi
        end

        function moduleapi:CreateSlider(optionSettings)
            local optionapi = {
                Type = "Slider",
                Value = optionSettings.Default or optionSettings.Min,
                Min = optionSettings.Min,
                Max = optionSettings.Max,
                Index = getTableSize(moduleapi.Options)
            }

            optionSettings.Function = optionSettings.Function or function() end

            function optionapi:SetValue(value)
                if tonumber(value) == math.huge or value ~= value then
                    return
                end

                optionapi.Value = value
                optionSettings.Function(value)
            end

            moduleapi.Options[optionSettings.Name] = optionapi
            return optionapi
        end

        function moduleapi:Clean(obj)
            table.insert(moduleapi.Connections, obj)
        end

        function moduleapi:Toggle()
            moduleapi.Enabled = not moduleapi.Enabled

            if not moduleapi.Enabled then
                for _, v in pairs(moduleapi.Connections) do
                    pcall(function()
                        v:Disconnect()
                    end)
                end

                table.clear(moduleapi.Connections)
            end

            task.spawn(settings.Function, moduleapi.Enabled)
            vapelite:UpdateTextGUI()
        end

        vapelite.Modules[settings.Name] = moduleapi
        return moduleapi
    end

    function vapelite:Send(data)
        if suc and web then
            web:Send(httpService:JSONEncode(data))
        end
    end

    function vapelite:Save()
        if not vapelite.Loaded then
            return
        end

        vapelite:Send({
            msg = "writesettings",
            id = "vapeliteclean",
            content = httpService:JSONEncode(vapelite.Modules)
        })
    end

    function vapelite:Load()
        local replicatedmodules = {}

        for moduleName, module in pairs(vapelite.Modules) do
            local newmodule = {
                name = moduleName,
                desc = module.Tooltip,
                options = {},
                toggled = module.Enabled
            }

            for optionName, option in pairs(module.Options) do
                if option.Type == "Slider" then
                    table.insert(newmodule.options, {
                        name = optionName,
                        type = "Slider",
                        state = option.Value,
                        min = option.Min,
                        max = option.Max,
                        index = option.Index
                    })
                else
                    table.insert(newmodule.options, {
                        name = optionName,
                        type = "Toggle",
                        toggled = option.Enabled,
                        index = option.Index
                    })
                end
            end

            table.sort(newmodule.options, function(a, b)
                return a.index < b.index
            end)

            table.insert(replicatedmodules, newmodule)
        end

        table.sort(replicatedmodules, function(a, b)
            return a.name < b.name
        end)

        vapelite.Loaded = true

        vapelite:Send({
            msg = "connectrequest",
            modules = replicatedmodules
        })
    end

    function vapelite.Receive(data)
        data = httpService:JSONDecode(data)

        if data.msg == "togglemodule" then
            local module = vapelite.Modules[data.module]

            if module and module.Enabled ~= data.state then
                module:Toggle()
            end
        elseif data.msg == "togglebuttontoggle" or data.msg == "togglebuttonslider" then
            local option = vapelite.Modules[data.module] and vapelite.Modules[data.module].Options[data.setting]

            if option then
                if option.Type == "Toggle" then
                    option:Toggle()
                else
                    option:SetValue(data.state)
                end
            end
        elseif data.msg == "print" then
            print("[WebSocket]", data.content)
        end

        vapelite:Save()
    end

    function vapelite.Uninject()
        if web then
            pcall(function()
                web:Disconnect()
            end)
        end

        vapelite.Loaded = nil

        for _, module in pairs(vapelite.Modules) do
            if module.Enabled then
                module:Toggle()
            end
        end

        for _, connection in pairs(vapelite.Connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end

        shared.vapelite = nil
    end

    shared.vapelite = vapelite.Uninject
end)


--// WebSocket Hooks
if web then
    table.insert(vapelite.Connections, web.OnMessage:Connect(vapelite.Receive))
    table.insert(vapelite.Connections, web.OnClose:Connect(vapelite.Uninject))
end

if lplr then
    table.insert(vapelite.Connections, lplr.OnTeleport:Connect(function()
        vapelite.Uninject(true)
    end))
end


local basePath = "VapeLite/CustomModules"
local placePath = basePath .. "/" .. tostring(game.PlaceId) .. ".lua"
local toLoad = isfile(placePath) and placePath or basePath .. "/Universal.lua"

print('[ VAPELITE ]: Loading File: '..tostring(toLoad)
)

loadstring(readfile(toLoad))(vapelite)
