local addonName, _ = ... ---@type string, table
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, false)

---@class GUI: AceModule
local GUI = addon:GetModule("GUI")
---@class CONST: AceModule
local const = addon:GetModule("CONST")
---@class HbFrame: AceModule
local HbFrame = addon:GetModule("HbFrame")

---@class ConfigFrame: AceModule
local CF = addon:NewModule("ConfigFrame")

-- Lazy-loaded modules (avoid circular dependency on init)
local E, U, Config, Client, Macro
local function EnsureModules()
    if not E then E = addon:GetModule("Element") end
    if not U then U = addon:GetModule("Utils") end
    if not Config then Config = addon.G.Config end
    if not Client then Client = addon:GetModule("Client") end
    if not Macro then Macro = addon:GetModule("Macro") end
end

local tinsert, wipe, ipairs, pairs, type, tostring, tonumber = table.insert, wipe, ipairs, pairs, type, tostring, tonumber
local math_max, math_min, math_abs, math_floor = math.max, math.min, math.abs, math.floor
local CreateFrame, UIParent, InCombatLockdown = CreateFrame, UIParent, InCombatLockdown
local GetScreenWidth, GetScreenHeight = GetScreenWidth, GetScreenHeight
local StaticPopup_Show = StaticPopup_Show
local C_Timer = C_Timer

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------
local FRAME_WIDTH  = 930
local FRAME_HEIGHT = 600
local LEFT_WIDTH   = 220
local TREE_NODE_H  = 26
local TAB_HEIGHT   = 30
local PADDING      = 10
local INDENT       = 20

local DEFAULT_ICON = 134400 -- Interface\Icons\INV_Misc_QuestionMark

-------------------------------------------------------------------------------
-- Item display helpers (mirrors Config.lua logic)
-------------------------------------------------------------------------------

local function GetCraftingQualityMarkup(itemID)
    EnsureModules()
    if not Client:IsRetail() or not itemID or not C_TradeSkillUI or not C_TradeSkillUI.GetItemReagentQualityInfo then
        return ""
    end
    local qualityInfo = C_TradeSkillUI.GetItemReagentQualityInfo(itemID)
    if qualityInfo == nil or qualityInfo.iconChat == nil then
        return ""
    end
    return " " .. CreateAtlasMarkup(qualityInfo.iconChat, 16, 16)
end

---@param item table|nil  extraAttr table
---@return { icon:string, name:string, qualityMarkup:string, text:string }
local function BuildItemDisplayView(item)
    local icon = ""
    local name = ""
    local qualityMarkup = ""
    if item then
        icon = item.icon and ("|T" .. tostring(item.icon) .. ":16|t") or ""
        name = item.name or (item.id and tostring(item.id)) or ""
        qualityMarkup = GetCraftingQualityMarkup(item.id)
    end
    return {
        icon = icon,
        name = name,
        qualityMarkup = qualityMarkup,
        text = icon .. name .. qualityMarkup,
    }
end

-- Tab definitions per element type
local TAB_DEFS = {
    [const.ELEMENT_TYPE.BAR] = {
        { key = "settings", label = L["Settings"] },
        { key = "display",  label = L["Display"] },
        { key = "text",     label = L["Text"] },
        { key = "create",   label = L["Create"] },
    },
    [const.ELEMENT_TYPE.ITEM] = {
        { key = "settings", label = L["Settings"] },
        { key = "bindkey",  label = L["Bindkey Settings"] },
        { key = "display",  label = L["Display"] },
        { key = "text",     label = L["Text"] },
    },
    [const.ELEMENT_TYPE.ITEM_GROUP] = {
        { key = "settings", label = L["Settings"] },
        { key = "bindkey",  label = L["Bindkey Settings"] },
        { key = "display",  label = L["Display"] },
        { key = "text",     label = L["Text"] },
    },
    [const.ELEMENT_TYPE.SCRIPT] = {
        { key = "settings", label = L["Settings"] },
        { key = "display",  label = L["Display"] },
        { key = "text",     label = L["Text"] },
        { key = "event",    label = L["Event Settings"] },
    },
    [const.ELEMENT_TYPE.MACRO] = {
        { key = "settings", label = L["Settings"] },
        { key = "bindkey",  label = L["Bindkey Settings"] },
        { key = "display",  label = L["Display"] },
        { key = "text",     label = L["Text"] },
    },
}

local function GetTabsForElement(eleConfig)
    if not eleConfig then return nil end
    local baseTabs = TAB_DEFS[eleConfig.type]
    if not baseTabs then return nil end

    -- BAR 默认无绑定页，只有开启 flyout 时才开放绑定页。
    if eleConfig.type ~= const.ELEMENT_TYPE.BAR then
        return baseTabs
    end

    local tabs = {
        { key = "settings", label = L["Settings"] },
        { key = "display",  label = L["Display"] },
        { key = "text",     label = L["Text"] },
        { key = "create",   label = L["Create"] },
    }
    if eleConfig.flyout == true then
        table.insert(tabs, 2, { key = "bindkey", label = L["Bindkey Settings"] })
    end
    return tabs
end

local function HasTab(tabs, key)
    if not tabs then return false end
    for _, tab in ipairs(tabs) do
        if tab.key == key then
            return true
        end
    end
    return false
end

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------
CF.frame = nil
CF.treeButtons = {}
CF.treeButtonPool = {}
CF.tabButtons = {}
CF.expandedBars = {} -- [barIndex] = true/false
CF.selectedNode = nil -- { eleConfig, topEleConfig, barIndex, childIndex }
CF.selectedTabKey = nil
CF.contentChild = nil

-------------------------------------------------------------------------------
-- Static Popups
-------------------------------------------------------------------------------

StaticPopupDialogs["HAPPYBUTTON_CONFIRM_DELETE_BAR"] = {
    text = L["Delete"] .. "?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, data)
        if data and data.onAccept then data.onAccept() end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["HAPPYBUTTON_CONFIRM_DELETE_ELEMENT"] = {
    text = L["Delete"] .. "?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, data)
        if data and data.onAccept then data.onAccept() end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["HAPPYBUTTON_CONFIRM_IMPORT_OVERWRITE"] = {
    text = L["Detected existing configuration, overwrite it?"],
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, data)
        if data and data.onAccept then data.onAccept() end
    end,
    OnCancel = function(self, data)
        if data and data.onCancel then data.onCancel() end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-------------------------------------------------------------------------------
-- Main Frame Creation
-------------------------------------------------------------------------------

function CF:CreateMainFrame()
    local f = CreateFrame("Frame", "HappyButtonConfigFrame", UIParent, "BackdropTemplate")
    f:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(100)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() f:StartMoving() end)
    f:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
    f:SetResizable(true)
    if f.SetResizeBounds then
        f:SetResizeBounds(700, 450, 1400, 900)
    end
    f:Hide()
    tinsert(UISpecialFrames, "HappyButtonConfigFrame")

    -- Backdrop
    GUI:StyleFrame(f, true)

    -- Frame title
    if not GUI.isSkinEnabled and f.nativeBg then
        -- Native: title in NineSlice header
        local titleText = f.nativeBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleText:SetPoint("TOP", f.nativeBg, "TOP", 0, -5)
        titleText:SetText("HappyButton")
        self.titleText = titleText
    end

    -- Tab bar (full width, contains tabs only; native: below NineSlice header)
    local tabBar = CreateFrame("Frame", nil, f)
    tabBar:SetHeight(TAB_HEIGHT)
    if GUI.isSkinEnabled then
        tabBar:SetPoint("TOPLEFT", 0, 0)
        tabBar:SetPoint("TOPRIGHT", 0, 0)
    else
        tabBar:SetPoint("TOPLEFT", 4, -22)
        tabBar:SetPoint("TOPRIGHT", -4, -22)
    end
    tabBar:EnableMouse(true)
    tabBar:RegisterForDrag("LeftButton")
    tabBar:SetScript("OnDragStart", function() f:StartMoving() end)
    tabBar:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

    -- Tab bar bg
    local tabBg = tabBar:CreateTexture(nil, "BACKGROUND")
    tabBg:SetAllPoints()
    if GUI.isSkinEnabled then
        tabBg:SetColorTexture(unpack(GUI.Colors.header))
    else
        tabBg:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock")
        tabBg:SetHorizTile(true)
        tabBg:SetVertTile(true)
        tabBg:SetVertexColor(0.5, 0.5, 0.5, 1)
    end

    -- Tab separator (bottom line)
    local tabSep = tabBar:CreateTexture(nil, "OVERLAY")
    tabSep:SetHeight(GUI.isSkinEnabled and (GUI.mult or 1) or 1)
    tabSep:SetPoint("BOTTOMLEFT", 0, 0)
    tabSep:SetPoint("BOTTOMRIGHT", 0, 0)
    if GUI.isSkinEnabled then
        tabSep:SetColorTexture(0, 0, 0, 1)
    else
        tabSep:SetColorTexture(0.3, 0.3, 0.3, 1)
    end

    -- Close button
    local closeBtn = GUI:CreateCloseButton(f, function() f:Hide() end)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)

    self.tabBar = tabBar

    -- Add Bar button and Import button (left portion of tab bar)
    local halfW = (LEFT_WIDTH - 30) / 2
    local addBtn = GUI:CreateButton(tabBar, "+ " .. L["New Bar"], halfW, 24)
    addBtn:SetPoint("LEFT", tabBar, "LEFT", 10, 0)
    addBtn:SetScript("OnClick", function()
        CF:OnAddBar()
    end)
    self.addBarBtn = addBtn

    local importBtn = GUI:CreateButton(tabBar, L["Import"], halfW, 24)
    importBtn:SetPoint("LEFT", addBtn, "RIGHT", 10, 0)
    importBtn:SetScript("OnClick", function()
        CF:ShowImportView()
    end)
    self.importBtn = importBtn

    -- Resize grip
    local grip = CreateFrame("Button", nil, f)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function()
        f:StopMovingOrSizing()
        CF:OnResize()
    end)

    -- Left panel
    self:CreateLeftPanel(f, tabBar)

    -- Right panel
    self:CreateRightPanel(f, tabBar)

    -- Combat close
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then f:Hide() end
    end)

    -- On resize
    f:SetScript("OnSizeChanged", function() CF:OnResize() end)

    self.frame = f
    return f
end

function CF:OnResize()
    if not self.frame then return end
    -- Refresh scroll containers
    if self.treeScroll and self.treeScroll.Refresh then
        self.treeScroll:Refresh()
    end
    if self.contentScroll and self.contentScroll.Refresh then
        self.contentScroll:Refresh()
    end
    -- Rebuild tabs if visible
    if self.selectedNode then
        self:BuildTabs(self.selectedNode.eleConfig)
    end
end

-------------------------------------------------------------------------------
-- Left Panel (Tree Navigation)
-------------------------------------------------------------------------------

