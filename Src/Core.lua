local addonName, _ = ... ---@type string, table
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class HbFrame: AceModule
local HbFrame = addon:GetModule("HbFrame")

---@class PlayerCache: AceModule
local PlayerCache = addon:GetModule("PlayerCache")

---@class AttachFrameCache: AceModule
local AttachFrameCache = addon:GetModule("AttachFrameCache")

---@class ItemCache: AceModule
local ItemCache = addon:GetModule("ItemCache")

---@class BarCore: AceModule
local BarCore = addon:NewModule("BarCore")

BarCore.Frame = CreateFrame("Frame")

BarCore.IsInitialized = false

-- 初始化
function BarCore:Initial()
    PlayerCache:Initial()
    AttachFrameCache:Initial()
    ItemCache:Initial()
    HbFrame:Initial()
end

function BarCore:EnsureInitial()
    if self.IsInitialized then
        return
    end
    if not addon.db then
        return
    end
    self:Initial()
    self.IsInitialized = true
end

-- 事件配置
---@class EventRegisterConfig
---@field update boolean 是否触发按钮更新
---@field interval number | nil 限流间隔（秒），nil表示不限流
---@field delay boolean | nil 是否延迟到下一帧执行更新

---@type table<EventString, EventRegisterConfig>
local registerEvents = {
    ["ADDON_LOADED"] = { update = false },                               -- 加载插件
    ["PLAYER_LOGIN"] = { update = true },                                -- 登录
    ["PLAYER_ENTERING_WORLD"] = { update = true },                       -- 进入世界/读地图

    ["PLAYER_REGEN_DISABLED"] = { update = false },                      -- 进入战斗，战斗相关事件不限流
    ["PLAYER_REGEN_ENABLED"] = { update = true },                        -- 退出战斗，战斗相关事件不限流
    ["SPELL_UPDATE_COOLDOWN"] = { update = true, interval = 0.05 },      -- 触发冷却，需刷新图标冷却计时
    ["SPELL_UPDATE_CHARGES"] = { update = true },                        -- 技能充能改变，战斗相关事件不限流
    ["SPELL_UPDATE_USABLE"] = { update = true },                         -- 技能可用性改变，战斗相关事件不限流
    ["SPELLS_CHANGED"] = { update = true },                              -- 技能改变
    ["PLAYER_TALENT_UPDATE"] = { update = true },                        -- 天赋改变

    ["BAG_UPDATE"] = { update = true, interval = 0.20 },                 -- 背包物品改变
    ["BAG_UPDATE_DELAYED"] = { update = true, interval = 0.20 },         -- 背包延迟更新（含邮箱取件后）
    ["BAG_UPDATE_COOLDOWN"] = { update = true, interval = 0.05 },        -- 背包物品冷却变化
    ["PLAYER_EQUIPMENT_CHANGED"] = { update = true },                    -- 装备改变

    ["PLAYER_TARGET_CHANGED"] = { update = true },                       -- 目标改变
    ["UPDATE_MOUSEOVER_UNIT"] = { update = true, interval = 0.03, delay = true }, -- 鼠标指向改变
    ["MODIFIER_STATE_CHANGED"] = { update = true, interval = 0.03 },     -- 修饰按键按下
    ["ZONE_CHANGED"] = { update = true },                                -- 区域改变

    ["MOUNT_JOURNAL_USABILITY_CHANGED"] = { update = true },             -- 坐骑可用改变
    ["NEW_MOUNT_ADDED"] = { update = true },                             -- 学会新的坐骑
    ["PET_BAR_UPDATE_COOLDOWN"] = { update = true },                     -- 宠物相关
    ["NEW_PET_ADDED"] = { update = true },                               -- 学会新的宠物
    ["NEW_TOY_ADDED"] = { update = true },                               -- 学会新的玩具
    ["TOYS_UPDATED"] = { update = true },                                -- 玩具盒数据更新

    ["CVAR_UPDATE"] = { update = false },                                -- 改变 cvar
}

