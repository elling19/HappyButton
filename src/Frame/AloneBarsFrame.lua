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
---@field IsOpenEditMode boolean
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
        barFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", bar.posX or 0, - (bar.posY or 0))
        barFrame:SetLayout("Flow")

        -- 创建编辑模式背景
        barFrame.EditModeBg = barFrame.frame:CreateTexture(nil, "BACKGROUND")
        barFrame.EditModeBg:SetPoint("TOPLEFT", barFrame.frame, "TOPLEFT", 0, 0)
        barFrame.EditModeBg:SetPoint("BOTTOMRIGHT", barFrame.frame, "BOTTOMRIGHT", 0, 0)
        barFrame.EditModeBg:SetColorTexture(0, 0, 1, 0.5)  -- 蓝色半透明背景
        barFrame.EditModeBg:Hide()

        barFrame.frame:SetMovable(true)
        barFrame.frame:EnableMouse(true)
        barFrame.frame:RegisterForDrag("LeftButton")
        barFrame.frame:SetClampedToScreen(true)

        -- 监听鼠标点击事件：右键关闭编辑模式
        barFrame.frame:SetScript("OnMouseDown", function(_, button)
            if button == "RightButton" then
                if addon.G.IsEditMode == true then
                    addon:SendMessage(const.EVENT.EXIT_EDIT_MODE)
                end
            end
        end)

        barFrame.frame:SetScript("OnDragStart", function(frame)
            frame:StartMoving()
        end)


        barFrame.frame:SetScript("OnDragStop", function(frame)
            frame:StopMovingOrSizing()
            local newX, newY = frame:GetLeft(), frame:GetTop() - UIParent:GetHeight()
            bar.posX = math.floor(newX)
            bar.posY = - math.floor(newY)
            -- 更新配置文件中的坐标
            addon.db.profile.barList[bar.configIndex].posX = bar.posX
            addon.db.profile.barList[bar.configIndex].posY = bar.posY
        end)

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
        end
        bar.Frame = barFrame
    end
end

function AloneBarsFrame:HideButtons()

    
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

-- 开启编辑模式
function AloneBarsFrame:OpenEditMode()
    if addon.G.IsEditMode == true then
         -- 设置了鼠标移入需要临时关闭
         for _, bar in ipairs(AloneBarsFrame.Bars) do
            bar.Frame.EditModeBg:Show()
            for _, button in ipairs(bar.buttons) do
                if button.button then
                    button.button:Hide()
                end
            end
        end
    end
end

-- 关闭编辑模式
function AloneBarsFrame:CloseEditMode()
    if addon.G.IsEditMode == false then
        for _, bar in ipairs(AloneBarsFrame.Bars) do
            bar.Frame.EditModeBg:Hide()
            for _, button in ipairs(bar.buttons) do
                if button.button then
                    button.button:Show()
                end
            end
        end
    end
end


-- 初始化UI模块
function AloneBarsFrame:Initial()
    AloneBarsFrame:CollectBars()
    AloneBarsFrame:CreateFrame()
end
