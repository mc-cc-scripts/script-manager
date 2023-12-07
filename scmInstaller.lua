--installs the scm files into the game
---@class SCMInstaller
local SCMInstaller = {}

function SCMInstaller:getFilesTxt(source)
    local files = {}
    print("Downloading from " .. source .. "files.txt")
    local response = http.get(source .. "files.txt")
    if response == nil or response.getResponseCode() ~= 200 then
        error("Failed to download files.txt")
    end
    local file = response.readLine()
    while file ~= nil do
        table.insert(files, file)
        file = response.readLine()
    end
    response.close()
    return files
end

function SCMInstaller:deleteFiles(files)
    for _, value in ipairs(files) do
        print("Deleting File " .. value)
        if fs.exists(value) then
            fs.delete(value)
        end
    end
end

-- download the files
function SCMInstaller:downloadFiles(source, files)
    for index, value in ipairs(files) do
        print('Downloading ' .. index .. ' of ' .. #files .. ' files: ' .. value)
        local response = http.get(source .. value)
        if not response or response.getResponseCode() ~= 200 then
            error("Failed to download " .. value)
        end
        local file = fs.open(value, "w")
        file.write(response.readAll())
        file.close()
        response.close()
    end
end

return SCMInstaller
