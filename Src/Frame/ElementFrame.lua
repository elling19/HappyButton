local addonName, _ = ...

---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class E: AceModule
local E = addon:GetModule("Element")

---@class Item: AceModule
local Item = addon:GetModule("Item")

---@class AttachFrameCache: AceModule
local AttachFrameCache = addon:GetModule("AttachFrameCache")

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
---@field e table<EventString, any[][]>  -- 监听物品及触发器事件
---@field loadCondEvents table<EventString, any[][]>  -- 监听物品加载条件事件
---@field passLoadCond boolean | nil -- 是否通过物品加载条件，nil表示没有判断
---@field root ElementConfig | nil -- 根元素（通常是BAR），用于继承展示规则
---@field c ElementCbInfo[] | nil  -- 子元素的callback

---@class Bar
---@field BarFrame nil|table|Button
---@field Icon string | number | nil
---@field TriggerButton nil|Button
---@field TriggerIcon nil|Texture
---@field FlyoutFrame nil|Frame
---@field CloseBackdrop nil|Button
---@field CloseClickHandler nil|Button

---@class ElementFrame: AceModule
---@field Cbs ElementCbInfo | nil
---@field Events table<EventString, any[][]>
---@field Config ElementConfig  -- 当前Frame的配置文件
---@field Window Frame
---@field Bar Bar
---@field IsMouseInside boolean  -- 鼠标是否处在框体内
---@field IconHeight number
---@field IconWidth number
---@field BindkeyFontSize number
---@field BindkeyMargin number
---@field CountFontSize number
---@field CooldownFontSize number
---@field CurrentBarIndex number | nil 当前选择的Bar的下标
---@field attachFrameName string | nil -- 挂载frame的名字
---@field attachFrame Frame | nil -- 挂载frame
local ElementFrame = addon:NewModule("ElementFrame")



-- 判断是否水平方向展示
function ElementFrame:IsHorizontal()
    return
        self.Config.elesGrowth == const.GROWTH.LEFTBOTTOM
        or self.Config.elesGrowth == const.GROWTH.LEFTTOP
        or self.Config.elesGrowth == const.GROWTH.RIGHTBOTTOM
        or self.Config.elesGrowth == const.GROWTH.RIGHTTOP
end

---@return boolean
function ElementFrame:IsFlyoutEnabled()
    return self.Config and self.Config.flyout == true
end

---@return boolean
function ElementFrame:IsFlyoutAutoCollapseEnabled()
    if not self:IsFlyoutEnabled() then
        return false
    end
    return self.Config.flyoutAutoCollapse ~= false
end

---@return number
function ElementFrame:GetIconBaseSize()
    local base = math.min(self.IconWidth or 0, self.IconHeight or 0)
    if base <= 0 then
        local defaultW = addon.G and addon.G.iconWidth or 36
        local defaultH = addon.G and addon.G.iconHeight or 36
        base = math.min(defaultW, defaultH)
    end
    return base
end

---@param ratio number
---@param minValue number
---@param maxValue number
---@return number
function ElementFrame:GetScaledValue(ratio, minValue, maxValue)
    local value = math.floor(self:GetIconBaseSize() * ratio + 0.5)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

function ElementFrame:RefreshFontMetrics()
    self.BindkeyFontSize = self:GetScaledValue(0.38, 11, 24)
    self.BindkeyMargin = self:GetScaledValue(0.06, 2, 8)
    self.CountFontSize = self:GetScaledValue(0.36, 12, 28)
    self.CooldownFontSize = self:GetScaledValue(0.40, 12, 36)
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
    obj:RefreshFontMetrics()
    obj.CurrentBarIndex = 1
    ElementFrame.ReLoadUI(obj)
    return obj
end

function ElementFrame:ReLoadUI()
    self.IconHeight = self.Config.iconHeight or addon.G.iconHeight
    self.IconWidth = self.Config.iconWidth or addon.G.iconWidth
    self:RefreshFontMetrics()
    -- 移除旧的Cbs中的按钮
    self:ClearCbBtns(self.Cbs)
    self.Cbs = self:GetCbs(self.Config, nil)
    self.Events = E:GetEvents(self.Config, nil)
    self:RefreshAttachFrame()
    self:UpdateBar()
    self:CreateEditModeFrame()
    self:Update("PLAYER_ENTERING_WORLD", {})
    -- 设置初始的时候是否隐藏
    if self.Config.isDisplayMouseEnter == true then
        self:SetBarTransparency()
    end
