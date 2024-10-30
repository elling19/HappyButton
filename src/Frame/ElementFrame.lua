local addonName, _ = ...

---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class E: AceModule
local E = addon:GetModule("Element")

---@class Item: AceModule
local Item = addon:GetModule("Item")

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class ElementCallback: AceModule
local ECB = addon:GetModule('ElementCallback')

---@class Btn: AceModule
local Btn = addon:GetModule("Btn")

---@class ElementCbInfo
---@field f fun(ele: ElementConfig, lastCbResults: CbResult[]): CbResult[]  -- f: function
---@field p ElementConfig -- p: params
---@field r CbResult[]

---@class Bar
---@field TabBtn nil|table|Button
---@field BarFrame nil|table|Button
---@field BarBtns (table|Btn)[]
---@field Icon string | number | nil

---@class ElementFrame: AceModule
---@field Cbss ElementCbInfo[][]
---@field Config ElementConfig  -- 当前Frame的配置文件
---@field Window Frame
---@field BarMenuFrame Frame
---@field Bars Bar[]
---@field IsMouseInside boolean  -- 鼠标是否处在框体内
---@field IconHeight number
---@field IconWidth number
---@field CurrentBarIndex number | nil 当前选择的Bar的下标
local ElementFrame = addon:NewModule("ElementFrame")


-- 判断是否是barGroup，其他类型（item、itemGroup、script、bar）都被抽象成Bar来处理
function ElementFrame:IsBarGroup()
    return self.Config.type == const.ELEMENT_TYPE.BAR_GROUP
end

-- 判断是否水平方向展示
function ElementFrame:IsHorizontal()
    return
        self.Config.elesGrowth == const.GROWTH.LEFTBOTTOM
        or self.Config.elesGrowth == const.GROWTH.LEFTTOP
        or self.Config.elesGrowth == const.GROWTH.RIGHTBOTTOM
        or self.Config.elesGrowth == const.GROWTH.RIGHTTOP
end

-- 判断图标列表横向展示
function ElementFrame:IsIconsHorizontal()
    -- 1. 当是BarGroup的时候、且组是纵向排列
    -- 2. 当是Bar的时候、且Bar水平排列
    return (self:IsBarGroup() and not self:IsHorizontal()) or (not self:IsBarGroup() and self:IsHorizontal())
end

-- 获取框体相对屏幕的位置
---@param frame  Frame
---@return number, number
function ElementFrame:GetPosition(frame)
    local frameLeft      = frame:GetLeft()
    local frameRight     = frame:GetRight()
    local frameBottom    = frame:GetBottom()
    local frameTop       = frame:GetTop()
    local frameX, frameY = frame:GetCenter()
    local x, y           = frame:GetCenter()
    if self.Config.attachFrameAnchorPos == const.ANCHOR_POS.TOPLEFT then
        x = frameLeft
        y = frameTop
    elseif self.Config.attachFrameAnchorPos == const.ANCHOR_POS.TOPRIGHT then
        x = frameRight
        y = frameTop
    elseif self.Config.attachFrameAnchorPos == const.ANCHOR_POS.BOTTOMLEFT then
        x = frameLeft
        y = frameBottom
    elseif self.Config.attachFrameAnchorPos == const.ANCHOR_POS.BOTTOMRIGHT then
        x = frameRight
        y = frameBottom
    elseif self.Config.attachFrameAnchorPos == const.ANCHOR_POS.TOP then
        x = frameX
        y = frameTop
    elseif self.Config.attachFrameAnchorPos == const.ANCHOR_POS.BOTTOM then
        x = frameX
        y = frameBottom
    elseif self.Config.attachFrameAnchorPos == const.ANCHOR_POS.LEFT then
        x = frameLeft
        y = frameY
    elseif self.Config.attachFrameAnchorPos == const.ANCHOR_POS.RIGHT then
        x = frameRight
        y = frameY
    elseif self.Config.attachFrameAnchorPos == const.ANCHOR_POS.CENTER then
        x = frameX
        y = frameY
    end
    return x, y
end

---@param element ElementConfig
---@return ElementFrame
function ElementFrame:New(element)
    local obj = setmetatable({}, { __index = self })
    obj.Config = element
    ElementFrame.InitialWindow(obj)
    obj.IsMouseInside = false
    obj.IconHeight = obj.Config.iconHeight or addon.G.iconHeight
    obj.IconWidth = obj.Config.iconWidth or addon.G.iconWidth
    obj.CurrentBarIndex = 1
    ElementFrame.ReLoadUI(obj)
    return obj
