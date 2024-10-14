local _, HT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("HappyToolkit", false)

local U = HT.Utils

---@type ToolkitGUI
local ToolkitGUI = HT.ToolkitGUI

---@class ToolkitCore
---@field Frame table
---@field Initial fun(): nil
---@field ToggleToolkitGUI fun(): nil
---@field Start fun(): nil
local ToolkitCore = {
    Frame = CreateFrame("Frame"),
}

-- 初始化配置
function ToolkitCore.Initial()
    -- 初始化SavedVariables配置信息
    ToolkitGUI.Initial()
end

-- 切换GUI显示状态
function ToolkitCore.ToggleToolkitGUI()
    if ToolkitGUI.IsOpen == false then
        if not InCombatLockdown() then
            ToolkitGUI.ShowWindow()
        else
            U.PrintInfoText(L["You cannot use this in combat."])
        end
    else
        ToolkitGUI.HideWindow()
    end
end

-- 注册事件
function ToolkitCore.Start()
    -- 注册相关事件以立即更新宏（如玩家登录或冷却更新）
    ToolkitCore.Frame:RegisterEvent("ADDON_LOADED")  -- 插件加载
    ToolkitCore.Frame:RegisterEvent("PLAYER_LOGIN")  -- 登录
    ToolkitCore.Frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")  -- 触发冷却
    ToolkitCore.Frame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- 进入战斗事件
    ToolkitCore.Frame:SetScript("OnEvent", function(self, event, arg1)
        if event == "PLAYER_LOGIN" then
            ToolkitCore.Initial()
        end
        if event == "ADDON_LOADED" and arg1 == "HappyToolkit" then
        end
        if event == "SPELL_UPDATE_COOLDOWN" then
        end
        if event == "PLAYER_REGEN_DISABLED" then
            ToolkitGUI.HideWindow()
        end
    end)
end

HT.ToolkitCore = ToolkitCore