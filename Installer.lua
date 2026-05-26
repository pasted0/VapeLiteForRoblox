local http = http or request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request) or (getgenv().request)
local httpService = game:GetService("HttpService")

if isfolder('VapeLite') then
    delfolder('VapeLite')
end

local function getFilesFromGithubFolder(folder)
    local url = string.format("https://api.github.com/repos/pasted0/VapeLiteForRoblox/contents/%s", folder)
    local response = http({
        Url = url,
        Method = "GET",
        Headers = {
            ["User-Agent"] = "Mozilla/5.0"
        }
    })

    if response.StatusCode == 200 then
        local data = httpService:JSONDecode(response.Body)
        local files = {}
        for _, item in ipairs(data) do
            if item.type == "file" then
                table.insert(files, item.path)
            end
        end
        return files
    else
        warn("Failed to fetch files from GitHub: " .. response.StatusCode)
        return nil
    end
end

makefolder('VapeLite')
writefile('VapeLite/Init.lua', game:HttpGet("https://raw.githubusercontent.com/pasted0/vapelite/main/Init.lua"))
writefile('VapeLite/MainScript.lua', game:HttpGet("https://raw.githubusercontent.com/pasted0/vapelite/main/MainScript.lua"))
makefolder('VapeLite/CustomModules')
writefile('VapeLite/CustomModules/Universal.lua', game:HttpGet("https://raw.githubusercontent.com/pasted0/vapelite/main/CustomModules/Universal.lua"))


local files = getFilesFromGithubFolder("CustomModules")
if files then
    for _, file in next, files do
        local content = game:HttpGet("https://raw.githubusercontent.com/pasted0/vapelite/main/" .. file)
        writefile("VapeLite/" .. file, content)
        print("[ VAPELITE ]: Wrote to file: " .. file)
    end
end


makefolder('VapeLite/Profiles')

loadstring(readfile('VapeLite/MainScript.lua'))()