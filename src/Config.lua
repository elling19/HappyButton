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

---@class Trigger: AceModule
local Trigger = addon:GetModule("Trigger")

---@class Condition: AceModule
local Condition = addon:GetModule("Condition")

---@class Utils: AceModule
local U = addon:GetModule('Utils')

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")
local LibDeflate = LibStub:GetLibrary("LibDeflate")
local AceGUI = LibStub("AceGUI-3.0")


---@class Config
local Config = {}

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
    if item.type == const.ITEM_TYPE.ITEM or item.type ==
        const.ITEM_TYPE.EQUIPMENT or item.type == const.ITEM_TYPE.TOY then
        local itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subClassID = C_Item.GetItemInfoInstant(val)
        if itemID then
            item.id = itemID
            item.icon = icon
        else
            return R:Err(L["Unable to get the id, please check the input."])
        end
        local itemName = C_Item.GetItemNameByID(item.id)
        if itemName then
            item.name = itemName
        else
            return R:Err(L["Unable to get the name, please check the input."])
        end
    elseif item.type == const.ITEM_TYPE.SPELL then
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
        local spellName = C_Spell.GetSpellName(item.extraAttr.id)
        if spellName then
            item.extraAttr.name = spellName
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

---@param ele ElementConfig
function Config.LocalizeItemsName(ele)
    if ele.type == const.ELEMENT_TYPE.ITEM then
        local item = E:ToItem(ele)
        Config.UpdateItemLocalizeName(item)
    end
    if ele.elements then
        for _, childEle in ipairs(ele.elements) do
            Config.LocalizeItemsName(childEle)
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

---@class ConfigOptions
---@field ElementsOptions function
---@field ConfigOptions function
---@field Options function
local ConfigOptions = {}

