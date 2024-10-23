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

---@class ElementCbInfo
---@field f fun(ele: ElementConfig): CbResult | CbResult[]  -- f: function
---@field p ElementConfig -- p: params
---@field r CbResult[]

---@class Bar
---@field TabBtn nil|table|Button
---@field BarFrame nil|table|Button
---@field BarBtns (table|Button)[]
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
                table.insert(cbs, self:GetCbss(_eleConfig)[1][1])
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
                btn:Hide()
                btn:ClearAllPoints()
                btn = {}
            end
        end
    end
end

function ElementFrame:Update()
    for barIndex, bar in ipairs(self.Bars) do
        local cbResults = {} ---@type CbResult[]
        if self.Cbss[barIndex] then
            for _, cb in ipairs(self.Cbss[barIndex]) do
                cb.r = cb.f(cb.p)
                for _, r in ipairs(cb.r) do
                    table.insert(cbResults, r)
                end
            end
        end
        for cbIndex, r in ipairs(cbResults) do
            -- 如果图标不足，补全图标
            if cbIndex > #bar.BarBtns then
                local btn = CreateFrame("Button", ("Button-%s-%s-%s"):format(self.Config.id, barIndex, cbIndex),
                    bar.BarFrame, "SecureActionButtonTemplate, UIPanelButtonTemplate")
                btn:SetNormalTexture(134400)
                btn:SetSize(self.IconWidth, self.IconHeight)
                if self.Config.type == const.ELEMENT_TYPE.BAR_GROUP then
                    if self.Config.elesGrowth == const.GROWTH.LEFTTOP or self.Config.elesGrowth == const.GROWTH.RIGHTTOP then
                        btn:SetPoint("BOTTOM", bar.BarFrame, "BOTTOM", 0, self.IconHeight * (cbIndex - 1))
                    elseif self.Config.elesGrowth == const.GROWTH.LEFTBOTTOM or self.Config.elesGrowth == const.GROWTH.RIGHTBOTTOM then
                        btn:SetPoint("TOP", bar.BarFrame, "TOP", 0, -self.IconHeight * (cbIndex - 1))
                    elseif self.Config.elesGrowth == const.GROWTH.BOTTOMLEFT or self.Config.elesGrowth == const.GROWTH.TOPLEFT then
                        btn:SetPoint("RIGHT", bar.BarFrame, "RIGHT", -self.IconWidth * (cbIndex - 1), 0)
                    elseif self.Config.elesGrowth == const.GROWTH.BOTTOMRIGHT or self.Config.elesGrowth == const.GROWTH.TOPRIGHT then
                        btn:SetPoint("LEFT", bar.BarFrame, "LEFT", self.IconWidth * (cbIndex - 1), 0)
                    else
                        -- 默认右下
                        btn:SetPoint("TOP", bar.BarFrame, "TOP", 0, -self.IconHeight * (cbIndex - 1))
                    end
                else
                    if self.Config.elesGrowth == const.GROWTH.LEFTTOP or self.Config.elesGrowth == const.GROWTH.LEFTBOTTOM then
                        btn:SetPoint("RIGHT", bar.BarFrame, "RIGHT", -self.IconWidth * (cbIndex - 1), 0)
                    elseif self.Config.elesGrowth == const.GROWTH.TOPLEFT or self.Config.elesGrowth == const.GROWTH.TOPRIGHT then
                        btn:SetPoint("BOTTOM", bar.BarFrame, "BOTTOM", 0, self.IconHeight * (cbIndex - 1))
                    elseif self.Config.elesGrowth == const.GROWTH.BOTTOMLEFT or self.Config.elesGrowth == const.GROWTH.BOTTOMRIGHT then
                        btn:SetPoint("TOP", bar.BarFrame, "TOP", 0, -self.IconHeight * (cbIndex - 1))
                    elseif self.Config.elesGrowth == const.GROWTH.RIGHTBOTTOM or self.Config.elesGrowth == const.GROWTH.RIGHTTOP then
                        btn:SetPoint("LEFT", bar.BarFrame, "LEFT", self.IconWidth * (cbIndex - 1), 0)
                    else
                        -- 默认右下
                        btn:SetPoint("LEFT", bar.BarFrame, "LEFT", self.IconWidth * (cbIndex - 1), 0)
                    end
                end
                btn:RegisterForClicks("AnyDown", "AnyUp")
                btn:SetAttribute("macrotext", "")
                btn.r = r
                btn.barIndex = barIndex
                btn.cbIndex = cbIndex
                table.insert(bar.BarBtns, btn)
            end
            local btn = bar.BarBtns[cbIndex]
            -- 如果回调函数返回的是item模式
            if r.item ~= nil then
                -- 更新图标宏
                self:SetPoolMacro(btn)
                -- 更新冷却计时
                self:SetPoolCooldown(btn)
                -- 更新鼠标移入移出事件
                self:SetButtonMouseEvent(btn)
                self:SetPoolLearnable(btn)
            else
                self:SetScriptEvent(btn)
            end
            -- 隐藏/显示文字
            if self.Config.isDisplayText == true then
                if btn.text == nil then
                    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    if self:IsIconsHorizontal() then
                        btn.text:SetWidth(self.IconWidth)
                    else
                        btn.text:SetHeight(self.IconHeight)
                    end
                    if self:IsIconsHorizontal() then
                        btn.text:SetPoint("TOP", btn, "BOTTOM", 0, -5)
                    else
                        btn.text:SetPoint("LEFT", btn, "RIGHT", 5, 0)
                    end
                end
                if r.text then
                    if self:IsIconsHorizontal() then
                        btn.text:SetText(U.String.ToVertical(r.text))
                    else
                        btn.text:SetText(r.text)
                    end
                end
            else
                if btn.text then
                    btn.text:Hide()
                end
            end
        end
        -- 如果按钮过多，删除冗余按钮
        if #cbResults < #bar.BarBtns then
            for i = #bar.BarBtns, #cbResults + 1, -1 do
                table.remove(bar.BarBtns, i)
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
        local newX, newY
        if self.Config.elesGrowth == const.GROWTH.RIGHTBOTTOM then
            newX = frame:GetLeft()
            newY = frame:GetTop() - UIParent:GetHeight()
        elseif self.Config.elesGrowth == const.GROWTH.RIGHTTOP then
            newX = frame:GetLeft()
            newY = frame:GetTop()
        elseif self.Config.elesGrowth == const.GROWTH.LEFTBOTTOM then
            newX = frame:GetLeft() - UIParent:GetWidth()
            newY = frame:GetTop() - UIParent:GetHeight()
        elseif self.Config.elesGrowth == const.GROWTH.LEFTTOP then
            newX = frame:GetLeft() - UIParent:GetWidth()
            newY = frame:GetTop()
        elseif self.Config.elesGrowth == const.GROWTH.TOPLEFT then
            newX = frame:GetLeft() - UIParent:GetWidth()
            newY = frame:GetTop()
        elseif self.Config.elesGrowth == const.GROWTH.TOPRIGHT then
            newX = frame:GetLeft()
            newY = frame:GetTop()
        elseif self.Config.elesGrowth == const.GROWTH.BOTTOMLEFT then
            newX = frame:GetLeft() - UIParent:GetWidth()
            newY = frame:GetTop() - UIParent:GetHeight()
        elseif self.Config.elesGrowth == const.GROWTH.BOTTOMRIGHT then
            newX = frame:GetLeft()
            newY = frame:GetTop() - UIParent:GetHeight()
        else
            -- 默认右下
            newX = frame:GetLeft()
            newY = frame:GetTop() - UIParent:GetHeight()
        end
        self.Config.posX = math.floor(newX)
        self.Config.posY = math.floor(newY)
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
    local frameAnchorPos = self.Config.anchorPos or const.ANCHOR_POS.TOPLEFT
    local attachFrameAnchorPos = self.Config.attachFrameAnchorPos or const.ANCHOR_POS.TOPLEFT
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

