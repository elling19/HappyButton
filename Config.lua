local _, HT = ...
local HtItem = HT.HtItem
local U = HT.Utils
HT.AceAddonName = "HappyToolkit"
HT.AceAddonConfigDB = "HappyToolkitDB"
HT.AceAddon = LibStub("AceAddon-3.0"):NewAddon(HT.AceAddonName, "AceConsole-3.0", "AceEvent-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")
local LibDeflate = LibStub:GetLibrary("LibDeflate")
local AceGUI = LibStub("AceGUI-3.0")

-- 临时变量
local tmpCoverConfig = false  -- 默认选择不覆盖配置，创建副本
local tmpImportItemGroupConfigString = nil  -- 导入itemGroup配置字符串
local tmpNewItemType = nil
local tmpNewItemVal = nil
local tmpNewItem = {type=nil, title = nil, id = nil, icon = nil, name = nil}


local function ResetTmpNewItem()
    tmpNewItem = {type=nil, title = nil, id = nil, icon = nil, name = nil}
end


-- 展示导出配置框
local function ShowExportDialog(exportData)
    local dialog = AceGUI:Create("Window")
    dialog:SetTitle("Copy Export Data")
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
local function isTitleDuplicated(title, titleList)
    for _, _title in pairs(titleList) do
        if _title == title then
            return true
        end
    end
    return false
end

-- 创建副本标题的函数
local function createDuplicateTitle(title, titleList)
    local count = 1
    local newTitle = title .. " [" .. count .. "]"
    -- 检查新标题是否也重复，如果是则继续递增
    while isTitleDuplicated(newTitle, titleList) do
        count = count + 1
        newTitle = title .. " [" .. count .. "]"
    end
    return newTitle
end


-- 添加物品组类型选项
local itemGroupModeOptions = {
    RANDOM = "Display only one item, randomly selected.",
    SEQ = "Display only one item, selected sequentially.",
    MULTIPLE = "Display multiple items."
}


