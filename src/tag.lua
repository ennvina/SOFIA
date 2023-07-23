local AddonName, SOFIA = ...

function SOFIA:CreateTag(window)
    if not window.tags then
        window.tags = {}
    end
    local index = #window.tags -- Index starts at 0
    local tag = CreateFrame("Frame", nil, window)
    local constants = self:GetConstants("tag")

    local titleHeight = self:GetConstants("title").barHeight
    local border = constants.border
    tag:SetPoint("TOPLEFT", border, -titleHeight - index*constants.height - border)
    tag:SetPoint("RIGHT", -border, 0)
    tag:SetHeight(constants.height - 2*border)

    tag.text = tag:CreateFontString("ARTWORK", nil)
    tag.text:SetFont(constants.fontFace, constants.fontSize)
    tag.text:SetPoint("LEFT", constants.marginLeft, 0)
    local fgColor = self:GetColor(constants.fgColor)
    tag.text:SetTextColor(fgColor:GetRGB())

    tag.texture = tag:CreateTexture(nil, "LOW")
    local bgColor = self:GetColor(constants.bgColor)
    tag.texture:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, 0.5)
    tag.texture:SetAllPoints()

    if not window.tags then
        window.tags = { tag }
    else
        table.insert(window.tags, tag)
    end
    return tag
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

function SOFIA:RefreshTagPool()
    if not self.window then
        self:Error("Cannot manage tag pool before the window is created")
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
