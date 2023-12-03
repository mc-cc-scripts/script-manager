

---@class SCMConfig
local Config = {}
SCM.Config = Config
do


    ---@class SCMConfigData
    Config.config = {
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
        ["cliPrefix"] = false,
        ["SCMFileNames"] = {
            ["Log"] = "Log",
            ["UI"] = "UI"
        }
    }

    ---@source: https://stackoverflow.com/a/2705804/10495683
    ---@param T table
    ---@return integer
    local function tablelength(T)
        local count = 0
        for _ in pairs(T) do count = count + 1 end
        return count
    end


    --- saves the config to the config file
    ---@param config SCMConfigData | nil
    function Config:saveConfig(config)
        config = config or self.config
        
        local file = fs.open(config["configDirectory"] .. config["configFile"], "w")
        if not file then
            os.execute("mkdir " .. config["configDirectory"])
            file = fs.open(config["configDirectory"] .. config["configFile"], "w")
        end
        file.write(textutils.serializeJSON(config))
        file.close()
    end

    --- loads the config from the config file
    ---@param config SCMConfigData | nil
    function Config:loadConfig(config)
        config = config or self.config
        local file = fs.open(config["configDirectory"] .. config["configFile"], "r")

        if not file then
            -- Create config file if it does not exist yet
            self:saveConfig(config)
        else
            -- Load config from file
            local temp = textutils.unserializeJSON(file.readAll()) or {}
            -- Check if loaded config size is equal to the default size,
            -- otherwise the config is corrupted and will be overwritten
            if tablelength(temp) == tablelength(self.config) then
                self.config = temp
            else
                self:saveConfig(config)
            end
            file.close()
        end
    end

    ---@param name string
    ---@param value string
    function Config:updateConfig(name, value)
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
                self:saveConfig(self.config)
            end
        else
            scm.log:log("You can currently configure the following variables:")
            for cname, cvalue in pairs(self.config) do
                scm.log:log(cname, tostring(cvalue))
            end
        end
    end

    function Config:getAll()
        return self.config
    end

    ---@param name string
    ---@param value any
    function Config:set(name, value)
        self.config[name] = value
    end
end
return Config
