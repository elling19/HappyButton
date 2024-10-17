local addonName, _ = ...

---@class HappyToolkit: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

local Element = addon:GetModule("Element", true)


---@class CONST: AceModule
local const = addon:GetModule('CONST')


---@class BarGroup: Element
---@field bars Bar[]
local BarGroup = addon:NewModule("BarGroup", Element)


---@return BarGroup
function BarGroup:New()
    local obj = setmetatable({}, {__index = self})
    return obj
  end