-- 更新pool的宏文案
function ElementFrame:SetPoolMacro(btn)
    local r = btn.r
    if r == nil or r.item == nil then
        return
    end
    if btn == nil then
        return
    end
    -- 设置宏命令
    btn:SetAttribute("type", "macro") -- 设置按钮为宏类型
    if r.icon then
        btn:SetNormalTexture(r.icon)
    end
    local macroText = ""
    if r.item.type == const.ITEM_TYPE.ITEM then
        macroText = "/use item:" .. r.item.id
    elseif r.item.type == const.ITEM_TYPE.TOY then
        macroText = "/use item:" .. r.item.id
    elseif r.item.type == const.ITEM_TYPE.SPELL then
        macroText = "/cast " .. r.item.name
    elseif r.item.type == const.ITEM_TYPE.MOUNT then
        macroText = "/cast " .. r.item.name
    elseif r.item.type == const.ITEM_TYPE.PET then
        macroText = "/SummonPet " .. r.item.name
    end
    -- 宏命令附加关闭窗口
    if r.closeGUIAfterClick == nil or r.closeGUIAfterClick == true then
        macroText = macroText .. "\r" .. "/SETCLOSEEFRAME" .. " " .. self.Config.id
    end
    btn:SetAttribute("macrotext", macroText)
