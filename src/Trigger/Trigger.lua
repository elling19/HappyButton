local addonName, _ = ...


---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

local L = LibStub("AceLocale-3.0"):GetLocale(addonName, false)

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class Trigger: AceModule
local Trigger = addon:NewModule("Trigger")


-- 创建自身触发器
---@param title string | nil
---@return TriggerConfig
function Trigger:NewSelfTriggerConfig(title)
    ---@type SelfTriggerCondition
    local condition = {
        isLearned = true,
        count = 0,
    }
    ---@type TriggerConfig
    local triggerConfig = {
        id = U.String.GenerateID(),
        type = "self",
        condition = condition,
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

