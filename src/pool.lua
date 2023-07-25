local AddonName, SOFIA = ...

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

function SOFIA:RefreshTagPool()
    if not self.window then
        self:Debug("Cannot manage tag pool before the window is created")
        return
    end

    local titleHeight = self:GetConstants("title").barHeight
    local tagHeight = self:GetConstants("tag").height
    local windowHeight = self.window:GetHeight()
    local nbActiveTags = math.floor((windowHeight-titleHeight)/tagHeight)

    local poolCountChanged = nbActiveTags ~= self.window.nbActiveTags

    -- Grow/shrink tag pool if and only if the pool count changes
    if poolCountChanged then
        self:ReserveTagPool(self.window, nbActiveTags)
        self:ShrinkToFit(self.window, nbActiveTags)
        self.window.nbActiveTags = nbActiveTags
    end
end
