local addonName, _ = ...


---@class HappyActionBar: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

local E = addon:GetModule("Element", true)

---@class Bar: E
local Bar = addon:NewModule("Bar", E)