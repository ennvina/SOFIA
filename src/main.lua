local AddonName, SOFIA = ...

SLASH_SOFIA1 = "/sofia"

SlashCmdList.SOFIA = function(msg, editBox)
    local color = "FFFFCDCD"
    if msg == "reset" then
        SOFIADB = nil -- reset to nothing
        SOFIA:LoadDB() -- because DB has nothing, loading will set it to default
        SOFIA:ApplySettings()
        print(WrapTextInColorCode(string.format("%s options have been reset.", AddonName), color))
    elseif msg == "show" then
        SOFIA:ShowWindow()
        print(WrapTextInColorCode(string.format("%s window shown. If you still don't see it, please try /sofia reset", AddonName), color))
    elseif msg == "hide" then
        SOFIA:HideWindow()
        print(WrapTextInColorCode(string.format("%s window hidden. To show it again, please enter /sofia show", AddonName), color))
    elseif msg == "toggle" then
        SOFIA:ToggleWindow()
        print(WrapTextInColorCode(string.format("%s window toggled.", AddonName), color))
    else
        print(WrapTextInColorCode("Usage: /sofia [command]", color))
        print(WrapTextInColorCode(
            "Commands:\n"..
            "show: show the window\n"..
            "hide: hide the window\n"..
            "reset: reset to default settings\n", color))
    end
end