end

-- Re-resolve attach frame and update window when target frame becomes available later.
---@return boolean changed
function ElementFrame:RefreshAttachFrame()
    local attachFrameName, attachFrame = self:GetAttachFrame()
    local changed = (self.attachFrame ~= attachFrame)
        or (self.attachFrameName ~= attachFrameName)
    self.attachFrameName = attachFrameName
    self.attachFrame = attachFrame

    if self.attachFrame then
        AttachFrameCache:Add(self.attachFrameName, self.attachFrame)
    end

    if self.attachFrame and changed then
        self:UpdateWindow()
    elseif self.attachFrame == nil then
        -- Target frame is not available yet. Keep window hidden until a later event retries and succeeds.
        self:HideWindow()
    end
    return changed
end

---@param eleConfig ElementConfig
---@param rootConfig ElementConfig | nil
---@return ElementCbInfo | nil
function ElementFrame:GetCbs(eleConfig, rootConfig)
    if eleConfig.type == const.ELEMENT_TYPE.ITEM then
        local item = E:ToItem(eleConfig)
        ---@type ElementCbInfo
        local cb = { f = ECB.CallbackOfSingleMode, p = item, r = {}, btns = {}, e = E:GetEvents(item, rootConfig), loadCondEvents = E:GetLoadCondEvents(eleConfig), root = rootConfig or eleConfig, c = nil }
        return cb
    elseif eleConfig.type == const.ELEMENT_TYPE.MACRO then
        local macro = E:ToMacro(eleConfig)
        ---@type ElementCbInfo
        local cb = { f = ECB.CallbackOfMacroMode, p = macro, r = {}, btns = {}, e = E:GetEvents(macro, rootConfig), loadCondEvents = E:GetLoadCondEvents(eleConfig), root = rootConfig or eleConfig, c = nil }
        return cb
    elseif eleConfig.type == const.ELEMENT_TYPE.ITEM_GROUP then
        local itemGroup = E:ToItemGroup(eleConfig)
        ---@type ElementCbInfo
        local cb
        if itemGroup.extraAttr.mode == const.ITEMS_GROUP_MODE.RANDOM then
            cb = { f = ECB.CallbackOfRandomMode, p = itemGroup, r = {}, btns = {}, e = E:GetEvents(itemGroup, rootConfig), loadCondEvents = E:GetLoadCondEvents(eleConfig), root = rootConfig or eleConfig, c = nil }
        end
        if itemGroup.extraAttr.mode == const.ITEMS_GROUP_MODE.SEQ then
            cb = { f = ECB.CallbackOfSeqMode, p = itemGroup, r = {}, btns = {}, e = E:GetEvents(itemGroup, rootConfig), loadCondEvents = E:GetLoadCondEvents(eleConfig), root = rootConfig or eleConfig, c = nil }
        end
        return cb
    elseif eleConfig.type == const.ELEMENT_TYPE.SCRIPT then
        local script = E:ToScript(eleConfig)
        if script.extraAttr.script then
            ---@type ElementCbInfo
            local cb = { f = ECB.CallbackOfScriptMode, p = script, r = {}, btns = {}, e = E:GetEvents(script, rootConfig), loadCondEvents = E:GetLoadCondEvents(eleConfig), root = rootConfig or eleConfig, c = nil }
            return cb
        else
            return nil
        end
    elseif eleConfig.type == const.ELEMENT_TYPE.BAR then
        ---@type ElementCbInfo[]
        local cCb = {}
        local bar = E:ToBar(eleConfig)
        if bar.elements then
            for _, _eleConfig in ipairs(bar.elements) do
                table.insert(cCb, ElementFrame:GetCbs(_eleConfig, rootConfig or eleConfig))
            end
        end
        local cb = { f = nil, p = bar, r = {}, btns = {}, e = E:GetEvents(bar, rootConfig), loadCondEvents = E:GetLoadCondEvents(eleConfig), root = rootConfig or eleConfig, c = cCb }
        return cb
    end
    return nil
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

    if self.Bar.TriggerButton == nil then
        local trigger = CreateFrame("Button", ("HtBarTrigger-%s"):format(self.Config.id), self.Bar.BarFrame, "SecureHandlerClickTemplate")
        trigger:SetAllPoints(self.Bar.BarFrame)
        local icon = trigger:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(trigger)
        icon:SetTexture(self.Config.icon or 134400)
        self.Bar.TriggerButton = trigger
        self.Bar.TriggerIcon = icon
    end

    if self.Bar.FlyoutFrame == nil then
        local flyout = CreateFrame("Frame", ("HtBarFlyout-%s"):format(self.Config.id), self.Window, "SecureHandlerShowHideTemplate")
        flyout:SetFrameStrata("FULLSCREEN_DIALOG")
        flyout:Hide()
        self.Bar.FlyoutFrame = flyout
    end

    -- 关闭处理器：供按钮宏追加 /click 使用
    if self.Bar.CloseClickHandler == nil then
        local closeHandler = CreateFrame("Button", ("HtFlyoutClose-%s"):format(self.Config.id), UIParent, "SecureHandlerClickTemplate")
        closeHandler:Hide()
        closeHandler:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
        closeHandler:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
        self.Bar.CloseClickHandler = closeHandler
    end

    -- 全屏点击关闭底板：点击 flyout 外任意位置可关闭
    if self.Bar.CloseBackdrop == nil then
        local backdrop = CreateFrame("Button", ("HtFlyoutBackdrop-%s"):format(self.Config.id), UIParent, "SecureHandlerClickTemplate")
        backdrop:SetAllPoints(UIParent)
        backdrop:SetFrameStrata("FULLSCREEN")
        backdrop:EnableMouse(true)
        backdrop:Hide()
        self.Bar.CloseBackdrop = backdrop
    end
    -- 绑定底板与 FlyoutFrame（非战斗才能调用 SetFrameRef/SetAttribute）
    if not InCombatLockdown() then
        local backdrop = self.Bar.CloseBackdrop
        local flyout   = self.Bar.FlyoutFrame
        if backdrop and flyout then
            ---@diagnostic disable-next-line: undefined-field
            backdrop:SetFrameRef("FlyoutFrame", flyout)
            ---@diagnostic disable-next-line: undefined-field
            backdrop:SetAttribute("_onclick", [=[
                local flyout = self:GetFrameRef("FlyoutFrame")
                if flyout then flyout:Hide() end
            ]=])
            -- FlyoutFrame 显隐时同步底板
            flyout:HookScript("OnShow", function() backdrop:Show() end)
            flyout:HookScript("OnHide", function() backdrop:Hide() end)
        end

        local closeHandler = self.Bar.CloseClickHandler
        if closeHandler and flyout then
            ---@diagnostic disable-next-line: undefined-field
            closeHandler:SetFrameRef("FlyoutFrame", flyout)
            ---@diagnostic disable-next-line: undefined-field
            closeHandler:SetAttribute("_onclick", [=[
                local flyout = self:GetFrameRef("FlyoutFrame")
                if flyout then flyout:Hide() end
            ]=])
        end
    end

    if self.Bar.TriggerIcon then
        self.Bar.TriggerIcon:SetTexture(self.Config.icon or 134400)
    end
    self:ApplyTriggerSkin()

    self:UpdateFlyoutAnchor()
    self:UpdateFlyoutSecureHandler()

    if self:IsFlyoutEnabled() then
        self.Bar.TriggerButton:Show()
    else
        self.Bar.TriggerButton:Hide()
        if self.Bar.FlyoutFrame and self.Bar.FlyoutFrame:IsShown() then
            self.Bar.FlyoutFrame:Hide()
        end
    end
