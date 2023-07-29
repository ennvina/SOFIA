local AddonName, SOFIA = ...

function SOFIA:GetSettingsConfig()
    if self then
        return self.db and self.db.settings or nil
    else
        return SOFIA.db and SOFIA.db.settings or nil
    end
end

function SOFIA:SetSort(sort)
    self:Debug("Setting sort %s", sort)

    local config = self:GetSettingsConfig()
    if config then
        if config.sort == sort then
            return -- Setting has not changed: nothing to do
        end
        config.sort = sort
    else
        self:Error("Cannot set sort option %s", tostring(sort))
    end

    -- Reconsider all candidates to sort tags
    self:WriteCandidatesToTags()
end

function SOFIA:SetSize(size)
    self:Debug("Setting size %s", size)

    local config = self:GetSettingsConfig()
    if config then
        if config.size == size then
            return -- Setting has not changed: nothing to do
        end
        config.size = size
    else
        self:Error("Cannot set size option %s", tostring(size))
    end

    -- Apply option to window and roster
    self:UpdateTagSize(self:GetWindow())
    self:RefreshTagPoolCount()
end

function SOFIA:SetSpacing(spacing)
    self:Debug("Setting spacing %s", spacing)

    local config = self:GetSettingsConfig()
    if config then
        if config.spacing == spacing then
            return -- Setting has not changed: nothing to do
        end
        config.spacing = spacing
    else
        self:Error("Cannot set size option %s", tostring(spacing))
    end

    -- Apply option to window and roster
    self:UpdateTagSize(self:GetWindow())
    self:RefreshTagPoolCount()
end

-- Open the settings popup menu
function SOFIA:OpenSettings()
    if not self.window then
        self:Error("Cannot open settings before the main window is created")
    end

    if self.window.settings then
        self.window.settings:Hide()
        self.window.settings = nil
    end

    self.window.settings = CreateFrame("Frame", AddonName.."_SettingsFrame", UIParent, "UIDropDownMenuTemplate")

    local config = self:GetSettingsConfig()

    local menu = {
        -- Option to sort by different value
        {
            text = "Sort By",
            notCheckable = true,
            hasArrow = true,
            menuList = {
                {
                    text = LEVEL,
                    func = function()
                        self:SetSort("level")
                        self.window.settings:Hide()
                        self.window.settings = nil
                    end,
                    checked = config and config.sort == "level",
                    tooltipOnButton = true,
                    tooltipTitle = "Sort by player level",
                    tooltipText = "Players with the highest level appear on top. "..
                        "When two players have the same level, the one who leveled up first appears on top.",
                },
                {
                    text = "Recent level up",
                    func = function()
                        self:SetSort("recent")
                        self.window.settings:Hide()
                        self.window.settings = nil
                    end,
                    checked = config and config.sort == "recent",
                    tooltipOnButton = true,
                    tooltipTitle = "Sort by most recent level up",
                    tooltipText = "Players who leveled up recently appear on top."
                },
            }
        },
        -- Option to set the font size and tag height
        {
            text = "Size",
            notCheckable = true,
            hasArrow = true,
            menuList = {
                {
                    text = SMALL,
                    func = function()
                        self:SetSize("small")
                        self.window.settings:Hide()
                        self.window.settings = nil
                    end,
                    checked = config and config.size == "small",
                },
                {
                    text = "Medium",
                    func = function()
                        self:SetSize("medium")
                        self.window.settings:Hide()
                        self.window.settings = nil
                    end,
                    checked = config and config.size == "medium",
                },
                {
                    text = LARGE,
                    func = function()
                        self:SetSize("large")
                        self.window.settings:Hide()
                        self.window.settings = nil
                    end,
                    checked = config and config.size == "large",
                },
            }
        },
        -- Option to set the spacing between tags
        {
            text = "Spacing",
            notCheckable = true,
            hasArrow = true,
            menuList = {
                {
                    text = NONE,
                    func = function()
                        self:SetSpacing("none")
                        self.window.settings:Hide()
                        self.window.settings = nil
                    end,
                    checked = config and config.spacing == "none",
                },
                {
                    text = SMALL,
                    func = function()
                        self:SetSpacing("small")
                        self.window.settings:Hide()
                        self.window.settings = nil
                    end,
                    checked = config and config.spacing == "small",
                },
                {
                    text = LARGE,
                    func = function()
                        self:SetSpacing("large")
                        self.window.settings:Hide()
                        self.window.settings = nil
                    end,
                    checked = config and config.spacing == "large",
                },
            }
        },
        -- Convenient shortcut to close the menu
        {
            text = CLOSE,
            notCheckable = true,
            func = function()
                self.window.settings:Hide()
                self.window.settings = nil
            end,
        },
    }

    EasyMenu(menu, self.window.settings, "cursor", 0, 0, "MENU")
end
