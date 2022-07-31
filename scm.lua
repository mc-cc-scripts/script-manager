local args = {...}

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
        func = function ()
            self:download(args[2], "library")
        end,
        desc = [[
Adds a library with all its dependencies.
If only a name is given, it will try to download from the official GitHub repositories.
add <name>
add <name>@<pastebinCode>
add <URL>
        ]]
    },
    ["get"] = {
        func = function ()
            self:download(args[2], "program")
        end,
        desc = [[
Adds a program with all its dependencies.
If only a name is given, it will try to download from the official GitHub repositories.
get <name>
get <name>@<pastebinCode>
get <URL>
        ]]
    },
    ["update"] = {}, -- maybe add parameter for extra source
    ["remove"] = {},
    ["list"] = {},
    ["config"] = {},
    ["help"] = {}
}



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
    local separator = string.find(target, "@")
    if separator then
        local name = string.sub(target, 1, separator - 1)
        local code = string.sub(target, separator + 1)
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
    local name = url:match( "[^/]+$" )
    
    -- remove file extension if name contains a dot
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

function scm:init ()
    if not fs.exists(self.config["configDirectory"]) then
        fs.makeDir(self.config["configDirectory"])
    end

    --@TODO: Load config
    scm:loadScripts()
end

scm:init()
return scm