---@param elements ElementConfig[]
---@param topEleConfig ElementConfig | nil 顶层的菜单，当为nil的时候，表示当前elements参数本身是顶层菜单
---@param selectGroups table  配置界面选项卡位置
local function GetElementOptions(elements, topEleConfig, selectGroups)
    local isRoot = topEleConfig == nil
    local eleArgs = {}
    for i, ele in ipairs(elements) do
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
        local showTitle = ele.title
        local showIcon = ele.icon or 134400
        if ele.type == const.ELEMENT_TYPE.ITEM then
            local item = E:ToItem(ele)
            if item.extraAttr.name then
                showTitle = item.extraAttr.name
            end
            if item.extraAttr.icon then
                showIcon = item.extraAttr.icon
            end
        end
        local iconPath = "|T" .. showIcon .. ":16|t"

        local args = {}
        local baseSettingOrder = 1
        local baseSettingArgs = {}
        local baseSettingOptions = {
            type = "group",
            name = L["General Settings"],
            inline = true,
            order = 2,
            args = baseSettingArgs
        }
        args.baseSetting = baseSettingOptions
        baseSettingArgs.delete = {
            order = baseSettingOrder,
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
        baseSettingOrder = baseSettingOrder + 1
        baseSettingArgs.export = {
            order = baseSettingOrder,
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
        baseSettingOrder = baseSettingOrder + 1
        baseSettingArgs.localize = {
            order = baseSettingOrder,
            width = 1,
            type = 'execute',
            name = L["Localize the name of items"],
            func = function()
                Config.LocalizeItemsName(ele)
                HbFrame:ReloadEframeUI(updateFrameConfig)
            end
        }
        local elementSettingOrder = 1
        local elementSettingArgs = {}
        local elementSettingOptions = {
            type = "group",
            name = L["Element Settings"],
            inline = true,
            order = 3,
            args = elementSettingArgs
        }
        args.elementSetting = elementSettingOptions
        elementSettingArgs.title = {
            order = elementSettingOrder,
            width = 1,
            type = 'input',
            name = L['Element Title'],
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
                ele.title = val
                HbFrame:ReloadEframeUI(updateFrameConfig)
                addon:UpdateOptions()
            end
        }
        elementSettingOrder = elementSettingOrder + 1
        elementSettingArgs.icon = {
            order = elementSettingOrder,
            width = 1,
            type = 'input',
            name = L["Element Icon ID or Path"],
            get = function() return ele.icon end,
            set = function(_, val)
                ele.icon = val
                HbFrame:ReloadEframeUI(updateFrameConfig)
                addon:UpdateOptions()
            end
        }
        elementSettingOrder = elementSettingOrder + 1
        if isRoot then
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
                    validate = function(_, val)
                        local r = Config.VerifyItemAttr(addon.G.tmpNewItemType,
                            val)
                        if r:is_err() then
                            return r:unwrap_err()
                        else
                            addon.G.tmpNewItem = r:unwrap()
                        end
                        return true
                    end,
                    set = function(_, _)
                        item.extraAttr = U.Table
                            .DeepCopyDict(addon.G.tmpNewItem)
                        HbFrame:ReloadEframeUI(updateFrameConfig)
                        addon.G.tmpNewItemVal = nil
                        addon.G.tmpNewItem = {}
                    end,
                    get = function()
                        return addon.G.tmpNewItemVal
                    end
                }
                elementSettingOrder = elementSettingOrder + 1
            else
                elementSettingArgs.id = {
                    order = elementSettingOrder,
                    width = 1,
                    type = 'input',
                    name = L["ID"],
                    disabled = true,
                    get = function()
                        return tostring(extraAttr.id)
                    end
                }
                elementSettingOrder = elementSettingOrder + 1
                elementSettingArgs.name = {
                    order = elementSettingOrder,
                    width = 1,
                    type = 'input',
                    name = L["Name"],
                    disabled = true,
                    get = function() return extraAttr.name end
                }
                elementSettingOrder = elementSettingOrder + 1
                elementSettingArgs.type = {
                    order = elementSettingOrder,
                    width = 2,
                    type = 'select',
                    name = L["Type"],
                    values = const.ItemTypeOptions,
                    disabled = true,
                    get = function() return extraAttr.type end
                }
                elementSettingOrder = elementSettingOrder + 1
            end
        end
        if isRoot then
            if ele.type ~= const.ELEMENT_TYPE.ITEM and ele.type ~=
                const.ELEMENT_TYPE.ITEM_GROUP then
                elementSettingArgs.elementsGrowth = {
                    order = elementSettingOrder,
                    width = 2,
                    type = 'select',
                    name = L["Direction of elements growth"],
                    values = const.GrowthOptions,
                    set = function(_, val)
                        ele.elesGrowth = val
                        HbFrame:ReloadEframeUI(updateFrameConfig)
                    end,
                    get = function() return ele.elesGrowth end
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
                multiline = 20,
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
        end
        if isRoot then
            local positionSettingOrder = 1
            local positionSettingArgs = {}
            local positionSettingOptions = {
                type = "group",
                name = L["Position Settings"],
                inline = true,
                order = 3,
                args = positionSettingArgs
            }
            args.positionSetting = positionSettingOptions
            positionSettingArgs.attachFrame = {
                order = positionSettingOrder,
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
            positionSettingOrder = positionSettingOrder + 1
            positionSettingArgs.attachFrameOptions = {
                order = positionSettingOrder,
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
            positionSettingOrder = positionSettingOrder + 1
            positionSettingArgs.AnchorPos = {
                order = positionSettingOrder,
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
            positionSettingOrder = positionSettingOrder + 1
            positionSettingArgs.attachFrameAnchorPos = {
                order = positionSettingOrder,
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
            positionSettingOrder = positionSettingOrder + 1
            positionSettingArgs.posX = {
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
            positionSettingOrder = positionSettingOrder + 1
            positionSettingArgs.posY = {
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
        end
        local displaySettingOrder = 1
        local displaySettingArgs = {}
        local displaySettingOptions = {
            type = "group",
            name = L["Display Rule"],
            inline = true,
            order = 4,
            args = displaySettingArgs
        }
        args.displaySetting = displaySettingOptions
        displaySettingArgs.isLoadToggle = {
            order = displaySettingOrder,
            width = 2,
            type = 'toggle',
            name = L["Load"],
            set = function(_, val)
                ele.isLoad = val
                if ele.isLoad == true then
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
            get = function(_) return ele.isLoad end
        }
        displaySettingOrder = displaySettingOrder + 1
        if isRoot then
            displaySettingArgs.isDisplayMouseEnter = {
                order = displaySettingOrder,
                width = 2,
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
            if ele.type == const.ELEMENT_TYPE.BAR_GROUP then
                displaySettingArgs.combatLoadCond = {
                    order = displaySettingOrder,
                    width = 2,
                    type = 'description',
                    name = L["BarGroup only load when out of combat"]
                }
            else
                displaySettingArgs.combatLoadCond = {
                    order = displaySettingOrder,
                    width = 2,
                    type = 'select',
                    values = const.CombatLoadCondOptions,
                    name = L["Combat Load Condition"],
                    set = function(_, val)
                        ele.combatLoadCond = val
                        HbFrame:UpdateEframe(updateFrameConfig)
                    end,
                    get = function(_)
                        return ele.combatLoadCond
                    end
                }
            end
            displaySettingOrder = displaySettingOrder + 1
        end
        if E:IsLeaf(ele) then
            displaySettingArgs.displayLearnedToggle = {
                order = displaySettingOrder,
                width = 2,
                type = 'toggle',
                name = L["Whether to display only learned or owned items."],
                set = function(_, val)
                    ele.isDisplayUnLearned = not val
                    HbFrame:UpdateEframe(updateFrameConfig)
                end,
                get = function(_)
                    return not ele.isDisplayUnLearned
                end
            }
        end
        displaySettingOrder = displaySettingOrder + 1
        -- 文字设置：根元素或者叶子元素可以使用
        if isRoot or E:IsLeaf(ele) then
            local textSettingOrder = 1
            local textSettingArgs = {}
            local textSettingOptions = {
                type = "group",
                name = L["Text Settings"],
                inline = true,
                order = 5,
                args = textSettingArgs
            }
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

        -- 物品条组、物品条、物品组添加子元素
        if ele.type == const.ELEMENT_TYPE.BAR_GROUP or ele.type == const.ELEMENT_TYPE.BAR or ele.type == const.ELEMENT_TYPE.ITEM_GROUP then
            local addChildrenSettingOrder = 1
            local addChildrenSettingArgs = {}
            local addChildrenSettingOptions = {
                type = "group",
                name = L["Add Child Elements"],
                inline = true,
                order = 6,
                args = addChildrenSettingArgs
            }
            args.addChildrenSetting = addChildrenSettingOptions

            if ele.type == const.ELEMENT_TYPE.BAR_GROUP then
                addChildrenSettingArgs.addBar = {
                    order = addChildrenSettingOrder,
                    width = 1,
                    type = 'execute',
                    name = L["New Bar"],
                    func = function()
                        local bar = E:New(Config.GetNewElementTitle(L["Bar"],
                                ele.elements),
                            const.ELEMENT_TYPE.BAR)
                        table.insert(ele.elements, bar)
                        HbFrame:ReloadEframeUI(updateFrameConfig)
                        AceConfigDialog:SelectGroup(addonName, unpack(
                            selectGroupsAfterAddItem))
                    end
                }
                addChildrenSettingOrder = addChildrenSettingOrder + 1
            end
            if ele.type == const.ELEMENT_TYPE.BAR then
                addChildrenSettingArgs.addBar = {
                    order = addChildrenSettingOrder,
                    width = 1,
                    type = 'execute',
                    name = L["New Bar"],
                    func = function()
                        local bar = E:New(Config.GetNewElementTitle(L["Bar"],
                                ele.elements),
                            const.ELEMENT_TYPE.BAR)
                        table.insert(ele.elements, bar)
                        HbFrame:ReloadEframeUI(updateFrameConfig)
                        AceConfigDialog:SelectGroup(addonName, unpack(
                            selectGroupsAfterAddItem))
                    end
                }
                addChildrenSettingOrder = addChildrenSettingOrder + 1
                addChildrenSettingArgs.addItemGroup = {
                    order = addChildrenSettingOrder,
                    width = 1,
                    type = 'execute',
                    name = L["New ItemGroup"],
                    func = function()
                        local itemGroup = E:NewItemGroup(
                            Config.GetNewElementTitle(
                                L["ItemGroup"], ele.elements))
                        table.insert(ele.elements, itemGroup)
                        HbFrame:ReloadEframeUI(updateFrameConfig)
                        AceConfigDialog:SelectGroup(addonName, unpack(
                            selectGroupsAfterAddItem))
                    end
                }
                addChildrenSettingOrder = addChildrenSettingOrder + 1
                addChildrenSettingArgs.addScript = {
                    order = addChildrenSettingOrder,
                    width = 1,
                    type = 'execute',
                    name = L["New Script"],
                    func = function()
                        local script = E:New(
                            Config.GetNewElementTitle(L["Script"],
                                ele.elements),
                            const.ELEMENT_TYPE.SCRIPT)
                        table.insert(ele.elements, script)
                        HbFrame:ReloadEframeUI(updateFrameConfig)
                        AceConfigDialog:SelectGroup(addonName, unpack(
                            selectGroupsAfterAddItem))
                    end
                }
                addChildrenSettingOrder = addChildrenSettingOrder + 1
                addChildrenSettingArgs.addItem = {
                    order = addChildrenSettingOrder,
                    width = 1,
                    type = 'execute',
                    name = L["New Item"],
                    func = function()
                        local item = E:New(Config.GetNewElementTitle(L["Item"],
                                ele.elements),
                            const.ELEMENT_TYPE.ITEM)
                        table.insert(ele.elements, item)
                        HbFrame:ReloadEframeUI(updateFrameConfig)
                        AceConfigDialog:SelectGroup(addonName, unpack(
                            selectGroupsAfterAddItem))
                    end
                }
                addChildrenSettingOrder = addChildrenSettingOrder + 1
            end
            if ele.type == const.ELEMENT_TYPE.ITEM_GROUP then
                local itemGroup = E:ToItemGroup(ele)
                addChildrenSettingOrder = addChildrenSettingOrder + 1
                addChildrenSettingArgs.itemType = {
                    order = addChildrenSettingOrder,
                    type = 'select',
                    name = L["Item Type"],
                    values = const.ItemTypeOptions,
                    set = function(_, val)
                        addon.G.tmpNewItemType = val
                    end,
                    get = function() return addon.G.tmpNewItemType end
                }
                addChildrenSettingOrder = addChildrenSettingOrder + 1
                addChildrenSettingArgs.itemVal = {
                    order = addChildrenSettingOrder,
                    type = 'input',
                    name = L["Item name or item id"],
                    validate = function(_, val)
                        local r = Config.VerifyItemAttr(addon.G.tmpNewItemType, val)
                        if r:is_err() then
                            return r:unwrap_err()
                        else
                            addon.G.tmpNewItem = r:unwrap()
                        end
                        return true
                    end,
                    set = function(_, _)
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
                addChildrenSettingOrder = addChildrenSettingOrder + 1
            end
        end
        -- 物品组查看/编辑/删除物品
        if ele.type == const.ELEMENT_TYPE.ITEM_GROUP then
            local itemGroup = E:ToItemGroup(ele)
            local editChildrenSettingOrder = 1
            local editChildrenSettingArgs = {}
            local editChildrenSettingOptions = {
                type = "group",
                name = L["Edit Child Elements"],
                inline = true,
                order = 7,
                args = editChildrenSettingArgs
            }
            args.editChildrenSetting = editChildrenSettingOptions
            local itemsOptions = {} ---@type table<number, ItemConfig>
            if ele.elements then
                for _, _item in ipairs(ele.elements) do
                    local item = E:ToItem(_item)
                    local optionTitle = item.extraAttr.name or item.title or ""
                    local optionIcon = item.extraAttr.icon or item.icon or ""
                    table.insert(itemsOptions, "|T" .. optionIcon .. ":16|t" .. optionTitle)
                end
            end
            editChildrenSettingArgs.selectChildren = {
                order = editChildrenSettingOrder,
                width = 1,
                type = "select",
                name = L["Select Item"],
                values = itemsOptions,
                set = function(_, val)
                    itemGroup.extraAttr.configSelectedItemIndex = val
                end,
                get = function() return itemGroup.extraAttr.configSelectedItemIndex end
            }
            editChildrenSettingOrder = editChildrenSettingOrder + 1
            editChildrenSettingArgs.deleteChildren = {
                order = editChildrenSettingOrder,
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
        end

        -- 触发器设置：叶子元素可以使用
        if E:IsLeaf(ele) then
            local triggerSettingOrder = 1
            local triggerSettingArgs = {}
            local triggerSettingOptions = {
                type = "group",
                name = L["Trigger Settings"],
                inline = true,
                order = 8,
                args = triggerSettingArgs
            }
            args.triggerSetting = triggerSettingOptions
            local triggerOptions = {}
            if ele.triggers then
                for triggerIndex, _ in ipairs(ele.triggers) do
                    table.insert(triggerOptions, L["Trigger"] .. triggerIndex)
                end
            end
            if #triggerOptions > 0 then
                triggerSettingArgs.selectTrigger = {
                    order = triggerSettingOrder,
                    width = 1,
                    type = "select",
                    name = "",
                    values = triggerOptions,
                    set = function(_, val)
                        ele.configSelectedTriggerIndex = val
                    end,
                    get = function() return ele.configSelectedTriggerIndex end
                }
                triggerSettingOrder = triggerSettingOrder + 1
                triggerSettingArgs.deleteTrigger = {
                    order = triggerSettingOrder,
                    width = 1,
                    type = "execute",
                    name = L["Delete"],
                    confirm = true,
                    func = function()
                        if ele.configSelectedTriggerIndex then
                            table.remove(ele.triggers, ele.configSelectedTriggerIndex)
                            if ele.configSelectedTriggerIndex > #ele.triggers then
                                ele.configSelectedTriggerIndex = #ele.triggers
                            end
                            HbFrame:UpdateEframe(updateFrameConfig)
                            addon:UpdateOptions()
                        end
                    end
                }
                triggerSettingOrder = triggerSettingOrder + 1
            end
            local editTrigger
            if ele.configSelectedTriggerIndex then
                editTrigger = ele.triggers[ele.configSelectedTriggerIndex]
            end
            if editTrigger then
                triggerSettingArgs.selectType = {
                    order = triggerSettingOrder,
                    width = 2,
                    type = "select",
                    name = L["Select Trigger Type"],
                    values = const.TriggerTypeOptions,
                    set = function(_, val)
                        -- 当选择的触发器类型和当前触发器类型不一致的时候，重新设置触发器类型，并且需要删除之前触发器设置的条件和限制
                        if val ~= editTrigger.type then
                            editTrigger.type = val
                            editTrigger.condition = {}
                            editTrigger.confine = {}
                        end
                    end,
                    get = function() return editTrigger.type end
                }
                triggerSettingOrder = triggerSettingOrder + 1
            end
            if editTrigger and editTrigger.type == "aura" then
                local trigger = Trigger:ToAuraTriggerConfig(editTrigger)
                triggerSettingArgs.selectAuraType = {
                    order = triggerSettingOrder,
                    width = 1,
                    type = "select",
                    name = L["Select Aura Type"],
                    values = const.AuraTypeOptions,
                    set = function(_, val)
                        trigger.confine.type = val
                    end,
                    get = function() return trigger.confine.type end
                }
                triggerSettingOrder = triggerSettingOrder + 1
                triggerSettingArgs.selectAuraTarget = {
                    order = triggerSettingOrder,
                    width = 1,
                    type = "select",
                    name = L["Select Target"],
                    values = const.TriggerTargetOptions,
                    set = function(_, val)
                        trigger.confine.target = val
                    end,
                    get = function() return trigger.confine.target end
                }
                triggerSettingOrder = triggerSettingOrder + 1
                triggerSettingArgs.auraID = {
                    order = triggerSettingOrder,
                    width = 1,
                    type = "input",
                    name = L["Aura ID"],
                    validate = function(_, val)
                        if val == nil or val == "" or val == " " then
                            return false
                        end
                        if tonumber(val) == nil then
                            return false
                        end
                        return true
                    end,
                    set = function(_, val)
                        trigger.confine.spellId = tonumber(val)
                        HbFrame:UpdateEframe(updateFrameConfig)
                        addon:UpdateOptions()
                    end,
                    get = function()
                        if trigger.confine.spellId == nil then
                            return ""
                        else
                            return tostring(trigger.confine.spellId)
                        end
                    end
                }
                triggerSettingOrder = triggerSettingOrder + 1
            end
            if editTrigger and editTrigger.type == "self" then
                local trigger = Trigger:ToSelfTriggerConfig(editTrigger)
            end
            triggerSettingArgs.addTrigger = {
                order = triggerSettingOrder,
                width = 2,
                type = "execute",
                name = L["New Trigger"],
                func = function()
                    local trigger = Trigger:NewSelfTriggerConfig()
                    if ele.triggers == nil then
                        ele.triggers = {}
                    end
                    table.insert(ele.triggers, trigger)
                    ele.configSelectedTriggerIndex = #ele.triggers
                    HbFrame:UpdateEframe(updateFrameConfig)
                    addon:UpdateOptions()
                end
            }
        end

        -- 触发器条件设置：叶子元素可以使用
        if E:IsLeaf(ele) then
            local condSettingOrder = 1
            local condSettingArgs = {}
            local condSettingOptions = {
                type = "group",
                name = L["Condition Settings"],
                inline = true,
                order = 9,
                args = condSettingArgs
            }
            args.condSetting = condSettingOptions
            local condOptions = {}
            if ele.conditions then
                for condIndex, _ in ipairs(ele.conditions) do
                    table.insert(condOptions, L["Condition"] .. condIndex)
                end
            end
            if #condOptions > 0 then
                condSettingArgs.selectCondition = {
                    order = condSettingOrder,
                    width = 1,
                    type = "select",
                    name = "",
                    values = condOptions,
                    set = function(_, val)
                        ele.configSelectedConditionIndex = val
                    end,
                    get = function() return ele.configSelectedConditionIndex end
                }
                condSettingOrder = condSettingOrder + 1
                condSettingArgs.deleteCondition = {
                    order = condSettingOrder,
                    width = 1,
                    type = "execute",
                    name = L["Delete"],
                    confirm = true,
                    func = function()
                        if ele.configSelectedConditionIndex then
                            table.remove(ele.conditions, ele.configSelectedConditionIndex)
                            if ele.configSelectedConditionIndex > #ele.conditions then
                                ele.configSelectedConditionIndex = #ele.conditions
                            end
                            HbFrame:UpdateEframe(updateFrameConfig)
                            addon:UpdateOptions()
                        end
                    end
                }
                condSettingOrder = condSettingOrder + 1
            end
            local editCondtion
            if ele.configSelectedConditionIndex then
                editCondtion = ele.conditions[ele.configSelectedConditionIndex]
            end
            if editCondtion then
                local triggerOptions = {}
                if ele.triggers then
                    for k, t in ipairs(ele.triggers) do
                        triggerOptions[t.id] = L["Trigger"] .. tostring(k)
                    end
                end
                condSettingArgs.selectLeftTrigger = {
                    order = condSettingOrder,
                    width = 1,
                    type = "select",
                    name = L["Left Value Settings"],
                    values = triggerOptions,
                    set = function(_, val)
                        editCondtion.leftTriggerId = val
                        HbFrame:UpdateEframe(updateFrameConfig)
                        addon:UpdateOptions()
                    end,
                    get = function()
                        return editCondtion.leftTriggerId
                    end
                }
                condSettingOrder = condSettingOrder + 1
                local leftValOptions = {}
                if ele.triggers then
                    for _, t in ipairs(ele.triggers) do
                        if t.id == editCondtion.leftTriggerId then
                            if t.type then
                                leftValOptions = Trigger:GetConditions(t.type)
                            end
                        end
                    end
                end
                condSettingArgs.leftVal = {
                    order = condSettingOrder,
                    width = 1,
                    type = "select",
                    name = "",
                    values = leftValOptions,
                    set = function(_, val)
                        editCondtion.leftVal = val
                        HbFrame:UpdateEframe(updateFrameConfig)
                        addon:UpdateOptions()
                    end,
                    get = function() return editCondtion.leftVal end
                }
                condSettingOrder = condSettingOrder + 1
                -- 获取触发器对于条件设置的值，根据值来获取值的类型：是数字类型还是布尔类型，根据类型来选择右值如何选择。
                local leftValType = nil
                if leftValOptions and leftValOptions[editCondtion.leftVal] then
                    ---@type type
                    leftValType = leftValOptions[editCondtion.leftVal]
                end
                if leftValType ~= nil then
                    condSettingArgs.operate = {
                        order = condSettingOrder,
                        width = 1,
                        type = "select",
                        name = L["Operate"],
                        values = const.OperateOptions,
                        set = function(_, val)
                            editCondtion.operator = val
                            HbFrame:UpdateEframe(updateFrameConfig)
                            addon:UpdateOptions()
                        end,
                        get = function() return editCondtion.operator end
                    }
                    condSettingOrder = condSettingOrder + 1
                    if leftValType == "boolean" then
                        condSettingArgs.rightValue = {
                            order = condSettingOrder,
                            width = 1,
                            type = "select",
                            name = L["Right Value Settings"] ,
                            values = const.BooleanOptions,
                            set = function(_, val)
                                editCondtion.rightValue = val
                                HbFrame:UpdateEframe(updateFrameConfig)
                                addon:UpdateOptions()
                            end,
                            get = function() return editCondtion.rightValue end
                        }
                    else
                        condSettingArgs.rightValue = {
                            order = condSettingOrder,
                            width = 1,
                            type = "input",
                            name = L["Right Value Settings"] ,
                            validate = function(_, val)
                                if val == nil or val == "" or val == " " then
                                    return false
                                end
                                if tonumber(val) == nil then
                                    return false
                                end
                                return true
                            end,
                            set = function(_, val)
                                editCondtion.rightValue = tonumber(val)
                                HbFrame:UpdateEframe(updateFrameConfig)
                                addon:UpdateOptions()
                            end,
                            get = function()
                                if editCondtion.rightValue == nil then
                                    return ""
                                else
                                    return tostring(editCondtion.rightValue)
                                end
                            end
                        }
                    end
                    condSettingOrder = condSettingOrder + 1
                end
            end
            condSettingArgs.addCondition = {
                order = condSettingOrder,
                width = 2,
                type = "execute",
                name = L["New Condition"],
                func = function()
                    local condition = Condition:New()
                    if ele.conditions == nil then
                        ele.conditions = {}
                    end
                    table.insert(ele.conditions, condition)
                    ele.configSelectedConditionIndex = #ele.conditions
                    HbFrame:UpdateEframe(updateFrameConfig)
                    addon:UpdateOptions()
                end
            }
        end

        -- 物品条和物品条组递归查看子元素
        if ele.type == const.ELEMENT_TYPE.BAR_GROUP or ele.type == const.ELEMENT_TYPE.BAR then
            if ele.elements and #ele.elements then
                local tmpArgs = GetElementOptions(ele.elements, topEleConfig or ele,
                    copySelectGroups)
                for k, v in pairs(tmpArgs) do args[k] = v end
            end
        end
        -- 递归菜单
        local menuName = iconPath .. showTitle
        if not isRoot then
            menuName = "|cff00ff00" .. iconPath .. showTitle .. "|r"
        end
        eleArgs["elementMenu" .. i] = {
            type = 'group',
            name = menuName,
            args = args,
            order = i + 1
        }
    end
    return eleArgs
end

function ConfigOptions.ElementsOptions()
    local options = {
        type = 'group',
        name = L["Element Settings"],
        order = 2,
        args = {
            addBarGroup = {
                order = 1,
                width = 1,
                type = 'execute',
                name = L["New BarGroup"],
                func = function()
                    local barGroup = E:New(
                        Config.GetNewElementTitle(
                            L["BarGroup"],
                            addon.db.profile.elements),
                        const.ELEMENT_TYPE.BAR_GROUP)
                    table.insert(addon.db.profile.elements, barGroup)
                    HbFrame:AddEframe(barGroup)
                    AceConfigDialog:SelectGroup(addonName, "element",
                        "elementMenu" ..
                        #addon.db.profile.elements)
                end
            },
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
            addItemGroup = {
                order = 3,
                width = 1,
                type = 'execute',
                name = L["New ItemGroup"],
                func = function()
                    local itemGroup = E:NewItemGroup(
                        Config.GetNewElementTitle(
                            L["ItemGroup"],
                            addon.db.profile.elements))
                    table.insert(addon.db.profile.elements, itemGroup)
                    HbFrame:AddEframe(itemGroup)
                    AceConfigDialog:SelectGroup(addonName, "element",
                        "elementMenu" ..
                        #addon.db.profile.elements)
                end
            },
            addScript = {
                order = 4,
                width = 1,
                type = 'execute',
                name = L["New Script"],
                func = function()
                    local script = E:New(
                        Config.GetNewElementTitle(L["Script"],
                            addon.db
                            .profile
                            .elements),
                        const.ELEMENT_TYPE.SCRIPT)
                    table.insert(addon.db.profile.elements, script)
                    HbFrame:AddEframe(script)
                    AceConfigDialog:SelectGroup(addonName, "element",
                        "elementMenu" ..
                        #addon.db.profile.elements)
                end
            },
            addItem = {
                order = 5,
                width = 1,
                type = 'execute',
                name = L["New Item"],
                func = function()
                    local item = E:New(Config.GetNewElementTitle(L["Item"],
                            addon.db
                            .profile
                            .elements),
                        const.ELEMENT_TYPE.ITEM)
                    table.insert(addon.db.profile.elements, item)
                    HbFrame:AddEframe(item)
                    AceConfigDialog:SelectGroup(addonName, "element",
                        "elementMenu" ..
                        #addon.db.profile.elements)
                end
            },

            sapce1 = { order = 6, type = 'description', name = "\n\n\n" },
            itemHeading = {
                order = 7,
                type = 'header',
                name = L["Import Configuration"]
            },
            coverToggle = {
                order = 8,
                width = 2,
                type = 'toggle',
                name = L["Whether to overwrite the existing configuration."],
                set = function(_, _)
                    addon.G.tmpCoverConfig = not addon.G.tmpCoverConfig
                end,
                get = function(_) return addon.G.tmpCoverConfig end
            },
            importEditBox = {
                order = 9,
                type = 'input',
                name = L["Configuration string"],
                multiline = 20,
                width = "full",
                set = function(_, val)
                    addon.G.tmpImportElementConfigString = val
                    local errorMsg =
                        L["Import failed: Invalid configuration string."]
                    if val == nil or val == "" then
                        print(errorMsg)
                        return
                    end
                    local decodedData = LibDeflate:DecodeForPrint(val)
                    if decodedData == nil then
                        print(errorMsg)
                        return
                    end
                    local decompressedData =
                        LibDeflate:DecompressDeflate(decodedData)
                    if decompressedData == nil then
                        print(errorMsg)
                        return
                    end
                    ---@type boolean, ElementConfig
                    local success, eleConfig =
                        AceSerializer:Deserialize(decompressedData)
                    if not success then
                        print(errorMsg)
                        return
                    end
                    if type(eleConfig) ~= "table" then
                        print(errorMsg)
                        return
                    end
                    if eleConfig.title == nil then
                        print(errorMsg)
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
                        print(errorMsg)
                        return
                    end
                    if eleConfig.extraAttr == nil then
                        print(errorMsg)
                        return
                    end
                    if Config.IsIdDuplicated(eleConfig.id,
                            addon.db.profile.elements) then
                        --- 如果覆盖配置
                        if addon.G.tmpCoverConfig == true then
                            for i, ele in ipairs(addon.db.profile.elements) do
                                if ele.id == eleConfig.id then
                                    addon.db.profile.elements[i] = eleConfig
                                    addon:UpdateOptions()
                                    AceConfigDialog:SelectGroup(addonName,
                                        "element",
                                        "elementMenu" ..
                                        i)
                                    return true
                                end
                            end
                        else
                            eleConfig.id = U.String.GenerateID()
                        end
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
        name = "",
        handler = addon,
        type = 'group',
        args = {
            general = {
                order = 1,
                type = 'group',
                name = L["General Settings"],
                args = {
                    editFrame = {
                        order = 1,
                        width = 2,
                        type = "execute",
                        name = L["Toggle Edit Mode"],
                        func = function()
                            if addon.G.IsEditMode == false then
                                addon.G.IsEditMode = true
                                HbFrame:OpenEditMode()
                            else
                                addon.G.IsEditMode = false
                                HbFrame:CloseEditMode()
                            end
                        end
                    },
                    editFrameDesc = {
                        order = 2,
                        width = 2,
                        type = "description",
                        name = L["Left-click to drag and move, right-click to exit edit mode."]
                    },
                    versionSpace = {
                        order = 3,
                        width = 2,
                        type = "description",
                        name = "\n\n\n"
                    },
                    versionDesc = {
                        order = 4,
                        width = 2,
                        type = "description",
                        name = L["Version"] .. ": " .. "0.0.4"
                    }
                }
            },
            element = ConfigOptions.ElementsOptions()
        }
    }
    return options
end

function addon:OnInitialize()
    -- 检测是否安装了ElvUI
    local ElvUI = nil
    local ElvUISkins = nil
    ---@diagnostic disable-next-line: undefined-field
    if _G.ElvUI then
        ---@diagnostic disable-next-line: undefined-field
        ElvUI = unpack(_G.ElvUI) ---@type ElvUI
        ElvUISkins = ElvUI:GetModule("Skins") ---@type ElvUISkins
    end
    -- 全局变量
    ---@class GlobalValue
    self.G = {
        ElvUI = ElvUI,
        ElvUISkins = ElvUISkins,
        screenWidth = math.floor(GetScreenWidth()),   -- 屏幕宽度
        screenHeight = math.floor(GetScreenHeight()), -- 屏幕高度
        iconWidth = 32,
        iconHeight = 32,
        IsEditMode = false,
        tmpCoverConfig = false,             -- 默认选择不覆盖配置，默认创建副本
        tmpImportElementConfigString = nil, -- 导入elementconfig配置字符串
        tmpConfigString = nil,              -- 全局配置编辑字符串
        tmpNewItemType = nil,
        tmpNewItemVal = nil,
        tmpNewItem = { type = nil, id = nil, icon = nil, name = nil }, ---@type ItemAttr
        tmpNewText = nil, -- 添加文本
    }
    -- 注册数据库，添加分类设置
    self.db = LibStub("AceDB-3.0"):New("HappyButtonDB", {
        profile = {
            elements = {} ---@type ElementConfig[]
        }
    }, true)
    -- 注册选项表
    AceConfig:RegisterOptionsTable(addonName, ConfigOptions.Options)
    -- 在Blizzard界面选项中添加一个子选项
    self.optionsFrame = AceConfigDialog:AddToBlizOptions(addonName, addonName)
    -- 输入 /HappyButton 打开配置
    self:RegisterChatCommand(addonName, "OpenConfig")
    self:RegisterChatCommand("hb", "OpenConfig")
end

function addon:OpenConfig() AceConfigDialog:Open(addonName) end

function addon:UpdateOptions()
    -- 重新注册配置表来更新菜单栏
    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
end
