local addonName, _ = ...  ---@type string, table

---@class HappyToolkit: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class ToolkitCore: AceModule
local ToolkitCore = addon:GetModule("ToolkitCore")

ToolkitCore:Start()

-- -- 全局变量、提供给按键绑定使用
-- G_HAPPY_TOOLKIT = {}

-- -- 按键绑定
-- function G_HAPPY_TOOLKIT.RunWishByKeyBinding()
--     ToolkitCore:ToggleMainFrame()
-- end
