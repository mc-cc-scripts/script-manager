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
    -- Local Settings
    ["rootDirectory"] = "",
    ["programDirectory"] = "",
    ["libraryDirectory"] = "libs/",
    ["configDirectory"] = "config/",
    ["configFile"] = "scm-config.json",
    ["scriptFile"] = "scm-scripts.json" -- will be saved in configDirectory as well
}
----------------

scm.scripts = {}
scm.commands = {
    ["add"] = {
        func = function (args)
            self:download(args[2], "library")
        end,
        description = [[
Adds a library with all its dependencies.
If only a name is given, it will try to download from the official GitHub repositories.
add <name>
add <name>@<pastebinCode>
add <URL>
        ]]
    },
    ["get"] = {
        func = function (args)
            self:download(args[2], "program")
        end,
        description = [[
Adds a program with all its dependencies.
If only a name is given, it will try to download from the official GitHub repositories.
get <name>
get <name>@<pastebinCode>
get <URL>
        ]]
    },
    ["update"] = {}, -- maybe add parameter for extra source
    ["remove"] = {
        func = function (args)
            if args[2] == "all" then
                self:removeAllScripts()
            else 
                self:removeScripts(args[2])
            end
        end,
        description = [[
remove <name>           Removes the given script
remove all              Removes all scripts
        ]]
    },
    ["list"] = {
        func = function (_)
            self:listScripts()
        end,
        description = [[
list                    Lists all installed scripts
        ]]
    },
    ["config"] = {
        func = function (args)
            self:updateConfig(args[2], args[3])
        end,
        description = [[
config                  Lists all available configurations
config <name> <value>   Updates the configuration
        ]]
    },
    ["help"] = {
        func = function (args)
            if args[2] then
                print (args[2], self.commands[args[2]]["description"])
            end
            for k, v in pairs(self.commands) do
                print(k, v.description)
            end
        end,
        description = [[
help                    Shows all available commands and their description
help <name>             Shows the description of the given command
        ]]
    }
}

function scm:splitNameCode (str)
    local separator = string.find(str, "@")
    
    if separator then
        local name = string.sub(str, 1, separator - 1)
        local code = string.sub(str, separator + 1)
        return name, code
    end

    return nil, nil
end

function scm:download (target, fileType)
    if target == nil then 
        --@TODO: Error handling
        return false
    end

    local sourceObject = {
        name = nil,
        source = target,
        type = fileType
    }

    -- Check for Pastebin
    local name, code = self:splitNameCode(target)
    if name and code then
        sourceObject.name = name
        return scm:addScript(self:downloadPastebin(sourceObject, code, self.config[fileType .. "Directory"]))
    end

    -- Check for URL
    local isURL = string.lower(string.sub(target, 0, 4)) == "http"
    if isURL then
        return scm:addScript(self:downloadURL(sourceObject, self.config[fileType .. "Directory"]))
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

    return scm:addScript(self:downloadGit(sourceObject, repository, self.config[fileType .. "Directory"]))
end

function scm:downloadGit (sourceObject, repository, targetDirectory)
    local url = self.config["rawURL"] .. 
                self.config["user"] .. "/" .. 
                repository .. "/" .. 
                self.config["branch"] .. "/" .. 
                sourceObject.name .. ".lua"

    sourceObject.source = url

    return self:downloadURL(sourceObject, targetDirectory)
end

function scm:downloadPastebin (sourceObject, code, targetDirectory)
    -- Only download if it does not already exist
    if not fs.exists(targetDirectory .. sourceObject.name) then
        shell.run("pastebin", "get", code, targetDirectory .. sourceObject.name)
        return sourceObject, true
    end

    -- File already exists, you should use update
    --@TODO: Add error message
    return nil, false
end

function scm:downloadURL (sourceObject, targetDirectory)
    if not sourceObject.name then
        sourceObject.name = self:getNameFromURL(sourceObject.source)
    end

    local request = http.get(sourceObject.source)

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

function scm:getNameFromURL (url)
    local name = url:match("[^/]+$")
    
    -- Remove file extension if name contains a dot
    if name:find("%.") then
        name = name:match("(.+)%..+$")
    end

    return name
end

function scm:addScript (sourceObject, success)
    if not success or not sourceObject then return false end

    table.insert(self.scripts, sourceObject)
    self:saveScripts()
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
    print ("name", "source", "type")
    print ("----------------------")
    for i = 1, #self.scripts, 1 do
        print (self.scripts[i].name, self.scripts[i].source, self.scripts[i].type)
    end
end

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
    end
end

function scm:removeAllScripts ()    
    for i = 1, #self.scripts, 1 do
        self:removeScript(self.scripts[i].name)
    end
end

-- source: https://stackoverflow.com/a/2705804/10495683
function tablelength (T)
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
        for name, value in pairs(self.config) do
            print (name, tostring(value))
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

function scm:handleArguments (args)
    self:commands[args[1]]["func"](args)
end

scm:init()
scm:handleArguments({...})
return scm
