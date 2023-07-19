---@class SCMAutoComplete
local Autocomplete = {}

do
    ---@class SCMNet
    local Net
    ---@class SCMScriptManager
    local ScriptManager
    ---@class SCMUI
    local UI
    ---@class SCMConfig
    local config
    ---@type fun(...):SCMLog
    local log
    -- TODO: add autocomplete
    Autocomplete.commands = {
        ["require"] = {
            ---@param args table
            func = function(args)
                Net:download(args[2], "library", nil)
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
                Net:download(args[2], "program", nil)
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
                    ScriptManager:updateAllScripts()
                elseif args[3] then
                    ScriptManager:updateScript(args[2], args[3])
                elseif args[2] then
                    ScriptManager:updateScript(args[2], nil)
                else
                    Net:updateSCM()
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
                    ScriptManager:removeAllScripts()
                else
                    ScriptManager:removeScript(args[2])
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
                UI:listScripts()
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
                    config:updateConfig(args[2], args[3])
                elseif args[2] then
                    if config.getAll(config)[args[2]] ~= nil then
                        print(args[2], tostring(config.getAll(config)[args[2]]))
                    end
                else
                    print("You can currently configure the following variables:")
                    for cname, cvalue in pairs(config.getAll(config)) do
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
                Autocomplete:refreshAutocomplete()
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
                    if Autocomplete.commands[args[2]] then
                        textutils.pagedPrint(args[2] .. "\n" .. Autocomplete.commands[args[2]]["description"])
                    end
                else
                    for k, v in pairs(Autocomplete.commands) do
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

    function Autocomplete:init(libs)
        log = function(...) libs["log"](libs.log, ...) end
        Net = libs.Net
        ScriptManager = libs.scriptManager
        UI = libs.UI
        config = libs.config
    end

    function Autocomplete:addScriptToAutoComplete(source)
        self.commands["update"]["args"] = self.commands["update"]["args"] or {}
        self.commands["remove"]["args"] = self.commands["remove"]["args"] or {}
        self.commands["update"]["args"][source.name] = {}
        self.commands["remove"]["args"][source.name] = {}
    end

    function Autocomplete:prepareAutocomplete()
        -- prepare update and remove
        ScriptManager:loadScripts()
        local installedScripts = {}
        for i = 1, #ScriptManager.scripts, 1 do
            installedScripts[ScriptManager.scripts[i].name] = {}
        end
        installedScripts["all"] = {}

        self.commands["update"]["args"] = installedScripts
        self.commands["remove"]["args"] = installedScripts

        -- prepare add and require
        Net:loadRepoScripts()

        -- prepare config
        local availableConfigs = {}

        for k, _ in pairs(config.getAll(config)) do
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

    function Autocomplete:refreshRepoScripts()
        log("Downloading program and library names from GitHub...")
        local repoScripts = {}

        local programs = {}
        local libraries = {}

        local request = http.get(config.getAll(config)["apiGithubURL"]
            .. config.getAll(config)["user"]
            .. config.getAll(config)["apiGithubGetRepos"])
        if request then
            local response = request.readAll()
            request.close()

            local responseTable = textutils.unserializeJSON(response)

            local programSuffix = config.getAll(config)["programSuffix"]
            local librarySuffix = config.getAll(config)["librarySuffix"]

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
            log("Done")
        else
            log("Download failed")
        end

        self.commands["add"]["args"] = programs
        self.commands["require"]["args"] = libraries

        repoScripts["libraries"] = libraries
        repoScripts["programs"] = programs

        local file = fs.open(config.getAll(config)["configDirectory"]
            .. config.getAll(config)["repoScriptsFile"], "w")
        if file then
            file.write(textutils.serializeJSON(repoScripts))
            file.close()
        end
    end

    ---@param shell table
    ---@param index integer
    ---@param argument string
    ---@param previous table
    ---@return table | nil
    local function completionFunction(shell, index, argument, previous)
        local commands = {}
        for k, _ in pairs(Autocomplete.commands) do
            commands[k] = Autocomplete.commands[k]["args"] or {}
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

    function Autocomplete:updateAutocomplete()
        shell.setCompletionFunction("scm", completionFunction)
    end

    function Autocomplete:refreshAutocomplete()
        self:refreshRepoScripts()
        self:prepareAutocomplete()
        self:updateAutocomplete()
    end

    ---@param t table
    function Autocomplete:setProgramms(t)
        self.commands["add"]["args"] = t
    end

    
    ---@param t table
    function Autocomplete:setLibaries(t)
        self.commands["require"]["args"] = t
    end
end
return Autocomplete
