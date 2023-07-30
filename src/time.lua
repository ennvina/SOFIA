local AddonName, SOFIA = ...

local timeAtLogin = GetServerTime()

function SOFIA:GetCurrentTime()
    return GetServerTime()
end

-- Return the number of secs since login or since reload ui
function SOFIA:ElapsedSinceLogin()
    return self:GetCurrentTime() - timeAtLogin
end

function SOFIA:HumanReadableDateTime(serverTime)
    local secsAgo = self:GetCurrentTime()-serverTime
    if secsAgo < 0 then
        return "soon™"
    end

    -- Omit date if too recent
    if secsAgo < 60 then
        return "a few seconds ago"
    end

    if secsAgo < 120 then
        return "one minute ago"
    end

    if secsAgo < 3600 then
        return string.format("%d minutes ago", math.floor(secsAgo/60))
    end

    -- Add date if too old (more than 60 minutes)
    local time = date("%H:%M", serverTime)

    local myDay = math.floor(serverTime/86400) -- 86400 = number of secs in a day
    local today = math.floor(self:GetCurrentTime()/86400)
    local daysAgo = today-myDay
    if daysAgo <= 0 then
        return string.format("today %s", time)
    elseif daysAgo == 1 then
        return string.format("yesterday %s", time)
    elseif daysAgo < 31 then
        return string.format("%d days ago %s", daysAgo, time)
    elseif  daysAgo < 365 then
        return string.format("%s %s", date("%m/%d", serverTime), time)
    else
        return string.format("%s %s", date("%Y/%m/%d", serverTime), time)
    end
end