end

function ElementFrame:ReLoadUI()
    self.IconHeight = self.Config.iconHeight or addon.G.iconHeight
    self.IconWidth = self.Config.iconWidth or addon.G.iconWidth
    self.Cbss = self:GetCbss(self.Config)
    self:UpdateWindow()
    self:UpdateBarMenuFrame()
    self:UpdateBars()
    self:UpdateBarFrame()
    self:CreateEditModeFrame()
    self:Update()
end

---@param eleConfig ElementConfig
---@return ElementCbInfo[][]
function ElementFrame:GetCbss(eleConfig)
    if eleConfig.isLoad == false then
        return { {} }
    end
    if eleConfig.type == const.ELEMENT_TYPE.ITEM then
        local item = E:ToItem(eleConfig)
        ---@type ElementCbInfo
        local cb = { f = ECB.CallbackOfSingleMode, p = item, r = {} }
        return { { cb, } }
    elseif eleConfig.type == const.ELEMENT_TYPE.ITEM_GROUP then
        local itemGroup = E:ToItemGroup(eleConfig)
        ---@type ElementCbInfo
        local cb
        if itemGroup.extraAttr.mode == const.ITEMS_GROUP_MODE.RANDOM then
            cb = { f = ECB.CallbackOfRandomMode, p = itemGroup, r = {} }
        end
        if itemGroup.extraAttr.mode == const.ITEMS_GROUP_MODE.SEQ then
            cb = { f = ECB.CallbackOfSeqMode, p = itemGroup, r = {} }
        end
        return { { cb, } }
    elseif eleConfig.type == const.ELEMENT_TYPE.SCRIPT then
        local script = E:ToScript(eleConfig)
        if script.extraAttr.script then
            local cb = { f = ECB.CallbackOfScriptMode, p = script, r = {} }
            return { { cb, } }
        end
    elseif eleConfig.type == const.ELEMENT_TYPE.BAR then
        ---@type ElementCbInfo[]
        local cbs = {}
        local bar = E:ToBar(eleConfig)
        for _, _eleConfig in ipairs(bar.elements) do
            if _eleConfig.isLoad then
                local eleConfigCbss = self:GetCbss(_eleConfig)
                for _, _cbs in ipairs(eleConfigCbss[1]) do
                    table.insert(cbs, _cbs)
                end
            end
        end
        return { cbs, }
    elseif eleConfig.type == const.ELEMENT_TYPE.BAR_GROUP then
        ---@type ElementCbInfo[][]
        local cbss = {}
        local barGroup = E:ToBarGroup(eleConfig)
        for _, _eleConfig in ipairs(barGroup.elements) do
            if _eleConfig.isLoad == true then
                table.insert(cbss, self:GetCbss(_eleConfig)[1])
            end
        end
        return cbss
    end
    return { {} }
end

-- 创建Bar[]
function ElementFrame:UpdateBars()
    self:RemoveBars()
    ---@type Bar[]
    local bars = {}
    if self.Config.isLoad == false then
        self.Bars = bars
        return
    end
    if self.Config.type == const.ELEMENT_TYPE.BAR_GROUP then
        for _, _eleConfig in ipairs(self.Config.elements) do
            ---@type Bar
            local bar = { TabBtn = nil, BarFrame = nil, BarBtns = {}, Icon = _eleConfig.icon }
            table.insert(bars, bar)
        end
        self.Bars = bars
    else
        ---@type Bar
        local bar = { TabBtn = nil, BarFrame = nil, BarBtns = {}, Icon = self.Config.icon }
        table.insert(bars, bar)
        self.Bars = bars
    end
end

-- 移除Bar[]
function ElementFrame:RemoveBars()
    -- 清空旧的Bars
    if not self.Bars then
        return
    end
    for _, bar in ipairs(self.Bars) do
        if bar.BarFrame then
            bar.BarFrame:Hide()
            bar.BarFrame:ClearAllPoints()
            bar.BarFrame = nil
        end
        if bar.TabBtn then
            bar.TabBtn:Hide()
            bar.TabBtn:ClearAllPoints()
            bar.TabBtn = nil
        end
        for _, btn in ipairs(bar.BarBtns) do
            if btn then
                btn:Delete()
                ---@diagnostic disable-next-line: cast-local-type
                btn = nil
            end
        end
    end
end

