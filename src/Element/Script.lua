local addonName, _ = ...


---@class HappyToolkit: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

local Element = addon:GetModule("Element", true)

---@class CONST: AceModule
local const = addon:GetModule('CONST')


---@class Item: Element
---@field script string | nil
local Script = addon:NewModule("Script", Element)