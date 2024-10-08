local _, HT = ...

local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("HappyToolkit", false)
local ToolkitPool = HT.ToolkitPool


local ToolkitGUI = {
    Window = nil,
    ScrollFrame = nil,
    IsOpen = false,
    UISize = {
        IconSize = 32,
        HeadingHeight = 32, -- 每个分类标题高度
        ScrollHeight = 480,  -- 刚好是图标大小（32+8） * 12 = 504，默认显示11个图标+HeadingHeight
        Width = 204, -- 每个图标32，一共7个。32*7=224。减去20的边框。224-20=204
        Num = 1
    },
    tabs = {}, -- 分类切换按钮
    currentTabIndex = 1,
}

-- 收集注册的回调函数，执行回调函数，返回nil或者具体的函数，
-- 如果是nil则不注册到列表中
-- 如果不是nil，则注册到列表
function ToolkitGUI.CollectCallbackList()
    for _, catePool in ipairs(ToolkitPool) do
        catePool.pool = {}  -- 清空原来的pool
        for _, cb in ipairs(catePool.cbPool) do
            local cbResult = cb()
            if not (cbResult == nil ) and type(cbResult) == "function" then
                table.insert(catePool.pool, {callback=cbResult, execButton=nil, showButton=nil, text=nil})
            end
        end
    end
end

