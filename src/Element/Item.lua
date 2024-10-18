local addonName, _ = ...


---@class HappyToolkit: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

local E = addon:GetModule("Element", true)

---@class Item: E
local Item = addon:NewModule("Item", E)
