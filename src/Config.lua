local _, HT = ...
---@type HtItem
local HtItem = HT.HtItem
---@type Utils
local U = HT.Utils

HT.AceAddonName = "HappyToolkit"
HT.AceAddonConfigDB = "HappyToolkitDB"
HT.AceAddon = LibStub("AceAddon-3.0"):NewAddon(HT.AceAddonName, "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("HappyToolkit", false)
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")
local LibDeflate = LibStub:GetLibrary("LibDeflate")
local AceGUI = LibStub("AceGUI-3.0")

---@class ProfileConfig.ConfigTable
---@field name string
---@field profile table


---@class IconSourceAttrs
---@field mode integer
---@field replaceName boolean | nil
---@field displayUnLearned boolean | nil
---@field item ItemOfHtItem | nil
---@field itemList ItemOfHtItem[] | nil
---@field script string | nil
local IconSourceAttrs = {}


---@class IconSource
---@field title string
---@field type string
---@field attrs IconSourceAttrs
local IconSource = {}


---@class ProfileConfig
---@field tmpConfigString string
---@field GenerateNewProfileName fun(title: string): string
---@field ShowLoadConfirmation fun(title: string): nil
local ProfileConfig = {}

ProfileConfig.tmpConfigString = nil  -- 全局配置编辑字符串

function ProfileConfig.GenerateNewProfileName(title)
    local index = 1
    while HT.AceAddon.db.profiles[title .. "[" .. index .. "]"] do
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
            HT.AceAddon.db:SetProfile(profileName)
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
Config.tmpNewItem = {type=nil, id = nil, icon = nil, name = nil, alias = nil}

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


---@class ConfigOptions
---@field CategoryOptions function
---@field IconSourceOptions function
---@field ConfigOptions function
---@field Options function
local ConfigOptions = {}

function ConfigOptions.CategoryOptions()
    local options = {
        type = 'group',
        name = L["Category"],
        args = {
            add = {
                order = 1,
                type = 'execute',
                name = L["New Category"],
                width = 2,
                func = function()
                    local newCategoryTitle = L["Default"]
                    local titleList = {}
                    for _, category in ipairs(HT.AceAddon.db.profile.categoryList) do
                        table.insert(titleList, category.title)
                    end
                    if Config.IsTitleDuplicated(newCategoryTitle, titleList) then
                        newCategoryTitle = Config.CreateDuplicateTitle(newCategoryTitle, titleList)
                    end
                    table.insert(HT.AceAddon.db.profile.categoryList, { title = newCategoryTitle, icon = nil, sourceList = {} })
                    HT.AceAddon:UpdateOptions()
                    AceConfigDialog:SelectGroup(HT.AceAddonName, "category", "categoryMenu" .. #HT.AceAddon.db.profile.categoryList)
                end,
            },
        },
    }

    for i, category in ipairs(HT.AceAddon.db.profile.categoryList) do
        options.args["categoryMenu" .. i] = {
            type = 'group',
            name = "|cff00ff00" .. category.title .. "|r",
            args = {
                title = {
                    order = 1,
                    width=2,
                    type = 'input',
                    name = L["Title"],
                    validate = function (_, val)
                        for _i, _category in ipairs(HT.AceAddon.db.profile.categoryList) do
                            if _category.title == val and i ~= _i then
                                return "repeat title, please input another one."
                            end
                        end
                        return true
                    end,
                    get = function() return category.title end,
                    set = function(_, val)
                        category.title = val
                        HT.AceAddon:UpdateOptions()
                    end,
                },
                icon = {
                    order=2,
                    width=2,
                    type = 'input',
                    name = L["Icon"],
                    get = function() return category.icon end,
                    set = function(_, val)
                        category.icon = val
                        HT.AceAddon:UpdateOptions()
                    end,
                },
                displayToogle = {
                    order = 3,
                    width=2,
                    type = 'toggle',
                    name = L["Display"] ,
                    set = function(_, _) category.isDisplay = not category.isDisplay end,
                    get = function(_) return category.isDisplay == true end,
                },
                space1 = {
                    order = 4,
                    type = 'description',
                    name = "\n"
                },
                iconSourceList = {
                    order = 5,
                    width=2,
                    type = 'multiselect',
                    name = L["Select items to display"],
                    values = function()
                        local values = {}
                        for _, source in ipairs(HT.AceAddon.db.profile.iconSourceList) do
                            values[source.title] = L[source.type] .. ": " .. source.title
                        end
                        return values
                    end,
                    get = function(_, key)
                        for _, thing in ipairs(category.sourceList) do
                            if thing.title == key then
                                return true
                            end
                        end
                        return false
                    end,
                    set = function(_, key, value)
                        if value == true then
                            for _, thing in ipairs(category.sourceList) do
                                if thing.title == key then
                                    return
                                end
                            end
                            table.insert(category.sourceList, {title=key})
                        end
                        if value == false then
                            for index, thing in ipairs(category.sourceList) do
                                if thing.title == key then
                                    table.remove(category.sourceList, index)
                                    return
                                end
                            end
                        end
                    end,
                },
                space2 = {
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
                        table.remove(HT.AceAddon.db.profile.categoryList, i)
                        HT.AceAddon:UpdateOptions()
                    end,
                },
            },
            order = i + 1,
        }
    end
    return options
end

function ConfigOptions.IconSourceOptions()
    local options = {
        type = 'group',
        name = L["IconSource"],
        args = {
            addItemGroup = {
                order = 1,
                type = 'execute',
                name = L["New ItemGroup"],
                width = 1,
                func = function()
                    local newItemGroupTitle = L["Default"]
                    local titleList = {}
                    for _, source in ipairs(HT.AceAddon.db.profile.iconSourceList) do
                        table.insert(titleList, source.title)
                    end
                    if Config.IsTitleDuplicated(newItemGroupTitle, titleList) then
                        newItemGroupTitle = Config.CreateDuplicateTitle(newItemGroupTitle, titleList)
                    end
                    ---@type IconSource
                    local iconSource = {title=newItemGroupTitle, type="ITEM_GROUP", attrs={ mode=HtItem.ItemGroupMode.MULTIPLE, replaceName=false, displayUnLearned=false, itemList={} }}
                    table.insert(HT.AceAddon.db.profile.iconSourceList, iconSource)
                    HT.AceAddon:UpdateOptions()
                    AceConfigDialog:SelectGroup(HT.AceAddonName, "iconSource", "SourceMenu" .. #HT.AceAddon.db.profile.iconSourceList)
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
                    for _, source in ipairs(HT.AceAddon.db.profile.iconSourceList) do
                        table.insert(titleList, source.title)
                    end
                    if Config.IsTitleDuplicated(newScriptTitle, titleList) then
                        newScriptTitle = Config.CreateDuplicateTitle(newScriptTitle, titleList)
                    end
                    table.insert(HT.AceAddon.db.profile.iconSourceList, {title=newScriptTitle, type="SCRIPT", attrs={ script=nil }})
                    HT.AceAddon:UpdateOptions()
                    AceConfigDialog:SelectGroup(HT.AceAddonName, "iconSource", "SourceMenu" .. #HT.AceAddon.db.profile.iconSourceList)
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
                name = L["Overwrite the existing configuration."] ,
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
                    -- {title=val, type="ITEM_GROUP", attrs={ mode=HtItem.ItemGroupMode.MULTIPLE, replaceName=false, displayUnLearned=false, itemList={} }}
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
                    for _, iconSource in ipairs(HT.AceAddon.db.profile.iconSourceList) do
                        table.insert(titleList, iconSource.title)
                    end
                    if Config.IsTitleDuplicated(configTable.title, titleList) then
                        if Config.tmpCoverConfig == true then
                            for i, itemGroup in ipairs(HT.AceAddon.db.profile.iconSourceList) do
                                if itemGroup.title == configTable.title then
                                    HT.AceAddon.db.profile.iconSourceList[i] = configTable
                                    HT.AceAddon:UpdateOptions()
                                    AceConfigDialog:SelectGroup(HT.AceAddonName, "iconSource", "SourceMenu" .. i)
                                    return true
                                end
                            end
                        else
                            configTable.title = Config.CreateDuplicateTitle(configTable.title, titleList)
                        end
                    end
                    table.insert(HT.AceAddon.db.profile.iconSourceList, configTable)
                    HT.AceAddon:UpdateOptions()
                    AceConfigDialog:SelectGroup(HT.AceAddonName, "iconSource", "SourceMenu" .. #HT.AceAddon.db.profile.iconSourceList)
                end,
                get = function (_) return Config.tmpImportSourceString end
            },
        },
    }
    for i, source in ipairs(HT.AceAddon.db.profile.iconSourceList) do
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
                            for _i, _source in ipairs(HT.AceAddon.db.profile.iconSourceList) do
                                if _source.title == val and i ~= _i then
                                    return "repeat title, please input another one."
                                end
                            end
                            return true
                        end,
                        get = function() return source.title end,
                        set = function(_, val)
                            -- 在category中修改对应的script
                            for _, category in ipairs(HT.AceAddon.db.profile.categoryList) do
                                if category.sourceList ~= nil then
                                    for index, thing in ipairs(category.sourceList) do
                                        if thing.title == source.title then
                                            category.sourceList[index].title = val
                                            break
                                        end
                                    end
                                end
                            end
                            source.title = val
                            HT.AceAddon:UpdateOptions()
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
                        set = function(_, val)
                            source.attrs.script = val
                            HT.AceAddon:UpdateOptions()
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
                            table.remove(HT.AceAddon.db.profile.iconSourceList, i)
                            -- 从category中删除对应的script
                            for _, category in ipairs(HT.AceAddon.db.profile.categoryList) do
                                if category.sourceList ~= nil then
                                    for index, thing in ipairs(category.sourceList) do
                                        if thing.title == source.title then
                                            table.remove(category.sourceList, index)
                                            break
                                        end
                                    end
                                end
                            end
                            HT.AceAddon:UpdateOptions()
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
                        name = L['Title'],
                        validate = function (_, val)
                            for _i, _source in ipairs(HT.AceAddon.db.profile.iconSourceList) do
                                if _source.title == val and i ~= _i then
                                    return "repeat title, please input another one."
                                end
                            end
                            return true
                        end,
                        get = function() return source.title end,
                        set = function(_, val)
                            -- 在category中修改对应的itemGroup
                            for _, category in ipairs(HT.AceAddon.db.profile.iconSourceList) do
                                if category.sourceList ~= nil then
                                    for index, thing in ipairs(category.sourceList) do
                                        if thing.title == source.title then
                                            category.sourceList[index].title = val
                                            break
                                        end
                                    end
                                end
                            end
                            source.title = val
                            HT.AceAddon:UpdateOptions()
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
                        values = HtItem.ItemGroupModeOptions,
                        set = function(_, val)
                            source.attrs.mode = val
                        end,
                        get = function () return source.attrs.mode end,
                    },
                    displayLearnedToggle = {
                        order = 4,
                        width=2,
                        type = 'toggle',
                        name = L["Only display learned or owned items."],
                        set = function(_, val) source.attrs.displayUnLearned = not val end,
                        get = function(_) return not source.attrs.displayUnLearned end,
                    },
                    replaceNameToggle = {
                        order = 4,
                        width=2,
                        type = 'toggle',
                        name = L["Use icon source title to replace item name."],
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
                        values = HtItem.TypeOptions,
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
                            if val == nil or val == "" or val == " " then
                                return "Please input effect title."
                            end
                            Config.tmpNewItem = {}
                            Config.tmpNewItem.type = Config.tmpNewItemType
                            if Config.tmpNewItem.type == nil then
                                return L["Please select item type."]
                            end
                            -- 添加物品逻辑
                            if Config.tmpNewItem.type == HtItem.Type.ITEM or Config.tmpNewItem.type == HtItem.Type.EQUIPMENT or Config.tmpNewItem.type == HtItem.Type.TOY then
                                local itemID = C_Item.GetItemIDForItemInfo(val)
                                if itemID then
                                    Config.tmpNewItem.id = itemID
                                else
                                    return L["Unable to get the id, please check the input."]
                                end
                                local itemName = C_Item.GetItemNameByID(Config.tmpNewItem.id)
                                if itemName then
                                    Config.tmpNewItem.name = itemName
                                else
                                    return L["Unable to get the name, please check the input."]
                                end
                                local itemIcon = C_Item.GetItemIconByID(Config.tmpNewItem.id)
                                if itemIcon then
                                    Config.tmpNewItem.icon = itemIcon
                                else
                                    return "Can not get the icon, please check your input."
                                end
                            elseif Config.tmpNewItem.type == HtItem.Type.SPELL then
                                local spellID = C_Spell.GetSpellIDForSpellIdentifier(val)
                                if spellID then
                                    Config.tmpNewItem.id = spellID
                                else
                                    return L["Unable to get the id, please check the input."]
                                end
                                local spellName = C_Spell.GetSpellName(Config.tmpNewItem.id)
                                if spellName then
                                    Config.tmpNewItem.name = spellName
                                else
                                    return "Can not get the name, please check your input."
                                end
                                local iconID, originalIconID = C_Spell.GetSpellTexture(Config.tmpNewItem.id)
                                if iconID then
                                    Config.tmpNewItem.icon = iconID
                                else
                                    return L["Unable to get the icon, please check the input."]
                                end
                            elseif Config.tmpNewItem.type == HtItem.Type.MOUNT then
                                Config.tmpNewItem.id = tonumber(val)
                                if Config.tmpNewItem.id == nil then
                                    for mountDisplayIndex = 1, C_MountJournal.GetNumDisplayedMounts() do
                                        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight = C_MountJournal.GetDisplayedMountInfo(mountDisplayIndex)
                                        if name == val then
                                            Config.tmpNewItem.id = mountID
                                            Config.tmpNewItem.name = name
                                            Config.tmpNewItem.icon = icon
                                            break
                                        end
                                    end
                                end
                                if Config.tmpNewItem.id == nil then
                                    return L["Unable to get the id, please check the input."]
                                end
                                if Config.tmpNewItem.icon == nil then
                                    local name, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID = C_MountJournal.GetMountInfoByID(Config.tmpNewItem.id)
                                    if name then
                                        Config.tmpNewItem.id = mountID
                                        Config.tmpNewItem.name = name
                                        Config.tmpNewItem.icon = icon
                                    else
                                        return "Can not get the name, please check your input."
                                    end
                                end
                            elseif Config.tmpNewItem.type == HtItem.Type.PET then
                                Config.tmpNewItem.id = tonumber(val)
                                if Config.tmpNewItem.id == nil then
                                    local speciesId, petGUID = C_PetJournal.FindPetIDByName(val)
                                    if speciesId then
                                        Config.tmpNewItem.id = speciesId
                                    end
                                end
                                if Config.tmpNewItem.id == nil then
                                    return L["Unable to get the id, please check the input."]
                                end
                                local speciesName, speciesIcon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable, creatureDisplayID = C_PetJournal.GetPetInfoBySpeciesID(Config.tmpNewItem.id)
                                if speciesName then
                                    Config.tmpNewItem.name = speciesName
                                    Config.tmpNewItem.icon = speciesIcon
                                else
                                    return L["Unable to get the name, please check the input."]
                                end
                            else
                                return "Wrong type, please check your input."
                            end
                            return true
                        end,
                        set = function(_, _)
                            Config.tmpNewItemVal = nil
                            table.insert(source.attrs.itemList, U.Table.DeepCopy(Config.tmpNewItem))
                            Config.tmpNewItem = {}
                            HT.AceAddon:UpdateOptions()
                            AceConfigDialog:SelectGroup(HT.AceAddonName, "iconSource", "SourceMenu" .. i, "item" .. #source.attrs.itemList)
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
                            table.remove(HT.AceAddon.db.profile.iconSourceList, i)
                            -- 从category中删除对应的itemGroup
                            for _, category in ipairs(HT.AceAddon.db.profile.categoryList) do
                                if category.sourceList ~= nil then
                                    for index, thing in ipairs(category.sourceList) do
                                        if thing.title == source.title then
                                            table.remove(category.sourceList, index)
                                            break
                                        end
                                    end
                                end
                            end
                            HT.AceAddon:UpdateOptions()
                        end,
                    },
                },
                order = i + 1,
            }
            -- 动态生成 itemList，每个 item 作为左侧菜单栏中的独立组
            for j, item in ipairs(source.attrs.itemList) do
                options.args["SourceMenu" .. i].args["item" .. j] = {
                    type = 'group',
                    name = item.name,
                    args = {
                        id = {
                            order = 2,
                            width=2,
                            type = 'input',
                            name = L["ID"],
                            disabled = true,
                            get = function() return tostring(item.id) end,
                        },
                        name = {
                            order = 2,
                            width=2,
                            type = 'input',
                            name = L["Name"],
                            disabled = true,
                            get = function() return item.name end,
                        },
                        alias ={
                            order = 3,
                            width=2,
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
                                HT.AceAddon:UpdateOptions()
                            end
                        },
                        icon = {
                            order = 4,
                            width=2,
                            type = 'input',
                            name = L["Icon"],
                            disabled = true,
                            get = function() return tostring(item.icon) end,
                        },
                        type = {
                            order = 5,
                            width=2,
                            type = 'select',
                            name = L["Type"],
                            values = HtItem.TypeOptions,
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
                                HT.AceAddon:UpdateOptions()
                                AceConfigDialog:SelectGroup(HT.AceAddonName, "iconSource", "SourceMenu" .. i)
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
    local profiles = AceDBOptions:GetOptionsTable(HT.AceAddon.db)
    profiles.args.importExport = {
        type = "group",
        name = L["Import/Export Configuration"] ,
        inline = true,
        order = 100,
        args = {
            export = {
                type = "execute",
                name = L["Export"],
                func = function()
                    ---@type ProfileConfig.ConfigTable
                    local configTable = {
                        name=HT.AceAddon.db:GetCurrentProfile() or L["Default"],
                        profile=HT.AceAddon.db.profile
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
                    HT.AceAddon.db.profiles[newProfileName] = configTable.profile
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
        handler = HT.AceAddon,
        type = 'group',
        args = {
            general = {
                order=1,
                type = 'group',
                name = L["General"],
                args = {
                    showGuiDefault = {
                        order = 1,
                        width=2,
                        type = 'toggle',
                        name = L["Show the gui by default when login in."],
                        set = function(_, val) HT.AceAddon.db.profile.showGuiDefault = val end,
                        get = function(_) return HT.AceAddon.db.profile.showGuiDefault end,
                    },
                    -- 设置窗口位置：x 和 y 值
                    windowPositionX = {
                        order = 2,
                        type = 'range',
                        name = L["Window Position X"],
                        min = 0,
                        max = math.floor(GetScreenWidth()),
                        step = 1,
                        set = function(_, val) HT.AceAddon.db.profile.windowPositionX = val end,
                        get = function(_) return HT.AceAddon.db.profile.windowPositionX end,
                    },
                    windowPositionY = {
                        order = 3,
                        type = 'range',
                        name = L["Window Position Y"],
                        min = 0,
                        max = math.floor(GetScreenHeight()),
                        step = 1,
                        set = function(_, val) HT.AceAddon.db.profile.windowPositionY = val end,
                        get = function(_) return HT.AceAddon.db.profile.windowPositionY end,
                    },
                },
            },
            category=ConfigOptions.CategoryOptions(),
            iconSource=ConfigOptions.IconSourceOptions(),
            profiles = ConfigOptions.ConfigOptions()
        },
    }
    return options
end



function HT.AceAddon:OnInitialize()
    -- 注册数据库，添加分类设置
    self.db = LibStub("AceDB-3.0"):New(HT.AceAddonConfigDB, {
        profile = {
            enable = true,
            windowPositionX = 0, -- 默认X位置
            windowPositionY = 0, -- 默认Y位置
            categoryList = {},
            iconSourceList={},
        }
    }, true)
    -- 注册选项表
    AceConfig:RegisterOptionsTable(HT.AceAddonName, ConfigOptions.Options)
    -- 在Blizzard界面选项中添加一个子选项
    self.optionsFrame = AceConfigDialog:AddToBlizOptions(HT.AceAddonName, HT.AceAddonName)
    -- 输入 /HappyToolkit 打开配置
    self:RegisterChatCommand(HT.AceAddonName, "OpenConfig")
end

function HT.AceAddon:OpenConfig()
    AceConfigDialog:Open(HT.AceAddonName)
end

function HT.AceAddon:UpdateOptions()
    -- 重新注册配置表来更新菜单栏
    LibStub("AceConfigRegistry-3.0"):NotifyChange(self.AceAddonName)
end
