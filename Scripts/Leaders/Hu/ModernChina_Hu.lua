-- =============================================================
-- Hu Jintao / 科学发展观
--   1. Improved Hu plots gain +1 to all six yields when adjacent to another
--      improved plot.
--   2. Every completed Congress grants a Builder.
--
-- Standalone Gameplay context.
-- =============================================================

local CIV_TYPE = 'CIVILIZATION_MODERN_CHINA'
local HU_LEADER = 'LEADER_HU'
local DISTRICT_CONGRESS = 'DISTRICT_CONGRESS'
local UNIT_BUILDER = 'UNIT_BUILDER'
local ADJACENT_IMPROVEMENT_PROPERTY = 'MC_HU_IMPROVEMENT_ADJACENT'

local function Log(msg)
    print('[ModernChina][Hu] ' .. tostring(msg))
end

local function Safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        Log('ERROR: ' .. tostring(err))
    end
    return ok
end

local function IsHu(pid)
    local cfg = pid ~= nil and PlayerConfigurations[pid]
    return cfg ~= nil
        and cfg:GetCivilizationTypeName() == CIV_TYPE
        and cfg:GetLeaderTypeName() == HU_LEADER
end

local function FindRow(collection, field, value)
    for row in collection() do
        if row[field] == value then return row end
    end
    return nil
end

local function HasAdjacentImprovement(plot)
    local neighbors = Map.GetAdjacentPlots(plot:GetX(), plot:GetY())
    for i = 1, 6 do
        local neighbor = neighbors[i]
        if neighbor ~= nil and neighbor:GetImprovementType() ~= -1 then
            return true
        end
    end
    return false
end

local function RefreshPlot(plot)
    if plot == nil then return end
    local value = 0
    if plot:GetImprovementType() ~= -1 and HasAdjacentImprovement(plot) then
        value = 1
    end

    local current = plot:GetProperty(ADJACENT_IMPROVEMENT_PROPERTY)
    if current == nil or current ~= value then
        plot:SetProperty(ADJACENT_IMPROVEMENT_PROPERTY, value)
    end
end

local function RefreshHuImprovements(pid)
    if not IsHu(pid) then return end
    local pPlayer = Players[pid]
    if pPlayer == nil then return end
    for _, city in pPlayer:GetCities():Members() do
        for _, plot in pairs(city:GetOwnedPlots() or {}) do
            RefreshPlot(plot)
        end
    end
end

local function RefreshAllHuPlayers()
    for _, pid in ipairs(PlayerManager.GetAliveIDs()) do
        if IsHu(pid) then
            Safe(RefreshHuImprovements, pid)
        end
    end
end

local function SpawnBuilder(pid, x, y)
    local pPlayer = Players[pid]
    if pPlayer == nil then return nil end
    local city = Cities.GetCityInPlot(x, y)
    if city == nil or city:GetOwner() ~= pid then return nil end

    local builder = FindRow(GameInfo.Units, 'UnitType', UNIT_BUILDER)
    if builder == nil then return nil end

    local unit = pPlayer:GetUnits():Create(builder.Index, city:GetX(), city:GetY())
    if unit ~= nil then return unit end

    local cityPlot = Map.GetPlot(city:GetX(), city:GetY())
    local neighbors = Map.GetAdjacentPlots(cityPlot:GetX(), cityPlot:GetY())
    for i = 1, 6 do
        local plot = neighbors[i]
        if plot ~= nil then
            unit = pPlayer:GetUnits():Create(builder.Index, plot:GetX(), plot:GetY())
            if unit ~= nil then return unit end
        end
    end
    return nil
end

local function OnDistrictConstructed(pid, districtType, x, y)
    if not IsHu(pid) then return end
    local district = GameInfo.Districts[districtType]
    if district == nil then
        district = FindRow(GameInfo.Districts, 'Index', districtType)
    end
    if district == nil or district.DistrictType ~= DISTRICT_CONGRESS then return end

    local unit = SpawnBuilder(pid, x, y)
    if unit ~= nil then
        Log(string.format('Congress completed at (%d,%d): Builder created', x, y))
    else
        Log(string.format('Congress completed at (%d,%d): no Builder spawn tile', x, y))
    end
end

local function Initialize()
    Log('=== script loading ===')
    Safe(function()
        GameEvents.OnDistrictConstructed.Add(function(pid, districtType, x, y)
            Safe(OnDistrictConstructed, pid, districtType, x, y)
        end)
    end)
    Safe(function()
        Events.ImprovementAddedToMap.Add(function()
            Safe(RefreshAllHuPlayers)
        end)
    end)
    Safe(function()
        Events.ImprovementRemovedFromMap.Add(function()
            Safe(RefreshAllHuPlayers)
        end)
    end)
    Safe(function()
        GameEvents.OnGameTurnStarted.Add(function()
            Safe(RefreshAllHuPlayers)
        end)
    end)
    Safe(function()
        Events.LoadScreenClose.Add(function()
            Safe(RefreshAllHuPlayers)
        end)
    end)
    Log('=== script initialized ===')
end

Safe(Initialize)
