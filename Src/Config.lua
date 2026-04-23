local addonName, _ = ... ---@type string, table

---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class Result: AceModule
local R = addon:GetModule("Result")

---@class HbFrame: AceModule
local HbFrame = addon:GetModule("HbFrame")

local L = LibStub("AceLocale-3.0"):GetLocale(addonName, false)

---@class E: AceModule
local E = addon:GetModule("Element")

---@class Text: AceModule
local Text = addon:GetModule("Text")

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class Client: AceModule
local Client = addon:GetModule("Client")

---@class Api: AceModule
local Api = addon:GetModule("Api")

---@class Macro: AceModule
local Macro = addon:GetModule("Macro")

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")
local LibDeflate = LibStub:GetLibrary("LibDeflate")
local AceGUI = LibStub("AceGUI-3.0")

---@class Config
local Config = {}
local tooltipSetTextPatched = setmetatable({}, { __mode = "k" })
-- Ace3 width notes:
-- 1. AceConfigDialog uses width_multiplier = 170, so width = 1 means 170px.
-- 2. In the main Tree + Scroll layout, effective full width is:
--    full = DEFAULT_CONFIG_UI_WIDTH - 34 (Frame content) - 175 (Tree) - 20 (Tree gap) - 20 (ScrollBar)
--         = DEFAULT_CONFIG_UI_WIDTH - 249
-- 3. To keep full and numeric widths on the same ratio base, use:
--    DEFAULT_CONFIG_UI_WIDTH = 249 + 170 * N
--    where N is how many width = 1 units should fit into a full row.
-- 4. Strict proportional width candidates:
--    N = 3 -> 759/760, N = 4 -> 929/930, N = 5 -> 1099/1100,
--    N = 6 -> 1269/1270, N = 7 -> 1439/1440
-- 5. Current value 960 is a readability-oriented width, not a strict N-integer proportional width.
local DEFAULT_CONFIG_UI_WIDTH = 930
local DEFAULT_CONFIG_UI_HEIGHT = 600

---@param itemID number | nil
---@return string
local function GetCraftingQualityMarkup(itemID)
    if not Client:IsRetail() or not itemID or not C_TradeSkillUI or not C_TradeSkillUI.GetItemReagentQualityInfo then
        return ""
    end
    local qualityInfo = C_TradeSkillUI.GetItemReagentQualityInfo(itemID)
    if qualityInfo == nil or qualityInfo.iconChat == nil then
        return ""
    end
    return " " .. CreateAtlasMarkup(qualityInfo.iconChat, 16, 16)
end

---@param item ItemAttr | nil
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

---@param selectGroups string[]
---@param hasChildren boolean
local function SetBarDefaultTab(selectGroups, hasChildren)
    local status = AceConfigDialog:GetStatusTable(addonName, selectGroups)
    if status.groups == nil then
        status.groups = {}
    end
    -- 仅在首次进入时设置默认tab，避免后续刷新把当前tab强制切回列表。
    if status.groups.selected == nil then
        if hasChildren then
            status.groups.selected = "barElementList"
        else
            status.groups.selected = "barElementCreate"
        end
    end
end

-- WoW 12.x tooltip:SetText 参数签名变化兼容。
-- 仅补丁 AceConfigDialog 使用的 tooltip 对象，避免改动第三方库源码。
function Config.PatchAceConfigTooltipSetText()
    if AceConfigDialog == nil or AceConfigDialog.tooltip == nil then
        return
    end
    local tooltip = AceConfigDialog.tooltip
    if tooltipSetTextPatched[tooltip] == true then
        return
    end
    local rawSetText = tooltip.SetText
    if type(rawSetText) ~= "function" then
        return
    end
    tooltip.SetText = function(self, text, r, g, b, alpha, wrap)
        local ok = pcall(rawSetText, self, text, r, g, b, alpha, wrap)
        if ok then
            return
        end
        -- 兼容旧调用：SetText(text, r, g, b, wrap)
        if type(alpha) == "boolean" and wrap == nil then
            local okOld = pcall(rawSetText, self, text, nil, nil, alpha)
            if okOld then
                return
            end
        end
        pcall(rawSetText, self, text)
    end
    tooltipSetTextPatched[tooltip] = true
end

---@param itemType ElementType
---@param val string | nil
---@return Result
function Config.VerifyItemAttr(itemType, val)
    if val == nil or val == "" or val == " " then
        return R:Err("Please input effect title.")
    end
    local G = addon.G
    local item = {} ---@type ItemAttr
    item.type = itemType
    if item.type == nil then return R:Err(L["Please select item type."]) end
    -- 添加物品逻辑
    -- 说明：print(type(C_ToyBox.GetToyInfo(item.id))) 返回的是number，和文档定义的不一致，无法通过API获取玩具信息，因此只能使用物品的API来获取
    if item.type == const.ITEM_TYPE.ITEM or item.type == const.ITEM_TYPE.EQUIPMENT or item.type == const.ITEM_TYPE.TOY then
        local input = tonumber(val) or val
        local itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subClassID = Api.GetItemInfoInstant(input)
        if itemID then
            item.id = itemID
            item.icon = icon
        elseif tonumber(val) ~= nil then
            item.id = tonumber(val)
            if C_Item and C_Item.RequestLoadItemDataByID then
                C_Item.RequestLoadItemDataByID(item.id)
            end
            return R:Err(L["Item data is not ready yet, please try again."])
        else
            local _, itemLinkByInfo, _, _, _, _, _, _, _, itemTextureByInfo = Api.GetItemInfo(val)
            local itemIDByInfo = itemLinkByInfo and tonumber(string.match(itemLinkByInfo, "item:(%d+)")) or nil
            if itemIDByInfo then
                item.id = itemIDByInfo
                item.icon = itemTextureByInfo
            else
                return R:Err(L["Unable to get the id, please check the input."])
            end
        end

        if item.icon == nil and C_Item and C_Item.GetItemIconByID then
            item.icon = C_Item.GetItemIconByID(item.id)
        end

        local itemName = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(item.id)
        if itemName then
            item.name = itemName
        else
            if C_Item and C_Item.RequestLoadItemDataByID then
                C_Item.RequestLoadItemDataByID(item.id)
            end
            return R:Err(L["Item data is not ready yet, please try again."])
        end

        -- local itemID = C_Item.GetItemIDForItemInfo(val)
        -- if itemID then
        --     item.id = itemID
        -- else
        --     return R:Err(L["Unable to get the id, please check the input."])
        -- end
        -- local itemIcon = C_Item.GetItemIconByID(item.id)
        -- if itemIcon then
        --     item.icon = itemIcon
        -- else
        --     return R:Err("Can not get the icon, please check your input.")
        -- end

    elseif item.type == const.ITEM_TYPE.SPELL then
        if Client:IsRetail() then
            local spellID = C_Spell.GetSpellIDForSpellIdentifier(val)
            if spellID then
                item.id = spellID
            else
                return R:Err(L["Unable to get the id, please check the input."])
            end
            local spellName = C_Spell.GetSpellName(item.id)
            if spellName then
                item.name = spellName
            else
                return R:Err("Can not get the name, please check your input.")
            end
            local iconID, originalIconID = C_Spell.GetSpellTexture(item.id)
            if iconID then
                item.icon = iconID
            else
                return R:Err(L["Unable to get the icon, please check the input."])
            end
        else
            local spellInfo = Api.GetSpellInfo(val)
            if spellInfo then
                item.id = spellInfo.spellID
                item.name = spellInfo.name
                item.icon = spellInfo.iconID
            else
                return R:Err(L["Unable to get the id, please check the input."])
            end
        end
    elseif item.type == const.ITEM_TYPE.MOUNT then
        item.id = tonumber(val)
        if item.id == nil then
            for mountDisplayIndex = 1, C_MountJournal.GetNumDisplayedMounts() do
                local name, spellID, icon, isActive, isUsable, sourceType,
                isFavorite, isFactionSpecific, faction, shouldHideOnChar,
                isCollected, mountID, isSteadyFlight =
                    C_MountJournal.GetDisplayedMountInfo(mountDisplayIndex)
                if name == val then
                    item.id = mountID
                    item.name = name
                    item.icon = icon
                    break
                end
            end
        end
        if item.id == nil then
            return R:Err(L["Unable to get the id, please check the input."])
        end
        if item.icon == nil then
            local name, spellID, icon, active, isUsable, sourceType, isFavorite,
            isFactionSpecific, faction, shouldHideOnChar, isCollected,
            mountID = C_MountJournal.GetMountInfoByID(item.id)
            if name then
                item.id = mountID
                item.name = name
                item.icon = icon
            else
                return R:Err("Can not get the name, please check your input.")
            end
        end
    elseif item.type == const.ITEM_TYPE.PET then
        item.id = tonumber(val)
        if item.id == nil then
            local speciesId, petGUID = C_PetJournal.FindPetIDByName(val)
            if speciesId then item.id = speciesId end
        end
        if item.id == nil then
            return R:Err(L["Unable to get the id, please check the input."])
        end
        local speciesName, speciesIcon, petType, companionID, tooltipSource,
        tooltipDescription, isWild, canBattle, isTradeable, isUnique,
        obtainable, creatureDisplayID =
            C_PetJournal.GetPetInfoBySpeciesID(item.id)
        if speciesName then
            item.name = speciesName
            item.icon = speciesIcon
        else
            return R:Err(L["Unable to get the name, please check the input."])
        end
    else
        return R:Err("Wrong type, please check your input.")
    end
    return R:Ok(item)
end

--[[
对单个物品进行本地化处理
]]
---@param item ItemConfig
function Config.UpdateItemLocalizeName(item)
    if item == nil or item.extraAttr == nil or item.extraAttr.id == nil or
        item.extraAttr.type == nil then
        return
    end
    if item.extraAttr.type == const.ITEM_TYPE.ITEM or item.extraAttr.type ==
        const.ITEM_TYPE.EQUIPMENT or item.extraAttr.type == const.ITEM_TYPE.TOY then
        local itemName = C_Item.GetItemNameByID(item.extraAttr.id)
        if itemName then
            item.extraAttr.name = itemName
        else
            local syncItem = Item:CreateFromItemID(item.extraAttr.id)
            syncItem:ContinueOnItemLoad(function()
                local syncName = syncItem:GetItemName()
                if syncName then
                    item.extraAttr.name = syncItem:GetItemName()
                end
            end)
        end
    elseif item.extraAttr.type == const.ITEM_TYPE.SPELL then
        local spellInfo = Api.GetSpellInfo(item.extraAttr.id)
        if spellInfo then
            item.extraAttr.name = spellInfo.name
        else
            local syncSpell = Spell:CreateFromSpellID(item.extraAttr.id)
            syncSpell:ContinueOnSpellLoad(function()
                local syncName = syncSpell:GetSpellName()
                if syncName then item.extraAttr.name = syncName end
            end)
        end
    elseif item.extraAttr.type == const.ITEM_TYPE.MOUNT then
        local name, spellID, icon, active, isUsable, sourceType, isFavorite,
        isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID =
            C_MountJournal.GetMountInfoByID(item.extraAttr.id)
        if name then item.extraAttr.name = name end
    elseif item.extraAttr.type == const.ITEM_TYPE.PET then
        local speciesName, speciesIcon, petType, companionID, tooltipSource,
        tooltipDescription, isWild, canBattle, isTradeable, isUnique,
        obtainable, creatureDisplayID =
            C_PetJournal.GetPetInfoBySpeciesID(item.extraAttr.id)
        if speciesName then item.extraAttr.name = speciesName end
    else
    end
end

---------------------------------------------------------
-- 对配置文件进行处理：
-- 1. 本地化处理
-- 2. 按键处理：如果不导入配置则移除配置中的按键设置
---------------------------------------------------------
---@param ele ElementConfig
function Config.HandleConfig(ele)
    if addon.G.tmpImportKeybind == false and ele.bindKey ~= nil then
        ele.bindKey = nil
    end
    if ele.type == const.ELEMENT_TYPE.ITEM then
        local item = E:ToItem(ele)
        Config.UpdateItemLocalizeName(item)
    end
    if ele.elements then
        for _, childEle in ipairs(ele.elements) do
            Config.HandleConfig(childEle)
        end
    end
