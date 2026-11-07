-- ============================================================
-- Qian Xuesen / 战略科学家
--   1. Golden / Dark / Heroic Age rewards
--   2. Chemistry unlocks Nuclear Fission and Combined Arms
--   3. Computers unlocks Nuclear Fusion
--
-- Standalone Gameplay context. It deliberately does not depend on functions
-- declared in the shared or Mao scripts.
-- ============================================================

local QIAN_LEADER = 'LEADER_QIAN_XUESEN'
local KEY_QIAN_AGE = 'MC_QIAN_AGE_REWARD'

local TECH_CHEMISTRY = 'TECH_CHEMISTRY'
local TECH_COMPUTERS = 'TECH_COMPUTERS'
local TECH_NUCLEAR_FISSION = 'TECH_NUCLEAR_FISSION'
local TECH_NUCLEAR_FUSION = 'TECH_NUCLEAR_FUSION'
local TECH_COMBINED_ARMS = 'TECH_COMBINED_ARMS'

local g_techBoosts, g_civicBoosts = nil, nil
local g_qianBridgeAge = {}

local function Log(msg)
    print('[ModernChina][Qian] ' .. tostring(msg))
end

local function Safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        Log('ERROR: ' .. tostring(err))
    end
    return ok
end

local function IsQian(pid)
    local cfg = pid ~= nil and PlayerConfigurations[pid]
    return cfg ~= nil and cfg:GetLeaderTypeName() == QIAN_LEADER
end

local function Prop(obj, key, default)
    local value = obj:GetProperty(key)
    if value == nil then return default end
    return value
end

local function FindRow(collection, field, value)
    for row in collection() do
        if row[field] == value then return row end
    end
    return nil
end

local function InitBoostData()
    if g_techBoosts ~= nil then return end
    g_techBoosts, g_civicBoosts = {}, {}
    for row in GameInfo.Boosts() do
        if row.TechnologyType ~= nil then g_techBoosts[row.TechnologyType] = true end
        if row.CivicType ~= nil then g_civicBoosts[row.CivicType] = true end
    end
end

local function BoostSource()
    if BoostSources ~= nil and BoostSources.BOOST_SOURCE_GOODYHUT ~= nil then
        return BoostSources.BOOST_SOURCE_GOODYHUT
    end
    return 0
end

local function CurrentEraType()
    local eras = Game.GetEras()
    if eras == nil then return nil end
    local eraIndex = eras:GetCurrentEra()
    local eraRow = GameInfo.Eras[eraIndex]
    if eraRow == nil then
        for row in GameInfo.Eras() do
            if row.Index == eraIndex then
                eraRow = row
                break
            end
        end
    end
    return eraRow and eraRow.EraType or nil
end

local function GrantQianAgeRewards(pid, ageKind)
    if not IsQian(pid) then return false end
    local pPlayer = Players[pid]
    if pPlayer == nil then return false end

    ageKind = tostring(ageKind or ''):upper()
    if ageKind ~= 'GOLDEN' and ageKind ~= 'DARK' and ageKind ~= 'HEROIC' then
        return false
    end
    g_qianBridgeAge[pid] = ageKind

    local eraType = CurrentEraType()
    local eras = Game.GetEras()
    if eraType == nil or eras == nil then
        Log('age reward skipped: current era unavailable')
        return false
    end

    local signature = tostring(eras:GetCurrentEra()) .. ':' .. ageKind
    if Prop(pPlayer, KEY_QIAN_AGE, '') == signature then return false end

    InitBoostData()
    local pTechs = pPlayer:GetTechs()
    local pCulture = pPlayer:GetCulture()
    local source = BoostSource()
    local techCount, civicCount = 0, 0

    if ageKind ~= 'DARK' then
        for row in GameInfo.Technologies() do
            if row.EraType == eraType
                and g_techBoosts[row.TechnologyType]
                and not pTechs:HasTech(row.Index)
                and not pTechs:HasBoostBeenTriggered(row.Index) then
                if Safe(function() pTechs:TriggerBoost(row.Index, source) end) then
                    techCount = techCount + 1
                end
            end
        end
    end

    if ageKind ~= 'GOLDEN' then
        for row in GameInfo.Civics() do
            if row.EraType == eraType
                and g_civicBoosts[row.CivicType]
                and not pCulture:HasCivic(row.Index)
                and not pCulture:HasBoostBeenTriggered(row.Index) then
                if Safe(function() pCulture:TriggerBoost(row.Index, source) end) then
                    civicCount = civicCount + 1
                end
            end
        end
    end

    pPlayer:SetProperty(KEY_QIAN_AGE, signature)
    Log(string.format('age reward: pid=%d era=%s age=%s tech=%d civic=%d',
        pid, tostring(eraType), tostring(ageKind), techCount, civicCount))
    return true
end

local function CompleteTechByType(pTechs, technologyType)
    local row = FindRow(GameInfo.Technologies, 'TechnologyType', technologyType)
    if row == nil or pTechs:HasTech(row.Index) then return false end
    return Safe(function()
        pTechs:SetTech(row.Index, false)
    end)
end

local function GrantQianStrategicUnlocks(pid)
    if not IsQian(pid) then return false end
    local pPlayer = Players[pid]
    if pPlayer == nil then return false end

    local pTechs = pPlayer:GetTechs()
    local chemistry = FindRow(GameInfo.Technologies, 'TechnologyType', TECH_CHEMISTRY)
    local computers = FindRow(GameInfo.Technologies, 'TechnologyType', TECH_COMPUTERS)
    local changed = false

    if chemistry ~= nil and pTechs:HasTech(chemistry.Index) then
        changed = CompleteTechByType(pTechs, TECH_NUCLEAR_FISSION) or changed
        changed = CompleteTechByType(pTechs, TECH_COMBINED_ARMS) or changed
    end
    if computers ~= nil and pTechs:HasTech(computers.Index) then
        changed = CompleteTechByType(pTechs, TECH_NUCLEAR_FUSION) or changed
    end

    if changed then
        Log('strategic technology chain unlocked for pid=' .. tostring(pid))
    end
    return changed
end

local function OnResearchCompleted(pid, technologyIndex, canceled)
    if canceled == true or canceled == 1 then return end
    if IsQian(pid) then
        GrantQianStrategicUnlocks(pid)
    end
end

local function RegisterQianAgeBridge()
    GameEvents.MC_QianAgeUpdate.Add(function(pid, params)
        local age = type(params) == 'table' and params.Age or params
        GrantQianAgeRewards(pid, age)
    end)
end

local function OnGameTurnStarted(turn)
    for _, pid in ipairs(PlayerManager.GetAliveIDs()) do
        if IsQian(pid) then
            local age = g_qianBridgeAge[pid]
            if age ~= nil then
                Safe(function() GrantQianAgeRewards(pid, age) end)
            end
            Safe(function() GrantQianStrategicUnlocks(pid) end)
        end
    end
end

local function Initialize()
    Log('=== script loading ===')
    Safe(InitBoostData)
    Safe(RegisterQianAgeBridge)
    Safe(function()
        Events.ResearchCompleted.Add(function(pid, technologyIndex, canceled)
            Safe(OnResearchCompleted, pid, technologyIndex, canceled)
        end)
    end)
    Safe(function() GameEvents.OnGameTurnStarted.Add(OnGameTurnStarted) end)
    Log('=== script initialized ===')
end

Safe(Initialize)
