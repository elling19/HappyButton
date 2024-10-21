local addonName, _ = ...  ---@type string, table
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

local L = LibStub("AceLocale-3.0"):GetLocale(addonName, false)

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class HtFrame: AceModule
local HtFrame = addon:GetModule("HtFrame")

---@class ToolkitCore: AceModule
local ToolkitCore = addon:NewModule("ToolkitCore")

ToolkitCore.Frame = CreateFrame("Frame")

-- 初始化配置
function ToolkitCore:Initial()
    HtFrame:Initial()
end

-- 注册事件
function ToolkitCore:Start()
    -- 注册相关事件以立即更新宏（如玩家登录或冷却更新）
    ToolkitCore.Frame:RegisterEvent("ADDON_LOADED")  -- 插件加载
    ToolkitCore.Frame:RegisterEvent("PLAYER_LOGIN")  -- 登录
    ToolkitCore.Frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")  -- 触发冷却
    ToolkitCore.Frame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- 进入战斗事件
    ToolkitCore.Frame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- 退出战斗事件
    ToolkitCore.Frame:SetScript("OnEvent", function(self, event, arg1)
        if event == "PLAYER_LOGIN" then
            ToolkitCore:Initial()
        end
        if event == "ADDON_LOADED" and arg1 == addonName then
        end
        if event == "SPELL_UPDATE_COOLDOWN" then
        end
        if event == "PLAYER_REGEN_DISABLED" then
            HtFrame:OnCombatEvent()
        end
        if event == "PLAYER_REGEN_ENABLED" then
            HtFrame:OutCombatEvent()
        end
    end)
end