end

-- 设置pool的冷却
function ElementFrame:SetPoolCooldown(btn)
    if btn == nil then
        return
    end
    local r = btn.r
    if r == nil or r.item == nil then
        return
    end
    if btn.cooldown == nil then
        -- 创建冷却效果
        btn.cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
        btn.cooldown:SetAllPoints(btn)             -- 设置冷却效果覆盖整个按钮
        btn.cooldown:SetDrawEdge(true)             -- 显示边缘
        btn.cooldown:SetHideCountdownNumbers(true) -- 隐藏倒计时数字
    end
    local item = r.item
    btn:SetScript("OnUpdate", function (frame)
        -- 更新冷却倒计时
        if item.type == const.ITEM_TYPE.ITEM then
            local startTimeSeconds, durationSeconds, enableCooldownTimer = C_Item.GetItemCooldown(item.id)
            CooldownFrame_Set(frame.cooldown, startTimeSeconds, durationSeconds, enableCooldownTimer)
        elseif item.type == const.ITEM_TYPE.TOY then
            local startTimeSeconds, durationSeconds, enableCooldownTimer = C_Item.GetItemCooldown(item.id)
            CooldownFrame_Set(frame.cooldown, startTimeSeconds, durationSeconds, enableCooldownTimer)
        elseif item.type == const.ITEM_TYPE.SPELL then
            local spellCooldownInfo = C_Spell.GetSpellCooldown(item.id)
            if spellCooldownInfo then
                CooldownFrame_Set(frame.cooldown, spellCooldownInfo.startTime, spellCooldownInfo.duration, spellCooldownInfo.isEnabled)
            end
        elseif item.type == const.ITEM_TYPE.PET then
            local speciesId, petGUID = C_PetJournal.FindPetIDByName(item.name)
            if petGUID then
                local start, duration, isEnabled = C_PetJournal.GetPetCooldownByGUID(petGUID)
                CooldownFrame_Set(frame.cooldown, start, duration, isEnabled)
            end
        end
    end)
end

-- 设置脚本模式的点击事件
function ElementFrame:SetScriptEvent(btn)
    if btn == nil then
        return
    end
    local r = btn.r
    if r == nil then
        return
    end
    if r.leftClickCallback then
        btn:SetScript("OnClick", function()
            r.leftClickCallback()
        end)
    elseif r.macro then
        btn:SetAttribute("type", "macro")
        local macroText = ""
        macroText = macroText .. r.macro
        if r.closeGUIAfterClick == nil or r.closeGUIAfterClick == true then
            macroText = macroText .. "\r" .. "/closehtmainframe"
        end
        btn:SetAttribute("macrotext", macroText)
    end
    if r.icon then
        btn:SetNormalTexture(r.icon)
    end