function CF:CreateLeftPanel(parent, titleBar)
    local left = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    left:SetWidth(LEFT_WIDTH)
    left:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", GUI.isSkinEnabled and 0 or 4, GUI.isSkinEnabled and 0 or 4)

    -- Background (skinned mode: own backdrop with nav color; native: inherits main frame's NineSlice bg)
    if GUI.isSkinEnabled then
        if not left.backdrop then
            left.backdrop = CreateFrame("Frame", nil, left, "BackdropTemplate")
            left.backdrop:SetAllPoints()
            left.backdrop:SetFrameLevel(math.max(0, left:GetFrameLevel() - 1))
        end
        left.backdrop:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        -- DEBUG: use bright red to confirm backdrop is visible
        left.backdrop:SetBackdropColor(unpack(GUI.Colors.nav))
    end

    -- Separator line on the right
    local sep = left:CreateTexture(nil, "OVERLAY")
    sep:SetWidth(GUI.isSkinEnabled and (GUI.mult or 1) or 1)
    sep:SetPoint("TOPRIGHT", 0, 0)
    sep:SetPoint("BOTTOMRIGHT", 0, 0)
    if GUI.isSkinEnabled then
        sep:SetColorTexture(0, 0, 0, 1)
    else
        sep:SetColorTexture(0.3, 0.3, 0.3, 1)
    end

    -- Add Bar button is in tab bar, not here

    -- Tree scroll area
    local treeScroll = GUI:CreateScrollFrame(left)
    treeScroll:SetPoint("TOPLEFT", left, "TOPLEFT", -2, -4)
    treeScroll:SetPoint("BOTTOMRIGHT", left, "BOTTOMRIGHT", -2, 8)

    self.leftPanel = left
    self.treeScroll = treeScroll
    self.treeChild = treeScroll.content
end

function CF:GetTreeButton()
    local btn = table.remove(self.treeButtonPool)
    if not btn then
        btn = self:CreateTreeButton()
    end
    tinsert(self.treeButtons, btn)
    btn:Show()
    return btn
end

function CF:ReleaseTreeButtons()
    for _, btn in ipairs(self.treeButtons) do
        btn:Hide()
        btn:ClearAllPoints()
        tinsert(self.treeButtonPool, btn)
    end
    wipe(self.treeButtons)
end

function CF:CreateTreeButton()
    local btn = CreateFrame("Button", nil, self.treeChild)
    btn:SetHeight(TREE_NODE_H)
    btn:EnableMouse(true)
    btn:RegisterForClicks("AnyUp")

    -- Selected bg
    local selBg = btn:CreateTexture(nil, "BACKGROUND", nil, 0)
    selBg:SetAllPoints()
    selBg:SetColorTexture(0, 0.6, 1, 0.25)
    selBg:Hide()
    btn.selBg = selBg

    -- Hover highlight
    local hl = btn:CreateTexture(nil, "BACKGROUND", nil, 1)
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.1)
    hl:Hide()
    btn.hl = hl

    -- Hover scripts
    btn:SetScript("OnEnter", function(self_btn)
        if not self_btn.isSelected then
            self_btn.hl:Show()
        end
    end)
    btn:SetScript("OnLeave", function(self_btn)
        self_btn.hl:Hide()
    end)

    -- Arrow (for expandable nodes)
    local arrow = btn:CreateTexture(nil, "ARTWORK")
    arrow:SetSize(12, 12)
    arrow:SetTexture("Interface\\Buttons\\UI-PlusButton-UP")
    arrow:Hide()
    btn.arrow = arrow

    -- Icon (22x22, texCoord crop like PasteFlow)
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.icon = icon

    -- Title (12pt like PasteFlow)
    local title = GUI:CreateText(btn, "", 12)
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)
    btn.title = title

    -- Type badge (11pt, center justified, fixed width like PasteFlow)
    local tag = GUI:CreateText(btn, "", 11)
    tag:SetPoint("RIGHT", -6, 0)
    tag:SetWidth(70)
    tag:SetJustifyH("RIGHT")
    tag:SetTextColor(unpack(GUI.Colors.disabled))
    btn.tag = tag

    return btn
end

function CF:BuildTree()
    self:ReleaseTreeButtons()
    local elements = addon.db and addon.db.profile and addon.db.profile.elements
    if not elements then return end

    local yOff = 0
    local rowIndex = 0
    for barIdx, barConfig in ipairs(elements) do
        -- Bar node
        local btn = self:GetTreeButton()
        btn:SetPoint("TOPLEFT", self.treeChild, "TOPLEFT", 0, yOff)
        btn:SetPoint("TOPRIGHT", self.treeChild, "TOPRIGHT", 0, yOff)
        rowIndex = rowIndex + 1
        btn.rowIndex = rowIndex

        -- Arrow
        btn.arrow:Show()
        btn.arrow:ClearAllPoints()
        btn.arrow:SetPoint("LEFT", 6, 0)
        local expanded = self.expandedBars[barIdx]
        btn.arrow:SetTexture(expanded and "Interface\\Buttons\\UI-MinusButton-UP" or "Interface\\Buttons\\UI-PlusButton-UP")

        -- Bar nodes don't show icons
        btn.icon:Hide()

        -- Title (anchored to arrow, no icon)
        btn.title:ClearAllPoints()
        btn.title:SetText(barConfig.title or (L["Bar"] .. " " .. barIdx))
        btn.title:SetPoint("LEFT", btn.arrow, "RIGHT", 4, 0)
        btn.title:SetPoint("RIGHT", btn.tag, "LEFT", -4, 0)

        -- Tag
        btn.tag:Show()
        btn.tag:SetText(L["Bar"])
        btn.tag:SetTextColor(1.00, 0.82, 0.00)

        -- Selection state
        local isSelected = self.selectedNode and self.selectedNode.barIndex == barIdx and self.selectedNode.childIndex == nil
        btn.isSelected = isSelected
        if isSelected then btn.selBg:Show() else btn.selBg:Hide() end

        -- Click handlers
        local capturedBarIdx = barIdx
        btn:SetScript("OnClick", function(self_btn, mouseBtn)
            if mouseBtn == "LeftButton" then
                -- Toggle expand
                self.expandedBars[capturedBarIdx] = not self.expandedBars[capturedBarIdx]
                -- Select this bar
                self:SelectNode({
                    eleConfig = barConfig,
                    topEleConfig = barConfig,
                    barIndex = capturedBarIdx,
                    childIndex = nil,
                })
                self:BuildTree()
            elseif mouseBtn == "RightButton" then
                self:ShowContextMenu(self_btn, {
                    eleConfig = barConfig,
                    topEleConfig = barConfig,
                    barIndex = capturedBarIdx,
                    childIndex = nil,
                })
            end
        end)

        yOff = yOff - TREE_NODE_H

        -- Child nodes (if expanded)
        if expanded and barConfig.elements then
            for childIdx, childConfig in ipairs(barConfig.elements) do
                local cBtn = self:GetTreeButton()
                cBtn:SetPoint("TOPLEFT", self.treeChild, "TOPLEFT", 0, yOff)
                cBtn:SetPoint("TOPRIGHT", self.treeChild, "TOPRIGHT", 0, yOff)
                rowIndex = rowIndex + 1
                cBtn.rowIndex = rowIndex

                -- No arrow for children
                cBtn.arrow:Hide()

                -- Icon (clear old anchors from pooled button)
                cBtn.icon:ClearAllPoints()
                cBtn.icon:Show()
                local cIcon = childConfig.icon or DEFAULT_ICON
                local cTitle = childConfig.title or ("Element " .. childIdx)
                -- ITEM type: use actual item icon and title text as name + crafting quality markup
                if childConfig.type == const.ELEMENT_TYPE.ITEM and childConfig.extraAttr then
                    if childConfig.extraAttr.icon then
                        cIcon = childConfig.extraAttr.icon
                    end
                    -- Keep list title consistent with item value input, but do not prepend icon here
                    local itemDisplay = BuildItemDisplayView(childConfig.extraAttr)
                    if itemDisplay.name ~= "" or itemDisplay.qualityMarkup ~= "" then
                        cTitle = itemDisplay.name .. itemDisplay.qualityMarkup
                    elseif childConfig.extraAttr.name then
                        cTitle = childConfig.extraAttr.name
                    end
                end
                if type(cIcon) == "number" then
                    cBtn.icon:SetTexture(cIcon)
                else
                    cBtn.icon:SetTexture(tostring(cIcon))
                end
                cBtn.icon:SetPoint("LEFT", INDENT + 6, 0)

                -- Title
                cBtn.title:ClearAllPoints()
                cBtn.title:SetText(cTitle)
                cBtn.title:SetPoint("LEFT", cBtn.icon, "RIGHT", 4, 0)
                cBtn.title:SetPoint("RIGHT", -8, 0)

                -- Hide type tag on child rows to free horizontal space
                cBtn.tag:Hide()

                -- Type tag
                local typeLabel = ""
                if childConfig.type == const.ELEMENT_TYPE.ITEM then
                    -- Show specific item sub-type (Toy/Spell/Mount/Pet/Equipment/Item)
                    local subType = childConfig.extraAttr and childConfig.extraAttr.type
                    typeLabel = subType and const.ItemTypeOptions[subType] or L["Item"]
                elseif childConfig.type == const.ELEMENT_TYPE.ITEM_GROUP then typeLabel = L["ITEM_GROUP"]
                elseif childConfig.type == const.ELEMENT_TYPE.SCRIPT then typeLabel = L["Script"]
                elseif childConfig.type == const.ELEMENT_TYPE.MACRO then typeLabel = L["Macro"]
                end
                cBtn.tag:SetText(typeLabel)
                -- Type-specific badge color (PasteFlow style)
                if childConfig.type == const.ELEMENT_TYPE.ITEM then
                    cBtn.tag:SetTextColor(0.12, 0.75, 0.12)
                elseif childConfig.type == const.ELEMENT_TYPE.ITEM_GROUP then
                    cBtn.tag:SetTextColor(0.44, 0.84, 1.00)
                elseif childConfig.type == const.ELEMENT_TYPE.SCRIPT then
                    cBtn.tag:SetTextColor(0.64, 0.21, 0.93)
                elseif childConfig.type == const.ELEMENT_TYPE.MACRO then
                    cBtn.tag:SetTextColor(0.90, 0.80, 0.50)
                else
                    cBtn.tag:SetTextColor(0.62, 0.62, 0.62)
                end

                -- Selection state
                local cSelected = self.selectedNode and self.selectedNode.barIndex == barIdx and self.selectedNode.childIndex == childIdx
                cBtn.isSelected = cSelected
                if cSelected then cBtn.selBg:Show() else cBtn.selBg:Hide() end

                -- Click
                local cBarIdx, cChildIdx = barIdx, childIdx
                cBtn:SetScript("OnClick", function(self_btn, mouseBtn)
                    if mouseBtn == "RightButton" then
                        self:ShowContextMenu(self_btn, {
                            eleConfig = childConfig,
                            topEleConfig = barConfig,
                            barIndex = cBarIdx,
                            childIndex = cChildIdx,
                        })
                        return
                    end
                    self:SelectNode({
                        eleConfig = childConfig,
                        topEleConfig = barConfig,
                        barIndex = cBarIdx,
                        childIndex = cChildIdx,
                    })
                    self:BuildTree()
                end)

                yOff = yOff - TREE_NODE_H
            end
        end
    end

    self.treeChild:SetHeight(math_abs(yOff) + 10)
    if self.treeScroll and self.treeScroll.Refresh then
        self.treeScroll:Refresh()
    end
end

function CF:SelectNode(nodeInfo)
    local oldType = self.selectedNode and self.selectedNode.eleConfig.type
    self.selectedNode = nodeInfo

    self:BuildTabs(nodeInfo.eleConfig)

    -- Build tabs if element type changed or first selection
    if not oldType or oldType ~= nodeInfo.eleConfig.type then
        -- Select first tab
        local tabs = GetTabsForElement(nodeInfo.eleConfig)
        if tabs and tabs[1] then
            self:SelectTab(tabs[1].key)
        end
    else
        -- Same type, refresh current tab content
        self:SelectTab(self.selectedTabKey)
    end
