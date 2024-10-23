local addonName, _ = ...

---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class E: AceModule
local E = addon:GetModule("Element")

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class ElementFrame: AceModule
local ElementFrame = addon:GetModule('ElementFrame')

---@class HbFrame: AceModule
---@field EFrames ElementFrame[]
local HbFrame = addon:NewModule("HbFrame")


-- 初始化UI模块
function HbFrame:Initial()
    local elementsConfig = addon.db.profile.elements ---@type ElementConfig[]
    local eFrames = {} ---@type table<string, ElementFrame>
    for _, eleConfig in ipairs(elementsConfig) do
        eFrames[eleConfig.id] = ElementFrame:New(eleConfig)
    end
    HbFrame.EFrames = eFrames
end

-- 增加
---@param eleConfig ElementConfig
function HbFrame:AddEframe(eleConfig)
    if self.EFrames[eleConfig.id] ~= nil then
        return
    end
    self.EFrames[eleConfig.id] = ElementFrame:New(eleConfig)
end

-- 移除
---@param eleConfig ElementConfig
function HbFrame:DeleteEframe(eleConfig)
    if self.EFrames[eleConfig.id] == nil then
        return
    end
    local eFrame = self.EFrames[eleConfig.id]
    eFrame:Delete()
    self.EFrames[eleConfig.id] = nil
end

-- 重载UI
---@param eleConfig ElementConfig
function HbFrame:ReloadEframeUI(eleConfig)
    if self.EFrames[eleConfig.id] == nil then
        return
    end
    local eFrame = self.EFrames[eleConfig.id]
    eFrame:ReLoadUI()
end

-- 重载Window框体位置
---@param eleConfig ElementConfig
function HbFrame:UpdateEframeWindow(eleConfig)
    if self.EFrames[eleConfig.id] == nil then
        return
    end
    local eFrame = self.EFrames[eleConfig.id]
    eFrame:UpdateWindow()
end

-- 更新
---@param eleConfig ElementConfig
function HbFrame:UpdateEframe(eleConfig)
    if self.EFrames[eleConfig.id] == nil then
        return
    end
    local eFrame = self.EFrames[eleConfig.id]
    eFrame:Update()
end

-- 全部更新
function HbFrame:UpdateAllEframes()
    for _, eFrame in pairs(self.EFrames) do
        eFrame:Update()
    end
end

-- 开启编辑模式
function HbFrame:OpenEditMode()
    for _, eFrame in pairs(self.EFrames) do
        eFrame:OpenEditMode()
    end
end

-- 关闭编辑模式
function HbFrame:CloseEditMode()
    for _, eFrame in pairs(self.EFrames) do
        eFrame:CloseEditMode()
    end
end

-- 处理战斗event
function HbFrame:OnCombatEvent()
    for _, eFrame in pairs(self.EFrames) do
        if eFrame:IsBarGroup() then
            eFrame:HideWindow()
        else
            if eFrame.Config.combatLoadCond == const.COMBAT_LOAD_COND.OUT_COMBAT_LOAD then
                eFrame:HideWindow()
            else
                eFrame:ShowWindow()
            end
        end
    end
end

-- 处理战斗结束event
function HbFrame:OutCombatEvent()
    for _, eFrame in pairs(self.EFrames) do
        if eFrame:IsBarGroup() then
            eFrame:ShowWindow()
        else
            if eFrame.Config.combatLoadCond == const.COMBAT_LOAD_COND.IN_COMBAT_LOAD then
                eFrame:HideWindow()
            else
                eFrame:ShowWindow()
            end
        end
    end
end
