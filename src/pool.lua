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
        self:Debug("Created %d tags in pool", nbAdded)
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
    local tagHeight = self:GetConstants("tag").height
    local windowHeight = self.window:GetHeight()
    local nbActiveTags = math.floor((windowHeight-titleHeight)/tagHeight)

    local poolCountChanged = nbActiveTags ~= self.pool.nbActiveTags

    -- Grow/shrink tag pool if and only if the pool count changes
    if poolCountChanged then
        self:ReserveTagPool(self.window, nbActiveTags)
        self:ShrinkToFit(self.window, nbActiveTags)
        local addedActiveTags = nbActiveTags > self.pool.nbActiveTags
        self.pool.nbActiveTags = nbActiveTags
        if addedActiveTags then
            self:WriteCandidatesToTags()
        end
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

    -- @todo
    self:Debug("Must set player %s", tostring(player.name))

    if not self.pool.candidates[player.guid] then
        self.pool.candidates[player.guid] = player
        self.pool.nbCandidates = self.pool.nbCandidates + 1
    end
end

-- A single player has been deleted
function SOFIA:RemoveTagPoolPlayer(guid)
    if not self.pool.candidates[guid] then
        return
    end

    self.pool.candidates[guid] = nil
    self.pool.nbCandidates = self.pool.nbCandidates - 1

    for _, player in ipairs(self.pool.chosen) do
        if player.guid == guid then
            -- A chosen one was removed, replace by someone else or no one
            self:WriteCandidatesToTags()
            break
        end
    end
end

function SOFIA:WriteCandidatesToTags()
    local nbActiveTags = self.pool.nbActiveTags
    local nbCandidates = self.pool.nbCandidates

    -- @todo
    self:Debug("Must sort and write candidates to tags")
    -- self.pool.chosen = {}
end

-- Static initializer
SOFIA:InitPool()