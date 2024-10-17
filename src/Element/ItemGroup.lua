local addonName, _ = ...


---@class HappyToolkit: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

local Element = addon:GetModule("Element", true)

---@class CONST: AceModule
local const = addon:GetModule('CONST')


---@class ItemGroup: Element
---@field items Item[]
local ItemGroup = addon:NewModule("ItemGroup", Element)