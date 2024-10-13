local _, HT = ...

local AceGUI = LibStub("AceGUI-3.0")
local U = HT.Utils
local HtItem = HT.HtItem

local ToolkitGUI = {
    CategoryList = {},
    Window = nil,
    ScrollFrame = nil,
    IsOpen = false,
    UISize = {
        IconSize = 32,
        IconNum = 15, -- 最多展示15个图标
        Width = 204, -- 每个图标32，一共7个。32*7=224。减去20的边框。224-20=204
        Num = 1
    },
    tabs = {}, -- 分类切换按钮
    currentTabIndex = 1,
}

function ToolkitGUI.CollectConfig()
    ToolkitGUI.CategoryList = {}
    local categoryList = HT.AceAddon.db.profile.categoryList
    local iconSourceList = HT.AceAddon.db.profile.iconSourceList
    for _, category in ipairs(categoryList) do
        local pool = {}
        pool.icon = category.icon
        pool.title = category.title
        pool.sourceList = {}
        for _, thing in ipairs(category.sourceList) do
            local source
            for _, _source in ipairs(iconSourceList) do
                if _source.title == thing.title then
                    source = _source
                    break
                end
            end
            if source then
                if source.type == "SCRIPT" then
                    table.insert(pool.sourceList, {type="SCRIPT", callback=HtItem.CallbackOfScriptMode, parameters=source.attrs.script})
                end
                if source.type == "ITEM_GROUP" then
                    if source.attrs.mode == "RANDOM" then
                        table.insert(pool.sourceList, {type="ITEM_GROUP", callback=HtItem.CallbackOfRandomMode, parameters=source.attrs.itemList})
                    end
                    if source.attrs.mode == "SEQ" then
                        table.insert(pool.sourceList, {type="ITEM_GROUP", callback=HtItem.CallbackOfSeqMod, parameters=source.attrs.itemList})
                    end
                    if source.attrs.mode == "MULTIPLE" then
                        for _, item in ipairs(source.attrs.itemList) do
                            table.insert(pool.sourceList, {type="ITEM_GROUP", callback=HtItem.CallbackOfMultipleMode, parameters=item})
                        end
                    end
                end
            end
        end
        table.insert(ToolkitGUI.CategoryList, pool)
    end
end

