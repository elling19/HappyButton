local addonName, _ = ...


---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class Api: AceModule
local Api = addon:GetModule("Api")

---@class AuraCache: AceModule
---@field player table<number, AuraCacheInfo>
---@field target table<number, AuraCacheInfo>
---@field playerTask table<number, number[]>  -- 玩家aura剩余时间<spellID, remainingTime[]>
---@field targetTask table<number, number[]>  -- 目标aura剩余时间<spellID, remainingTime[]>
local AuraCache = addon:NewModule("AuraCache")

---@class AuraCacheInfo
---@field name string
---@field instanceID number
---@field expirationTime number
---@field spellId number
---@field charges number
---@field isHarmful boolean
---@field isHelpful boolean

function AuraCache:Initial()
    AuraCache.player = {}
    AuraCache.playerTask = {}
    AuraCache.targetTask = {}
end

---@param auraData  AuraData
---@return AuraCacheInfo
function AuraCache:AuraDataToHbAura(auraData)
    ---@type AuraCacheInfo
    local hbAura = {
        name = auraData.name,
        instanceID = auraData.auraInstanceID,
        expirationTime = auraData.expirationTime,
        spellId = auraData.spellId,
        charges = auraData.charges,
        isHarmful = auraData.isHarmful,
        isHelpful = auraData.isHelpful,
    }
    return hbAura
end

-- 完全更新一个target的所有光环信息
---@param target UnitId
---@return table<number, AuraCacheInfo>
function AuraCache:InitialTargetAura(target)
    ---@type table<number, AuraCacheInfo>
    local auras = {}
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 300 do
            local aura = C_UnitAuras.GetAuraDataByIndex(target, i)
            if aura == nil then
                break
            end
            auras[aura.spellId] = AuraCache:AuraDataToHbAura(aura)
        end
    else
        for i = 1, 150 do
            ---@diagnostic disable-next-line: deprecated
            local name, icon, count, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod = UnitBuff(target, i)
            if spellId == nil then
                break
            end
            ---@type AuraCacheInfo
            local auraData = {
                name = name,
                instanceID = -1,
                expirationTime = expirationTime,
                spellId = spellId,
                charges = count,
                isHarmful = false,
                isHelpful = true
            }
            auras[spellId] = auraData
        end
        for i = 1, 150 do
            ---@diagnostic disable-next-line: deprecated
            local name, icon, count, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod = UnitDebuff(target, i)
            if spellId == nil then
                break
            end
            ---@type AuraCacheInfo
            local auraData = {
                name = name,
                instanceID = -1,
                expirationTime = expirationTime,
                spellId = spellId,
                charges = count,
                isHarmful = true,
                isHelpful = false
            }
            auras[spellId] = auraData
        end
    end
    return auras
end

---@param event EventString
---@param eventArgs any
---@return EventString, any
function AuraCache:Update(event, eventArgs)
    if event == "PLAYER_TARGET_CHANGED" then
        if UnitExists("target") then
            AuraCache.target = AuraCache:InitialTargetAura("target")
        else
            AuraCache.target = nil
        end
        return event, eventArgs
    end
    if event == "UNIT_AURA" then
        local target = eventArgs[1]
        -- 目前只处理玩家和目标的光环
        if target ~= "player" and target ~= "target" then
            return event, eventArgs
        end
        -- 没有AuraCache:InitialTargetAura方法，则全部更新，因为UnitAura无法获取instanceID来更新
        if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then
            AuraCache[target] = AuraCache:InitialTargetAura(target)
            return event, eventArgs
        end
        -- 如果target数据为空，则更新全部
        if AuraCache[target] == nil then
            AuraCache[target] = AuraCache:InitialTargetAura(target)
            return event, eventArgs
        end
        ---@type UnitAuraUpdateInfo
        local updateInfo = eventArgs[2]
        if updateInfo.isFullUpdate == true then
            AuraCache[target] = AuraCache:InitialTargetAura(target)
        end
        if updateInfo.addedAuras then
            for _, aura in ipairs(updateInfo.addedAuras) do
                local hbAura = AuraCache:AuraDataToHbAura(aura)
                AuraCache[target][hbAura.spellId] = hbAura
            end
        end
        if updateInfo.updatedAuraInstanceIDs then
            for _, _instanceID in ipairs(updateInfo.updatedAuraInstanceIDs) do
                for spellId, aura in pairs(AuraCache[target]) do
                    if aura.instanceID == _instanceID then
                        AuraCache[target][spellId] = C_UnitAuras.GetAuraDataByAuraInstanceID(target, _instanceID)
                        break
                    end
                end
            end
        end
        if updateInfo.removedAuraInstanceIDs then
            for _, _instanceID in ipairs(updateInfo.removedAuraInstanceIDs) do
                for spellId, aura in pairs(AuraCache[target]) do
                    if aura.instanceID == _instanceID then
                        AuraCache[target][spellId] = nil
                        break
                    end
                end
            end
        end
    end
    return event, eventArgs
end

function AuraCache:CollectTask()
    
    
end
