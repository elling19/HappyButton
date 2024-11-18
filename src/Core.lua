local addonName, _ = ... ---@type string, table
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class HbFrame: AceModule
local HbFrame = addon:GetModule("HbFrame")

---@class BarCore: AceModule
local BarCore = addon:NewModule("BarCore")

BarCore.Frame = CreateFrame("Frame")

-- 初始化配置
function BarCore:Initial()
    HbFrame:Initial()
end

-- 使用定时器替代UNIT_AURA事件执行
C_Timer.NewTicker(0.5, function()
    HbFrame:UpdateAllEframes("UNIT_AURA")
end)

-- 注册事件
function BarCore:Start()
    -- 注册相关事件以立即更新宏（如玩家登录或冷却更新）
    BarCore.Frame:RegisterEvent("ADDON_LOADED")             -- 插件加载
    BarCore.Frame:RegisterEvent("PLAYER_LOGIN")             -- 登录
    BarCore.Frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")    -- 触发冷却
    BarCore.Frame:RegisterEvent("PLAYER_REGEN_DISABLED")    -- 进入战斗事件
    BarCore.Frame:RegisterEvent("PLAYER_REGEN_ENABLED")     -- 退出战斗事件
    BarCore.Frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED") -- 装备改变（物品、装备）
    BarCore.Frame:RegisterEvent("SPELLS_CHANGED")           -- 技能改变（技能）
    BarCore.Frame:RegisterEvent("PLAYER_TALENT_UPDATE")     -- 天赋改变（技能）
    BarCore.Frame:RegisterEvent("PLAYER_TARGET_CHANGED")    -- 目标改变（脚本、触发器）
    BarCore.Frame:RegisterEvent("BAG_UPDATE")               -- 背包物品改变(物品、装备)
    -- BarCore.Frame:RegisterEvent("UNIT_AURA")
    BarCore.Frame:SetScript("OnEvent", function(self, event, arg1)
        if event == "PLAYER_LOGIN" then
            BarCore:Initial()
        end
        if event == "SPELL_UPDATE_COOLDOWN" or
            event == "PLAYER_EQUIPMENT_CHANGED" or
            event == "SPELLS_CHANGED" or
            event == "PLAYER_TALENT_UPDATE" or
            event == "PLAYER_TARGET_CHANGED" or
            event == "BAG_UPDATE" or
            event == "PLAYER_REGEN_ENABLED"
        then
            HbFrame:UpdateAllEframes(event)
        end
        if event == "PLAYER_REGEN_DISABLED" then
            HbFrame:OnCombatEvent()
        end
    end)
end