end

-------------------------------------------------------------------------------
-- Right Panel (Tabs + Content)
-------------------------------------------------------------------------------

function CF:CreateRightPanel(parent, titleBar)
    local right = CreateFrame("Frame", nil, parent)
    right:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", LEFT_WIDTH, 0)
    right:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", GUI.isSkinEnabled and 0 or -4, GUI.isSkinEnabled and 0 or 4)

    -- Content scroll area (directly below the shared tab bar)
    local contentScroll = GUI:CreateScrollFrame(right)
    contentScroll:SetPoint("TOPLEFT", 0, 0)
    contentScroll:SetPoint("BOTTOMRIGHT", right, "BOTTOMRIGHT", -2, 2)

    local contentChild = contentScroll.content

    -- Placeholder text (shown when nothing is selected)
    local placeholder = GUI:CreateText(right, L["Select an element from the left tree to edit its settings."], GUI.Fonts.size_header)
    placeholder:SetPoint("CENTER", contentScroll, "CENTER", 0, 0)
    placeholder:SetTextColor(unpack(GUI.Colors.disabled))
    placeholder:SetWidth(400)
    placeholder:SetJustifyH("CENTER")
    placeholder:SetWordWrap(true)

    self.rightPanel = right
    self.contentScroll = contentScroll
    self.contentChild = contentChild
    self.placeholder = placeholder
end

function CF:BuildTabs(eleOrType)
    -- Clear old tab buttons
    if self._tabGroup then
        self._tabGroup.frame:Hide()
        self._tabGroup = nil
    end
    for _, btn in ipairs(self.tabButtons) do
        btn:Hide()
    end
    wipe(self.tabButtons)

    local eleConfig = nil
    if type(eleOrType) == "table" then
        eleConfig = eleOrType
    elseif self.selectedNode and self.selectedNode.eleConfig then
        eleConfig = self.selectedNode.eleConfig
    end
    local tabs = GetTabsForElement(eleConfig)
    if not tabs or #tabs == 0 then return end

    if not HasTab(tabs, self.selectedTabKey) then
        self.selectedTabKey = tabs[1].key
    end

    local barW = self.tabBar:GetWidth()
    if barW < 10 then barW = FRAME_WIDTH end
    local rightW = barW - LEFT_WIDTH

    local tg = GUI:CreateTabGroup(self.tabBar, tabs, {
        width = rightW,
        height = TAB_HEIGHT,
        selected = self.selectedTabKey,
        onClick = function(key) CF:SelectTab(key) end,
    })
    tg.frame:SetPoint("LEFT", self.tabBar, "LEFT", LEFT_WIDTH, 0)
    self._tabGroup = tg
    self.tabButtons = tg.buttons
end

function CF:SelectTab(tabKey)
    self.selectedTabKey = tabKey

    -- Update tab button visuals
    if self._tabGroup then
        self._tabGroup.Select(tabKey)
    end

    -- Hide placeholder
    if self.placeholder then self.placeholder:Hide() end

    -- Clear content
    self:ClearContent()

    -- Render content for selected tab
    if self.selectedNode then
        self:RenderTab(tabKey, self.selectedNode.eleConfig, self.selectedNode.topEleConfig)
    end
end

function CF:ClearContent()
    if not self.contentChild then return end
    -- Hide all child frames
    for _, child in ipairs({self.contentChild:GetChildren()}) do
        child:Hide()
    end
    -- Hide all regions (font strings, textures)
    for _, region in ipairs({self.contentChild:GetRegions()}) do
        region:Hide()
    end
    self.contentChild:SetHeight(1)
    if self.contentScroll and self.contentScroll.ScrollToTop then
        self.contentScroll:ScrollToTop()
    end
end

-------------------------------------------------------------------------------
-- Tab Content Rendering
-------------------------------------------------------------------------------

-- Helper: layout widgets vertically, returns next yOffset
local function LayoutWidget(widget, parent, yOff, xOff)
    xOff = xOff or PADDING
    widget:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff, yOff)
    return yOff - widget:GetHeight() - 8
end

-- Helper: layout multiple widgets on the same row, returns next yOffset
local function LayoutRow(widgets, parent, yOff, xOff, gap)
    xOff = xOff or PADDING
    gap = gap or 10
    local maxH = 0
    local curX = xOff
    for _, w in ipairs(widgets) do
        w:SetPoint("TOPLEFT", parent, "TOPLEFT", curX, yOff)
        curX = curX + w:GetWidth() + gap
        local h = w:GetHeight()
        if h > maxH then maxH = h end
    end
    return yOff - maxH - 8
end

-- Helper: create a section divider
local function SectionDivider(parent, label, yOff, width)
    local d = GUI:CreateDivider(parent, width or 500, 20, label, false)
    d:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING, yOff)
    return yOff - 28
end

-- Helper: create a form row with label + widget
local function FormRow(parent, label, widgetFunc, yOff, contentWidth)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(contentWidth or 600, 28)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING, yOff)

    local lbl = GUI:CreateText(row, label, GUI.Fonts.size_normal)
    lbl:SetPoint("LEFT", 0, 0)
    lbl:SetWidth(130)
    lbl:SetJustifyH("RIGHT")
    lbl:SetTextColor(unpack(GUI.Colors.text))

    local widget = widgetFunc(row)
    widget:SetPoint("LEFT", lbl, "RIGHT", 10, 0)

    return row, yOff - 34
end

function CF:RenderTab(tabKey, eleConfig, topEleConfig)
    local parent = self.contentChild
    local contentW = self.contentScroll:GetWidth() - 30
    parent:SetWidth(contentW)

    if tabKey == "settings" then
        if eleConfig.type == const.ELEMENT_TYPE.BAR then
            self:RenderBarSettings(parent, eleConfig, contentW)
        else
            self:RenderElementSettings(parent, eleConfig, topEleConfig, contentW)
        end
    elseif tabKey == "display" then
        self:RenderDisplay(parent, eleConfig, topEleConfig, contentW)
    elseif tabKey == "text" then
        self:RenderText(parent, eleConfig, topEleConfig, contentW)
    elseif tabKey == "create" then
        self:RenderCreate(parent, eleConfig, contentW)
    elseif tabKey == "bindkey" then
        self:RenderBindkey(parent, eleConfig, contentW)
    elseif tabKey == "event" then
        self:RenderEvent(parent, eleConfig, contentW)
    else
        self:RenderPlaceholder(parent, tabKey)
    end

    -- Refresh scroll after content is rendered
    if self.contentScroll and self.contentScroll.Refresh then
        self.contentScroll:Refresh()
    end
end

-------------------------------------------------------------------------------
-- Bar Settings Tab
-------------------------------------------------------------------------------

function CF:RenderBarSettings(parent, eleConfig, contentW)
    local yOff = -PADDING

    -- === Basic Section ===
    yOff = SectionDivider(parent, L["Basic"], yOff, contentW - 20)

    -- Title + Icon (same row)
    local titleInput = GUI:CreateInput(parent, {
        get = function() return eleConfig.title end,
        set = function(v)
            eleConfig.title = v
            self:BuildTree()
        end,
    })
    titleInput = GUI:VGroup(parent, L["Title"], titleInput)

    local iconInput = GUI:CreateIconInput(parent, {
        defaultIcon = DEFAULT_ICON,
        ---@diagnostic disable-next-line: return-type-mismatch
        get = function() return (eleConfig.icon) end,
        set = function(v)
            eleConfig.icon = v
            self:BuildTree()
            HbFrame:ReloadEframeUI(eleConfig)
            self:SelectTab(self.selectedTabKey)
        end,
    })
    iconInput = GUI:VGroup(parent, L["Element Icon ID or Path"], iconInput)
    yOff = LayoutRow({titleInput, iconInput}, parent, yOff, PADDING + 10)

    -- Icon size (same row)
    local iconWSlider = GUI:CreateSlider(parent, {
        label = L["Icon Width"],
        min = 24, max = 128, step = 1,
        get = function() return eleConfig.iconWidth or addon.G.iconWidth or 32 end,
        set = function(v)
            eleConfig.iconWidth = v
            HbFrame:ReloadEframeUI(eleConfig)
        end,
    })

    local iconHSlider = GUI:CreateSlider(parent, {
        label = L["Icon Height"],
        min = 24, max = 128, step = 1,
        get = function() return eleConfig.iconHeight or addon.G.iconHeight or 32 end,
        set = function(v)
            eleConfig.iconHeight = v
            HbFrame:ReloadEframeUI(eleConfig)
        end,
    })
    yOff = LayoutRow({iconWSlider, iconHSlider}, parent, yOff, PADDING + 10)

    -- === Position Section ===
    yOff = SectionDivider(parent, L["Position"], yOff, contentW - 20)

    -- Attach frame (input + preset dropdown on same row)
    local afInput = GUI:CreateInput(parent, {
        get = function() return eleConfig.attachFrame or "UIParent" end,
        set = function(v)
            eleConfig.attachFrame = (v ~= "" and v) or "UIParent"
            HbFrame:ReloadEframeUI(eleConfig)
        end,
    })
    afInput = GUI:VGroup(parent, L["AttachFrame"], afInput)

    local afOpts = {}
    for k, v in pairs(const.AttachFrameOptions) do
        tinsert(afOpts, { value = k, text = v })
    end
    local afDD = GUI:CreateDropdown(parent, {
        options = afOpts,
        get = function() return eleConfig.attachFrame end,
        set = function(v)
            eleConfig.attachFrame = v
            afInput:SetValue(v)
            HbFrame:ReloadEframeUI(eleConfig)
        end,
    })
    afDD = GUI:VGroup(parent, L["Preset"], afDD)
    yOff = LayoutRow({afInput, afDD}, parent, yOff, PADDING + 10)

    -- Anchor pos (same row)
    local apOpts = {}
    for k, v in pairs(const.AnchorPosOptions) do
        tinsert(apOpts, { value = k, text = v })
    end
    local anchorDD = GUI:CreateDropdown(parent, {
        options = apOpts,
        get = function() return eleConfig.anchorPos end,
        set = function(v)
            eleConfig.anchorPos = v
            HbFrame:ReloadEframeUI(eleConfig)
        end,
    })
    anchorDD = GUI:VGroup(parent, L["Element Anchor Position"], anchorDD)

    local afapDD = GUI:CreateDropdown(parent, {
        options = apOpts,
        get = function() return eleConfig.attachFrameAnchorPos end,
        set = function(v)
            eleConfig.attachFrameAnchorPos = v
            HbFrame:ReloadEframeUI(eleConfig)
        end,
    })
    afapDD = GUI:VGroup(parent, L["AttachFrame Anchor Position"], afapDD)
    yOff = LayoutRow({anchorDD, afapDD}, parent, yOff, PADDING + 10)

    -- X / Y offset (same row)
    local screenW = math_floor(GetScreenWidth())
    local screenH = math_floor(GetScreenHeight())
    local posXSlider = GUI:CreateSlider(parent, {
        label = L["Relative X-Offset"],
        min = -screenW, max = screenW, step = 1,
        get = function() return eleConfig.posX or 0 end,
        set = function(v)
            eleConfig.posX = v
            -- 位置拖动时只更新窗口锚点，确保 slider 拖动过程立即可见。
            HbFrame:UpdateEframeWindow(eleConfig)
        end,
    })

    local posYSlider = GUI:CreateSlider(parent, {
        label = L["Relative Y-Offset"],
        min = -screenH, max = screenH, step = 1,
        get = function() return eleConfig.posY or 0 end,
        set = function(v)
            eleConfig.posY = v
            -- 位置拖动时只更新窗口锚点，确保 slider 拖动过程立即可见。
            HbFrame:UpdateEframeWindow(eleConfig)
        end,
    })
    yOff = LayoutRow({posXSlider, posYSlider}, parent, yOff, PADDING + 10)

    parent:SetHeight(math_abs(yOff) + PADDING)
