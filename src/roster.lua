local AddonName, SOFIA = ...

-- Cache frequently called functions
local GetServerTime = GetServerTime

-- List of players; will be synchronized with db during ApplyRosterSettings
local roster = {}

local function CreatePlayer(guid, realm, name, class, guild, level, progress, dead)
    local time = GetServerTime()

    return {
        -- Intrinsics
        guid = guid,
        realm = realm,
        name = name,
        class = class,

        -- Guild info
        guild = guild,
        guildless = not guild,

        -- Level
        level = level,
        levelProgress = progress,
        lastLevelUp = time,

        -- Death status
        dead = dead,

        -- "I was there"
        lastSeen = time,
    }
end

local function UpdatePlayer(player, guid, realm, name, class, guild, level, progress, dead)
    local time = GetServerTime()

    -- Intrinsics
    -- player.guid = guid -- GUID cannot change, because GUID defines player entry in table
    player.realm = realm -- Player may transfer to a new realm
    player.name = name -- Although exceptional, name may change
    -- player.class = class -- Class cannot change in World of Warcraft

    -- Guild info
    if guild then
        player.guild = guild -- Player may change guild
        player.guildless = false -- Player with a guild is, by definition, not guildless
    else
        player.guildless = true -- Know player left guild, but remember former guild name
    end

    -- Level
    if level ~= player.level then
        -- When the level changes, update it and remember when it happened
        player.level = level
        player.lastLevelUp = time
    end
    player.levelProgress = progress -- Level progress may change frequently

    -- Death status
    if not player.dead then -- Update death only to kill, not to resurrect
        player.dead = dead
    end

    -- "I was there"
    player.lastSeen = time
end

-- Add or update player info
function SOFIA.SetPlayerInfo(self, guid, realm, name, class, guild, level, progress, dead)
    if not progress then progress = 0 end
    if type(dead) ~= 'boolean' then dead = false end

    local player = roster[guid]
    if player then
        -- Player known: update
        UpdatePlayer(player, guid, realm, name, class, guild, level, progress, dead)
    else
        -- Player unknown yet: add
        player = CreatePlayer(guid, realm, name, class, guild, level, progress, dead)
        roster[guid] = player
    end
end

-- GetGuildRosterInfo() is available with new data
local function UpdateAllGuild()
    print("Guild update arrived")
    GetGuildRosterInfo()
end

function SOFIA.ApplyRosterSettings(self, _roster)
    roster = _roster
    self:SetPlayerInfo(
        UnitGUID("player"), GetRealmName(), UnitName("player"), select(2,UnitClass("player")), -- Intrinsics
        select(1, GetGuildInfo("player")), -- Guild info
        UnitLevel("player"), UnitXP("player")/UnitXPMax("player"), -- Level
        UnitIsDeadOrGhost("player") -- Death status
    )
end

local rosterTimerFrame = CreateFrame("Frame", AddonName.."_RosterTimer")

function SOFIA.StartRosterTimer(self)
    rosterTimerFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
    rosterTimerFrame:SetScript("OnEvent", UpdateAllGuild)

    -- Request guild info on a regular basis
    C_GuildInfo.GuildRoster() -- Start requesting now
    -- Then request every 11 secs (must be more than 10 secs)
    C_Timer.NewTicker(11, C_GuildInfo.GuildRoster)
end
