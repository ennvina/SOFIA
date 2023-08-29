local AddonName, SOFIA = ...

-- Map between className and classFile
-- Key = className, Value = classFile
--
-- This map is necessary because GetFriendInfoByIndex returns the className, which is localized
-- We prefer the classFile which is language-agnostic, hence the need to map from name to file
--
-- The map is not necessary per se because we could loop through all classes every time
-- But because this lookup is somewhat heavy, it's much better to pre-compute a map once
local classMap = {}

local function UpdateAllFriends()
    C_FriendList.ShowFriends() -- Try to trigger a friend list update (may get answer next time)

    local realm = GetRealmName() or ""
    local nbFriends = C_FriendList and C_FriendList.GetNumFriends() or 0

    for i=1, nbFriends do
        local info = C_FriendList.GetFriendInfoByIndex(i)
        if info.connected then -- Cannot exploit information on logged out friends
            local name = select(1,strsplit("-", info.name))
            local classFile = info.className and classMap[info.className] or ''
            local guild = SOFIA:GetPlayerGuild(info.guid)

            SOFIA:SetPlayerInfo(info.guid, realm, name, classFile, guild, info.level)
        end
    end
end

function SOFIA:StartFriendTimer()
    -- Init classMap
    for i=1, GetNumClasses() do
        local className, classFile = GetClassInfo(i)
        if className and classFile then -- May be nil e.g., Death Knight (i==6) on Classic Era
            classMap[className] = classFile
        end
    end

    -- Request friend info on a regular basis
    C_Timer.NewTicker(11, function() UpdateAllFriends() end)

    -- Try to update all friends at start
    UpdateAllFriends()
end
