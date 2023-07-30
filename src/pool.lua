local AddonName, SOFIA = ...

-- Pool constructor
function SOFIA:InitPool()
    self.pool = {
        nbActiveTags = 0, -- Number of tags potentially displayed on screen
        nbCandidates = 0, -- Convenient variable to count 'candidates' size
        candidates = {}, -- Map of candidates, indexed by GUID
        chosen = {}, -- Array of chosen ones, sorted by relevance score
    }
end

-- Allocate more tags in the pool
function SOFIA:ReserveTagPool(window, count)
    local nbAdded = 0
    local security = 1000 -- Security to avoid infinite loop
    while (not window.tags or #window.tags < count) and nbAdded < security do
        self:CreateTag(window)
        nbAdded = nbAdded + 1
    end
    if nbAdded > 0 then
        self:Debug("Created %d tag%s in pool", nbAdded, nbAdded > 1 and "s" or "")
    end
end

-- Show/hide tags in the pool, based on the number of active tags
function SOFIA:ShrinkToFit(window, count)
    if not window.tags then
        -- No tags, nothing to shrink
        return
    end

    for i, tag in ipairs(window.tags) do
        tag:SetShown(i <= count)
    end
end

-- The window has changed in a way that it may display more tags or less tags
function SOFIA:RefreshTagPoolCount()
    if not self.window then
        self:Debug("Cannot manage tag pool before the window is created")
        return
    end

    local titleHeight = self:GetConstants("title").barHeight
    local tagHeight = self:GetVariableConstants("tag", "size").height
    local spacing = self:GetVariableConstants("tag", "spacing")
    local windowHeight = self.window:GetHeight()
    local constants = self:GetConstants("tag")
    local border = constants and constants.border or 0
    local nbActiveTags = math.floor((windowHeight-titleHeight-border)/(tagHeight+spacing))

    local poolCountChanged = nbActiveTags ~= self.pool.nbActiveTags

    -- Grow/shrink tag pool if and only if the pool count changes
    if poolCountChanged then
        self:ReserveTagPool(self.window, nbActiveTags)
        self:ShrinkToFit(self.window, nbActiveTags)
        local addedActiveTags = nbActiveTags > self.pool.nbActiveTags
        local chosenWereTruncated = self.pool.nbCandidates > self.pool.nbActiveTags
        self.pool.nbActiveTags = nbActiveTags
        if addedActiveTags then
            self:WriteCandidatesToTags(not chosenWereTruncated)
        end
    end
end

local function PlayerSorterByLevel(a, b)
    if a.level == b.level then
        -- Levels are identical
        -- The best one is the one who leveled up first
        return a.lastLevelUp < b.lastLevelUp
    end

    -- Levels are different
    -- The best one is the one with highest level
    return a.level > b.level
end

local function PlayerSorterByRecentLevelUp(a, b)
    -- The best players are the ones who leveled up last
    return a.lastLevelUp > b.lastLevelUp
end

local function GetPlayerSorter()
    local config = SOFIA:GetSettingsConfig()
    local sort = config and config.sort
    if sort == "recent" then
        return PlayerSorterByRecentLevelUp
    elseif sort == "level" then
        return PlayerSorterByLevel
    else
        if type(sort) == 'string' then
            SOFIA:Error("Unknown sort option '%s'.", sort)
        else
            SOFIA:Error("Undefined sort option.", sort)
        end
        return PlayerSorterByLevel
    end
end

-- Set the list of all players, indexed by their GUID
-- If the list is empty, all players are cleared
function SOFIA:SetTagPoolPlayers(players)
    local nbCandidates = 0
    for _, _ in pairs(players) do
        nbCandidates = nbCandidates + 1
    end

    -- Update the candidate list
    self.pool.candidates = players
    self.pool.nbCandidates = nbCandidates

    -- Sort candidates and write the 'best' ones to tags
    self:WriteCandidatesToTags()
end

-- A single player has been added or updated
function SOFIA:SetTagPoolPlayer(player, isNew, updated)
    if self.pool.nbActiveTags == 0 then
        -- No active tags available: update the candidate list and leave
        if not self.pool.candidates[player.guid] then
            self.pool.candidates[player.guid] = player
            self.pool.nbCandidates = self.pool.nbCandidates + 1
        end
        return
    end

    local worthChecking = false
    if not self.pool.candidates[player.guid] then
        self.pool.candidates[player.guid] = player
        self.pool.nbCandidates = self.pool.nbCandidates + 1
        worthChecking = true
    elseif updated.something then
        -- For now, interesting updates are level and name
        worthChecking = updated.level or updated.name
    end

    if not worthChecking then
        return
    end

    if self:IsChosenOne(player.guid) then
        -- Player is a chosen one: refresh the tag list accordingly
        self:WriteCandidatesToTags(true)
    else
        -- Player is not a chosen one: give the player a chance to be in it
        local hereComesANewChallenger = false
        if #self.pool.chosen < self.pool.nbActiveTags then
            hereComesANewChallenger = true
        else
            local playerSorter = GetPlayerSorter()
            for _, challenger in ipairs(self.pool.chosen) do
                if playerSorter(player, challenger) then
                    hereComesANewChallenger = true
                    break
                end
            end
        end
        if hereComesANewChallenger then
            -- Pre-fill the chosen list with the new candidate
            table.insert(self.pool.chosen, player)
            -- Then go for it
            self:WriteCandidatesToTags(true)
        end
    end
end

-- A single player has been deleted
function SOFIA:RemoveTagPoolPlayer(guid)
    if not self.pool.candidates[guid] then
        return
    end

    self.pool.candidates[guid] = nil
    self.pool.nbCandidates = self.pool.nbCandidates - 1

    if self:IsChosenOne(guid) then
        -- A chosen one was removed, replace by someone else or no one
        self:WriteCandidatesToTags()
    end
end

-- Check if a player is a chosen one, and if yes, return its index
function SOFIA:IsChosenOne(guid)
    for index, player in ipairs(self.pool.chosen) do
        if player.guid == guid then
            return index
        end
    end
    return nil
end

-- Sort all candidates and pick the 'best' ones, ordered by relevance
-- The best ones are the chosen ones
-- If prechosen is true, base the chosen ones off of previous chosen
-- Otherwise, all candidates are evaulated
function SOFIA:WriteCandidatesToTags(prechosen)
    local nbActiveTags = self.pool.nbActiveTags
    local nbCandidates = prechosen and #self.pool.chosen or self.pool.nbCandidates

    if not prechosen then
        self.pool.chosen = {}
        for _, player in pairs(self.pool.candidates) do
            table.insert(self.pool.chosen, player)
        end
    end

    local playerSorter = GetPlayerSorter()
    table.sort(self.pool.chosen, playerSorter)

    if nbCandidates > nbActiveTags then
        -- Clamp the list if there are too many candidates
        for i = nbCandidates, nbActiveTags+1, -1 do
            table.remove(self.pool.chosen, i)
        end
    end

    local previousPlayer = nil
    local previousRank = nil
    local rankless = (SOFIA:GetSettingsConfig() or {})["sort"] == "recent"
    for i = 1, nbActiveTags do
        local player = self.pool.chosen[i]
        if player then
            if rankless then
                self:FillTag(i, player, nil)
            else
                local rank = i
                if previousPlayer and not playerSorter(previousPlayer, player) then
                    -- Give same rank to consecutive players with same score
                    rank = previousRank
                end
                self:FillTag(i, player, rank)
                previousRank = rank
            end
            previousPlayer = player
        else
            self:EmptyTag(i)
        end
    end
end

-- Static initializer
SOFIA:InitPool()
