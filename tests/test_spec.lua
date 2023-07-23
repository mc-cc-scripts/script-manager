--TODO:
--implement Test Suite
require("tests/testSuite")
require("tests.Suite.helperFunctions")

--#region assert Definitions

---@class are
---@field same function
---@field equal function
---@field equals function

---@class is
---@field truthy function
---@field falsy function
---@field not_true function
---@field not_false function

---@class has
---@field error function
---@field errors function

---@class assert
---@field are are
---@field is is
---@field are_not are
---@field is_not is
---@field has has
---@field has_no has
---@field True function
---@field False function
---@field has_error function
---@field is_true function
---@field equal function
assert = assert

--#endregion assert Definitions

local configTmp
local scriptTmp
local testScript
---@param scm SCM
local function saveConfig(scm)
    local config = scm.Config
    config:loadConfig()
    configTmp = table.copy(config:getAll())
end

---@param scm SCM
local function restoreConfig(scm)
    local config = scm.Config
    config:saveConfig(configTmp)
end

---@param scm SCM
local function saveScripts(scm)
    local scriptManager = scm.ScriptManager
    scriptManager:loadScripts()
    scriptTmp = table.copy(scriptManager.scripts)
end

---@param scm SCM
local function restoreScripts(scm)
    local scriptManager = scm.ScriptManager
    scriptManager.scripts = scriptTmp
    scriptManager:saveScripts()
end
---@param func function
---@param ... any
local function runTests(func, ...)
    ---@class SCM
    local scm = require("../scm")
    saveConfig(scm)
    saveScripts(scm)
    scm.Config:set("libraryDirectory", "tmpLibs/");
    scm.Config:set("programDirectory", "tmpPrograms/");
    local success, err = pcall(func, scm, ...)
    restoreConfig(scm)
    restoreScripts(scm)
    assert.is.falsy(err)
    os.execute("rm -rf tmpLibs")

    if not success then
        error('Error Message was empty')
    end
end

describe("Testing everything about SCM:", function()
    describe("Require all SCM Modules", function()
        it("should be able to require all modules", function()
            local scm = require("../scm")
            assert.is_true('table' == type(scm))
            assert.is.truthy(scm.Autocomplete)
            assert.is.truthy(scm.Config)
            assert.is.truthy(scm.Net)
            assert.is.truthy(scm.UI)
            assert.is.truthy(scm.ScriptManager)
            assert.is.truthy(scm.Log)
            print("Require of all modules test passed")
        end)
    end)
    describe("Config ->", function()
        it("Change SCM Config", function()
            runTests(function(scm)
                local config = scm.Config
                -- Set Config
                config:set("verbose", false)
                assert.is.truthy(config:getAll()["verbose"] == false)
                config:set("verbose", "Wrong")
                config:saveConfig()
                config:set("verbose", false)

                -- Check if the file saved correctly
                config:loadConfig()
                assert.equal("Wrong", config:getAll()["verbose"])
                config:set("verbose", true)
                assert.is.truthy(config:getAll()["verbose"] == true)
                print("Config test passed")
            end)
        end)
    end)
    describe("ScriptManager ->", function()
        it("Load Empty", function()
            runTests(
                function(scm)
                    scm.Config:set("libraryDirectory", "tmpLibs");
                    local scriptManager = scm.ScriptManager
                    scriptManager:loadScripts()
                    local scripts = scriptManager.scripts
                    assert.is.truthy(scripts)
                    assert.is.truthy(type(scripts) == "table")

                    print("1. ScriptManager test passed")
                end
            )
        end)
        it("Load Local", function()
            runTests(
                function(scm)
                    local scriptManager = scm.ScriptManager
                    local file = io.open("testFile.lua", "w")
                    if not file then
                        error('file not create')
                    end
                    file:write("local t = {test = true} \n return t")
                    file:close()
                    local tFile = scm:load("testFile")
                    assert.is.truthy(tFile)
                    assert.is.truthy(tFile.test)
                    os.remove("testFile.lua")
                    print("2. ScriptManager test passed")
                end
            )
        end)
        describe("Load Remote", function ()
            it("Get TestLib", function()
                runTests(
                    ---@param scm SCM
                    function(scm)
                        local testScript = scm:load("scmTest")
                        local scriptManager = scm.ScriptManager
                        -- what should be there:
                        -- local tScript = {
                        --     name = "testLibrary",
                        --     type = "remote",
                        --     source = {
                        --         ["github"] = "https://raw.githubusercontent.com/mc-cc-scripts/script-manager/master/testLibrary.lua"
                        --     }
                        -- }
                        -- scriptManager:addScript(tScript, true)
                        assert.is.truthy(testScript)
                        assert.is.truthy(testScript.test)
                        print("3. ScriptManager test passed")
                    end
                )
            end)
            
        end)
    end)
end)
