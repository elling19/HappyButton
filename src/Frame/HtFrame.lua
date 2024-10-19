local addonName, _ = ...

---@class HappyToolkit: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class E: AceModule
local E = addon:GetModule("Element")

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class ElementFrame: AceModule
local ElementFrame = addon:GetModule('ElementFrame')

---@class HtFrame: AceModule
---@field EFrames ElementFrame[]
local HtFrame = addon:NewModule("HtFrame")


-- 初始化UI模块
function HtFrame:Initial()
    local elementsConfig = addon.db.profile.elements ---@type ElementConfig[]
    local eFrames = {}  ---@type ElementFrame[]
    for index, elementConfig in ipairs(elementsConfig) do
        local eFrame = ElementFrame:New(elementConfig, index)
        table.insert(eFrames, eFrame)
    end
    HtFrame.EFrames = eFrames
end

-- 更新
function HtFrame:Update()
    for _, eFrame in ipairs(HtFrame.EFrames) do
        eFrame:Update()
    end
end

-- 开启编辑模式
function HtFrame:OpenEditMode()
    for _, eFrame in ipairs(HtFrame.EFrames) do
        eFrame:OpenEditMode()
    end
end

-- 关闭编辑模式
function HtFrame:CloseEditMode()
    for _, eFrame in ipairs(HtFrame.EFrames) do
        eFrame:CloseEditMode()
    end
end