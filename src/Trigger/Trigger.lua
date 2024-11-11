local addonName, _ = ...


---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class Api: AceModule
local Api = addon:GetModule("Api")

---@class Trigger: AceModule
local Trigger = addon:NewModule("Trigger")

local L = LibStub("AceLocale-3.0"):GetLocale(addonName, false)

-- 创建自身触发器
---@return TriggerConfig
function Trigger:NewSelfTriggerConfig()
    ---@type TriggerConfig
    local triggerConfig = {
        id = U.String.GenerateID(),
        type = "self",
        confine = {}
    }
    return triggerConfig
end


---@param config TriggerConfig
---@return SelfTriggerConfig
function Trigger:ToSelfTriggerConfig(config)
    return config --- @type SelfTriggerConfig
end


---@param config TriggerConfig
---@return AuraTriggerConfig
function Trigger:ToAuraTriggerConfig(config)
    return config --- @type AuraTriggerConfig
end

-- 获取触发器名称
---@param triggerType  TriggerType
---@return string
function Trigger:GetTriggerName(triggerType)
    if triggerType == "self" then
        return L["Self Trigger"]
    end
    if triggerType == "aura" then
        return L["Aura Trigger"]
    end
    return "Unknown"
end


-- 根据触发器类型获取触发器条件列表
-- ！！！返回列表的key值务必在ElementCallback函数的返回值中！！！
---@param triggerType TriggerType
---@return table<string, type>
function Trigger:GetConditions(triggerType)
    if triggerType == "self" then
        return {
            count = "number",
            isLearned = "boolean",
            isUsable = "boolean"
        } ---@type table<SelfTriggerCond, type>
    end
    if triggerType == "aura" then
        return {
            remainingTime = "number",
            targetIsEnemy = "boolean"
        } ---@type table<AuraTriggerCond, type>
    end
    return {}
end

-- 根据触发器类型获取触发器条件选项
---@param triggerType TriggerType
---@return table<string, string>
function Trigger:GetConditionsOptions(triggerType)
    local conditions = self:GetConditions(triggerType)
    local options = {}
    for k, cond in pairs(conditions) do
        options[k] = L[k]
    end
    return options
end


---@param triggerConfig TriggerConfig
---@return table<AuraTriggerCond, any>
function Trigger:GetAuraTriggerCond(triggerConfig)
    ---@type table<AuraTriggerCond, any>
    local result = {}
    local trigger = Trigger:ToAuraTriggerConfig(triggerConfig)
    if not trigger.confine then
        return result
    end
    local target = trigger.confine.target or "player"
    local auraId = trigger.confine.spellId
    if not auraId then
        return result
    end
    local filter
    if trigger.confine.type == "buff" then
        filter = "HELPFUL"
    end
    if trigger.confine.type == "defbuff" then
        filter = "HARMFUL"
    end
    if UnitExists(target) and UnitIsEnemy("player", target) then
        result.targetIsEnemy = true
    else
        result.targetIsEnemy = false
    end
    for i = 1, 100 do
        local aura = Api.GetBuffDataByIndex(target, i, filter)
        if aura and aura.spellId == auraId then
            result.remainingTime = aura.expirationTime - GetTime()
            break
        end
    end
    if result.remainingTime == nil then
        result.remainingTime = 0
    end
    return result
end