function ToolkitGUI.CreateFrame()
    local window = AceGUI:Create("Window")
    local windowWidth = ToolkitGUI.UISize.Num * (ToolkitGUI.UISize.Width + ToolkitGUI.UISize.IconSize)
    window:SetWidth(windowWidth + 20)
    -- UI高度计算
    -- 分类切换按钮高度：ToolkitGUI.UISize.IconSize = 32
    -- 输入框高度：ToolkitGUI.UISize.IconSize = 32
    -- 滚动高度 = ToolkitGUI.UISize.ScrollHeight = 500
    -- 整体高度 = 滚动高度 + （类切换按钮高度 + 标题/padding这些高度）
    local windowHeight = ToolkitGUI.UISize.ScrollHeight + ToolkitGUI.UISize.IconSize + 64
    window:SetHeight(windowHeight)
    window:SetPoint("TOPLEFT")
    window:SetLayout("List")
    window:EnableResize(false)
    window:SetTitle("HappyToolkit")
    window.frame:Hide()

    -- 创建TabGroup
    local tabGroup = AceGUI:Create("SimpleGroup")
    tabGroup:SetWidth(windowWidth)
    tabGroup:SetHeight(ToolkitGUI.UISize.IconSize)
    tabGroup:SetLayout("Flow")
    local tabScrollIconNum = 0 -- 计算每个tab点击时候滚动图标的个数
    for _, catePool in ipairs(ToolkitPool) do
        table.insert(ToolkitGUI.tabs, {title=catePool.title, icon=catePool.icon, button=nil, scrollIconNum=tabScrollIconNum})
        -- 每个分类图标的个数为：标签+图标个数
        local currentIconNum = 1 + #catePool.pool
        tabScrollIconNum =  tabScrollIconNum + currentIconNum
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

    -- 创建内容容器，用于显示每个标签页对应的内容
    local container = AceGUI:Create("SimpleGroup")
    container = AceGUI:Create("SimpleGroup")
    container:SetWidth(windowWidth)
    container:SetHeight(ToolkitGUI.UISize.ScrollHeight)
    container:SetLayout("Fill")

    -- 创建内容容器滚动区域
    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("List")
    for cateIndex, catePool in ipairs(ToolkitPool) do
        -- 创建包裹元素
        local cateGroup = AceGUI:Create("SimpleGroup")
        cateGroup:SetFullWidth(true)
        cateGroup:SetLayout("List")
        cateGroup:SetPoint("CENTER")
        local labelContainer = AceGUI:Create("SimpleGroup")
        labelContainer:SetFullWidth(true)
        labelContainer:SetHeight(ToolkitGUI.UISize.HeadingHeight)
        labelContainer:SetLayout("Fill")
        local cateTitleLabel = AceGUI:Create("Heading")
        cateTitleLabel:SetText(catePool.title)
        labelContainer:AddChild(cateTitleLabel)
        cateGroup:AddChild(labelContainer)
        -- 创建包裹button的元素
        local toolkitGroup = AceGUI:Create("SimpleGroup")
        toolkitGroup:SetFullWidth(true)
        toolkitGroup:SetHeight(ToolkitGUI.UISize.IconSize)
        toolkitGroup:SetLayout("Flow")
        for poolIndex, pool in ipairs(catePool.pool) do
            local callbackResult = pool.callback()
            pool._cateIndex = cateIndex
            pool._poolIndex = poolIndex
            pool._callbackResult = callbackResult
            -- 创建包裹button的元素
            local toolkitContainer = AceGUI:Create("SimpleGroup")
            toolkitContainer:SetRelativeWidth(1 / ToolkitGUI.UISize.Num)
            toolkitContainer:SetHeight(ToolkitGUI.UISize.IconSize)
            toolkitContainer:SetLayout("Flow")
            local buttonContainer = AceGUI:Create("SimpleGroup")
            buttonContainer:SetWidth(ToolkitGUI.UISize.IconSize)
            buttonContainer:SetHeight(ToolkitGUI.UISize.IconSize)
            buttonContainer:SetLayout("Fill")
            pool.showButton = CreateFrame("Button", ("%s-%s"):format(cateIndex, poolIndex), buttonContainer.frame)
            pool._button_container = buttonContainer
            pool.showButton:SetNormalTexture(134400)
            pool.showButton:SetSize(ToolkitGUI.UISize.IconSize, ToolkitGUI.UISize.IconSize)
            pool.showButton:SetPoint("CENTER", buttonContainer.frame, "CENTER")
            local label1Container = AceGUI:Create("SimpleGroup")
            label1Container:SetFullWidth(true)
            pool.text = label1Container.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            pool.text:SetWidth(ToolkitGUI.UISize.Width - ToolkitGUI.UISize.IconSize - 5)  -- 5是距离图标的边距
            pool.text:SetText("")
            pool.text:SetPoint("LEFT", label1Container.frame, "LEFT", 5 + ToolkitGUI.UISize.IconSize, 0)  -- 将文本靠左对齐，并设置一些间距
            pool.text:SetJustifyH("LEFT")  -- 确保文本左对齐
            if not (callbackResult == nil) then
                -- 如果回调函数返回的是宏命名模式
                if not (callbackResult.macro == nil) then
                    -- 更新图标宏
                    ToolkitGUI.SetPoolMacro(pool)
                    -- 更新冷却计时
                    ToolkitGUI.SetPoolCooldown(pool)
                    -- 更新鼠标移入移出事件
                    ToolkitGUI.SetShowButtonMouseEvent(pool)
                    ToolkitGUI.SetPoolLearnable(pool)
                elseif not (callbackResult.leftClickCallback == nil) then
                    callbackResult.leftClickCallback()
                end
                if callbackResult.text then
                    pool.text:SetText(callbackResult.text)
                end
            end
            toolkitContainer:AddChild(buttonContainer)
            toolkitContainer:AddChild(label1Container)
            toolkitGroup:AddChild(toolkitContainer)
        end
        cateGroup:AddChild(toolkitGroup)
        scrollFrame:AddChild(cateGroup)
    end
    container:AddChild(scrollFrame)
    window:AddChild(container)
    ToolkitGUI.Window = window
    ToolkitGUI.ScrollFrame = scrollFrame
    ToolkitGUI.Window.closebutton:SetScript("OnClick", function()
        ToolkitGUI.Window:Hide()
        ToolkitGUI.IsOpen = false
    end)
end

function ToolkitGUI.selectTab(index)
    ToolkitGUI.currentTabIndex = index
    -- 将当前tab设置为不可点击，其他tab可以点击
    for tabIndex, tab in ipairs(ToolkitGUI.tabs) do
        if tabIndex == index then
            if not (tab.button == nil) then
                tab.button:SetDisabled(true)
                if index == 1 then
                    ToolkitGUI.ScrollFrame:SetScroll(0)
                else
                    ToolkitGUI.ScrollFrame:SetScroll((tab.scrollIconNum + 1) * 20)
                end
            end
        else
            if not (tab.button == nil) then
                tab.button:SetDisabled(false)
            end
        end
    end