end

-------------------------------------------------------------------------------
-- Element Settings Tab (ITEM / ITEM_GROUP / SCRIPT / MACRO)
-------------------------------------------------------------------------------



function CF:RenderElementSettings(parent, eleConfig, topEleConfig, contentW)
    EnsureModules()
    local yOff = -PADDING
    local nodeInfo = self.selectedNode

    if eleConfig.type == const.ELEMENT_TYPE.ITEM then
        -- ============== ITEM: NO title, NO icon. Only itemType + itemVal =============

        -- Item Type
        local itOpts = {}
        for k, v in pairs(const.ItemTypeOptions) do
            tinsert(itOpts, { value = k, text = v })
        end

        -- Edit state management (mirrors GetEditItemState from Config.lua)
        if not CF._editItemStates then CF._editItemStates = setmetatable({}, { __mode = "k" }) end
        local state = CF._editItemStates[eleConfig]
        if not state then
            local view = BuildItemDisplayView(eleConfig.extraAttr)
            state = {
                itemType = eleConfig.extraAttr and eleConfig.extraAttr.type or const.ITEM_TYPE.ITEM,
                itemVal = view.text,
            }
            CF._editItemStates[eleConfig] = state
        end

        local itemTypeDD = GUI:CreateDropdown(parent, {
            options = itOpts,
            get = function() return state.itemType end,
            set = function(v) state.itemType = v end,
        })
        itemTypeDD = GUI:VGroup(parent, L["Item Type"], itemTypeDD)

        -- Item value (shows icon+name+quality markup as display text, same row as itemType)
        local itemValInput = GUI:CreateInput(parent, {
            get = function() return state.itemVal or "" end,
            set = function(v)
                state.itemVal = v
                -- Async verify item
                local itemType = state.itemType or const.ITEM_TYPE.ITEM
                local r = Config.VerifyItemAttr(itemType, v)
                if r:is_ok() then
                    local newAttr = r:unwrap()
                    eleConfig.extraAttr = U.Table.DeepCopyDict(newAttr)
                    local view = BuildItemDisplayView(eleConfig.extraAttr)
                    state.itemVal = view.text
                    HbFrame:ReloadEframeUI(topEleConfig)
                    self:BuildTree()
                    self:SelectTab(self.selectedTabKey)
                else
                    -- Retry async for ITEM/EQUIPMENT/TOY
                    if itemType == const.ITEM_TYPE.ITEM or itemType == const.ITEM_TYPE.EQUIPMENT or itemType == const.ITEM_TYPE.TOY then
                        local attempts = 0
                        local function retryVerify()
                            attempts = attempts + 1
                            local r2 = Config.VerifyItemAttr(itemType, v)
                            if r2:is_ok() then
                                local newAttr2 = r2:unwrap()
                                eleConfig.extraAttr = U.Table.DeepCopyDict(newAttr2)
                                local view2 = BuildItemDisplayView(eleConfig.extraAttr)
                                state.itemVal = view2.text
                                HbFrame:ReloadEframeUI(topEleConfig)
                                self:BuildTree()
                                self:SelectTab(self.selectedTabKey)
                            elseif attempts < 8 then
                                C_Timer.After(0.2, retryVerify)
                            else
                                Config.ShowErrorDialog(L["Invalid item input, please check and re-enter."])
                            end
                        end
                        C_Timer.After(0.2, retryVerify)
                    else
                        Config.ShowErrorDialog(r:unwrap_err())
                    end
                end
            end,
        })
        itemValInput = GUI:VGroup(parent, L["Item name or item id"], itemValInput)
        yOff = LayoutRow({itemTypeDD, itemValInput}, parent, yOff, PADDING + 10)

    elseif eleConfig.type == const.ELEMENT_TYPE.ITEM_GROUP then
        -- ============== ITEM_GROUP: title, icon, mode, child item management =============
        yOff = SectionDivider(parent, L["Basic"], yOff, contentW - 20)

        -- Title + Icon (same row)
        local titleInput = GUI:CreateInput(parent, {
            get = function() return eleConfig.title end,
            set = function(v) eleConfig.title = v; self:BuildTree() end,
        })
        titleInput = GUI:VGroup(parent, L["Title"], titleInput)

        local iconInput = GUI:CreateIconInput(parent, {
            defaultIcon = DEFAULT_ICON,
            ---@diagnostic disable-next-line: return-type-mismatch
            get = function() return (eleConfig.icon) end,
            set = function(v)
                eleConfig.icon = v
                self:BuildTree()
            end,
        })
        iconInput = GUI:VGroup(parent, L["Element Icon ID or Path"], iconInput)
        yOff = LayoutRow({titleInput, iconInput}, parent, yOff, PADDING + 10)

        -- Mode
        local modeOpts = {}
        for k, v in pairs(const.ItemsGroupModeOptions) do
            tinsert(modeOpts, { value = k, text = v })
        end
        local modeDD = GUI:CreateDropdown(parent, {
            width = 250,
            options = modeOpts,
            get = function() return eleConfig.extraAttr and eleConfig.extraAttr.mode end,
            set = function(v)
                if eleConfig.extraAttr then
                    eleConfig.extraAttr.mode = v
                    HbFrame:ReloadEframeUI(topEleConfig)
                end
            end,
        })
        modeDD = GUI:VGroup(parent, L["Mode"], modeDD)
        yOff = LayoutWidget(modeDD, parent, yOff, PADDING + 10)

        -- Add child item section
        yOff = SectionDivider(parent, L["Item"], yOff, contentW - 20)

        -- Item type for adding
        if not CF._igAddState then CF._igAddState = {} end
        if not CF._igAddState[eleConfig] then CF._igAddState[eleConfig] = { itemType = const.ITEM_TYPE.ITEM } end
        local addState = CF._igAddState[eleConfig]

        local itOpts = {}
        for k, v in pairs(const.ItemTypeOptions) do
            tinsert(itOpts, { value = k, text = v })
        end
        local addTypeDD = GUI:CreateDropdown(parent, {
            options = itOpts,
            get = function() return addState.itemType end,
            set = function(v) addState.itemType = v end,
        })
        addTypeDD = GUI:VGroup(parent, L["Item Type"], addTypeDD)
        yOff = LayoutWidget(addTypeDD, parent, yOff, PADDING + 10)

        -- Item value input (adding child item)
        local addValInput = GUI:CreateInput(parent, {
            get = function() return addState.itemVal or "" end,
            set = function(v)
                addState.itemVal = v
                local itemType = addState.itemType or const.ITEM_TYPE.ITEM
                local r = Config.VerifyItemAttr(itemType, v)
                if r:is_ok() then
                    local newElement = E:New(
                        Config.GetNewElementTitle(L["Item"], eleConfig.elements),
                        const.ELEMENT_TYPE.ITEM)
                    local item = E:ToItem(newElement)
                    item.extraAttr = U.Table.DeepCopyDict(r:unwrap())
                    tinsert(eleConfig.elements, item)
                    HbFrame:ReloadEframeUI(topEleConfig)
                    if eleConfig.extraAttr then
                        eleConfig.extraAttr.configSelectedItemIndex = #eleConfig.elements
                    end
                    addState.itemVal = nil
                    self:SelectTab(self.selectedTabKey)
                else
                    -- Retry async
                    if itemType == const.ITEM_TYPE.ITEM or itemType == const.ITEM_TYPE.EQUIPMENT or itemType == const.ITEM_TYPE.TOY then
                        local attempts = 0
                        local function retryVerify()
                            attempts = attempts + 1
                            local r2 = Config.VerifyItemAttr(itemType, v)
                            if r2:is_ok() then
                                local newElement = E:New(
                                    Config.GetNewElementTitle(L["Item"], eleConfig.elements),
                                    const.ELEMENT_TYPE.ITEM)
                                local item = E:ToItem(newElement)
                                item.extraAttr = U.Table.DeepCopyDict(r2:unwrap())
                                tinsert(eleConfig.elements, item)
                                HbFrame:ReloadEframeUI(topEleConfig)
                                if eleConfig.extraAttr then
                                    eleConfig.extraAttr.configSelectedItemIndex = #eleConfig.elements
                                end
                                addState.itemVal = nil
                                self:SelectTab(self.selectedTabKey)
                            elseif attempts < 8 then
                                C_Timer.After(0.2, retryVerify)
                            else
                                Config.ShowErrorDialog(L["Invalid item input, please check and re-enter."])
                            end
                        end
                        C_Timer.After(0.2, retryVerify)
                    else
                        Config.ShowErrorDialog(r:unwrap_err())
                    end
                end
            end,
        })
        addValInput = GUI:VGroup(parent, L["Item name or item id"], addValInput)
        yOff = LayoutWidget(addValInput, parent, yOff, PADDING + 10)
        if eleConfig.elements and #eleConfig.elements > 0 then
            local childOpts = {}
            for ci, child in ipairs(eleConfig.elements) do
                local childItem = E:ToItem(child)
                local view = BuildItemDisplayView(childItem.extraAttr)
                tinsert(childOpts, { value = ci, text = view.text ~= "" and view.text or (L["Item"] .. " " .. ci) })
            end
            if not eleConfig.extraAttr then eleConfig.extraAttr = {} end
            if not eleConfig.extraAttr.configSelectedItemIndex then
                eleConfig.extraAttr.configSelectedItemIndex = 1
            end

            local selectDD = GUI:CreateDropdown(parent, {
                width = 250,
                options = childOpts,
                get = function() return eleConfig.extraAttr.configSelectedItemIndex end,
                set = function(v) eleConfig.extraAttr.configSelectedItemIndex = v end,
            })
            selectDD = GUI:VGroup(parent, L["Select Item"], selectDD)
            yOff = LayoutWidget(selectDD, parent, yOff, PADDING + 10)

            -- Child item actions (delete, moveUp, moveDown)
            local cBtnW = 90
            local cGap = 8
            local delChildBtn = GUI:CreateButton(parent, L["Delete"], cBtnW, 26)
            delChildBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING + 10, yOff)
            delChildBtn:SetScript("OnClick", function()
                local idx = eleConfig.extraAttr.configSelectedItemIndex
                if idx and eleConfig.elements[idx] then
                    table.remove(eleConfig.elements, idx)
                    if idx > #eleConfig.elements then
                        eleConfig.extraAttr.configSelectedItemIndex = math_max(1, #eleConfig.elements)
                    end
                    HbFrame:ReloadEframeUI(topEleConfig)
                    self:SelectTab(self.selectedTabKey)
                end
            end)

            local childUpBtn = GUI:CreateButton(parent, L["Move Up"], cBtnW, 26)
            childUpBtn:SetPoint("LEFT", delChildBtn, "RIGHT", cGap, 0)
            if eleConfig.extraAttr.configSelectedItemIndex <= 1 then childUpBtn:Disable() end
            childUpBtn:SetScript("OnClick", function()
                local idx = eleConfig.extraAttr.configSelectedItemIndex
                if idx > 1 then
                    eleConfig.elements[idx], eleConfig.elements[idx - 1] = eleConfig.elements[idx - 1], eleConfig.elements[idx]
                    eleConfig.extraAttr.configSelectedItemIndex = idx - 1
                    HbFrame:ReloadEframeUI(topEleConfig)
                    self:SelectTab(self.selectedTabKey)
                end
            end)

            local childDownBtn = GUI:CreateButton(parent, L["Move Down"], cBtnW, 26)
            childDownBtn:SetPoint("LEFT", childUpBtn, "RIGHT", cGap, 0)
            if eleConfig.extraAttr.configSelectedItemIndex >= #eleConfig.elements then childDownBtn:Disable() end
            childDownBtn:SetScript("OnClick", function()
                local idx = eleConfig.extraAttr.configSelectedItemIndex
                if idx < #eleConfig.elements then
                    eleConfig.elements[idx], eleConfig.elements[idx + 1] = eleConfig.elements[idx + 1], eleConfig.elements[idx]
                    eleConfig.extraAttr.configSelectedItemIndex = idx + 1
                    HbFrame:ReloadEframeUI(topEleConfig)
                    self:SelectTab(self.selectedTabKey)
                end
            end)
            yOff = yOff - 36
        end

    elseif eleConfig.type == const.ELEMENT_TYPE.SCRIPT then
        -- ============== SCRIPT: title, icon, multiline script content =============

        -- Title + Icon (same row)
        local titleInput = GUI:CreateInput(parent, {
            get = function() return eleConfig.title end,
            set = function(v) eleConfig.title = v; self:BuildTree() end,
        })
        titleInput = GUI:VGroup(parent, L["Title"], titleInput)

        local iconInput = GUI:CreateIconInput(parent, {
            defaultIcon = DEFAULT_ICON,
            ---@diagnostic disable-next-line: return-type-mismatch
            get = function() return (eleConfig.icon) end,
            set = function(v)
                eleConfig.icon = v
                self:BuildTree()
            end,
        })
        iconInput = GUI:VGroup(parent, L["Element Icon ID or Path"], iconInput)
        yOff = LayoutRow({titleInput, iconInput}, parent, yOff, PADDING + 10)

        local script = E:ToScript(eleConfig)
        local scriptInput = GUI:CreateMultiLineInput(parent, {
            label = L["Script"], width = contentW - 40, height = 200,
            get = function() return script.extraAttr and script.extraAttr.script or "" end,
            validate = function(val)
                local func, loadstringErr = loadstring(val)
                if not func then
                    Config.ShowErrorDialog(L["Illegal script."] .. " " .. tostring(loadstringErr))
                    return false
                end
                local status, pcallErr = pcall(func())
                if not status then
                    Config.ShowErrorDialog(L["Illegal script."] .. " " .. tostring(pcallErr))
                    return false
                end
                return true
            end,
            set = function(v)
                if script.extraAttr then script.extraAttr.script = v end
                HbFrame:ReloadEframeUI(topEleConfig)
            end,
        })
        yOff = LayoutWidget(scriptInput, parent, yOff, PADDING + 10)

    elseif eleConfig.type == const.ELEMENT_TYPE.MACRO then
        -- ============== MACRO: title, icon, multiline macro content =============

        -- Title + Icon (same row)
        local titleInput = GUI:CreateInput(parent, {
            get = function() return eleConfig.title end,
            set = function(v) eleConfig.title = v; self:BuildTree() end,
        })
        titleInput = GUI:VGroup(parent, L["Title"], titleInput)

        local iconInput = GUI:CreateIconInput(parent, {
            defaultIcon = DEFAULT_ICON,
            ---@diagnostic disable-next-line: return-type-mismatch
            get = function() return (eleConfig.icon) end,
            set = function(v)
                eleConfig.icon = v
                self:BuildTree()
            end,
        })
        iconInput = GUI:VGroup(parent, L["Element Icon ID or Path"], iconInput)
        yOff = LayoutRow({titleInput, iconInput}, parent, yOff, PADDING + 10)

        local macro = E:ToMacro(eleConfig)
        local macroInput = GUI:CreateMultiLineInput(parent, {
            label = L["Macro"], width = contentW - 40, height = 200,
            get = function() return macro.extraAttr and macro.extraAttr.macro or "" end,
            validate = function(val)
                if Macro and Macro.Ast then
                    local macroAstR = Macro:Ast(val)
                    if macroAstR:is_err() then
                        Config.ShowErrorDialog(macroAstR:unwrap_err())
                        return false
                    end
                    addon.G.tmpMacroAst = macroAstR:unwrap()
                end
                return true
            end,
            set = function(v)
                if macro.extraAttr then
                    macro.extraAttr.macro = v
                    if Macro and addon.G.tmpMacroAst then
                        macro.extraAttr.ast = U.Table.DeepCopy(addon.G.tmpMacroAst)
                        local events = Macro:GetEventsFromAst(macro.extraAttr.ast)
                        if events then
                            eleConfig.listenEvents = events
                        end
                    end
                end
                HbFrame:ReloadEframeUI(topEleConfig)
            end,
        })
        yOff = LayoutWidget(macroInput, parent, yOff, PADDING + 10)

    end

    parent:SetHeight(math_abs(yOff) + PADDING)
end

-------------------------------------------------------------------------------
-- Display Tab
-------------------------------------------------------------------------------

function CF:RenderDisplay(parent, eleConfig, topEleConfig, contentW)
    local yOff = -PADDING
    local isRoot = eleConfig.type == const.ELEMENT_TYPE.BAR

    -- Load condition
    yOff = SectionDivider(parent, L["Load Rule"], yOff, contentW - 20)

    -- isLoad toggle
    local loadSwitch = GUI:CreateSwitch(parent, {
        label = L["Load"],
        get = function()
            if eleConfig.loadCond then return eleConfig.loadCond.LoadCond end
            return true
        end,
        set = function(v)
            if not eleConfig.loadCond then eleConfig.loadCond = {} end
            eleConfig.loadCond.LoadCond = v
            HbFrame:ReloadEframeUI(topEleConfig or eleConfig)
        end,
    })
    yOff = LayoutWidget(loadSwitch, parent, yOff, PADDING + 10)

    -- BAR-only: mouseEnter, combat condition
    if isRoot then
        local mouseSwitch = GUI:CreateSwitch(parent, {
            label = L["Whether to show the bar menu when the mouse enter."],
            get = function() return eleConfig.isDisplayMouseEnter end,
            set = function(v)
                eleConfig.isDisplayMouseEnter = v
                HbFrame:ReloadEframeUI(eleConfig)
            end,
        })
        yOff = LayoutWidget(mouseSwitch, parent, yOff, PADDING + 10)

        -- Combat condition toggle + select (same row)
        local combatSwitch = GUI:CreateSwitch(parent, {
            label = L["Combat Load Condition"],
            get = function() return eleConfig.loadCond and eleConfig.loadCond.CombatCond ~= nil end,
            set = function(v)
                if not eleConfig.loadCond then eleConfig.loadCond = {} end
                if v then
                    eleConfig.loadCond.CombatCond = eleConfig.loadCond.CombatCond or false
                else
                    eleConfig.loadCond.CombatCond = nil
                end
                self:SelectTab(self.selectedTabKey)
            end,
        })

        if eleConfig.loadCond and eleConfig.loadCond.CombatCond ~= nil then
            local combatOpts = {}
            for k, v in pairs(const.LoadCondCombatOptions) do
                tinsert(combatOpts, { value = k, text = v })
            end
            local combatDD = GUI:CreateDropdown(parent, {
                label = "",
                options = combatOpts,
                get = function() return eleConfig.loadCond.CombatCond end,
                set = function(v)
                    eleConfig.loadCond.CombatCond = v
                end,
            })
            yOff = LayoutRow({combatSwitch, combatDD}, parent, yOff, PADDING + 10)
        else
            yOff = LayoutWidget(combatSwitch, parent, yOff, PADDING + 10)
        end
    end

    -- Class filter (both root and child)
    local classSwitch = GUI:CreateSwitch(parent, {
        label = L["Enable Class Settings"],
        get = function() return eleConfig.loadCond and eleConfig.loadCond.ClassCond ~= nil end,
        set = function(v)
            if not eleConfig.loadCond then eleConfig.loadCond = {} end
            if v then
                if not eleConfig.loadCond.ClassCond then
                    eleConfig.loadCond.ClassCond = {}
                end
            else
                eleConfig.loadCond.ClassCond = nil
            end
            self:SelectTab(self.selectedTabKey)
        end,
    })
    yOff = LayoutWidget(classSwitch, parent, yOff, PADDING + 10)

    if eleConfig.loadCond and eleConfig.loadCond.ClassCond then
        for classId, className in pairs(const.ClassOptions) do
            local cSwitch = GUI:CreateSwitch(parent, {
                label = className,
                get = function()
                    return eleConfig.loadCond.ClassCond[classId] == true
                end,
                set = function(v)
                    eleConfig.loadCond.ClassCond[classId] = v or nil
                end,
            })
            yOff = LayoutWidget(cSwitch, parent, yOff, PADDING + 20)
        end
    end

    -- Display Rule
    yOff = SectionDivider(parent, L["Display Rule"], yOff, contentW - 20)

    local ruleOpts = {}
    for k, v in pairs(const.DisplayStateRuleOptions) do
        tinsert(ruleOpts, { value = k, text = v })
    end

    -- Unlearned (switch + dropdown same row)
    local unlearnedSwitch = GUI:CreateSwitch(parent, {
        label = L["Not Owned"],
        get = function() return eleConfig.displayRule and eleConfig.displayRule.unlearned ~= nil end,
        set = function(v)
            if not eleConfig.displayRule then eleConfig.displayRule = {} end
            if v then
                eleConfig.displayRule.unlearned = eleConfig.displayRule.unlearned or "hide"
            else
                eleConfig.displayRule.unlearned = nil
            end
            self:SelectTab(self.selectedTabKey)
        end,
    })

    if eleConfig.displayRule and eleConfig.displayRule.unlearned then
        local unlearnedDD = GUI:CreateDropdown(parent, {
            label = "", width = 160,
            options = ruleOpts,
            get = function() return eleConfig.displayRule.unlearned end,
            set = function(v) eleConfig.displayRule.unlearned = v end,
        })
        yOff = LayoutRow({unlearnedSwitch, unlearnedDD}, parent, yOff, PADDING + 10)
    else
        yOff = LayoutWidget(unlearnedSwitch, parent, yOff, PADDING + 10)
    end

    -- Unusable (switch + dropdown same row)
    local unusableSwitch = GUI:CreateSwitch(parent, {
        label = L["Not Usable"],
        get = function() return eleConfig.displayRule and eleConfig.displayRule.unusable ~= nil end,
        set = function(v)
            if not eleConfig.displayRule then eleConfig.displayRule = {} end
            if v then
                eleConfig.displayRule.unusable = eleConfig.displayRule.unusable or "gray"
            else
                eleConfig.displayRule.unusable = nil
            end
            self:SelectTab(self.selectedTabKey)
        end,
    })

    if eleConfig.displayRule and eleConfig.displayRule.unusable then
        local unusableDD = GUI:CreateDropdown(parent, {
            label = "", width = 160,
            options = ruleOpts,
            get = function() return eleConfig.displayRule.unusable end,
            set = function(v) eleConfig.displayRule.unusable = v end,
        })
        yOff = LayoutRow({unusableSwitch, unusableDD}, parent, yOff, PADDING + 10)
    else
        yOff = LayoutWidget(unusableSwitch, parent, yOff, PADDING + 10)
    end

    -- BAR-only: quality border, growth direction
    if isRoot then
        local qualitySwitch = GUI:CreateSwitch(parent, {
            label = L["Show Item Quality Color"],
            get = function() return eleConfig.isShowQualityBorder end,
            set = function(v)
                eleConfig.isShowQualityBorder = v
                HbFrame:ReloadEframeUI(eleConfig)
            end,
        })
        yOff = LayoutWidget(qualitySwitch, parent, yOff, PADDING + 10)

        -- Growth direction
        local growthOpts = {}
        for k, v in pairs(const.GrowthOptions) do
            tinsert(growthOpts, { value = k, text = v })
        end
        local growthDD = GUI:CreateDropdown(parent, {
            width = 160,
            options = growthOpts,
            get = function() return eleConfig.elesGrowth end,
            set = function(v)
                eleConfig.elesGrowth = v
                HbFrame:ReloadEframeUI(eleConfig)
            end,
        })
        growthDD = GUI:VGroup(parent, L["Direction of elements growth"], growthDD)
        yOff = LayoutWidget(growthDD, parent, yOff, PADDING + 10)

        -- Flyout mode
        local flyoutSwitch = GUI:CreateSwitch(parent, {
            label = L["Flyout"],
            get = function() return eleConfig.flyout == true end,
            set = function(v)
                eleConfig.flyout = v or nil
                HbFrame:ReloadEframeUI(eleConfig)
                self:BuildTabs(eleConfig)
                self:SelectTab(self.selectedTabKey)
            end,
        })
        yOff = LayoutWidget(flyoutSwitch, parent, yOff, PADDING + 10)
    end

    parent:SetHeight(math_abs(yOff) + PADDING)
end

-------------------------------------------------------------------------------
-- Text Tab
-------------------------------------------------------------------------------

function CF:RenderText(parent, eleConfig, topEleConfig, contentW)
    EnsureModules()
    local Text = addon:GetModule("Text")
    local yOff = -PADDING
    local isRoot = eleConfig.type == const.ELEMENT_TYPE.BAR
    local updateId = topEleConfig or eleConfig

    -- Use root settings (for child elements)
    if not isRoot then
        local useRootSwitch = GUI:CreateSwitch(parent, {
            label = L["Use root element settings"],
            get = function() return eleConfig.isUseRootTexts end,
            set = function(v)
                eleConfig.isUseRootTexts = v
                self:SelectTab(self.selectedTabKey)
            end,
        })
        yOff = LayoutWidget(useRootSwitch, parent, yOff, PADDING + 10)

        if eleConfig.isUseRootTexts then
            parent:SetHeight(math_abs(yOff) + PADDING)
            return
        end
    end

    -- Helper: check if a text expr exists in texts array
    local function hasTextExpr(expr)
        if not eleConfig.texts then return false end
        for _, t in ipairs(eleConfig.texts) do
            if t.text == expr then return true end
        end
        return false
    end

    local function getTextGrowth(expr)
        if not eleConfig.texts then return nil end
        for _, t in ipairs(eleConfig.texts) do
            if t.text == expr then return t.growth end
        end
        return nil
    end

    -- Item Name toggle (%n) + growth direction (same row when enabled)
    local nameSwitch = GUI:CreateSwitch(parent, {
        label = L["Item Name"],
        get = function() return hasTextExpr("%n") end,
        set = function()
            if not eleConfig.texts then eleConfig.texts = {} end
            for i, t in ipairs(eleConfig.texts) do
                if t.text == "%n" then
                    table.remove(eleConfig.texts, i)
                    HbFrame:ReloadEframeUI(updateId)
                    self:SelectTab(self.selectedTabKey)
                    return
                end
            end
            tinsert(eleConfig.texts, Text:New("%n"))
            HbFrame:ReloadEframeUI(updateId)
            self:SelectTab(self.selectedTabKey)
        end,
    })

    if hasTextExpr("%n") then
        local tgOpts = {}
        for k, v in pairs(const.TextGrowthOptions) do
            tinsert(tgOpts, { value = k, text = v })
        end
        local nameGrowthDD = GUI:CreateDropdown(parent, {
            width = 140,
            options = tgOpts,
            get = function() return getTextGrowth("%n") end,
            set = function(v)
                if eleConfig.texts then
                    for _, t in ipairs(eleConfig.texts) do
                        if t.text == "%n" then
                            t.growth = v
                            HbFrame:ReloadEframeUI(updateId)
                            return
                        end
                    end
                end
            end,
        })
        nameGrowthDD = GUI:VGroup(parent, L["Text Growth"], nameGrowthDD)
        yOff = LayoutRow({nameSwitch, nameGrowthDD}, parent, yOff, PADDING + 10)
    else
        yOff = LayoutWidget(nameSwitch, parent, yOff, PADDING + 10)
    end

    -- Item Count toggle (%s)
    local countSwitch = GUI:CreateSwitch(parent, {
        label = L["Item Count"],
        get = function() return hasTextExpr("%s") end,
        set = function()
            if not eleConfig.texts then eleConfig.texts = {} end
            for i, t in ipairs(eleConfig.texts) do
                if t.text == "%s" then
                    table.remove(eleConfig.texts, i)
                    HbFrame:ReloadEframeUI(updateId)
                    self:SelectTab(self.selectedTabKey)
                    return
                end
            end
            tinsert(eleConfig.texts, Text:New("%s"))
            HbFrame:ReloadEframeUI(updateId)
            self:SelectTab(self.selectedTabKey)
        end,
    })
    yOff = LayoutWidget(countSwitch, parent, yOff, PADDING + 10)

    parent:SetHeight(math_abs(yOff) + PADDING)
end

-------------------------------------------------------------------------------
-- Create Tab (add child elements to BAR) — sub-tab based
-------------------------------------------------------------------------------

CF._createSubTab = "item"
CF._createState = {}

function CF:RenderCreate(parent, eleConfig, contentW)
    EnsureModules()
    local yOff = -PADDING

    -- Sub-tabs
    local subTabs = {
        { key = "item",      label = L["Item"] },
        { key = "itemgroup", label = L["ItemGroup"] },
        { key = "macro",     label = L["Macro"] },
        { key = "script",    label = L["Script"] },
    }

    local sub = CF._createSubTab or "item"

    local tg = GUI:CreateTabGroup(parent, subTabs, {
        width = contentW - 20,
        height = 26,
        selected = sub,
        onClick = function(key)
            CF._createSubTab = key
            self:SelectTab("create")
        end,
    })
    tg.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING + 10, yOff)

    yOff = yOff - 26 - 10

    if sub == "item" then
        -- === Create Item ===
        if not CF._createState.item then
            CF._createState.item = { itemType = const.ITEM_TYPE.ITEM }
        end
        local s = CF._createState.item

        local itOpts = {}
        for k, v in pairs(const.ItemTypeOptions) do
            tinsert(itOpts, { value = k, text = v })
        end
        local typeDD = GUI:CreateDropdown(parent, {
            width = 160,
            options = itOpts,
            get = function() return s.itemType end,
            set = function(v) s.itemType = v end,
        })
        typeDD = GUI:VGroup(parent, L["Item Type"], typeDD)

        local valInput = GUI:CreateInput(parent, {
            get = function() return s.itemVal or "" end,
            set = function(v)
                s.itemVal = v
                -- Auto-create on input (matching original Config.lua behavior)
                local itemType = s.itemType or const.ITEM_TYPE.ITEM
                local r = Config.VerifyItemAttr(itemType, v)
                if r:is_ok() then
                    local newElement = E:New(
                        Config.GetNewElementTitle(L["Item"], eleConfig.elements),
                        const.ELEMENT_TYPE.ITEM)
                    local item = E:ToItem(newElement)
                    item.extraAttr = U.Table.DeepCopyDict(r:unwrap())
                    item.icon = item.extraAttr.icon
                    tinsert(eleConfig.elements, item)
                    HbFrame:ReloadEframeUI(eleConfig)
                    s.itemVal = nil
                    self:Refresh()
                else
                    -- Async retry for ITEM/EQUIPMENT/TOY
                    if itemType == const.ITEM_TYPE.ITEM or itemType == const.ITEM_TYPE.EQUIPMENT or itemType == const.ITEM_TYPE.TOY then
                        local attempts = 0
                        local function retryVerify()
                            attempts = attempts + 1
                            local r2 = Config.VerifyItemAttr(itemType, v)
                            if r2:is_ok() then
                                local newElement = E:New(
                                    Config.GetNewElementTitle(L["Item"], eleConfig.elements),
                                    const.ELEMENT_TYPE.ITEM)
                                local item = E:ToItem(newElement)
                                item.extraAttr = U.Table.DeepCopyDict(r2:unwrap())
                                item.icon = item.extraAttr.icon
                                tinsert(eleConfig.elements, item)
                                HbFrame:ReloadEframeUI(eleConfig)
                                s.itemVal = nil
                                self:Refresh()
                            elseif attempts < 8 then
                                C_Timer.After(0.2, retryVerify)
                            else
                                Config.ShowErrorDialog(L["Invalid item input, please check and re-enter."])
                            end
                        end
                        C_Timer.After(0.2, retryVerify)
                    else
                        Config.ShowErrorDialog(r:unwrap_err())
                    end
                end
            end,
        })
        valInput = GUI:VGroup(parent, L["Item name or item id"], valInput)
        yOff = LayoutRow({typeDD, valInput}, parent, yOff, PADDING + 10)

    elseif sub == "itemgroup" then
        -- === Create ItemGroup ===
        if not CF._createState.itemgroup then
            CF._createState.itemgroup = { mode = const.ITEMS_GROUP_MODE.RANDOM }
        end
        local s = CF._createState.itemgroup

        local modeOpts = {}
        for k, v in pairs(const.ItemsGroupModeOptions) do
            tinsert(modeOpts, { value = k, text = v })
        end
        local modeDD = GUI:CreateDropdown(parent, {
            options = modeOpts,
            get = function() return s.mode end,
            set = function(v) s.mode = v end,
        })
        modeDD = GUI:VGroup(parent, L["Mode"], modeDD)

        local titleInput = GUI:CreateInput(parent, {
            get = function() return s.title or "" end,
            set = function(v)
                if v and v ~= "" then
                    local newIG = E:NewItemGroup(Config.GetNewElementTitle(v, eleConfig.elements))
                    newIG.extraAttr.mode = s.mode or const.ITEMS_GROUP_MODE.RANDOM
                    tinsert(eleConfig.elements, newIG)
                    HbFrame:ReloadEframeUI(eleConfig)
                    s.title = nil
                    self:Refresh()
                end
            end,
        })
        titleInput = GUI:VGroup(parent, L["Title"], titleInput)
        yOff = LayoutRow({modeDD, titleInput}, parent, yOff, PADDING + 10)

    elseif sub == "macro" then
        -- === Create Macro ===
        if not CF._createState.macro then CF._createState.macro = {} end
        local s = CF._createState.macro

        local titleInput = GUI:CreateInput(parent, {
            width = 250,
            get = function() return s.title or "" end,
            set = function(v) s.title = v end,
        })
        titleInput = GUI:VGroup(parent, L["Title"], titleInput)
        yOff = LayoutWidget(titleInput, parent, yOff, PADDING + 10)

        local contentInput = GUI:CreateMultiLineInput(parent, {
            label = L["Macro"], width = contentW - 40, height = 200,
            get = function() return s.content or "" end,
            validate = function(val)
                if Macro and Macro.Ast then
                    local macroAstR = Macro:Ast(val)
                    if macroAstR:is_err() then
                        Config.ShowErrorDialog(macroAstR:unwrap_err())
                        return false
                    end
                    addon.G.tmpMacroAst = macroAstR:unwrap()
                end
                return true
            end,
            set = function(val)
                s.content = val
                if s.title and s.title ~= "" and val and val ~= "" then
                    local newMacro = E:New(
                        Config.GetNewElementTitle(s.title, eleConfig.elements),
                        const.ELEMENT_TYPE.MACRO)
                    newMacro = E:ToMacro(newMacro)
                    newMacro.extraAttr.macro = val
                    if addon.G.tmpMacroAst then
                        newMacro.extraAttr.ast = U.Table.DeepCopy(addon.G.tmpMacroAst)
                        local events = Macro:GetEventsFromAst(newMacro.extraAttr.ast)
                        if events then
                            newMacro.listenEvents = events
                        end
                    end
                    tinsert(eleConfig.elements, newMacro)
                    HbFrame:ReloadEframeUI(eleConfig)
                    s.title = nil
                    s.content = nil
                    self:Refresh()
                end
            end,
        })
        yOff = LayoutWidget(contentInput, parent, yOff, PADDING + 10)

    elseif sub == "script" then
        -- === Create Script ===
        if not CF._createState.script then CF._createState.script = {} end
        local s = CF._createState.script

        local titleInput = GUI:CreateInput(parent, {
            width = 250,
            get = function() return s.title or "" end,
            set = function(v) s.title = v end,
        })
        titleInput = GUI:VGroup(parent, L["Title"], titleInput)
        yOff = LayoutWidget(titleInput, parent, yOff, PADDING + 10)

        local contentInput = GUI:CreateMultiLineInput(parent, {
            label = L["Script"], width = contentW - 40, height = 200,
            get = function() return s.content or "" end,
            validate = function(val)
                local func, err = loadstring(val)
                if not func then
                    Config.ShowErrorDialog(L["Illegal script."] .. " " .. tostring(err))
                    return false
                end
                return true
            end,
            set = function(val)
                s.content = val
                if s.title and s.title ~= "" and val and val ~= "" then
                    local newScript = E:New(
                        Config.GetNewElementTitle(s.title, eleConfig.elements),
                        const.ELEMENT_TYPE.SCRIPT)
                    newScript = E:ToScript(newScript)
                    newScript.extraAttr.script = val
                    tinsert(eleConfig.elements, newScript)
                    HbFrame:ReloadEframeUI(eleConfig)
                    s.title = nil
                    s.content = nil
                    self:Refresh()
                end
            end,
        })
        yOff = LayoutWidget(contentInput, parent, yOff, PADDING + 10)
    end

    parent:SetHeight(math_abs(yOff) + PADDING)