local function CategoryOptions()
    local options = {
        type = 'group',
        name = "Category",
        args = {
            add = {
                order = 1,
                type = 'input',
                name = "New Category",
                width = 2,
                desc = "Input title to create a new category",
                validate = function (_, val)
                    if val == nil or val == "" or val == " " then
                        return "invaid title."
                    end
                    for _, category in ipairs(HT.AceAddon.db.profile.categoryList) do
                        if category.title == val then
                            return "repeat title, please choose another title."
                        end
                    end
                    return true
                end,
                set = function(_, val)
                    table.insert(HT.AceAddon.db.profile.categoryList, { title = val, icon = nil, thingList = {} })
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
                    name = 'Category Title',
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
                    name = "Category Icon",
                    desc = "Edit the icon path of the selected category",
                    get = function() return category.icon end,
                    set = function(_, val)
                        category.icon = val
                        HT.AceAddon:UpdateOptions()
                    end,
                },
                space1 = {
                    order = 3,
                    type = 'description',
                    name = "\n"
                },
                itemGroupList = {
                    order = 4,
                    width=2,
                    type = 'multiselect',
                    name = "Select item groups to display",
                    values = function()
                        local values = {}
                        for _, itemGroup in ipairs(HT.AceAddon.db.profile.itemGroupList) do
                            values[itemGroup.title] = itemGroup.title
                        end
                        return values
                    end,
                    get = function(_, key)
                        for _, thing in ipairs(category.thingList) do
                            if thing.type == "ITEM_GROUP" and thing.title == key then
                                return true
                            end
                        end
                        return false
                    end,
                    set = function(_, key, value)
                        if value == true then
                            for _, thing in ipairs(category.thingList) do
                                if thing.type == "ITEM_GROUP" and thing.title == key then
                                    return
                                end
                            end
                            table.insert(category.thingList, {type="ITEM_GROUP", title=key})
                        end
                        if value == false then
                            for index, thing in ipairs(category.thingList) do
                                if thing.type == "ITEM_GROUP" and thing.title == key then
                                    table.remove(category.thingList, index)
                                    return
                                end
                            end
                        end
                    end,
                },
                scriptList = {
                    order = 5,
                    width=2,
                    type = 'multiselect',
                    name = "Select scripts to display",
                    values = function()
                        local values = {}
                        for _, script in ipairs(HT.AceAddon.db.profile.scriptList) do
                            values[script.title] = script.title
                        end
                        return values
                    end,
                    get = function(_, key)
                        for _, thing in ipairs(category.thingList) do
                            if thing.type == "SCRIPT" and thing.title == key then
                                return true
                            end
                        end
                        return false
                    end,
                    set = function(_, key, value)
                        if value == true then
                            for _, thing in ipairs(category.thingList) do
                                if thing.type == "SCRIPT" and thing.title == key then
                                    return
                                end
                            end
                            table.insert(category.thingList, {type="SCRIPT", title=key})
                        end
                        if value == false then
                            for index, thing in ipairs(category.thingList) do
                                if thing.type == "SCRIPT" and thing.title == key then
                                    table.remove(category.thingList, index)
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
                    name = 'Delete Category',
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


local function ScriptOptions()
    local options = {
        type = 'group',
        name = "Script",
        args = {
            add = {
                order = 1,
                type = 'input',
                name = "New Script",
                width = 2,
                desc = "Input title to create a new script",
                validate = function (_, val)
                    if val == nil or val == "" or val == " " then
                        return "invaid title."
                    end
                    for _, script in ipairs(HT.AceAddon.db.profile.scriptList) do
                        if script.title == val then
                            return "repeat title, please choose another title."
                        end
                    end
                    return true
                end,
                set = function(info, val)
                    table.insert(HT.AceAddon.db.profile.scriptList, {title=val, script=nil})
                    HT.AceAddon:UpdateOptions()
                    AceConfigDialog:SelectGroup(HT.AceAddonName, "script", "scriptMenu" .. #HT.AceAddon.db.profile.scriptList)
                end,
            },
        },
    }

    for i, script in ipairs(HT.AceAddon.db.profile.scriptList) do
        options.args["scriptMenu" .. i] = {
            type = 'group',
            name = "|cff00ff00" .. script.title .. "|r",
            args = {
                title = {
                    order = 1,
                    width=2,
                    type = 'input',
                    name = 'Script Title',
                    validate = function (_, val)
                        for _i, _script in ipairs(HT.AceAddon.db.profile.scriptList) do
                            if _script.title == val and i ~= _i then
                                return "repeat title, please input another one."
                            end
                        end
                        return true
                    end,
                    get = function() return script.title end,
                    set = function(_, val)
                        -- 在category中修改对应的script
                        for _, category in ipairs(HT.AceAddon.db.profile.categoryList) do
                            if category.thingList ~= nil then
                                for index, thing in ipairs(category.thingList) do
                                    if thing.type == "SCRIPT" and thing.title == script.title then
                                        category.thingList[index].title = val
                                        break
                                    end
                                end
                            end
                        end
                        script.title = val
                        HT.AceAddon:UpdateOptions()
                    end,
                },
                edit = {
                    order = 2,
                    type = 'input',
                    name = "Script:",
                    multiline = 20,
                    -- multiline = true,
                    width = "full",
                    set = function(info, val)
                        script.script = val
                        HT.AceAddon:UpdateOptions()
                    end,
                    get = function()
                        return script.script
                    end,
                },
                delete = {
                    order = 3,
                    width=2,
                    type = 'execute',
                    name = 'Delete Script',
                    confirm=true,
                    func = function()
                        table.remove(HT.AceAddon.db.profile.scriptList, i)
                        -- 从category中删除对应的script
                        for _, category in ipairs(HT.AceAddon.db.profile.categoryList) do
                            if category.thingList ~= nil then
                                for index, thing in ipairs(category.thingList) do
                                    if thing.type == "SCRIPT" and thing.title == script.title then
                                        table.remove(category.thingList, index)
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

    return options
end

local function ItemGroupOptions()
    local options = {
        type = 'group',
        name = "ItemGroup",
        args = {
            add = {
                order = 1,
                type = 'input',
                name = "New ItemGroup",
                width = 2,
                desc = "Input title to create a new itemGroup",
                validate = function (_, val)
                    if val == nil or val == "" or val == " " then
                        return "invaid title."
                    end
                    for _, script in ipairs(HT.AceAddon.db.profile.itemGroupList) do
                        if script.title == val then
                            return "repeat title, please choose another title."
                        end
                    end
                    return true
                end,
                set = function(info, val)
                    table.insert(HT.AceAddon.db.profile.itemGroupList, { title=val, mode="MULTIPLE", displayUnUseable=false, displayUnLearned=false, itemList={} })
                    HT.AceAddon:UpdateOptions()
                    AceConfigDialog:SelectGroup(HT.AceAddonName, "itemGroup", "itemGroupMenu" .. #HT.AceAddon.db.profile.itemGroupList)
                end,
            },
            sapce1 = {
                order = 2,
                type = 'description',
                name = "\n\n\n"
            },
            itemHeading = {
                order = 3,
                type = 'header',
                name = "Import Config",
            },
            coverToggle = {
                order = 4,
                width=2,
                type = 'toggle',
                name = "Cover the config if exists.",
                set = function(_, _) tmpCoverConfig = not tmpCoverConfig end,
                get = function(_) return tmpCoverConfig end,
            },
            importEditBox = {
                order = 4,
                type = 'input',
                name = "Import ItemGroup Config String:",
                multiline = 20,
                width = "full",
                set = function(info, val)
                    tmpImportItemGroupConfigString = val
                    if val == nil or val == "" then
                        print("Please input the config string.")
                        return
                    end
                    local decodedData = LibDeflate:DecodeForPrint(val)
                    if decodedData == nil then
                        print("Import failed: Invalid data.")
                        return
                    end
                    local decompressedData = LibDeflate:DecompressDeflate(decodedData)
                    if decompressedData == nil then
                        print("Import failed: Invalid data.")
                        return
                    end
                    local success, configTable = AceSerializer:Deserialize(decompressedData)
                    if not success then
                        print("Import failed: Invalid data.")
                        return
                    end
                    -- 校验反序列是否正确
                    -- table需要包含{ title=val, mode="MULTIPLE", displayUnUseable=false, displayUnLearned=false, itemList={} }
                    if type(configTable) ~= "table" then
                        print("Import failed: Invalid data.")
                        return
                    end
                    if configTable.title == nil then
                        print("Import failed: Invalid data.")
                        return
                    end
                    if configTable.mode == nil then
                        print("Import failed: Invalid data.")
                        return
                    end
                    if configTable.itemList == nil or type(configTable.itemList) ~= "table" then
                        print("Import failed: Invalid data.")
                        return
                    end
                    -- 判断标题是否重复
                    local titleList = {}
                    for _, itemGroup in ipairs(HT.AceAddon.db.profile.itemGroupList) do
                        table.insert(titleList, itemGroup.title)
                    end
                    if isTitleDuplicated(configTable.title, titleList) then
                        if tmpCoverConfig == true then
                            for i, itemGroup in ipairs(HT.AceAddon.db.profile.itemGroupList) do
                                if itemGroup.title == configTable.title then
                                    HT.AceAddon.db.profile.itemGroupList[i] = configTable
                                    HT.AceAddon:UpdateOptions()
                                    AceConfigDialog:SelectGroup(HT.AceAddonName, "itemGroup", "itemGroupMenu" .. i)
                                    return true
                                end
                            end
                        else
                            configTable.title = createDuplicateTitle(configTable.title, titleList)
                        end
                    end
                    table.insert(HT.AceAddon.db.profile.itemGroupList, configTable)
                    HT.AceAddon:UpdateOptions()
                    AceConfigDialog:SelectGroup(HT.AceAddonName, "itemGroup", "itemGroupMenu" .. #HT.AceAddon.db.profile.itemGroupList)
                end,
                get = function (_) return tmpImportItemGroupConfigString end
            },
        },
    }

    -- 动态生成每个 itemGroupMenu
    for i, itemGroup in ipairs(HT.AceAddon.db.profile.itemGroupList) do
        options.args["itemGroupMenu" .. i] = {
            type = 'group',
            name = "|cff00ff00" .. itemGroup.title .. "|r",
            args = {
                title = {
                    order = 1,
                    width=1,
                    type = 'input',
                    name = 'ItemGroup Title',
                    validate = function (_, val)
                        for _i, _script in ipairs(HT.AceAddon.db.profile.itemGroupList) do
                            if _script.title == val and i ~= _i then
                                return "repeat title, please input another one."
                            end
                        end
                        return true
                    end,
                    get = function() return itemGroup.title end,
                    set = function(_, val)
                        -- 在category中修改对应的itemGroup
                        for _, category in ipairs(HT.AceAddon.db.profile.categoryList) do
                            if category.thingList ~= nil then
                                for index, thing in ipairs(category.thingList) do
                                    if thing.type == "ITEM_GROUP" and thing.title == itemGroup.title then
                                        category.thingList[index].title = val
                                        break
                                    end
                                end
                            end
                        end
                        itemGroup.title = val
                        HT.AceAddon:UpdateOptions()
                    end,
                },
                export = {
                    order=2,
                    width=1,
                    type = 'execute',
                    name = 'Export ItemGroup',
                    func = function()
                        local serializedData = AceSerializer:Serialize(itemGroup)
                        local compressedData = LibDeflate:CompressDeflate(serializedData)
                        local base64Encoded = LibDeflate:EncodeForPrint(compressedData)
                        ShowExportDialog(base64Encoded)
                    end,
                },
                mode = {
                    order = 3,
                    width=2,
                    type = 'select',
                    name = "ItemGroup Mode",
                    values = itemGroupModeOptions,
                    set = function(_, val)
                        itemGroup.mode = val
                    end,
                    get = function () return itemGroup.mode end,
                },
                displayLearnedToggle = {
                    order = 4,
                    width=2,
                    type = 'toggle',
                    name = "Only display learned item.",
                    set = function(_, val) itemGroup.displayUnLearned = not val end,
                    get = function(_) return not itemGroup.displayUnLearned end,
                },
                displayUseableToggle = {
                    order = 5,
                    width=2,
                    type = 'toggle',
                    name = "Only display useable item.",
                    set = function(_, val) itemGroup.displayUnUseable = not val end,
                    get = function(_) return not itemGroup.displayUnUseable end,
                },
                sapce1 = {
                    order = 6,
                    type = 'description',
                    name = "\n\n\n"
                },
                itemHeading = {
                    order = 7,
                    type = 'header',
                    name = "Add Item",
                },
                itemType = {
                    order = 8,
                    type = 'select',
                    name = "Item Type",
                    values = HtItem.TypeOptions,
                    set = function(_, val)
                        tmpNewItemType = val
                    end,
                    get = function ()
                        return tmpNewItemType
                    end
                },
                itemTitle = {
                    order = 9,
                    type = 'input',
                    name = "Item title or item id",
                    validate = function (_, val)
                        if val == nil or val == "" or val == " " then
                            return "Please input effect title."
                        end
                        ResetTmpNewItem()
                        tmpNewItem.type = tmpNewItemType
                        if tmpNewItem.type == nil then
                            return "Please select item type."
                        end
                        -- 添加物品逻辑
                        if tmpNewItem.type == HtItem.Type.ITEM or tmpNewItem.type == HtItem.Type.EQUIPMENT or tmpNewItem.type == HtItem.Type.TOY then
                            local itemID = C_Item.GetItemIDForItemInfo(val)
                            if itemID then
                                tmpNewItem.id = itemID
                            else
                                return "Can not get the id, please check your input."
                            end
                            local itemName = C_Item.GetItemNameByID(tmpNewItem.id)
                            if itemName then
                                tmpNewItem.name = itemName
                                tmpNewItem.title = itemName
                            else
                                return "Can not get the name, please check your input."
                            end
                            local itemIcon = C_Item.GetItemIconByID(tmpNewItem.id)
                            if itemIcon then
                                tmpNewItem.icon = itemIcon
                            else
                                return "Can not get the icon, please check your input."
                            end
                        elseif tmpNewItem.type == HtItem.Type.SPELL then
                            local spellID = C_Spell.GetSpellIDForSpellIdentifier(val)
                            if spellID then
                                tmpNewItem.id = spellID
                            else
                                return "Can not get the id, please check your input."
                            end
                            local spellName = C_Spell.GetSpellName(tmpNewItem.id)
                            if spellName then
                                tmpNewItem.name = spellName
                                tmpNewItem.title = spellName
                            else
                                return "Can not get the name, please check your input."
                            end
                            local iconID, originalIconID = C_Spell.GetSpellTexture(tmpNewItem.id)
                            if iconID then
                                tmpNewItem.icon = iconID
                            else
                                return "Can not get the icon, please check your input."
                            end
                        elseif tmpNewItem.type == HtItem.Type.MOUNT then
                            tmpNewItem.id = tonumber(val)
                            if tmpNewItem.id == nil then
                                for mountDisplayIndex = 1, C_MountJournal.GetNumDisplayedMounts() do
                                    local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight = C_MountJournal.GetDisplayedMountInfo(mountDisplayIndex)
                                    if name == val then
                                        tmpNewItem.id = mountID
                                        tmpNewItem.name = name
                                        tmpNewItem.title = name
                                        tmpNewItem.icon = icon
                                        break
                                    end
                                end
                            end
                            if tmpNewItem.id == nil then
                                return "Can not get the id, please check your input."
                            end
                            if tmpNewItem.icon == nil then
                                local name, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID = C_MountJournal.GetMountInfoByID(newItem.id)
                                if name then
                                    tmpNewItem.id = mountID
                                    tmpNewItem.name = name
                                    tmpNewItem.title = name
                                    tmpNewItem.icon = icon
                                else
                                    return "Can not get the name, please check your input."
                                end
                            end
                        elseif tmpNewItem.type == HtItem.Type.PET then
                            tmpNewItem.id = tonumber(val)
                            if tmpNewItem.id == nil then
                                local speciesId, petGUID = C_PetJournal.FindPetIDByName(val)
                                if speciesId then
                                    tmpNewItem.id = speciesId
                                end
                            end
                            if tmpNewItem.id == nil then
                                return "Can not get the id, please check your input."
                            end
                            local speciesName, speciesIcon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable, creatureDisplayID = C_PetJournal.GetPetInfoBySpeciesID(newItem.id)
                            if speciesName then
                                tmpNewItem.name = speciesName
                                tmpNewItem.title = speciesName
                                tmpNewItem.icon = speciesIcon
                            else
                                return "Can not get the name, please check your input."
                            end
                        else
                            return "Wrong type, please check your input."
                        end
                        return true
                    end,
                    set = function(_, _)
                        tmpNewItemVal = nil
                        local x = U.DeepCopy(newItem)
                        table.insert(itemGroup.itemList, U.DeepCopy(newItem))
                        tmpNewItem = {}
                        HT.AceAddon:UpdateOptions()
                        AceConfigDialog:SelectGroup(HT.AceAddonName, "itemGroup", "itemGroupMenu" .. i, "item" .. #itemGroup.itemList)
                    end,
                    get = function ()
                        return tmpNewItemVal
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
                    name = 'Delete ItemGroup',
                    confirm=true,
                    func = function()
                        table.remove(HT.AceAddon.db.profile.itemGroupList, i)
                        -- 从category中删除对应的itemGroup
                        for _, category in ipairs(HT.AceAddon.db.profile.categoryList) do
                            if category.thingList ~= nil then
                                for index, thing in ipairs(category.thingList) do
                                    if thing.type == "ITEM_GROUP" and thing.title == itemGroup.title then
                                        table.remove(category.thingList, index)
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
        for j, item in ipairs(itemGroup.itemList) do
            options.args["itemGroupMenu" .. i].args["item" .. j] = {
                type = 'group',
                name = item.title,
                args = {
                    title = {
                        order = 1,
                        width=2,
                        type = 'input',
                        name = "Item Title",
                        set = function(_, val)
                            item.title = val
                            HT.AceAddon:UpdateOptions()
                        end,
                        get = function() return item.title end,
                    },
                    id = {
                        order = 2,
                        width=2,
                        type = 'input',
                        name = "Item ID",
                        disabled = true,
                        get = function() return tostring(item.id) end,
                    },
                    name = {
                        order = 2,
                        width=2,
                        type = 'input',
                        name = "Item Name",
                        disabled = true,
                        get = function() return tostring(item.name) end,
                    },
                    icon = {
                        order = 2,
                        width=2,
                        type = 'input',
                        name = "Item Icon",
                        disabled = true,
                        get = function() return tostring(item.icon) end,
                    },
                    type = {
                        order = 3,
                        width=2,
                        type = 'select',
                        name = "Item Type",
                        values = HtItem.TypeOptions,
                        disabled = true,
                        get = function() return item.type end,
                    },
                    space = {
                        order = 4,
                        type = 'description',
                        name = "\n"
                    },
                    delete = {
                        order = 5,
                        width=2,
                        type = 'execute',
                        name = "Delete Item",
                        confirm=true,
                        func = function()
                            table.remove(itemGroup.itemList, j)
                            HT.AceAddon:UpdateOptions()
                            AceConfigDialog:SelectGroup(HT.AceAddonName, "itemGroup", "itemGroupMenu" .. i)
                        end,
                    },
                },
                order = j + 1,
            }
        end
    end

    return options
end

local function GetOptions()
    local options = {
        name = "HappyToolkit Options",
        handler = HT.AceAddon,
        type = 'group',
        args = {
            general = {
                order=1,
                type = 'group',
                name = "General",
                args = {
                    -- 设置窗口位置：x 和 y 值
                    windowPositionX = {
                        type = 'range',
                        name = "Window Position X",
                        desc = "Set the X position of the window",
                        min = 0,
                        max = math.floor(GetScreenWidth()),
                        step = 1,
                        set = function(_, val) HT.AceAddon.db.profile.windowPositionX = val end,
                        get = function(_) return HT.AceAddon.db.profile.windowPositionX end,
                    },
                    windowPositionY = {
                        type = 'range',
                        name = "Window Position Y",
                        desc = "Set the Y position of the window",
                        min = 0,
                        max = math.floor(GetScreenHeight()),
                        step = 1,
                        set = function(_, val) HT.AceAddon.db.profile.windowPositionY = val end,
                        get = function(_) return HT.AceAddon.db.profile.windowPositionY end,
                    },
                },
            },
            category=CategoryOptions(),
            itemGroup=ItemGroupOptions(),
            script = ScriptOptions(),
            profiles = AceDBOptions:GetOptionsTable(HT.AceAddon.db) -- 添加profile管理
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
            itemGroupList = {},
            scriptList = {},
        }
    }, true)
    -- 注册选项表
    AceConfig:RegisterOptionsTable(HT.AceAddonName, GetOptions)
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
