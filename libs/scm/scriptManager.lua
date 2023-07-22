--- done
---@class SCMScriptManager
local ScriptManager = { scripts = {} }
SCM.ScriptManager = ScriptManager
do
    local config = function()
        return SCM.Config:getAll()
    end
    local log = function(...) SCM.Log:log(...) end

    ---loads the scripts
    function ScriptManager:loadScripts()
        local file = fs.open(config()["configDirectory"] .. config()["scriptFile"], "r")
        if not file then
            self:saveScripts()
        else
            self.scripts = textutils.unserialiseJSON(file.readAll() or {})
            file.close()
        end
    end

    ---loads all scripts
    function ScriptManager:saveScripts()
        local file = fs.open(config()["configDirectory"] .. config()["scriptFile"], "w")
        file.write(textutils.serializeJSON(self.scripts))
        file.close()
    end

    ---adds a script to the script File
    ---@param sourceObject table | nil
    ---@param success boolean
    ---@return boolean
    function ScriptManager:addScript(sourceObject, success)
        if not success or not sourceObject then return false end
        log("Adding script" .. sourceObject.name .. "...")
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
            log("Script added: " .. sourceObject.name)
            table.insert(self.scripts, sourceObject)
        else
            log("Script already exists.")
            return false
        end

        self:saveScripts()

        SCM.Autocomplete:addScriptToAutoComplete(sourceObject)
        SCM.Autocomplete:prepareAutocomplete()
        SCM.Autocomplete:updateAutocomplete()

        return true
    end

    ---@param name string
    ---@param sourceName string | nil
    ---@return boolean
    function ScriptManager:updateScript(name, sourceName)
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
            SCM.Net:download(updateObj.source[sourceName], updateObj.type, updateObj)
            return true
        end

        return false
    end

    --- updates all scripts
    function ScriptManager:updateAllScripts()
        for i = 1, #self.scripts, 1 do
            self:updateScript(self.scripts[i].name, "default")
        end
    end

    --- removes a script
    ---@param name string
    ---@param keepScriptConfig boolean | nil
    function ScriptManager:removeScript(name, keepScriptConfig)
        log("Removing script: " .. name)
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
        if scriptType and fs.exists(config()[scriptType .. "Directory"] .. name .. ".lua") then
            fs.delete(config()[scriptType .. "Directory"] .. name .. config()[scriptType .. "Suffix"])
            if scriptType == "library" then
                fs.delete(config()[scriptType .. "Directory"] .. name .. ".lua")
            end
        end

        if scriptType == "program" then
            fs.delete(name)
        end

        -- update autocomplete
        SCM.Autocomplete:prepareAutocomplete()
        SCM.Autocomplete:updateAutocomplete()
    end
    
    --- removes all scripts
    function ScriptManager:removeAllScripts()
        local tmpScripts = {}
        for i = 1, #self.scripts, 1 do
            table.insert(tmpScripts, self.scripts[i].name)
        end

        for i = 1, #tmpScripts, 1 do
            self:removeScript(tmpScripts[i])
        end
    end

---@param name string
---@param localPath string | nil | unknown
function ScriptManager:checkRequirements(name, localPath)
    log("Checking requirements of " .. (localPath or name) .. "...")
    local file
    if localPath then
        file = fs.open(localPath, "r")
        if not file then
            file = fs.open('./' .. localPath .. ".lua", "r")
        end
    elseif fs.exists("./" .. config()["libraryDirectory"] .. name .. config()["librarySuffix"] .. "/" .. name .. ".lua") then
        file = fs.open("./" .. config()["libraryDirectory"]
            .. name .. config()["librarySuffix"]
            .. "/" .. name .. ".lua", "r")
    else
        file = fs.open("./" .. config()["libraryDirectory"] .. name .. ".lua", "r")
    end
    if not file then log('File ' .. name .. ' not found') end
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
        local n = requires[i] --[[@as string]]
        local tmpName, tmpCode = self:splitNameCode(n)
        if tmpCode then n = tmpName--[[@as string]] end

        log("Trying to install " .. n .. "...")

        local scriptExists = false
        for j = 1, #self.scripts, 1 do
            if self.scripts[j].name == n then
                scriptExists = true
            end
        end

        if not scriptExists then
            if tmpCode then
                SCM.Net:download(tmpName .. "@" .. tmpCode, "library")
            else
                SCM.Net:download(n, "library")
            end
        else
            log(n .. " already exists.")
        end

        self:checkRequirements(n --[[@as string]])
    end
end

--- used when no script with the name was found online
--- searches locally for the script
---@param name string
---@return any | nil
local function fallbackRequire(name)
    log(name .. " not found online, try to find locally")
    --- if script does not exist
    local possiblePath = {
        name,
        config()["libraryDirectory"] .. name,
        config()["libraryDirectory"] .. name .. "/" .. name,
        config()["libraryDirectory"] .. name .. "/" .. "init.lua"
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
            ScriptManager:checkRequirements(name, path)
            return script
        end
    end
    log("Could not load " .. name)
    return nil
end

    ---@param name string
---@return any
function ScriptManager:load(name)
    log("Loading " .. name .. "...")
    local scriptExists = false
    for i = 1, #self.scripts, 1 do
        if self.scripts[i].name == name then
            scriptExists = true
        end
    end

    if not scriptExists then
        SCM.Net:download(name, "library")
    end

    scriptExists = false
    for i = 1, #self.scripts, 1 do
        if self.scripts[i].name == name then
            scriptExists = true
        end
    end

    if scriptExists then
        self:checkRequirements(name)
        local path = "./" .. config()["libraryDirectory"] .. name
        local script = require(path)
        log("Done")
        return script
    end

    return fallbackRequire(name)
end

---@param str string
---@return string | nil
---@return string | nil
function ScriptManager:splitNameCode(str)
    local separator = string.find(str, "@")

    if separator then
        local name = string.sub(str, 1, separator - 1)
        local code = string.sub(str, separator + 1)
        return name, code
    end

    return nil, nil
end

end

return ScriptManager
