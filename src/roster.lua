local AddonName, SOFIA = ...

-- Cache frequently called functions
local GetServerTime = GetServerTime

-- List of players; will be synchronized with db during ApplyRosterSettings
local roster = {}

-- Create a new player, return it and return its update status
local function CreatePlayer(guid, realm, name, class, guild, level, progress, dead)
    local time = GetServerTime()

    local player = {
        -- Intrinsics
        guid = guid,
        realm = realm,
        name = name,
        class = class,

        -- Guild info
        guild = guild,

        -- Level
        level = level,
        progress = progress,
        lastLevelUp = time,

        -- Death status
        dead = dead,

        -- "I was there"
        lastSeen = time,
    }

    local updated = {
        everything = true,
        something = true,

        -- Intrinsics
        guid = true,
        realm = true,
        name = true,
        class = true,

        -- Guild info
        guild = true,

        -- Level
        level = true,
        progress = true,
        -- Do not track 'lastLevelUp' updates, we know it gets updated alongside 'level'

        -- Death status
        dead = true,

        -- Do not track 'lastSeen' updates, because it always gets updated
    }

    return player, updated
end

-- Utility function to update a field
local function UpdateField(player, field, value, participle, updated)
    if participle then -- Passing no participle means we don't want to spam
        SOFIA:Debug("%s %s from '%s' to '%s'.", tostring(player.name), participle, tostring(player[field]), tostring(value))
    end
    player[field] = value
    updated.something = true
    updated[field] = true
end

-- Update a player, return it and return what was updated in the player
local function UpdatePlayer(player, guid, realm, name, class, guild, level, progress, dead)
    local time = GetServerTime()

    local updated = {
        everything = false, -- Cannot update everything because of immutable variables
        something = false, -- For now, nothing has changed, but the function will tell
    }

    -- Intrinsics
    -- player.guid = guid -- GUID cannot change, because GUID defines player entry in table
    if realm ~= player.realm then -- Player may transfer to a new realm
        UpdateField(player, 'realm', realm, 'transferred', updated)
    end
    if name ~= player.name then -- Although exceptional, name may change
        UpdateField(player, 'name', name, 'renamed', updated)
    end
    -- player.class = class -- Class cannot change in World of Warcraft

    -- Guild info
    if guild ~= player.guild then -- Player may change guild
        UpdateField(player, 'guild', guild, 'changed guild', updated)
    end

    -- Level
    if level ~= player.level then -- Player may level up, obviously
        -- When the level changes, update it and remember when it happened
        UpdateField(player, 'level', level, 'leveled up', updated)
        player.lastLevelUp = time -- Overwrite lastLevelUp, but do not advertise it
    end
    if progress ~= player.progress then -- Player sub-level may change frequently
        UpdateField(player, 'progress', progress, nil, updated)
    end

    -- Death status
    if dead ~= player.dead then
        if not player.dead then -- Update death status only to kill, not to resurrect
            UpdateField(player, 'dead', dead, 'switched death', updated)
        end
    end

    -- "I was there"
    player.lastSeen = time

    return player, updated
end

local function StorePlayerLocation(player, realm, guild)
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
    StorePlayerLocation(player, toRealm, toGuild)
end

-- Add or update player info
-- Returns if player has been added, and which fields of player have been updated
-- Do not tell when times (lastLevelUp or lastSeen) have been updated, because:
-- - lastLevelUp can be guessed when level gets updated
-- - lastSeen is always updated
function SOFIA.SetPlayerInfo(self, guid, realm, name, class, guild, level, progress, dead)
    if not progress then progress = 0 end -- Unknown progress is 0. Maybe we can do better
    if type(dead) ~= 'boolean' then dead = false end

    local location = roster._whereis[guid]
    if location then
        -- Player known: update
        local player = roster[location.realm][location.guild][guid]
        local _, updated = UpdatePlayer(player, guid, realm, name, class, guild, level, progress, dead)
        -- Move player if realm or guild has changed
        if realm ~= location.realm or guild ~= location.guild then
            RelocatePlayer(player, location.realm, location.guild, realm, guild)
        end
        return false, updated
    else
        -- Player unknown yet: add
        local player, updated = CreatePlayer(guid, realm, name, class, guild, level, progress, dead)
        StorePlayerLocation(player, realm, guild)
        return true, updated
    end
end

-- GetGuildRosterInfo() is available with new data
local function UpdateAllGuild()
    local realm = GetRealmName()
    local guild = select(1, GetGuildInfo("player"))
    for i=1, GetNumGuildMembers() do
        local name, _, _, level, _, _, _, _, _, _, class, _, _, _, _, _, guid = GetGuildRosterInfo(i)
        name = select(1,strsplit("-", name))
        local isNew, whatChanged = SOFIA:SetPlayerInfo(guid, realm, name, class, guild, level)
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
    local isNew, whatChanged = SOFIA:SetPlayerInfo(guid, realm, name, class, guild, level, progress, dead)
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
