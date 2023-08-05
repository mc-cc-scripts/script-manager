---@class SCM
SCM = {}
require('libs.scm.config')
require('libs.scm.net')
require('libs.scm.log')
require('libs.scm.scriptManager')
require('libs.scm.autocomplete')
require('libs.scm.ui')

function SCM:checkVersion()
    if not self.Config.config["updateAvailable"] and self.Config.config["lastVersionCheck"] ~= '' .. os.day("utc") then
        local success, newestVersion = self.Net:getNewestVersion()
        if success and newestVersion ~= self.Config.config["currentVersion"] then
            self.Config.config["updateAvailable"] = true
        end

        self.Config.config["lastVersionCheck"] = os.day("utc") .. ''
        self.Config:saveConfig()
    end
end

function SCM:init()
    if not fs.exists(self.Config.config["configDirectory"]) then
        fs.makeDir(self.Config.config["configDirectory"])
    end
    if not fs.exists(self.Config.config["libraryDirectory"]) then
        fs.makeDir(self.Config.config["libraryDirectory"])
    end

    self.Config:loadConfig()
    self.ScriptManager:loadScripts()

    self:checkVersion()
end

function SCM:load(...)
    return SCM.ScriptManager:load(...)
end

SCM:init()
SCM.Autocomplete:handleArguments({ ... })

return SCM
