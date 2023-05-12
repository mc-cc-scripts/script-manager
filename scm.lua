---Note: scm is not a real class, it should only exist once.
---@class scm
local scm = {}

-- Configuration
scm.config = {
    -- Git Settings (In this case on GitHub, not tested with others)
    ["user"] = "mc-cc-scripts",
    ["repository"] = "script-manager",
    ["branch"] = "master",
    ["rawURL"] = "https://raw.githubusercontent.com/",
    ["programSuffix"] = "-prog",
    ["librarySuffix"] = "-lib",
    ["infoFile"] = "files.txt", -- provides the structure of a git repo (paths to all files)
    ["apiGithubURL"] = "https://api.github.com/orgs/",
    ["apiGithubGetRepos"] = "/repos?type=all&per_page=100&page=1",
    ["apiGithubGetTags"] = "https://api.github.com/repos/<USER>/<REPO>/tags",
    ["installScript"] = "1kKZ8zTS",
    -- Local Settings
    ["currentVersion"] = "0.0.0", -- will get the newest version through the github api, no need to update here
    ["updateAvailable"] = false,
    ["lastVersionCheck"] = "1",
    ["programDirectory"] = "progs/",
    ["libraryDirectory"] = "libs/",
    ["configDirectory"] = "config/",
    ["configFile"] = "scm-config.json",
    ["scriptFile"] = "scm-scripts.json", -- will be saved in configDirectory as well
    ["verbose"] = true,
    ["printPrefix"] = "[scm] ",
    ["logDate"] = false,
    ["writeLogFile"] = false,
    ["logFilePath"] = "logs/scm-log.txt",
    ["repoScriptsFile"] = "scm-repo-scripts.txt", -- will be saved in configDirectory as well
    ["allowCLIPrefix"] = true,
    ["cliPrefix"] = false
}
----------------


scm.scripts = {}
scm.commands = {
    ["require"] = {
        ---@param args table
        func = function(args)
            scm:download(args[2], "library", nil)
        end,
        description = [[
Adds a library with all its dependencies.
If only a name is given, it will try to download from the official GitHub repositories.
$ require <name>
$ require <name>@<pastebinCode>
        ]]
    },
    ["add"] = {
        ---@param args table
        func = function(args)
            scm:download(args[2], "program", nil)
        end,
        description = [[
Adds a program with all its dependencies.
If only a name is given, it will try to download from the official GitHub repositories.
$ add <name>
$ add <name>@<pastebinCode>
        ]]
    },
    ["update"] = {
        ---@param args table
        func = function(args)
            if args[2] == "all" then
                scm:updateAllScripts()
            elseif args[3] then
                scm:updateScript(args[2], args[3])
            elseif args[2] then
                scm:updateScript(args[2], nil)
            else
                scm:updateSCM()
            end
        end,
        description = [[
$ update
  Updates this program (SCM)
$ update <name>
  Updates the script with the given name
$ update all
  Updates all installed programs and libraries
$ update <name> <srcName>
  Updates the script with an specific source
        ]]
    },
    ["remove"] = {
        ---@param args table
        func = function(args)
            if args[2] == "all" then
                scm:removeAllScripts()
            else
                scm:removeScript(args[2])
            end
        end,
        description = [[
$ remove <name>
  Removes the given script
$ remove all
  Removes all scripts
        ]]
    },
    ["list"] = {
        ---@param _ table
        func = function(_)
            scm:listScripts()
        end,
        description = [[
$ list
  Lists all installed scripts
        ]]
    },
    ["config"] = {
        ---@param args table
        func = function(args)
            if args[3] then
                scm:updateConfig(args[2], args[3])
            elseif args[2] then
                if scm.config[args[2]] ~= nil then
                    print(args[2], tostring(scm.config[args[2]]))
                end
            else
                print("You can currently configure the following variables:")
                for cname, cvalue in pairs(scm.config) do
                    textutils.pagedPrint(cname .. "\t" .. tostring(cvalue))
                end
            end
        end,
        description = [[
$ config
  Lists all available configurations
$ config <name>
  Shows a specific configuration
$ config <name> <value>
  Updates the configuration
        ]]
    },
    ["refresh"] = {
        func = function(args)
            scm:refreshAutocomplete()
        end,
        description = [[
$ refresh
  Downloads the names of all programs and libraries of the official repository.
  Refreshes autocomplete.
        ]]
    },
    ["help"] = {
        ---@param args table
        func = function(args)
            if args[2] then
                if scm.commands[args[2]] then
                    textutils.pagedPrint(args[2] .. "\n" .. scm.commands[args[2]]["description"])
                end
            else
                for k, v in pairs(scm.commands) do
                    textutils.pagedPrint("# " .. k .. "\n" .. v.description)
                end
            end
        end,
        description = [[
$ help
  Shows all available commands and their description
$ help <name>
  Shows the description of the given command
        ]]
    }
}

