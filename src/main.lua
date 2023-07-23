local AddonName, SOFIA = ...

SLASH_SOFIA1 = "/sofia"

local function printColor(color, pattern, ...)
    print(WrapTextInColorCode(string.format(pattern, unpack{...}), color))
end

local function printChat(pattern, ...)
    local color = SOFIA:GetColorHex('chat')
    printColor(color, pattern, ...)
end

function SOFIA.Error(self, pattern, ...)
    local color = "FFB20000" -- Do not fetch from SOFIA:GetColorHex to minimize calls during errors
    printColor(color, '[%s] '..pattern, AddonName, ...)
end

function SOFIA.Debug(self, pattern, ...)
    if not self.db or not self.db.debug then return end

    local color = "FFB20000" -- Do not fetch from SOFIA:GetColorHex to minimize calls during debug
    printColor(color, '[%s] '..pattern, AddonName, ...)
end

SlashCmdList.SOFIA = function(msg, editBox)
    if msg == "reset" then
        SOFIADB = nil -- reset to nothing
        SOFIA:LoadDB() -- because DB has nothing, loading will set it to default
        SOFIA:ApplySettings()
        printChat("%s options and data have been reset.", AddonName)
    elseif msg == "show" then
        SOFIA:ShowWindow()
        printChat("%s window shown. If you still don't see it, please try /sofia reset", AddonName)
    elseif msg == "hide" then
        SOFIA:HideWindow()
        printChat("%s window hidden. To show it again, please enter /sofia show", AddonName)
    elseif msg == "toggle" then
        SOFIA:ToggleWindow()
        printChat("%s window toggled.", AddonName)
    elseif msg == "debug" then
        SOFIA:ToggleDebug()
    else
        printChat("Usage: /sofia [command]")
        printChat(
            "Commands:\n"..
            "show: show the window\n"..
            "hide: hide the window\n"..
            "reset: reset to default settings and wipe all data\n")
    end
end

function SOFIA.ToggleDebug(self)
    local color = SOFIA:GetColorHex('chat')
    if not self.db then
        printChat("%s DB not initialized yet.", AddonName)
    end
    if self.db.debug then
        self.db.debug = false
        printChat("%s debug disabled.", AddonName, 123)
    else
        self.db.debug = true
        printChat("%s debug enabled.", AddonName, 345)
    end
end