end

-- 对 TriggerButton/TriggerIcon 应用当前皮肤（图标裁切 + 高亮纹理）
function ElementFrame:ApplyTriggerSkin()
    local trigger = self.Bar and self.Bar.TriggerButton
    local icon    = self.Bar and self.Bar.TriggerIcon
    if not trigger or not icon then
        return
    end
    -- 图标裁切（与 Btn:ApplyIconCropByProvider 保持一致）
    local provider = Btn:GetSkinProvider()
    if provider == "elvui" then
        local coords = addon.G and addon.G.ElvUI and addon.G.ElvUI.TexCoords
        if type(coords) == "table" and #coords >= 4 then
            icon:SetTexCoord(unpack(coords))
        else
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end
    elseif provider == "ndui" then
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    else
        icon:SetTexCoord(0, 1, 0, 1)
    end
    -- 高亮/按下纹理
    local white8x8 = "Interface\\Buttons\\WHITE8x8"
    if addon.G and addon.G.ElvUI and addon.G.ElvUI.Media
        and addon.G.ElvUI.Media.Textures and addon.G.ElvUI.Media.Textures.White8x8 then
        white8x8 = addon.G.ElvUI.Media.Textures.White8x8
    end
    trigger:SetHighlightTexture(white8x8)
    trigger:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.3)
    trigger:SetPushedTexture(white8x8)
    trigger:GetPushedTexture():SetVertexColor(1, 1, 1, 0.3)