function ElementFrame:Update()
    for barIndex, bar in ipairs(self.Bars) do
        local cbInfos = {} ---@type ElementCbInfo[]
        if self.Cbss[barIndex] then
            for _, cb in ipairs(self.Cbss[barIndex]) do
                cb.r = cb.f(cb.p, cb.r)
                for _, r in ipairs(cb.r) do
                    ECB:Compatible(r)
                    ECB:UseTrigger(cb.p, r)
                    local cbInfo = { p = cb.p, f = cb.f, r = { r, } } ---@type ElementCbInfo
                    table.insert(cbInfos, cbInfo)
                end
            end
        end
        for cbIndex, cbInfo in ipairs(cbInfos) do
            -- 如果图标不足，补全图标
            if cbIndex > #bar.BarBtns then
                local btn = Btn:New(self, barIndex, cbIndex)
                table.insert(bar.BarBtns, btn)
            end
            local btn = bar.BarBtns[cbIndex]
            btn:Update(cbInfo.p, cbInfo.r[1])
        end
        -- 如果按钮过多，删除冗余按钮
        if #cbInfos < #bar.BarBtns then
            for i = #bar.BarBtns, #cbInfos + 1, -1 do
                local btn = bar.BarBtns[i]
                btn:Delete()
                bar.BarBtns[i] = nil
            end
        end
    end
    self:SetWindowSize()
end

function ElementFrame:InitialWindow()
    self.Window = CreateFrame("Frame", ("HtWindow-%s"):format(self.Config.id), UIParent)
    self.Window:SetFrameStrata("BACKGROUND")
    self.Window:SetMovable(true)
    self.Window:EnableMouse(true)
    self.Window:RegisterForDrag("LeftButton")
    self.Window:SetClampedToScreen(true)
    self:ShowWindow()

    -- 监听鼠标点击事件：右键关闭编辑模式
    self.Window:SetScript("OnMouseDown", function(_, button)
        if button == "RightButton" then
            if addon.G.IsEditMode == true then
                addon:SendMessage(const.EVENT.EXIT_EDIT_MODE)
            end
        end
    end)

    -- 监听拖动事件并更新位置
    self.Window:SetScript("OnDragStart", function(frame)
        frame:StartMoving()
    end)

    -- 监听窗口的拖拽事件
    self.Window:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        local parentX, parentY = self:GetPosition(frame:GetParent() or UIParent)
        local frameX, frameY   = self:GetPosition(frame)
        local newX             = frameX - parentX
        local newY             = frameY - parentY
        self.Config.posX       = math.floor(newX)
        self.Config.posY       = math.floor(newY)
    end)

    self.Window:SetScript("OnUpdate", function(frame)
        if addon.G.IsEditMode == true then
            return
        end
        local mouseOver = frame:IsMouseOver()
        if mouseOver and not self.IsMouseInside then
            if self.Config.isDisplayMouseEnter == true then
                if self:IsBarGroup() then
                    self:SetBarGroupShow()
                else
                    self:SetBarNonTransparency()
                end
            end
            self.IsMouseInside = true
        elseif not mouseOver and self.IsMouseInside then
            if self.Config.isDisplayMouseEnter == true then
                if self:IsBarGroup() then
                    self:SetBarGroupHidden()
                else
                    self:SetBarTransparency()
                end
            else
                if self:IsBarGroup() then
                    self:HideAllBarFrame()
                end
            end
            self.IsMouseInside = false
        end
    end)
end

function ElementFrame:UpdateWindow()
    local barNum = #self.Cbss

    if self:IsHorizontal() then
        self.Window:SetHeight(self.IconHeight)
        self.Window:SetWidth(self.IconWidth * barNum)
    else
        self.Window:SetHeight(self.IconHeight * barNum)
        self.Window:SetWidth(self.IconWidth)
    end

    -- 将窗口定位到初始位置
    local x = self.Config.posX or 0
    local y = self.Config.posY or 0

    self.Window:ClearAllPoints()
    -- 设置Window框体挂载目标
    local attachFrame = UIParent
    if self.Config.attachFrame and self.Config.attachFrame ~= const.ATTACH_FRAME.UIParent then
        local frame = _G[self.Config.attachFrame]
        if frame then
            attachFrame = frame
        end
    end
    self.Window:SetParent(attachFrame)
    -- 设置锚点位置
    local frameAnchorPos = self.Config.anchorPos or const.ANCHOR_POS.CENTER
    local attachFrameAnchorPos = self.Config.attachFrameAnchorPos or const.ANCHOR_POS.CENTER
    self.Window:SetPoint(frameAnchorPos, attachFrame, attachFrameAnchorPos, x, y)
