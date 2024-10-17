local addonName, _ = ...  ---@type string, table

---@class HappyToolkit: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class MainFrame: AceModule
local MainFrame = addon:GetModule("MainFrame")

---@class AloneBarsFrame: AceModule
local AloneBarsFrame = addon:GetModule("AloneBarsFrame")

-- 主窗口右键事件
addon:RegisterMessage(const.EVENT.EXIT_EDIT_MODE, function()
    addon.G.IsEditMode = false
    MainFrame:CloseEditMode()
    AloneBarsFrame:CloseEditMode()
end)

