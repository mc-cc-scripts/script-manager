-- implement Test Suite

local json = require("tests/Suite/json")
local https = require("socket.http")
local fs = require("tests/Suite/fs")
local textutils = {}
---@param t table
textutils.serializeJSON = function(t) return json.stringify(t) end

---@param s string
---@return table
textutils.unserializeJSON = function(s) return json.parse(s) end

_G.textutils = textutils

_G.http = {
    get = function(...)
        local t = https.request(...)
        if t == "404: Not Found" and printAllowed then
            print("404: Not Found for request: " .. tostring(...))
        end
        return
        {
            ["readAll"] = function() return t end,
            ["close"] = function() return end
        }
    end
}

_G.shell = {
    -- TODO: implement shell - CompleteFunction
    ["setCompletionFunction"] = function(...) return end,
    ["run"] = function (...) return end
}

_G.printAllowed = false

_G.fs = fs
