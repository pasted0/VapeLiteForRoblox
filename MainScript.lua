local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end

shared.vapelite = nil
local vapelite = shared.vapelite
local playersService = cloneref(game:GetService("Players"))
local runService = cloneref(game:GetService("RunService"))
local httpService = cloneref(game:GetService("HttpService"))

local lplr = playersService.LocalPlayer

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
        Modules = {},
        Categories = {}
    }

    local function getTableSize(tab)
        local ind = 0
        for _ in pairs(tab) do ind = ind + 1 end
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

    function vapelite:Send(data)
        if suc and web then
            pcall(function()
                web:Send(httpService:JSONEncode(data))
            end)
        end
    end

    function vapelite:CreateCategory(name)
        if not name or name == "" then return nil end
        if self.Categories[name] then return self.Categories[name] end

        local categoryapi = {
            Name = name,
            Modules = {},
            CreateModule = function(self, settings)
                if not settings or not settings.Name then return nil end
                settings.Category = name
                return vapelite:CreateModule(settings)
            end
        }
        self.Categories[name] = categoryapi
        self:Send({ msg = "createcategory", name = name })
        return categoryapi
    end

    function vapelite:CreateModule(settings)
        if not settings or not settings.Name then return nil end
        local moduleName = settings.Name

        local moduleapi = {
            Enabled = false,
            Options = {},
            Connections = {},
            Name = moduleName,
            Tooltip = settings.Tooltip or "",
            Category = settings.Category or nil
        }

        if moduleapi.Category then
            if not self.Categories[moduleapi.Category] then
                self:CreateCategory(moduleapi.Category)
            end
        end

        function moduleapi:CreateToggle(optionSettings)
            local optionapi = {
                Type = "Toggle",
                Enabled = false,
                Index = getTableSize(moduleapi.Options)
            }
            optionSettings.Function = optionSettings.Function or function() end

            function optionapi:Toggle()
                optionapi.Enabled = not optionapi.Enabled
                pcall(optionSettings.Function, optionapi.Enabled)
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
                Value = optionSettings.Default or optionSettings.Min or 0,
                Min = optionSettings.Min or 0,
                Max = optionSettings.Max or 100,
                Suffix = optionSettings.Suffix or 1,
                Index = getTableSize(moduleapi.Options)
            }
            optionSettings.Function = optionSettings.Function or function() end

            function optionapi:SetValue(value)
                if tonumber(value) == math.huge or value ~= value then
                    return
                end
                optionapi.Value = value
                pcall(optionSettings.Function, value)
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
                        if v and v.Disconnect then
                            v:Disconnect()
                        elseif v and typeof(v) == "RBXScriptConnection" then
                            pcall(function() v:Disconnect() end)
                        end
                    end)
                end
                for i = #moduleapi.Connections, 1, -1 do table.remove(moduleapi.Connections, i) end
            end

            task.spawn(function()
                if settings.Function then
                    pcall(settings.Function, moduleapi.Enabled)
                end
            end)

            vapelite:UpdateTextGUI()
        end

        self.Modules[moduleName] = moduleapi
        return moduleapi
    end

    function vapelite:Remove(module)
        if not module then return end

        local mod = vapelite.Modules[module]
        if mod then
            if mod.Enabled then
                mod:Toggle()
            end

            if mod.Category and vapelite.Categories[mod.Category] then
                local list = vapelite.Categories[mod.Category].Modules
                for i = #list, 1, -1 do
                    if list[i] == mod then
                        table.remove(list, i)
                    end
                end
                if #vapelite.Categories[mod.Category].Modules == 0 then
                    vapelite.Categories[mod.Category] = nil
                end
            end

            vapelite.Modules[module] = nil
            vapelite:Send({ msg = "deletemodule", module = module })
        end
    end

    function vapelite:Save()
        if not vapelite.Loaded then return end
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
                toggled = module.Enabled,
                category = module.Category
            }

            for optionName, option in pairs(module.Options) do
                if option.Type == "Slider" then
                    table.insert(newmodule.options, {
                        name = optionName,
                        type = "Slider",
                        state = option.Value,
                        min = option.Min,
                        max = option.Max,
                        suffix = option.Suffix,
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

            table.sort(newmodule.options, function(a, b) return a.index < b.index end)
            table.insert(replicatedmodules, newmodule)
        end

        table.sort(replicatedmodules, function(a, b) return a.name < b.name end)
        vapelite.Loaded = true
        vapelite:Send({ msg = "connectrequest", modules = replicatedmodules })
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
            pcall(function() web:Disconnect() end)
        end

        vapelite.Loaded = nil

        for _, module in pairs(vapelite.Modules) do
            if module.Enabled then
                module:Toggle()
            end
        end

        for _, connection in pairs(vapelite.Connections) do
            pcall(function() connection:Disconnect() end)
        end

        shared.vapelite = nil
    end

    shared.vapelite = vapelite.Uninject
end)

vapelite.BadExecutor = false
local exe = tostring(identifyexecutor())
if exe:find('Velocity') then
    vapelite.BadExecutor = true
end

if web then
    table.insert(vapelite.Connections, web.OnMessage:Connect(vapelite.Receive))
    table.insert(vapelite.Connections, web.OnClose:Connect(vapelite.Uninject))
end

if lplr then
    table.insert(vapelite.Connections, lplr.OnTeleport:Connect(function()
        vapelite.Uninject(true)
    end))
end

local basePath = 'VapeLite/CustomModules'
local placePath = basePath .. '/' .. tostring(game.PlaceId) .. '.lua'

local function getFileIfBadExec(filepath)
    local found
    task.spawn(function()
        found = game:HttpGet('https://raw.githubusercontent.com/pasted0/VapeLiteForRoblox/refs/heads/main/'..filepath)
    end)
    task.wait(1)
    if not found then
        print('Velocity is the best executor ever!!!')
        return false
    end
    return found
end

if not vapelite.BadExecutor then
    if not isfile(placePath) then
        local file = game:HttpGet('https://raw.githubusercontent.com/pasted0/VapeLiteForRoblox/refs/heads/main/CustomModules/' .. tostring(game.PlaceId) .. '.lua')
        if file ~= '404: Not Found' then
            writefile(placePath, file)
        end
    end

    if not isfile(basePath .. '/Universal.lua') then
        local file = game:HttpGet('https://raw.githubusercontent.com/pasted0/VapeLiteForRoblox/refs/heads/main/CustomModules/Universal.lua')
        if file ~= '404: Not Found' then
            writefile(basePath .. '/Universal.lua', file)
        end
    end
else
    if not isfile(placePath) and getFileIfBadExec('https://raw.githubusercontent.com/pasted0/VapeLiteForRoblox/refs/heads/main/CustomModules/' .. tostring(game.PlaceId) .. '.lua') then
        writefile(placePath, getFileIfBadExec('https://raw.githubusercontent.com/pasted0/VapeLiteForRoblox/refs/heads/main/CustomModules/' .. tostring(game.PlaceId) .. '.lua'))
    else
        if not isfile(basePath .. '/Universal.lua') then
            writefile(basePath .. '/Universal.lua', getFileIfBadExec('https://raw.githubusercontent.com/pasted0/VapeLiteForRoblox/refs/heads/main/CustomModules/Universal.lua'))
        end
    end
end

local toLoad = isfile(placePath) and placePath or nil
if not toLoad then
    toLoad = basePath .. "/Universal.lua"
else
    print('[ VAPELITE ]: Loading Universal Modules')
    loadstring(readfile(basePath .. '/Universal.lua'))(vapelite, true)
end

print('[ VAPELITE ]: Loading File: '..tostring(toLoad))
loadstring(readfile(toLoad))(vapelite)