-- The GameEras age queries are UI-only. Read them here and hand the result to
-- gameplay through ExposedMembers, where the boost grant itself is executed.

local LEADER_QIAN = 'LEADER_QIAN_XUESEN'

local function log(msg)
    print('[ModernChina][QianAgeBridge] ' .. tostring(msg))
end

local function ageOf(eras, pid)
    local ok, heroic = pcall(function()
        return eras:HasHeroicGoldenAge(pid)
    end)
    if ok and heroic then return 'HEROIC' end

    local okGolden, golden = pcall(function()
        return eras:HasGoldenAge(pid)
    end)
    if okGolden and golden then return 'GOLDEN' end

    local okDark, dark = pcall(function()
        return eras:HasDarkAge(pid)
    end)
    if okDark and dark then return 'DARK' end
    return 'NORMAL'
end

local function isQian(pid)
    local cfg = pid ~= nil and PlayerConfigurations[pid]
    if cfg == nil then return false end
    local ok, leader = pcall(function()
        return cfg:GetLeaderTypeName()
    end)
    return ok and leader == LEADER_QIAN
end

local function aliveMajorIds()
    local ids = {}
    local ok, majors = pcall(function()
        return PlayerManager.GetAliveMajors()
    end)
    if ok and type(majors) == 'table' then
        for _, player in ipairs(majors) do
            local okId, pid = pcall(function() return player:GetID() end)
            if okId and type(pid) == 'number' then ids[#ids + 1] = pid end
        end
        return ids
    end

    for pid = 0, 63 do
        local player = Players[pid]
        if player ~= nil then
            local okAlive, alive = pcall(function() return player:IsAlive() end)
            local okMajor, major = pcall(function() return player:IsMajor() end)
            if okAlive and okMajor and alive and major then ids[#ids + 1] = pid end
        end
    end
    return ids
end

local function publish()
    local okEras, eras = pcall(function() return Game.GetEras() end)
    if not okEras or eras == nil then
        log('Game.GetEras unavailable; age bridge skipped')
        return
    end

    local shared = type(ExposedMembers) == 'table' and ExposedMembers or nil
    local api = shared and shared.ModernChina
    local events = shared and shared.GameEvents
    local pushed = 0

    for _, pid in ipairs(aliveMajorIds()) do
        if isQian(pid) then
            local age = ageOf(eras, pid)
            local ok = false
            if api ~= nil and type(api.ApplyQianAge) == 'function' then
                ok = pcall(api.ApplyQianAge, pid, age)
            end
            if not ok and events ~= nil and events.MC_QianAgeUpdate ~= nil then
                ok = pcall(function()
                    events.MC_QianAgeUpdate(pid, age)
                end)
            end
            if ok then pushed = pushed + 1 end
        end
    end

    if pushed > 0 then log('published age for ' .. tostring(pushed) .. ' Qian player(s)') end
end

local eventsToWatch = {
    'LoadScreenClose',
    'PlayerTurnStarted',
    'PlayerTurnStartComplete',
    'LocalPlayerTurnBegin',
    'PlayerEraChanged',
    'PlayerAgeChanged',
    'PlayerDarkAgeChanged',
}

for _, name in ipairs(eventsToWatch) do
    pcall(function()
        local evt = Events[name]
        if evt ~= nil and evt.Add ~= nil then
            evt.Add(function() pcall(publish) end)
        end
    end)
end

pcall(publish)
