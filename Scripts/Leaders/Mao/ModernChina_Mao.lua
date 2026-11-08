-- ============================================================
-- Mao / Zhu gameplay logic
--   1. 再造中华: first use of each government grants +1 Governor Title
--   2. 红军会师: first assignment of Zhu to a city grants a Red Army
--
-- This is a standalone Gameplay context. Do not call local functions from the
-- shared or Qian scripts; each AddGameplayScripts file has its own environment.
-- ============================================================

local CIV_TYPE    = 'CIVILIZATION_MODERN_CHINA'
local MAO_LEADER  = 'LEADER_MAO_MC'
local GOV_ZHU     = 'GOVERNOR_ZHU'
local UNIT_RED_ARMY = 'UNIT_RED_ARMY'
local KEY_USED_GOV = 'MC_USED_GOVERNMENTS'

local function Log(msg)
    print('[ModernChina][Mao] ' .. tostring(msg))
end

local function Safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        Log('ERROR: ' .. tostring(err))
    end
    return ok
end

local function IsModernChina(pid)
    local cfg = pid ~= nil and PlayerConfigurations[pid]
    return cfg ~= nil and cfg:GetCivilizationTypeName() == CIV_TYPE
end

local function IsMao(pid)
    local cfg = pid ~= nil and PlayerConfigurations[pid]
    return cfg ~= nil and cfg:GetLeaderTypeName() == MAO_LEADER
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

local function ResolveGovernorType(governorType)
    if governorType == nil then return nil end
    if type(governorType) == 'string' then return governorType end
    for row in GameInfo.Governors() do
        if row.Index == governorType then return row.GovernorType end
    end
    local row = GameInfo.Governors[governorType]
    return row and row.GovernorType or nil
end

local function GovUsed(pPlayer, govID)
    local used = Prop(pPlayer, KEY_USED_GOV, '|')
    return string.find(used, '|' .. tostring(govID) .. '|', 1, true) ~= nil
end

local function MarkGovUsed(pPlayer, govID)
    local used = Prop(pPlayer, KEY_USED_GOV, '|')
    if string.find(used, '|' .. tostring(govID) .. '|', 1, true) == nil then
        pPlayer:SetProperty(KEY_USED_GOV, used .. tostring(govID) .. '|')
    end
end

local function OnGovernmentChanged(pid, govID)
    if govID == nil or not IsModernChina(pid) or not IsMao(pid) then return end
    local pPlayer = Players[pid]
    if pPlayer == nil then return end
    if GovUsed(pPlayer, govID) then return end

    MarkGovUsed(pPlayer, govID)
    Safe(function() pPlayer:GetGovernors():ChangeGovernorPoints(1) end)
    Log(string.format('government first used: pid=%d gov=%s -> +1 governor title',
        pid, tostring(govID)))
end

local function OnGovernorAssigned(cityOwner, cityID, governorOwner, governorType)
    if ResolveGovernorType(governorType) ~= GOV_ZHU then return end
    if cityOwner == nil or not IsModernChina(cityOwner) or not IsMao(cityOwner) then return end

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
        Log('Zhu first assigned to ' .. tostring(city:GetName()) .. ' -> Red Army created')
    end
end

local function Initialize()
    Log('=== script loading ===')
    Safe(function()
        Events.GovernmentChanged.Add(function(pid, govID)
            Safe(OnGovernmentChanged, pid, govID)
        end)
    end)
    Safe(function()
        Events.GovernorAssigned.Add(function(cityOwner, cityID, governorOwner, governorType)
            Safe(OnGovernorAssigned, cityOwner, cityID, governorOwner, governorType)
        end)
    end)
    Log('=== script initialized ===')
end

Safe(Initialize)
