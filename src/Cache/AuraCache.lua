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
---@field remainingTimes number[]
---@field exist true | nil

---@class AuraCache: AceModule
---@field cache table<UnitId, table<SpellID, AuraCacheTaskInfo>>
---@field data table<UnitId, table<SpellID, AuraCacheInfo> | nil>
local AuraCache = addon:NewModule("AuraCache")

function AuraCache:Initial()
    AuraCache.cache = {player = {}, target = {}}
    AuraCache.data = {player = {}, target = nil}
    AuraCache.data.player = AuraCache:InitialTargetAura("player")
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
function AuraCache:Update(event, eventArgs)
    if event == "PLAYER_TARGET_CHANGED" then
        if UnitExists("target") then
            AuraCache.data.target = AuraCache:InitialTargetAura("target")
        else
            AuraCache.data.target = nil
        end
        AuraCache:CreateTargetAllTickerTasks("target")
        return
    end
    if event == "UNIT_AURA" then
        local target = eventArgs[1]
        -- 目前只处理玩家和目标的光环
        if target ~= "player" and target ~= "target" then
            return
        end
        -- 没有AuraCache:InitialTargetAura方法，则全部更新，因为UnitAura无法获取instanceID来更新
        if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then
            AuraCache.data[target] = AuraCache:InitialTargetAura(target)
            AuraCache:CreateTargetAllTickerTasks(target)
            return
        end
        -- 如果target数据为空，则更新全部
        if AuraCache.data[target] == nil then
            AuraCache.data[target] = AuraCache:InitialTargetAura(target)
            AuraCache:CreateTargetAllTickerTasks(target)
            return
        end
        ---@type UnitAuraUpdateInfo
        local updateInfo = eventArgs[2]
        if updateInfo.isFullUpdate == true then
            AuraCache.data[target] = AuraCache:InitialTargetAura(target)
            AuraCache:CreateTargetAllTickerTasks(target)
        end
        if updateInfo.addedAuras then
            for _, aura in ipairs(updateInfo.addedAuras) do
                local hbAura = AuraCache:AuraDataToHbAura(aura)
                AuraCache.data[target][hbAura.spellId] = hbAura
                AuraCache:CreateTargetTickerTask(target, hbAura.spellId)
            end
        end
        if updateInfo.updatedAuraInstanceIDs then
            for _, _instanceID in ipairs(updateInfo.updatedAuraInstanceIDs) do
                for spellId, aura in pairs(AuraCache.data[target]) do
                    if aura.instanceID == _instanceID then
                        local auraInfo = C_UnitAuras.GetAuraDataByAuraInstanceID(target, _instanceID)
                        if auraInfo then
                            AuraCache.data[target][spellId] = AuraCache:AuraDataToHbAura(auraInfo)
                        end
                        AuraCache:CreateTargetTickerTask(target, spellId)
                        break
                    end
                end
            end
        end
        if updateInfo.removedAuraInstanceIDs then
            for _, _instanceID in ipairs(updateInfo.removedAuraInstanceIDs) do
                for spellId, aura in pairs(AuraCache.data[target]) do
                    if aura.instanceID == _instanceID then
                        AuraCache.data[target][spellId] = nil
                        AuraCache:CreateTargetTickerTask(target, spellId)
                        break
                    end
                end
            end
        end
    end
end


--- 按aura来更新目标任务
---@param target UnitId
---@param spellId SpellID
function AuraCache:CreateTargetTickerTask(target, spellId)
    local task = AuraCache.cache[target][spellId]
    if task == nil then
        return
    end
    local auraInfo = AuraCache.data[target][spellId]
    if auraInfo == nil then
         -- 如果没有这个buff了，立即执行
        addon:SendMessage(const.EVENT.HB_UNIT_AURA, target, spellId)
        return
    end
    -- 是否需要马上发送消息
    local needSendMessageNow = false
    if task.exist then
        needSendMessageNow = true
    end
    if task.remainingTimes then
        for _, remainingTime in ipairs(task.remainingTimes) do
            local realRemainingTime = auraInfo.expirationTime - GetTime() -- 计算出当前aura剩余时间，去和触发器的剩余时间比较
            if realRemainingTime > remainingTime then
                -- 当前剩余时间 - 触发器预设剩余时间 + 0.05秒延迟
                C_Timer.NewTimer(realRemainingTime - remainingTime + 0.05, function ()
                    addon:SendMessage(const.EVENT.HB_UNIT_AURA, target, auraInfo.spellId)
                end)
            else
                -- 如果时间已经过了，那么立即执行
                needSendMessageNow = true
            end
        end
    end
    if needSendMessageNow == true then
        addon:SendMessage(const.EVENT.HB_UNIT_AURA, target, auraInfo.spellId)
    end
end

-- 更新目标全部任务
---@param target UnitId
function AuraCache:CreateTargetAllTickerTasks(target)
    local tasks = AuraCache.cache[target]
    if tasks == nil then
        return
    end
    for spellID, task in pairs(tasks) do
        -- 立即触发一次
        addon:SendMessage(const.EVENT.HB_UNIT_AURA, target, spellID)
        local aura = AuraCache.data[target] and AuraCache.data[target][spellID] or nil
        if aura then
            for _, remainingTime in ipairs(task.remainingTimes) do
                local realRemainingTime = aura.expirationTime - GetTime()
                if realRemainingTime > remainingTime then
                    -- 当前剩余时间 - 触发器预设剩余时间 + 0.05秒延迟
                    C_Timer.NewTimer(realRemainingTime - remainingTime + 0.05, function ()
                        addon:SendMessage(const.EVENT.HB_UNIT_AURA, target, spellID)
                    end)
                end
            end
        end
    end
end


-- 从缓存中获取数据，如果没有可以返回nil
---@param target UnitId
---@param spellId SpellID
---@return AuraCacheInfo | nil
function AuraCache:Get(target, spellId)
    if AuraCache.cache[target][spellId] == nil then
        ---@type AuraCacheTaskInfo
        AuraCache.cache[target][spellId] = {
            remainingTimes = {},
            exist = nil,
        }
    end
    return AuraCache.data[target] and AuraCache.data[target][spellId] or nil
end

-- 在缓存中添加新的追踪信息
---@param target UnitId
---@param spellId SpellID
---@param remainingTime number | nil
---@param exist boolean | nil
function AuraCache:PutTask(target, spellId, remainingTime, exist)
    if AuraCache.cache[target][spellId] == nil then
        ---@type AuraCacheTaskInfo
        AuraCache.cache[target][spellId] = {
            remainingTimes = {},
            exist = true,
        }
    end
    -- 将需要监听内容添加到缓存中
    if exist ~= nil then
        AuraCache.cache[target][spellId].exist = true
    end
    if remainingTime ~= nil then
        if U.Table.IsInArray(AuraCache.cache[target][spellId].remainingTimes, remainingTime) == false then
            table.insert(AuraCache.cache[target][spellId].remainingTimes, remainingTime)
        end
    end
end