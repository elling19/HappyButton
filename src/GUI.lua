local _, HT = ...

local AceGUI = LibStub("AceGUI-3.0")

-- 获取鼠标的 UI 坐标
local function GetMousePosition()
    local x, y = GetCursorPosition()  -- 获取原始鼠标坐标
    local scale = UIParent:GetEffectiveScale()  -- 获取UI缩放
    return x / scale, y / scale  -- 返回缩放后的坐标
end

---@type Utils
local U = HT.Utils

---@type HtItem
local HtItem = HT.HtItem

---@class ToolkitGUI 
local ToolkitGUI = {
    CategoryList = {},
    IconFrameList = {},  -- 存储图标容器列表
    Window = nil,
    IsOpen = false,
    IsMouseInside = false,  -- 鼠标是否处在框体内
    UISize = {
        IconSize = 32,
        Width = (32 * 50) + (32 + 5),
    },
    tabs = {}, -- 分类切换按钮
    currentTabIndex = nil,
}

function ToolkitGUI.CollectConfig()
    ToolkitGUI.CategoryList = {}
    local categoryList = HT.AceAddon.db.profile.categoryList
    local iconSourceList = HT.AceAddon.db.profile.iconSourceList
    for _, category in ipairs(categoryList) do
        if category.isDisplay then
            local pool = {}
            pool.icon = category.icon
            pool.title = category.title
            pool.sourceList = {}
            for _, thing in ipairs(category.sourceList) do
                ---@type IconSource
                local source
                for _, _source in ipairs(iconSourceList) do
                    if _source.title == thing.title then
                        source = _source
                        break
                    end
                end
                if source then
                    if source.type == "SCRIPT" then
                        table.insert(pool.sourceList, {type="SCRIPT", callback=HtItem.CallbackOfScriptMode, source=source})
                    end
                    if source.type == "ITEM_GROUP" then
                        if source.attrs.mode == HtItem.ItemGroupMode.RANDOM then
                            table.insert(pool.sourceList, {type="ITEM_GROUP", callback=HtItem.CallbackOfRandomMode, source=source})
                        end
                        if source.attrs.mode == HtItem.ItemGroupMode.SEQ then
                            table.insert(pool.sourceList, {type="ITEM_GROUP", callback=HtItem.CallbackOfSeqMode, source=source})
                        end
                        if source.attrs.mode == HtItem.ItemGroupMode.MULTIPLE then
                            for _, item in ipairs(source.attrs.itemList) do
                                ---@type boolean
                                local needDisplay = true
                                if source.attrs.displayUnLearned == false then
                                    if HtItem.IsLearned(item) == false then
                                        needDisplay = false
                                    end
                                end
                                if needDisplay == true then
                                    ---@type IconSource
                                    local newSource = {
                                        attrs = {
                                            mode=HtItem.ItemGroupMode.SINGLE,
                                            replaceName=source.attrs.replaceName,
                                            displayUnLearned=source.attrs.displayUnLearned,
                                            item=item
                                        },
                                        title = source.title,
                                        type = "ITEM_GROUP"
                                    }
                                    table.insert(pool.sourceList, {type="ITEM_GROUP", callback=HtItem.CallbackOfSingleMode, source=newSource})
                                end
                            end
                        end
                    end
                end
            end
            if #pool.sourceList > 0 then
                table.insert(ToolkitGUI.CategoryList, pool)
            end
        end
    end
end

