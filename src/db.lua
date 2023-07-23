local AddonName, SOFIA = ...

-- Shortcuts for colors, not saved in db
SOFIA.colors = {
    ['black']       = CreateColor(0, 0, 0),
    ['white']       = CreateColor(1, 1, 1),

    ['hcRed']       = CreateColor(1, 0, 0),
    ['darkRed']     = CreateColor(0.7, 0, 0),
}

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
        fontFace = "Fonts\\ARIALN.ttf",
        fontSize = 12,
    },
}

-- Values for ver first loading, or for resetting
SOFIA.defaults = {
    window = {
        visible = true,
        point = 'TOPLEFT', x = 350, y = 700,
        width = 150, height = 350,
    },
    roster = {},
}

-- Load database and use default values if needed
function SOFIA.LoadDB(self)
    local currentversion = 020
    local db = SOFIADB or {}

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
function SOFIA.ApplySettings(self)
    self:ApplyWindowSettings(self.db.window)
    self:ApplyRosterSettings(self.db.roster)
end

-- Utility frame dedicated to react to variable loading
local loader = CreateFrame("Frame", AddonName.."_DBLoader")
loader:RegisterEvent("VARIABLES_LOADED")
loader:SetScript("OnEvent", function (event)
    SOFIA:LoadDB()
    SOFIA:CreateWindow() -- Good practice to create window when variables are loaded, to avoid clunky behavior
    SOFIA:ApplySettings()
    SOFIA:StartRosterTimer() -- Good practice to query roster information only when roster is linked to db
--    SOFIAOptionsPanel_Init(SOFIA.OptionsPanel)
    loader:UnregisterEvent("VARIABLES_LOADED")
end)
