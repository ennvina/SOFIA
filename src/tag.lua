local AddonName, SOFIA = ...

local function CreateText(parent, constants, side)
    local text = parent:CreateFontString("ARTWORK", nil, constants.className)

    if side == "LEFT" then
        text:SetPoint("LEFT", constants.marginLeft, 0)
    else
        text:SetPoint("RIGHT", -constants.marginRight, 0)
    end
    text:SetTextColor(SOFIA:GetColor(constants.fgColor):GetRGB())

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
    tag.texts.name  = CreateText(tag, constants, "LEFT")
    tag.texts.level = CreateText(tag, constants, "RIGHT")

    tag.texture = tag:CreateTexture(nil, "LOW")
    tag.texture:SetTexCoord(unpack(constants.texCoord))
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

    tag.texts.name:SetText(tostring(index)..". "..player.name)
    tag.texts.level:SetText(tostring(player.level))
end

function SOFIA:EmptyTag(index)
    if index < 0 or index > #self.window.tags then
        self:Debug("Invalid tag index %s", tostring(index))
        return
    end
    local tag = self.window.tags[index]

    -- Set it fully transparent
    tag.texture:SetVertexColor(0, 0, 0, 0)

    tag.texts.name:SetText("")
    tag.texts.level:SetText("")
end
