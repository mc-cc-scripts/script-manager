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
    -- Local Settings
    ["installScript"] = "1kKZ8zTS",
    ["rootDirectory"] = "",
    ["programDirectory"] = "progs/",
    ["libraryDirectory"] = "rom/modules/libs/",
    ["configDirectory"] = "config/",
    ["configFile"] = "scm-config.json",
    ["scriptFile"] = "scm-scripts.json" -- will be saved in configDirectory as well
}
----------------


scm.scripts = {}
scm.commands = {
    ["add"] = {
        ---@param args table
        func = function (args)
            scm:download(args[2], "library", nil)
        end,
        description = [[
Adds a library with all its dependencies.
If only a name is given, it will try to download from the official GitHub repositories.
$ add <name>
$ add <name>@<pastebinCode>
$ add <URL>
        ]]
    },
    ["get"] = {
        ---@param args table
        func = function (args)
            scm:download(args[2], "program", nil)
        end,
        description = [[
Adds a program with all its dependencies.
If only a name is given, it will try to download from the official GitHub repositories.
$ get <name>
$ get <name>@<pastebinCode>
$ get <URL>
        ]]
    },
    ["update"] = {
        ---@param args table
        func = function (args)
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
        func = function (args)
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
        func = function (_)
            scm:listScripts()
        end,
        description = [[
$ list
Lists all installed scripts
        ]]
    },
    ["config"] = {
        ---@param args table
        func = function (args)
            scm:updateConfig(args[2], args[3])
        end,
        description = [[
$ config
Lists all available configurations
$ config <name> <value>
Updates the configuration
        ]]
    },
    ["help"] = {
        ---@param args table
        func = function (args)
            if args[2] then
                textutils.pagedPrint(args[2] .. "\n" .. scm.commands[args[2]]["description"])
            end
            for k, v in pairs(scm.commands) do
                textutils.pagedPrint(k .. "\n" .. v.description)
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

---@param str string
---@return string | nil
---@return string | nil
function scm:splitNameCode (str)
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
function scm:download (target, fileType, updateObj)
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

    -- Check for URL
    local isURL = string.lower(string.sub(target, 0, 4)) == "http"
    if isURL then
        return scm:addScript(self:downloadURL(sourceObject, self.config[fileType .. "Directory"], updateObj))
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
function scm:downloadGit (sourceObject, repository, targetDirectory, updateObj)
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
            local file = fs.open(targetDirectory .. sourceObject.name .. self.config[sourceObject.type .. "Suffix"] .. "/" .. self.config["infoFile"], "w")
            file.write(content)
            file.close()

            local filePaths = {}
            file = fs.open(targetDirectory .. sourceObject.name .. self.config[sourceObject.type .. "Suffix"] .. "/" .. self.config["infoFile"], "r")
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
                        local tmpFile = fs.open(targetDirectory .. sourceObject.name .. self.config[sourceObject.type .. "Suffix"] .. "/" .. filePaths[i], "w")
                        tmpFile.write(tmpContent)
                        tmpFile.close()
                    else
                        success = false
                    end
                else
                    success = false
                end
                tmpRequest.close()

                if not success then
                    return nil, false
                end
            end

            -- create a link that calls the file within the program directory
            if sourceObject.type == "program" then
                local progamLink = fs.open(sourceObject.name, "w")
                progamLink.write("shell.execute(\"" .. targetDirectory .. sourceObject.name .. self.config[sourceObject.type .. "Suffix"] .. "/" .. sourceObject.name .. ".lua" .. "\", ...)")
                progamLink.close()
            elseif sourceObject.type == "library" then
                local libraryLink = fs.open(targetDirectory .. sourceObject.name .. ".lua", "w")
                
                local tmpName = sourceObject.name
                if tmpName:find("%.") then
                    tmpName = tmpName:match("(.+)%..+$")
                end

                libraryLink.write("return require(\"" .. tmpName .. self.config[sourceObject.type .. "Suffix"] .. "/" .. tmpName .. "\")")
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
function scm:downloadPastebin (sourceObject, code, targetDirectory, updateObj)
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

    shell.run("pastebin", "get", code, targetDirectory .. sourceObject.name)
    return sourceObject, true
end

---@param sourceObject table
---@param targetDirectory string
---@param updateObj table | nil
---@return table | nil
---@return boolean
function scm:downloadURL (sourceObject, targetDirectory, updateObj)
    local sourceName = "default" or updateObj.sourceName
    sourceObject.name = sourceObject.name or updateObj.name

    if not sourceObject.name then
        sourceObject.name = self:getNameFromURL(sourceObject.source[sourceName])
    end

    local request = http.get(sourceObject.source[sourceName])

    if request then
        local content = request.readAll()
        request.close()

        if content then
            local file = fs.open(self.config["rootDirectory"] .. targetDirectory .. sourceObject.name, "w")
            file.write(content)
            file.close()
            return sourceObject, true
        end
    end

    return nil, false
end

---@param url string
---@return string
function scm:getNameFromURL (url)
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
function scm:addScript (sourceObject, success)
    if not success or not sourceObject then return false end

    -- Check if script already exists, then update
    for i = 1, #self.scripts, 1 do
        if self.scripts[i].name == sourceObject.name and self.scripts[i].type == sourceObject.type then
            if self.scripts[i].source[sourceObject.sourceName] then
                self.scripts[i].source[sourceObject.sourceName] = sourceObject.source[sourceObject.sourceName]
                self:saveScripts()
                
                return true
            end
        end
    end

    table.insert(self.scripts, sourceObject)
    self:saveScripts()

    return true
end

function scm:saveScripts ()
    local file = fs.open(self.config["configDirectory"] .. self.config["scriptFile"], "w")
    file.write(textutils.serializeJSON(self.scripts))
    file.close()
end

function scm:loadScripts ()
    local file = fs.open(self.config["configDirectory"] .. self.config["scriptFile"], "r")

    if not file then
        self:saveScripts()
    else
        self.scripts = textutils.unserializeJSON(file.readAll()) or {}
        file.close()
    end
end

function scm:listScripts ()
    print ("name", "type")
    print ("----------------------")
    for i = 1, #self.scripts, 1 do
        print (self.scripts[i].name, self.scripts[i].type)
    end
end

---@param name string
function scm:removeScript (name)
    local o = {}
    local scriptType = nil

    for i = 1, #self.scripts, 1 do
        if self.scripts[i].name ~= name then
            table.insert(o, self.scripts[i])
        else 
            scriptType = self.scripts[i].type
        end
    end

    self.scripts = o
    self:saveScripts()

    if scriptType and fs.exists(self.config[scriptType .. "Directory"] .. name) then
        fs.delete(self.config[scriptType .. "Directory"] .. name)
        if scriptType == "program" then
            fs.delete(name)
        elseif scriptType == "library" then
            fs.delete(self.config[scriptType .. "Directory"] .. name .. self.config[scriptType .. "Suffix"])
        end
    end
end

function scm:removeAllScripts ()
    for i = 1, #self.scripts, 1 do
        self:removeScript(self.scripts[i].name)
    end
end

---@param name string
---@param sourceName string
function scm:updateScript (name, sourceName)
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
        self:download(updateObj.source[sourceName], updateObj.type, updateObj)
    end
end

function scm:updateAllScripts ()
    for i = 1, #self.scripts, 1 do
        self:updateScript(self.scripts[i].name, "default")
    end
end

function scm:updateSCM ()
    shell.run("pastebin", "run", self.config.installScript)
end

---@source: https://stackoverflow.com/a/2705804/10495683
---@param T table
---@return integer
local function tablelength (T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function scm:saveConfig ()
    local file = fs.open(self.config["configDirectory"] .. self.config["configFile"], "w")
    file.write(textutils.serializeJSON(self.config))
    file.close()
end

function scm:loadConfig ()
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
        else self:saveConfig() end
        file.close()
    end
end

---@param name string
---@param value string
function scm:updateConfig (name, value)
    local writeConfig = true

    if name and value then
        if self.config[name] ~= nil then
            if type(self.config[name]) == type(true) then
                -- Check for boolean
                if value == "true" then self.config[name] = true
                elseif value == "false" then self.config[name] = false end
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
        print ("You can currently configure the following variables:")
        for cname, cvalue in pairs(self.config) do
            print (cname, tostring(cvalue))
        end
    end
end

function scm:init ()
    -- Create directories
    if not fs.exists(self.config["configDirectory"]) then
        fs.makeDir(self.config["configDirectory"])
    end
    if not fs.exists(self.config["libraryDirectory"]) then
        fs.makeDir(self.config["libraryDirectory"])
    end

    self:loadConfig()
    self:loadScripts()
end

---@param args table
function scm:handleArguments (args)
    if args[1] then
        self.commands[args[1]]["func"](args)
    end
end

scm:init()
scm:handleArguments({...})
return scm
