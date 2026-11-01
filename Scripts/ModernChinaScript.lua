-- ============================================================
-- 现代中国 (Modern China) — 游戏内脚本
--   1. 中国化：清蛮族营地 / 建贸易路线 / 新大陆城市 → 随机尤里卡或鼓舞
--   2. 代表大会：本局首次建成 → +1 总督点数
--   3. 毛「再造中华」：每首次使用一个政体 → +1 总督点数
--   4. 总督「朱」：红军会师（首次就位 → 获得一个红军）
--   5. 工作重心项目：限时城市增益 + 状态内的触发效果
--
-- 调试：Lua.log 里搜 [ModernChina]，每回合都会打印一行健康信息
-- ============================================================

local CIV_TYPE       = 'CIVILIZATION_MODERN_CHINA'
local LEADER_TYPE    = 'LEADER_MAO'
local QIAN_LEADER    = 'LEADER_QIAN_XUESEN'
local GOV_ZHU        = 'GOVERNOR_ZHU'
local DIST_CONGRESS  = 'DISTRICT_CONGRESS'
local UNIT_RED_ARMY  = 'UNIT_RED_ARMY'
local IMP_CAMP       = 'IMPROVEMENT_BARBARIAN_CAMP'

local KEY_USED_GOV   = 'MC_USED_GOVERNMENTS'
local KEY_CONGRESS   = 'MC_CONGRESS_DONE'
local KEY_QIAN_AGE   = 'MC_QIAN_AGE_REWARD'
local g_qianBridgeAge = {}

local WORK = {
    PROJECT_MC_WORK_ECONOMY = {
        turns = 20,
        label = 'LOC_PROJECT_MC_WORK_ECONOMY_NAME',
        up    = { 'MC_WORK_ECONOMY_GOLD_UP', 'MC_WORK_ECONOMY_FOOD_UP' },
        down  = { 'MC_WORK_ECONOMY_GOLD_DOWN', 'MC_WORK_ECONOMY_FOOD_DOWN' },
        state = 'ECONOMY',
    },
    PROJECT_MC_WORK_CULTURE = {
        turns = 20,
        label = 'LOC_PROJECT_MC_WORK_CULTURE_NAME',
        up    = { 'MC_WORK_CULTURE_CULTURE_UP', 'MC_WORK_CULTURE_FAITH_UP' },
        down  = { 'MC_WORK_CULTURE_CULTURE_DOWN', 'MC_WORK_CULTURE_FAITH_DOWN' },
        state = 'CULTURE',
    },
    PROJECT_MC_WORK_TECH = {
        turns = 10,
        label = 'LOC_PROJECT_MC_WORK_TECH_NAME',
        up    = { 'MC_WORK_TECH_SCIENCE_UP', 'MC_WORK_TECH_PRODUCTION_UP' },
        down  = { 'MC_WORK_TECH_SCIENCE_DOWN', 'MC_WORK_TECH_PRODUCTION_DOWN' },
        state = 'TECH',
    },
}

-- ============================================================
-- 基础工具
-- ============================================================

local function Log(msg)
    print('[ModernChina] ' .. tostring(msg))
end

local function IsModernChina(pid)
    local cfg = pid ~= nil and PlayerConfigurations[pid]
    return cfg ~= nil and cfg:GetCivilizationTypeName() == CIV_TYPE
end

local function IsMao(pid)
    local cfg = pid ~= nil and PlayerConfigurations[pid]
    return cfg ~= nil and cfg:GetLeaderTypeName() == LEADER_TYPE
end

local function IsQian(pid)
    local cfg = pid ~= nil and PlayerConfigurations[pid]
    return cfg ~= nil and cfg:GetLeaderTypeName() == QIAN_LEADER
end

local function FindRow(collection, field, value)
    for row in collection() do
        if row[field] == value then return row end
    end
    return nil
end

local function Safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        Log('ERROR: ' .. tostring(err))
    end
    return ok
