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

---@class LoadCondition: AceModule
local LoadCondition = addon:GetModule("LoadCondition")

---@class ElementCbInfo
---@field f fun(ele: ElementConfig, lastCbResults: CbResult[]): CbResult[]  -- f: function
---@field p ElementConfig -- p: params
---@field r CbResult[]
---@field btns Btn[]  -- 按钮，数量和CbResult保持一致
---@field e table<string, boolean>

---@class Bar
---@field BarFrame nil|table|Button
---@field Icon string | number | nil

---@class ElementFrame: AceModule
---@field Cbs ElementCbInfo[]
---@field Events table<string, boolean>
---@field Config ElementConfig  -- 当前Frame的配置文件
---@field Window Frame
---@field Bar Bar
---@field IsMouseInside boolean  -- 鼠标是否处在框体内
---@field IconHeight number
---@field IconWidth number
---@field CurrentBarIndex number | nil 当前选择的Bar的下标
local ElementFrame = addon:NewModule("ElementFrame")



-- 判断是否水平方向展示
function ElementFrame:IsHorizontal()
    return
        self.Config.elesGrowth == const.GROWTH.LEFTBOTTOM
        or self.Config.elesGrowth == const.GROWTH.LEFTTOP
        or self.Config.elesGrowth == const.GROWTH.RIGHTBOTTOM
        or self.Config.elesGrowth == const.GROWTH.RIGHTTOP
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
    -- 移除旧的Cbs中的按钮
    if self.Cbs then
        for _, cbs in ipairs(self.Cbs) do
            if cbs.btns then
                for i = #cbs.btns, 1, -1 do
                    cbs.btns[i]:Delete()
                    cbs.btns[i] = nil
                end
            end
        end
    end
    self.Cbs = self:GetCbs(self.Config)
    self.Events = E:GetEvents(self.Config)
    self:UpdateWindow()
    self:UpdateBar()
    self:CreateEditModeFrame()
    self:OutCombatUpdate()
    -- 设置初始的时候是否隐藏
    if self.Config.isDisplayMouseEnter == true then
        self:SetBarTransparency()
    end
end

---@param eleConfig ElementConfig
---@return ElementCbInfo[]
function ElementFrame:GetCbs(eleConfig)
    if eleConfig.loadCond and LoadCondition:Pass(eleConfig.loadCond) == false then
        return {}
    end
    if eleConfig.type == const.ELEMENT_TYPE.ITEM then
        local item = E:ToItem(eleConfig)
        ---@type ElementCbInfo
        local cb = { f = ECB.CallbackOfSingleMode, p = item, r = {}, btns = {}, e = E:GetEvents(item) }
        return { cb, }
    elseif eleConfig.type == const.ELEMENT_TYPE.ITEM_GROUP then
        local itemGroup = E:ToItemGroup(eleConfig)
        ---@type ElementCbInfo
        local cb
        if itemGroup.extraAttr.mode == const.ITEMS_GROUP_MODE.RANDOM then
            cb = { f = ECB.CallbackOfRandomMode, p = itemGroup, r = {}, btns = {}, e = E:GetEvents(itemGroup) }
        end
        if itemGroup.extraAttr.mode == const.ITEMS_GROUP_MODE.SEQ then
            cb = { f = ECB.CallbackOfSeqMode, p = itemGroup, r = {}, btns = {}, e = E:GetEvents(itemGroup) }
        end
        return { cb, }
    elseif eleConfig.type == const.ELEMENT_TYPE.SCRIPT then
        local script = E:ToScript(eleConfig)
        if script.extraAttr.script then
            ---@type ElementCbInfo
            local cb = { f = ECB.CallbackOfScriptMode, p = script, r = {}, btns = {}, e = E:GetEvents(script) }
            return { cb, }
        else
            return {}
        end
    elseif eleConfig.type == const.ELEMENT_TYPE.BAR then
        ---@type ElementCbInfo[]
        local cbs = {}
        local bar = E:ToBar(eleConfig)
        for _, _eleConfig in ipairs(bar.elements) do
            if _eleConfig.loadCond and _eleConfig.loadCond then
                local eleConfigCbs = self:GetCbs(_eleConfig)
                for _, _cbs in ipairs(eleConfigCbs) do
                    table.insert(cbs, _cbs)
                end
            end
        end
        return cbs
    end
    return {}
