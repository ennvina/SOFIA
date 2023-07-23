local AddonName, SOFIA = ...

function SOFIA:CreateTag(baseFrame)
    local tag = CreateFrame("Frame", nil, baseFrame)
    local constants = self:GetConstants("tag")

    tag:SetPoint("TOPLEFT")
    tag:SetPoint("RIGHT")
    tag:SetHeight(constants.height)

    tag.text = tag:CreateFontString("ARTWORK", nil)
    tag.text:SetFont(constants.fontFace, constants.fontSize)
    tag.text:SetPoint("LEFT", constants.marginLeft, 0)
    tag.text:SetTextColor(self:GetColor(constants.fgColor):GetRGB())

    tag.texture = tag:CreateTexture(nil, "BACKGROUND")
    tag.texture:SetColorTexture(0,0,0,0.5)
    tag.texture:SetAllPoints()

    if not baseFrame.tags then
        baseFrame.tags = { tag }
    else
        table.insert(baseFrame.tags, tag)
    end
    return tag
end