end

-- 只写日志，不弹通知：gameplay 脚本里 pPlayer:AddNotification 不存在（会报 function expected instead of nil）
local function Notify(pid, message)
    Log('notify: ' .. tostring(message))
end

local function Prop(obj, key, default)
    local v = obj:GetProperty(key)
    if v == nil then return default end
    return v
end

function MCGetTurn()
    if Game.GetCurrentGameTurn ~= nil then return Game.GetCurrentGameTurn() end
    if Game.GetGameTurn ~= nil then return Game.GetGameTurn() end
    return 0
end

local function CountCityDistricts(city)
    local n = 0
    for _ in city:GetDistricts():Members() do n = n + 1 end
    return n
end

local function CountCityBuildings(city)
    local n = 0
    local buildings = city:GetBuildings()
    if buildings == nil then return 0 end
    for row in GameInfo.Buildings() do
        if buildings:HasBuilding(row.Index) then n = n + 1 end
    end
    return n
end

local function ResolveProjectType(projectID)
    if projectID == nil then return nil end
    if type(projectID) == 'string' then return projectID end
    for row in GameInfo.Projects() do
        if row.Index == projectID then return row.ProjectType end
    end
    local row = GameInfo.Projects[projectID]
    if row ~= nil then return row.ProjectType end
    return nil
end

local function ResolveGovernorType(governorType)
    if governorType == nil then return nil end
    if type(governorType) == 'string' then return governorType end
    for row in GameInfo.Governors() do
        if row.Index == governorType then return row.GovernorType end
    end
    local row = GameInfo.Governors[governorType]
    if row ~= nil then return row.GovernorType end
    return nil
end

-- ============================================================
-- 中国化：随机尤里卡 / 鼓舞
-- ============================================================

local g_techBoosts, g_civicBoosts, g_eraChrono = nil, nil, nil

local function InitBoostData()
    if g_techBoosts ~= nil then return end
    g_techBoosts, g_civicBoosts, g_eraChrono = {}, {}, {}
    for row in GameInfo.Boosts() do
        if row.TechnologyType ~= nil then g_techBoosts[row.TechnologyType] = true end
        if row.CivicType ~= nil then g_civicBoosts[row.CivicType] = true end
    end
    for row in GameInfo.Eras() do
        g_eraChrono[row.EraType] = row.ChronologyIndex
    end
    Log(string.format('boost data ready: techBoostable=%d civicBoostable=%d eras=%d',
        (function() local n = 0 for _ in pairs(g_techBoosts) do n = n + 1 end return n end)(),
        (function() local n = 0 for _ in pairs(g_civicBoosts) do n = n + 1 end return n end)(),
        (function() local n = 0 for _ in pairs(g_eraChrono) do n = n + 1 end return n end)()))
end

local function BoostSource()
    if BoostSources ~= nil and BoostSources.BOOST_SOURCE_GOODYHUT ~= nil then
        return BoostSources.BOOST_SOURCE_GOODYHUT
    end
    return 0
end