end

-------------------------------------------------------------------------------
-- Bindkey Tab
-------------------------------------------------------------------------------

function CF:RenderBindkey(parent, eleConfig, contentW)
    EnsureModules()
    local yOff = -PADDING
    local updateId = self.selectedNode and self.selectedNode.topEleConfig or eleConfig

    -- Keybinding button (click to start listening, press key to bind)
    local keyWidget = GUI:CreateKeybinding(parent, {
        width = 200,
        height = 26,
        emptyText = L["Bindkey"],
        specialFrameName = "HappyButtonConfigFrame",
        get = function()
            return eleConfig.bindKey and eleConfig.bindKey.key or nil
        end,
        set = function(bindStr)
            if bindStr == nil or bindStr == "" then
                eleConfig.bindKey = nil
            else
                if not eleConfig.bindKey then
                    eleConfig.bindKey = { key = bindStr, characters = {}, classes = {} }
                else
                    eleConfig.bindKey.key = bindStr
                end
            end
            HbFrame:ReloadEframeUI(updateId)
            CF:SelectTab(CF.selectedTabKey)
        end,
    })
    local keyBtn = GUI:VGroup(parent, L["Bindkey"], keyWidget, L["Bindkey Help Content"])

    yOff = LayoutWidget(keyBtn, parent, yOff, PADDING + 10)

    -- Show additional options only when a key is bound
    if eleConfig.bindKey then
        -- Bind for account
        local isAccount = eleConfig.bindKey.characters == nil and eleConfig.bindKey.classes == nil
        local accountSwitch = GUI:CreateSwitch(parent, {
            label = L["Bind For Account"],
            get = function() return isAccount end,
            set = function(v)
                if v then
                    eleConfig.bindKey.characters = nil
                    eleConfig.bindKey.classes = nil
                else
                    eleConfig.bindKey.characters = {}
                    eleConfig.bindKey.classes = {}
                end
                HbFrame:ReloadEframeUI(updateId)
                self:SelectTab(self.selectedTabKey)
            end,
        })
        yOff = LayoutWidget(accountSwitch, parent, yOff, PADDING + 10)

        -- Per-character and per-class (only when not account-wide)
        if not isAccount then
            local charSwitch = GUI:CreateSwitch(parent, {
                label = L["Bind For Current Character"],
                get = function()
                    return eleConfig.bindKey.characters and eleConfig.bindKey.characters[UnitGUID("player")]
                end,
                set = function(v)
                    if not eleConfig.bindKey.characters then eleConfig.bindKey.characters = {} end
                    if v then
                        eleConfig.bindKey.characters[UnitGUID("player")] = true
                    else
                        eleConfig.bindKey.characters[UnitGUID("player")] = nil
                    end
                    HbFrame:ReloadEframeUI(updateId)
                end,
            })
            yOff = LayoutWidget(charSwitch, parent, yOff, PADDING + 10)

            local _, classId = UnitClassBase("player")
            local classSwitch = GUI:CreateSwitch(parent, {
                label = L["Bind For Current Class"],
                get = function()
                    return eleConfig.bindKey.classes and eleConfig.bindKey.classes[classId]
                end,
                set = function(v)
                    if not eleConfig.bindKey.classes then eleConfig.bindKey.classes = {} end
                    if v then
                        eleConfig.bindKey.classes[classId] = true
                    else
                        eleConfig.bindKey.classes[classId] = nil
                    end
                    HbFrame:ReloadEframeUI(updateId)
                end,
            })
            yOff = LayoutWidget(classSwitch, parent, yOff, PADDING + 10)
        end

        -- Combat load condition (switch + dropdown same row)
        local combatSwitch = GUI:CreateSwitch(parent, {
            label = L["Combat Load Condition"],
            get = function() return eleConfig.bindKey.combat ~= nil end,
            set = function(v)
                if v then
                    eleConfig.bindKey.combat = true
                else
                    eleConfig.bindKey.combat = nil
                end
                self:SelectTab(self.selectedTabKey)
            end,
        })

        if eleConfig.bindKey.combat ~= nil then
            local combatOpts = {}
            for k, v in pairs(const.LoadCondCombatOptions) do
                tinsert(combatOpts, { value = k, text = v })
            end
            local combatDD = GUI:CreateDropdown(parent, {
                label = "",
                options = combatOpts,
                get = function() return eleConfig.bindKey.combat end,
                set = function(v) eleConfig.bindKey.combat = v end,
            })
            yOff = LayoutRow({combatSwitch, combatDD}, parent, yOff, PADDING + 10)
        else
            yOff = LayoutWidget(combatSwitch, parent, yOff, PADDING + 10)
        end

        -- AttachFrame load condition (switch + dropdown same row)
        local afSwitch = GUI:CreateSwitch(parent, {
            label = L["AttachFrame Load Condition"],
            get = function() return eleConfig.bindKey.attachFrame ~= nil end,
            set = function(v)
                if v then
                    eleConfig.bindKey.attachFrame = true
                else
                    eleConfig.bindKey.attachFrame = nil
                end
                self:SelectTab(self.selectedTabKey)
            end,
        })

        if eleConfig.bindKey.attachFrame ~= nil then
            local afOpts = {}
            for k, v in pairs(const.LoadCondAttachFrameOptions) do
                tinsert(afOpts, { value = k, text = v })
            end
            local afDD = GUI:CreateDropdown(parent, {
                label = "",
                options = afOpts,
                get = function() return eleConfig.bindKey.attachFrame end,
                set = function(v) eleConfig.bindKey.attachFrame = v end,
            })
            yOff = LayoutRow({afSwitch, afDD}, parent, yOff, PADDING + 10)
        else
            yOff = LayoutWidget(afSwitch, parent, yOff, PADDING + 10)
        end

    end

    parent:SetHeight(math_abs(yOff) + PADDING)