end


function ToolkitGUI.Update()
    for _, catePool in ipairs(ToolkitPool) do
        for _, pool in ipairs(catePool.pool) do
            local callbackResult = pool.callback()
            if not (callbackResult == nil) then
                pool._callbackResult = callbackResult
                ToolkitGUI.SetPoolCooldown(pool)
                ToolkitGUI.SetPoolMacro(pool)
                ToolkitGUI.SetPoolLearnable(pool)
                if callbackResult.text then
                    pool.text:SetText(callbackResult.text)
                end
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
    if ToolkitGUI.IsOpen == false then
        ToolkitGUI.Window.frame:Show()
        ToolkitGUI.Update()
        ToolkitGUI.IsOpen = true
    end
end

-- 更新宏文案
function ToolkitGUI.SetButtonMacro(pool, targetButton)
    local callbackResult = pool._callbackResult
    if callbackResult == nil or callbackResult.macro == nil then
        return
    end
    if targetButton == nil then
        return
    end
    -- 设置宏命令
    targetButton:SetAttribute("type", "macro") -- 设置按钮为宏类型
    if callbackResult.icon then
        targetButton:SetNormalTexture(callbackResult.icon)
    end
    local macroText = ""
    if callbackResult.macro.itemID then
        macroText = "/use item:" .. callbackResult.macro.itemID
    elseif callbackResult.macro.toyID then
        macroText = "/use item:" .. callbackResult.macro.toyID
    elseif callbackResult.macro.spellID then
        local spellInfo = C_Spell.GetSpellInfo(callbackResult.macro.spellID)
        if spellInfo then
            macroText = "/cast " .. spellInfo.name
        end
    elseif callbackResult.macro.mountID then
        local name, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID = C_MountJournal.GetMountInfoByID(callbackResult.macro.mountID)
        if name then
            macroText = "/cast " .. name
        end
    elseif callbackResult.macro.petID then
        local speciesName, speciesIcon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable, creatureDisplayID = C_PetJournal.GetPetInfoBySpeciesID(callbackResult.macro.petID)
        if speciesName then
            macroText = "/SummonPet " .. speciesName
        end
    end
    -- 宏命令附加更新冷却计时
    macroText = macroText .. "\r" .. ("/sethappytoolkitguicooldown %s %s"):format(pool._cateIndex, pool._poolIndex)
    -- 宏命令附加关闭窗口
    if callbackResult.closeGUIAfterClick == nil or callbackResult.closeGUIAfterClick == true then
        macroText = macroText .. "\r" .. "/closehappytoolkitgui"
    end
    targetButton:SetAttribute("macrotext", macroText)
end

-- 更新pool的宏文案
function ToolkitGUI.SetPoolMacro(pool)
    if pool == nil then
        return
    end
    if pool.showButton then
        ToolkitGUI.SetButtonMacro(pool, pool.showButton)
    end
    if pool.execButton then
        ToolkitGUI.SetButtonMacro(pool, pool.execButton)
    end
end