function MC_GiveRandomBoost(pid, iSource)
    if not IsModernChina(pid) then return end
    InitBoostData()
    local pPlayer = Players[pid]
    if pPlayer == nil then return end

    local pTechs   = pPlayer:GetTechs()
    local pCulture = pPlayer:GetCulture()
    local maxEra   = (pPlayer:GetEra() or 0) + 1

    local pool = {}
    for row in GameInfo.Technologies() do
        if not pTechs:HasTech(row.Index)
            and g_techBoosts[row.TechnologyType]
            and (g_eraChrono[row.EraType] or 0) <= maxEra then
            pool[#pool + 1] = { kind = 'T', index = row.Index, name = row.Name, key = row.TechnologyType }
        end
    end
    for row in GameInfo.Civics() do
        if not pCulture:HasCivic(row.Index)
            and g_civicBoosts[row.CivicType]
            and (g_eraChrono[row.EraType] or 0) <= maxEra then
            pool[#pool + 1] = { kind = 'C', index = row.Index, name = row.Name, key = row.CivicType }
        end
    end
    Log(string.format('give random boost: pid=%d era=%d pool=%d', pid, maxEra, #pool))
    if #pool == 0 then return false end

    local pick = pool[math.random(#pool)]
    local itemName = Locale.Lookup(pick.name)
    local src = iSource or BoostSource()

    if pick.kind == 'T' then
        if pTechs:HasBoostBeenTriggered(pick.index) then
            pTechs:SetResearchProgress(pick.index, pTechs:GetResearchCost(pick.index))
            Notify(pid, Locale.Lookup('LOC_MC_NOTIFY_TECH_UNLOCKED', itemName))
        else
            if not Safe(function() pTechs:TriggerBoost(pick.index, src) end) then
                -- TriggerBoost 失败就直接解锁，保证奖励一定生效
                pTechs:SetResearchProgress(pick.index, pTechs:GetResearchCost(pick.index))
                Notify(pid, Locale.Lookup('LOC_MC_NOTIFY_TECH_UNLOCKED', itemName))
            else
                Notify(pid, Locale.Lookup('LOC_MC_NOTIFY_TECH_BOOSTED', itemName))
            end
        end
        Log('  -> tech ' .. tostring(pick.key))
    else
        if pCulture:HasBoostBeenTriggered(pick.index) then
            pCulture:SetCulturalProgress(pick.index, pCulture:GetCultureCost(pick.index))
            Notify(pid, Locale.Lookup('LOC_MC_NOTIFY_CIVIC_UNLOCKED', itemName))
        else
            if not Safe(function() pCulture:TriggerBoost(pick.index, src) end) then
                pCulture:SetCulturalProgress(pick.index, pCulture:GetCultureCost(pick.index))
                Notify(pid, Locale.Lookup('LOC_MC_NOTIFY_CIVIC_UNLOCKED', itemName))
            else
                Notify(pid, Locale.Lookup('LOC_MC_NOTIFY_CIVIC_BOOSTED', itemName))
            end
        end
        Log('  -> civic ' .. tostring(pick.key))
    end
    return true
end

-- ============================================================
-- 蛮族营地跟踪
-- ============================================================

local g_campIndex = nil
local g_camps     = {}   -- [pid] = { ["x_y"] = {x, y} }

local function CampIndex()
    if g_campIndex == nil then
        local row = FindRow(GameInfo.Improvements, 'ImprovementType', IMP_CAMP)
        g_campIndex = row and row.Index or -1
        Log('camp improvement index = ' .. tostring(g_campIndex))
    end
    return g_campIndex
end

local function PlotKey(x, y)
    return tostring(x) .. '_' .. tostring(y)
end

local function ScanAllCamps()
    local now = {}
    local idx = CampIndex()
    if idx < 0 then return now end
    local w, h = Map.GetGridSize()
    for x = 0, w - 1 do
        for y = 0, h - 1 do
            local plot = Map.GetPlot(x, y)
            if plot ~= nil and plot:GetImprovementType() == idx then
                now[PlotKey(x, y)] = { x, y }
            end
        end
    end
    return now
end

-- 该玩家是否有单位在 (x,y) 或相邻格
local function HasUnitNear(pid, x, y)
    local plot = Map.GetPlot(x, y)
    if plot == nil then return false end
    local function CheckPlot(p)
        if p == nil then return false end
        for _, unit in ipairs(Units.GetUnitsInPlot(p)) do
            if unit ~= nil and unit:GetOwner() == pid then return true end
        end
        return false
    end
    if CheckPlot(plot) then return true end
    for dir = 0, 5 do
        if CheckPlot(plot:GetNeighborPlot(dir)) then return true end
    end
    return false
end

local function AwardCampClear(pid, x, y, reason)
    if not IsModernChina(pid) then return false end
    if not HasUnitNear(pid, x, y) then
        Log(string.format('camp gone at (%d,%d) [%s] but no unit of pid=%d nearby', x, y, tostring(reason), pid))
        return false
    end
    Log(string.format('camp cleared at (%d,%d) by pid=%d [%s]', x, y, pid, tostring(reason)))
    return MC_GiveRandomBoost(pid, nil) == true
end

local function OnImprovementRemoved(locX, locY, eOwner)
    local key = PlotKey(locX, locY)
    for pid, camps in pairs(g_camps) do
        if camps[key] ~= nil then
            if AwardCampClear(pid, locX, locY, 'event') then
                camps[key] = nil
            end
        end
    end
end

local function OnImprovementAdded(locX, locY, eImprovementType, eOwner)
    if eImprovementType ~= CampIndex() then return end
    for pid, _ in pairs(g_camps) do
        g_camps[pid][PlotKey(locX, locY)] = { locX, locY }
    end
end

-- 每回合兜底扫描（覆盖脚本加载前已存在的营地 / 事件没触发的情况）
local function CheckCamps(pid)
    local now  = ScanAllCamps()
    local prev = g_camps[pid]
    if prev == nil then
        g_camps[pid] = now
        Log(string.format('camp baseline pid=%d count=%d', pid, (function() local n = 0 for _ in pairs(now) do n = n + 1 end return n end)()))
        return
    end
    for key, pos in pairs(prev) do
        if now[key] == nil then
            if AwardCampClear(pid, pos[1], pos[2], 'poll') then
                prev[key] = nil
            end
        end
    end
    for key, pos in pairs(now) do
        prev[key] = pos
    end
    g_camps[pid] = prev
end

-- ============================================================
-- 贸易路线 / 新大陆城市 / 代表大会
-- ============================================================

local g_routes, g_cities, g_congress = {}, {}, {}

local function CountRoutes(pPlayer)
    local n = 0
    for _, city in pPlayer:GetCities():Members() do
        local routes = city:GetTrade():GetOutgoingRoutes()
        if routes ~= nil then n = n + #routes end
    end
    return n
end

local function CountPlayerDistricts(pPlayer, districtIndex)
    local n = 0
    for _, district in pPlayer:GetDistricts():Members() do
        if district:GetType() == districtIndex and district:IsComplete() then
            n = n + 1
        end
    end
    return n
end

local function GetCapitalContinent(pPlayer)
    local capital = pPlayer:GetCities():GetCapitalCity()
    if capital == nil then return nil end
    local plot = Map.GetPlot(capital:GetX(), capital:GetY())
    if plot == nil then return nil end
    return plot:GetContinentType()
end

local function CheckNewCities(pid)
    local pPlayer = Players[pid]
    local known  = g_cities[pid]
    local capCon = GetCapitalContinent(pPlayer)
    local now    = {}
    for _, city in pPlayer:GetCities():Members() do
        local id = city:GetID()
        now[id] = true
        if known ~= nil and known[id] == nil and capCon ~= nil then
            local plot = Map.GetPlot(city:GetX(), city:GetY())
            if plot ~= nil and plot:GetContinentType() ~= capCon then
                Log('new city on another continent: ' .. tostring(city:GetName()))
                MC_GiveRandomBoost(pid, nil)
            end
        end
    end
    g_cities[pid] = now
end

local function CheckTradeRoutes(pid)
    local pPlayer = Players[pid]
    local n = CountRoutes(pPlayer)
    local prev = g_routes[pid]
    if prev ~= nil and n > prev then
        Log(string.format('trade routes %d -> %d', prev, n))
        for _ = 1, (n - prev) do
            MC_GiveRandomBoost(pid, nil)
        end
    end
    g_routes[pid] = n
    return n
end

local function CheckCongress(pid)
    local pPlayer = Players[pid]
    local district = FindRow(GameInfo.Districts, 'DistrictType', DIST_CONGRESS)
    if district == nil then return 0 end
    local n = CountPlayerDistricts(pPlayer, district.Index)
    local prev = g_congress[pid]
    if prev ~= nil and n > prev then
        if not Prop(pPlayer, KEY_CONGRESS, false) then
            Safe(function() pPlayer:GetGovernors():ChangeGovernorPoints(1) end)
            pPlayer:SetProperty(KEY_CONGRESS, true)
            Notify(pid, Locale.Lookup('LOC_MC_NOTIFY_CONGRESS_BUILT'))
        end
    end
    g_congress[pid] = n
    return n
end

-- ============================================================
-- 政体：毛「再造中华」
-- ============================================================

local function GovUsed(pPlayer, govID)
    local s = Prop(pPlayer, KEY_USED_GOV, '|')
    return string.find(s, '|' .. tostring(govID) .. '|', 1, true) ~= nil
end

local function MarkGovUsed(pPlayer, govID)
    local s = Prop(pPlayer, KEY_USED_GOV, '|')
    if string.find(s, '|' .. tostring(govID) .. '|', 1, true) == nil then
        pPlayer:SetProperty(KEY_USED_GOV, s .. tostring(govID) .. '|')
    end
end

local function OnGovernmentChanged(pid, govID)
    if not IsModernChina(pid) or not IsMao(pid) then return end
    if govID == nil then return end
    local pPlayer = Players[pid]
    if pPlayer == nil then return end
    Log(string.format('government changed pid=%d gov=%s', pid, tostring(govID)))
    if GovUsed(pPlayer, govID) then return end
    MarkGovUsed(pPlayer, govID)
    Safe(function() pPlayer:GetGovernors():ChangeGovernorPoints(1) end)
    Notify(pid, Locale.Lookup('LOC_MC_NOTIFY_NEW_GOVERNMENT'))
end

-- ============================================================
-- 总督「朱」：红军会师
-- ============================================================

local function OnGovernorAssigned(cityOwner, cityID, governorOwner, governorType)
    if ResolveGovernorType(governorType) ~= GOV_ZHU then return end
    if cityOwner == nil or not IsModernChina(cityOwner) then return end
    local pPlayer = Players[cityOwner]
    if pPlayer == nil then return end
    local city = pPlayer:GetCities():FindID(cityID)
    if city == nil then return end

    local key = 'MC_ZHU_ARRIVED_' .. tostring(cityID)
    if Prop(city, key, false) then return end
    city:SetProperty(key, true)

    local unitRow = FindRow(GameInfo.Units, 'UnitType', UNIT_RED_ARMY)
    if unitRow == nil then return end
    local unit = pPlayer:GetUnits():Create(unitRow.Index, city:GetX(), city:GetY())
    if unit ~= nil then
        Log('Zhu arrived at city ' .. tostring(city:GetName()) .. ' -> spawn Red Army')
        Notify(cityOwner, Locale.Lookup('LOC_MC_NOTIFY_RED_ARMY_JOINED'))
    end
end

-- ============================================================
-- 工作重心
-- ============================================================

local function BuffKey(state, suffix)
    return 'MC_WORK_' .. state .. '_' .. suffix
end

local function ApplyModifiers(obj, list)
    for _, id in ipairs(list) do
        Safe(function() obj:AttachModifierByID(id) end)
    end
end

local function StartWorkState(pid, city, projectType)
    local def = WORK[projectType]
    if def == nil then return end
    local endTurn = Prop(city, BuffKey(def.state, 'END'), -1)
    if endTurn >= 0 then
        ApplyModifiers(city, def.down)
    end
    city:SetProperty(BuffKey(def.state, 'END'), MCGetTurn() + def.turns)
    ApplyModifiers(city, def.up)
    if def.state == 'ECONOMY' then
        city:SetProperty('MC_WORK_ECONOMY_DISTRICTS', CountCityDistricts(city))
        city:SetProperty('MC_WORK_ECONOMY_BUILDINGS', CountCityBuildings(city))
    end
    Notify(pid, Locale.Lookup('LOC_MC_NOTIFY_WORK_STARTED', Locale.Lookup(def.label), def.turns))
end

local function OnCityProjectCompleted(pid, cityID, projectID)
    if not IsModernChina(pid) then return end
    local pPlayer = Players[pid]
    if pPlayer == nil then return end
    local city = pPlayer:GetCities():FindID(cityID)
    if city == nil then return end

    local projectType = ResolveProjectType(projectID)
    if projectType == nil then return end
    Log(string.format('project completed pid=%d city=%s project=%s', pid, tostring(city:GetName()), tostring(projectType)))

    local cultureEnd = Prop(city, BuffKey('CULTURE', 'END'), -1)
    if cultureEnd >= 0 and MCGetTurn() <= cultureEnd and math.random(100) <= 25 then
        Safe(function() pPlayer:AttachModifierByID('MC_WORK_GRANT_RELIC') end)
    end

    if WORK[projectType] ~= nil then
        StartWorkState(pid, city, projectType)
    end
end

local function TickWorkStates(pid)
    local pPlayer = Players[pid]
    local turn = MCGetTurn()
    for _, city in pPlayer:GetCities():Members() do
        for _, def in pairs(WORK) do
            local endTurn = Prop(city, BuffKey(def.state, 'END'), -1)
            if endTurn >= 0 and turn > endTurn then
                city:SetProperty(BuffKey(def.state, 'END'), -1)
                ApplyModifiers(city, def.down)
            end
        end
        local econEnd = Prop(city, BuffKey('ECONOMY', 'END'), -1)
        if econEnd >= 0 and turn <= econEnd then
            local dNow = CountCityDistricts(city)
            local bNow = CountCityBuildings(city)
            local dPrev = Prop(city, 'MC_WORK_ECONOMY_DISTRICTS', dNow)
            local bPrev = Prop(city, 'MC_WORK_ECONOMY_BUILDINGS', bNow)
            local gained = math.max(0, dNow - dPrev) + math.max(0, bNow - bPrev)
            if gained > 0 then
                for _ = 1, gained do
                    Safe(function() pPlayer:AttachModifierByID('MC_WORK_ADD_TRADE_CAPACITY') end)
                end
                city:SetProperty('MC_WORK_ECONOMY_DISTRICTS', dNow)
                city:SetProperty('MC_WORK_ECONOMY_BUILDINGS', bNow)
            end
        end
    end
end

local function OnUnitCreated(pid, unitID, unitType)
    if not IsModernChina(pid) then return end
    local pPlayer = Players[pid]
    if pPlayer == nil then return end
    local unit = UnitManager.GetUnit(pid, unitID)
    if unit == nil then return end
    local info = GameInfo.Units[unit:GetType()]
    if info == nil then return end
    if info.FormationClass ~= 'FORMATION_CLASS_LAND_COMBAT'
        and info.FormationClass ~= 'FORMATION_CLASS_NAVAL'
        and info.FormationClass ~= 'FORMATION_CLASS_AIR' then
        return
    end
    local city = Cities.GetCityInPlot(unit:GetX(), unit:GetY())
    if city == nil or city:GetOwner() ~= pid then return end
    local endTurn = Prop(city, BuffKey('TECH', 'END'), -1)
    if endTurn < 0 or MCGetTurn() > endTurn then return end

    local points = math.floor((info.Cost or 0) * 0.2)
    if points <= 0 then return end
    local classType = 'GREAT_PERSON_CLASS_GENERAL'
    if info.FormationClass == 'FORMATION_CLASS_NAVAL' then
        classType = 'GREAT_PERSON_CLASS_ADMIRAL'
    end
    local cls = FindRow(GameInfo.GreatPersonClasses, 'GreatPersonClassType', classType)
    if cls == nil then return end
    Safe(function() pPlayer:GetGreatPeoplePoints():ChangePointsTotal(cls.Index, points) end)
end

-- ============================================================
-- 钱学森「战略科学家」：时代开始时授予当前时代全部对应加成
-- ============================================================

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
    if ageKind ~= 'GOLDEN'
        and ageKind ~= 'DARK'
        and ageKind ~= 'HEROIC' then
        return false
    end
    g_qianBridgeAge[pid] = ageKind

    local eraType = CurrentEraType()
    if eraType == nil then
        Log('Qian age reward skipped: current era type unavailable')
        return false
    end

    local signature = tostring(Game.GetEras():GetCurrentEra()) .. ':' .. ageKind
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
    Log(string.format('Qian age reward: pid=%d era=%s age=%s tech=%d civic=%d',
        pid, tostring(eraType), tostring(ageKind), techCount, civicCount))
    return true
end

local function RegisterQianAgeBridge()
    local shared = ExposedMembers
    if type(shared) ~= 'table' then return end
    if type(shared.ModernChina) ~= 'table' then
        shared.ModernChina = {}
    end
    shared.ModernChina.ApplyQianAge = function(pid, age)
        return GrantQianAgeRewards(pid, age)
    end
    -- Let the UI event channel call gameplay code even if direct exposure is unavailable.
    shared.GameEvents = GameEvents
    GameEvents.MC_QianAgeUpdate.Add(function(pid, age)
        GrantQianAgeRewards(pid, age)
    end)
end

-- ============================================================
-- 主循环
-- ============================================================

local function OnGameTurnStarted(turn)
    Safe(InitBoostData)
    for _, pid in ipairs(PlayerManager.GetAliveIDs()) do
        if IsModernChina(pid) then
            local routes = -1
            Safe(function() CheckCamps(pid) end)
            Safe(function() routes = CheckTradeRoutes(pid) end)
            Safe(function() CheckNewCities(pid) end)
            local congress = 0
            Safe(function() congress = CheckCongress(pid) end)
            Safe(function() TickWorkStates(pid) end)
            local camps = 0
            if g_camps[pid] ~= nil then
                for _ in pairs(g_camps[pid]) do camps = camps + 1 end
            end
            Log(string.format('tick turn=%s pid=%d camps=%d routes=%s congress=%d',
                tostring(turn), pid, camps, tostring(routes), congress))
        end
        if IsQian(pid) then
            local age = g_qianBridgeAge[pid]
            if age ~= nil then
                Safe(function() GrantQianAgeRewards(pid, age) end)
            end
        end
    end
end

local function Initialize()
    Log('=== script loading ===')
    Safe(function() math.randomseed(MCGetTurn() * 7919 + 13) end)
    Safe(InitBoostData)
    Safe(RegisterQianAgeBridge)
    Safe(function() GameEvents.OnGameTurnStarted.Add(OnGameTurnStarted) end)
    Safe(function() Events.GovernmentChanged.Add(function(a, b) Safe(OnGovernmentChanged, a, b) end) end)
    Safe(function() Events.GovernorAssigned.Add(function(a, b, c, d) Safe(OnGovernorAssigned, a, b, c, d) end) end)
    Safe(function() Events.CityProjectCompleted.Add(function(a, b, c) Safe(OnCityProjectCompleted, a, b, c) end) end)
    Safe(function() GameEvents.UnitCreated.Add(function(a, b, c) Safe(OnUnitCreated, a, b, c) end) end)
    Safe(function() Events.ImprovementRemovedFromMap.Add(function(a, b, c) Safe(OnImprovementRemoved, a, b, c) end) end)
    Safe(function() Events.ImprovementAddedToMap.Add(function(a, b, c, d) Safe(OnImprovementAdded, a, b, c, d) end) end)
    Log('=== script initialized ===')
end

Safe(Initialize)
