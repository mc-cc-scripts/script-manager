--installs the scm files into the game
---@class SCMInstaller
local SCMInstaller = {}


local files = {}
local source = "raw.githubusercontent.com/mc-cc-scripts/script-manager/Issue-30-Spilt-SCM/"


function SCMInstaller:getFilesTxt()
    http.get(source .. "files.txt", nil, function(response)
        local file = response.readLine()
        while file ~= nil do
            table.insert(files, file)
            file = response.readLine()
        end
        response.close()
    end)
end

function SCMInstaller:delteFiles()
    for _, value in ipairs(files) do
        print("Deleting File " .. value)
        if fs.exists(value) then
            fs.delete(value)
        end
    end
end

-- download the files
function SCMInstaller:downloadFiles()
    for index, value in ipairs(files) do
        http.get(source .. value, nil, function(response)
            print('Downloading ' .. index .. ' of ' .. #files .. ' files: ' .. value)
            local file = fs.open(value, "w")
            file.write(response.readAll())
            file.close()
            response.close()
        end)
    end
end

return SCMInstaller