-- 更新图标创建冷却计时
function ToolkitGUI.SetButtonCooldown(pool, targetButton)
    if targetButton == nil then
        return
    end
    local callbackResult = pool._callbackResult
    if callbackResult == nil or callbackResult.macro == nil then
        return
    end
    if targetButton.cooldown == nil then
        -- 创建冷却效果
        targetButton.cooldown = CreateFrame("Cooldown", nil, targetButton, "CooldownFrameTemplate")
        targetButton.cooldown:SetAllPoints(targetButton)  -- 设置冷却效果覆盖整个按钮
        targetButton.cooldown:SetDrawEdge(true)  -- 显示边缘
        targetButton.cooldown:SetHideCountdownNumbers(true)  -- 隐藏倒计时数字
    end
    local macro = callbackResult.macro
    local itemID, spellID, toyID, petID = macro.itemID, macro.spellID, macro.toyID, macro.petID
    -- 更新冷却倒计时
    if itemID then
        local startTimeSeconds, durationSeconds, enableCooldownTimer = C_Item.GetItemCooldown(itemID)
        if enableCooldownTimer and durationSeconds > 0 then
            targetButton.cooldown:SetCooldown(startTimeSeconds, durationSeconds)
        else
            targetButton.cooldown:Clear()
        end
    elseif toyID then
        local startTimeSeconds, durationSeconds, enableCooldownTimer = C_Item.GetItemCooldown(toyID)
        if enableCooldownTimer and durationSeconds > 0 then
            targetButton.cooldown:SetCooldown(startTimeSeconds, durationSeconds)
        else
            targetButton.cooldown:Clear()
        end
    elseif spellID then
        local spellCooldownInfo = C_Spell.GetSpellCooldown(spellID)
        if spellCooldownInfo and spellCooldownInfo.isEnabled == true and spellCooldownInfo.duration > 0 then
            targetButton.cooldown:SetCooldown(spellCooldownInfo.startTime, spellCooldownInfo.duration)
        else
            targetButton.cooldown:Clear()
        end
    elseif petID then
        local speciesName, speciesIcon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable, creatureDisplayID = C_PetJournal.GetPetInfoBySpeciesID(petID)
        if speciesName then
            local speciesId, petGUID = C_PetJournal.FindPetIDByName(speciesName)
            if petGUID then
                local start, duration, isEnabled = C_PetJournal.GetPetCooldownByGUID(petGUID)
                if isEnabled and duration > 0 then
                    targetButton.cooldown:SetCooldown(start, duration)
                else
                    targetButton.cooldown:Clear()
                end
            end
        end
    end
end

-- 设置pool的冷却
function ToolkitGUI.SetPoolCooldown(pool)
    if pool == nil then
        return
    end
    if pool.showButton then
        ToolkitGUI.SetButtonCooldown(pool, pool.showButton)
    end
    if pool.execButton then
        ToolkitGUI.SetButtonCooldown(pool, pool.execButton)
    end
end

-- 当pool上的技能没有学习的时候，置为灰色
function ToolkitGUI.SetPoolLearnable(pool)
    if pool == nil then
        return
    end
    local callbackResult = pool._callbackResult
    if callbackResult == nil or callbackResult.macro == nil then
        return
    end
    local macro = callbackResult.macro
    local itemID, toyID, spellID, mountID, petID = macro.itemID, macro.toyID, macro.spellID, macro.mountID, macro.petID
    local hasThisThing = false
    if itemID then
        local count = C_Item.GetItemCount(itemID, false)
        if not (count == 0) then
            hasThisThing = true
        end
    elseif toyID then
        if PlayerHasToy(toyID) then
            hasThisThing = true
        end
    elseif spellID then
        if IsSpellKnown(spellID) then
            hasThisThing = true
        end
    elseif mountID then
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(mountID)
        if isCollected then
            hasThisThing = true
        end
    elseif petID then
        for petIndex = 1, C_PetJournal.GetNumPets() do
            local _, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByIndex(petIndex)
            if speciesID == petID then
                hasThisThing = true
                break
            end
        end
    end
    -- 如果没有学习这个技能，则将图标和文字改成灰色半透明
    if hasThisThing == false then
        if pool.showButton then
            pool.showButton:SetEnabled(false)
            pool.showButton:SetAlpha(0.5)
        end
        if pool.execButton then
            pool.execButton:SetEnabled(false)
            pool.execButton:SetAlpha(0.5)
        end
        if pool.text then
            pool.text:SetTextColor(0.5, 0.5, 0.5)
        end
    else
        if pool.showButton then
            pool.showButton:SetEnabled(true)
            pool.showButton:SetAlpha(1)
        end
        if pool.execButton then
            pool.execButton:SetEnabled(true)
            pool.execButton:SetAlpha(1)
        end
        if pool.text then
            pool.text:SetTextColor(1, 1, 1)
        end
    end
