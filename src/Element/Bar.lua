local addonName, _ = ...


---@class HappyToolkit: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

local Element = addon:GetModule("Element", true)

---@class CONST: AceModule
local const = addon:GetModule('CONST')


---@class Bar: Element
---@field icon string | number | nil
---@field items Item[]
local Bar = addon:NewModule("Bar", Element)