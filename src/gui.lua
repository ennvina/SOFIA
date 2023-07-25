local AddonName, SOFIA = ...

function SOFIA:GetWindow()
    return self and self.window or SOFIA.window
end

function SOFIA:GetWindowConfig()
    if self then
        return self.db and self.db.window or nil
    else
        return SOFIA.db and SOFIA.db.window or nil
    end
end

local function createMainFrame()
    local mainFrame = CreateFrame("Frame", AddonName..'_MainFrame', UIParent)

    mainFrame:EnableMouse(true)
    mainFrame:SetMovable(true)

    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetClampedToScreen(true)
    mainFrame:SetScript("OnDragStart", function() mainFrame:StartMoving() end)

    mainFrame:SetScript(
        "OnDragStop",
        function()
            mainFrame:StopMovingOrSizing()

            local config = SOFIA:GetWindowConfig()
            config.point = 'TOPLEFT'
            config.y = mainFrame:GetTop()
            config.x = mainFrame:GetLeft()
        end
    )

    mainFrame:SetScript("OnShow", function()
        SOFIA:RefreshTagPool()
    end)

    mainFrame:SetScript("OnSizeChanged", function()
        if mainFrame:IsShown() then
            SOFIA:RefreshTagPool()
        end
    end)

    return mainFrame
end

-- Create title frame
local function createTitleFrame(baseFrame, subtitle)
    local titleFrame = CreateFrame("Frame", AddonName..'_TitleFrame', baseFrame)
    local constants = SOFIA:GetConstants('title')

    titleFrame:SetPoint('TOPLEFT')
    titleFrame:SetPoint('TOPRIGHT')
    titleFrame:SetHeight(constants.barHeight)

    local bgColor = SOFIA:GetColor(constants.bgColor)
    titleFrame.texture = titleFrame:CreateTexture(nil, "BACKGROUND")
    titleFrame.texture:SetColorTexture(bgColor:GetRGB())
    titleFrame.texture:SetAllPoints()

    local fgColor = SOFIA:GetColor(constants.fgColor)
    titleFrame.text = titleFrame:CreateFontString(nil, "ARTWORK")
    titleFrame.text:SetFont(constants.fontFace, constants.fontSize)
    titleFrame.text:SetPoint("LEFT", constants.marginLeft, 0)
    if subtitle then
        titleFrame.text:SetText(string.format('%s - %s', AddonName, subtitle))
    else
        titleFrame.text:SetText(AddonName)
    end
    titleFrame.text:SetTextColor(fgColor:GetRGB())
    -- Add shadow if the text color is bright
    if (fgColor.r + fgColor.g + fgColor.b) > 1.5 then
        titleFrame.text:SetShadowColor(0,0,0,0.5)
        titleFrame.text:SetShadowOffset(1,-1)
    end

    baseFrame.titleFrame = titleFrame
    return titleFrame
end