end

-- 设置execButton的鼠标移入移出事件
function ToolkitGUI.SetExecButtonMouseEvent(pool)
    if pool == nil or pool.execButton == nil then
        return
    end
    pool.execButton:SetScript("OnEnter", function (_)
        ToolkitGUI.SetShowGameTooltip(pool, pool.execButton)
    end)
    pool.execButton:SetScript("OnLeave", function(_)
        GameTooltip:Hide() -- 隐藏提示
    end)
end


-- 设置button鼠标移入事件
function ToolkitGUI.SetShowGameTooltip(pool, targetButton)
    local callbackResult = pool._callbackResult
        if callbackResult == nil or callbackResult.macro == nil then
            return
        end
        local macro = callbackResult.macro
        local itemID, toyID, spellID, mountID, petID = macro.itemID, macro.toyID, macro.spellID, macro.mountID, macro.petID
        GameTooltip:SetOwner(targetButton, "ANCHOR_RIGHT") -- 设置提示显示的位置
        if itemID then
            GameTooltip:SetItemByID(itemID)
        elseif toyID then
            GameTooltip:SetToyByItemID(toyID)
        elseif spellID then
            GameTooltip:SetSpellByID(spellID)
        elseif mountID then
            local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(mountID)
            GameTooltip:SetMountBySpellID(spellID)
        elseif petID then
            local speciesName, speciesIcon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable, creatureDisplayID = C_PetJournal.GetPetInfoBySpeciesID(petID)
            local speciesId, petGUID = C_PetJournal.FindPetIDByName(speciesName)
            GameTooltip:SetCompanionPet(petGUID)
        end
end

-- 设置ShowButton的鼠标移入移出事件
function ToolkitGUI.SetShowButtonMouseEvent(pool)
    if pool == nil or pool.showButton == nil then
        return
    end
    pool.showButton:SetScript("OnLeave", function(_)
        GameTooltip:Hide() -- 隐藏提示
    end)
    pool.showButton:SetScript("OnEnter", function (self)
        ToolkitGUI.SetShowGameTooltip(pool, self)
        if pool.execButton then
            return
        end
        -- 创建可以点击的按钮button来替换仅仅可以显示的showButton
        -- 创建可以点击的button
        pool.execButton = CreateFrame("Button", ("%s-%s"):format(pool._cateIndex, pool._poolIndex), pool._button_container.frame, "SecureActionButtonTemplate, UIPanelButtonTemplate")
        pool.execButton:SetNormalTexture(134400)
        pool.execButton:SetSize(ToolkitGUI.UISize.IconSize, ToolkitGUI.UISize.IconSize)
        pool.execButton:SetPoint("CENTER", pool._button_container.frame, "CENTER")
        pool.execButton:RegisterForClicks("AnyDown", "AnyUp")
        -- 设置鼠标移入时候的高亮效果为白色半透明效果
        local highlightTexture = pool.execButton:CreateTexture()
        highlightTexture:SetColorTexture(255, 255, 255, 0.2)
        pool.execButton:SetHighlightTexture(highlightTexture)
        -- 移除初次展示的showButton
        pool.showButton:Hide()
        pool.showButton:SetParent(nil)
        pool.showButton:ClearAllPoints()
        pool.showButton = nil

        -- 更新execButton的宏和冷却
        ToolkitGUI.SetExecButtonMouseEvent(pool)
        ToolkitGUI.SetPoolMacro(pool)
        ToolkitGUI.SetPoolCooldown(pool)
    end)
end

-- 根据索引获取pool
function ToolkitGUI.GetPoolByIndex(cate, poolIndex)
    local catePool = ToolkitPool[cate]
    if catePool == nil then
        return nil
    end
    local pool = catePool.pool[poolIndex]
    return pool
end

-- 初始化UI模块
function ToolkitGUI.Initial()
    ToolkitGUI.CollectCallbackList()
    ToolkitGUI.CreateFrame()
    ToolkitGUI.Update()
end

HT.ToolkitGUI = ToolkitGUI

return ToolkitGUI