end

-- 展示导出配置框
---@param exportData string
function Config.ShowExportDialog(exportData)
    local dialog = AceGUI:Create("Window")
    dialog:SetTitle(L["Please copy the configuration to the clipboard."])
    dialog:SetWidth(500)
    dialog:SetHeight(300)
    dialog:SetLayout("Fill")
    ---@diagnostic disable-next-line: invisible
    local dialogFrame = dialog["frame"]
    if dialogFrame then
        dialogFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        dialogFrame:SetFrameLevel(100)
        dialogFrame:Raise()
    end

    local editBox = AceGUI:Create("MultiLineEditBox")
    editBox:SetLabel("")
    editBox:DisableButton(true)
    editBox:SetFullWidth(true)
    editBox:SetFullHeight(true)
    editBox:SetText(exportData)
    editBox:SetCallback("OnEnterPressed",
        function(widget) widget:ClearFocus() end)
    dialog:AddChild(editBox)
end

---@param errorText string
---@param targetSelectGroups string[] | nil
function Config.ShowErrorDialog(errorText, targetSelectGroups)
    local message = tostring(errorText or "")

    if addon.G.hbCenterErrorFrame == nil then
        local frame = CreateFrame("Frame", nil, UIParent)
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        frame:SetSize(640, 40)
        frame:SetFrameStrata("TOOLTIP")
        frame:SetFrameLevel(1000)

        local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        text:SetPoint("CENTER", frame, "CENTER", 0, 0)
        text:SetWidth(620)
        text:SetJustifyH("CENTER")
        text:SetJustifyV("MIDDLE")

        frame.msgText = text
        frame:Hide()
        addon.G.hbCenterErrorFrame = frame
    end

    local frame = addon.G.hbCenterErrorFrame
    if frame and frame.msgText then
        addon.G.hbCenterErrorToken = (addon.G.hbCenterErrorToken or 0) + 1
        local token = addon.G.hbCenterErrorToken
        frame.msgText:SetText("|cffff3030" .. message .. "|r")
        frame:Show()
        frame:Raise()
        C_Timer.After(2.5, function()
            if addon.G.hbCenterErrorToken == token and frame:IsShown() then
                frame:Hide()
            end
        end)
    else
        U.Print.PrintErrorText(message)
    end

    if targetSelectGroups ~= nil and type(targetSelectGroups) == "table" then
        local restoreGroups = U.Table.DeepCopyList(targetSelectGroups)
        C_Timer.After(0, function()
            AceConfigDialog:SelectGroup(addonName, unpack(restoreGroups))
        end)
        -- AceConfig 在部分输入交互后会二次刷新状态，这里再补一次恢复。
        C_Timer.After(0.05, function()
            AceConfigDialog:SelectGroup(addonName, unpack(restoreGroups))
        end)
    end
end

-- 通知 AceConfig 配置已改变，刷新 UI 显示
local function NotifyOptionsChanged()
    if AceConfigRegistry and AceConfigRegistry.NotifyChange then
        AceConfigRegistry:NotifyChange(addonName)
    end
end

-- 异步校验物品属性
-- 对于物品/装备/玩具在 0.2 秒间隔内最多重试 8 次（API 延迟加载）
-- 其他类型只重试 1 次
---@param itemType ElementType 物品类型
---@param val string 用户输入的物品ID或名称
---@param onDone fun(ok:boolean, item:ItemAttr|nil, err:string|nil) 异步完成回调 ok=true表示成功，item为物品信息；ok=false时err为错误信息
local function AsyncVerifyCreateItemAttr(itemType, val, onDone)
    local attempts = 0
    local maxAttempts = 1
    if itemType == const.ITEM_TYPE.ITEM or itemType == const.ITEM_TYPE.EQUIPMENT or itemType == const.ITEM_TYPE.TOY then
        maxAttempts = 8
    end

    local function doVerify()
        attempts = attempts + 1
        local r = Config.VerifyItemAttr(itemType, val)
        if r:is_ok() then
            onDone(true, r:unwrap(), nil)
            return
        end

        if attempts >= maxAttempts then
            onDone(false, nil, L["Invalid item input, please check and re-enter."])
            return
        end

        C_Timer.After(0.2, doVerify)
    end

    doVerify()
end

---@param item ItemConfig
---@return table
local function GetEditItemState(item)
    if addon.G.tmpEditItemStates == nil then
        addon.G.tmpEditItemStates = setmetatable({}, { __mode = "k" })
    end
    local state = addon.G.tmpEditItemStates[item]
    if state == nil then
        local view = BuildItemDisplayView(item.extraAttr)
        state = {
            itemType = item.extraAttr and item.extraAttr.type or const.ITEM_TYPE.ITEM,
            itemVal = view.text,
            displayText = view.text,
            verified = true,
            verifyPending = false,
            verifyToken = 0,
            verifyError = nil,
            item = item.extraAttr and U.Table.DeepCopyDict(item.extraAttr) or nil,
        }
        addon.G.tmpEditItemStates[item] = state
    end
    return state
end

---@param item ItemConfig
local function ResetEditItemState(item)
    if addon.G.tmpEditItemStates ~= nil then
        addon.G.tmpEditItemStates[item] = nil
    end
end

-- 检查标题是否重复的函数
---@param title string
---@param eleList ElementConfig[]
---@return boolean
function Config.IsTitleDuplicated(title, eleList)
    -- 判断标题是否重复
    for _, ele in pairs(eleList) do
        if ele.title == title then return true end
    end
    return false
end

-- 检查ID是否重复
---@param eleId string
---@param eleList ElementConfig[]
---@return boolean
function Config.IsIdDuplicated(eleId, eleList)
    for _, ele in pairs(eleList) do if ele.id == eleId then return true end end
    return false
end

-- 创建副本标题的函数
---@param title string
---@param eleList ElementConfig[]
---@return string
function Config.CreateDuplicateTitle(title, eleList)
    local count = 1
    local newTitle = title .. " [" .. count .. "]"
    -- 检查新标题是否也重复，如果是则继续递增
    while Config.IsTitleDuplicated(newTitle, eleList) do
        count = count + 1
        newTitle = title .. " [" .. count .. "]"
    end
    return newTitle
end

function Config.GetNewElementTitle(title, elements)
    if Config.IsTitleDuplicated(title, elements) then
        title = Config.CreateDuplicateTitle(title, elements)
    end
    return title
end

---@param eleType ElementType | nil
---@return boolean
function Config.IsBarChildType(eleType)
    return eleType == const.ELEMENT_TYPE.ITEM
        or eleType == const.ELEMENT_TYPE.ITEM_GROUP
        or eleType == const.ELEMENT_TYPE.SCRIPT
        or eleType == const.ELEMENT_TYPE.MACRO
end

---@param legacyElements ElementConfig[] | nil
---@param outChildren ElementConfig[]
local function CollectBarChildrenFromLegacy(legacyElements, outChildren)
    if legacyElements == nil then
        return
    end
    for _, child in ipairs(legacyElements) do
        if child.type == const.ELEMENT_TYPE.BAR then
            CollectBarChildrenFromLegacy(child.elements, outChildren)
        elseif Config.IsBarChildType(child.type) then
            addon:compatibilizeConfig(child)
            table.insert(outChildren, child)
        end
    end
end

---@param eleConfig ElementConfig
---@param currentRootElements ElementConfig[]
---@return BarConfig
function Config.NormalizeAsRootBar(eleConfig, currentRootElements)
    addon:compatibilizeConfig(eleConfig)
    if eleConfig.type ~= const.ELEMENT_TYPE.BAR then
        local child = eleConfig
        local bar = E:ToBar(E:New(Config.GetNewElementTitle(L["Bar"], currentRootElements), const.ELEMENT_TYPE.BAR))
        if Config.IsBarChildType(child.type) then
            table.insert(bar.elements, child)
        end
        return bar
    end

    local bar = E:ToBar(eleConfig)
    local normalizedChildren = {}
    CollectBarChildrenFromLegacy(bar.elements, normalizedChildren)
    bar.elements = normalizedChildren
    return bar
end

function Config.NormalizeProfileElements()
    local normalized = {}
    if addon.db == nil or addon.db.profile == nil or addon.db.profile.elements == nil then
        return
    end
    for _, ele in ipairs(addon.db.profile.elements) do
        local bar = Config.NormalizeAsRootBar(ele, normalized)
        if Config.IsTitleDuplicated(bar.title, normalized) then
            bar.title = Config.CreateDuplicateTitle(bar.title, normalized)
        end
        table.insert(normalized, bar)
    end
    addon.db.profile.elements = normalized
end

---@class ConfigOptions
---@field ElementsOptions function
---@field ConfigOptions function
---@field Options function
local ConfigOptions = {}

