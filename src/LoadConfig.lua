local addonName, _ = ...

---@class HappyToolkit: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class LoadConfig: AceModule
local LoadConfig = addon:NewModule("LoadConfig")

---@class CONST: AceModule
local const = addon:GetModule('CONST')

local L = LibStub("AceLocale-3.0"):GetLocale(addonName, false)

---@class HtItem: AceModule
local HtItem = addon:GetModule('HtItem')

---@class Callback: AceModule
local Callback = addon:GetModule('Callback')


LoadConfig.Bars = nil ---@type Bar[] | nil -- nil表示没有开始读取，用来判断是否需要刷新

---@class BarButton
---@field type string
---@field callback function
---@field source any
---@field button nil | any
local BarButton = {}

---@class Bar
---@field configIndex number  -- 在配置文件中的下标
---@field icon string | number | nil
---@field title string
---@field posX number
---@field posY number
---@field isDisplayName string
---@field displayMode BarDisplayMode
---@field Frame AceGUIWidget | nil
---@field buttons BarButton[]
local Bar = {}

---@class Utils: AceModule
local U = addon:GetModule('Utils')

function LoadConfig:ReLoadBars()
    local Bars = {}
    local barList = addon.db.profile.barList
    local sourceList = addon.db.profile.sourceList
    for _index, _bar in ipairs(barList) do
        if _bar.displayMode and _bar.displayMode ~= const.BAR_DISPLAY_MODE.Hidden then
            ---@type Bar
            local bar = {
                configIndex = _index,
                icon = _bar.icon,
                title = _bar.title,
                posX = _bar.posX or 0,
                posY = _bar.posY or 0,
                displayMode = _bar.displayMode,
                isDisplayName = _bar.isDisplayName,
                buttons = {},
                Frame = nil,
            }
            for _, thing in ipairs(_bar.sourceList) do
                ---@type Source
                local source
                for _, _source in ipairs(sourceList) do
                    if _source.title == thing.title then
                        source = _source
                        break
                    end
                end
                if source then
                    if source.type == "SCRIPT" then
                        if source.attrs and source.attrs.script then
                            local func, err = loadstring("return " .. source.attrs.script)
                            if func then
                                local status, result = pcall(func())
                                if status then
                                    if type(result) == "function" then
                                        local cbStatus, cbResult = pcall(result)
                                        if cbStatus then
                                            if U.Table.IsArray(cbResult) then
                                                for _, cb in ipairs(cbResult) do
                                                    if cb then
                                                        ---@type BarButton
                                                        local barButton = {type="SCRIPT", callback=Callback.CallbackOfScriptMode, source=cb}
                                                        table.insert(bar.buttons, barButton)
                                                    end
                                                end
                                            else
                                                local errMsg = L["Illegal script."] .. " " .. tostring(cbResult)
                                                U.Print.PrintErrorText(errMsg)
                                            end
                                        else
                                            local errMsg = L["Illegal script."] .. " " .. tostring(cbResult)
                                            U.Print.PrintErrorText(errMsg)
                                        end
                                    else
                                        local errMsg = L["Illegal script."] .. " " .. "the script should return a callback function."
                                        U.Print.PrintErrorText(errMsg)
                                    end
                                else
                                    local errMsg = L["Illegal script."] .. " " .. tostring(result)
                                    U.Print.PrintErrorText(errMsg)
                                end
                            else
                                U.Print.PrintErrorText(L["Illegal script."] .. " " .. err)
                            end
                        end
                    end
                    if source.type == "ITEM_GROUP" then
                        if source.attrs.mode == const.ITEMS_GROUP_MODE.RANDOM then
                            ---@type BarButton
                            local barButton = {type="ITEM_GROUP", callback=Callback.CallbackOfRandomMode, source=source}
                            table.insert(bar.buttons, barButton)
                        end
                        if source.attrs.mode == const.ITEMS_GROUP_MODE.SEQ then
                            ---@type BarButton
                            local barButton = {type="ITEM_GROUP", callback=Callback.CallbackOfSeqMode, source=source}
                            table.insert(bar.buttons, barButton)
                        end
                        if source.attrs.mode == const.ITEMS_GROUP_MODE.MULTIPLE then
                            for _, item in ipairs(source.attrs.itemList) do
                                local htItem = HtItem:New(item)
                                ---@type boolean
                                local needDisplay = true
                                if source.attrs.displayUnLearned == false then
                                    if htItem:IsLearned() == false then
                                        needDisplay = false
                                    end
                                end
                                if needDisplay == true then
                                    ---@type Source
                                    local newSource = {
                                        attrs = {
                                            mode=const.ITEMS_GROUP_MODE.SINGLE,
                                            replaceName=source.attrs.replaceName,
                                            displayUnLearned=source.attrs.displayUnLearned,
                                            item=item
                                        },
                                        title = source.title,
                                        type = "ITEM_GROUP"
                                    }
                                    ---@type BarButton
                                    local barButton = {type="ITEM_GROUP", callback=Callback.CallbackOfSingleMode, source=newSource}
                                    table.insert(bar.buttons, barButton)
                                end
                            end
                        end
                    end
                end
            end
            if #bar.buttons > 0 then
                table.insert(Bars, bar)
            end
        end
    end
    self.Bars = Bars
end

function LoadConfig:LoadBars()
    if LoadConfig.Bars == nil then
        self:ReLoadBars()
    end
end
