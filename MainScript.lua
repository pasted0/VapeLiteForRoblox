-- will probably use this for somthing more later
local vapelite = loadstring(readfile('VapeLite/Init.lua'))()

local basePath = "VapeLite/CustomModules"
local placePath = basePath .. "/" .. tostring(game.PlaceId) .. ".lua"
local toLoad = isfile(placePath) and placePath or basePath .. "/Universal.lua"

print('[ VAPELITE ]: Loading File: '..tostring(toLoad)
)

loadstring(readfile(toLoad))(vapelite)

print("VapeLite Clean Framework Loaded")
print("Frontend sync initialized")
