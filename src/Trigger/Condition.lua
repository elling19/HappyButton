local addonName, _ = ...


---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

local L = LibStub("AceLocale-3.0"):GetLocale(addonName, false)

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class Condition: AceModule
local Condition = addon:NewModule("Condition")

-- 创建自身触发器
---@return ConditionConfig
function Condition:New()
    ---@type ConditionConfig
    local condition = {}
    return condition
end