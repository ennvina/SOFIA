local AddonName, SOFIA = ...

-- Shortcuts for colors, not saved in db
SOFIA.colors = {
    ['black']       = CreateColor(0, 0, 0),
    ['white']       = CreateColor(1, 1, 1),

    ['hcRed']       = CreateColor(1, 0, 0),
    ['darkRed']     = CreateColor(0.7, 0, 0),

    ['chat']        = CreateColor(1, 0.8, 0.8),

    ['flashy']      = CreateColor(1, 0, 1),
}
function SOFIA:GetColor(name)
    local color = self.colors[name]
    if color then
        return color
    else
        self:Error("Unknown color '%s'.", name)
        -- Return very flashy color to make it stand out as 'hey, this is not normal'
        return CreateColor(1,0,1)
    end
end
function SOFIA:GetColorHex(name)
    return self:GetColor(name):GenerateHexColor()
end

-- Global constants, not saved in db
SOFIA.constants = {
    constraints = {
        minWidth = 150,
        minHeight = 100,
        maxWidth = 450,
        maxHeight = 1000,
    },

    title = {
        bgColor = 'darkRed',
        fgColor = 'black',
        barHeight = 18,
        marginLeft = 5,
        fontFace = "Fonts\\ARIALN.ttf",
        fontSize = 12,
    },

    tag = {
        size = {
            small = {
                height = 16,
                tooltipOffsetX = -78,
                tooltipOffsetY = 24,
                className = "GameFontNormalSmall",
            },
            large = {
                height = 24,
                tooltipOffsetX = -82,
                tooltipOffsetY = 28,
                className = "GameFontNormalLarge",
            },
        },
        border = 1,
        marginLeft = 5,
        marginRight = 10,
        texCoord = {0, 0.97, 0, 1},
        texture = 'Interface\\RaidFrame\\Raid-Bar-Hp-Fill',
        fgColor = 'white',
    },
}
function SOFIA:GetConstants(tag)
    local constants = self.constants[tag]
    if constants then
        return constants
    else
        self:Error("Unknown constant tag '%s'.", tag)
        return {}
    end
end

function SOFIA:GetVariableConstants(tag, setting)
    local constants = self.constants[tag]
    if not constants then
        self:Error("Unknown constant tag '%s'.", tag)
        return {}
    end

    local settings = constants[setting]
    if not settings then
        self:Error("Unknown constant settings '%s' for tag '%s'.", setting, tag)
        return {}
    end

    local settingsConfig = self:GetSettingsConfig()
    if not settingsConfig then
        self:Error("Settings not initialized yet.")
        return {}
    end

    local userSetting = settingsConfig[setting]
    if type(userSetting) == 'nil' then
        self:Debug("User has no settings for '%s', using default setting instead.", setting)
        userSetting = self.defaults.settings[setting]
        if type(userSetting) == 'nil' then
            self:Debug("There is no default setting for '%s'.", setting)
            return {}
        end
    end

    return settings[userSetting]
end

-- Values for ver first loading, or for resetting
SOFIA.defaults = {
    -- Debug option
    debug = false,

    -- Window settings
    window = {
        visible = true,
        point = 'TOPLEFT', x = 350, y = 700,
        width = 195, height = 390,
    },

    -- Roster data, sorted by realm and guild
    roster = {
        _whereis = {},
    },

    -- User-defined options
    settings = {
        sort = "level",
        size = "large",
    },
}

-- Load database and use default values if needed
function SOFIA:LoadDB()
    local currentversion = 050
    local db = SOFIADB or {}

    if type(db.debug) ~= 'boolean' then
        db.debug = self.defaults.debug
    end

    if not db.window then
        db.window = self.defaults.window
    end

    if not db.roster then
        db.roster = self.defaults.roster
    end

    if not db.settings then
        db.settings = self.defaults.settings
    end

    db.version = currentversion
    SOFIADB = db
    self.db = db
end

-- Apply all settings after loading or on-the-fly
function SOFIA:ApplySettings()
    self:ApplyWindowSettings()
    self:ApplyRosterSettings()
end

-- Utility frame dedicated to react to variable loading
local loader = CreateFrame("Frame", AddonName.."_DBLoader")
loader:RegisterEvent("VARIABLES_LOADED")
loader:SetScript("OnEvent", function (event)
    -- Load the DB or initialize to defaults, if loading for the first time
    SOFIA:LoadDB()

    -- Good practice to create window when variables are loaded, to avoid clunky behavior
    SOFIA:CreateWindow()

    SOFIA:ApplySettings()

    -- At first, the one and only player guaratanteed to be tracked is oneself
    local myself = SOFIA:GetPlayerByGUID(UnitGUID("player"))
    if myself then
        SOFIA:SetTagPoolPlayer(myself)
    end

    -- Good practice to query player information only when roster is linked to db
    SOFIA:StartGuildTimer()
    SOFIA:StartMyselfTimer()

--    SOFIAOptionsPanel_Init(SOFIA.OptionsPanel)

    loader:UnregisterEvent("VARIABLES_LOADED")
    SOFIA:Debug("Variables loaded and applied.")
end)