end

function ElementFrame:UpdateFlyoutAnchor()
    if not self.Bar then
        return
    end
    local flyout = self.Bar.FlyoutFrame
    local anchor = self.Bar.BarFrame
    if flyout == nil or anchor == nil then
        return
    end
    flyout:ClearAllPoints()
    if self.Config.elesGrowth == const.GROWTH.LEFTTOP or self.Config.elesGrowth == const.GROWTH.LEFTBOTTOM then
        flyout:SetPoint("RIGHT", anchor, "LEFT", 0, 0)
    elseif self.Config.elesGrowth == const.GROWTH.TOPLEFT or self.Config.elesGrowth == const.GROWTH.TOPRIGHT then
        flyout:SetPoint("BOTTOM", anchor, "TOP", 0, 0)
    elseif self.Config.elesGrowth == const.GROWTH.BOTTOMLEFT or self.Config.elesGrowth == const.GROWTH.BOTTOMRIGHT then
        flyout:SetPoint("TOP", anchor, "BOTTOM", 0, 0)
    else
        flyout:SetPoint("LEFT", anchor, "RIGHT", 0, 0)
    end
end

function ElementFrame:UpdateFlyoutSecureHandler()
    if not self:IsFlyoutEnabled() then
        return
    end
    if InCombatLockdown() then
        return
    end
    if not self.Bar then
        return
    end
    local trigger = self.Bar.TriggerButton
    local flyout = self.Bar.FlyoutFrame
    if trigger == nil or flyout == nil then
        return
    end
    ---@diagnostic disable-next-line: undefined-field
    trigger:SetFrameRef("FlyoutFrame", flyout)
    ---@diagnostic disable-next-line: undefined-field
    trigger:SetAttribute("_onclick", [=[
        local flyout = self:GetFrameRef("FlyoutFrame")
        if flyout then
            if flyout:IsShown() then
                flyout:Hide()
            else
                flyout:Show()
            end
        end
    ]=])
end


-- 更新
---@param event EventString
---@param eventArgs any[]
function ElementFrame:Update(event, eventArgs)
    -- Before rendering/updating, retry attach-frame resolution if previous mount failed.
    if self.attachFrame == nil then
        self:RefreshAttachFrame()
        if self.attachFrame == nil then
            return
        end
    end

    self:UpdateCbPassLoadCond(self.Cbs, event, eventArgs)
    if InCombatLockdown() then
        self:InCombatUpdate(event, eventArgs)
    else
        self:OutCombatUpdate(event, eventArgs)
    end
end


-- 根据事件更新Cb是否通过加载条件
---@param cb ElementCbInfo
---@param event EventString
---@param eventArgs any[]
function ElementFrame:UpdateCbPassLoadCond(cb, event, eventArgs)
    if cb == nil then
        return
    end
    -- 如果是加载条件的事件，先更新加载条件
    if cb.loadCondEvents[event] ~= nil or cb.passLoadCond == nil then
        cb.passLoadCond = LoadCondition:Pass(cb.p.loadCond)
    end
    if cb.c then
        for _, c in ipairs(cb.c) do
            self:UpdateCbPassLoadCond(c, event, eventArgs)
        end
    end
end

-- 删除cb下面的btn信息
---@param cb ElementCbInfo
function ElementFrame:ClearCbBtns(cb)
    if cb == nil then
        return
    end
    if cb.r then
        cb.r = {}
    end
    if cb.btns then
        for i = #cb.btns, 1, -1 do
            cb.btns[i]:Delete()
            cb.btns[i] = nil
        end
    end
    if cb.c then
        for _, c in ipairs(cb.c) do
            self:ClearCbBtns(c)
        end
    end
