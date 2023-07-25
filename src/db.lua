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
        minWidth = 100,
        minHeight = 100,
        maxWidth = 800,
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
        height = 24,
        border = 1,
        marginLeft = 5,
        marginRight = 10,
        className = "GameFontNormalLarge",
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

-- Values for ver first loading, or for resetting
SOFIA.defaults = {
    -- Debug option
    debug = false,

    -- Window settings
    window = {
        visible = true,
        point = 'TOPLEFT', x = 350, y = 700,
        width = 150, height = 300,
    },

    -- Roster data, sorted by realm and guild
    roster = {
        _whereis = {},
    },
}

-- Load database and use default values if needed
function SOFIA:LoadDB()
    local currentversion = 020
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

    db.version = currentversion
    SOFIADB = db
    self.db = db
end

-- Apply all settings after loading or on-the-fly
function SOFIA:ApplySettings()
    self:ApplyWindowSettings(self.db.window)
    self:ApplyRosterSettings(self.db.roster)
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