end

-------------------------------------------------------------------------------
-- Event Tab (Script elements)
-------------------------------------------------------------------------------

function CF:RenderEvent(parent, eleConfig, contentW)
    local yOff = -PADDING
    local updateId = self.selectedNode and self.selectedNode.topEleConfig or eleConfig

    -- Enable event listening toggle
    local enableSwitch = GUI:CreateSwitch(parent, {
        label = L["Enable Event Listening"],
        get = function() return eleConfig.listenEvents ~= nil end,
        set = function(v)
            if v then
                eleConfig.listenEvents = eleConfig.listenEvents or {}
            else
                eleConfig.listenEvents = nil
            end
            HbFrame:ReloadEframeUI(updateId)
            self:SelectTab(self.selectedTabKey)
        end,
    })
    yOff = LayoutWidget(enableSwitch, parent, yOff, PADDING + 10)

    -- Event multiselect (only when enabled)
    if eleConfig.listenEvents ~= nil then
        for eventKey, _ in pairs(const.BUILDIN_EVENTS) do
            local evSwitch = GUI:CreateSwitch(parent, {
                label = eventKey,
                get = function() return eleConfig.listenEvents[eventKey] == true end,
                set = function(v)
                    if v then
                        eleConfig.listenEvents[eventKey] = true
                    else
                        eleConfig.listenEvents[eventKey] = nil
                    end
                    HbFrame:ReloadEframeUI(updateId)
                end,
            })
            yOff = LayoutWidget(evSwitch, parent, yOff, PADDING + 20)
        end
    end

    parent:SetHeight(math_abs(yOff) + PADDING)