end

-- 统计cb下面的btn数量
---@param cb ElementCbInfo
---@return number
function ElementFrame:CountCbBtnNumber(cb)
    if cb == nil then
        return 0
    end
    local count = 0
    if cb.btns then
        count = count + #cb.btns
    end
    if cb.c then
        for _, c in ipairs(cb.c) do
            count = count + self:CountCbBtnNumber(c)
        end
    end
    return count
end

-- 更新cb下面的btn
---@param cb ElementCbInfo
---@param event EventString
---@param eventArgs any[]
function ElementFrame:CbBtnsUpdateBySelf(cb, event, eventArgs)
    if cb == nil then
        return
    end
    if cb.btns then
        for _, btn in ipairs(cb.btns) do
            btn:UpdateBySelf(event, eventArgs)
        end
    end
    if cb.c then
        for _, c in ipairs(cb.c) do
            self:CbBtnsUpdateBySelf(c, event, eventArgs)
        end
    end
end


-- 执行cb函数
---@param cb ElementCbInfo
---@param btnIndex {index: number}  -- 用来维护当前frame的btn顺序
---@param event EventString
---@param eventArgs any[]
function ElementFrame:ExcuteCb(cb, btnIndex, event, eventArgs)
    if cb == nil then
        return
    end
    -- 如果是物品条，判断物品条的加载条件是否满足，满足则继续，不满足则递归清除物品的cb
    if cb.p.type == const.ELEMENT_TYPE.BAR then
        if cb.passLoadCond == true then
            if cb.p.elements then
                for _, c in ipairs(cb.c) do
                    self:ExcuteCb(c, btnIndex, event, eventArgs)
                end
            end
        else
            self:ClearCbBtns(cb)
        end
        return
    end
    -- 非物品条，先判断物品是否满足加载条件
    if cb.passLoadCond == true then
        -- 如果当前事件不是这个cb需要监听的事件，则使用上一次cb;否则执行回调函数cb
        if cb.e[event] ~= nil and E:CompareEventParam(cb.e[event], eventArgs) then
            cb.r = cb.f(cb.p, cb.r)
            -- 反向遍历 rs 数组
            for i = #cb.r, 1, -1 do
                ECB:UpdateSelfTrigger(cb.r[i], event, eventArgs)
                ECB:UseTrigger(cb.p, cb.r[i], cb.root)
                -- 战斗外更新，如果发现隐藏按钮则是移除按钮，首先需要将状态改成false
                cb.r[i].isHideBtn = false
                if cb.r[i].effects then
                    for _, effect in ipairs(cb.r[i].effects) do
                        if effect.type == "btnHide" and effect.status == true then
                            cb.r[i].isHideBtn = true
                            break
                        end
                    end
                end
            end
        end
    else
        cb.r = {}
    end
    local cbBtnIndex = 0
    for _, r in ipairs(cb.r) do
        if r.isHideBtn ~= true then
            btnIndex.index = btnIndex.index + 1
            cbBtnIndex = cbBtnIndex + 1
            -- 如果图标不足，补全图标
            if cbBtnIndex > #cb.btns then
                local btn = Btn:New(self, cb, cbBtnIndex)
                table.insert(cb.btns, btn)
            end
            local btn = cb.btns[cbBtnIndex]
            btn:UpdateByElementFrame(cbBtnIndex, btnIndex.index, event, eventArgs)
        end
    end
    -- 如果按钮过多，删除冗余按钮
    if cbBtnIndex < #cb.btns then
        for i = #cb.btns, cbBtnIndex + 1, -1 do
            cb.btns[i]:Delete()
            cb.btns[i] = nil
        end
    end
end

-- 战斗外更新
---@param event EventString
---@param eventArgs any[]
function ElementFrame:OutCombatUpdate(event, eventArgs)
    if self.Cbs == nil then
        return
    end
    -- 首先判断载入条件
    if self.Cbs.passLoadCond == false then
        self:HideWindow()
        return
    end
    -- 事件不在监听范围内则跳过
    if self.Events[event] == nil or not E:CompareEventParam(self.Events[event], eventArgs) then
        return
    end
    local btnIndex = { index = 0 }
    self:ExcuteCb(self.Cbs, btnIndex, event, eventArgs)
    self:SetWindowSize()
    if self.Config.loadCond and self.Config.loadCond.CombatCond == true then
        self:HideWindow()
    else
        self:ShowWindow()
    end
