local addonName, _ = ... ---@type string, table

---@class HappyToolkit: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class MainFrame: AceModule
local MainFrame = addon:GetModule("MainFrame")

---@class AloneBarsFrame: AceModule
local AloneBarsFrame = addon:GetModule("AloneBarsFrame")

local L = LibStub("AceLocale-3.0"):GetLocale(addonName, false)

---@class Element: AceModule
local Element = addon:GetModule("Element")

---@class Utils: AceModule
local U = addon:GetModule('Utils')

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")
local LibDeflate = LibStub:GetLibrary("LibDeflate")
local AceGUI = LibStub("AceGUI-3.0")



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

local function getNewElementTitle()
    local newTitle = L["Default"]
    local titleList = {}
    for _, bar in ipairs(addon.db.profile.elements) do
        table.insert(titleList, bar.title)
    end
    if Config.IsTitleDuplicated(newTitle, titleList) then
        newTitle = Config.CreateDuplicateTitle(newTitle, titleList)
    end
    return newTitle
end

---@class ConfigOptions
---@field ElementsOptions function
---@field BarOptions function
---@field SourceOptions function
---@field ConfigOptions function
---@field Options function
local ConfigOptions = {}

---@param elements any
---@param selectGroupList table
local function GetElementOptions(elements, selectGroupList)
    local eleArgs = {}
    for i, ele in ipairs(elements) do
        local copySelectGroupList = U.Table.DeepCopyList(selectGroupList)  -- 复制一份目标菜单路径
        table.insert(copySelectGroupList, "elementMenu" .. i)
        local selectGroupListAfterAddItem = U.Table.DeepCopyList(copySelectGroupList)  -- 创建元素后的目标菜单路径
        table.insert(selectGroupListAfterAddItem, "elementMenu" .. (#ele.elements + 1))
        local iconPath = "|T" .. (ele.icon or 134400) .. ":16|t"
        local args = {}
        local order = 1
        args.title = {
            order = order,
            width=1,
            type = 'input',
            name = L["Title"],
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
            name = L["Icon"],
            get = function() return ele.icon end,
            set = function(_, val)
                ele.icon = val
                addon:UpdateOptions()
            end,
        }
        order = order + 1
        if ele.type == const.ELEMENT_TYPE.BAR_GROUP then
            args.addBar = {
                order = order,
                width = 1,
                type = 'execute',
                name = L["New Bar"],
                func = function()
                    ---@type Element
                    local bar = Element:New(getNewElementTitle(), const.ELEMENT_TYPE.BAR)
                    table.insert(ele.elements, bar)
                    AceConfigDialog:SelectGroup(addonName, unpack(selectGroupListAfterAddItem))
                end,
            }
            order = order + 1
        end
        if ele.type == const.ELEMENT_TYPE.BAR then
            args.addItemGroup = {
                order = order,
                width = 1,
                type = 'execute',
                name = L["New ItemGroup"],
                func = function()
                    ---@type Element
                    local itemGroup = Element:New(getNewElementTitle(), const.ELEMENT_TYPE.ITEM_GROUP)
                    table.insert(ele.elements, itemGroup)
                    AceConfigDialog:SelectGroup(addonName, unpack(selectGroupListAfterAddItem))
                end,
            }
            order = order + 1
            args.addScript = {
                order = order,
                width = 1,
                type = 'execute',
                name = L["New Script"],
                func = function()
                    ---@type Element
                    local script = Element:New(getNewElementTitle(), const.ELEMENT_TYPE.SCRIPT)
                    table.insert(ele.elements, script)
                    AceConfigDialog:SelectGroup(addonName, unpack(selectGroupListAfterAddItem))
                end,
            }
            order = order + 1
            args.addItem = {
                order = order,
                width = 1,
                type = 'execute',
                name = L["New Item"],
                func = function()
                    ---@type Element
                    local item = Element:New(getNewElementTitle(), const.ELEMENT_TYPE.ITEM)
                    table.insert(ele.elements, item)
                    AceConfigDialog:SelectGroup(addonName, unpack(selectGroupListAfterAddItem))
                end,
            }
            order = order + 1
        end
        if ele.type == const.ELEMENT_TYPE.ITEM_GROUP then
              args.addItem = {
                order = order,
                width = 1,
                type = 'execute',
                name = L["New Item"],
                func = function()
                    ---@type Element
                    local item = Element:New(getNewElementTitle(), const.ELEMENT_TYPE.ITEM)
                    table.insert(ele.elements, item)
                    AceConfigDialog:SelectGroup(addonName, unpack(selectGroupListAfterAddItem))
                end,
            }
            order = order + 1
        end
        args.delete = {
            order = order,
            width = 2,
            type = 'execute',
            name = L["Delete"],
            confirm=true,
            func = function()
                table.remove(addon.db.profile.elements, i)
                addon:UpdateOptions()
            end,
        }
        order = order + 1
        if ele.elements and #ele.elements then
            local tmpArgs = GetElementOptions(ele.elements, copySelectGroupList)
            for k, v in pairs(tmpArgs) do
                args[k] = v
            end
        end
        eleArgs["elementMenu" .. i] = {
            type = 'group',
            name = "|cff00ff00" .. iconPath .. tostring(ele.type) .. ":" .. ele.title  .. "|r",
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
        order = 1,
        args = {
            addBarGroup = {
                order = 1,
                width = 1,
                type = 'execute',
                name = L["New BarGroup"],
                func = function()
                    ---@type Element
                    local barGroup = Element:New(getNewElementTitle(), const.ELEMENT_TYPE.BAR_GROUP)
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
                    ---@type Element
                    local bar = Element:New(getNewElementTitle(), const.ELEMENT_TYPE.BAR)
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
                    ---@type Element
                    local itemGroup = Element:New(getNewElementTitle(), const.ELEMENT_TYPE.ITEM_GROUP)
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
                    ---@type Element
                    local script = Element:New(getNewElementTitle(), const.ELEMENT_TYPE.SCRIPT)
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
                    ---@type Element
                    local item = Element:New(getNewElementTitle(), const.ELEMENT_TYPE.ITEM)
                    table.insert(addon.db.profile.elements, item)
                    AceConfigDialog:SelectGroup(addonName, "element", "elementMenu" .. #addon.db.profile.elements)
                end,
            },
        },
    }
    local args = GetElementOptions(addon.db.profile.elements, {"element", })
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
                    name = L["Title"],
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
                    name = L["Icon"],
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
                        name = L["Wheter to use icon source title to replace item name."],
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
                            if val == nil or val == "" or val == " " then
                                return "Please input effect title."
                            end
                            Config.tmpNewItem = {}
                            Config.tmpNewItem.type = Config.tmpNewItemType
                            if Config.tmpNewItem.type == nil then
                                return L["Please select item type."]
                            end
                            -- 添加物品逻辑
                            if Config.tmpNewItem.type == const.ITEM_TYPE.ITEM or Config.tmpNewItem.type == const.ITEM_TYPE.EQUIPMENT or Config.tmpNewItem.type == const.ITEM_TYPE.TOY then
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
                            elseif Config.tmpNewItem.type == const.ITEM_TYPE.SPELL then
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
                            elseif Config.tmpNewItem.type == const.ITEM_TYPE.MOUNT then
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
                            elseif Config.tmpNewItem.type == const.ITEM_TYPE.PET then
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
                                MainFrame:OpenEditMode()
                                AloneBarsFrame:OpenEditMode()
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
            mainFrame = {
                order=2,
                type = 'group',
                name = L["Main frame"],
                args = {
                    showbarMenuDefault = {
                        order = 1,
                        width=2,
                        type = 'toggle',
                        name = L["Whether to show the bar menu when login in."],
                        set = function(_, val) addon.db.profile.showbarMenuDefault = val end,
                        get = function(_) return addon.db.profile.showbarMenuDefault end,
                    },
                    showbarMenuOnMouseEnter = {
                        order = 2,
                        width=2,
                        type = 'toggle',
                        name = L["Whether to show the bar menu when the mouse enter."],
                        set = function(_, val) addon.db.profile.showbarMenuOnMouseEnter = val end,
                        get = function(_) return addon.db.profile.showbarMenuOnMouseEnter end,
                    }
                },
            },
            bar=ConfigOptions.BarOptions(),
            source=ConfigOptions.SourceOptions(),
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
        IsEditMode = false
    }
    -- 注册数据库，添加分类设置
    self.db = LibStub("AceDB-3.0"):New("HappyToolkitDB", {
        profile = {
            elements = {},  ---@type Element[]
            --- todo:删除其他
            showbarMenuDefault = true,
            showbarMenuOnMouseEnter = false,
            posX = 0,
            posY = 0,
            barList = {},
            sourceList={},
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
