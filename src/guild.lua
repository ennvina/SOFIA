local AddonName, SOFIA = ...

-- GetGuildRosterInfo() is available with new data
-- This function is triggered by the "GUILD_ROSTER_UPDATE" event
local function UpdateAllGuild()
    if not IsInGuild() then return end -- Very unlikely, may happen if quitting guild during update?

    local realm = GetRealmName() or ""
    local guild = select(1, GetGuildInfo("player")) or ""
    local nbGuildmates = GetNumGuildMembers() or 0

    if realm == "" or guild == "" or nbGuildmates == 0 then
        -- Wrong init, try again later
        SOFIA:Debug("Cannot update guild status right now, will try again in a few seconds.")
        return
    end

    local guildmates = {} -- Gather GUIDs of guildmates currently in the guild
    for i=1, nbGuildmates do
        local name, _, _, level, _, _, _, _, _, _, class, _, _, _, _, _, guid = GetGuildRosterInfo(i)
        name = select(1,strsplit("-", name))
        guildmates[guid] = true
        local isNew, whatChanged = SOFIA:SetPlayerInfo(guid, realm, name, class, guild, level)
        if whatChanged.guild then
            SOFIA:Debug("%s joined guild '%s'.", name, guild)
        end
    end

    -- Check who left guild
    local leavers = {}
    for guid, player in pairs(SOFIA:GetRoster(realm, guild)) do
        if not guildmates[guid] then
            SOFIA:Debug("%s left guild '%s'.", player.name, guild)
            table.insert(leavers, player)
        end
    end
    for _, player in ipairs(leavers) do
        -- Put the player in the 'guildless' guild by default
        -- Maybe we'll cross the player again someday and the guild will be updated
        player.guild = ""
        SOFIA:RelocatePlayer(player, realm, guild, realm, "")
    end
end

local guildTimerFrame = CreateFrame("Frame", AddonName.."_GuildTimer")

function SOFIA:StartGuildTimer()
    guildTimerFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
    guildTimerFrame:SetScript("OnEvent", UpdateAllGuild)

    -- Request guild info on a regular basis
    -- C_GuildInfo.GuildRoster sends a request to the server to refresh guild information
    -- Once information is available, the "GUILD_ROSTER_UPDATE" event is fired
    -- Please note, guild info is not guaranteed to be really available even after the event
    -- The request is ignored if done more often than every 10 secs, hence the 11 secs value
    C_Timer.NewTicker(11, function() C_GuildInfo.GuildRoster() end)

    -- We'd like to request immediately at start
    -- But there is a very little chance that guild info would be available this early
    -- Even after the 11 secs delay from above, the first fetch is not always good
--    C_GuildInfo.GuildRoster()
end