end

-- 当pool上的技能没有学习的时候，置为灰色
function ElementFrame:SetPoolLearnable(btn)
    if btn == nil then
        return
    end
    local r = btn.r
    if r == nil or r.item == nil then
        return
    end
    local item = r.item
    local hasThisThing = false
    if item.type == const.ITEM_TYPE.ITEM then
        local count = C_Item.GetItemCount(item.id, false)
        if not (count == 0) then
            hasThisThing = true
        end
    elseif item.type == const.ITEM_TYPE.TOY then
        if PlayerHasToy(item.id) then
            hasThisThing = true
        end
    elseif item.type == const.ITEM_TYPE.SPELL then
        if IsSpellKnown(item.id) then
            hasThisThing = true
        end
    elseif item.type == const.ITEM_TYPE.MOUNT then
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight =
            C_MountJournal.GetMountInfoByID(item.id)
        if isCollected then
            hasThisThing = true
        end
    elseif item.type == const.ITEM_TYPE.PET then
        for petIndex = 1, C_PetJournal.GetNumPets() do
            local _, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable =
                C_PetJournal.GetPetInfoByIndex(petIndex)
            if speciesID == item.id then
                hasThisThing = true
                break
            end
        end
    end
    -- 如果没有学习这个技能，则将图标和文字改成灰色半透明
    if hasThisThing == false then
        if btn then
            btn:SetEnabled(false)
            btn:SetAlpha(0.5)
        end
        if btn.text then
            btn.text:SetTextColor(0.5, 0.5, 0.5)
        end
    else
        if btn then
            btn:SetEnabled(true)
            btn:SetAlpha(1)
        end
        if btn.text then
            btn.text:SetTextColor(1, 1, 1)
        end
    end
end

-- 根据索引获取btn
function ElementFrame:GetButtonByIndex(barIndex, buttonIndex)
    local bar = self.Bars[barIndex]
    if bar == nil then
        return nil
    end
    local button = bar.BarBtns[buttonIndex]
    return button
end

-- 设置button鼠标移入事件
function ElementFrame:SetShowGameTooltip(btn)
    local r = btn.r
    if r == nil or r.item == nil then
        return
    end
    local item = r.item
    GameTooltip:SetOwner(btn, "ANCHOR_RIGHT") -- 设置提示显示的位置
    if item.type == const.ITEM_TYPE.ITEM then
        GameTooltip:SetItemByID(item.id)
    elseif item.type == const.ITEM_TYPE.TOY then
        GameTooltip:SetToyByItemID(item.id)
    elseif item.type == const.ITEM_TYPE.SPELL then
        GameTooltip:SetSpellByID(item.id)
    elseif item.type == const.ITEM_TYPE.MOUNT then
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight =
            C_MountJournal.GetMountInfoByID(item.id)
        GameTooltip:SetMountBySpellID(spellID)
    elseif item.type == const.ITEM_TYPE.PET then
        local speciesName, speciesIcon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable, creatureDisplayID =
            C_PetJournal.GetPetInfoBySpeciesID(item.id)
        local speciesId, petGUID = C_PetJournal.FindPetIDByName(speciesName)
        GameTooltip:SetCompanionPet(petGUID)
    end
end

-- 设置button的鼠标移入移出事件
function ElementFrame:SetButtonMouseEvent(btn)
    if btn == nil then
        return
    end
    btn:SetScript("OnLeave", function(_)
        GameTooltip:Hide() -- 隐藏提示
    end)
    btn:SetScript("OnEnter", function(_)
        self:SetShowGameTooltip(btn)
        -- 设置鼠标移入时候的高亮效果为白色半透明效果
        local highlightTexture = btn:CreateTexture()
        highlightTexture:SetColorTexture(255, 255, 255, 0.2)
        btn:SetHighlightTexture(highlightTexture)
    end)
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