end

-- 创建Bar
function ElementFrame:UpdateBar()
    if not self.Bar then
        local barFrame = CreateFrame("Frame", ("HtBarFrame-%s"):format(self.Config.id), self.Window)
        self.Bar = { BarFrame = barFrame, Icon = self.Config.icon }
    end
    if self.Config.elesGrowth == const.GROWTH.RIGHTBOTTOM then
        self.Bar.BarFrame:SetPoint("TOPLEFT", self.Window, "TOPLEFT", 0, 0)
    elseif self.Config.elesGrowth == const.GROWTH.RIGHTTOP then
        self.Bar.BarFrame:SetPoint("BOTTOMLEFT", self.Window, "BOTTOMLEFT", 0, 0)
    elseif self.Config.elesGrowth == const.GROWTH.LEFTBOTTOM then
        self.Bar.BarFrame:SetPoint("TOPRIGHT", self.Window, "TOPRIGHT", 0, 0)
    elseif self.Config.elesGrowth == const.GROWTH.LEFTTOP then
        self.Bar.BarFrame:SetPoint("BOTTOMRIGHT", self.Window, "BOTTOMRIGHT", 0, 0)
    elseif self.Config.elesGrowth == const.GROWTH.TOPLEFT then
        self.Bar.BarFrame:SetPoint("BOTTOMRIGHT", self.Window, "BOTTOMRIGHT", 0, 0)
    elseif self.Config.elesGrowth == const.GROWTH.TOPRIGHT then
        self.Bar.BarFrame:SetPoint("BOTTOMLEFT", self.Window, "BOTTOMLEFT", 0, 0)
    elseif self.Config.elesGrowth == const.GROWTH.BOTTOMLEFT then
        self.Bar.BarFrame:SetPoint("TOPRIGHT", self.Window, "TOPRIGHT", 0, 0)
    elseif self.Config.elesGrowth == const.GROWTH.BOTTOMRIGHT then
        self.Bar.BarFrame:SetPoint("TOPLEFT", self.Window, "TOPLEFT", 0, 0)
    else
        -- 默认右下
        self.Bar.BarFrame:SetPoint("TOPLEFT", self.Window, "TOPLEFT", 0, 0)
    end
    self.Bar.BarFrame:SetWidth(self.IconWidth)
    self.Bar.BarFrame:SetHeight(self.IconHeight)
end

-- 更新
---@param event string | nil
function ElementFrame:Update(event)
    if InCombatLockdown() then
        self:InCombatUpdate(event)
    else
        self:OutCombatUpdate(event)
    end
end

-- 战斗外更新
---@param event string | nil
function ElementFrame:OutCombatUpdate(event)
    if event and self.Events[event] == nil then
        return
    end
    -- 首先判断载入条件
    if LoadCondition:Pass(self.Config.loadCond) == false then
        self:HideWindow()
        return
    end
    if self.Cbs then
        local btnIndex = 1
        for _, cb in ipairs(self.Cbs) do
            ---@type CbResult[]
            local cbResults = {}
            -- 判断是否通过展示条件判断，如果不通过，则相当于当前元素全部隐藏
            if LoadCondition:Pass(cb.p.loadCond) == true then
                cbResults = cb.f(cb.p, cb.r)
                -- 反向遍历 rs 数组
                for i = #cbResults, 1, -1 do
                    local r = cbResults[i]
                    ECB:UpdateSelfTrigger(r)
                    r.effects = ECB:UseTrigger(cb.p, r)
                    -- 战斗外更新，如果发现隐藏按钮则是移除按钮
                    local hideBtn = false
                    if r.effects then
                        for _, effect in ipairs(r.effects) do
                            if effect.type == "btnHide" then
                                hideBtn = true
                                break
                            end
                        end
                    end
                    if hideBtn == true then
                        table.remove(cbResults, i)
                    end
                end
            else
                cbResults = {}
            end
            cb.r = cbResults
            for cbIndex, _ in ipairs(cb.r) do
                -- 如果图标不足，补全图标
                if cbIndex > #cb.btns then
                    local btn = Btn:New(self, cb, cbIndex)
                    table.insert(cb.btns, btn)
                end
                local btn = cb.btns[cbIndex]
                btn:UpdateByElementFrame(cbIndex, btnIndex, event)
                btnIndex  = btnIndex + 1
            end
            -- 如果按钮过多，删除冗余按钮
            if #cb.r < #cb.btns then
                for i = #cb.btns, #cb.r + 1, -1 do
                    cb.btns[i]:Delete()
                    cb.btns[i] = nil
                end
            end

        end
    end

    self:SetWindowSize()
    if self.Config.loadCond and self.Config.loadCond.CombatCond == true then
        self:HideWindow()
    else
        self:ShowWindow()
    end
