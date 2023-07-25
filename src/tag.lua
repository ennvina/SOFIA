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

function SOFIA:FillTag(index, player)
    if index < 0 or index > #self.window.tags then
        self:Debug("Invalid tag index %s", tostring(index))
        return
    end
    local tag = self.window.tags[index]

    tag.texture:SetColorTexture(GetClassColor(player.class))
end

function SOFIA:EmptyTag(index)
    if index < 0 or index > #self.window.tags then
        self:Debug("Invalid tag index %s", tostring(index))
        return
    end
    local tag = self.window.tags[index]

    -- Set it almost transparent, until we find a better appearance
    tag.texture:SetColorTexture(0, 0, 0, 0.1)
end
