local AddonName, SOFIA = ...

SLASH_SOFIA1 = "/sofia"

local function printColor(color, pattern, ...)
    local addonColor = SOFIA:GetColorHex('darkRed')
    print(string.format('|c%s%s|r: ', addonColor, AddonName)..WrapTextInColorCode(string.format(pattern, unpack{...}), color))
end

local function printChat(pattern, ...)
    local color = SOFIA:GetColorHex('chat')
    printColor(color, pattern, ...)
end

function SOFIA:Error(pattern, ...)
    local hcColor = "FFB20000" -- Do not fetch from SOFIA:GetColorHex to minimize calls during errors
    print(string.format('|c%s%s|r: '..pattern, hcColor, AddonName, unpack{...}))
end

function SOFIA:Debug(pattern, ...)
    if not self.db or not self.db.debug then return end

    local hcColor = "FFB20000" -- Do not fetch from SOFIA:GetColorHex to minimize calls during debug
    print(string.format('|c%s%s|r: '..pattern, hcColor, AddonName, unpack{...}))
end

SlashCmdList.SOFIA = function(msg, editBox)
    if msg == "reset" then
        SOFIA.db.window = SOFIA.defaults.window
        SOFIA:ApplySettings()
        printChat("Options have been reset.")
    elseif msg == "delete" then
        SOFIA.db.roster = SOFIA.defaults.roster
        if SOFIA.window and SOFIA.window:IsShown() then
            SOFIA:SetTagPoolPlayers({})
        end
        printChat("All data have been wiped.")
    elseif msg == "show" then
        SOFIA:ShowWindow()
        printChat("Window shown. If you still don't see it, please try /sofia reset")
    elseif msg == "hide" then
        SOFIA:HideWindow()
        printChat("Window hidden. To show it again, please enter /sofia show")
    elseif msg == "toggle" then
        SOFIA:ToggleWindow()
        printChat("Window toggled.")
    elseif msg == "debug" then
        SOFIA:ToggleDebug()
    else
        printChat("Usage: /sofia [command]")
        printChat("Commands:"..
        "\n".."show: show the window"..
        "\n".."hide: hide the window"..
        "\n".."reset: reset to default settings"..
        "\n".."delete: wipe all roster data on all realms")
    end
end

function SOFIA:ToggleDebug()
    local color = SOFIA:GetColorHex('chat')
    if not self.db then
        printChat("DB not initialized yet.")
    end
    if self.db.debug then
        self.db.debug = false
        printChat("Debug disabled.")
    else
        self.db.debug = true
        printChat("Debug enabled.")
    end
end