end

function ElementFrame:UpdateBarMenuFrame()
    --- 只有BarGroup才需要处理BarMenu和TabBtn
    if self.Config.type ~= const.ELEMENT_TYPE.BAR_GROUP then
        return
    end
    if self.BarMenuFrame == nil then
        self.BarMenuFrame = CreateFrame("Frame", ("HtBarMenuFrame-%s"), self.Window)
    end
    self.BarMenuFrame:SetHeight(self.Window:GetHeight())
    self.BarMenuFrame:SetWidth(self.Window:GetWidth())
    self.BarMenuFrame:ClearAllPoints()
    if self.Config.elesGrowth == const.GROWTH.RIGHTBOTTOM then
        self.BarMenuFrame:SetPoint("TOPLEFT", self.Window, "TOPLEFT", 0, 0)
    elseif self.Config.elesGrowth == const.GROWTH.RIGHTTOP then
        self.BarMenuFrame:SetPoint("BOTTOMLEFT", self.Window, "BOTTOMLEFT", 0, 0)
    elseif self.Config.elesGrowth == const.GROWTH.LEFTBOTTOM then
        self.BarMenuFrame:SetPoint("TOPRIGHT", self.Window, "TOPRIGHT", 0, 0)
    elseif self.Config.elesGrowth == const.GROWTH.LEFTTOP then
        self.BarMenuFrame:SetPoint("BOTTOMRIGHT", self.Window, "BOTTOMRIGHT", 0, 0)
    elseif self.Config.elesGrowth == const.GROWTH.TOPLEFT then
        self.BarMenuFrame:SetPoint("BOTTOMRIGHT", self.Window, "BOTTOMRIGHT", 0, 0)
    elseif self.Config.elesGrowth == const.GROWTH.TOPRIGHT then
        self.BarMenuFrame:SetPoint("BOTTOMLEFT", self.Window, "BOTTOMLEFT", 0, 0)
    elseif self.Config.elesGrowth == const.GROWTH.BOTTOMLEFT then
        self.BarMenuFrame:SetPoint("TOPRIGHT", self.Window, "TOPRIGHT", 0, 0)
    elseif self.Config.elesGrowth == const.GROWTH.BOTTOMRIGHT then
        self.BarMenuFrame:SetPoint("TOPLEFT", self.Window, "TOPLEFT", 0, 0)
    else
        -- 默认右下
        self.BarMenuFrame:SetPoint("TOPLEFT", self.Window, "TOPLEFT", 0, 0)
    end
end