function ToolkitGUI.CreateFrame()
    local iconSize = ToolkitGUI.UISize.IconSize
    local categoryNum = #ToolkitGUI.CategoryList
    local windowHeight = iconSize * categoryNum

    local window = AceGUI:Create("SimpleGroup")
    window.frame:SetFrameStrata("BACKGROUND")
    window:SetLayout("Flow")
    window:SetHeight(windowHeight + 2 * iconSize)
    window:SetWidth(600)
    window.frame:Hide()

    -- 将窗口定位到初始位置
    window.frame:ClearAllPoints()
    local x = HT.AceAddon.db.profile.windowPositionX or 0
    local y = - (HT.AceAddon.db.profile.windowPositionY or 0)
    window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)


    window.frame:SetMovable(true)
    window.frame:EnableMouse(true)
    window.frame:RegisterForDrag("LeftButton")
    window.frame:SetClampedToScreen(true)

    -- 监听拖动事件并更新位置
    window.frame:SetScript("OnDragStart", function(frame)
        frame:StartMoving()
    end)

    -- 监听窗口的拖拽事件
    window.frame:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        local newX, newY = frame:GetLeft(), frame:GetTop() - UIParent:GetHeight()
        -- 更新数据库中的位置
        HT.AceAddon.db.profile.windowPositionX = math.floor(newX)
        HT.AceAddon.db.profile.windowPositionY = - math.floor(newY)
    end)

    -- 创建内容容器滚动区域
    local tabGroup = AceGUI:Create("SimpleGroup")
    tabGroup:SetWidth(iconSize)
    tabGroup:SetHeight(windowHeight)
    tabGroup:SetLayout("List")
    window:AddChild(tabGroup)
    window.frame:SetScript("OnUpdate", function(self)
        local mouseOver = self:IsMouseOver()
        if mouseOver and not ToolkitGUI.IsMouseInside then
            ToolkitGUI.IsMouseInside = true
        elseif not mouseOver and ToolkitGUI.IsMouseInside then
            ToolkitGUI.HideAllTabs()
            ToolkitGUI.IsMouseInside = false
        end
    end)

    local buttonCount = 0 -- 计算图标总数量，用来计算滚动距离
    for _, category in ipairs(ToolkitGUI.CategoryList) do
        buttonCount = buttonCount + #category.sourceList + 1  -- 分类图标个数 + 分类标题
    end
    local scrollRatio  -- 滚动系数
    if buttonCount <= categoryNum then
        scrollRatio = 1
    else
        scrollRatio = 1000 / (buttonCount - categoryNum)
    end
    local topCount = 0
    for _, category in ipairs(ToolkitGUI.CategoryList) do
        table.insert(ToolkitGUI.tabs, {title=category.title, icon=category.icon, button=nil, scrollHeight=topCount * scrollRatio})
        topCount =  topCount + #category.sourceList + 1
    end
    for index, tab in ipairs(ToolkitGUI.tabs) do
        local tabContainer = AceGUI:Create("SimpleGroup")
        tabContainer:SetWidth(iconSize)
        tabContainer:SetHeight(iconSize)
        tabContainer:SetLayout("Fill")
        local tabIcon = CreateFrame("Button", ("tab-%s"):format(index), tabContainer.frame, "UIPanelButtonTemplate")
        if tonumber(tab.icon) then
            tabIcon:SetNormalTexture(tonumber(tab.icon))
        else
            tabIcon:SetNormalTexture(tab.icon)
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
            ToolkitGUI.ShowTab(index)
        end)
        tabIcon:SetScript("OnClick", function(_, _)
            ToolkitGUI.ToggleTab(index)
        end)
        tabGroup:AddChild(tabContainer)
        tab.button = tabIcon
    end


    for cateIndex, category in ipairs(ToolkitGUI.CategoryList) do
        local iconsFrame = AceGUI:Create("SimpleGroup")
        iconsFrame:SetWidth(#category.sourceList * 32)
        iconsFrame:SetHeight(32)
        iconsFrame:SetLayout("Flow")
        iconsFrame.frame:Hide()
        for poolIndex, pool in ipairs(category.sourceList) do
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
            pool.text = buttonContainer.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            pool.text:SetPoint("TOP", buttonContainer.frame, "BOTTOM", 0, -5)
            pool.text:SetWidth(32)
            if callbackResult ~= nil then
                -- 如果回调函数返回的是item模式
                if not (callbackResult.item == nil) then
                    -- 更新图标宏
                    ToolkitGUI.SetPoolMacro(pool)
                    -- 更新冷却计时
                    ToolkitGUI.SetPoolCooldown(pool)
                    -- 更新鼠标移入移出事件
                    ToolkitGUI.SetButtonMouseEvent(pool)
                    ToolkitGUI.SetPoolLearnable(pool)
                elseif not (callbackResult.leftClickCallback == nil) then
                    callbackResult.leftClickCallback()
                end
                if callbackResult.text then
                    pool.text:SetText(U.String.ToVertical(callbackResult.text))
                end
            end
            iconsFrame:AddChild(buttonContainer)
            iconsFrame.frame:SetPoint("TOPLEFT", window.frame, "TOPLEFT", 32, - 32 * (cateIndex - 1))
        end
        table.insert(ToolkitGUI.IconFrameList, iconsFrame)
    end
    ToolkitGUI.Window = window

    if HT.AceAddon.db.profile.showGuiDefault == true then
        ToolkitGUI.ShowWindow()
    else
        ToolkitGUI.HideWindow()
    end
end

function ToolkitGUI.ToggleTab(index)
    if ToolkitGUI.currentTabIndex == index then
        ToolkitGUI.currentTabIndex = nil
        ToolkitGUI.IconFrameList[index].frame:Hide()
    else
        ToolkitGUI.currentTabIndex = index
        ToolkitGUI.IconFrameList[index].frame:Show()
    end
end

function ToolkitGUI.ShowTab(index)
    ToolkitGUI.currentTabIndex = index
    for tabIndex, tab in ipairs(ToolkitGUI.tabs) do
        if tab.button ~= nil then
            ToolkitGUI.IconFrameList[tabIndex].frame:Hide()
        end
    end
    ToolkitGUI.IconFrameList[index].frame:Show()
end

function ToolkitGUI.HideAllTabs()
    for _, frame in ipairs(ToolkitGUI.IconFrameList) do
        frame.frame:Hide()
    end
    ToolkitGUI.currentTabIndex = nil
end

function ToolkitGUI.Update()
    for _, category in ipairs(ToolkitGUI.CategoryList) do
        for _, pool in ipairs(category.sourceList) do
            local callbackResult = pool.callback(pool.source)
            if not (callbackResult == nil) then
                pool._callbackResult = callbackResult
                ToolkitGUI.SetPoolCooldown(pool)
                ToolkitGUI.SetPoolMacro(pool)
                ToolkitGUI.SetPoolLearnable(pool)
            end
        end
    end
end

-- 隐藏窗口
function ToolkitGUI.HideWindow()
    if ToolkitGUI.IsOpen == true then
        ToolkitGUI.Window.frame:Hide()
        ToolkitGUI.IsOpen = false
        ToolkitGUI.HideAllTabs()
    end
end

-- 显示窗口
function ToolkitGUI.ShowWindow()
    if ToolkitGUI.IsOpen == false then
        ToolkitGUI.Window.frame:Show()
        ToolkitGUI.Update()
        ToolkitGUI.IsOpen = true
    end
end

-- 更新pool的宏文案
function ToolkitGUI.SetPoolMacro(pool)
    local callbackResult = pool._callbackResult
    if callbackResult == nil or callbackResult.item == nil then
        return
    end
    if pool.button == nil then
        return
    end
    -- 设置宏命令
    pool.button:SetAttribute("type", "macro") -- 设置按钮为宏类型
    if callbackResult.icon then
        pool.button:SetNormalTexture(callbackResult.icon)
    end
    local macroText = ""
    if callbackResult.item.type == HtItem.Type.ITEM then
        macroText = "/use item:" .. callbackResult.item.id
    elseif callbackResult.item.type == HtItem.Type.TOY then
        macroText = "/use item:" .. callbackResult.item.id
    elseif callbackResult.item.type == HtItem.Type.SPELL then
        macroText = "/cast " .. callbackResult.item.name
    elseif callbackResult.item.type == HtItem.Type.MOUNT then
        macroText = "/cast " .. callbackResult.item.name
    elseif callbackResult.item.type == HtItem.Type.PET then
        macroText = "/SummonPet " .. callbackResult.item.name
    end
    -- 宏命令附加更新冷却计时
    macroText = macroText .. "\r" .. ("/sethappytoolkitguicooldown %s %s"):format(pool._cateIndex, pool._poolIndex)
    -- 宏命令附加关闭窗口
    if callbackResult.closeGUIAfterClick == nil or callbackResult.closeGUIAfterClick == true then
        macroText = macroText .. "\r" .. "/closehappytoolkitgui"
    end
    pool.button:SetAttribute("macrotext", macroText)
    if callbackResult.text then
        pool.text:SetText(U.String.ToVertical(callbackResult.text))
    end
end

-- 设置pool的冷却
function ToolkitGUI.SetPoolCooldown(pool)
    if pool.button == nil then
        return
    end
    local callbackResult = pool._callbackResult
    if callbackResult == nil or callbackResult.item == nil then
        return
    end
    if pool.button.cooldown == nil then
        -- 创建冷却效果
        pool.button.cooldown = CreateFrame("Cooldown", nil, pool.button, "CooldownFrameTemplate")
        pool.button.cooldown:SetAllPoints(pool.button)  -- 设置冷却效果覆盖整个按钮
        pool.button.cooldown:SetDrawEdge(true)  -- 显示边缘
        pool.button.cooldown:SetHideCountdownNumbers(true)  -- 隐藏倒计时数字
    end
    local item = callbackResult.item
    -- 更新冷却倒计时
    if item.type == HtItem.Type.ITEM then
        local startTimeSeconds, durationSeconds, enableCooldownTimer = C_Item.GetItemCooldown(item.id)
        if enableCooldownTimer and durationSeconds > 0 then
            pool.button.cooldown:SetCooldown(startTimeSeconds, durationSeconds)
        else
            pool.button.cooldown:Clear()
        end
    elseif item.type == HtItem.Type.TOY then
        local startTimeSeconds, durationSeconds, enableCooldownTimer = C_Item.GetItemCooldown(item.id)
        if enableCooldownTimer and durationSeconds > 0 then
            pool.button.cooldown:SetCooldown(startTimeSeconds, durationSeconds)
        else
            pool.button.cooldown:Clear()
        end
    elseif item.type == HtItem.Type.SPELL then
        local spellCooldownInfo = C_Spell.GetSpellCooldown(item.id)
        if spellCooldownInfo and spellCooldownInfo.isEnabled == true and spellCooldownInfo.duration > 0 then
            pool.button.cooldown:SetCooldown(spellCooldownInfo.startTime, spellCooldownInfo.duration)
        else
            pool.button.cooldown:Clear()
        end
    elseif item.type == HtItem.Type.PET then
        local speciesId, petGUID = C_PetJournal.FindPetIDByName(item.name)
        if petGUID then
            local start, duration, isEnabled = C_PetJournal.GetPetCooldownByGUID(petGUID)
            if isEnabled and duration > 0 then
                pool.button.cooldown:SetCooldown(start, duration)
            else
                pool.button.cooldown:Clear()
            end
        end
    end
end

-- 当pool上的技能没有学习的时候，置为灰色
function ToolkitGUI.SetPoolLearnable(pool)
    if pool == nil then
        return
    end
    local callbackResult = pool._callbackResult
    if callbackResult == nil or callbackResult.item == nil then
        return
    end
    local item = callbackResult.item
    local hasThisThing = false
    if item.type == HtItem.Type.ITEM then
        local count = C_Item.GetItemCount(item.id, false)
        if not (count == 0) then
            hasThisThing = true
        end
    elseif item.type == HtItem.Type.TOY then
        if PlayerHasToy(item.id) then
            hasThisThing = true
        end
    elseif item.type == HtItem.Type.SPELL then
        if IsSpellKnown(item.id) then
            hasThisThing = true
        end
    elseif item.type == HtItem.Type.MOUNT then
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(item.id)
        if isCollected then
            hasThisThing = true
        end
    elseif item.type == HtItem.Type.PET then
        for petIndex = 1, C_PetJournal.GetNumPets() do
            local _, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByIndex(petIndex)
            if speciesID == item.id then
                hasThisThing = true
                break
            end
        end
    end
    -- 如果没有学习这个技能，则将图标和文字改成灰色半透明
    if hasThisThing == false then
        if pool.button then
            pool.button:SetEnabled(false)
            pool.button:SetAlpha(0.5)
        end
        if pool.text then
            pool.text:SetTextColor(0.5, 0.5, 0.5)
        end
    else
        if pool.button then
            pool.button:SetEnabled(true)
            pool.button:SetAlpha(1)
        end
        if pool.text then
            pool.text:SetTextColor(1, 1, 1)
        end
    end
end

-- 设置button鼠标移入事件
function ToolkitGUI.SetShowGameTooltip(pool)
    local callbackResult = pool._callbackResult
    if callbackResult == nil or callbackResult.item == nil then
        return
    end
    local item = callbackResult.item
    GameTooltip:SetOwner(pool.button, "ANCHOR_RIGHT") -- 设置提示显示的位置
    if item.type == HtItem.Type.ITEM then
        GameTooltip:SetItemByID(item.id)
    elseif item.type == HtItem.Type.TOY then
        GameTooltip:SetToyByItemID(item.id)
    elseif item.type == HtItem.Type.SPELL then
        GameTooltip:SetSpellByID(item.id)
    elseif item.type == HtItem.Type.MOUNT then
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(item.id)
        GameTooltip:SetMountBySpellID(spellID)
    elseif item.type == HtItem.Type.PET then
        local speciesName, speciesIcon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable, creatureDisplayID = C_PetJournal.GetPetInfoBySpeciesID(item.id)
        local speciesId, petGUID = C_PetJournal.FindPetIDByName(speciesName)
        GameTooltip:SetCompanionPet(petGUID)
    end
end

-- 设置button的鼠标移入移出事件
function ToolkitGUI.SetButtonMouseEvent(pool)
    if pool == nil or pool.button == nil then
        return
    end
    pool.button:SetScript("OnLeave", function(_)
        GameTooltip:Hide() -- 隐藏提示
    end)
    pool.button:SetScript("OnEnter", function (_)
        ToolkitGUI.SetShowGameTooltip(pool)
        -- 设置鼠标移入时候的高亮效果为白色半透明效果
        local highlightTexture = pool.button:CreateTexture()
        highlightTexture:SetColorTexture(255, 255, 255, 0.2)
        pool.button:SetHighlightTexture(highlightTexture)
    end)
end

-- 根据索引获取pool
function ToolkitGUI.GetPoolByIndex(cate, poolIndex)
    local catePool = ToolkitGUI.CategoryList[cate]
    if catePool == nil then
        return nil
    end
    local pool = catePool.sourceList[poolIndex]
    return pool
end

-- 初始化UI模块
function ToolkitGUI.Initial()
    ToolkitGUI.CollectConfig()
    ToolkitGUI.CreateFrame()
    ToolkitGUI.Update()
end

HT.ToolkitGUI = ToolkitGUI
