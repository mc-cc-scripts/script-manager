---@class SCMUI
local UI = {}
SCM.UI = UI
do
    function UI:listScripts()
        local scripts = SCM.ScriptManager.scripts
        print("name", "type")
        print("----------------------")
        for i = 1, #scripts, 1 do
            print(scripts[i].name, scripts[i].type)
        end
    end

    ---@param resetPosition boolean | nil
    function UI:cli(resetPosition, args)
        if resetPosition ~= nil and resetPosition == true then
            term.setCursorPos(1, 7)
        end

        -- enable autocomplete
        SCM.Autocomplete:prepareAutocomplete()
        SCM.Autocomplete:updateAutocomplete()

        -- enable newline starting with `scm `
        if SCM.Config.config["allowCLIPrefix"] then
            SCM.Config.config["cliPrefix"] = true
            SCM.Config:saveConfig()
        end

        -- some interface
        local _, cursorY = term.getCursorPos()
        if cursorY < 7 then cursorY = 7 end
        term.setCursorPos(1, cursorY)
        term.blit("                                ", "ffffffffffffffffffffffffffffffff",
            "44444444444444444444444444444444")
        term.setCursorPos(1, cursorY)
        term.scroll(1)
        term.blit(" SCM - Script Manager           ", "ffffffffffffffffffffffffffffffff",
            "44444444444444444444444444444444")
        term.setCursorPos(1, cursorY)
        term.scroll(1)
        term.blit(" Autocomplete enabled.          ", "77777777777777777777777777777777",
            "44444444444444444444444444444444")
        term.setCursorPos(1, cursorY)
        term.scroll(1)
        term.blit(" Type `scm help` to learn more. ", "77777777ffffffff7777777777777777",
            "44444444444444444444444444444444")
        term.setCursorPos(1, cursorY)
        term.scroll(1)
        if (SCM.Config.config["updateAvailable"]) then
            term.blit(" Update available!              ", "7eeeeeeeeeeeeeeeee77777777777777",
                "44444444444444444444444444444444")
            term.setCursorPos(1, cursorY)
            term.scroll(1)
        end
        term.blit("                                ", "ffffffffffffffffffffffffffffffff",
            "44444444444444444444444444444444")
        term.setCursorPos(1, cursorY)
        term.scroll(2)

        if SCM.Config.config["cliPrefix"] then
            shell.run(read(nil, nil, shell.complete, "scm "))
        end
    end
end

return UI
