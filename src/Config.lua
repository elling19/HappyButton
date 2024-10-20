local addonName, _ = ... ---@type string, table

---@class HappyToolkit: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class Result: AceModule
local R = addon:GetModule("Result")

---@class HtFrame: AceModule
local HtFrame = addon:GetModule("HtFrame")

local L = LibStub("AceLocale-3.0"):GetLocale(addonName, false)

---@class E: AceModule
local E = addon:GetModule("Element")

---@class Utils: AceModule
local U = addon:GetModule('Utils')

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")
local LibDeflate = LibStub:GetLibrary("LibDeflate")
local AceGUI = LibStub("AceGUI-3.0")


---@param val string | nil
---@return Result
local function VerifyItemAttr(val)
    if val == nil or val == "" or val == " " then
        return R:Err("Please input effect title.")
    end
    local G = addon.G
    G.tmpNewItem = {}
    G.tmpNewItem.type = G.tmpNewItemType
    if G.tmpNewItem.type == nil then
        return R:Err(L["Please select item type."])
    end
    -- 添加物品逻辑
    if G.tmpNewItem.type == const.ITEM_TYPE.ITEM or G.tmpNewItem.type == const.ITEM_TYPE.EQUIPMENT or G.tmpNewItem.type == const.ITEM_TYPE.TOY then
        local itemID = C_Item.GetItemIDForItemInfo(val)
        if itemID then
            G.tmpNewItem.id = itemID
        else
            return R:Err(L["Unable to get the id, please check the input."])
        end
        local itemName = C_Item.GetItemNameByID(G.tmpNewItem.id)
        if itemName then
            G.tmpNewItem.name = itemName
        else
            return R:Err(L["Unable to get the name, please check the input."])
        end
        local itemIcon = C_Item.GetItemIconByID(G.tmpNewItem.id)
        if itemIcon then
            G.tmpNewItem.icon = itemIcon
        else
            return R:Err("Can not get the icon, please check your input.")
        end
    elseif G.tmpNewItem.type == const.ITEM_TYPE.SPELL then
        local spellID = C_Spell.GetSpellIDForSpellIdentifier(val)
        if spellID then
            G.tmpNewItem.id = spellID
        else
            return R:Err(L["Unable to get the id, please check the input."])
        end
        local spellName = C_Spell.GetSpellName(G.tmpNewItem.id)
        if spellName then
            G.tmpNewItem.name = spellName
        else
            return R:Err("Can not get the name, please check your input.")
        end
        local iconID, originalIconID = C_Spell.GetSpellTexture(G.tmpNewItem.id)
        if iconID then
            G.tmpNewItem.icon = iconID
        else
            return R:Err(L["Unable to get the icon, please check the input."])
        end
    elseif G.tmpNewItem.type == const.ITEM_TYPE.MOUNT then
        G.tmpNewItem.id = tonumber(val)
        if G.tmpNewItem.id == nil then
            for mountDisplayIndex = 1, C_MountJournal.GetNumDisplayedMounts() do
                local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight = C_MountJournal.GetDisplayedMountInfo(mountDisplayIndex)
                if name == val then
                    G.tmpNewItem.id = mountID
                    G.tmpNewItem.name = name
                    G.tmpNewItem.icon = icon
                    break
                end
            end
        end
        if G.tmpNewItem.id == nil then
            return R:Err(L["Unable to get the id, please check the input."])
        end
        if G.tmpNewItem.icon == nil then
            local name, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID = C_MountJournal.GetMountInfoByID(G.tmpNewItem.id)
            if name then
                G.tmpNewItem.id = mountID
                G.tmpNewItem.name = name
                G.tmpNewItem.icon = icon
            else
                return R:Err("Can not get the name, please check your input.")
            end
        end
    elseif G.tmpNewItem.type == const.ITEM_TYPE.PET then
        G.tmpNewItem.id = tonumber(val)
        if G.tmpNewItem.id == nil then
            local speciesId, petGUID = C_PetJournal.FindPetIDByName(val)
            if speciesId then
                G.tmpNewItem.id = speciesId
            end
        end
        if G.tmpNewItem.id == nil then
            return R:Err(L["Unable to get the id, please check the input."])
        end
        local speciesName, speciesIcon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable, creatureDisplayID = C_PetJournal.GetPetInfoBySpeciesID(G.tmpNewItem.id)
        if speciesName then
            G.tmpNewItem.name = speciesName
            G.tmpNewItem.icon = speciesIcon
        else
            return R:Err(L["Unable to get the name, please check the input."])
        end
    else
        return R:Err("Wrong type, please check your input.")
    end
    return R:Ok()
end

---@class ProfileConfig.ConfigTable
---@field name string
---@field profile table


---@class SourceAttrs
---@field mode integer
---@field replaceName boolean | nil
---@field displayUnLearned boolean | nil
---@field item ItemOfHtItem | nil
---@field itemList ItemOfHtItem[] | nil
---@field script string | nil
local SourceAttrs = {}


---@class Source
---@field title string
---@field type string
---@field attrs SourceAttrs
local Source = {}


---@class ProfileConfig
---@field tmpConfigString string
---@field GenerateNewProfileName fun(title: string): string
---@field ShowLoadConfirmation fun(title: string): nil
local ProfileConfig = {}

ProfileConfig.tmpConfigString = nil  -- 全局配置编辑字符串

function ProfileConfig.GenerateNewProfileName(title)
    local index = 1
    while addon.db.profiles[title .. "[" .. index .. "]"] do
        index = index + 1
    end
    return title .. "[" .. index .. "]"
end