function ElementFrame:UpdateBarFrame()
    for index, bar in ipairs(self.Bars) do
        if self.Config.type == const.ELEMENT_TYPE.BAR_GROUP then
            local TabBtn = CreateFrame("Button", ("tab-%s"):format(index), self.BarMenuFrame, "UIPanelButtonTemplate")
            local icon = bar.Icon
            if icon then
                local iconNumber = tonumber(icon)
                if iconNumber then
                    TabBtn:SetNormalTexture(iconNumber)
                else
                    TabBtn:SetNormalTexture(icon)
                end
            else
                TabBtn:SetNormalTexture(134400)
            end
            TabBtn:SetSize(self.IconWidth, self.IconHeight)
            TabBtn:ClearAllPoints()
            if self.Config.elesGrowth == const.GROWTH.LEFTTOP or self.Config.elesGrowth == const.GROWTH.LEFTBOTTOM then
                TabBtn:SetPoint("RIGHT", self.BarMenuFrame, "RIGHT", -(index - 1) * self.IconWidth, 0)
            elseif self.Config.elesGrowth == const.GROWTH.TOPLEFT or self.Config.elesGrowth == const.GROWTH.TOPRIGHT then
                TabBtn:SetPoint("BOTTOM", self.BarMenuFrame, "BOTTOM", 0, (index - 1) * self.IconHeight)
            elseif self.Config.elesGrowth == const.GROWTH.BOTTOMLEFT or self.Config.elesGrowth == const.GROWTH.BOTTOMRIGHT then
                TabBtn:SetPoint("TOP", self.BarMenuFrame, "TOP", 0, -(index - 1) * self.IconHeight)
            else
                TabBtn:SetPoint("LEFT", self.BarMenuFrame, "LEFT", (index - 1) * self.IconWidth, 0)
            end
            TabBtn:SetScript("OnEnter", function(_)
                local highlightTexture = TabBtn:CreateTexture()
                highlightTexture:SetColorTexture(255, 255, 255, 0.2)
                TabBtn:SetHighlightTexture(highlightTexture)
                self:ShowBarFrame(index)
            end)
            TabBtn:SetScript("OnClick", function(_, _)
                self:ToggleBarFrame(index)
            end)
            bar.TabBtn = TabBtn
        end
        local barFrame = CreateFrame("Frame", ("HtBarFrame-%s"):format(index), self.Window)
        if self:IsBarGroup() then
            if self.Config.elesGrowth == const.GROWTH.RIGHTBOTTOM or self.Config.elesGrowth == const.GROWTH.LEFTBOTTOM then
                barFrame:SetPoint("TOP", bar.TabBtn, "BOTTOM", 0, 0)
            elseif self.Config.elesGrowth == const.GROWTH.RIGHTTOP or self.Config.elesGrowth == const.GROWTH.LEFTTOP then
                barFrame:SetPoint("BOTTOM", bar.TabBtn, "TOP", 0, 0)
            elseif self.Config.elesGrowth == const.GROWTH.TOPLEFT or self.Config.elesGrowth == const.GROWTH.BOTTOMLEFT then
                barFrame:SetPoint("RIGHT", bar.TabBtn, "LEFT", 0, 0)
            elseif self.Config.elesGrowth == const.GROWTH.TOPRIGHT or self.Config.elesGrowth == const.GROWTH.BOTTOMRIGHT then
                barFrame:SetPoint("LEFT", bar.TabBtn, "RIGHT", 0, 0)
            else
                -- 默认右下
                barFrame:SetPoint("LEFT", bar.TabBtn, "RIGHT", 0, 0)
            end
        else
            if self.Config.elesGrowth == const.GROWTH.RIGHTBOTTOM then
                barFrame:SetPoint("TOPLEFT", self.Window, "TOPLEFT", 0, 0)
            elseif self.Config.elesGrowth == const.GROWTH.RIGHTTOP then
                barFrame:SetPoint("BOTTOMLEFT", self.Window, "BOTTOMLEFT", 0, 0)
            elseif self.Config.elesGrowth == const.GROWTH.LEFTBOTTOM then
                barFrame:SetPoint("TOPRIGHT", self.Window, "TOPRIGHT", 0, 0)
            elseif self.Config.elesGrowth == const.GROWTH.LEFTTOP then
                barFrame:SetPoint("BOTTOMRIGHT", self.Window, "BOTTOMRIGHT", 0, 0)
            elseif self.Config.elesGrowth == const.GROWTH.TOPLEFT then
                barFrame:SetPoint("BOTTOMRIGHT", self.Window, "BOTTOMRIGHT", 0, 0)
            elseif self.Config.elesGrowth == const.GROWTH.TOPRIGHT then
                barFrame:SetPoint("BOTTOMLEFT", self.Window, "BOTTOMLEFT", 0, 0)
            elseif self.Config.elesGrowth == const.GROWTH.BOTTOMLEFT then
                barFrame:SetPoint("TOPRIGHT", self.Window, "TOPRIGHT", 0, 0)
            elseif self.Config.elesGrowth == const.GROWTH.BOTTOMRIGHT then
                barFrame:SetPoint("TOPLEFT", self.Window, "TOPLEFT", 0, 0)
            else
                -- 默认右下
                barFrame:SetPoint("TOPLEFT", self.Window, "TOPLEFT", 0, 0)
            end
        end
        barFrame:SetWidth(self.IconWidth)
        barFrame:SetHeight(self.IconHeight)
        if self:IsBarGroup() or self.Config.isDisplayMouseEnter then
            barFrame:Hide()
        end
        bar.BarFrame = barFrame
    end
end

-- 创建编辑模式背景
function ElementFrame:CreateEditModeFrame()
    self.EditModeBg = self.Window:CreateTexture(nil, "BACKGROUND")
    self.EditModeBg:SetPoint("TOPLEFT", self.Window, "TOPLEFT", 0, 0)
    self.EditModeBg:SetPoint("BOTTOMRIGHT", self.Window, "BOTTOMRIGHT", 0, 0)
    self.EditModeBg:SetColorTexture(0, 0, 1, 0.5) -- 蓝色半透明背景
    self.EditModeBg:Hide()
end

function ElementFrame:ToggleBarFrame(index)
    if self.CurrentBarIndex == index then
        self.CurrentBarIndex = nil
        self.Bars[index].BarFrame:Hide()
    else
        self.CurrentBarIndex = index
        self.Bars[index].BarFrame:Show()
        self:SetWindowSize()
    end
