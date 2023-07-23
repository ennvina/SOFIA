local AddonName, SOFIA = ...

-- Cache frequently called functions
local GetServerTime = GetServerTime

-- List of players; will be synchronized with db during ApplyRosterSettings
local roster = {}

function SOFIA.GetRoster(self, realm, guild)
    if realm == '_whereis' then
        self:Debug("Invalid real name '%s'.", realm)
    end

    if not roster[realm] then
        self:Debug("Unknown realm '%s'.", realm)
        return {}
    end

    if not roster[realm][guild] then
        self:Debug("Unknown guild '%s'.", guild)
        return {}
    end

    return roster[realm][guild]
end

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
        local before, after = tostring(player[field]), tostring(value)
        if field == 'dead' then
            before, after = before == 'true' and 'dead' or 'alive', after == 'true' and 'dead' or 'alive'
        end
        local pattern = "%s %s from %s to %s."
        if type(player[field]) == 'string' or type(value) == 'string' then
            pattern = "%s %s from '%s' to '%s'."
        end
        SOFIA:Debug(pattern, tostring(player.name), participle, before, after)
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
        player.progress = -1 -- Progress is unknown upon level up; may be overwritten below
        updated.progress = true -- Also tell progress gets updated, silently
    end
    if progress ~= player.progress and progress >= 0 then -- Player sub-level may change frequently
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

function SOFIA.StorePlayerLocation(self, player, realm, guild)
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

function SOFIA.RelocatePlayer(self, player, fromRealm, fromGuild, toRealm, toGuild)
    roster[fromRealm or ""][fromGuild or ""][player.guid] = nil
    self:StorePlayerLocation(player, toRealm, toGuild)
    if (fromRealm or "") ~= toRealm then
        SOFIA:Debug("Relocated %s from realm '%s' to '%s'.", player.name, fromRealm or "", toRealm)
    end
    if (fromGuild or "") ~= toGuild then
        SOFIA:Debug("Relocated %s from guild '%s' to '%s'.", player.name, fromGuild or "", toGuild)
    end
end

function SOFIA.FindPlayerByGUID(self, guid)
    for realm, realmData in pairs(roster) do
        if realm ~= '_whereis' then
            for guild, guildData in pairs(realmData) do
                if guildData[guid] then
                    return { realm = realm, guild = guild }
                end
            end
        end
    end
    return nil
end

-- Add or update player info
-- Returns if player has been added, and which fields of player have been updated
-- Do not tell when times (lastLevelUp or lastSeen) have been updated, because:
-- - lastLevelUp can be guessed when level gets updated
-- - lastSeen is always updated
function SOFIA.SetPlayerInfo(self, guid, realm, name, class, guild, level, progress, dead)
    if not progress then progress = -1 end -- Unknown progress is -1 to tell "I don't know"
    if type(dead) ~= 'boolean' then dead = false end

    local location = roster._whereis[guid]
    if location then
        -- Check integrity of _whereis
        if not roster[location.realm]
        or not roster[location.realm][location.guild]
        or not roster[location.realm][location.guild][guid] then
            self:Debug("%s not found in realm '%s' in guild '%s'.", guid, location.realm, location.guild)
            location = self:FindPlayerByGUID(guid)
            if location then
                self:Debug("%s was in fact in realm '%s' in guild '%s'.", guid, location.realm, location.guild)
                roster._whereis[guid] = location
            else
                self:Debug("The player is nowhere to be found, a new one will be created.")
                roster._whereis[guid] = nil
            end
        elseif roster[location.realm]
           and roster[location.realm][location.guild]
           and roster[location.realm][location.guild][guid]
           and (roster[location.realm][location.guild][guid].realm ~= location.realm
             or roster[location.realm][location.guild][guid].guild ~= location.guild) then
             SOFIA:Debug("%s location is not synchronized with its actual realm and guild.", guid)
        end
    end
    if location then
        -- Player known: update
        local player = roster[location.realm][location.guild][guid]
        local _, updated = UpdatePlayer(player, guid, realm, name, class, guild, level, progress, dead)
        -- Move player if realm or guild has changed
        if ((realm or "") ~= location.realm) or ((guild or "") ~= location.guild) then
            self:RelocatePlayer(player, location.realm, location.guild, realm, guild)
        end
        return false, updated
    else
        -- Player unknown yet: add
        local player, updated = CreatePlayer(guid, realm, name, class, guild, level, progress, dead)
        self:StorePlayerLocation(player, realm, guild)
        return true, updated
    end
end

function SOFIA.ApplyRosterSettings(self, _roster)
    roster = _roster
end
