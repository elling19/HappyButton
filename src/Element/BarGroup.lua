local addonName, _ = ...

---@class HappyActionBar: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

local E = addon:GetModule("Element", true)

---@class BarGroup: E
local BarGroup = addon:NewModule("BarGroup", E)