function scm:refreshRepoScripts()
    self:log("Downloading program and library names from GitHub...")
    local repoScripts = {}

    local programs = {}
    local libraries = {}

    local request = http.get(self.config["apiGithubURL"] .. self.config["user"] .. self.config["apiGithubGetRepos"])
    if request then
        local response = request.readAll()
        request.close()

        local responseTable = textutils.unserializeJSON(response)

        local programSuffix = self.config["programSuffix"]
        local librarySuffix = self.config["librarySuffix"]

        for i = 1, #responseTable, 1 do
            local scriptName = responseTable[i]["name"]
            if string.sub(scriptName, -string.len(programSuffix)) == programSuffix then
                programs[
                string.sub(scriptName, 0, string.len(scriptName) - string.len(programSuffix))
                ] = {}
            elseif string.sub(scriptName, -string.len(librarySuffix)) == librarySuffix then
                libraries[
                string.sub(scriptName, 0, string.len(scriptName) - string.len(librarySuffix))
                ] = {}
            end
        end
        scm:log("Done")
    else
        scm:log("Download failed")
    end

    self.commands["add"]["args"] = programs
    self.commands["require"]["args"] = libraries

    repoScripts["libraries"] = libraries
    repoScripts["programs"] = programs

    local file = fs.open(self.config["configDirectory"] .. self.config["repoScriptsFile"], "w")
    if file then
        file.write(textutils.serializeJSON(repoScripts))
        file.close()
    end
end

function scm:loadRepoScripts()
    local file = fs.open(self.config["configDirectory"] .. self.config["repoScriptsFile"], "r")

    if not file then
        self:refreshRepoScripts()
    else
        local repoScripts = textutils.unserializeJSON(file.readAll()) or nil
        if repoScripts then
            self.commands["add"]["args"] = repoScripts["programs"]
            self.commands["require"]["args"] = repoScripts["libraries"]
        end

        file.close()
    end
end

function scm:prepareAutocomplete()
    -- prepare update and remove
    scm:loadScripts()
    local installedScripts = {}
    for i = 1, #self.scripts, 1 do
        installedScripts[self.scripts[i].name] = {}
    end
    installedScripts["all"] = {}

    self.commands["update"]["args"] = installedScripts
    self.commands["remove"]["args"] = installedScripts

    -- prepare add and require
    self:loadRepoScripts()

    -- prepare config
    local availableConfigs = {}

    for k, _ in pairs(self.config) do
        availableConfigs[k] = {}
    end

    self.commands["config"]["args"] = availableConfigs

    -- prepare help
    local availableCommands = {}

    for k, _ in pairs(self.commands) do
        availableCommands[k] = {}
    end

    self.commands["help"]["args"] = availableCommands
end