end

-------------------------------------------------------------------------------
-- Import UI (shown when no node is selected)
-------------------------------------------------------------------------------

function CF:RenderImport(parent, contentW)
    EnsureModules()
    local yOff = -PADDING

    -- Import multiline editbox (no auto-submit on focus lost)
    local importBox = GUI:CreateMultiLineInput(parent, {
        label = L["Configuration string"],
        width = contentW - 40,
        height = 180,
        get = function() return addon.G.tmpImportElementConfigString or "" end,
        set = function() end, -- noop: submit via button
        validate = function() return true end,
    })
    importBox:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING + 10, yOff)
    yOff = yOff - 200

    -- Import confirm button
    local importBtn = GUI:CreateButton(parent, L["Import"], 120, 28)
    importBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING + 10, yOff)
    importBtn:SetScript("OnClick", function()
        local val = importBox:GetValue()
        addon.G.tmpImportElementConfigString = val
        self:DoImport(val)
    end)
    yOff = yOff - 36

    parent:SetHeight(math_abs(yOff) + PADDING)
end

function CF:DoImport(val)
    EnsureModules()
    local errorMsg = L["Import failed: Invalid configuration string."]
    if val == nil or val == "" then
        U.Print.PrintErrorText(errorMsg)
        return
    end
    local AceSerializer = LibStub("AceSerializer-3.0")
    local LibDeflate = LibStub("LibDeflate")
    if not AceSerializer or not LibDeflate or not Config then return end

    local decodedData = LibDeflate:DecodeForPrint(val)
    if decodedData == nil then U.Print.PrintErrorText(errorMsg); return end

    local decompressedData = LibDeflate:DecompressDeflate(decodedData)
    if decompressedData == nil then U.Print.PrintErrorText(errorMsg); return end

    local success, eleConfig = AceSerializer:Deserialize(decompressedData)
    if not success then U.Print.PrintErrorText(errorMsg); return end
    if type(eleConfig) ~= "table" then U.Print.PrintErrorText(errorMsg); return end
    if eleConfig.title == nil then U.Print.PrintErrorText(errorMsg); return end

    local rightType = false
    for _, v in pairs(const.ELEMENT_TYPE) do
        if v == eleConfig.type then rightType = true; break end
    end
    if not rightType then U.Print.PrintErrorText(errorMsg); return end
    if eleConfig.extraAttr == nil then U.Print.PrintErrorText(errorMsg); return end

    -- Always strip keybinds on import
    addon.G.tmpImportKeybind = false
    Config.HandleConfig(eleConfig)
    eleConfig = Config.NormalizeAsRootBar(eleConfig, addon.db.profile.elements)

    if Config.IsIdDuplicated(eleConfig.id, addon.db.profile.elements) then
        -- Show confirm dialog for overwrite
        local dialog = StaticPopup_Show("HAPPYBUTTON_CONFIRM_IMPORT_OVERWRITE")
        if dialog then
            dialog.data = {
                onAccept = function()
                    for i, ele in ipairs(addon.db.profile.elements) do
                        if ele.id == eleConfig.id then
                            addon.db.profile.elements[i] = eleConfig
                            HbFrame:ReloadEframeUI(eleConfig)
                            CF:Refresh()
                            U.Print.PrintSuccessText(L["Import successful."])
                            return
                        end
                    end
                end,
                onCancel = function()
                    eleConfig.id = U.String.GenerateID()
                    if Config.IsTitleDuplicated(eleConfig.title, addon.db.profile.elements) then
                        eleConfig.title = Config.CreateDuplicateTitle(eleConfig.title, addon.db.profile.elements)
                    end
                    tinsert(addon.db.profile.elements, eleConfig)
                    HbFrame:AddEframe(eleConfig)
                    CF:Refresh()
                    U.Print.PrintSuccessText(L["Import successful."])
                end,
            }
        end
        return
    end

    if Config.IsTitleDuplicated(eleConfig.title, addon.db.profile.elements) then
        eleConfig.title = Config.CreateDuplicateTitle(eleConfig.title, addon.db.profile.elements)
    end

    tinsert(addon.db.profile.elements, eleConfig)
    HbFrame:AddEframe(eleConfig)
    self:Refresh()
    U.Print.PrintSuccessText(L["Import successful."])
