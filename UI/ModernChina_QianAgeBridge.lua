-- The GameEras age queries are UI-only. Read them here and hand the result to
-- gameplay through the supported EXECUTE_SCRIPT channel.

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

local function publish()
    local okEras, eras = pcall(function() return Game.GetEras() end)
    if not okEras or eras == nil then
        log('Game.GetEras unavailable; age bridge skipped')
        return
    end

    local pid = Game.GetLocalPlayer()
    if pid == nil or pid < 0 or not isQian(pid) then return end
    local player = Players[pid]
    if player == nil then return end

    local okActive, active = pcall(function() return player:IsTurnActive() end)
    if okActive and not active then return end

    local age = ageOf(eras, pid)
    local ok = pcall(function()
        UI.RequestPlayerOperation(pid, PlayerOperations.EXECUTE_SCRIPT, {
            OnStart = 'MC_QianAgeUpdate',
            Age = age,
        })
    end)
    if ok then
        log('published age ' .. tostring(age) .. ' for player ' .. tostring(pid))
    else
        log('age publish failed for player ' .. tostring(pid))
    end
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
