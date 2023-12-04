---@class Autocomplete
local Autocomplete = {}
SCM.Autocomplete = Autocomplete

do
    local log = function(...) SCM.Log:log(...) end
    Autocomplete.commands = {
        ["require"] = {
            ---@param args table
            func = function(args)
                SCM.Net:download(args[2], "library", nil)
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
                SCM.Net:download(args[2], "program", nil)
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
                    SCM.ScriptManager:updateAllScripts()
                elseif args[3] then
                    SCM.ScriptManager:updateScript(args[2], args[3])
                elseif args[2] then
                    SCM.ScriptManager:updateScript(args[2], nil)
                else
                    SCM.Net:updateSCM()
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
                    SCM.ScriptManager:removeAllScripts()
                else
                    SCM.ScriptManager:removeScript(args[2])
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
                SCM.UI:listScripts()
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
                    SCM.Config:updateConfig(args[2], args[3])
                elseif args[2] then
                    if SCM.Config.getAll(SCM.Config)[args[2]] ~= nil then
                        print(args[2], tostring(SCM.Config.getAll(SCM.Config)[args[2]]))
                    end
                else
                    print("You can currently configure the following variables:")
                    for cname, cvalue in pairs(SCM.Config.getAll(SCM.Config)) do
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
                SCM.Autocomplete:refreshAutocomplete()
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
                    if SCM.Autocomplete.commands[args[2]] then
                        textutils.pagedPrint(args[2] .. "\n" .. SCM.Autocomplete.commands[args[2]]["description"])
                    end
                else
                    for k, v in pairs(SCM.Autocomplete.commands) do
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

    function Autocomplete:addScriptToAutoComplete(source)
        self.commands["update"]["args"] = self.commands["update"]["args"] or {}
        self.commands["remove"]["args"] = self.commands["remove"]["args"] or {}
        self.commands["update"]["args"][source.name] = {}
        self.commands["remove"]["args"][source.name] = {}
    end

    function Autocomplete:prepareAutocomplete()
        -- prepare update and remove
        SCM.ScriptManager:loadScripts()
        local installedScripts = {}
        for i = 1, #SCM.ScriptManager.scripts, 1 do
            installedScripts[SCM.ScriptManager.scripts[i].name] = {}
        end
        installedScripts["all"] = {}

        self.commands["update"]["args"] = installedScripts
        self.commands["remove"]["args"] = installedScripts

        -- prepare add and require
        SCM.Net:loadRepoScripts()

        -- prepare config
        local availableConfigs = {}

        for k, _ in pairs(SCM.Config:getAll()) do
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

        local request = http.get(SCM.Config.getAll(SCM.Config)["apiGithubURL"]
            .. SCM.Config.getAll(SCM.Config)["user"]
            .. SCM.Config.getAll(SCM.Config)["apiGithubGetRepos"])
        if request then
            local response = request.readAll()
            request.close()

            local responseTable = textutils.unserializeJSON(response)

            local programSuffix = SCM.Config.getAll(SCM.Config)["programSuffix"]
            local librarySuffix = SCM.Config.getAll(SCM.Config)["librarySuffix"]

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
        else
            log("Download failed")
        end

        self.commands["add"]["args"] = programs
        self.commands["require"]["args"] = libraries

        repoScripts["libraries"] = libraries
        repoScripts["programs"] = programs

        local file = fs.open(SCM.Config.getAll(SCM.Config)["configDirectory"]
            .. SCM.Config.getAll(SCM.Config)["repoScriptsFile"], "w")
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
        shell.setCompletionFunction("scm.lua", completionFunction)
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

    function Autocomplete:handleArguments(args)
        if #args == 0 then
            SCM.UI:cli(false, args)
            return
        end

        if args[1] and self.commands[args[1]] then
            self.commands[args[1]]["func"](args)
            if SCM.Config.config["cliPrefix"] then
                shell.run(read(nil, nil, shell.complete, "scm "))
            end
        end
    end
end
