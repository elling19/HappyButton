local addonName, _ = ...


---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class Api: AceModule
local Api = addon:GetModule("Api")

---@class AuraCacheInfo
---@field name string
---@field instanceID number
---@field expirationTime number
---@field spellId SpellID
---@field charges number
---@field isHarmful boolean
---@field isHelpful boolean


---@class AuraCacheTaskInfo
---@field triggers {remainingTime: number, exist: boolean}[]

---@class AuraCacheTargetInfo
---@field auras table<SpellID, AuraCacheInfo> | nil
---@field tasks table<SpellID, AuraCacheTaskInfo>


---@class AuraCache: AceModule
---@field player AuraCacheTargetInfo
---@field target AuraCacheTargetInfo
local AuraCache = addon:NewModule("AuraCache")



function AuraCache:Initial()
    ---@type AuraCacheTargetInfo
    AuraCache.player = {auras = {}, tasks = {}}
    ---@type AuraCacheTargetInfo
    AuraCache.target = {auras = nil, tasks = {}}
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
            local auras = AuraCache:InitialTargetAura("target")
            AuraCache.target.auras = auras
        else
            AuraCache.target.auras = {}
        end
        AuraCache:CreateTargetAllTickerTasks("target")
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
            AuraCache:CreateTargetAllTickerTasks(target)
            return event, eventArgs
        end
        -- 如果target数据为空，则更新全部
        if AuraCache[target].auras == nil then
            AuraCache[target] = AuraCache:InitialTargetAura(target)
            AuraCache:CreateTargetAllTickerTasks(target)
            return event, eventArgs
        end
        ---@type UnitAuraUpdateInfo
        local updateInfo = eventArgs[2]
        if updateInfo.isFullUpdate == true then
            AuraCache[target] = AuraCache:InitialTargetAura(target)
            AuraCache:CreateTargetAllTickerTasks(target)
        end
        if updateInfo.addedAuras then
            for _, aura in ipairs(updateInfo.addedAuras) do
                local hbAura = AuraCache:AuraDataToHbAura(aura)
                AuraCache[target][hbAura.spellId] = hbAura
                AuraCache:CreateTargetTickerTask(hbAura.spellId, target)
            end
        end
        if updateInfo.updatedAuraInstanceIDs then
            for _, _instanceID in ipairs(updateInfo.updatedAuraInstanceIDs) do
                for spellId, aura in pairs(AuraCache[target]) do
                    if aura.instanceID == _instanceID then
                        AuraCache[target][spellId] = C_UnitAuras.GetAuraDataByAuraInstanceID(target, _instanceID)
                        AuraCache:CreateTargetTickerTask(spellId, target)
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
                        AuraCache:CreateTargetTickerTask(spellId, target)
                        break
                    end
                end
            end
        end
    end
    return event, eventArgs
end


--- 按aura来更新目标任务
---@param spellId SpellID
---@param target UnitId
function AuraCache:CreateTargetTickerTask(spellId, target)
    ---@type AuraCacheTaskInfo
    local task = AuraCache[target].tasks[spellId]
    if task == nil then
        return
    end
    local auraInfo = AuraCache[target].auras[spellId]
    for _, trigger in ipairs(task.triggers) do
        if auraInfo then
            if trigger.remainingTime then
                local realRemainingTime = auraInfo.expirationTime - GetTime() -- 计算出当前aura剩余时间，去和触发器的剩余时间比较
                if realRemainingTime > trigger.remainingTime then
                    -- 当前剩余时间 - 触发器预设剩余时间 + 0.05秒延迟
                    C_Timer.NewTicker(realRemainingTime - trigger.remainingTime + 0.05, function ()
                        print("HB_UNIT_AURA", target, auraInfo.spellId)
                    end)
                else
                    -- 如果时间已经过了，那么立即执行
                    print("HB_UNIT_AURA", target, auraInfo.spellId)
                end
            end
        else
            -- 如果没有这个buff了，立即执行
            print("HB_UNIT_AURA", target, auraInfo.spellId)
        end
    end
end

-- 更新目标全部任务
---@param target UnitId
function AuraCache:CreateTargetAllTickerTasks(target)
    ---@type table<SpellID, AuraCacheTaskInfo>
    local tasks = AuraCache[target].tasks
    if tasks == nil then
        return
    end
    for spellID, task in pairs(tasks) do
        -- 立即触发一次
        print("HB_UNIT_AURA", target, spellID)
        local aura = AuraCache[target].auras[spellID]
        if aura then
            for _, trigger in ipairs(task.triggers) do
                if trigger.remainingTime then
                    local realRemainingTime = aura.expirationTime - GetTime()
                    if realRemainingTime > trigger.remainingTime then
                        -- 当前剩余时间 - 触发器预设剩余时间 + 0.05秒延迟
                        C_Timer.NewTicker(realRemainingTime - trigger.remainingTime + 0.05, function ()
                            print("HB_UNIT_AURA", target, aura.spellId)
                        end)
                    end
                end
            end
        end
    end
end

-- 添加任务
---@param target UnitId
---@param spellID SpellID
---@param remainingTime number
---@param exist boolean
function AuraCache:AddTask(target, spellID, remainingTime, exist)
    if AuraCache[target] == nil then
        return
    end
    if AuraCache[target].tasks[spellID] == nil then
        ---@type AuraCacheTaskInfo
        AuraCache[target].tasks[spellID] = {
            triggers = {{remainingTime = remainingTime, exist = exist}, }
        }
    else
        table.insert(AuraCache[target].tasks[spellID].triggers, {remainingTime = remainingTime, exist = exist})
    end
end

-- 移除任务
---@param target UnitId
---@param spellID SpellID
---@param remainingTime number
---@param exist boolean
function AuraCache:RemoveTask(target, spellID, remainingTime, exist)
    if AuraCache[target] == nil then
        return
    end
    if AuraCache[target].tasks[spellID] == nil then
        return
    end
    if AuraCache[target].tasks[spellID].triggers == nil then
        AuraCache[target].tasks[spellID] = nil
    end
    for i = #AuraCache[target].tasks[spellID].triggers, 1, -1 do
        local trigger = AuraCache[target].tasks[spellID].triggers[i]
        if trigger.remainingTime == remainingTime and trigger.exist == exist then
            table.remove(AuraCache[target].tasks[spellID].triggers, i)  -- 删除元素
            break
        end
    end
    if #AuraCache[target].tasks[spellID].triggers == 0 then
        AuraCache[target].tasks[spellID] = nil
    end
end