end

-------------------------------------------------------------------------------
-- Placeholder for unimplemented tabs
-------------------------------------------------------------------------------

function CF:RenderPlaceholder(parent, tabKey)
    local text = GUI:CreateText(parent, "Tab: " .. tostring(tabKey), GUI.Fonts.size_header)
    text:SetPoint("CENTER", parent, "TOP", 0, -60)
    text:SetTextColor(unpack(GUI.Colors.disabled))
    parent:SetHeight(120)
end

-------------------------------------------------------------------------------
-- Actions
-------------------------------------------------------------------------------

function CF:OnAddBar()
    local E = addon:GetModule("Element")
    if E and E.New then
        local newBar = E:New(L["Bar"], const.ELEMENT_TYPE.BAR)
        tinsert(addon.db.profile.elements, newBar)
        HbFrame:AddEframe(newBar)
        local barIdx = #addon.db.profile.elements
        self.expandedBars[barIdx] = true
        self:SelectNode({
            eleConfig = newBar,
            topEleConfig = newBar,
            barIndex = barIdx,
            childIndex = nil,
        })
        self:Refresh()
    end
end

function CF:OnDeleteBar(eleConfig)
    if not eleConfig then return end
    local elements = addon.db.profile.elements
    for i, ele in ipairs(elements) do
        if ele.id == eleConfig.id then
            HbFrame:DeleteEframe(eleConfig)
            table.remove(elements, i)
            self.selectedNode = nil
            self:Refresh()
            return
        end
    end
end

function CF:OnDeleteElement(eleConfig, topEleConfig)
    if not eleConfig or not topEleConfig or not topEleConfig.elements then return end
    for i, ele in ipairs(topEleConfig.elements) do
        if ele.id == eleConfig.id then
            table.remove(topEleConfig.elements, i)
            HbFrame:ReloadEframeUI(topEleConfig)
            self.selectedNode = nil
            self:Refresh()
            return
        end
    end
end

function CF:OnMoveUp(nodeInfo)
    local elements = addon.db.profile.elements
    if not elements then return end
    if nodeInfo.childIndex then
        -- Move child element up within bar
        local list = nodeInfo.topEleConfig.elements
        local idx = nodeInfo.childIndex
        if idx <= 1 then return end
        list[idx], list[idx - 1] = list[idx - 1], list[idx]
        nodeInfo.childIndex = idx - 1
        HbFrame:ReloadEframeUI(nodeInfo.topEleConfig)
    else
        -- Move bar up
        local idx = nodeInfo.barIndex
        if idx <= 1 then return end
        elements[idx], elements[idx - 1] = elements[idx - 1], elements[idx]
        nodeInfo.barIndex = idx - 1
        HbFrame:ReloadAllEframeUI()
    end
    self.selectedNode = nodeInfo
    self:Refresh()
end

function CF:OnMoveDown(nodeInfo)
    local elements = addon.db.profile.elements
    if not elements then return end
    if nodeInfo.childIndex then
        local list = nodeInfo.topEleConfig.elements
        local idx = nodeInfo.childIndex
        if idx >= #list then return end
        list[idx], list[idx + 1] = list[idx + 1], list[idx]
        nodeInfo.childIndex = idx + 1
        HbFrame:ReloadEframeUI(nodeInfo.topEleConfig)
    else
        local idx = nodeInfo.barIndex
        if idx >= #elements then return end
        elements[idx], elements[idx + 1] = elements[idx + 1], elements[idx]
        nodeInfo.barIndex = idx + 1
        HbFrame:ReloadAllEframeUI()
    end
    self.selectedNode = nodeInfo
    self:Refresh()
end

function CF:OnCopy(nodeInfo)
    local U = addon:GetModule("Utils")
    local E = addon:GetModule("Element")
    if not U or not E then return end
    local copy = U.Table.DeepCopy(nodeInfo.eleConfig)
    -- Assign new ID to the copy and all sub-elements
    copy.id = U.String.GenerateID()
    copy.title = (copy.title or "") .. " " .. L["Copy"]
    if copy.elements then
        for _, child in ipairs(copy.elements) do
            child.id = U.String.GenerateID()
        end
    end
    if nodeInfo.childIndex then
        -- Copy child element within bar
        local list = nodeInfo.topEleConfig.elements
        tinsert(list, nodeInfo.childIndex + 1, copy)
        HbFrame:ReloadEframeUI(nodeInfo.topEleConfig)
    else
        -- Copy bar
        local elements = addon.db.profile.elements
        tinsert(elements, nodeInfo.barIndex + 1, copy)
        HbFrame:AddEframe(copy)
    end
    self:Refresh()
end

function CF:OnExport(nodeInfo)
    local AceSerializer = LibStub("AceSerializer-3.0")
    local LibDeflate = LibStub("LibDeflate")
    local Cfg = addon.G.Config
    if not AceSerializer or not LibDeflate or not Cfg then return end
    local serialized = AceSerializer:Serialize(nodeInfo.eleConfig)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForPrint(compressed)
    Cfg.ShowExportDialog(encoded)
end

function CF:ShowContextMenu(anchor, nodeInfo)
    local isBar = nodeInfo.childIndex == nil
    local elements = addon.db.profile.elements
    local options = {}

    -- Move Up
    local canUp = isBar and (nodeInfo.barIndex > 1) or (not isBar and nodeInfo.childIndex > 1)
    tinsert(options, {
        text = L["Move Up"],
        disabled = not canUp,
        func = function() self:OnMoveUp(nodeInfo) end,
    })

    -- Move Down
    local canDown
    if isBar then
        canDown = elements and nodeInfo.barIndex < #elements
    else
        canDown = nodeInfo.topEleConfig.elements and nodeInfo.childIndex < #nodeInfo.topEleConfig.elements
    end
    tinsert(options, {
        text = L["Move Down"],
        disabled = not canDown,
        func = function() self:OnMoveDown(nodeInfo) end,
    })

    -- Copy (child elements only, not bars)
    if not isBar then
        tinsert(options, {
            text = L["Copy"],
            func = function() self:OnCopy(nodeInfo) end,
        })
    end

    -- Export (bars only)
    if isBar then
        tinsert(options, {
            text = L["Export"],
            func = function() self:OnExport(nodeInfo) end,
        })
    end

    -- Delete
    tinsert(options, {
        text = L["Delete"],
        func = function()
            if isBar then
                local dialog = StaticPopup_Show("HAPPYBUTTON_CONFIRM_DELETE_BAR")
                if dialog then
                    dialog.data = { onAccept = function() self:OnDeleteBar(nodeInfo.eleConfig) end }
                end
            else
                local dialog = StaticPopup_Show("HAPPYBUTTON_CONFIRM_DELETE_ELEMENT")
                if dialog then
                    dialog.data = { onAccept = function() self:OnDeleteElement(nodeInfo.eleConfig, nodeInfo.topEleConfig) end }
                end
            end
        end,
    })

    GUI:OpenDropdown(anchor, options)
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

function CF:Refresh()
    if not self.frame or not self.frame:IsShown() then return end
    self:BuildTree()
    if self.selectedNode then
        self:SelectTab(self.selectedTabKey)
    else
        self:ClearContent()
        if self.placeholder then self.placeholder:Hide() end
        for _, btn in ipairs(self.tabButtons) do btn:Hide() end
        -- Show hint when nothing selected
        local hint = GUI:CreateText(self.contentChild, L["Select an element from the left tree to edit its settings."], GUI.Fonts.size_normal)
        hint:SetPoint("TOPLEFT", self.contentChild, "TOPLEFT", PADDING + 10, -PADDING)
        hint:SetWidth((self.rightPanel:GetWidth() or 400) - 60)
        hint:SetTextColor(unpack(GUI.Colors.disabled))
        hint:SetJustifyH("CENTER")
        hint:SetWordWrap(true)
        self.contentChild:SetHeight(60)
    end
end

function CF:ShowImportView()
    self.selectedNode = nil
    self.selectedTabKey = nil
    -- Deselect tree nodes
    if self.treeButtons then
        for _, tb in ipairs(self.treeButtons) do
            tb.isSelected = false
            if tb.selBg then tb.selBg:Hide() end
        end
    end
    self:ClearContent()
    if self.placeholder then self.placeholder:Hide() end
    for _, btn in ipairs(self.tabButtons) do btn:Hide() end
    self:RenderImport(self.contentChild, (self.rightPanel:GetWidth() or 400) - 20)
end

function CF:Toggle()
    if InCombatLockdown() then
        local U = addon:GetModule("Utils")
        if U and U.Print and U.Print.PrintInfoText then
            U.Print.PrintInfoText(L["You cannot use this in combat."])
        end
        return
    end

    if not self.frame then
        self:CreateMainFrame()
    end

    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self.frame:Show()
        self:Refresh()
    end
end

function CF:Show()
    self:Toggle()
end

function CF:Hide()
    if self.frame then self.frame:Hide() end
end