---@param shell table
---@param index integer
---@param argument string
---@param previous table
---@return table | nil
local function completionFunction(shell, index, argument, previous)
    local commands = {}
    for k, _ in pairs(scm.commands) do
        commands[k] = scm.commands[k]["args"] or {}
    end

    local currArg = commands
    for i = 2, #previous do
        if currArg[previous[i]] then
            currArg = currArg[previous[i]]
        else
            return nil
        end
    end

    local results = {}
    for word, _ in pairs(currArg) do
        if word:sub(1, #argument) == argument then
            results[#results + 1] = word:sub(#argument + 1)
        end
    end
    return results;
end

local function updateAutocomplete()
    shell.setCompletionFunction("scm", completionFunction)
end

function scm:refreshAutocomplete()
    scm:refreshRepoScripts()
    scm:prepareAutocomplete()
    updateAutocomplete()
end

---@param message string
function scm:log(message)
    local datetime = ""
    if self.config["logDate"] then datetime = os.date("[%Y-%m-%d %H:%M:%S] ") end
    if self.config["verbose"] then print(self.config["printPrefix"] .. message) end

    if self.config["writeLogFile"] then
        local file = fs.open(self.config["logFilePath"], "a")
        file.write(datetime .. message .. "\n")
        file.close()
    end
end

---@param str string
---@return string | nil
---@return string | nil
function scm:splitNameCode(str)
    local separator = string.find(str, "@")

    if separator then
        local name = string.sub(str, 1, separator - 1)
        local code = string.sub(str, separator + 1)
        return name, code
    end

    return nil, nil
end

---@param target string
---@param fileType string
---@param updateObj table | nil
---@return boolean
function scm:download(target, fileType, updateObj)
    scm:log("Downloading " .. fileType .. " " .. target .. "...")
    if target == nil then
        --@TODO: Error handling
        return false
    end

    local sourceObject = {
        name = nil,
        source = {
            ["default"] = target
        },
        type = fileType
    }

    if updateObj then sourceObject.name = updateObj.name end

    -- Check for Pastebin
    local name, code = self:splitNameCode(target)
    if name and code then
        sourceObject.name = name
        return scm:addScript(self:downloadPastebin(sourceObject, code, self.config[fileType .. "Directory"], updateObj))
    end

    -- We assume it's Git
    -- The suffix is used to find the correct repository on GitHub
    local suffix
    if fileType == "library" then
        suffix = self.config["librarySuffix"]
    else
        suffix = self.config["programSuffix"]
    end
    local repository = target .. suffix
    sourceObject.name = target

    return scm:addScript(self:downloadGit(sourceObject, repository, self.config[fileType .. "Directory"], updateObj))
end

---@param sourceObject table
---@param repository string
---@param targetDirectory string
---@param updateObj table | nil
---@return table | nil
---@return boolean
function scm:downloadGit(sourceObject, repository, targetDirectory, updateObj)
    local baseUrl = self.config["rawURL"] ..
        self.config["user"] .. "/" ..
        repository .. "/" ..
        self.config["branch"] .. "/"

    local filesUrl = baseUrl .. self.config["infoFile"]

    local request = http.get(filesUrl)
    if request then
        local content = request.readAll()
        request.close()

        if content then
            local file = fs.open(targetDirectory .. sourceObject.name
                .. self.config[sourceObject.type .. "Suffix"]
                .. "/" .. self.config["infoFile"], "w")
            file.write(content)
            file.close()

            local filePaths = {}
            file = fs.open(targetDirectory .. sourceObject.name
                .. self.config[sourceObject.type .. "Suffix"]
                .. "/" .. self.config["infoFile"], "r")
            for line in file.readLine do
                filePaths[#filePaths + 1] = line
            end
            file.close()

            for i = 1, #filePaths, 1 do
                local success = true
                local tmpRequest = http.get(baseUrl .. filePaths[i])
                if tmpRequest then
                    local tmpContent = tmpRequest.readAll()
                    if tmpContent then
                        local tmpFile = fs.open(targetDirectory .. sourceObject.name
                            .. self.config[sourceObject.type .. "Suffix"]
                            .. "/" .. filePaths[i], "w")
                        tmpFile.write(tmpContent)
                        tmpFile.close()
                    else
                        success = false
                    end

                    tmpRequest.close()
                else
                    success = false
                end

                if not success then
                    return nil, false
                end
            end

            -- create a link that calls the file within the program directory
            if sourceObject.type == "program" then
                local progamLink = fs.open(sourceObject.name, "w")
                progamLink.write("shell.execute(\"" .. targetDirectory .. sourceObject.name ..
                    self.config[sourceObject.type .. "Suffix"]
                    .. "/" .. sourceObject.name .. ".lua" .. "\", ...)")
                progamLink.close()
            elseif sourceObject.type == "library" then
                local libraryLink = fs.open(targetDirectory .. sourceObject.name .. ".lua", "w")

                local tmpName = sourceObject.name
                if tmpName:find("%.") then
                    tmpName = tmpName:match("(.+)%..+$")
                end

                libraryLink.write("return require(\"./" .. self.config["libraryDirectory"]
                    .. tmpName .. self.config[sourceObject.type .. "Suffix"]
                    .. "/" .. tmpName .. "\")")
                libraryLink.close()
            end

            return sourceObject, true
        end
    end

    return nil, false
end

---@param sourceObject table
---@param code string
---@param targetDirectory string
---@param updateObj table | nil
---@return table | nil
---@return boolean
function scm:downloadPastebin(sourceObject, code, targetDirectory, updateObj)
    -- Only download if it does not already exist, or if it should be updated
    if fs.exists(targetDirectory .. sourceObject.name) then
        if updateObj then
            fs.delete(targetDirectory .. sourceObject.name)
            sourceObject = updateObj
        else
            -- File already exists, you should use update
            return nil, false
        end
    end

    if updateObj then
        fs.delete(sourceObject.name)
    end

    if sourceObject.type == "program" then
        shell.run("pastebin", "get", code, sourceObject.name .. ".lua")
    else
        shell.run("pastebin", "get", code, targetDirectory .. sourceObject.name .. ".lua")
    end

    return sourceObject, true
end

---@param sourceObject table
---@param targetDirectory string
---@param updateObj table | nil
---@return table | nil
---@return boolean
function scm:downloadURL(sourceObject, targetDirectory, updateObj)
    local sourceName = "default" or updateObj.sourceName
    if updateObj then
        sourceObject.name = sourceObject.name or updateObj.name
    end

    if not sourceObject.name then
        sourceObject.name = self:getNameFromURL(sourceObject.source[sourceName])
    end

    local request = http.get(sourceObject.source[sourceName])

    if request then
        local content = request.readAll()
        request.close()

        if content then
            local file = fs.open(targetDirectory .. sourceObject.name, "w")
            file.write(content)
            file.close()
            return sourceObject, true
        end
    end

    return nil, false
end

---@param url string
---@return string
function scm:getNameFromURL(url)
    -- Gets the filename + extension from a url (everything after last /)
    local name = url:match("[^/]+$")

    -- Remove file extension if name contains a dot
    if name:find("%.") then
        name = name:match("(.+)%..+$")
    end

    return name
end

---@param sourceObject table | nil
---@param success boolean
---@return boolean
function scm:addScript(sourceObject, success)
    if not success or not sourceObject then return false end
    scm:log("Adding script " .. sourceObject.name .. "...")
    local scriptExists = false

    -- Check if script already exists, then update
    for i = 1, #self.scripts, 1 do
        if self.scripts[i].name == sourceObject.name and self.scripts[i].type == sourceObject.type then
            scriptExists = true
            if self.scripts[i].source[sourceObject.sourceName] then
                self.scripts[i].source[sourceObject.sourceName] = sourceObject.source[sourceObject.sourceName]
                self:saveScripts()

                return true
            end
        end
    end

    if not scriptExists then
        scm:log("Script added: " .. sourceObject.name)
        table.insert(self.scripts, sourceObject)
    else
        scm:log("Script already exists.")
        return false
    end

    self:saveScripts()

    -- update for autocomplete
    self.commands["update"]["args"] = self.commands["update"]["args"] or {}
    self.commands["remove"]["args"] = self.commands["remove"]["args"] or {}
    self.commands["update"]["args"][sourceObject.name] = {}
    self.commands["remove"]["args"][sourceObject.name] = {}
    self:prepareAutocomplete()
    updateAutocomplete()

    return true
end

function scm:saveScripts()
    local file = fs.open(self.config["configDirectory"] .. self.config["scriptFile"], "w")
    file.write(textutils.serializeJSON(self.scripts))
    file.close()
end

function scm:loadScripts()
    local file = fs.open(self.config["configDirectory"] .. self.config["scriptFile"], "r")

    if not file then
        self:saveScripts()
    else
        self.scripts = textutils.unserializeJSON(file.readAll()) or {}
        file.close()
    end
end

function scm:listScripts()
    print("name", "type")
    print("----------------------")
    for i = 1, #self.scripts, 1 do
        print(self.scripts[i].name, self.scripts[i].type)
    end
end

---@param name string
function scm:removeScript(name, keepScriptConfig)
    scm:log("Removing script: " .. name)
    local o = {}
    local scriptType = nil

    if keepScriptConfig ~= true then
        for i = 1, #self.scripts, 1 do
            if self.scripts[i].name ~= name then
                table.insert(o, self.scripts[i])
            else
                scriptType = self.scripts[i].type
            end
        end

        self.scripts = o
        self:saveScripts()
    end

    -- delete file
    if scriptType and fs.exists(self.config[scriptType .. "Directory"] .. name .. ".lua") then
        fs.delete(self.config[scriptType .. "Directory"] .. name .. self.config[scriptType .. "Suffix"])
        if scriptType == "library" then
            fs.delete(self.config[scriptType .. "Directory"] .. name .. ".lua")
        end
    end

    if scriptType == "program" then
        fs.delete(name)
    end

    -- update autocomplete
    self:prepareAutocomplete()
    updateAutocomplete()
end

function scm:removeAllScripts()
    local tmpScripts = {}
    for i = 1, #self.scripts, 1 do
        table.insert(tmpScripts, self.scripts[i].name)
    end

    for i = 1, #tmpScripts, 1 do
        self:removeScript(tmpScripts[i])
    end
end

---@param name string
---@param sourceName string
---@return boolean
function scm:updateScript(name, sourceName)
    if not sourceName then sourceName = "default" end

    local updateObj = {
        ["name"] = name,
        ["type"] = nil,
        ["sourceName"] = sourceName,
        ["source"] = {}
    }

    for i = 1, #self.scripts, 1 do
        if self.scripts[i].name == name then
            updateObj.source[sourceName] = self.scripts[i].source[sourceName]
            updateObj.type = self.scripts[i].type
        end
    end

    if updateObj.source[sourceName] and updateObj.type then
        self:removeScript(name, true)
        self:download(updateObj.source[sourceName], updateObj.type, updateObj)
        return true
    end

    return false
end

function scm:updateAllScripts()
    for i = 1, #self.scripts, 1 do
        self:updateScript(self.scripts[i].name, "default")
    end
end

function scm:updateSCM()
    scm:log("Updating scm...")
    shell.run("pastebin", "run", self.config.installScript)
    local success, version = self:getNewestVersion()
    if success then
        self.config["currentVersion"] = version
        self.config["updateAvailable"] = false
        self.config["lastVersionCheck"] = os.day("utc")
        self:saveConfig()
    end
end

---@source: https://stackoverflow.com/a/2705804/10495683
---@param T table
---@return integer
local function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function scm:saveConfig()
    local file = fs.open(self.config["configDirectory"] .. self.config["configFile"], "w")
    file.write(textutils.serializeJSON(self.config))
    file.close()
end

function scm:loadConfig()
    local file = fs.open(self.config["configDirectory"] .. self.config["configFile"], "r")

    if not file then
        -- Create config file if it does not exist yet
        self:saveConfig()
    else
        -- Load config from file
        local temp = textutils.unserializeJSON(file.readAll()) or {}
        -- Check if loaded config size is equal to the default size,
        -- otherwise the config is corrupted and will be overwritten
        if tablelength(temp) == tablelength(self.config) then
            self.config = temp
        else
            self:saveConfig()
        end
        file.close()
    end
end

---@param name string
---@param value string
function scm:updateConfig(name, value)
    local writeConfig = true

    if name and value then
        if self.config[name] ~= nil then
            if type(self.config[name]) == type(true) then
                -- Check for boolean
                if value == "true" then
                    self.config[name] = true
                elseif value == "false" then
                    self.config[name] = false
                end
            else
                -- We assume it's a string
                self.config[name] = value
            end
        else
            writeConfig = false
        end

        if writeConfig then
            self:saveConfig()
        end
    else
        scm:log("You can currently configure the following variables:")
        for cname, cvalue in pairs(self.config) do
            scm:log(cname, tostring(cvalue))
        end
    end
end

---@param name string
---@param localPath string | nil | unknown
function scm:checkRequirements(name, localPath)
    scm:log("Checking requirements of " .. (localPath or name) .. "...")
    local file
    if localPath then
        file = fs.open(localPath, "r")
        if not file then
            file = fs.open('./' .. localPath .. ".lua", "r")
        end
    elseif fs.exists("./" .. self.config["libraryDirectory"] .. name .. self.config["librarySuffix"] .. "/" .. name .. ".lua") then
        file = fs.open("./" .. self.config["libraryDirectory"]
            .. name .. self.config["librarySuffix"]
            .. "/" .. name .. ".lua", "r")
    else
        file = fs.open("./" .. self.config["libraryDirectory"] .. name .. ".lua", "r")
    end
    if not file then scm:log('File ' .. name .. ' not found') end
    -- Find requirements by searching for comment --@requires name
    local requires = {}
    while true do
        local line = file.readLine()
        if not line then break end

        local find = string.find(line, "--@requires")
        if find then
            line = string.sub(line, find + 12)
            local lineEnd = string.find(line, " ")

            local scriptName = nil
            if lineEnd then
                scriptName = string.sub(line, 0, lineEnd - 1)
            else
                scriptName = string.sub(line, 0)
            end

            requires[#requires + 1] = scriptName
        end
    end
    file.close()

    -- Install missing requirements
    for i = 1, #requires do
        local n = requires[i]
        local tmpName, tmpCode = self:splitNameCode(n)
        if tmpCode then n = tmpName end

        scm:log("Trying to install " .. n .. "...")

        local scriptExists = false
        for j = 1, #self.scripts, 1 do
            if self.scripts[j].name == n then
                scriptExists = true
            end
        end

        if not scriptExists then
            if tmpCode then
                self:download(tmpName .. "@" .. tmpCode, "library")
            else
                self:download(n, "library")
            end
        else
            scm:log(n .. " already exists.")
        end

        self:checkRequirements(n)
    end
end

--- used when no script with the name was found online
--- searches locally for the script
---@param name string
---@return any | nil
local function fallbackRequire(name)
    scm:log(name .. " not found online, try to find locally")
    --- if script does not exist
    local possiblePath = {
        name,
        scm.config["libraryDirectory"] .. name,
        scm.config["libraryDirectory"] .. name .. "/" .. name,
        scm.config["libraryDirectory"] .. name .. "/" .. "init.lua"
    }
    local script
    local success
    ---TryFunction for Require
    ---@param path string
    ---@return any
    local function tryRequire(path)
        return require(path)
    end

    for _, path in pairs(possiblePath) do
        success, script = pcall(tryRequire, path)
        if success then
            scm:checkRequirements(name, path)
            return script
        end
    end
    scm:log("Could not load " .. name)
    return nil
end

---@param name string
---@return any
function scm:load(name)
    scm:log("Loading " .. name .. "...")
    local scriptExists = false
    for i = 1, #self.scripts, 1 do
        if self.scripts[i].name == name then
            scriptExists = true
        end
    end

    if not scriptExists then
        self:download(name, "library")
    end

    scriptExists = false
    for i = 1, #self.scripts, 1 do
        if self.scripts[i].name == name then
            scriptExists = true
        end
    end

    if scriptExists then
        self:checkRequirements(name)
        local path = "./" .. self.config["libraryDirectory"] .. name
        local script = require(path)
        scm:log("Done")
        return script
    end

    return fallbackRequire(name)
end

function scm:getNewestVersion()
    local githubAPIgetTags = self.config["apiGithubGetTags"]
    githubAPIgetTags = githubAPIgetTags:gsub("<USER>", self.config["user"])
    githubAPIgetTags = githubAPIgetTags:gsub("<REPO>", self.config["repository"])

    local request = http.get(githubAPIgetTags)

    if request then
        local content = request.readAll()
        request.close()
        local scmTags = textutils.unserializeJSON(content)
        return true, scmTags[1]["name"]
    else
        self:log("Request to GitHub API failed.")
        return false, "0.0.0"
    end
end

function scm:checkVersion()
    if not self.config["updateAvailable"] and self.config["lastVersionCheck"] ~= '' .. os.day("utc") then
        local success, newestVersion = scm:getNewestVersion()
        if success and newestVersion ~= self.config["currentVersion"] then
            self.config["updateAvailable"] = true
        end

        self.config["lastVersionCheck"] = os.day("utc") .. ''
        self:saveConfig()
    end
end

function scm:init()
    -- Create directories
    if not fs.exists(self.config["configDirectory"]) then
        fs.makeDir(self.config["configDirectory"])
    end
    if not fs.exists(self.config["libraryDirectory"]) then
        fs.makeDir(self.config["libraryDirectory"])
    end

    self:loadConfig()
    self:loadScripts()

    self:checkVersion()
end

---@param resetPosition boolean | nil
function scm:cli(resetPosition, args)
    if resetPosition ~= nil and resetPosition == true then
        term.setCursorPos(1, 7)
    end

    -- enable autocomplete
    self:prepareAutocomplete()
    updateAutocomplete()

    -- enable newline starting with `scm `
    if self.config["allowCLIPrefix"] then
        self.config["cliPrefix"] = true
        self:saveConfig()
    end

    -- some interface
    local _, cursorY = term.getCursorPos()
    if cursorY < 7 then cursorY = 7 end
    term.setCursorPos(1, cursorY)
    term.blit("                                ",
        "ffffffffffffffffffffffffffffffff",
        "44444444444444444444444444444444")
    term.setCursorPos(1, cursorY)
    term.scroll(1)
    term.blit(" SCM - Script Manager           ",
        "ffffffffffffffffffffffffffffffff",
        "44444444444444444444444444444444")
    term.setCursorPos(1, cursorY)
    term.scroll(1)
    term.blit(" Autocomplete enabled.          ",
        "77777777777777777777777777777777",
        "44444444444444444444444444444444")
    term.setCursorPos(1, cursorY)
    term.scroll(1)
    term.blit(" Type `scm help` to learn more. ",
        "77777777ffffffff7777777777777777",
        "44444444444444444444444444444444")
    term.setCursorPos(1, cursorY)
    term.scroll(1)
    if (self.config["updateAvailable"]) then
        term.blit(" Update available!              ",
            "7eeeeeeeeeeeeeeeee77777777777777",
            "44444444444444444444444444444444")
        term.setCursorPos(1, cursorY)
        term.scroll(1)
    end
    term.blit("                                ",
        "ffffffffffffffffffffffffffffffff",
        "44444444444444444444444444444444")
    term.setCursorPos(1, cursorY)
    term.scroll(2)

    if self.config["cliPrefix"] then
        shell.run(read(nil, nil, shell.complete, "scm "))
    end
end

---@param args table
function scm:handleArguments(args)
    if #args == 0 then
        self:cli(false, args)
        return
    end

    if args[1] and self.commands[args[1]] then
        self.commands[args[1]]["func"](args)
        if self.config["cliPrefix"] then
            shell.run(read(nil, nil, shell.complete, "scm "))
        end
    end
end

scm:init()
scm:handleArguments({ ... })
return scm
