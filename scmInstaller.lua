-- Updates / Installs the Script Manager (scm) from GitHub
-- Run `pastebin run xxxxxx`
-- SCM: https://github.com/mc-cc-scripts/script-manager

local files = {
    'libs/scm/autocomplete.lua',
    'libs/scm/config.lua',
    'libs/scm/net.lua',
    'libs/scm/scriptManager.lua',
    'libs/scm/ui.lua',
    'libs/scm.lua',
    'scm.lua',
}

local function installFiles()
    for _, script in ipairs(files) do
        http.get('https://raw.githubusercontent.com/mc-cc-scripts/script-manager/master/' .. script, nil, function(_, data)
            local file = fs.open(script, 'w')
            file.write(data)
            file.close()
        end)
    end
end