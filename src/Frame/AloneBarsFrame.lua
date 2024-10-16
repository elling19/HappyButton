local addonName, _ = ...  ---@type string, table

---@class HappyToolkit: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

local AceGUI = LibStub("AceGUI-3.0")

---@class LoadConfig: AceModule
local LoadConfig = addon:GetModule('LoadConfig')
---@type LoadConfig

---@class BaseFrame: AceModule
local BaseFrame = addon:GetModule('BaseFrame')

---@class AloneBarsFrame: AceModule
---@field Bars Bar[]
local AloneBarsFrame = addon:NewModule("AloneBarsFrame")

function AloneBarsFrame.CollectBars()
    LoadConfig:LoadBars()
    local bars = {} ---@type Bar[]
    ---@type number, Bar
    for _, bar in ipairs(LoadConfig.Bars) do
        if bar.displayMode == const.BAR_DISPLAY_MODE.Alone then
            table.insert(bars, bar)
        end
    end
    AloneBarsFrame.Bars = bars
end

function AloneBarsFrame:CreateFrame()
    local iconSize = 32
    for barIndex, bar in ipairs(AloneBarsFrame.Bars) do
        local barFrame = AceGUI:Create("SimpleGroup")
        barFrame:SetWidth(#bar.buttons * iconSize)
        barFrame:SetHeight(iconSize)
        barFrame:SetLayout("Flow")
        for buttonIndex, button in ipairs(bar.buttons) do
            local callbackResult = button.callback(button.source)
            button._cateIndex = barIndex
            button._poolIndex = buttonIndex
            button._callbackResult = callbackResult
            local buttonContainer = AceGUI:Create("SimpleGroup")
            buttonContainer:SetWidth(iconSize)
            buttonContainer:SetHeight(iconSize)
            buttonContainer:SetLayout("Fill")
            button.button = CreateFrame("Button", ("%s-%s"):format(barIndex, buttonIndex), buttonContainer.frame, "SecureActionButtonTemplate, UIPanelButtonTemplate")
            button._button_container = buttonContainer
            button.button:SetNormalTexture(134400)
            button.button:SetSize(iconSize, iconSize)
            button.button:SetPoint("CENTER", buttonContainer.frame, "CENTER")
            button.button:RegisterForClicks("AnyDown", "AnyUp")
            button.button:SetAttribute("macrotext", "")
            if callbackResult ~= nil then
                -- 如果回调函数返回的是item模式
                if callbackResult.item ~= nil then
                    -- 更新图标宏
                    BaseFrame:SetPoolMacro(const.BAR_DISPLAY_MODE.Alone, button)
                    -- 更新冷却计时
                    BaseFrame:SetPoolCooldown(button)
                    -- 更新鼠标移入移出事件
                    BaseFrame:SetPoolLearnable(button)
                else
                    BaseFrame:SetScriptEvent(button)
                end
            end
            barFrame:AddChild(buttonContainer)
            barFrame.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 500, - 500 - iconSize * (barIndex - 1))
        end
        bar.Frame = barFrame
    end
end

-- 根据索引获取pool
function AloneBarsFrame:GetButtonByIndex(barIndex, buttonIndex)
    local bar = AloneBarsFrame.Bars[barIndex]
    if bar == nil then
        return nil
    end
    local button = bar.buttons[buttonIndex]
    return button
end

-- 初始化UI模块
function AloneBarsFrame:Initial()
    AloneBarsFrame:CollectBars()
    AloneBarsFrame:CreateFrame()
end
