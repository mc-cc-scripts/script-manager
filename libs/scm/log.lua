---@class SCMLog
local Log = {}
SCM.Log = Log
do
    local config = {}
    function Log:init(lib)
        config = lib["config"].config
    end

    function Log:log(message)
        local datetime = ""
        if config["logDate"] then datetime = "" .. os.date("[%Y-%m-%d %H:%M:%S] ") end
        if config["verbose"] then print(config["printPrefix"] .. message) end
    
        if config["writeLogFile"] then
            local file = fs.open(config["logFilePath"], "a")
            file.write(datetime .. message .. "\n")
            file.close()
        end
    end
end


return Log