local http = http or request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request) or (getgenv().request)
local httpService = game:GetService("HttpService")

if isfolder('VapeLite') then
    delfolder('VapeLite')
end



makefolder('VapeLite')
writefile('VapeLite/MainScript.lua', game:HttpGet("https://raw.githubusercontent.com/pasted0/VapeLiteForRoblox/refs/heads/main/MainScript.lua"))
makefolder('VapeLite/CustomModules')




makefolder('VapeLite/Profiles')

loadstring(readfile('VapeLite/MainScript.lua'))()