local function createButton(baseFrame, position, texture, callback, texCoord, tooltip)
    local button = CreateFrame("Button", nil, baseFrame)

    button:SetPoint('RIGHT', -position, 0)
    button:SetWidth(14)
    button:SetHeight(14)

    if type(texture) == 'string' then
        texture = {
            normal = texture,
            highlight = texture,
            pushed = texture,
        }
    end

    local normal = button:CreateTexture()
    normal:SetTexture(texture.normal)
    normal:SetAllPoints()
    button:SetNormalTexture(normal)

    local highlight = button:CreateTexture()
    highlight:SetTexture(texture.highlight)
    highlight:SetAllPoints()
    button:SetHighlightTexture(highlight)

    local pushed = button:CreateTexture()
    pushed:SetTexture(texture.pushed)
    pushed:SetAllPoints()
    button:SetPushedTexture(pushed)

    if (texCoord) then
        normal:SetTexCoord(unpack(texCoord))
        highlight:SetTexCoord(unpack(texCoord))
        pushed:SetTexCoord(unpack(texCoord))
    end

    button:SetScript("OnClick", callback)

    if tooltip then
        button:SetScript("OnEnter", function()
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip_SetTitle(GameTooltip, tooltip)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    return button
end

local function createTitleButtons(baseFrame)
    -- List of buttons as they appear in the title bar, from right to left
    local buttons = {
        -- Close button
        {
            texture = {
                normal = 'Interface/Buttons/UI-Panel-MinimizeButton-Up',
                pushed = 'Interface/Buttons/UI-Panel-MinimizeButton-Down',
                highlight = 'Interface/Buttons/UI-Panel-MinimizeButton-Highlight',
            },
            callback = function()
                SlashCmdList.SOFIA("hide")
            end,
            texCoord = {0.08, 0.9, 0.1, 0.9},
            -- tooltip = CLOSE, -- No need a tooltip, everyone knows what a close button is
        },
        -- Settings button, disabled for now because there are no options yet
        -- {
        --     texture = 'Interface/GossipFrame/BinderGossipIcon',
        --     callback = SOFIA.ToggleSettings,
        --     tooltip = SETTINGS,
        -- },
    }

    local position = 5

    for _, button in pairs(buttons) do
        createButton(baseFrame, position, button.texture, button.callback, button.texCoord, button.tooltip)
        position = position + 15
    end
end

-- Create background frame
local function createBackgroundFrame(baseFrame, offsetY)
    local backgroundFrame = CreateFrame("Frame", AddonName..'_BackgroundFrame', baseFrame)

    backgroundFrame:SetPoint('LEFT')
    backgroundFrame:SetPoint('RIGHT')
    backgroundFrame:SetPoint('TOP', 0, -offsetY)
    backgroundFrame:SetPoint('BOTTOM')

    backgroundFrame.texture = backgroundFrame:CreateTexture(nil, "BACKGROUND")
    backgroundFrame.texture:SetColorTexture(0, 0, 0, 0.5)
    backgroundFrame.texture:SetAllPoints()

    baseFrame.bgFrame = backgroundFrame
    return backgroundFrame
end

-- Create resizer for width and height
local function createCornerResizer(baseFrame)
    baseFrame:SetResizable(true)

    local resizer = CreateFrame("Button", AddonName..'_ResizerFrame', baseFrame, "PanelResizeButtonTemplate")

    resizer:SetPoint("BOTTOMRIGHT")

    local constraints = SOFIA:GetConstants('constraints')
    resizer:Init(baseFrame, constraints.minWidth, constraints.minHeight, constraints.maxWidth, constraints.maxHeight)

    resizer:SetOnResizeStoppedCallback(function(frame)
        local config = SOFIA:GetWindowConfig()
        config.width = frame:GetWidth()
        config.height = frame:GetHeight()
    end)

    baseFrame.resizer = resizer
    return resizer
end

-- Create main window
function SOFIA:CreateWindow()
    local window = createMainFrame()
    self.window = window

    local titleFrame = createTitleFrame(window)
    createTitleButtons(titleFrame)
    createBackgroundFrame(window, titleFrame:GetHeight())
--    createTextFrame(historyBackgroundFrame)
    createCornerResizer(window)
end

function SOFIA:ShowWindow()
    local config = self:GetWindowConfig()

    config.visible = true

    local window = self:GetWindow()
    if window then
        window:Show()
    end
end

function SOFIA:HideWindow()
    local config = self:GetWindowConfig()

    config.visible = false

    local window = self:GetWindow()
    if window then
        window:Hide()
    end
end

function SOFIA:ToggleWindow()
    local config = self:GetWindowConfig()

    local visible
    if config then
        visible = not config.visible
        config.visible = visible
    else
        visible = true
    end

    local window = self:GetWindow()
    if window then
        window:SetShown(visible)
    end
end

function SOFIA:ApplyWindowSettings()
    local mainFrame = self:GetWindow()
    local config = self:GetWindowConfig()

    if not mainFrame or not config then
        return
    end

    mainFrame:ClearAllPoints()
    if config.point then
        mainFrame:SetPoint(config.point, UIParent, 'BOTTOMLEFT', config.x, config.y)
    else
        mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    mainFrame:SetWidth(config.width)
    mainFrame:SetHeight(config.height)
    mainFrame:SetShown(config.visible)
end
