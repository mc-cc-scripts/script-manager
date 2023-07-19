---@class SCMConfig
local Config = require('libs.scm.config')
---@class SCMNet
local Net = require('computer.1.libs.scm.net')
---@class SCMScriptManager
local ScriptManager = require('libs.scm.scriptManager')
---@class SCMAutocomplete
local Autocomplete = require('libs.scm.autocomplete')
---@class SCMUI
local UI = require('libs.scm.ui')

---@class SCM
local SCM = {}
    ---@class SCMLibraries
    SCM.libraries = {
        config = Config,
        Net = Net,
        scriptManager = ScriptManager,
        autocomplete = Autocomplete,
        UI = UI,
    }

    function SCM:init()
        for _, lib in ipairs(SCM.libraries) do
            pcall(lib.init, lib)
        end
    end

    function SCM:load(name)
        return ScriptManager:load(name)
    end

    function SCM:loadScript(name)
        return ScriptManager:loadScript(name)
    end

    
return SCM