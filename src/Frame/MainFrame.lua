local addonName, _ = ...

local AceGUI = LibStub("AceGUI-3.0")

---@class HappyToolkit: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class LoadConfig: AceModule
local LoadConfig = addon:GetModule('LoadConfig')

---@class BaseFrame: AceModule
local BaseFrame = addon:GetModule('BaseFrame')

---@class MainFrame: AceModule
local MainFrame = addon:NewModule("MainFrame")

MainFrame.Window = AceGUI:Create("SimpleGroup")
MainFrame.CateMenuFrame = AceGUI:Create("SimpleGroup")
MainFrame.Bars = {}
MainFrame.IsOpen = false
MainFrame.IsMouseInside = false  -- 鼠标是否处在框体内
MainFrame.IconSize = 32
MainFrame.tabs = {} -- 分类切换按钮
MainFrame.currentTabIndex = nil
MainFrame.IsOpenEditMode = false

-- 创建编辑模式背景
MainFrame.EditModeBg = MainFrame.Window.frame:CreateTexture(nil, "BACKGROUND")
MainFrame.EditModeBg:SetPoint("TOPLEFT", MainFrame.Window.frame, "TOPLEFT", 0, 0)
MainFrame.EditModeBg:SetPoint("BOTTOMRIGHT", MainFrame.Window.frame, "BOTTOMRIGHT", 0, 0)
MainFrame.EditModeBg:SetColorTexture(0, 0, 1, 0.5)  -- 蓝色半透明背景
MainFrame.EditModeBg:Hide()


function MainFrame:CollectBars()
    LoadConfig:LoadBars()
    local bars = {} ---@type Bar[]
    ---@type number, Bar
    for _, bar in ipairs(LoadConfig.Bars) do
        if bar.displayMode == const.BAR_DISPLAY_MODE.Mount then
            table.insert(bars, bar)
        end
    end
    MainFrame.Bars = bars
end

