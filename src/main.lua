local AddonName, SOFIA = ...

SLASH_SOFIA1 = "/sofia"

local function printColor(color, pattern, ...)
    print(WrapTextInColorCode(string.format(pattern, unpack{...}), color))
end

SlashCmdList.SOFIA = function(msg, editBox)
    local color = "FFFFCDCD"
    if msg == "reset" then
        SOFIADB = nil -- reset to nothing
        SOFIA:LoadDB() -- because DB has nothing, loading will set it to default
        SOFIA:ApplySettings()
        printColor(color, "%s options and data have been reset.", AddonName)
    elseif msg == "show" then
        SOFIA:ShowWindow()
        printColor(color, "%s window shown. If you still don't see it, please try /sofia reset", AddonName)
    elseif msg == "hide" then
        SOFIA:HideWindow()
        printColor(color, "%s window hidden. To show it again, please enter /sofia show", AddonName)
    elseif msg == "toggle" then
        SOFIA:ToggleWindow()
        printColor(color, "%s window toggled.", AddonName)
    elseif msg == "debug" then
        SOFIA:ToggleDebug()
    else
        printColor(color, "Usage: /sofia [command]")
        printColor(color,
            "Commands:\n"..
            "show: show the window\n"..
            "hide: hide the window\n"..
            "reset: reset to default settings and wipe all data\n")
    end
end

function SOFIA.ToggleDebug(self)
    local color = "FFFFCDCD"
    if not self.db then
        printColor(color, "%s DB not initialized yet.", AddonName)
    end
    if self.db.debug then
        self.db.debug = false
        printColor(color, "%s debug disabled.", AddonName, 123)
    else
        self.db.debug = true
        printColor(color, "%s debug enabled.", AddonName, 345)
    end
end
