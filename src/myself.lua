local AddonName, SOFIA = ...

local function RefreshMyself()
    -- @todo implement a security against guildless tests, which happen quite often (during startup, loading screens...)
    local guid, realm, name, class = UnitGUID("player"), GetRealmName(), UnitName("player"), select(2,UnitClass("player")) -- Intrinsics
    local guild = select(1, GetGuildInfo("player")) -- Guild info
    local level, progress = UnitLevel("player"), (UnitXPMax("player") > 0) and (UnitXP("player")/UnitXPMax("player")) or nil -- Level
    local dead = UnitIsDeadOrGhost("player") -- Death status
    local isNew, whatChanged = SOFIA:SetPlayerInfo(guid, realm, name, class, guild, level, progress, dead)
end

local function OnEvent(frame, event, unit, ...)
    if event == "UNIT_HEALTH" then
        if UnitIsUnit(unit, "player") and UnitIsDeadOrGhost("player") then
            RefreshMyself()
        end
    elseif event == "PLAYER_XP_UPDATE" then
        if UnitIsUnit(unit, "player") then
            RefreshMyself()
        end
    elseif event == "PLAYER_GUILD_UPDATE" then
        if UnitIsUnit(unit, "player") then
            RefreshMyself()
        end
    end
end

local myselfTimerFrame = CreateFrame("Frame", AddonName.."_MyselfTimer")

function SOFIA:StartMyselfTimer()
    myselfTimerFrame:RegisterEvent("UNIT_HEALTH")
    myselfTimerFrame:RegisterEvent("PLAYER_XP_UPDATE")
    myselfTimerFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
    myselfTimerFrame:SetScript("OnEvent", OnEvent)

    -- Request own info on a regular basis
    -- There's no need to check too often because events are already tracked to update when something relevant happens
    C_Timer.NewTicker(10, RefreshMyself)

    -- Try in 2 secs, just in case
    C_Timer.NewTimer(2, RefreshMyself)
end