---@type table<EventString, {waiting: boolean, hasPending: boolean, pendingArgs: any[]|nil}>
local throttleStates = {}

-- 临时调试：输出指定事件是否触发
local debugEvents = {
    ["BAG_UPDATE_DELAYED"] = true,
    ["SPELL_UPDATE_USABLE"] = true,
    ["TOYS_UPDATED"] = true,
}

---@param event EventString
---@param eventArgs any[]
function BarCore:HandleEventSideEffects(event, eventArgs)
    if event == "ADDON_LOADED" and eventArgs[1] == addonName then
        BarCore:EnsureInitial()
    end

    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        BarCore:EnsureInitial()
    end

    if event == "PLAYER_ENTERING_WORLD" and (eventArgs[1] == true or eventArgs[2] == true) then
        C_Timer.After(0.3, function()
            HbFrame:UpdateAllEframes("PLAYER_ENTERING_WORLD", {})
        end)
    end

    if event == "PLAYER_REGEN_DISABLED" then
        HbFrame:OnCombatEvent()
    end

    if event == "PLAYER_REGEN_ENABLED" then
        HbFrame:OnCombatEvent()
    end

    if event == "CVAR_UPDATE" then
        local cvarName = eventArgs[1]
        if cvarName == "ActionButtonUseKeyDown" then
            HbFrame:UpdateRegisterForClicks()
        end
    end

    if event == "SPELL_UPDATE_COOLDOWN" then
        ItemCache:UpdateGcd()
    end

    -- 当玩家技能发生改变的时候，如果配置文件中有需要更新的 ItemAttr，则更新 ItemAttr
    if event == "PLAYER_TALENT_UPDATE" or event == "SPELLS_CHANGED" then
        HbFrame:CompleteItemAttr()
    end
end

---@param event EventString
---@param eventArgs any[]
---@param eventConfig EventRegisterConfig
function BarCore:DispatchUpdateEvent(event, eventArgs, eventConfig)
    local function DispatchNow()
        HbFrame:UpdateAllEframes(event, eventArgs)
    end

    if eventConfig.delay == true then
        C_Timer.After(0, function()
            DispatchNow()
        end)
    else
        DispatchNow()
    end
end

---@param event EventString
---@param eventArgs any[]
---@param eventConfig EventRegisterConfig
function BarCore:DispatchWithThrottle(event, eventArgs, eventConfig)
    local interval = eventConfig.interval or 0
    if interval <= 0 then
        self:DispatchUpdateEvent(event, eventArgs, eventConfig)
        return
    end

    local state = throttleStates[event]
    if state == nil then
        state = { waiting = false, hasPending = false, pendingArgs = nil }
        throttleStates[event] = state
    end

    if state.waiting == true then
        state.hasPending = true
        state.pendingArgs = eventArgs
        return
    end

    state.waiting = true
    self:DispatchUpdateEvent(event, eventArgs, eventConfig)

    C_Timer.After(interval, function()
        state.waiting = false
        if state.hasPending == true then
            local pendingArgs = state.pendingArgs or {}
            state.hasPending = false
            state.pendingArgs = nil
            BarCore:DispatchWithThrottle(event, pendingArgs, eventConfig)
        end
    end)
end

-- 注册事件
function BarCore:Start()
    for eventName, _ in pairs(registerEvents) do
        BarCore.Frame:RegisterEvent(eventName)
    end

    BarCore.Frame:SetScript("OnEvent", function(_, event, ...)
        local eventArgs = { ... }
        local eventConfig = registerEvents[event]

        if debugEvents[event] == true then
            -- U.Print.PrintInfoText("[Debug] Event fired: " .. event)
        end
        BarCore:HandleEventSideEffects(event, eventArgs)

        if eventConfig ~= nil and eventConfig.update == true then
            BarCore:DispatchWithThrottle(event, eventArgs, eventConfig)
        end
    end)
end