end

-- 显示指定下标的BarFrame
function ElementFrame:ShowBarFrame(index)
    self.CurrentBarIndex = index
    for _index, bar in ipairs(self.Bars) do
        if bar.BarFrame ~= nil then
            self.Bars[_index].BarFrame:Hide()
        end
    end
    self.Bars[index].BarFrame:Show()
    self:SetWindowSize()
end

-- 隐藏所有的BarFrame
function ElementFrame:HideAllBarFrame()
    for _index, bar in ipairs(self.Bars) do
        if bar.BarFrame ~= nil then
            self.Bars[_index].BarFrame:Hide()
        end
    end
    self.CurrentBarIndex = nil
    self:SetWindowSize()
end

-- 将bargroup类型设置成隐藏
function ElementFrame:SetBarGroupHidden()
    if self.BarMenuFrame then
        self.BarMenuFrame:Hide()
    end
    for _, bar in ipairs(self.Bars) do
        bar.BarFrame:Hide()
    end
    self.CurrentBarIndex = nil
end

-- 将bargroup类型设置成显示
function ElementFrame:SetBarGroupShow()
    if self.BarMenuFrame then
        self.BarMenuFrame:Show()
    end
    self.CurrentBarIndex = nil
end

--- 将单个Bar类型设置成透明
function ElementFrame:SetBarTransparency()
    if self.Bars and #self.Bars > 0 then
        self.Bars[1].BarFrame:SetAlpha(0)
    end
end

--- 将单个Bar类型设置成不透明
function ElementFrame:SetBarNonTransparency()
    if self.Bars and #self.Bars > 0 then
        self.Bars[1].BarFrame:SetAlpha(1)
    end
end

--- 将单个Bar类型设置成隐藏
function ElementFrame:SetBarHidden()
    if self.Bars and #self.Bars > 0 then
        self.Bars[1].BarFrame:Hide()
    end
end

--- 将单个Bar类型设置成不透明
function ElementFrame:SetBarShow()
    if self.Bars and #self.Bars > 0 then
        self.Bars[1].BarFrame:Show()
    end
end

-- 设置窗口宽度：窗口会遮挡视图，会减少鼠标可点击范围，因此窗口宽度尽可能小
function ElementFrame:SetWindowSize()
    local buttonNum = 1
    if self:IsBarGroup() then
        if self.CurrentBarIndex ~= nil then
            -- 初始创建的barGroup没有Bar，需要判断非空
            if #self.Bars ~= 0 then
                local currentBar = self.Bars[self.CurrentBarIndex]
                if currentBar then
                    local barBtns = currentBar.BarBtns
                    buttonNum = (#barBtns) + 1
                end
            end
        end
        if self:IsHorizontal() then
            self.Window:SetWidth(self.IconWidth * #self.Bars)
            self.Window:SetHeight(self.IconHeight * buttonNum)
        else
            self.Window:SetWidth(self.IconWidth * buttonNum)
            self.Window:SetHeight(self.IconHeight * #self.Bars)
        end
    else
        if self.Bars and #self.Bars > 0 then
            buttonNum = #self.Bars[1].BarBtns
        end
        if self:IsHorizontal() then
            self.Window:SetWidth(self.IconWidth * buttonNum)
            self.Window:SetHeight(self.IconHeight)
        else
            self.Window:SetWidth(self.IconWidth)
            self.Window:SetHeight(self.IconHeight * buttonNum)
        end
    end
end

-- 隐藏窗口
function ElementFrame:HideWindow()
    self.Window:Hide()
end

-- 显示窗口
function ElementFrame:ShowWindow()
    self.Window:Show()
end

-- 开启编辑模式
function ElementFrame:OpenEditMode()
    if addon.G.IsEditMode == true then
        self.Window:Show()
        self.EditModeBg:Show()
        if self:IsBarGroup() then
            self:SetBarGroupHidden()
        else
            self:SetBarHidden()
        end
    end
end

-- 关闭编辑模式
function ElementFrame:CloseEditMode()
    if addon.G.IsEditMode == false then
        self.EditModeBg:Hide()
        if self:IsBarGroup() then
            self:SetBarGroupShow()
        else
            self:SetBarShow()
        end
    end
end

-- 卸载框体
function ElementFrame:Delete()
    self.Window:Hide()
    self.Window:ClearAllPoints()
    self.Window = nil
end
