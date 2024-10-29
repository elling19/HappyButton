local addonName, _ = ...


---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class Trigger: AceModule
local Trigger = addon:NewModule("Trigger")


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

---@param triggerType TriggerType
---@return table<string, type>
function Trigger:GetConditions(triggerType)
    if triggerType == "self" then
        return {
            count = "number",
            isLearned = "boolean"
        }
    end
    if triggerType == "aura" then
        return {
            remainingTime = "number",
        }
    end
    return {}
end