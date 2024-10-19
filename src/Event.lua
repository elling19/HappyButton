local addonName, _ = ...  ---@type string, table

---@class HappyToolkit: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class HtFrame: AceModule
local HtFrame = addon:GetModule("HtFrame")

-- 主窗口右键事件
addon:RegisterMessage(const.EVENT.EXIT_EDIT_MODE, function()
    addon.G.IsEditMode = false
    HtFrame:CloseEditMode()
end)