function ToolkitGUI.CreateFrame()
    -- UI高度计算
    -- 分类切换按钮高度：ToolkitGUI.UISize.IconSize = 32
    -- 输入框高度：ToolkitGUI.UISize.IconSize = 32
    -- 滚动高度 = ToolkitGUI.UISize.IconNum * ToolkitGUI.UISize.IconSize
    -- 整体高度 = 滚动高度 + （类切换按钮高度 + 标题/padding这些高度）
    local windowHeight = ToolkitGUI.UISize.IconNum * ToolkitGUI.UISize.IconSize + ToolkitGUI.UISize.IconSize + 64
    local windowWidth = ToolkitGUI.UISize.Num * (ToolkitGUI.UISize.Width + ToolkitGUI.UISize.IconSize)
    local window = AceGUI:Create("SimpleGroup")
    window:SetLayout("List")
    window.frame:Hide()
    window:SetHeight(windowHeight)
    window:SetWidth(windowWidth + 20)

    -- 将窗口定位到初始位置
    window.frame:ClearAllPoints()
    local x = HT.AceAddon.db.profile.windowPositionX or 0
    local y = - (HT.AceAddon.db.profile.windowPositionY or 0)
    window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)
   
    -- 确保窗口可以拖动
    window.frame:SetMovable(true)
    window.frame:EnableMouse(true)
    window.frame:RegisterForDrag("LeftButton")

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

    -- 创建TabGroup
    local tabGroup = AceGUI:Create("SimpleGroup")
    tabGroup:SetWidth(windowWidth)
    tabGroup:SetHeight(ToolkitGUI.UISize.IconSize)
    tabGroup:SetLayout("Flow")
    local buttonCount = 0 -- 计算图标总数量，用来计算滚动距离
    for _, category in ipairs(ToolkitGUI.CategoryList) do
        buttonCount = buttonCount + #category.sourceList + 1  -- 分类图标个数 + 分类标题
    end
    local scrollRatio  -- 滚动系数
    if buttonCount <= ToolkitGUI.UISize.IconNum then
        scrollRatio = 1
    else
        scrollRatio = 1000 / (buttonCount - ToolkitGUI.UISize.IconNum)
    end
    local topCount = 0
    for _, category in ipairs(ToolkitGUI.CategoryList) do
        table.insert(ToolkitGUI.tabs, {title=category.title, icon=category.icon, button=nil, scrollHeight=topCount * scrollRatio})
        topCount =  topCount + #category.sourceList + 1
    end
    for index, tab in ipairs(ToolkitGUI.tabs) do
        local tabIcon = AceGUI:Create("Icon")
        tabIcon:SetWidth(ToolkitGUI.UISize.IconSize)
        tabIcon:SetHeight(ToolkitGUI.UISize.IconSize)
        tabIcon:SetImage(tab.icon)
        tabIcon:SetImageSize(ToolkitGUI.UISize.IconSize, ToolkitGUI.UISize.IconSize)
        tabIcon:SetCallback("OnClick", function()
            ToolkitGUI.selectTab(index)
        end)
        tabIcon:SetCallback("OnEnter", function(self)
            GameTooltip:SetOwner(self.frame, "ANCHOR_RIGHT")
            GameTooltip:SetText(tab.title, 1, 1, 1)
            GameTooltip:Show()
        end)
        tabIcon:SetCallback("OnLeave", function()
            GameTooltip:Hide()
        end)
        tabGroup:AddChild(tabIcon)
        tab.button = tabIcon
    end
    window:AddChild(tabGroup)

    -- 创建内容容器，用于包裹scrollFrame容器
    local container = AceGUI:Create("SimpleGroup")
    container = AceGUI:Create("SimpleGroup")
    container:SetWidth(windowWidth)
    container:SetHeight(ToolkitGUI.UISize.IconSize * ToolkitGUI.UISize.IconNum)
    container:SetLayout("Fill")
    -- 创建内容容器滚动区域
    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("List")

    for cateIndex, category in ipairs(ToolkitGUI.CategoryList) do
        -- 创建包裹元素
        local labelContainer = AceGUI:Create("SimpleGroup")
        labelContainer:SetFullWidth(true)
        labelContainer:SetHeight(ToolkitGUI.UISize.IconSize)
        labelContainer:SetLayout("Fill")
        local cateTitleLabel = AceGUI:Create("Heading")
        cateTitleLabel:SetText(category.title)
        labelContainer:AddChild(cateTitleLabel)
        scrollFrame:AddChild(labelContainer)
        for poolIndex, pool in ipairs(category.sourceList) do
            local callbackResult = pool.callback(pool.parameters)
            pool._cateIndex = cateIndex
            pool._poolIndex = poolIndex
            pool._callbackResult = callbackResult
            local buttonContainer = AceGUI:Create("SimpleGroup")
            buttonContainer:SetWidth(ToolkitGUI.UISize.IconSize)
            buttonContainer:SetHeight(ToolkitGUI.UISize.IconSize)
            buttonContainer:SetLayout("Fill")
            pool.button = CreateFrame("Button", ("%s-%s"):format(cateIndex, poolIndex), buttonContainer.frame, "SecureActionButtonTemplate, UIPanelButtonTemplate")
            pool._button_container = buttonContainer
            pool.button:SetNormalTexture(134400)
            pool.button:SetSize(ToolkitGUI.UISize.IconSize, ToolkitGUI.UISize.IconSize)
            pool.button:SetPoint("CENTER", buttonContainer.frame, "CENTER")
            pool.button:RegisterForClicks("AnyDown", "AnyUp")
            pool.button:SetAttribute("macrotext", "")
            pool.text = buttonContainer.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            pool.text:SetWidth(ToolkitGUI.UISize.Width - ToolkitGUI.UISize.IconSize - 5)  -- 5是距离图标的边距
            pool.text:SetPoint("LEFT", buttonContainer.frame, "LEFT", 5 + ToolkitGUI.UISize.IconSize, 0)  -- 将文本靠左对齐，并设置一些间距
            pool.text:SetJustifyH("LEFT")  -- 确保文本左对齐
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
                    pool.text:SetText(callbackResult.text)
                end
            end
            scrollFrame:AddChild(buttonContainer)
        end
    end
    container:AddChild(scrollFrame)
    window:AddChild(container)
    ToolkitGUI.Window = window
    ToolkitGUI.ScrollFrame = scrollFrame
    -- ToolkitGUI.Window.closebutton:SetScript("OnClick", function()
    --     ToolkitGUI.Window:Hide()
    --     ToolkitGUI.IsOpen = false
    -- end)
end

function ToolkitGUI.selectTab(index)
    ToolkitGUI.currentTabIndex = index
    for tabIndex, tab in ipairs(ToolkitGUI.tabs) do
        if tabIndex == index then
            if not (tab.button == nil) then
                ToolkitGUI.ScrollFrame:SetScroll(tab.scrollHeight)
            end
        end
    end
end


function ToolkitGUI.Update()
    for _, category in ipairs(ToolkitGUI.CategoryList) do
        for _, pool in ipairs(category.sourceList) do
            local callbackResult = pool.callback(pool.parameters)
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
    end
end

-- 显示窗口
function ToolkitGUI.ShowWindow()
     -- 将窗口定位到初始位置
     ToolkitGUI.Window.frame:ClearAllPoints()
     local x = HT.AceAddon.db.profile.windowPositionX or 0
     local y = - (HT.AceAddon.db.profile.windowPositionY or 0)
     ToolkitGUI.Window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)
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
        pool.text:SetText(callbackResult.text)
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

return ToolkitGUI
