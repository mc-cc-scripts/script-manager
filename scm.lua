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


return scm
