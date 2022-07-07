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
    ["configDirectory"] = "config",
    ["configFile"] = "scm-config.json"
}
----------------

scm.scripts = {}
scm.commands = {
    ["add"] = {
        func = function ()
            --@TODO: Function to add a library via Git, Pastebin or URL
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
    ["get"] = {},
    ["update"] = {},
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
    
    -- Check for Pastebin
    local separator = string.find(target, "@")
    if separator then
        local name = string.sub(target, 1, separator - 1)
        local code = string.sub(target, separator + 1)
        return self:downloadPastebin(name, code)
    end

    -- Check for URL
    local isURL = string.lower(string.sub(target, 0, 4)) == "http"
    if isURL then
        return self:downloadURL(target)
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

    return self:downloadGit(target, repository)
end

function scm:downloadGit (name, repository)
    --@TODO: Download a library or program from Git
    local URL = self.config["rawURL"] .. 
                self.config["user"] .. "/" .. 
                repository .. "/" .. 
                self.config["branch"] .. "/" .. 
                name .. ".lua"
    --@TODO: Return false on error, true on success
    return false
end

function scm:downloadPastebin (name, code)
    --@TODO: Download file from Pastebin

    --@TODO: Return false on error, true on success
    return false
end

function scm:downloadURL (url)
    --@TODO: Return false on error, true on success
    return false
end


return scm
