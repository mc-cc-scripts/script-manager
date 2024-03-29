---@class SCMNet
local Net = {}
SCM.Net = Net
do
    local configLib = SCM.Config
    local config = function()
        return SCM.Config:getAll()
    end
    local log = function(...) SCM.Log:log(...) end

    ---@param target string
    ---@param fileType string
    ---@param updateObj table | nil
    ---@return boolean
    function Net:download(target, fileType, updateObj)
        log("Downloading " .. fileType .. " " .. target .. "...")
        if target == nil then
            --@TODO: Error handling
            return false
        end
        local sourceObject = {
            name = nil,
            source = {
                ["default"] = target,
            },
            sourceName = "default",
            type = fileType
        }
        if updateObj then sourceObject.name = updateObj.name end

        -- Check for Pastebin
        local name, code = SCM.ScriptManager:splitNameCode(target)
        if name and code then
            sourceObject.name = name
            return SCM.ScriptManager:addScript(self:downloadPastebin(sourceObject, code,
                config()[fileType .. "Directory"],
                updateObj))
        end

        -- We assume it's Git
        -- The suffix is used to find the correct repository on GitHub
        local suffix
        if fileType == "library" then
            suffix = config()["librarySuffix"]
        else
            suffix = config()["programSuffix"]
        end
        local repository = target .. suffix
        sourceObject.name = target

        return SCM.ScriptManager:addScript(self:downloadGit(sourceObject, repository, config()[fileType .. "Directory"],
            updateObj))
    end

    ---@param sourceObject table
    ---@param code string
    ---@param targetDirectory string
    ---@param updateObj table | nil
    ---@return table | nil
    ---@return boolean
    function Net:downloadPastebin(sourceObject, code, targetDirectory, updateObj)
        -- Only download if it does not already exist, or if it should be updated
        if fs.exists(targetDirectory .. sourceObject.name) then
            if updateObj then
                if fs then
                    fs.delete(targetDirectory .. sourceObject.name)
                else
                    os.remove(targetDirectory .. sourceObject.name)
                    sourceObject = updateObj
                end
            else
                -- File already exists, you should use update
                return nil, false
            end
        end

        if updateObj then
            if fs then
                fs.delete(sourceObject.name)
            else
                os.remove(sourceObject.name)
            end
        end

        if sourceObject.type == "program" and code then
            shell.run("pastebin", "get", code, sourceObject.name .. ".lua")
        else
            shell.run("pastebin", "get", code, targetDirectory .. sourceObject.name .. ".lua")
        end

        return sourceObject, true
    end

    ---@param sourceObject table
    ---@param repository string
    ---@param targetDirectory string
    ---@param updateObj table | nil
    ---@return table | nil
    ---@return boolean
    function Net:downloadGit(sourceObject, repository, targetDirectory, updateObj)
        local baseUrl = config()["rawURL"] ..
            config()["user"] .. "/" ..
            repository .. "/" ..
            config()["branch"] .. "/"
        local filesUrl = baseUrl .. config()["infoFile"]

        local request = http.get(filesUrl)
        if request then
            local content = request.readAll()
            if content == '404: Not Found' then
                return nil, false
            end
            request.close()
            if content then
                local file = fs.open(targetDirectory .. sourceObject.name
                    .. config()[sourceObject.type .. "Suffix"]
                    .. "/" .. config()["infoFile"], "w")
                file.write(content)
                file.close()

                local filePaths = {}
                file = fs.open(targetDirectory .. sourceObject.name
                    .. config()[sourceObject.type .. "Suffix"]
                    .. "/" .. config()["infoFile"], "r")
                local line = file.readLine()
                while line do
                    filePaths[#filePaths + 1] = line
                    line = file.readLine()
                end
                file.close()
                for i = 1, #filePaths, 1 do
                    local success = true
                    local tmpRequest = http.get(baseUrl .. filePaths[i])
                    if tmpRequest then
                        local tmpContent = tmpRequest.readAll()
                        if tmpContent then
                            local tmpFile = fs.open(targetDirectory .. sourceObject.name
                                .. config()[sourceObject.type .. "Suffix"]
                                .. "/" .. filePaths[i], "w")
                            if not tmpFile then
                                os.execute("mkdir " .. targetDirectory .. sourceObject.name
                                    .. config()[sourceObject.type .. "Suffix"])
                                tmpFile = fs.open(targetDirectory .. sourceObject.name
                                    .. config()[sourceObject.type .. "Suffix"]
                                    .. "/" .. filePaths[i], "w")
                            end
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
                    local progamLink = fs.open(sourceObject.name .. ".lua", "w")
                    progamLink.write("shell.execute(\"" .. targetDirectory .. sourceObject.name ..
                        config()[sourceObject.type .. "Suffix"]
                        .. "/" .. sourceObject.name .. ".lua" .. "\", ...)")
                    progamLink.close()
                elseif sourceObject.type == "library" then
                    local libraryLink = fs.open(targetDirectory .. sourceObject.name .. ".lua", "w")
                    if not libraryLink then
                        os.execute("mkdir " .. targetDirectory)
                        libraryLink = fs.open(targetDirectory .. sourceObject.name .. ".lua", "w")
                    end

                    local tmpName = sourceObject.name
                    if tmpName:find("%.") then
                        tmpName = tmpName:match("(.+)%..+$")
                    end

                    libraryLink.write("return require(\"./" .. config()["libraryDirectory"]
                        .. tmpName .. config()[sourceObject.type .. "Suffix"]
                        .. "/" .. tmpName .. "\")")
                    libraryLink.close()
                end

                return sourceObject, true
            end
        end

        return nil, false
    end

    ---@param url string
    ---@return string
    function Net:getNameFromURL(url)
        -- Gets the filename + extension from a url (everything after last /)
        local name = url:match("[^/]+$")

        -- Remove file extension if name contains a dot
        if name:find("%.") then
            name = name:match("(.+)%..+$")
        end

        return name
    end

    function Net:getNewestVersion()
        local githubAPIgetTags = config()["apiGithubGetTags"]
        githubAPIgetTags = githubAPIgetTags:gsub("<USER>", config()["user"])
        githubAPIgetTags = githubAPIgetTags:gsub("<REPO>", config()["repository"])

        local request = http.get(githubAPIgetTags)

        if request then
            local content = request.readAll()
            request.close()
            local SCMTags = textutils.unserializeJSON(content)
            return true, SCMTags[1]["name"]
        else
            log("Request to GitHub API failed.")
            return false, "0.0.0"
        end
    end

    function Net:updateSCM()
        log("Updating SCM...")
        shell.run("pastebin", "run", config().installScript)
        local success, version = self:getNewestVersion()
        if success then
            configLib:set("currentVersion", version)
            configLib:set("updateAvailable", false)
            configLib:set("lastVersionCheck", os.day("utc"))
            configLib:saveConfig()
        end
    end

    function Net:loadRepoScripts()
        local file = fs.open(config()["configDirectory"] .. config()["repoScriptsFile"], "r")

        if not file then
            self:refreshRepoScripts()
        else
            local repoScripts = textutils.unserializeJSON(file.readAll()) or nil
            if repoScripts then
                SCM.Autocomplete:setPrograms(repoScripts["programs"])
                SCM.Autocomplete:setLibaries(repoScripts["libraries"])
            end

            file.close()
        end
    end

    function Net:refreshRepoScripts()
        log("Downloading program and library names from GitHub...")
        local repoScripts = {}

        local programs = {}
        local libraries = {}

        local request = http.get(config()["apiGithubURL"] .. config()["user"] .. config()["apiGithubGetRepos"])
        if request then
            local response = request.readAll()
            request.close()
            local responseTable = textutils.unserializeJSON(response)

            local programSuffix = config()["programSuffix"]
            local librarySuffix = config()["librarySuffix"]

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

        SCM.Autocomplete:setPrograms(programs)
        SCM.Autocomplete:setLibaries(libraries)

        repoScripts["libraries"] = libraries
        repoScripts["programs"] = programs

        local file = fs.open(config()["configDirectory"] .. config()["repoScriptsFile"], "w")
        if not file then
            os.execute("mkdir " .. config()["configDirectory"])
            file = fs.open(config()["configDirectory"] .. config()["repoScriptsFile"], "w")
        end
        if file then
            file.write("" .. textutils.serializeJSON(repoScripts))
            file.close()
        end
    end

    function Net:getNewestVersion()
        local githubAPIgetTags = config()["apiGithubGetTags"]
        githubAPIgetTags = githubAPIgetTags:gsub("<USER>", config()["user"])
        githubAPIgetTags = githubAPIgetTags:gsub("<REPO>", config()["repository"])

        local request = http.get(githubAPIgetTags)

        if request then
            local content = request.readAll()
            request.close()
            local scmTags = textutils.unserializeJSON(content)
            return true, scmTags[1]["name"]
        else
            log("Request to GitHub API failed.")
            return false, "0.0.0"
        end
    end
end

return Net