end

-- 战斗中更新
---@param event EventString
---@param eventArgs any[]
function ElementFrame:InCombatUpdate(event, eventArgs)
    if event and self.Events[event] == nil then
        return
    end
    if LoadCondition:Pass(self.Config.loadCond) == false then
        return
    end
    self:CbBtnsUpdateBySelf(self.Cbs, event, eventArgs)
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


-- 获取当前依附的框体名称、框体
---@return string, Frame | nil
function ElementFrame:GetAttachFrame()
    -- Default: attach to UIParent when config is empty or explicitly UIParent.
    ---@type Frame | nil
    local attachFrame = UIParent
    local attachFrameName = const.ATTACH_FRAME.UIParent
    if self.Config.attachFrame and self.Config.attachFrame ~= const.ATTACH_FRAME.UIParent then
        local frame = _G[self.Config.attachFrame]
        if frame then
            attachFrame = frame
            attachFrameName = self.Config.attachFrame
        else
            -- Target attach frame is configured but not created yet.
            attachFrame = nil
            attachFrameName = self.Config.attachFrame
        end
    end
    return attachFrameName, attachFrame
end

function ElementFrame:UpdateWindow()
    if not self.attachFrame then
        return
    end

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
    self.Window:SetParent(self.attachFrame)
    -- 设置锚点位置
    local frameAnchorPos = self.Config.anchorPos or const.ANCHOR_POS.CENTER
    local attachFrameAnchorPos = self.Config.attachFrameAnchorPos or const.ANCHOR_POS.CENTER
    self.Window:SetPoint(frameAnchorPos, self.attachFrame, attachFrameAnchorPos, x, y)
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
    if self.Bar.FlyoutFrame then
        self.Bar.FlyoutFrame:Hide()
    end
end

--- 将单个Bar类型设置成不透明
function ElementFrame:SetBarShow()
    self.Bar.BarFrame:Show()
end

-- 设置窗口宽度：窗口会遮挡视图，会减少鼠标可点击范围，因此窗口宽度尽可能小
function ElementFrame:SetWindowSize()
    local buttonNum = self:CountCbBtnNumber(self.Cbs)
    if buttonNum == 0 then
        buttonNum = 1
    end
    if self:IsFlyoutEnabled() then
        self.Window:SetWidth(self.IconWidth)
        self.Window:SetHeight(self.IconHeight)
        if self.Bar and self.Bar.FlyoutFrame then
            if self:IsHorizontal() then
                self.Bar.FlyoutFrame:SetWidth(self.IconWidth * buttonNum)
                self.Bar.FlyoutFrame:SetHeight(self.IconHeight)
            else
                self.Bar.FlyoutFrame:SetWidth(self.IconWidth)
                self.Bar.FlyoutFrame:SetHeight(self.IconHeight * buttonNum)
            end
        end
    elseif self:IsHorizontal() then
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

-- 更新配置文件中的物品属性
function ElementFrame:CompleteItemAttr()
    if self.Config == nil then
        return
    end
    E:CompleteItemAttr(self.Config)
end

-- 卸载框体
function ElementFrame:Delete()
    if self.Bar and self.Bar.CloseClickHandler then
        self.Bar.CloseClickHandler:Hide()
        self.Bar.CloseClickHandler:ClearAllPoints()
        self.Bar.CloseClickHandler = nil
    end
    if self.Bar and self.Bar.CloseBackdrop then
        self.Bar.CloseBackdrop:Hide()
        self.Bar.CloseBackdrop:ClearAllPoints()
        self.Bar.CloseBackdrop = nil
    end
    if self.Bar and self.Bar.FlyoutFrame then
        self.Bar.FlyoutFrame:Hide()
        self.Bar.FlyoutFrame:ClearAllPoints()
        self.Bar.FlyoutFrame = nil
    end
    if self.Bar and self.Bar.TriggerButton then
        self.Bar.TriggerButton:Hide()
        self.Bar.TriggerButton:ClearAllPoints()
        self.Bar.TriggerButton = nil
        self.Bar.TriggerIcon = nil
    end
    self.Window:Hide()
    self.Window:ClearAllPoints()
    self.Window = nil
    self:ClearCbBtns(self.Cbs)
end
