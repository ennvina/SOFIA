local AddonName, SOFIA = ...

function SOFIA:GetSettingsConfig()
    if self then
        return self.db and self.db.settings or nil
    else
        return SOFIA.db and SOFIA.db.settings or nil
    end
end

local function SetSort(sort)
    SOFIA:Debug("Setting sort %s", sort)

    local config = SOFIA:GetSettingsConfig()
    if config then
        if config.sort == sort then
            return -- Setting has not changed: nothing to do
        end
        config.sort = sort
    else
        SOFIA:Error("Cannot set sort option %s", tostring(sort))
    end

    -- @todo apply option to window and roster
end

local function SetSize(size)
    SOFIA:Debug("Setting size %s", size)

    local config = SOFIA:GetSettingsConfig()
    if config then
        if config.size == size then
            return -- Setting has not changed: nothing to do
        end
        config.size = size
    else
        SOFIA:Error("Cannot set size option %s", tostring(size))
    end

    -- @todo apply option to window and roster
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
            text = "Sort",
            notCheckable = true,
            hasArrow = true,
            menuList = {
                {
                    text = LEVEL,
                    func = function()
                        SetSort("level")
                        self.window.settings:Hide()
                        self.window.settings = nil
                    end,
                    checked = config and config.sort == "level",
                },
                {
                    text = "Recent level up",
                    func = function()
                        SetSort("recent")
                        self.window.settings:Hide()
                        self.window.settings = nil
                    end,
                    checked = config and config.sort == "recent",
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
                        SetSize("small")
                        self.window.settings:Hide()
                        self.window.settings = nil
                    end,
                    checked = config and config.size == "small",
                },
                {
                    text = LARGE,
                    func = function()
                        SetSize("large")
                        self.window.settings:Hide()
                        self.window.settings = nil
                    end,
                    checked = config and config.size == "large",
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
