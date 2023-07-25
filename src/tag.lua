local AddonName, SOFIA = ...

local function CreateText(parent, className, marginLeft, color)
    local text = parent:CreateFontString("ARTWORK", nil, className)

    text:SetPoint("LEFT", marginLeft, 0)
    text:SetTextColor(color:GetRGB())

    return text
end

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

    local fgColor = self:GetColor(constants.fgColor)
    tag.texts = {}
    tag.texts.level = CreateText(tag, constants.className, constants.marginLeftLevel, fgColor)
    tag.texts.name  = CreateText(tag, constants.className, constants.marginLeftName , fgColor)

    tag.texture = tag:CreateTexture(nil, "LOW")
    tag.texture:SetTexture(constants.texture)
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

    tag.texture:SetVertexColor(GetClassColor(player.class))

    tag.texts.level:SetText(tostring(player.level))
    tag.texts.name:SetText(player.name)
end

function SOFIA:EmptyTag(index)
    if index < 0 or index > #self.window.tags then
        self:Debug("Invalid tag index %s", tostring(index))
        return
    end
    local tag = self.window.tags[index]

    -- Set it fully transparent
    tag.texture:SetVertexColor(0, 0, 0, 0)

    tag.texts.level:SetText("")
    tag.texts.name:SetText("")
end