function ProfileConfig.ShowLoadConfirmation(profileName)
    StaticPopupDialogs["LOAD_NEW_PROFILE"] = {
        text = L["Configuration imported. Would you like to switch to the new configuration?"] ,
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            addon.db:SetProfile(profileName)
            ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    StaticPopup_Show("LOAD_NEW_PROFILE")
end

---@class Config
---@field tmpCoverConfig boolean 
---@field tmpImportSourceString string | nil
---@field tmpNewItemType integer | nil
---@field tmpNewItemVal string | nil
---@field tmpNewItem ItemOfHtItem
---@field ShowExportDialog function
---@field IsTitleDuplicated function
---@field CreateDuplicateTitle function
local Config = {}

-- 临时变量
Config.tmpCoverConfig = false  -- 默认选择不覆盖配置，默认创建副本
Config.tmpImportSourceString = nil  -- 导入itemGroup配置字符串
Config.tmpNewItemType = nil
Config.tmpNewItemVal = nil
Config.tmpNewItem = {type=nil, id = nil, icon = nil, name = nil}

-- 展示导出配置框
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
    editBox:SetCallback("OnEnterPressed", function(widget)
        widget:ClearFocus()
    end)
    dialog:AddChild(editBox)
end

-- 检查标题是否重复的函数
function Config.IsTitleDuplicated(title, titleList)
    for _, _title in pairs(titleList) do
        if _title == title then
            return true
        end
    end
    return false
end

-- 创建副本标题的函数
function Config.CreateDuplicateTitle(title, titleList)
    local count = 1
    local newTitle = title .. " [" .. count .. "]"
    -- 检查新标题是否也重复，如果是则继续递增
    while Config.IsTitleDuplicated(newTitle, titleList) do
        count = count + 1
        newTitle = title .. " [" .. count .. "]"
    end
    return newTitle
end

local function getNewElementTitle(title, elements)
    local titleList = {}
    for _, ele in ipairs(elements) do
        table.insert(titleList, ele.title)
    end
    if Config.IsTitleDuplicated(title, titleList) then
        title = Config.CreateDuplicateTitle(title, titleList)
    end
    return title
end

---@class ConfigOptions
---@field ElementsOptions function
---@field BarOptions function
---@field SourceOptions function
---@field ConfigOptions function
---@field Options function
local ConfigOptions = {}

---@param elements ElementConfig[]
---@param isTopElement boolean 是否是顶层的菜单
---@param selectGroups table  配置界面选项卡位置
local function GetElementOptions(elements, isTopElement, selectGroups)
    local eleArgs = {}
    for i, ele in ipairs(elements) do
        local copySelectGroups = U.Table.DeepCopyList(selectGroups)
        table.insert(copySelectGroups, "elementMenu" .. i)
        local selectGroupsAfterAddItem = U.Table.DeepCopyList(copySelectGroups)
        table.insert(selectGroupsAfterAddItem, "elementMenu" .. (#ele.elements + 1))
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
        local order = 1
        args.delete = {
            order = order,
            width = 1,
            type = 'execute',
            name = L["Delete"],
            confirm=true,
            func = function()
                table.remove(elements, i)
                AceConfigDialog:SelectGroup(addonName, unpack(selectGroups))
            end,
        }
        order = order + 1
        args.export = {
            order=order,
            width=1,
            type = 'execute',
            name = L['Export'],
            func = function()
                local serializedData = AceSerializer:Serialize(ele)
                local compressedData = LibDeflate:CompressDeflate(serializedData)
                local base64Encoded = LibDeflate:EncodeForPrint(compressedData)
                Config.ShowExportDialog(base64Encoded)
            end,
        }
        order = order + 1
        args.sapce1 = {
            order = order,
            type = 'description',
            name = "\n"
        }
        order = order + 1
        args.elementHeader = {
            order = order,
            type = 'header',
            name = L["Element"],
        }
        order = order + 1
        args.title = {
            order = order,
            width=1,
            type = 'input',
            name = L['Element Title'],
            validate = function (_, val)
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
                addon:UpdateOptions()
            end,
        }
        order = order + 1
        args.icon = {
            order=order,
            width=1,
            type = 'input',
            name = L["Element Icon"],
            get = function() return ele.icon end,
            set = function(_, val)
                ele.icon = val
                addon:UpdateOptions()
            end,
        }
        order = order + 1
        if isTopElement then
            args.iconWidth = {
                step = 1,
                order=order,
                width=1,
                type = 'range',
                name = L["Icon Width"],
                min = 24,
                max = 128,
                get = function(_) return ele.iconWidth or addon.G.iconWidth end,
                set = function(_, value) ele.iconWidth = value end,
            }
            order = order + 1
            args.iconHeight = {
                step = 1,
                order=order,
                width=1,
                type = 'range',
                name = L["Icon Height"],
                min = 24,
                max = 128,
                get = function(_) return ele.iconHeight or addon.G.iconHeight end,
                set = function(_, value) ele.iconHeight = value end,
            }
            order = order + 1
        end
        if ele.type == const.ELEMENT_TYPE.ITEM then
            local item = E:ToItem(ele)
            local extraAttr = item.extraAttr
            if extraAttr.id == nil then
                args.itemType = {
                    order = order,
                    type = 'select',
                    name = L["Item Type"],
                    values = const.ItemTypeOptions,
                    set = function(_, val)
                        addon.G.tmpNewItemType = val
                    end,
                    get = function ()
                        return addon.G.tmpNewItemType
                    end
                }
                order = order + 1
                args.itemVal = {
                    order = order,
                    type = 'input',
                    name = L["Item name or item id"],
                    validate = function (_, val)
                        local r = VerifyItemAttr(val)
                        if r:is_err() then
                            return r:unwrap_err()
                        end
                        return true
                    end,
                    set = function(_, _)
                        item.extraAttr = U.Table.DeepCopyDict(addon.G.tmpNewItem)
                        addon.G.tmpNewItemVal = nil
                        addon.G.tmpNewItem = {}
                    end,
                    get = function ()
                        return addon.G.tmpNewItemVal
                    end
                }
                order = order + 1
            else
                args.id = {
                    order = order,
                    width=1,
                    type = 'input',
                    name = L["ID"],
                    disabled = true,
                    get = function() return tostring(extraAttr.id) end,
                }
                order = order + 1
                args.name = {
                    order = order,
                    width=1,
                    type = 'input',
                    name = L["Name"],
                    disabled = true,
                    get = function() return extraAttr.name end,
                }
                order = order + 1
                args.type = {
                    order = order,
                    width=2,
                    type = 'select',
                    name = L["Type"],
                    values = const.ItemTypeOptions,
                    disabled = true,
                    get = function() return extraAttr.type end,
                }
                order = order + 1
                args.space = {
                    order = order,
                    type = 'description',
                    name = "\n"
                }
                order = order + 1
            end
        end
        if isTopElement then
            if ele.type ~= const.ELEMENT_TYPE.ITEM then
                args.arrange = {
                    order = order,
                    width=2,
                    type = 'select',
                    name = L["Arrange"],
                    values = const.ArrangeOptions,
                    set = function(_, val)
                        ele.arrange = val
                    end,
                    get = function () return ele.arrange end,
                }
                order = order + 1
            end
        end
        if ele.type == const.ELEMENT_TYPE.SCRIPT then
            local script = E:ToScript(ele)
            args.edit = {
                order = order,
                type = 'input',
                name = L["Script"],
                multiline = 20,
                width = "full",
                validate = function (_, val)
                    local func, loadstringErr = loadstring("return " .. val)
                    if not func then
                        local errMsg = L["Illegal script."] .. " " .. loadstringErr
                        U.Print.PrintErrorText(errMsg)
                        return errMsg
                    end
                    local status, pcallErr = pcall(func())
                    if not status then
                        local errMsg = L["Illegal script."] .. " " .. tostring(pcallErr)
                        U.Print.PrintErrorText(errMsg)
                        return errMsg
                    end
                    return true
                end,
                set = function(_, val)
                    script.extraAttr.script = val
                    addon:UpdateOptions()
                end,
                get = function()
                    return script.extraAttr.script
                end,
            }
            order = order + 1
        end
        if isTopElement then
            args.sapce2 = {
                order = order,
                type = 'description',
                name = "\n"
            }
            order = order + 1
            args.displayHeader = {
                order = order,
                type = 'header',
                name = L["Display Rule"],
            }
            order = order + 1
            args.isDisplayMouseEnter = {
                order = order,
                width=2,
                type = 'toggle',
                name = L["Whether to show the bar menu when the mouse enter."],
                set = function(_, val) ele.isDisplayMouseEnter = val end,
                get = function(_) return ele.isDisplayMouseEnter end,
            }
            order = order + 1
            args.isDisplayFontToggle = {
                order = order,
                width=2,
                type = 'toggle',
                name = L["Whether to display text."],
                set = function(_, val) ele.isDisplayText = val end,
                get = function(_) return ele.isDisplayText end,
            }
            order = order + 1
            if ele.type == const.ELEMENT_TYPE.ITEM then
                local item = E:ToItem(ele)
                local extraAttr = item.extraAttr
                args.replaceNameToggle = {
                    order = order,
                    width=2,
                    type = 'toggle',
                    name = L["Wheter to use element title to replace item name."],
                    set = function(_, val) extraAttr.replaceName = val end,
                    get = function(_) return extraAttr.replaceName == true end,
                }
                order = order + 1
            end
        end
        if ele.type == const.ELEMENT_TYPE.BAR_GROUP then
            args.sapceAddChild = {
                order = order,
                type = 'description',
                name = "\n\n"
            }
            order = order + 1
            args.addChildHeader = {
                order = order,
                type = 'header',
                name = L["Add Child Elements"],
            }
            order = order + 1
            args.addBar = {
                order = order,
                width = 1,
                type = 'execute',
                name = L["New Bar"],
                func = function()
                    local bar = E:New(getNewElementTitle(L["Bar"], ele.elements), const.ELEMENT_TYPE.BAR)
                    table.insert(ele.elements, bar)
                    AceConfigDialog:SelectGroup(addonName, unpack(selectGroupsAfterAddItem))
                end,
            }
            order = order + 1
        end
        if ele.type == const.ELEMENT_TYPE.BAR then
            args.sapceAddChild = {
                order = order,
                type = 'description',
                name = "\n\n"
            }
            order = order + 1
            args.addChildHeader = {
                order = order,
                type = 'header',
                name = L["Add Child Elements"],
            }
            order = order + 1
            args.addItemGroup = {
                order = order,
                width = 1,
                type = 'execute',
                name = L["New ItemGroup"],
                func = function()
                    local itemGroup = E:NewItemGroup(getNewElementTitle(L["ItemGroup"], ele.elements))
                    table.insert(ele.elements, itemGroup)
                    AceConfigDialog:SelectGroup(addonName, unpack(selectGroupsAfterAddItem))
                end,
            }
            order = order + 1
            args.addScript = {
                order = order,
                width = 1,
                type = 'execute',
                name = L["New Script"],
                func = function()
                    local script = E:New(getNewElementTitle(L["Script"], ele.elements), const.ELEMENT_TYPE.SCRIPT)
                    table.insert(ele.elements, script)
                    AceConfigDialog:SelectGroup(addonName, unpack(selectGroupsAfterAddItem))
                end,
            }
            order = order + 1
            args.addItem = {
                order = order,
                width = 1,
                type = 'execute',
                name = L["New Item"],
                func = function()
                    local item = E:New(getNewElementTitle(L["Item"], ele.elements), const.ELEMENT_TYPE.ITEM)
                    table.insert(ele.elements, item)
                    AceConfigDialog:SelectGroup(addonName, unpack(selectGroupsAfterAddItem))
                end,
            }
            order = order + 1
        end
        if ele.type == const.ELEMENT_TYPE.ITEM_GROUP then
            local itemGroup = E:ToItemGroup(ele)
            args.mode = {
                order = order,
                width=2,
                type = 'select',
                name = L["Mode"],
                values = const.ItemsGroupModeOptions,
                set = function(_, val)
                    itemGroup.extraAttr.mode = val
                end,
                get = function () return itemGroup.extraAttr.mode end,
            }
            order = order + 1
            args.displayLearnedToggle = {
                order = order,
                width=2,
                type = 'toggle',
                name = L["Whether to display only learned or owned items."],
                set = function(_, val) itemGroup.extraAttr.displayUnLearned = not val end,
                get = function(_) return not itemGroup.extraAttr.displayUnLearned end,
            }
            order = order + 1
            args.replaceNameToggle = {
                order = order,
                width=2,
                type = 'toggle',
                name = L["Wheter to use element title to replace item name."],
                set = function(_, val) itemGroup.extraAttr.replaceName = val end,
                get = function(_) return itemGroup.extraAttr.replaceName == true end,
            }
            order = order + 1
            args.sapceAddChild = {
                order = order,
                type = 'description',
                name = "\n\n"
            }
            order = order + 1
            args.itemHeading = {
                order = order,
                type = 'header',
                name = L["Add Item"],
            }
            order = order + 1
            args.itemType = {
                order = order,
                type = 'select',
                name = L["Item Type"],
                values = const.ItemTypeOptions,
                set = function(_, val)
                    addon.G.tmpNewItemType = val
                end,
                get = function ()
                    return addon.G.tmpNewItemType
                end
            }
            order = order + 1
            args.itemVal = {
                order = order,
                type = 'input',
                name = L["Item name or item id"],
                validate = function (_, val)
                    local r = VerifyItemAttr(val)
                    if r:is_err() then
                        return r:unwrap_err()
                    end
                    return true
                end,
                set = function(_, _)
                    local newElement = E:New(getNewElementTitle(L["Item"], ele.elements), const.ELEMENT_TYPE.ITEM)
                    local item = E:ToItem(newElement)
                    item.extraAttr = U.Table.DeepCopyDict(addon.G.tmpNewItem)
                    table.insert(ele.elements, item)
                    AceConfigDialog:SelectGroup(addonName, unpack(selectGroupsAfterAddItem))
                    addon.G.tmpNewItemVal = nil
                    addon.G.tmpNewItem = {}
                end,
                get = function ()
                    return addon.G.tmpNewItemVal
                end
            }
            order = order + 1
        end
        if ele.elements and #ele.elements then
            local tmpArgs = GetElementOptions(ele.elements, false, copySelectGroups)
            for k, v in pairs(tmpArgs) do
                args[k] = v
            end
        end
        local menuName = iconPath .. showTitle
        if not isTopElement then
            menuName = "|cff00ff00" .. iconPath .. showTitle .. "|r"
        end
        eleArgs["elementMenu" .. i] = {
            type = 'group',
            name = menuName,
            args = args,
            order = i + 1,
        }
    end
    return eleArgs
end

function ConfigOptions.ElementsOptions()
    local options = {
        type = 'group',
        name = L["Element"] ,
        order = 2,
        args = {
            addBarGroup = {
                order = 1,
                width = 1,
                type = 'execute',
                name = L["New BarGroup"],
                func = function()
                    local barGroup = E:New(getNewElementTitle(L["BarGroup"], addon.db.profile.elements), const.ELEMENT_TYPE.BAR_GROUP)
                    table.insert(addon.db.profile.elements, barGroup)
                    AceConfigDialog:SelectGroup(addonName, "element", "elementMenu" .. #addon.db.profile.elements)
                end,
            },
            addBar = {
                order = 2,
                width = 1,
                type = 'execute',
                name = L["New Bar"],
                func = function()
                    local bar = E:New(getNewElementTitle(L["Bar"], addon.db.profile.elements), const.ELEMENT_TYPE.BAR)
                    table.insert(addon.db.profile.elements, bar)
                    AceConfigDialog:SelectGroup(addonName, "element", "elementMenu" .. #addon.db.profile.elements)
                end,
            },
            addItemGroup = {
                order = 3,
                width = 1,
                type = 'execute',
                name = L["New ItemGroup"],
                func = function()
                    local itemGroup = E:NewItemGroup(getNewElementTitle(L["ItemGroup"], addon.db.profile.elements))
                    table.insert(addon.db.profile.elements, itemGroup)
                    AceConfigDialog:SelectGroup(addonName, "element", "elementMenu" .. #addon.db.profile.elements)
                end,
            },
            addScript = {
                order = 4,
                width = 1,
                type = 'execute',
                name = L["New Script"],
                func = function()
                    local script = E:New(getNewElementTitle(L["Script"], addon.db.profile.elements), const.ELEMENT_TYPE.SCRIPT)
                    table.insert(addon.db.profile.elements, script)
                    AceConfigDialog:SelectGroup(addonName, "element", "elementMenu" .. #addon.db.profile.elements)
                end,
            },
            addItem = {
                order = 5,
                width = 1,
                type = 'execute',
                name = L["New Item"],
                func = function()
                    local item = E:New(getNewElementTitle(L["Item"], addon.db.profile.elements), const.ELEMENT_TYPE.ITEM)
                    table.insert(addon.db.profile.elements, item)
                    AceConfigDialog:SelectGroup(addonName, "element", "elementMenu" .. #addon.db.profile.elements)
                end,
            },
        },
    }
    local args = GetElementOptions(addon.db.profile.elements, true, {"element", })
    for k, v in pairs(args) do
        options.args[k] = v
    end
    return options
end

function ConfigOptions.BarOptions()
    local options = {
        type = 'group',
        name = L["Items Bar"],
        order=3,
        args = {
            add = {
                order = 1,
                type = 'execute',
                name = L["New Bar"],
                width = 2,
                func = function()
                    local newBarTitle = L["Default"]
                    local titleList = {}
                    for _, bar in ipairs(addon.db.profile.barList) do
                        table.insert(titleList, bar.title)
                    end
                    if Config.IsTitleDuplicated(newBarTitle, titleList) then
                        newBarTitle = Config.CreateDuplicateTitle(newBarTitle, titleList)
                    end
                    table.insert(addon.db.profile.barList, {
                        title = newBarTitle,
                        icon = nil,
                        posX = 0,
                        posY = 0,
                        displayMode=const.BAR_DISPLAY_MODE.Mount,
                        displayNameToggle=false,
                        sourceList = {}
                    })
                    addon:UpdateOptions()
                    AceConfigDialog:SelectGroup(addonName, "bar", "barMenu" .. #addon.db.profile.barList)
                end,
            },
        },
    }

    for i, bar in ipairs(addon.db.profile.barList) do
        local iconPath = "|T" .. (bar.icon or 134400) .. ":16|t"
        options.args["barMenu" .. i] = {
            type = 'group',
            name = "|cff00ff00" .. iconPath .. bar.title .. "|r",
            args = {
                title = {
                    order = 1,
                    width=2,
                    type = 'input',
                    name = L['Element Title'],
                    validate = function (_, val)
                        for _i, _bar in ipairs(addon.db.profile.barList) do
                            if _bar.title == val and i ~= _i then
                                return "repeat title, please input another one."
                            end
                        end
                        return true
                    end,
                    get = function() return bar.title end,
                    set = function(_, val)
                        bar.title = val
                        addon:UpdateOptions()
                    end,
                },
                icon = {
                    order=2,
                    width=1,
                    type = 'input',
                    name = L["Element Icon"],
                    get = function() return bar.icon end,
                    set = function(_, val)
                        bar.icon = val
                        addon:UpdateOptions()
                    end,
                },
                iconDisplay = {
                    order = 3,
                    width=1,
                    type = "description",
                    name = iconPath,
                    fontSize = "medium",
                },
                displayMode = {
                    order = 4,
                    width=2,
                    type = 'select',
                    name = L["Display"],
                    values = const.BarDisplayModeOptions,
                    get = function(_) return bar.displayMode end,
                    set = function(_, val) bar.displayMode = val end,
                },
                displayNameToggle = {
                    order = 5,
                    width=2,
                    type = 'toggle',
                    name = L["Whether to display item name."],
                    set = function(_, val) bar.isDisplayName = val end,
                    get = function(_) return bar.isDisplayName == true end,
                },
                space1 = {
                    order = 6,
                    type = 'description',
                    name = "\n"
                },
                sourceList = {
                    order = 7,
                    width=2,
                    type = 'multiselect',
                    name = L["Select items to display"],
                    values = function()
                        local values = {}
                        for _, source in ipairs(addon.db.profile.sourceList) do
                            values[source.title] = L[source.type] .. ": " .. source.title
                        end
                        return values
                    end,
                    get = function(_, key)
                        for _, thing in ipairs(bar.sourceList) do
                            if thing.title == key then
                                return true
                            end
                        end
                        return false
                    end,
                    set = function(_, key, value)
                        if value == true then
                            for _, thing in ipairs(bar.sourceList) do
                                if thing.title == key then
                                    return
                                end
                            end
                            table.insert(bar.sourceList, {title=key})
                        end
                        if value == false then
                            for index, thing in ipairs(bar.sourceList) do
                                if thing.title == key then
                                    table.remove(bar.sourceList, index)
                                    return
                                end
                            end
                        end
                    end,
                },
                space2 = {
                    order = 8,
                    type = 'description',
                    name = "\n"
                },
                delete = {
                    order = 9,
                    width=2,
                    type = 'execute',
                    name = L["Delete"],
                    confirm=true,
                    func = function()
                        table.remove(addon.db.profile.barList, i)
                        addon:UpdateOptions()
                    end,
                },
            },
            order = i + 1,
        }
    end
    return options
end

function ConfigOptions.SourceOptions()
    local options = {
        type = 'group',
        name = L["Items Source"],
        order=4,
        args = {
            addItemsGroup = {
                order = 1,
                type = 'execute',
                name = L["New Items Group"],
                width = 1,
                func = function()
                    local newItemsGroupTitle = L["Default"]
                    local titleList = {}
                    for _, source in ipairs(addon.db.profile.sourceList) do
                        table.insert(titleList, source.title)
                    end
                    if Config.IsTitleDuplicated(newItemsGroupTitle, titleList) then
                        newItemsGroupTitle = Config.CreateDuplicateTitle(newItemsGroupTitle, titleList)
                    end
                    ---@type Source
                    local source = {title=newItemsGroupTitle, type="ITEM_GROUP", attrs={ mode=const.ITEMS_GROUP_MODE.MULTIPLE, replaceName=false, displayUnLearned=false, itemList={} }}
                    table.insert(addon.db.profile.sourceList, source)
                    addon:UpdateOptions()
                    AceConfigDialog:SelectGroup(addonName, "source", "SourceMenu" .. #addon.db.profile.sourceList)
                end,
            },
            addScript = {
                order = 2,
                type = 'execute',
                name = L["New Script"],
                width = 1,
                func = function()
                    local newScriptTitle = L["Default"]
                    local titleList = {}
                    for _, source in ipairs(addon.db.profile.sourceList) do
                        table.insert(titleList, source.title)
                    end
                    if Config.IsTitleDuplicated(newScriptTitle, titleList) then
                        newScriptTitle = Config.CreateDuplicateTitle(newScriptTitle, titleList)
                    end
                    table.insert(addon.db.profile.sourceList, {title=newScriptTitle, type="SCRIPT", attrs={ script=nil }})
                    addon:UpdateOptions()
                    AceConfigDialog:SelectGroup(addonName, "source", "SourceMenu" .. #addon.db.profile.sourceList)
                end,
            },
            sapce1 = {
                order = 3,
                type = 'description',
                name = "\n\n\n"
            },
            itemHeading = {
                order = 4,
                type = 'header',
                name = L["Import Configuration"],
            },
            coverToggle = {
                order = 4,
                width=2,
                type = 'toggle',
                name = L["Whether to overwrite the existing configuration."] ,
                set = function(_, _) Config.tmpCoverConfig = not Config.tmpCoverConfig end,
                get = function(_) return Config.tmpCoverConfig end,
            },
            importEditBox = {
                order = 4,
                type = 'input',
                name = L["Configuration string"],
                multiline = 20,
                width = "full",
                set = function(_, val)
                    Config.tmpImportSourceString = val
                    local errorMsg = L["Import failed: Invalid configuration string."]
                    if val == nil or val == "" then
                        print(errorMsg)
                        return
                    end
                    local decodedData = LibDeflate:DecodeForPrint(val)
                    if decodedData == nil then
                        print(errorMsg)
                        return
                    end
                    local decompressedData = LibDeflate:DecompressDeflate(decodedData)
                    if decompressedData == nil then
                        print(errorMsg)
                        return
                    end
                    local success, configTable = AceSerializer:Deserialize(decompressedData)
                    if not success then
                        print(errorMsg)
                        return
                    end
                    -- 校验反序列是否正确
                    -- table需要包含:
                    -- {title=val, type="ITEM_GROUP", attrs={ mode=const.ITEMS_GROUP_MODE.MULTIPLE, replaceName=false, displayUnLearned=false, itemList={} }}
                    -- {title=val, type="SCRIPT", attrs={script=nil}}
                    if type(configTable) ~= "table" then
                        print(errorMsg)
                        return
                    end
                    if configTable.title == nil then
                        print(errorMsg)
                        return
                    end
                    if configTable.type ~= "ITEM_GROUP" and configTable.type ~= "SCRIPT" then
                        print(errorMsg)
                        return
                    end
                    if configTable.attrs == nil then
                        print(errorMsg)
                        return
                    end
                    if configTable.type == "ITEM_GROUP" then
                        if configTable.attrs.mode == nil or configTable.attrs.itemList == nil then
                            print(errorMsg)
                            return
                        end
                        if type(configTable.attrs.itemList) ~= "table" then
                            print(errorMsg)
                            return
                        end
                    end
                    if configTable.type == "SCRIPT" then
                        if configTable.attrs.script == nil then
                            print(errorMsg)
                            return
                        end
                    end
                    -- 判断标题是否重复
                    local titleList = {}
                    for _, source in ipairs(addon.db.profile.sourceList) do
                        table.insert(titleList, source.title)
                    end
                    if Config.IsTitleDuplicated(configTable.title, titleList) then
                        if Config.tmpCoverConfig == true then
                            for i, itemGroup in ipairs(addon.db.profile.sourceList) do
                                if itemGroup.title == configTable.title then
                                    addon.db.profile.sourceList[i] = configTable
                                    addon:UpdateOptions()
                                    AceConfigDialog:SelectGroup(addonName, "source", "SourceMenu" .. i)
                                    return true
                                end
                            end
                        else
                            configTable.title = Config.CreateDuplicateTitle(configTable.title, titleList)
                        end
                    end
                    table.insert(addon.db.profile.sourceList, configTable)
                    addon:UpdateOptions()
                    AceConfigDialog:SelectGroup(addonName, "source", "SourceMenu" .. #addon.db.profile.sourceList)
                end,
                get = function (_) return Config.tmpImportSourceString end
            },
        },
    }
    for i, source in ipairs(addon.db.profile.sourceList) do
        if source.type == "SCRIPT" then
            options.args["SourceMenu" .. i] = {
                type = 'group',
                name = "|cff00ff00" .. source.title .. "|r",
                args = {
                    title = {
                        order = 1,
                        width=1,
                        type = 'input',
                        name = L['Title'],
                        validate = function (_, val)
                            for _i, _source in ipairs(addon.db.profile.sourceList) do
                                if _source.title == val and i ~= _i then
                                    return "repeat title, please input another one."
                                end
                            end
                            return true
                        end,
                        get = function() return source.title end,
                        set = function(_, val)
                            -- 在bar中修改对应的script
                            for _, bar in ipairs(addon.db.profile.barList) do
                                if bar.sourceList ~= nil then
                                    for index, thing in ipairs(bar.sourceList) do
                                        if thing.title == source.title then
                                            bar.sourceList[index].title = val
                                            break
                                        end
                                    end
                                end
                            end
                            source.title = val
                            addon:UpdateOptions()
                        end,
                    },
                    export = {
                        order=2,
                        width=1,
                        type = 'execute',
                        name = L['Export'],
                        func = function()
                            local serializedData = AceSerializer:Serialize(source)
                            local compressedData = LibDeflate:CompressDeflate(serializedData)
                            local base64Encoded = LibDeflate:EncodeForPrint(compressedData)
                            Config.ShowExportDialog(base64Encoded)
                        end,
                    },
                    edit = {
                        order = 3,
                        type = 'input',
                        name = L["Script"],
                        multiline = 20,
                        width = "full",
                        validate = function (_, val)
                            local func, err = loadstring("return " .. val)  -- 加载脚本，并确保返回函数
                            if not func then
                                local errMsg = L["Illegal script."] .. " " .. err
                                U.Print.PrintErrorText(errMsg)
                                return errMsg
                            end
                            local status, err = pcall(func())
                            if not status then
                                local errMsg = L["Illegal script."] .. " " .. tostring(err)
                                U.Print.PrintErrorText(errMsg)
                                return errMsg
                            end
                            return true
                        end,
                        set = function(_, val)
                            source.attrs.script = val
                            addon:UpdateOptions()
                        end,
                        get = function()
                            return source.attrs.script
                        end,
                    },
                    delete = {
                        order = 4,
                        width=2,
                        type = 'execute',
                        name = L["Delete"],
                        confirm=true,
                        func = function()
                            table.remove(addon.db.profile.sourceList, i)
                            -- 从bar中删除对应的script
                            for _, bar in ipairs(addon.db.profile.barList) do
                                if bar.sourceList ~= nil then
                                    for index, thing in ipairs(bar.sourceList) do
                                        if thing.title == source.title then
                                            table.remove(bar.sourceList, index)
                                            break
                                        end
                                    end
                                end
                            end
                            addon:UpdateOptions()
                        end,
                    }
                },
                order = i + 1,
            }
        end
        if source.type == "ITEM_GROUP" then
            options.args["SourceMenu" .. i] = {
                type = 'group',
                name = "|cff00ff00" .. source.title .. "|r",
                args = {
                    title = {
                        order = 1,
                        width=1,
                        type = 'input',
                        name = L['Element Title'],
                        validate = function (_, val)
                            for _i, _source in ipairs(addon.db.profile.sourceList) do
                                if _source.title == val and i ~= _i then
                                    return "repeat title, please input another one."
                                end
                            end
                            return true
                        end,
                        get = function() return source.title end,
                        set = function(_, val)
                            -- 在bar中修改对应的itemGroup
                            for _, bar in ipairs(addon.db.profile.sourceList) do
                                if bar.sourceList ~= nil then
                                    for index, thing in ipairs(bar.sourceList) do
                                        if thing.title == source.title then
                                            bar.sourceList[index].title = val
                                            break
                                        end
                                    end
                                end
                            end
                            source.title = val
                            addon:UpdateOptions()
                        end,
                    },
                    export = {
                        order=2,
                        width=1,
                        type = 'execute',
                        name = L['Export'],
                        func = function()
                            local serializedData = AceSerializer:Serialize(source)
                            local compressedData = LibDeflate:CompressDeflate(serializedData)
                            local base64Encoded = LibDeflate:EncodeForPrint(compressedData)
                            Config.ShowExportDialog(base64Encoded)
                        end,
                    },
                    mode = {
                        order = 3,
                        width=2,
                        type = 'select',
                        name = L["Mode"],
                        values = const.ItemsGroupModeOptions,
                        set = function(_, val)
                            source.attrs.mode = val
                        end,
                        get = function () return source.attrs.mode end,
                    },
                    displayLearnedToggle = {
                        order = 4,
                        width=2,
                        type = 'toggle',
                        name = L["Whether to display only learned or owned items."],
                        set = function(_, val) source.attrs.displayUnLearned = not val end,
                        get = function(_) return not source.attrs.displayUnLearned end,
                    },
                    replaceNameToggle = {
                        order = 5,
                        width=2,
                        type = 'toggle',
                        name = L["Wheter to use element title to replace item name."],
                        set = function(_, val) source.attrs.replaceName = val end,
                        get = function(_) return source.attrs.replaceName == true end,
                    },
                    sapce1 = {
                        order = 6,
                        type = 'description',
                        name = "\n\n\n"
                    },
                    itemHeading = {
                        order = 7,
                        type = 'header',
                        name = L["Add Item"],
                    },
                    itemType = {
                        order = 8,
                        type = 'select',
                        name = L["Item Type"],
                        values = const.ItemTypeOptions,
                        set = function(_, val)
                            Config.tmpNewItemType = val
                        end,
                        get = function ()
                            return Config.tmpNewItemType
                        end
                    },
                    itemVal = {
                        order = 9,
                        type = 'input',
                        name = L["Item name or item id"],
                        validate = function (_, val)
                            local r = VerifyItemAttr(val)
                            if r:is_err() then
                                return r:unwrap_err()
                            end
                            return true
                        end,
                        set = function(_, _)
                            Config.tmpNewItemVal = nil
                            table.insert(source.attrs.itemList, U.Table.DeepCopyDict(Config.tmpNewItem))
                            Config.tmpNewItem = {}
                            addon:UpdateOptions()
                            AceConfigDialog:SelectGroup(addonName, "source", "SourceMenu" .. i, "item" .. #source.attrs.itemList)
                        end,
                        get = function ()
                            return Config.tmpNewItemVal
                        end
                    },
                    sapce2 = {
                        order = 10,
                        type = 'description',
                        name = "\n\n\n"
                    },
                    delete = {
                        order = 11,
                        width=2,
                        type = 'execute',
                        name = L['Delete'],
                        confirm=true,
                        func = function()
                            table.remove(addon.db.profile.sourceList, i)
                            -- 从bar中删除对应的itemGroup
                            for _, bar in ipairs(addon.db.profile.barList) do
                                if bar.sourceList ~= nil then
                                    for index, thing in ipairs(bar.sourceList) do
                                        if thing.title == source.title then
                                            table.remove(bar.sourceList, index)
                                            break
                                        end
                                    end
                                end
                            end
                            addon:UpdateOptions()
                        end,
                    },
                },
                order = i + 1,
            }
            -- 动态生成 itemList，每个 item 作为左侧菜单栏中的独立组
            for j, item in ipairs(source.attrs.itemList) do
                local iconPath = "|T" .. (item.icon or 134400) .. ":16|t"
                options.args["SourceMenu" .. i].args["item" .. j] = {
                    type = 'group',
                    name = iconPath .. item.name,
                    args = {
                        id = {
                            order = 1,
                            width=1,
                            type = 'input',
                            name = L["ID"],
                            disabled = true,
                            get = function() return tostring(item.id) end,
                        },
                        iconDisplay = {
                            order = 2,
                            width=1,
                            type = "description",
                            name = iconPath,
                            fontSize = "medium",
                        },
                        name = {
                            order = 3,
                            width=1,
                            type = 'input',
                            name = L["Name"],
                            disabled = true,
                            get = function() return item.name end,
                        },
                        alias ={
                            order = 4,
                            width=1,
                            type = 'input',
                            name = L["Alias"],
                            get = function() return item.alias end,
                            validate = function (_, val) 
                                if val == nil or val == "" or val == " " then
                                    return L["Illegal value."]
                                end
                                return true
                            end,
                            set = function (_, val)
                                item.alias = val
                                addon:UpdateOptions()
                            end
                        },
                        type = {
                            order = 5,
                            width=2,
                            type = 'select',
                            name = L["Type"],
                            values = const.ItemTypeOptions,
                            disabled = true,
                            get = function() return item.type end,
                        },
                        space = {
                            order = 6,
                            type = 'description',
                            name = "\n"
                        },
                        delete = {
                            order = 7,
                            width=2,
                            type = 'execute',
                            name = L["Delete"],
                            confirm=true,
                            func = function()
                                table.remove(source.attrs.itemList, j)
                                addon:UpdateOptions()
                                AceConfigDialog:SelectGroup(addonName, "source", "SourceMenu" .. i)
                            end,
                        },
                    },
                    order = j + 1,
                }
            end
        end
    end
    return options
end

function ConfigOptions.ConfigOptions()
    local profiles = AceDBOptions:GetOptionsTable(addon.db)
    profiles.args.importExport = {
        type = "group",
        order = -1,
        name = L["Import/Export Configuration"] ,
        inline = true,
        args = {
            export = {
                type = "execute",
                name = L["Export"],
                func = function()
                    ---@type ProfileConfig.ConfigTable
                    local configTable = {
                        name=addon.db:GetCurrentProfile() or L["Default"],
                        profile=addon.db.profile
                    }
                    local serializedData = AceSerializer:Serialize(configTable)
                    local compressedData = LibDeflate:CompressDeflate(serializedData)
                    ProfileConfig.tmpConfigString = LibDeflate:EncodeForPrint(compressedData)
                end,
                order = 1,
            },
            import = {
                order = 2,
                type = 'input',
                name = L["Configuration String Edit Box"],
                multiline = 20,
                width = "full",
                get = function () return ProfileConfig.tmpConfigString end,
                set = function(_, val)
                    if val == nil or val == "" then
                        print(L["Import failed: Invalid configuration string."])
                        return
                    end
                    local decodedData = LibDeflate:DecodeForPrint(val)
                    if decodedData == nil then
                        print(L["Import failed: Invalid configuration string."])
                        return
                    end
                    local decompressedData = LibDeflate:DecompressDeflate(decodedData)
                    if decompressedData == nil then
                        print(L["Import failed: Invalid configuration string."])
                        return
                    end
                    ---@type boolean, ProfileConfig.ConfigTable 
                    local success, configTable = AceSerializer:Deserialize(decompressedData)
                    if not success then
                        print(L["Import failed: Invalid configuration string."])
                        return
                    end
                    local newProfileName = ProfileConfig.GenerateNewProfileName(configTable.name or L["Default"])
                    addon.db.profiles[newProfileName] = configTable.profile
                    Config.tmpImportSourceString = nil
                    ProfileConfig.ShowLoadConfirmation(newProfileName)
                end,
            },
        },
    }
    return profiles
end

function ConfigOptions.Options()
    local options = {
        name = "",
        handler = addon,
        type = 'group',
        args = {
            general = {
                order=1,
                type = 'group',
                name = L["General"],
                args = {
                    editFrame = {
                        order = 1,
                        width=2,
                        type = "execute",
                        name = L["Edit Mode"],
                        func = function()
                            if addon.G.IsEditMode == false then
                                addon.G.IsEditMode = true
                                HtFrame:OpenEditMode()
                            end
                        end,
                    },
                    editFrameDesc = {
                        order = 2,
                        width = 2,
                        type = "description",
                        name = L["Left-click to drag and move, right-click to exit edit mode."]
                    },
                },
            },
            element=ConfigOptions.ElementsOptions(),
            profiles = ConfigOptions.ConfigOptions()
        },
    }
    return options
end

function addon:OnInitialize()

    -- 全局变量
    ---@class GlobalValue
    self.G = {
        iconWidth = 32,
        iconHeight = 32,
        IsEditMode = false,
        tmpNewItemType = nil,
        tmpNewItemVal = nil,
        tmpNewItem = {type=nil, id = nil, icon = nil, name = nil}  ---@type ItemAttr
    }
    -- 注册数据库，添加分类设置
    self.db = LibStub("AceDB-3.0"):New("HappyToolkitDB", {
        profile = {
            elements = {},  ---@type ElementConfig[]
        }
    }, true)
    -- 注册选项表
    AceConfig:RegisterOptionsTable(addonName, ConfigOptions.Options)
    -- 在Blizzard界面选项中添加一个子选项
    self.optionsFrame = AceConfigDialog:AddToBlizOptions(addonName, addonName)
    -- 输入 /HappyToolkit 打开配置
    self:RegisterChatCommand(addonName, "OpenConfig")
end

function addon:OpenConfig()
    AceConfigDialog:Open(addonName)
end


function addon:UpdateOptions()
    -- 重新注册配置表来更新菜单栏
    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
end
