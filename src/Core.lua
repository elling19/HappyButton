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
    HbFrame:UpdateAllEframes("UNIT_AURA", {})
end)

---@type table<EventString, boolean> key表示事件名称，value表示是否循环监听
local registerEvents = {
    ["PLAYER_ENTERING_WORLD"] = true,           -- 读地图
    ["PLAYER_LOGIN"] = true,                    -- 登录
    ["UNIT_SPELLCAST_SUCCEEDED"] = true,        -- 施法成功
    ["SPELL_UPDATE_COOLDOWN"] = true,           -- 触发冷却
    ["PLAYER_REGEN_ENABLED"] = true,            -- 退出战斗事件
    ["PLAYER_EQUIPMENT_CHANGED"] = true,        -- 装备改变（物品、装备）
    ["SPELLS_CHANGED"] = true,                  -- 技能改变（技能）
    ["PLAYER_TALENT_UPDATE"] = true,            -- 天赋改变（技能）
    ["PLAYER_TARGET_CHANGED"] = true,           -- 目标改变（脚本、触发器）
    ["BAG_UPDATE"] = true,                      -- 背包物品改变(物品、装备)
    ["MODIFIER_STATE_CHANGED"] = true,          -- 修饰按键按下
    ["UPDATE_MOUSEOVER_UNIT"] = true,           -- 鼠标指向改变
    ["ZONE_CHANGED"] = true,                    -- 区域改变
    ["MOUNT_JOURNAL_USABILITY_CHANGED"] = true, -- 坐骑可用改变
    ["NEW_MOUNT_ADDED"] = true,                 -- 学会新的坐骑
    ["PET_BAR_UPDATE_COOLDOWN"] = true,         -- 宠物相关
    ["NEW_PET_ADDED"] = true,                   -- 学会新的宠物
    ["NEW_TOY_ADDED"] = true,                   -- 学会新的玩具
    ["ADDON_LOADED"] = false,                   -- 加载插件
    ["CVAR_UPDATE"] = false,                    -- 改变cvar
    ["PLAYER_REGEN_DISABLED"] = false,          -- 进入战斗事件
}

-- 需要更新图标的事件
---@type EventString[]
local updateEvents = {}
for e, needUpdate in pairs(registerEvents) do
    if needUpdate == true then
        table.insert(updateEvents, e)
    end
end

-- 限流事件
local throttlingEvents = {
    ["SPELL_UPDATE_COOLDOWN"] = {},
    ["BAG_UPDATE"] = {},
}

-- 延迟事件
local delayEvents = {
    ["UPDATE_MOUSEOVER_UNIT"] = true,
    ["UNIT_SPELLCAST_SUCCEEDED"] = true
}

-- 注册事件
function BarCore:Start()
    for event, _ in pairs(registerEvents) do
        BarCore.Frame:RegisterEvent(event)
    end
    -- BarCore.Frame:RegisterEvent("UNIT_AURA")
    BarCore.Frame:SetScript("OnEvent", function(_, event, ...)
        local args = { ... }
        if event == "PLAYER_LOGIN" then
            BarCore:Initial()
        end
        if event == "PLAYER_REGEN_DISABLED" then
            HbFrame:OnCombatEvent()
        end
        if event == "CVAR_UPDATE" then
            -- 如果用户修改了鼠标按下CVAR，需要通知按钮改变RegisterForClicks
            local cvar_name = args[1]
            if cvar_name == "ActionButtonUseKeyDown" then
                HbFrame:UpdateRegisterForClicks()
            end
        end
        -- 当玩家技能发生改变的时候，如果配置文件中有需要更新的ItemAttr，则更新ItemAttr（这是由于API无法获取非当前玩家拥有技能的信息）
        if event == "PLAYER_TALENT_UPDATE" or "SPELLS_CHANGED" then
            HbFrame:CompleteItemAttr()
        end
        for _, e in ipairs(updateEvents) do
            if e == event then
                if throttlingEvents[e] ~= nil then
                    if throttlingEvents[e].waiting ~= true then
                        HbFrame:UpdateAllEframes(e, args)
                        throttlingEvents[e].waiting = true
                        C_Timer.After(0.2, function()
                            throttlingEvents[e].waiting = false
                        end)
                    end
                elseif delayEvents[e] ~= nil then
                    C_Timer.After(0.1, function()
                        HbFrame:UpdateAllEframes(e, args)
                    end)
                else
                    HbFrame:UpdateAllEframes(e, args)
                end
                break
            end
        end
    end)
end