function MainFrame:CreateFrame()
    local iconSize = MainFrame.IconSize
    local barNum = #MainFrame.Bars
    local windowHeight = iconSize * barNum
    local maxPoolNum = 0
    for _, bar in ipairs(MainFrame.Bars) do
        if maxPoolNum < #bar.buttons then
            maxPoolNum = #bar.buttons
        end
    end

    MainFrame.Window.frame:SetFrameStrata("BACKGROUND")
    MainFrame.Window:SetLayout("Flow")
    MainFrame.Window:SetHeight(windowHeight)
    MainFrame:SetWindowsWidth()

    -- 将窗口定位到初始位置
    local x = addon.db.profile.posX or 0
    local y = - (addon.db.profile.posY or 0)

    MainFrame.Window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)

    MainFrame.Window.frame:SetMovable(true)
    MainFrame.Window.frame:EnableMouse(true)
    MainFrame.Window.frame:RegisterForDrag("LeftButton")
    MainFrame.Window.frame:SetClampedToScreen(true)

    -- 监听拖动事件并更新位置
    MainFrame.Window.frame:SetScript("OnDragStart", function(frame)
        frame:StartMoving()
    end)

    -- 监听窗口的拖拽事件
    MainFrame.Window.frame:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        local newX, newY = frame:GetLeft(), frame:GetTop() - UIParent:GetHeight()
        addon.db.profile.posX = math.floor(newX)
        addon.db.profile.posY = - math.floor(newY)
    end)

    MainFrame.Window.frame:SetScript("OnUpdate", function(self)
        local mouseOver = self:IsMouseOver()
        if mouseOver and not MainFrame.IsMouseInside then
            if addon.db.profile.showbarMenuOnMouseEnter == true then
                MainFrame:ShowCateMenuFrame()
            end
            MainFrame.IsMouseInside = true
        elseif not mouseOver and MainFrame.IsMouseInside then
            if addon.db.profile.showbarMenuOnMouseEnter == true then
                MainFrame:HideCateMenuFrame()
            end
            MainFrame:HideAllIconFrame()
            MainFrame.IsMouseInside = false
        end
    end)

    MainFrame.CateMenuFrame:SetWidth(iconSize)
    MainFrame.CateMenuFrame:SetHeight(windowHeight)
    MainFrame.CateMenuFrame:SetLayout("List")
    MainFrame.Window:AddChild(MainFrame.CateMenuFrame)

    for _, category in ipairs(MainFrame.Bars) do
        table.insert(MainFrame.tabs, {title=category.title, icon=category.icon, button=nil})
    end

    for index, tab in ipairs(MainFrame.tabs) do
        local tabContainer = AceGUI:Create("SimpleGroup")
        tabContainer:SetWidth(iconSize)
        tabContainer:SetHeight(iconSize)
        tabContainer:SetLayout("Fill")
        local tabIcon = CreateFrame("Button", ("tab-%s"):format(index), tabContainer.frame, "UIPanelButtonTemplate")
        if tab.icon then
            if tonumber(tab.icon) then
                tabIcon:SetNormalTexture(tonumber(tab.icon))
            else
                tabIcon:SetNormalTexture(tab.icon)
            end
        else
            tabIcon:SetNormalTexture(134400)
        end

        tabIcon:SetSize(iconSize, iconSize)
        tabIcon:SetPoint("CENTER", tabContainer.frame, "CENTER")
        tabIcon:SetScript("OnLeave", function(_)
            GameTooltip:Hide()
        end)
        tabIcon:SetScript("OnEnter", function (self)
            local highlightTexture = tabIcon:CreateTexture()
            highlightTexture:SetColorTexture(255, 255, 255, 0.2)
            tabIcon:SetHighlightTexture(highlightTexture)
            MainFrame:ShowIconFrame(index)
        end)
        tabIcon:SetScript("OnClick", function(_, _)
            MainFrame:ToggleIconFrame(index)
        end)
        MainFrame.CateMenuFrame:AddChild(tabContainer)
        tab.button = tabIcon
    end


    for cateIndex, bar in ipairs(MainFrame.Bars) do
        local iconsFrame = AceGUI:Create("SimpleGroup")
        iconsFrame:SetWidth(#bar.buttons * iconSize)
        iconsFrame:SetHeight(iconSize)
        iconsFrame:SetLayout("Flow")
        iconsFrame.frame:Hide()
        for poolIndex, pool in ipairs(bar.buttons) do
            local callbackResult = pool.callback(pool.source)
            pool._cateIndex = cateIndex
            pool._poolIndex = poolIndex
            pool._callbackResult = callbackResult
            local buttonContainer = AceGUI:Create("SimpleGroup")
            buttonContainer:SetWidth(iconSize)
            buttonContainer:SetHeight(iconSize)
            buttonContainer:SetLayout("Fill")
            pool.button = CreateFrame("Button", ("%s-%s"):format(cateIndex, poolIndex), buttonContainer.frame, "SecureActionButtonTemplate, UIPanelButtonTemplate")
            pool._button_container = buttonContainer
            pool.button:SetNormalTexture(134400)
            pool.button:SetSize(iconSize, iconSize)
            pool.button:SetPoint("CENTER", buttonContainer.frame, "CENTER")
            pool.button:RegisterForClicks("AnyDown", "AnyUp")
            pool.button:SetAttribute("macrotext", "")
            if bar.isDisplayName == true then
                pool.text = buttonContainer.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                pool.text:SetWidth(iconSize)
                pool.text:SetPoint("TOP", buttonContainer.frame, "BOTTOM", 0, -5)
            end
            if callbackResult ~= nil then
                -- 如果回调函数返回的是item模式
                if callbackResult.item ~= nil then
                    -- 更新图标宏
                    BaseFrame:SetPoolMacro(const.BAR_DISPLAY_MODE.Mount, pool)
                    -- 更新冷却计时
                    BaseFrame:SetPoolCooldown(pool)
                    -- 更新鼠标移入移出事件
                    BaseFrame:SetButtonMouseEvent(pool)
                    BaseFrame:SetPoolLearnable(pool)
                else
                    BaseFrame:SetScriptEvent(pool)
                end
                if callbackResult.text and pool.text then
                    pool.text:SetText(U.String.ToVertical(callbackResult.text))
                end
            end
            iconsFrame:AddChild(buttonContainer)
            iconsFrame.frame:SetPoint("TOPLEFT", MainFrame.Window.frame, "TOPLEFT", iconSize, - iconSize * (cateIndex - 1))
            bar.Frame = iconsFrame
        end
    end

    if addon.db.profile.showbarMenuDefault == true then
        MainFrame:ShowWindow()
    else
        MainFrame:HideWindow()
    end
end

function MainFrame:ToggleIconFrame(index)
    if MainFrame.currentTabIndex == index then
        MainFrame.currentTabIndex = nil
        MainFrame.Bars[index].Frame.frame:Hide()
    else
        MainFrame.currentTabIndex = index
        MainFrame.Bars[index].Frame.frame:Show()
        MainFrame:SetWindowsWidth()
    end
end

function MainFrame:ShowIconFrame(index)
    MainFrame.currentTabIndex = index
    for tabIndex, tab in ipairs(MainFrame.tabs) do
        if tab.button ~= nil then
            MainFrame.Bars[tabIndex].Frame.frame:Hide()
        end
    end
    MainFrame.Bars[index].Frame.frame:Show()
    MainFrame:SetWindowsWidth()
end

function MainFrame:HideAllIconFrame()
    for _, bar in ipairs(MainFrame.Bars) do
        bar.Frame.frame:Hide()
    end
    MainFrame.currentTabIndex = nil
end

function MainFrame:HideCateMenuFrame()
    -- 当设置了鼠标移入显示菜单的时候，不能隐藏window
    if addon.db.profile.showbarMenuOnMouseEnter == false then
        MainFrame.Window.frame:Hide()
    end
    MainFrame.CateMenuFrame.frame:Hide()
    MainFrame.IsOpen = false
end

function MainFrame:ShowCateMenuFrame()
    MainFrame.Window.frame:Show()
    MainFrame.CateMenuFrame.frame:Show()
    MainFrame.IsOpen = true
end

function MainFrame:Update()
    for _, bar in ipairs(MainFrame.Bars) do
        for _, pool in ipairs(bar.buttons) do
            local callbackResult = pool.callback(pool.source)
            if not (callbackResult == nil) then
                pool._callbackResult = callbackResult
                BaseFrame:SetPoolCooldown(pool)
                BaseFrame:SetPoolMacro(const.BAR_DISPLAY_MODE.Mount, pool)
                BaseFrame:SetPoolLearnable(pool)
            end
        end
    end
end


-- 设置窗口宽度：窗口会遮挡视图，会减少鼠标可点击范围，因此窗口宽度尽可能小
function MainFrame:SetWindowsWidth()
    local buttonNum = 0
    if MainFrame.currentTabIndex ~= nil then
        buttonNum = #MainFrame.Bars[MainFrame.currentTabIndex].buttons
    end
    MainFrame.Window:SetWidth(MainFrame.IconSize * (1 + buttonNum))
end

-- 隐藏窗口
function MainFrame:HideWindow()
    if MainFrame.IsOpen == true then
        MainFrame:HideCateMenuFrame()
        MainFrame:HideAllIconFrame()
    end
end

-- 显示窗口
function MainFrame:ShowWindow()
    if MainFrame.IsOpen == false then
        MainFrame:ShowCateMenuFrame()
        MainFrame:Update()
    end
end

-- 根据索引获取pool
function MainFrame:GetButtonByIndex(barIndex, buttonIndex)
    local bar = MainFrame.Bars[barIndex]
    if bar == nil then
        return nil
    end
    local button = bar.buttons[buttonIndex]
    return button
end

-- 开启编辑模式
function MainFrame:ToggleEditMode(IsOpenEditMode)
    if IsOpenEditMode == true and MainFrame.IsOpenEditMode == false then
        -- 设置了鼠标移入需要临时关闭
        MainFrame.EditModeBg:Show()
        MainFrame:HideCateMenuFrame()
        MainFrame.CateMenuFrame.frame:Hide()
        MainFrame.Window.frame:Show()
        MainFrame.IsOpen = false
        MainFrame.IsOpenEditMode = IsOpenEditMode
    end
    if IsOpenEditMode == false and MainFrame.IsOpenEditMode == true then
        MainFrame.EditModeBg:Hide()
        MainFrame:ShowCateMenuFrame()
        MainFrame.IsOpenEditMode = IsOpenEditMode
    end
end

-- 初始化UI模块
function MainFrame:Initial()
    MainFrame:CollectBars()
    MainFrame:CreateFrame()
    MainFrame:Update()
end