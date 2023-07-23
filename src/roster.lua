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
    player.guild = guild -- Player may change guild

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

    return player
end

local function StorePlayer(player, realm, guild)
    local location = { realm = realm or "", guild = guild or "" }
    roster._whereis[player.guid] = location

    if not roster[location.realm] then
        roster[location.realm] = {}
    end

    if not roster[location.realm][location.guild] then
        roster[location.realm][location.guild] = {}
    end

    roster[location.realm][location.guild][player.guid] = player
end

local function RelocatePlayer(player, fromRealm, fromGuild, toRealm, toGuild)
    roster[fromRealm or ""][fromGuild or ""][player.guid] = nil
    StorePlayer(player, toRealm, toGuild)
end

-- Add or update player info
function SOFIA.SetPlayerInfo(self, guid, realm, name, class, guild, level, progress, dead)
    if not progress then progress = 0 end -- Unknown progress is 0. Maybe we can do better
    if type(dead) ~= 'boolean' then dead = false end

    local location = roster._whereis[guid]
    if location then
        -- Player known: update
        local player = roster[location.realm][location.guild][guid]
        UpdatePlayer(player, guid, realm, name, class, guild, level, progress, dead)
        -- Move player to if realm or guild has changed
        if realm ~= location.realm or guild ~= location.guild then
            RelocatePlayer(player, location.realm, location.guild, realm, guild)
        end
    else
        -- Player unknown yet: add
        local player = CreatePlayer(guid, realm, name, class, guild, level, progress, dead)
        StorePlayer(player, realm, guild)
    end
end

-- GetGuildRosterInfo() is available with new data
local function UpdateAllGuild()
    local realm = GetRealmName()
    local guild = select(1, GetGuildInfo("player"))
    for i=1, GetNumGuildMembers() do
        local name, _, _, level, _, _, _, _, _, _, class, _, _, _, _, _, guid = GetGuildRosterInfo(i)
        SOFIA:SetPlayerInfo(guid, realm, name, class, guild, level)
    end
end

function SOFIA.ApplyRosterSettings(self, _roster)
    roster = _roster
end

local function WhoAmI()
    local guid, realm, name, class = UnitGUID("player"), GetRealmName(), UnitName("player"), select(2,UnitClass("player")) -- Intrinsics
    local guild = select(1, GetGuildInfo("player")) -- Guild info
    local level, progress = UnitLevel("player"), (UnitXPMax("player") > 0) and (UnitXP("player")/UnitXPMax("player")) or nil -- Level
    local dead = UnitIsDeadOrGhost("player") -- Death status
    SOFIA:SetPlayerInfo(guid, realm, name, class, guild, level, progress, dead)
end

local rosterTimerFrame = CreateFrame("Frame", AddonName.."_RosterTimer")

function SOFIA.StartRosterTimer(self)
    rosterTimerFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
    rosterTimerFrame:SetScript("OnEvent", UpdateAllGuild)

    -- Request guild info on a regular basis
    -- Request every 11 secs (must be more than 10 secs)
    C_Timer.NewTicker(11, C_GuildInfo.GuildRoster)
    -- C_GuildInfo.GuildRoster() -- Do not request now, because guild info is unlikely available at start

    -- Request own info
    -- Unlike guilds, the 10 secs threshold is not mandatory, but it's best no to query player info too often either
    C_Timer.NewTicker(11, WhoAmI)

    SOFIA:Debug("Started roster timers.")
end
