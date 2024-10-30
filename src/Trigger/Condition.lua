local addonName, _ = ...


---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class Condition: AceModule
local Condition = addon:NewModule("Condition")

-- 创建条件组
---@return ConditionGroupConfig
function Condition:NewGroup()
    ---@type ConditionGroupConfig
    local group = {
        conditions = {},
        expression = "%cond.1",
        effects = {}
    }
    return group
end

-- 创建自身触发器
---@return ConditionConfig
function Condition:NewCondition()
    ---@type ConditionConfig
    local condition = {}
    return condition
end