---@param elements ElementConfig[]
---@param topEleConfig ElementConfig | nil 顶层的菜单，当为nil的时候，表示当前elements参数本身是顶层菜单
---@param selectGroups table  配置界面选项卡位置
local function GetElementOptions(elements, topEleConfig, selectGroups)
    local function GetMaxArgOrder(groupArgs)
        local maxOrder = 0
        if groupArgs == nil then
            return maxOrder
        end
        for _, groupArg in pairs(groupArgs) do
            if type(groupArg) == "table" and type(groupArg.order) == "number" and groupArg.order > maxOrder then
                maxOrder = groupArg.order
            end
        end
        return maxOrder
    end

    local settingOrder = 1
    local isRoot = topEleConfig == nil
    local eleArgs = {}
    for i, ele in ipairs(elements) do
        -- 兼容性处理
        if not ele.loadCond then
            ele.loadCond = {
                LoadCond = true
            }
        end
        -- 判断需要触发哪个菜单的更新事件
        local updateFrameConfig
        if topEleConfig ~= nil then
            updateFrameConfig = topEleConfig
        else
            updateFrameConfig = ele
        end
        local copySelectGroups = U.Table.DeepCopyList(selectGroups)
        table.insert(copySelectGroups, "elementMenu" .. i)
        local selectGroupsAfterAddItem = U.Table.DeepCopyList(copySelectGroups)
        table.insert(selectGroupsAfterAddItem,
            "elementMenu" .. (#ele.elements + 1))
        local selectGroupsAfterAddItemInBar = U.Table.DeepCopyList(copySelectGroups)
        table.insert(selectGroupsAfterAddItemInBar, "barElementList")
        table.insert(selectGroupsAfterAddItemInBar,
            "elementMenu" .. (#ele.elements + 1))
        local showTitle = ele.title
        local showIcon = ele.icon or 134400
        if ele.type == const.ELEMENT_TYPE.ITEM then
            local item = E:ToItem(ele)
            if item.extraAttr.name then
                showTitle = item.extraAttr.name .. GetCraftingQualityMarkup(item.extraAttr.id)
            end
            if item.extraAttr.icon then
                showIcon = item.extraAttr.icon
            end
        end
        local iconPath = ""
        if ele.type ~= const.ELEMENT_TYPE.BAR then
            iconPath = "|T" .. showIcon .. ":16|t"
        end

        local args = {}
        --------------------------
        -- 元素设置
        --------------------------
        local elementSettingOrder = 1
        local elementSettingArgs = {}
        local elementSettingOptions = {
            type = "group",
            name = L["Element Settings"],
            order = settingOrder,
            args = elementSettingArgs
        }
        settingOrder = settingOrder + 1
        args.elementSetting = elementSettingOptions
        if ele.type ~= const.ELEMENT_TYPE.ITEM then
            elementSettingArgs.title = {
                order = elementSettingOrder,
                width = ele.type == const.ELEMENT_TYPE.BAR and "full" or 1,
                type = 'input',
                name = L['Title'],
                validate = function(_, val)
                    for _i, _ele in ipairs(elements) do
                        if _ele.title == val and i ~= _i then
                            return "repeat title, please input another one."
                        end
                    end
                    return true
                end,
                get = function() return ele.title end,
                set = function(_, val)
                    if val == "" or val == " " then
                        val = nil
                    end
                    ele.title = val
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                    addon:UpdateOptions()
                end
            }
            elementSettingOrder = elementSettingOrder + 1
            if ele.type ~= const.ELEMENT_TYPE.BAR then
                elementSettingArgs.icon = {
                    order = elementSettingOrder,
                    width = 1,
                    type = 'input',
                    name = L["Element Icon ID or Path"],
                    get = function() return ele.icon end,
                    set = function(_, val)
                        if val == "" or val == " " then
                            val = nil
                        end
                        ele.icon = val
                        HbFrame:ReloadEframeUI(updateFrameConfig)
                        addon:UpdateOptions()
                    end
                }
                elementSettingOrder = elementSettingOrder + 1
            end
        end
        if isRoot then
            elementSettingArgs.space1 = {
                type = "description",
                order = elementSettingOrder,
                width = "full",
                name = "",
            }
            elementSettingOrder = elementSettingOrder + 1
            elementSettingArgs.iconWidth = {
                step = 1,
                order = elementSettingOrder,
                width = 1,
                type = 'range',
                name = L["Icon Width"],
                min = 24,
                max = 128,
                get = function(_)
                    return ele.iconWidth or addon.G.iconWidth
                end,
                set = function(_, value)
                    ele.iconWidth = value
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                end
            }
            elementSettingOrder = elementSettingOrder + 1
            elementSettingArgs.iconHeight = {
                step = 1,
                order = elementSettingOrder,
                width = 1,
                type = 'range',
                name = L["Icon Height"],
                min = 24,
                max = 128,
                get = function(_)
                    return ele.iconHeight or addon.G.iconHeight
                end,
                set = function(_, value)
                    ele.iconHeight = value
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                end
            }
            elementSettingOrder = elementSettingOrder + 1
        end
        if ele.type == const.ELEMENT_TYPE.ITEM then
            local item = E:ToItem(ele)
            local extraAttr = item.extraAttr
            if extraAttr.id == nil then
                elementSettingArgs.itemType = {
                    order = elementSettingOrder,
                    type = 'select',
                    name = L["Item Type"],
                    values = const.ItemTypeOptions,
                    set = function(_, val)
                        addon.G.tmpNewItemType = val
                    end,
                    get = function()
                        return addon.G.tmpNewItemType
                    end
                }
                elementSettingOrder = elementSettingOrder + 1
                elementSettingArgs.itemVal = {
                    order = elementSettingOrder,
                    type = 'input',
                    name = L["Item name or item id"],
                    validate = function()
                        return true
                    end,
                    set = function(_, val)
                        addon.G.tmpNewItemVal = val
                        local r = Config.VerifyItemAttr(addon.G.tmpNewItemType, val)
                        if r:is_err() then
                            Config.ShowErrorDialog(r:unwrap_err(), selectGroups)
                            return
                        end
                        addon.G.tmpNewItem = r:unwrap()
                        item.extraAttr = U.Table.DeepCopyDict(addon.G.tmpNewItem)
                        HbFrame:ReloadEframeUI(updateFrameConfig)
                        addon.G.tmpNewItemVal = nil
                        addon.G.tmpNewItem = {}
                    end,
                    get = function()
                        return addon.G.tmpNewItemVal
                    end
                }
                elementSettingOrder = elementSettingOrder + 1
            end
        end
        if ele.type == const.ELEMENT_TYPE.SCRIPT then
            local script = E:ToScript(ele)
            elementSettingArgs.edit = {
                order = elementSettingOrder,
                type = 'input',
                name = L["Script"],
                multiline = 10,
                width = "full",
                validate = function(_, val)
                    local func, loadstringErr = loadstring(val)
                    if not func then
                        local errMsg = L["Illegal script."] .. " " ..
                            loadstringErr
                        U.Print.PrintErrorText(errMsg)
                        return errMsg
                    end
                    local status, pcallErr = pcall(func())
                    if not status then
                        local errMsg = L["Illegal script."] .. " " ..
                            tostring(pcallErr)
                        U.Print.PrintErrorText(errMsg)
                        return errMsg
                    end
                    return true
                end,
                set = function(_, val)
                    script.extraAttr.script = val
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                    addon:UpdateOptions()
                end,
                get = function() return script.extraAttr.script end
            }
            elementSettingOrder = elementSettingOrder + 1
        end
        if ele.type == const.ELEMENT_TYPE.ITEM_GROUP then
            local itemGroup = E:ToItemGroup(ele)
            elementSettingArgs.mode = {
                order = elementSettingOrder,
                width = 2,
                type = 'select',
                name = L["Mode"],
                values = const.ItemsGroupModeOptions,
                set = function(_, val)
                    itemGroup.extraAttr.mode = val
                    HbFrame:UpdateEframe(updateFrameConfig)
                end,
                get = function() return itemGroup.extraAttr.mode end
            }
            elementSettingOrder = elementSettingOrder + 1
            -- 物品组查看/编辑/删除物品
            elementSettingArgs.itemType = {
                order = elementSettingOrder,
                type = 'select',
                name = L["Item Type"],
                values = const.ItemTypeOptions,
                set = function(_, val)
                    addon.G.tmpNewItemType = val
                end,
                get = function() return addon.G.tmpNewItemType end
            }
            elementSettingOrder = elementSettingOrder + 1
            elementSettingArgs.itemVal = {
                order = elementSettingOrder,
                type = 'input',
                name = L["Item name or item id"],
                validate = function()
                    return true
                end,
                set = function(_, val)
                    addon.G.tmpNewItemVal = val
                    local r = Config.VerifyItemAttr(addon.G.tmpNewItemType, val)
                    if r:is_err() then
                        Config.ShowErrorDialog(r:unwrap_err(), selectGroups)
                        return
                    end
                    addon.G.tmpNewItem = r:unwrap()
                    local newElement = E:New(
                        Config.GetNewElementTitle(L["Item"],
                            ele.elements),
                        const.ELEMENT_TYPE.ITEM)
                    local item = E:ToItem(newElement)
                    item.extraAttr = U.Table.DeepCopyDict(addon.G.tmpNewItem)
                    table.insert(ele.elements, item)
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                    itemGroup.extraAttr.configSelectedItemIndex = #itemGroup.elements
                    addon.G.tmpNewItemVal = nil
                    addon.G.tmpNewItem = {}
                end,
                get = function() return addon.G.tmpNewItemVal end
            }
            elementSettingOrder = elementSettingOrder + 1
            local itemsOptions = {} ---@type table<number, ItemConfig>
            if ele.elements then
                for _, _item in ipairs(ele.elements) do
                    local item = E:ToItem(_item)
                    table.insert(itemsOptions, BuildItemDisplayView(item.extraAttr).text)
                end
            end
            elementSettingArgs.selectChildren = {
                order = elementSettingOrder,
                width = 1,
                type = "select",
                name = L["Select Item"],
                values = itemsOptions,
                set = function(_, val)
                    itemGroup.extraAttr.configSelectedItemIndex = val
                end,
                get = function() return itemGroup.extraAttr.configSelectedItemIndex end
            }
            elementSettingOrder = elementSettingOrder + 1
            elementSettingArgs.deleteChildren = {
                order = elementSettingOrder,
                width = 1,
                type = "execute",
                name = L["Delete"],
                confirm = true,
                func = function()
                    table.remove(itemGroup.elements, itemGroup.extraAttr.configSelectedItemIndex)
                    if itemGroup.extraAttr.configSelectedItemIndex > #itemGroup.elements then
                        itemGroup.extraAttr.configSelectedItemIndex = #itemGroup.elements
                    end
                end
            }
            elementSettingArgs.moveUp = {
                order = elementSettingOrder,
                width = 1,
                type = 'execute',
                name = L["Move Up"],
                disabled = function ()
                    return itemGroup.extraAttr.configSelectedItemIndex <= 1
                end,
                func = function()
                    if itemGroup.extraAttr.configSelectedItemIndex > 1 then
                        itemGroup.elements[itemGroup.extraAttr.configSelectedItemIndex], itemGroup.elements[itemGroup.extraAttr.configSelectedItemIndex - 1] = itemGroup.elements[itemGroup.extraAttr.configSelectedItemIndex - 1], itemGroup.elements[itemGroup.extraAttr.configSelectedItemIndex]
                        itemGroup.extraAttr.configSelectedItemIndex = itemGroup.extraAttr.configSelectedItemIndex - 1
                    end
                end
            }
            elementSettingOrder = elementSettingOrder + 1
            elementSettingArgs.moveDown = {
                order = elementSettingOrder,
                width = 1,
                type = 'execute',
                name = L["Move Down"],
                disabled = function ()
                    return itemGroup.extraAttr.configSelectedItemIndex >= #itemGroup.elements
                end,
                func = function()
                    if i < #itemGroup.elements then
                        itemGroup.elements[itemGroup.extraAttr.configSelectedItemIndex], itemGroup.elements[itemGroup.extraAttr.configSelectedItemIndex + 1] = itemGroup.elements[itemGroup.extraAttr.configSelectedItemIndex + 1], itemGroup.elements[itemGroup.extraAttr.configSelectedItemIndex]
                        itemGroup.extraAttr.configSelectedItemIndex = itemGroup.extraAttr.configSelectedItemIndex + 1
                    end
                end
            }
            elementSettingOrder = elementSettingOrder + 1
        end
        -----------------------------------------
        --- 宏条件设置
        -----------------------------------------
        if ele.type == const.ELEMENT_TYPE.MACRO then
            local macro = E:ToMacro(ele)
            elementSettingArgs.edit = {
                order = elementSettingOrder,
                type = 'input',
                name = L["Macro"],
                multiline = 10,
                width = "full",
                validate = function(_, val)
                    local macroAstR = Macro:Ast(val)
                    if macroAstR:is_err() then
                        return macroAstR:unwrap_err()
                    else
                        addon.G.tmpMacroAst = macroAstR:unwrap()
                        return true
                    end
                end,
                set = function(_, val)
                    macro.extraAttr.macro = val
                    macro.extraAttr.ast = U.Table.DeepCopy(addon.G.tmpMacroAst)
                    local events = Macro:GetEventsFromAst(macro.extraAttr.ast)
                    macro.listenEvents = events
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                    addon:UpdateOptions()
                end,
                get = function() return macro.extraAttr.macro end
            }
            elementSettingOrder = elementSettingOrder + 1
        end
        if isRoot then
            -- 位置设置，以分隔符形式展示
            elementSettingArgs.positionSeparator = {
                order = elementSettingOrder,
                type = "header",
                width = 2,
                name = L["Position"],
            }
            elementSettingOrder = elementSettingOrder + 1
            elementSettingArgs.positionSpaceBefore = {
                order = elementSettingOrder,
                type = "description",
                width = "full",
                name = "",
            }
            elementSettingOrder = elementSettingOrder + 1
            elementSettingArgs.attachFrame = {
                order = elementSettingOrder,
                type = 'input',
                name = L["AttachFrame"],
                set = function(_, val)
                    ele.attachFrame = val
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                end,
                get = function()
                    return ele.attachFrame
                end
            }
            elementSettingOrder = elementSettingOrder + 1
            elementSettingArgs.attachFrameOptions = {
                order = elementSettingOrder,
                type = 'select',
                name = "",
                width = 1,
                values = const.AttachFrameOptions,
                set = function(_, val)
                    ele.attachFrame = val
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                end,
                get = function()
                    return ele.attachFrame
                end
            }
            elementSettingOrder = elementSettingOrder + 1
            elementSettingArgs.space1 = {
                order = elementSettingOrder,
                type = "description",
                width = "full",
                name = ""
            }
            elementSettingOrder = elementSettingOrder + 1
            elementSettingArgs.AnchorPos = {
                order = elementSettingOrder,
                type = 'select',
                name = L["Element Anchor Position"],
                width = 1,
                values = const.AnchorPosOptions,
                set = function(_, val)
                    ele.anchorPos = val
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                end,
                get = function()
                    return ele.anchorPos
                end
            }
            elementSettingOrder = elementSettingOrder + 1
            elementSettingArgs.attachFrameAnchorPos = {
                order = elementSettingOrder,
                type = 'select',
                name = L["AttachFrame Anchor Position"],
                width = 1,
                values = const.AnchorPosOptions,
                set = function(_, val)
                    ele.attachFrameAnchorPos = val
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                end,
                get = function()
                    return ele.attachFrameAnchorPos
                end
            }
            elementSettingOrder = elementSettingOrder + 1
            elementSettingArgs.space2 = {
                order = elementSettingOrder,
                type = "description",
                width = "full",
                name = ""
            }
            elementSettingOrder = elementSettingOrder + 1
            elementSettingArgs.posX = {
                order = elementSettingOrder,
                type = "range",
                name = L["Relative X-Offset"],
                width = 1,
                min = -addon.G.screenWidth,
                max = addon.G.screenWidth,
                step = 1,
                get = function(_)
                    return ele.posX
                end,
                set = function(_, val)
                    ele.posX = val
                    HbFrame:UpdateEframeWindow(updateFrameConfig)
                end,
            }
            elementSettingOrder = elementSettingOrder + 1
            elementSettingArgs.posY = {
                order = elementSettingOrder,
                type = "range",
                name = L["Relative Y-Offset"],
                width = 1,
                min = -addon.G.screenHeight,
                max = addon.G.screenHeight,
                step = 1,
                get = function(_)
                    return ele.posY
                end,
                set = function(_, val)
                    ele.posY = val
                    HbFrame:UpdateEframeWindow(updateFrameConfig)
                end,
            }
            elementSettingOrder = elementSettingOrder + 1
            elementSettingArgs.positionSpaceAfter = {
                order = elementSettingOrder,
                type = "description",
                width = "full",
                name = "",
            }
            elementSettingOrder = elementSettingOrder + 1

            -- 操作分隔符和操作按钮
            elementSettingArgs.actionSpaceBefore = {
                order = elementSettingOrder,
                type = "description",
                width = "full",
                name = "",
            }
            elementSettingOrder = elementSettingOrder + 1
            elementSettingArgs.actionsSeparator = {
                order = elementSettingOrder,
                type = "header",
                width = 2,
                name = L["Actions"],
            }
            elementSettingOrder = elementSettingOrder + 1
            elementSettingArgs.delete = {
                order = elementSettingOrder,
                width = 1,
                type = 'execute',
                name = L["Delete"],
                confirm = true,
                func = function()
                    table.remove(elements, i)
                    if topEleConfig == nil then
                        HbFrame:DeleteEframe(ele)
                    else
                        HbFrame:ReloadEframeUI(topEleConfig)
                    end
                    AceConfigDialog:SelectGroup(addonName, unpack(selectGroups))
                end
            }
            elementSettingOrder = elementSettingOrder + 1
            elementSettingArgs.export = {
                order = elementSettingOrder,
                width = 1,
                type = 'execute',
                name = L['Export'],
                func = function()
                    local serializedData = AceSerializer:Serialize(ele)
                    local compressedData =
                        LibDeflate:CompressDeflate(serializedData)
                    local base64Encoded = LibDeflate:EncodeForPrint(compressedData)
                    Config.ShowExportDialog(base64Encoded)
                end
            }
            elementSettingOrder = elementSettingOrder + 1
            elementSettingArgs.actionSpaceAfter = {
                order = elementSettingOrder,
                type = "description",
                width = "full",
                name = "",
            }
        end
        -------------------
        -- 基本设置
        ------------------
        local baseSettingOrder = 1
        local baseSettingArgs = {}
        local baseSettingOptions = {
            type = "group",
            name = L["Settings"],
            order = settingOrder,
            args = baseSettingArgs
        }
        settingOrder = settingOrder + 1
        args.baseSetting = baseSettingOptions
        if ele.type == const.ELEMENT_TYPE.ITEM and not isRoot then
            local item = E:ToItem(ele)
            local extraAttr = item.extraAttr
            baseSettingArgs.itemType = {
                order = baseSettingOrder,
                width = 1,
                type = 'select',
                name = L["Item Type"],
                values = const.ItemTypeOptions,
                set = function(_, val)
                    local state = GetEditItemState(item)
                    state.itemType = val
                    state.itemVal = nil
                    state.displayText = nil
                    state.verified = false
                    state.verifyPending = false
                    state.verifyError = nil
                    state.item = nil
                    state.verifyToken = state.verifyToken + 1
                    NotifyOptionsChanged()
                end,
                get = function()
                    return GetEditItemState(item).itemType or extraAttr.type or const.ITEM_TYPE.ITEM
                end
            }
            baseSettingOrder = baseSettingOrder + 1
            baseSettingArgs.itemVal = {
                order = baseSettingOrder,
                width = 1,
                type = 'input',
                name = L["Item name or item id"],
                validate = function()
                    return true
                end,
                set = function(_, val)
                    local state = GetEditItemState(item)
                    if state.displayText ~= nil and val == state.displayText then
                        return
                    end
                    state.itemVal = val
                    state.verified = false
                    state.verifyPending = false
                    state.verifyError = nil
                    state.item = nil
                    state.verifyToken = state.verifyToken + 1

                    if val == nil or val == "" or val == " " then
                        NotifyOptionsChanged()
                        return
                    end

                    state.verifyPending = true
                    state.verifyToken = state.verifyToken + 1
                    local verifyToken = state.verifyToken
                    local itemType = state.itemType or extraAttr.type or const.ITEM_TYPE.ITEM
                    NotifyOptionsChanged()

                    AsyncVerifyCreateItemAttr(itemType, val, function(ok, verifiedItem, err)
                        local latestState = GetEditItemState(item)
                        if latestState.verifyToken ~= verifyToken then
                            return
                        end

                        latestState.verifyPending = false
                        if ok then
                            if verifiedItem == nil then
                                latestState.verified = false
                                latestState.item = nil
                                latestState.verifyError = L["Invalid item input, please check and re-enter."]
                                Config.ShowErrorDialog(latestState.verifyError, copySelectGroups)
                                NotifyOptionsChanged()
                                return
                            end
                            item.extraAttr = U.Table.DeepCopyDict(verifiedItem)
                            item.icon = verifiedItem.icon
                            latestState.verified = true
                            latestState.item = verifiedItem
                            latestState.verifyError = nil
                            local view = BuildItemDisplayView(verifiedItem)
                            latestState.displayText = view.text
                            latestState.itemVal = view.text
                            HbFrame:ReloadEframeUI(updateFrameConfig)
                        else
                            latestState.verified = false
                            latestState.item = nil
                            latestState.verifyError = err
                            Config.ShowErrorDialog(err or L["Unable to get the id, please check the input."], copySelectGroups)
                        end
                        NotifyOptionsChanged()
                    end)
                end,
                get = function()
                    return GetEditItemState(item).itemVal
                end
            }
            baseSettingOrder = baseSettingOrder + 1
        end
        if ele.type ~= const.ELEMENT_TYPE.BAR or isRoot then
            local needActionVisualSeparator = (not isRoot)
                and (ele.type == const.ELEMENT_TYPE.ITEM
                    or ele.type == const.ELEMENT_TYPE.ITEM_GROUP
                    or ele.type == const.ELEMENT_TYPE.SCRIPT
                    or ele.type == const.ELEMENT_TYPE.MACRO)
            if needActionVisualSeparator then
                baseSettingArgs.actionsSeparator = {
                    order = baseSettingOrder,
                    type = "header",
                    width = 2,
                    name = L["Actions"],
                }
                baseSettingOrder = baseSettingOrder + 1
            end

            local actionGroupOrder = baseSettingOrder
            local actionGroupArgs = {}
            baseSettingArgs.actions = {
                order = actionGroupOrder,
                type = "group",
                name = needActionVisualSeparator and "" or L["Actions"],
                inline = true,
                args = actionGroupArgs,
            }
            baseSettingOrder = baseSettingOrder + 1

            local actionOrder = 1
            actionGroupArgs.moveUp = {
                order = actionOrder,
                width = 2/3,
                type = 'execute',
                name = L["Move Up"],
                disabled = function ()
                    return i <= 1
                end,
                func = function()
                    if i > 1 then
                        elements[i], elements[i - 1] = elements[i - 1], elements[i]
                    end
                    local moveUpSelectGroups = U.Table.DeepCopyList(selectGroups)
                    table.insert(moveUpSelectGroups, "elementMenu" .. i - 1)
                    AceConfigDialog:SelectGroup(addonName, unpack(moveUpSelectGroups))
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                end
            }
            actionOrder = actionOrder + 1
            actionGroupArgs.moveDown = {
                order = actionOrder,
                width = 2/3,
                type = 'execute',
                name = L["Move Down"],
                disabled = function ()
                    return i >= #elements
                end,
                func = function()
                    if i < #elements then
                        elements[i], elements[i + 1] = elements[i + 1], elements[i]
                    end
                    local moveDownSelectGroups = U.Table.DeepCopyList(selectGroups)
                    table.insert(moveDownSelectGroups, "elementMenu" .. i + 1)
                    AceConfigDialog:SelectGroup(addonName, unpack(moveDownSelectGroups))
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                end
            }
            actionOrder = actionOrder + 1
            if (not isRoot) and ele.type == const.ELEMENT_TYPE.ITEM then
                actionGroupArgs.copy = {
                    order = actionOrder,
                    width = 2/3,
                    type = 'execute',
                    name = L["Copy"],
                    func = function()
                        local copiedItem = U.Table.DeepCopy(ele)
                        copiedItem.title = Config.GetNewElementTitle(ele.title or L["Item"], elements)
                        table.insert(elements, i + 1, copiedItem)
                        local copySelectGroups = U.Table.DeepCopyList(selectGroups)
                        table.insert(copySelectGroups, "elementMenu" .. i + 1)
                        AceConfigDialog:SelectGroup(addonName, unpack(copySelectGroups))
                        if topEleConfig == nil then
                            HbFrame:ReloadEframeUI(updateFrameConfig)
                        else
                            HbFrame:ReloadEframeUI(topEleConfig)
                        end
                    end
                }
                actionOrder = actionOrder + 1
            end
            if not isRoot then
                actionGroupArgs.delete = {
                    order = actionOrder,
                    width = 2/3,
                    type = 'execute',
                    name = L["Delete"],
                    confirm = true,
                    func = function()
                        if ele.type == const.ELEMENT_TYPE.ITEM then
                            ResetEditItemState(E:ToItem(ele))
                        end
                        table.remove(elements, i)
                        if topEleConfig == nil then
                            HbFrame:DeleteEframe(ele)
                        else
                            HbFrame:ReloadEframeUI(topEleConfig)
                        end
                        AceConfigDialog:SelectGroup(addonName, unpack(selectGroups))
                    end
                }
            end
        end
        if isRoot then
            -- 操作按钮已移至位置设置分组最下方
        end

        ---------------------------------------------------------
        -- 按键绑定设置
        ---------------------------------------------------------
        if E:IsSingleIconConfig(ele) then
            local bindkeySettingOrder = 1
            local bindkeySettingArgs = {}
            local bindkeySettingOptions = {
                type = "group",
                name = L["Bindkey Settings"],
                order = settingOrder,
                args = bindkeySettingArgs
            }
            settingOrder = settingOrder + 1
            args.bindkeySetting = bindkeySettingOptions
            bindkeySettingArgs.bindKey = {
                order = bindkeySettingOrder,
                type = "keybinding",
                name = L["Bindkey"],
                width = 1,
                get = function()
                    if ele.bindKey == nil then
                        return nil
                    end
                    return ele.bindKey.key
                end,
                set = function(_, key)
                    if key == nil or key == "" then
                        ele.bindKey = nil
                    else
                        if ele.bindKey == nil then
                            ele.bindKey = {key = key, characters = {}, classes = {}}  -- 默认选择不给任何角色绑定，防止误操作导致绑定到全部的角色上。
                        else
                            ele.bindKey.key = key
                        end
                    end
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                end
            }
            bindkeySettingOrder = bindkeySettingOrder + 1
            if ele.bindKey then
                bindkeySettingArgs.bindAccount = {
                    order = bindkeySettingOrder,
                    type = "toggle",
                    name = L["Bind For Account"],
                    width = 1,
                    set = function(_, val)
                        if val == true then
                            if ele.bindKey then
                                ele.bindKey.characters = nil
                                ele.bindKey.classes = nil
                            end
                        else
                            if ele.bindKey then
                                ele.bindKey.characters = {}
                                ele.bindKey.classes = {}
                            end
                        end
                        HbFrame:ReloadEframeUI(updateFrameConfig)
                    end,
                    get = function(_)
                        if ele.bindKey then
                            if ele.bindKey.characters == nil and ele.bindKey.classes == nil then
                                return true
                            end
                        else
                            return true
                        end
                    end
                }
                bindkeySettingOrder = bindkeySettingOrder + 1
            end
            if ele.bindKey and ele.bindKey.characters ~= nil then
                bindkeySettingArgs.bindCharacter = {
                    order = bindkeySettingOrder,
                    type = "toggle",
                    name = L["Bind For Current Character"],
                    width = 1,
                    set = function(_, val)
                        if val == true then
                            if ele.bindKey then
                                if ele.bindKey.characters == nil then
                                    ele.bindKey.characters = {}
                                end
                                ele.bindKey.characters[UnitGUID("player")] = true
                            end
                        else
                            if ele.bindKey and ele.bindKey.characters then
                                ele.bindKey.characters[UnitGUID("player")] = nil
                            end
                        end
                        HbFrame:ReloadEframeUI(updateFrameConfig)
                    end,
                    get = function(_)
                        if ele.bindKey and ele.bindKey.characters then
                            return ele.bindKey.characters[UnitGUID("player")]
                        end
                    end
                }
                bindkeySettingOrder = bindkeySettingOrder + 1
            end
            if ele.bindKey and ele.bindKey.classes ~= nil then
                local _, classId = UnitClassBase("player")
                bindkeySettingArgs.bindClass = {
                    order = bindkeySettingOrder,
                    type = "toggle",
                    name = L["Bind For Current Class"],
                    width = 1,
                    set = function(_, val)
                        if val == true then
                            if ele.bindKey then
                                if ele.bindKey.classes == nil then
                                    ele.bindKey.classes = {}
                                end
                                ele.bindKey.classes[classId] = true
                            end
                        else
                            if ele.bindKey and ele.bindKey.classes then
                                ele.bindKey.classes[classId] = nil
                            end
                        end
                        HbFrame:ReloadEframeUI(updateFrameConfig)
                    end,
                    get = function(_)
                        if ele.bindKey and ele.bindKey.classes then
                            return ele.bindKey.classes[classId]
                        end
                    end
                }
                bindkeySettingOrder = bindkeySettingOrder + 1
            end
            if ele.bindKey then
                bindkeySettingArgs.loadCondCombat = {
                    order = bindkeySettingOrder,
                    width = 1,
                    type = 'toggle',
                    name = L["Combat Load Condition"],
                    set = function(_, val)
                        if val == true then
                            ele.bindKey.combat = true
                        else
                            ele.bindKey.combat = nil
                        end
                        HbFrame:UpdateEframe(updateFrameConfig)
                    end,
                    get = function(_)
                        return ele.bindKey.combat ~= nil
                    end
                }
                bindkeySettingOrder = bindkeySettingOrder + 1
                bindkeySettingArgs.loadCondCombatOptions = {
                    order = bindkeySettingOrder,
                    width = 1,
                    type = 'select',
                    values = const.LoadCondCombatOptions,
                    name = "",
                    disabled = function() return ele.bindKey.combat == nil end,
                    set = function(_, val)
                        ele.bindKey.combat = val
                        HbFrame:UpdateEframe(updateFrameConfig)
                    end,
                    get = function(_)
                        return ele.bindKey.combat
                    end
                }
                bindkeySettingOrder = bindkeySettingOrder + 1
                bindkeySettingArgs.loadAttachFrameShow = {
                    order = bindkeySettingOrder,
                    width = 1,
                    type = 'toggle',
                    name = L["AttachFrame Load Condition"],
                    desc = L["Not working when in combat"],
                    set = function(_, val)
                        if val == true then
                            ele.bindKey.attachFrame = true
                        else
                            ele.bindKey.attachFrame = nil
                        end
                        HbFrame:UpdateEframe(updateFrameConfig)
                    end,
                    get = function(_)
                        return ele.bindKey.attachFrame ~= nil
                    end
                }
                bindkeySettingOrder = bindkeySettingOrder + 1
                bindkeySettingArgs.loadCondAttachFrameOptions = {
                    order = bindkeySettingOrder,
                    width = 1,
                    type = 'select',
                    values = const.LoadCondAttachFrameOptions,
                    name = "",
                    disabled = function() return ele.bindKey.attachFrame == nil end,
                    set = function(_, val)
                        ele.bindKey.attachFrame = val
                        HbFrame:UpdateEframe(updateFrameConfig)
                    end,
                    get = function(_)
                        return ele.bindKey.attachFrame
                    end
                }
                bindkeySettingOrder = bindkeySettingOrder + 1
            end
            bindkeySettingArgs.reloadDesc1 = {
                order = bindkeySettingOrder,
                width = "full",
                type = "description",
                name = "\n",
            }
            bindkeySettingOrder = bindkeySettingOrder + 1
            bindkeySettingArgs.reloadDesc2 = {
                order = bindkeySettingOrder,
                width = "full",
                type = "description",
                name = L["The newly created button do not immediately respond to key bindings and require executing the /reload command."],
            }
            bindkeySettingOrder = bindkeySettingOrder + 1
        end
        local displaySettingOrder = 1
        local displaySettingArgs = {}
        local displaySettingOptions = {
            type = "group",
            name = L["Display Rule"],
            order = settingOrder,
            args = displaySettingArgs
        }
        settingOrder = settingOrder + 1
        args.displaySetting = displaySettingOptions

        -- 支持根元素和🍃叶子元素设置加载条件，根元素加载条件在Cbs获取的时候判断，叶子元素在cbResult的时候判断
        if isRoot or E:IsLeaf(ele) then
            displaySettingArgs.isLoadToggle = {
                order = displaySettingOrder,
                width = 2,
                type = 'toggle',
                name = L["Load"],
                set = function(_, val)
                    ele.loadCond.LoadCond = val
                    if ele.loadCond.LoadCond == true then
                        if isRoot then
                            HbFrame:AddEframe(updateFrameConfig)
                        else
                            HbFrame:ReloadEframeUI(updateFrameConfig)
                        end
                    else
                        if isRoot then
                            HbFrame:DeleteEframe(updateFrameConfig)
                        else
                            HbFrame:ReloadEframeUI(updateFrameConfig)
                        end
                    end
                end,
                get = function(_) return ele.loadCond.LoadCond end
            }
            displaySettingOrder = displaySettingOrder + 1
        end

        if isRoot then
            displaySettingArgs.isDisplayMouseEnter = {
                order = displaySettingOrder,
                width = "full",
                type = 'toggle',
                name = L["Whether to show the bar menu when the mouse enter."],
                set = function(_, val)
                    ele.isDisplayMouseEnter = val
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                end,
                get = function(_) return ele.isDisplayMouseEnter end
            }
            displaySettingOrder = displaySettingOrder + 1
        end
        -- 顶部元素设置是否开启战斗支持
        if isRoot then
            displaySettingArgs.loadCondCombat = {
                order = displaySettingOrder,
                width = 1,
                type = 'toggle',
                name = L["Combat Load Condition"],
                set = function(_, val)
                    if val == true then
                        ele.loadCond.CombatCond = true
                    else
                        ele.loadCond.CombatCond = nil
                    end
                    HbFrame:UpdateEframe(updateFrameConfig)
                end,
                get = function(_)
                    return ele.loadCond.CombatCond ~= nil
                end
            }
            displaySettingOrder = displaySettingOrder + 1
            displaySettingArgs.loadCondCombatOptions = {
                order = displaySettingOrder,
                width = 2,
                type = 'select',
                values = const.LoadCondCombatOptions,
                disabled = function() return ele.loadCond.CombatCond == nil end,
                name = "",
                set = function(_, val)
                    ele.loadCond.CombatCond = val
                    HbFrame:UpdateEframe(updateFrameConfig)
                end,
                get = function(_)
                    return ele.loadCond.CombatCond
                end
            }
            displaySettingOrder = displaySettingOrder + 1
        end
        -- 加载选项：职业
        displaySettingArgs.borderGlowStatus = {
            order = displaySettingOrder,
            width = "full",
            type = 'toggle',
            name = L["Enable Class Settings"] ,
            set = function(_, val)
                if val == false then
                    ele.loadCond.ClassCond = nil
                else
                    ele.loadCond.ClassCond = {}
                end
                HbFrame:ReloadEframeUI(updateFrameConfig)
            end,
            get = function(_)
                return ele.loadCond.ClassCond ~= nil
            end
        }
        displaySettingOrder = displaySettingOrder + 1
        if ele.loadCond.ClassCond ~= nil then
            displaySettingArgs.selectClasses = {
                order = displaySettingOrder,
                width = 2,
                type = "multiselect",
                name = "",
                values = const.ClassOptions,
                get = function(_, key)
                    if ele.loadCond.ClassCond then
                        for _, class in ipairs(ele.loadCond.ClassCond) do
                            if class == key then
                                return true
                            end
                        end
                    end
                    return false
                end,
                set = function(_, key, value)
                    if value == true then
                        if ele.loadCond.ClassCond then
                            if not U.Table.IsInArray(ele.loadCond.ClassCond, key) then
                                table.insert(ele.loadCond.ClassCond, key)
                            end
                        end
                    else
                        if ele.loadCond.ClassCond then
                            local index = U.Table.GetArrayIndex(ele.loadCond.ClassCond, key)
                            if index ~= 0 then
                                table.remove(ele.loadCond.ClassCond, index)
                            end
                        end
                    end
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                end,
            }
            displaySettingOrder = displaySettingOrder + 1
        end
        if isRoot and ele.type == const.ELEMENT_TYPE.BAR then
            displaySettingArgs.unlearnedDisplayRuleEnable = {
                order = displaySettingOrder,
                width = 1,
                type = "toggle",
                name = L["Not Owned"],
                set = function(_, val)
                    if ele.displayRule == nil then
                        ele.displayRule = {}
                    end
                    if val == true then
                        ele.displayRule.unlearned = ele.displayRule.unlearned or "hide"
                    else
                        ele.displayRule.unlearned = nil
                    end
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                end,
                get = function(_)
                    return ele.displayRule and ele.displayRule.unlearned ~= nil
                end,
            }
            displaySettingOrder = displaySettingOrder + 1
            displaySettingArgs.unlearnedDisplayRule = {
                order = displaySettingOrder,
                width = 2,
                type = "select",
                name = "",
                disabled = function() return ele.displayRule == nil or ele.displayRule.unlearned == nil end,
                values = const.DisplayStateRuleOptions,
                set = function(_, val)
                    ele.displayRule.unlearned = val
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                end,
                get = function(_)
                    return ele.displayRule.unlearned or "hide"
                end,
            }
            displaySettingOrder = displaySettingOrder + 1
                displaySettingArgs.unusableDisplayRuleEnable = {
                order = displaySettingOrder,
                width = 1,
                type = "toggle",
                name = L["Not Usable"],
                set = function(_, val)
                    if ele.displayRule == nil then
                        ele.displayRule = {}
                    end
                    if val == true then
                        ele.displayRule.unusable = ele.displayRule.unusable or "gray"
                    else
                        ele.displayRule.unusable = nil
                    end
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                end,
                get = function(_)
                    return ele.displayRule and ele.displayRule.unusable ~= nil
                end,
            }
            displaySettingOrder = displaySettingOrder + 1
            displaySettingArgs.unusableDisplayRule = {
                order = displaySettingOrder,
                width = 2,
                type = "select",
                name = "",
                disabled = function() return ele.displayRule == nil or ele.displayRule.unusable == nil end,
                values = const.DisplayStateRuleOptions,
                set = function(_, val)
                    ele.displayRule.unusable = val
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                end,
                get = function(_)
                    return ele.displayRule.unusable or "gray"
                end,
            }
            displaySettingOrder = displaySettingOrder + 1
        end
        if E:IsLeaf(ele) then
            displaySettingArgs.unlearnedDisplayRuleEnable = {
                order = displaySettingOrder,
                width = 1,
                type = "toggle",
                name = L["Not Owned"],
                set = function(_, val)
                    if ele.displayRule == nil then
                        ele.displayRule = {}
                    end
                    if val == true then
                        ele.displayRule.unlearned = ele.displayRule.unlearned or "hide"
                    else
                        ele.displayRule.unlearned = nil
                    end
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                end,
                get = function(_)
                    return ele.displayRule and ele.displayRule.unlearned ~= nil
                end,
            }
            displaySettingOrder = displaySettingOrder + 1
            displaySettingArgs.unlearnedDisplayRule = {
                order = displaySettingOrder,
                width = 1.5,
                type = "select",
                name = "",
                values = const.DisplayStateRuleOptions,
                disabled = function() return ele.displayRule == nil or ele.displayRule.unlearned == nil end,
                set = function(_, val)
                    ele.displayRule.unlearned = val
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                end,
                get = function(_)
                    return ele.displayRule.unlearned or "hide"
                end,
            }
            displaySettingOrder = displaySettingOrder + 1
            displaySettingArgs.unusableDisplayRuleEnable = {
                order = displaySettingOrder,
                width = 1,
                type = "toggle",
                name = L["Not Usable"],
                set = function(_, val)
                    if ele.displayRule == nil then
                        ele.displayRule = {}
                    end
                    if val == true then
                        ele.displayRule.unusable = ele.displayRule.unusable or "gray"
                    else
                        ele.displayRule.unusable = nil
                    end
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                end,
                get = function(_)
                    return ele.displayRule and ele.displayRule.unusable ~= nil
                end,
            }
            displaySettingOrder = displaySettingOrder + 1
                displaySettingArgs.unusableDisplayRule = {
                order = displaySettingOrder,
                width = 1.5,
                type = "select",
                name = "",
                disabled = function() return ele.displayRule == nil or ele.displayRule.unusable == nil end,
                values = const.DisplayStateRuleOptions,
                set = function(_, val)
                    ele.displayRule.unusable = val
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                end,
                get = function(_)
                    return ele.displayRule.unusable or "gray"
                end,
            }
            displaySettingOrder = displaySettingOrder + 1
        end
        if isRoot then
            displaySettingArgs.isShowQualityBorder = {
                order = displaySettingOrder,
                width = "full",
                type = 'toggle',
                name = L["Show Item Quality Color"],
                get = function(_)
                    return ele.isShowQualityBorder
                end,
                set = function(_, val)
                    ele.isShowQualityBorder = val
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                end
            }
            displaySettingOrder = displaySettingOrder + 1
        end

        if isRoot and (not E:IsSingleIconConfig(ele)) then
            displaySettingArgs.elementsGrowthText = {
                order = displaySettingOrder,
                width = 1,
                type = "description",
                name = L["Direction of elements growth"]
            }
            displaySettingOrder = displaySettingOrder + 1
            displaySettingArgs.elementsGrowth = {
                order = displaySettingOrder,
                width = 2,
                type = 'select',
                name = "",
                values = const.GrowthOptions,
                set = function(_, val)
                    ele.elesGrowth = val
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                end,
                get = function() return ele.elesGrowth end
            }
            displaySettingOrder = displaySettingOrder + 1
        end

        -- 文字设置：根元素或者叶子元素可以使用
        if isRoot or E:IsLeaf(ele) then
            local textSettingOrder = 1
            local textSettingArgs = {}
            local textSettingOptions = {
                type = "group",
                name = L["Text Settings"],
                order = settingOrder,
                args = textSettingArgs
            }
            settingOrder = settingOrder + 1
            args.textSetting = textSettingOptions
            if (not isRoot) and E:IsLeaf(ele) then
                textSettingArgs.useParentSettingToggle = {
                    order = textSettingOrder,
                    width = 2,
                    type = 'toggle',
                    name = L["Use root element settings"],
                    set = function(_, val)
                        ele.isUseRootTexts = val
                        HbFrame:UpdateEframe(updateFrameConfig)
                    end,
                    get = function(_)
                        return ele.isUseRootTexts == true
                    end
                }
                textSettingOrder = textSettingOrder + 1
            end
            if isRoot or (E:IsLeaf(ele) and ele.isUseRootTexts == false) then
                textSettingArgs.TextOfNameToogle = {
                    order = textSettingOrder,
                    width = 1,
                    type = 'toggle',
                    name = L["Item Name"],
                    set = function(_, _)
                        for tIndex, text in ipairs(ele.texts) do
                            if text.text == "%n" then
                                table.remove(ele.texts, tIndex)
                                HbFrame:UpdateEframe(updateFrameConfig)
                                return
                            end
                        end
                        table.insert(ele.texts, Text:New("%n"))
                        HbFrame:UpdateEframe(updateFrameConfig)
                    end,
                    get = function(_)
                        if ele.texts == nil then
                            ele.texts = {}
                        end
                        for _, text in ipairs(ele.texts) do
                            if text.text == "%n" then
                                return true
                            end
                        end
                        return false
                    end
                }
                textSettingOrder = textSettingOrder + 1
                -- 文本名称生长方向
                textSettingArgs.TextOfNameGrowth = {
                    order = textSettingOrder,
                    width = 1,
                    type = 'select',
                    values = const.TextGrowthOptions,
                    name = L["Text Growth"],
                    set = function(_, val)
                        for _, text in ipairs(ele.texts) do
                            if text.text == "%n" then
                                text.growth = val
                                HbFrame:UpdateEframe(updateFrameConfig)
                                return
                            end
                        end
                        HbFrame:UpdateEframe(updateFrameConfig)
                    end,
                    get = function(_)
                        if ele.texts == nil then
                            ele.texts = {}
                        end
                        for _, text in ipairs(ele.texts) do
                            if text.text == "%n" then
                                return text.growth
                            end
                        end
                        return nil
                    end
                }
                textSettingOrder = textSettingOrder + 1
                textSettingArgs.space1 = {
                    order = textSettingOrder,
                    type = "description",
                    width = "full",
                    name = ""
                }
                textSettingOrder = textSettingOrder + 1
                textSettingArgs.TextOfCountToogle = {
                    order = textSettingOrder,
                    width = 1,
                    type = 'toggle',
                    name = L["Item Count"],
                    set = function(_, _)
                        for tIndex, text in ipairs(ele.texts) do
                            if text.text == "%s" then
                                table.remove(ele.texts, tIndex)
                                HbFrame:UpdateEframe(updateFrameConfig)
                                return
                            end
                        end
                        table.insert(ele.texts, Text:New("%s"))
                        HbFrame:UpdateEframe(updateFrameConfig)
                    end,
                    get = function(_)
                        if ele.texts == nil then
                            ele.texts = {}
                        end
                        for _, text in ipairs(ele.texts) do
                            if text.text == "%s" then
                                return true
                            end
                        end
                        return false
                    end
                }
                textSettingOrder = textSettingOrder + 1
            end
        end

        -- 脚本设置事件监听
        if ele.type == const.ELEMENT_TYPE.SCRIPT then
            local eventSettingOrder = 1
            local eventSettingArgs = {}
            local eventSettingOptions = {
                type = "group",
                name = L["Event Settings"],
                order = settingOrder,
                args = eventSettingArgs
            }
            settingOrder = settingOrder + 1
            args.eventSetting = eventSettingOptions
            eventSettingArgs.borderGlowStatus = {
                order = eventSettingOrder,
                width = 2,
                type = 'toggle',
                name = L["Enable Event Listening"],
                set = function(_, val)
                    if val == false then
                        ele.listenEvents = nil
                    else
                        ele.listenEvents = {}
                    end
                    HbFrame:ReloadEframeUI(updateFrameConfig)
                end,
                get = function(_)
                    return ele.listenEvents ~= nil
                end
            }
            eventSettingOrder = eventSettingOrder + 1
            if ele.listenEvents ~= nil then
                eventSettingArgs.selectEvents = {
                    order = eventSettingOrder,
                    width = 2,
                    type = "multiselect",
                    name = "",
                    values = const.BUILDIN_EVENTS,
                    get = function(_, key)
                        return ele.listenEvents[key] ~= nil
                    end,
                    set = function(_, key, value)
                        if value == true then
                            ele.listenEvents[key] = {}
                        else
                            ele.listenEvents[key] = nil
                        end
                        HbFrame:ReloadEframeUI(updateFrameConfig)
                    end,
                }
                eventSettingOrder = eventSettingOrder + 1
            end
        end

        -- 递归菜单
        local menuName = iconPath .. showTitle
        if not isRoot then
            menuName = "|cff00ff00" .. iconPath .. showTitle .. "|r"
        end
        if ele.type == const.ELEMENT_TYPE.BAR then
            local selectGroupsInBarCreate = U.Table.DeepCopyList(copySelectGroups)
            table.insert(selectGroupsInBarCreate, "barElementCreate")
            local selectGroupsInBarCreateItem = U.Table.DeepCopyList(selectGroupsInBarCreate)
            table.insert(selectGroupsInBarCreateItem, "createItem")
            local barChildrenCreateArgs = {}
            barChildrenCreateArgs["createItemGroup"] = {
                type = "group",
                name = L["ItemGroup"],
                args = {
                    mode = {
                        order = 1,
                        width = 1.5,
                        type = "select",
                        name = L["Mode"],
                        values = const.ItemsGroupModeOptions,
                        set = function(_, val)
                            addon.G.tmpCreateItemGroupMode = val
                        end,
                        get = function()
                            return addon.G.tmpCreateItemGroupMode or const.ITEMS_GROUP_MODE.RANDOM
                        end,
                    },
                    title = {
                        order = 2,
                        width = 1.5,
                        type = "input",
                        name = L["Title"],
                        set = function(_, val)
                            addon.G.tmpCreateItemGroupTitle = val
                            local title = addon.G.tmpCreateItemGroupTitle
                            if title == nil or title == "" or title == " " then
                                title = L["ItemGroup"]
                            end
                            local itemGroup = E:NewItemGroup(
                                Config.GetNewElementTitle(title, ele.elements))
                            itemGroup.extraAttr.mode = addon.G.tmpCreateItemGroupMode or const.ITEMS_GROUP_MODE.RANDOM
                            table.insert(ele.elements, itemGroup)

                            addon.G.tmpCreateItemGroupTitle = nil
                            addon.G.tmpCreateItemGroupMode = const.ITEMS_GROUP_MODE.RANDOM

                            HbFrame:ReloadEframeUI(updateFrameConfig)
                            AceConfigDialog:SelectGroup(addonName, unpack(
                                selectGroupsAfterAddItemInBar))
                        end,
                        get = function()
                            return addon.G.tmpCreateItemGroupTitle
                        end,
                    },
                },
                order = 2
            }
            barChildrenCreateArgs["createItem"] = {
                type = "group",
                name = L["Item"],
                args = {
                    itemType = {
                        order = 1,
                        width = 1,
                        type = "select",
                        name = L["Item Type"],
                        values = const.ItemTypeOptions,
                        set = function(_, val)
                            -- 切换物品类型时重置所有校验状态
                            addon.G.tmpCreateItemType = val
                            addon.G.tmpCreateItemVerified = false
                            addon.G.tmpCreateItemVerifyPending = false
                            addon.G.tmpCreateItem = nil
                            addon.G.tmpCreateItemVerifyError = nil
                            addon.G.tmpCreateItemDisplayText = nil
                            NotifyOptionsChanged()
                        end,
                        get = function()
                            return addon.G.tmpCreateItemType or const.ITEM_TYPE.ITEM
                        end
                    },
                    itemVal = {
                        order = 2,
                        width = 1,
                        type = "input",
                        name = L["Item name or item id"],
                        validate = function()
                            return true
                        end,
                        set = function(_, val)
                            if addon.G.tmpCreateItemDisplayText ~= nil and val == addon.G.tmpCreateItemDisplayText then
                                return
                            end
                            -- 重置校验状态
                            addon.G.tmpCreateItemVal = val
                            addon.G.tmpCreateItemVerified = false
                            addon.G.tmpCreateItemVerifyPending = false
                            addon.G.tmpCreateItem = nil
                            addon.G.tmpCreateItemVerifyError = nil

                            if val == nil or val == "" or val == " " then
                                NotifyOptionsChanged()
                                return
                            end

                            -- 触发异步校验：生成 token、设置 pending、调用异步验证函数
                            addon.G.tmpCreateItemVerifyPending = true
                            addon.G.tmpCreateItemVerifyToken = (addon.G.tmpCreateItemVerifyToken or 0) + 1
                            local verifyToken = addon.G.tmpCreateItemVerifyToken
                            local itemType = addon.G.tmpCreateItemType or const.ITEM_TYPE.ITEM
                            NotifyOptionsChanged()

                            -- token 机制防止过期请求回调干扰当前状态
                            AsyncVerifyCreateItemAttr(itemType, val, function(ok, item, err)
                                if addon.G.tmpCreateItemVerifyToken ~= verifyToken then
                                    return
                                end

                                addon.G.tmpCreateItemVerifyPending = false
                                if ok then
                                    if item == nil then
                                        addon.G.tmpCreateItemVerified = false
                                        addon.G.tmpCreateItem = nil
                                        addon.G.tmpCreateItemVerifyError = L["Invalid item input, please check and re-enter."]
                                        Config.ShowErrorDialog(addon.G.tmpCreateItemVerifyError, selectGroupsInBarCreateItem)
                                        NotifyOptionsChanged()
                                        return
                                    end
                                    addon.G.tmpCreateItemVerified = true
                                    addon.G.tmpCreateItem = item
                                    addon.G.tmpCreateItemVerifyError = nil

                                    local itemTitle = item.name or tostring(item.id) or L["Item"]
                                    local newElement = E:New(
                                        Config.GetNewElementTitle(itemTitle, ele.elements),
                                        const.ELEMENT_TYPE.ITEM)
                                    local createdItem = E:ToItem(newElement)
                                    createdItem.extraAttr = U.Table.DeepCopyDict(item)
                                    createdItem.icon = item.icon
                                    table.insert(ele.elements, createdItem)

                                    addon.G.tmpCreateItemVal = nil
                                    addon.G.tmpCreateItemType = const.ITEM_TYPE.ITEM
                                    addon.G.tmpCreateItemVerified = false
                                    addon.G.tmpCreateItemVerifyPending = false
                                    addon.G.tmpCreateItem = nil
                                    addon.G.tmpCreateItemVerifyError = nil
                                    addon.G.tmpCreateItemDisplayText = nil

                                    HbFrame:ReloadEframeUI(updateFrameConfig)
                                    AceConfigDialog:SelectGroup(addonName, unpack(
                                        selectGroupsAfterAddItemInBar))
                                else
                                    addon.G.tmpCreateItemVerified = false
                                    addon.G.tmpCreateItem = nil
                                    addon.G.tmpCreateItemVerifyError = err
                                    Config.ShowErrorDialog(err or L["Unable to get the id, please check the input."], selectGroupsInBarCreateItem)
                                end
                                NotifyOptionsChanged()
                            end)
                        end,
                        get = function()
                            return addon.G.tmpCreateItemVal
                        end,
                    },
                },
                order = 1,
            }
            barChildrenCreateArgs["createMacro"] = {
                type = "group",
                name = L["Macro"],
                args = {
                    title = {
                        order = 1,
                        width = "full",
                        type = "input",
                        name = L["Title"],
                        set = function(_, val)
                            addon.G.tmpCreateMacroTitle = val
                        end,
                        get = function()
                            return addon.G.tmpCreateMacroTitle
                        end,
                    },
                    content = {
                        order = 2,
                        type = 'input',
                        name = L["Macro"],
                        multiline = 10,
                        width = "full",
                        validate = function(_, val)
                            local macroAstR = Macro:Ast(val)
                            if macroAstR:is_err() then
                                return macroAstR:unwrap_err()
                            end
                            addon.G.tmpCreateMacroAst = macroAstR:unwrap()
                            return true
                        end,
                        set = function(_, val)
                            addon.G.tmpCreateMacroVal = val
                            local title = addon.G.tmpCreateMacroTitle
                            if title == nil or title == "" or title == " " then
                                title = L["Macro"]
                            end
                            local macro = E:ToMacro(E:New(
                                Config.GetNewElementTitle(title, ele.elements),
                                const.ELEMENT_TYPE.MACRO))
                            macro.extraAttr.macro = addon.G.tmpCreateMacroVal
                            macro.extraAttr.ast = U.Table.DeepCopy(addon.G.tmpCreateMacroAst)
                            if macro.extraAttr.ast then
                                macro.listenEvents = Macro:GetEventsFromAst(macro.extraAttr.ast)
                            end
                            table.insert(ele.elements, macro)

                            addon.G.tmpCreateMacroTitle = nil
                            addon.G.tmpCreateMacroVal = nil
                            addon.G.tmpCreateMacroAst = nil

                            HbFrame:ReloadEframeUI(updateFrameConfig)
                            AceConfigDialog:SelectGroup(addonName, unpack(
                                selectGroupsAfterAddItemInBar))
                        end,
                        get = function()
                            return addon.G.tmpCreateMacroVal
                        end,
                    },
                },
                order = 3,
            }
            barChildrenCreateArgs["createScript"] = {
                type = "group",
                name = L["Script"],
                args = {
                    title = {
                        order = 1,
                        width = "full",
                        type = "input",
                        name = L["Title"],
                        set = function(_, val)
                            addon.G.tmpCreateScriptTitle = val
                        end,
                        get = function()
                            return addon.G.tmpCreateScriptTitle
                        end,
                    },
                    content = {
                        order = 2,
                        type = 'input',
                        name = L["Script"],
                        multiline = 10,
                        width = "full",
                        validate = function(_, val)
                            local func, loadstringErr = loadstring(val)
                            if not func then
                                return L["Illegal script."] .. " " .. loadstringErr
                            end
                            return true
                        end,
                        set = function(_, val)
                            addon.G.tmpCreateScriptVal = val
                            local title = addon.G.tmpCreateScriptTitle
                            if title == nil or title == "" or title == " " then
                                title = L["Script"]
                            end
                            local script = E:ToScript(E:New(
                                Config.GetNewElementTitle(title, ele.elements),
                                const.ELEMENT_TYPE.SCRIPT))
                            script.extraAttr.script = addon.G.tmpCreateScriptVal
                            table.insert(ele.elements, script)

                            addon.G.tmpCreateScriptTitle = nil
                            addon.G.tmpCreateScriptVal = nil

                            HbFrame:ReloadEframeUI(updateFrameConfig)
                            AceConfigDialog:SelectGroup(addonName, unpack(
                                selectGroupsAfterAddItemInBar))
                        end,
                        get = function()
                            return addon.G.tmpCreateScriptVal
                        end,
                    },
                },
                order = 4,
            }

            local barChildrenListArgs = {}
            local copySelectGroupsInBarChildren = U.Table.DeepCopyList(copySelectGroups)
            table.insert(copySelectGroupsInBarChildren, "barElementList")
            if ele.elements and #ele.elements then
                local tmpArgs = GetElementOptions(ele.elements, topEleConfig or ele,
                    copySelectGroupsInBarChildren)
                for k, v in pairs(tmpArgs) do
                    barChildrenListArgs[k] = v
                end
            end

            local barSettingTabArgs = {
                elementSetting = U.Table.DeepCopy(args.elementSetting),
                displaySetting = U.Table.DeepCopy(args.displaySetting),
                textSetting = U.Table.DeepCopy(args.textSetting),
            }
            if barSettingTabArgs.elementSetting then
                barSettingTabArgs.elementSetting.name = L["Basic"]
                barSettingTabArgs.elementSetting.order = 1
            end
            if barSettingTabArgs.displaySetting then
                barSettingTabArgs.displaySetting.name = L["Display"]
                barSettingTabArgs.displaySetting.order = 2
            end
            if barSettingTabArgs.textSetting then
                barSettingTabArgs.textSetting.name = L["Text"]
                barSettingTabArgs.textSetting.order = 3
            end
            local barArgs = {}
            barArgs["barSetting"] = {
                type = "group",
                name = L["Settings"],
                childGroups = "tab",
                args = barSettingTabArgs,
                order = 1
            }
            barArgs["barElementList"] = {
                type = "group",
                name = L["List"],
                childGroups = "tree",
                args = barChildrenListArgs,
                order = 2,
            }
            barArgs["barElementCreate"] = {
                type = "group",
                name = L["Create"],
                childGroups = "tab",
                args = barChildrenCreateArgs,
                order = 3,
            }
            SetBarDefaultTab(copySelectGroups, ele.elements ~= nil and #ele.elements > 0)
            eleArgs["elementMenu" .. i] = {
                type = 'group',
                childGroups = "tab",
                name = menuName,
                args = barArgs,
                order = i * 10
            }
        else
            -- 简化子元素 Tab 标题
            if ele.type ~= const.ELEMENT_TYPE.ITEM and args.elementSetting then args.elementSetting.name = L["Basic"] end
            if args.baseSetting then args.baseSetting.name = L["Settings"] end
            if args.bindkeySetting then args.bindkeySetting.name = L["Bindkey"] end
            if args.displaySetting then args.displaySetting.name = L["Display"] end
            if args.textSetting then args.textSetting.name = L["Text"] end
            if args.eventSetting then args.eventSetting.name = L["Event"] end
            if (ele.type == const.ELEMENT_TYPE.ITEM_GROUP or ele.type == const.ELEMENT_TYPE.SCRIPT or ele.type == const.ELEMENT_TYPE.MACRO)
                and args.elementSetting and args.baseSetting then
                local movedArgs = args.baseSetting.args
                if movedArgs then
                    local nextOrder = GetMaxArgOrder(args.elementSetting.args) + 1
                    for movedKey, movedArg in pairs(movedArgs) do
                        args.elementSetting.args[movedKey] = movedArg
                        if type(movedArg) == "table" and type(movedArg.order) == "number" then
                            movedArg.order = nextOrder
                            nextOrder = nextOrder + 1
                        end
                    end
                end
                args.baseSetting = nil
                args.elementSetting.name = L["Settings"]

                local tabOrder = 1
                if args.elementSetting then
                    args.elementSetting.order = tabOrder
                    tabOrder = tabOrder + 1
                end
                if args.bindkeySetting then
                    args.bindkeySetting.order = tabOrder
                    tabOrder = tabOrder + 1
                end
                if args.displaySetting then
                    args.displaySetting.order = tabOrder
                    tabOrder = tabOrder + 1
                end
                if args.textSetting then
                    args.textSetting.order = tabOrder
                    tabOrder = tabOrder + 1
                end
                if args.eventSetting then
                    args.eventSetting.order = tabOrder
                end
            end
            if ele.type == const.ELEMENT_TYPE.ITEM then
                args.elementSetting = nil
                local tabOrder = 1
                if args.baseSetting then
                    args.baseSetting.order = tabOrder
                    tabOrder = tabOrder + 1
                end
                if args.bindkeySetting then
                    args.bindkeySetting.order = tabOrder
                    tabOrder = tabOrder + 1
                end
                if args.displaySetting then
                    args.displaySetting.order = tabOrder
                    tabOrder = tabOrder + 1
                end
                if args.textSetting then
                    args.textSetting.order = tabOrder
                    tabOrder = tabOrder + 1
                end
                if args.eventSetting then
                    args.eventSetting.order = tabOrder
                end
            end
            eleArgs["elementMenu" .. i] = {
                type = 'group',
                childGroups = "tab",
                name = menuName,
                args = args,
                order = i * 10
            }
        end
    end
    return eleArgs
end

function ConfigOptions.ElementsOptions()
    local options = {
        type = 'group',
        name = L["Bar"],
        order = 2,
        args = {
            addBar = {
                order = 2,
                width = 1,
                type = 'execute',
                name = L["New Bar"],
                func = function()
                    local bar = E:New(Config.GetNewElementTitle(L["Bar"],
                            addon.db.profile
                            .elements),
                        const.ELEMENT_TYPE.BAR)
                    table.insert(addon.db.profile.elements, bar)
                    HbFrame:AddEframe(bar)
                    AceConfigDialog:SelectGroup(addonName, "element",
                        "elementMenu" ..
                        #addon.db.profile.elements)
                end
            },
            sapce1 = { order = 3, type = 'description', name = "\n\n\n" },
            itemHeading = {
                order = 4,
                type = 'header',
                name = L["Import Configuration"]
            },
            importEditBox = {
                order = 5,
                type = 'input',
                name = L["Configuration string"],
                multiline = 10,
                width = "full",
                set = function(_, val)
                    addon.G.tmpImportElementConfigString = val
                    local errorMsg =
                        L["Import failed: Invalid configuration string."]
                    if val == nil or val == "" then
                        U.Print.PrintErrorText(errorMsg)
                        return
                    end
                    local decodedData = LibDeflate:DecodeForPrint(val)
                    if decodedData == nil then
                        U.Print.PrintErrorText(errorMsg)
                        return
                    end
                    local decompressedData =
                        LibDeflate:DecompressDeflate(decodedData)
                    if decompressedData == nil then
                        U.Print.PrintErrorText(errorMsg)
                        return
                    end
                    ---@type boolean, ElementConfig
                    local success, eleConfig =
                        AceSerializer:Deserialize(decompressedData)
                    if not success then
                        U.Print.PrintErrorText(errorMsg)
                        return
                    end
                    if type(eleConfig) ~= "table" then
                        U.Print.PrintErrorText(errorMsg)
                        return
                    end
                    if eleConfig.title == nil then
                        U.Print.PrintErrorText(errorMsg)
                        return
                    end
                    local rightType = false
                    for _, v in pairs(const.ELEMENT_TYPE) do
                        if v == eleConfig.type then
                            rightType = true
                            break
                        end
                    end
                    if rightType == false then
                        U.Print.PrintErrorText(errorMsg)
                        return
                    end
                    if eleConfig.extraAttr == nil then
                        U.Print.PrintErrorText(errorMsg)
                        return
                    end
                    -- Always strip keybinds on import
                    addon.G.tmpImportKeybind = false
                    Config.HandleConfig(eleConfig)
                    eleConfig = Config.NormalizeAsRootBar(eleConfig,
                        addon.db.profile.elements)
                    if Config.IsIdDuplicated(eleConfig.id,
                            addon.db.profile.elements) then
                        -- Show confirm dialog for overwrite
                        local dialog = StaticPopup_Show("HAPPYBUTTON_CONFIRM_IMPORT_OVERWRITE")
                        if dialog then
                            dialog.data = {
                                onAccept = function()
                                    for i, ele in ipairs(addon.db.profile.elements) do
                                        if ele.id == eleConfig.id then
                                            addon.db.profile.elements[i] = eleConfig
                                            addon:UpdateOptions()
                                            AceConfigDialog:SelectGroup(addonName,
                                                "element",
                                                "elementMenu" .. i)
                                            return
                                        end
                                    end
                                end,
                                onCancel = function()
                                    eleConfig.id = U.String.GenerateID()
                                    if Config.IsTitleDuplicated(eleConfig.title,
                                            addon.db.profile.elements) then
                                        eleConfig.title =
                                            Config.CreateDuplicateTitle(eleConfig.title,
                                                addon.db.profile.elements)
                                    end
                                    table.insert(addon.db.profile.elements, eleConfig)
                                    HbFrame:AddEframe(eleConfig)
                                    addon:UpdateOptions()
                                    AceConfigDialog:SelectGroup(addonName, "element",
                                        "elementMenu" ..
                                        #addon.db.profile.elements)
                                end,
                            }
                        end
                        return
                    end
                    if Config.IsTitleDuplicated(eleConfig.title,
                            addon.db.profile.elements) then
                        eleConfig.title =
                            Config.CreateDuplicateTitle(eleConfig.title,
                                addon.db.profile
                                .elements)
                    end
                    table.insert(addon.db.profile.elements, eleConfig)
                    HbFrame:AddEframe(eleConfig)
                    addon:UpdateOptions()
                    AceConfigDialog:SelectGroup(addonName, "element",
                        "elementMenu" ..
                        #addon.db.profile.elements)
                end,
                get = function(_)
                    return addon.G.tmpImportElementConfigString
                end
            }
        }
    }
    local args = GetElementOptions(addon.db.profile.elements, nil, { "element" })
    for k, v in pairs(args) do options.args[k] = v end
    return options
end

function ConfigOptions.Options()
    local options = {
        name = addonName,
        handler = addon,
        type = 'group',
        args = {
            element = ConfigOptions.ElementsOptions()
        }
    }
    return options
end

function addon:OnInitialize()
    -- 检测是否安装了ElvUI
    local ElvUI = nil
    local ElvUISkins = nil
    local Masque = nil
    local NDui = nil
    ---@diagnostic disable-next-line: undefined-field
    if _G.ElvUI then
        ---@diagnostic disable-next-line: undefined-field
        ElvUI = unpack(_G.ElvUI) ---@type ElvUI
        ElvUISkins = ElvUI:GetModule("Skins") ---@type ElvUISkins
    end
    Masque = LibStub("Masque", true)
    ---@diagnostic disable-next-line: undefined-field
    NDui = _G.NDui
    local screenWidth, screenHeight = GetPhysicalScreenSize()
    -- 全局变量
    ---@class GlobalValue
    self.G = {
        ElvUI = ElvUI,
        ElvUISkins = ElvUISkins,
        Masque = Masque,
        NDui = NDui,
        screenWidth = math.floor(screenWidth),   -- 屏幕宽度
        screenHeight = math.floor(screenHeight), -- 屏幕高度
        iconWidth = 32,
        iconHeight = 32,
        IsEditMode = false,
        tmpImportElementConfigString = nil, -- 导入elementconfig配置字符串
        tmpConfigString = nil,              -- 全局配置编辑字符串
        tmpNewItemType = nil,
        tmpNewItemVal = nil,
        tmpNewItem = { type = nil, id = nil, icon = nil, name = nil }, ---@type ItemAttr
        tmpCreateItemGroupTitle = nil,
        tmpCreateItemGroupMode = const.ITEMS_GROUP_MODE.RANDOM,
        tmpCreateItemType = const.ITEM_TYPE.ITEM,
        tmpCreateItemVal = nil,
        tmpCreateItemVerified = false,
        tmpCreateItemVerifyPending = false,
        tmpCreateItemVerifyToken = 0,
        tmpCreateItemVerifyError = nil,
        tmpCreateItem = nil, ---@type ItemAttr | nil
        tmpCreateItemDisplayText = nil,
        tmpCreateMacroTitle = nil,
        tmpCreateMacroVal = nil,
        tmpCreateMacroAst = nil,
        tmpCreateScriptTitle = nil,
        tmpCreateScriptVal = nil,
        tmpQuickItemType = const.ITEM_TYPE.ITEM,
        tmpQuickItemVal = nil,
        tmpNewText = nil, -- 添加文本
        tmpMacroAst = nil,  -- 宏解析结果
    }
    -- Expose Config table so other modules (ConfigFrame) can access utility functions
    self.G.Config = Config
    -- 注册数据库，添加分类设置
    self.db = LibStub("AceDB-3.0"):New("HappyButtonDB", {
        profile = {
            elements = {} ---@type ElementConfig[]
        }
    }, true)
    -- 对配置文件进行兼容性处理
    Config.NormalizeProfileElements()
    if Client:IsRetail() then
        -- 正式服使用新配置UI
        self:RegisterChatCommand(addonName, "OpenNewConfig")
        self:RegisterChatCommand("hb", "OpenNewConfig")
    else
        -- 怀旧服使用旧 Ace3 配置面板
        AceConfig:RegisterOptionsTable(addonName, ConfigOptions.Options)
        Config.PatchAceConfigTooltipSetText()
        AceConfigDialog:SetDefaultSize(addonName, DEFAULT_CONFIG_UI_WIDTH, DEFAULT_CONFIG_UI_HEIGHT)
        self:RegisterChatCommand(addonName, "OpenConfig")
        self:RegisterChatCommand("hb", "OpenConfig")
    end
    -- 所有版本都支持 /hbo 打开旧 Ace3 配置面板
    AceConfig:RegisterOptionsTable(addonName, ConfigOptions.Options)
    Config.PatchAceConfigTooltipSetText()
    AceConfigDialog:SetDefaultSize(addonName, DEFAULT_CONFIG_UI_WIDTH, DEFAULT_CONFIG_UI_HEIGHT)
    self:RegisterChatCommand("hbo", "OpenOldConfig")
    -- 初始化提示标志：新配置UI的 /hbo 提示每次登录只显示一次
    self.newConfigHintShown = false
end

function addon:OpenConfig()
    if InCombatLockdown() then
        U.Print.PrintInfoText(L["You cannot use this in combat."] )
        return
    end
    AceConfigDialog:Open(addonName)
    C_Timer.After(0.1, function()
        local frame = AceConfigDialog.OpenFrames[addonName]
        if frame then
            local status = AceConfigDialog:GetStatusTable(addonName)
            if status.width == nil then
                status.width = DEFAULT_CONFIG_UI_WIDTH
            end
            if status.height == nil then
                status.height = DEFAULT_CONFIG_UI_HEIGHT
            end
            frame:SetWidth(status.width)
            frame:SetHeight(status.height)
        end
    end)
end

function addon:OpenNewConfig()
    local ConfigFrame = self:GetModule("ConfigFrame")
    if ConfigFrame then
        ConfigFrame:Toggle()
        -- 每次登录只输出一次提示
        if not self.newConfigHintShown then
            U.Print.PrintInfoText(L["If you prefer the old editing window, use /hbo to open it."])
            self.newConfigHintShown = true
        end
    end
end

function addon:OpenOldConfig()
    if InCombatLockdown() then
        U.Print.PrintInfoText(L["You cannot use this in combat."] )
        return
    end
    AceConfigDialog:Open(addonName)
    C_Timer.After(0.1, function()
        local frame = AceConfigDialog.OpenFrames[addonName]
        if frame then
            local status = AceConfigDialog:GetStatusTable(addonName)
            if status.width == nil then
                status.width = DEFAULT_CONFIG_UI_WIDTH
            end
            if status.height == nil then
                status.height = DEFAULT_CONFIG_UI_HEIGHT
            end
            frame:SetWidth(status.width)
            frame:SetHeight(status.height)
        end
    end)
end

function addon:UpdateOptions()
    -- 重新注册配置表来更新菜单栏
    -- LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
end

---@param element ElementConfig
function addon:compatibilizeConfig(element)
    if element == nil then
        return
    end
    if element.elements == nil then
        element.elements = {}
    end
    if element.loadCond == nil then
        element.loadCond = { LoadCond = true }
    end
    if element.displayRule == nil then
        element.displayRule = {}
    end
    if element.type == const.ELEMENT_TYPE.ITEM_GROUP then
        local itemGroup = E:ToItemGroup(element)
        if itemGroup.extraAttr == nil then
            itemGroup.extraAttr = {
                mode = const.ITEMS_GROUP_MODE.RANDOM,
                configSelectedItemIndex = 1,
            }
        end
        if itemGroup.extraAttr.mode == nil then
            itemGroup.extraAttr.mode = const.ITEMS_GROUP_MODE.RANDOM
        end
        if itemGroup.extraAttr.configSelectedItemIndex == nil then
            itemGroup.extraAttr.configSelectedItemIndex = 1
        end
    end
    if element.type == const.ELEMENT_TYPE.SCRIPT then
        local script = E:ToScript(element)
        if script.extraAttr == nil then
            script.extraAttr = {}
        end
    end
    if element.type == const.ELEMENT_TYPE.MACRO then
        local macro = E:ToMacro(element)
        if macro.extraAttr == nil then
            macro.extraAttr = {}
        end
    end
    if element.type == const.ELEMENT_TYPE.ITEM then
        local item = E:ToItem(element)
        if item.extraAttr == nil then
            item.extraAttr = {}
        end
    end
    if element.elements and #element.elements then
        for _, child in ipairs(element.elements) do
            addon:compatibilizeConfig(child)
        end
    end
end

AceConfigDialog.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
AceConfigDialog.frame:SetScript("OnEvent", function(_, event, _)
    if event == "PLAYER_REGEN_DISABLED" then
        AceConfigDialog:Close(addonName)
    end
end)