end

-- 战斗中更新
---@param event string | nil
function ElementFrame:InCombatUpdate(event)
    if event and self.Events[event] == nil then
        return
    end
    if LoadCondition:Pass(self.Config.loadCond) == false then
        return
    end
    if self.Cbs then
        for _, cb in ipairs(self.Cbs) do
            if cb.btns then
                for _, btn in ipairs(cb.btns) do
                    btn:UpdateBySelf(event)
                end
            end
        end
    end
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
                self:SetBarNonTransparency()
            end
            self.IsMouseInside = true
        elseif not mouseOver and self.IsMouseInside then
            if self.Config.isDisplayMouseEnter == true then
                self:SetBarTransparency()
            end
            self.IsMouseInside = false
        end
    end)
end

function ElementFrame:UpdateWindow()
    if self:IsHorizontal() then
        self.Window:SetHeight(self.IconHeight)
        self.Window:SetWidth(self.IconWidth)
    else
        self.Window:SetHeight(self.IconHeight)
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

-- 创建编辑模式背景
function ElementFrame:CreateEditModeFrame()
    self.EditModeBg = self.Window:CreateTexture(nil, "BACKGROUND")
    self.EditModeBg:SetPoint("TOPLEFT", self.Window, "TOPLEFT", 0, 0)
    self.EditModeBg:SetPoint("BOTTOMRIGHT", self.Window, "BOTTOMRIGHT", 0, 0)
    self.EditModeBg:SetColorTexture(0, 0, 1, 0.5) -- 蓝色半透明背景
    self.EditModeBg:Hide()
end


--- 将单个Bar类型设置成透明
function ElementFrame:SetBarTransparency()
    self.Bar.BarFrame:SetAlpha(0)
end

--- 将单个Bar类型设置成不透明
function ElementFrame:SetBarNonTransparency()
    self.Bar.BarFrame:SetAlpha(1)
end

--- 将单个Bar类型设置成隐藏
function ElementFrame:SetBarHidden()
    self.Bar.BarFrame:Hide()
end

--- 将单个Bar类型设置成不透明
function ElementFrame:SetBarShow()
    self.Bar.BarFrame:Show()
end

-- 设置窗口宽度：窗口会遮挡视图，会减少鼠标可点击范围，因此窗口宽度尽可能小
function ElementFrame:SetWindowSize()
    local buttonNum = 1
    if self.Cbs then
        buttonNum = 0
        for _, cb in ipairs(self.Cbs) do
            if cb.btns then
                buttonNum = buttonNum + #cb.btns
            end
        end
        buttonNum = buttonNum or 1
    end
    if self:IsHorizontal() then
        self.Window:SetWidth(self.IconWidth * buttonNum)
        self.Window:SetHeight(self.IconHeight)
    else
        self.Window:SetWidth(self.IconWidth)
        self.Window:SetHeight(self.IconHeight * buttonNum)
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
        self:SetBarHidden()
    end
end

-- 关闭编辑模式
function ElementFrame:CloseEditMode()
    if addon.G.IsEditMode == false then
        self.EditModeBg:Hide()
        self:SetBarShow()
    end
end

-- 卸载框体
function ElementFrame:Delete()
    self.Window:Hide()
    self.Window:ClearAllPoints()
    self.Window = nil
end
