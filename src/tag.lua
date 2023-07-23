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

-- Reserve more tags in the pool if needed
function SOFIA:ReserveTagPool(window, count)
    local nbAdded = 0
    while not window.tags or #window.tags < count do
        self:CreateTag(window)
        nbAdded = nbAdded + 1
    end
    if nbAdded > 0 then
        self:Debug("Created %d tags in pool", nbAdded)
    end
end

-- Show/hide extra tags in the pool
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
    local nbTags = math.floor((windowHeight-titleHeight)/tagHeight)

    if nbTags == self.window.nbTags then
        -- Avoid heavy work when the number of tags doesn't change
        return
    end

    self:ReserveTagPool(self.window, nbTags)
    self:ShrinkToFit(self.window, nbTags)
    self.window.nbTags = nbTags
end
