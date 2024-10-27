local addonName, _ = ... ---@type string, table
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class E: AceModule
local E = addon:GetModule("Element")

---@class Item: AceModule
local Item = addon:GetModule("Item")

---@class ElementCallback: AceModule
local ECB = addon:NewModule("ElementCallback")

---@class Utils: AceModule
local U = addon:GetModule('Utils')

local L = LibStub("AceLocale-3.0"):GetLocale(addonName, false)

---@class CbResult
---@field closeGUIAfterClick boolean | nil
---@field icon string | number
---@field text string
---@field item ItemAttr
---@field macro string | nil
---@field leftClickCallback function | nil
local CbResult = {}

-- 随机选择callback
---@param element ItemGroupConfig
---@param lastCbResult CbResult 上一次更新的结果
---@return CbResult
function ECB.CallbackOfRandomMode(element, lastCbResult)
    -- 如果上一次结果可用，则继续使用上一次的结果
    if lastCbResult and lastCbResult.item then
        local isUsable = Item:IsLearnedAndUsable(lastCbResult.item.id, lastCbResult.item.type)
        local isCooldown = Item:IsUseableAndCooldown(lastCbResult.item.id, lastCbResult.item.type)
        if isUsable and isCooldown then
            return lastCbResult
        end
    end
    local usableItemList = {} ---@type ItemConfig[]
    local cooldownItemList = {} ---@type ItemConfig[]
    for _, ele in ipairs(element.elements) do
        local item = E:ToItem(ele)
        local isUsable = Item:IsLearnedAndUsable(item.extraAttr.id, item.extraAttr.type)
        local isCooldown = Item:IsUseableAndCooldown(item.extraAttr.id, item.extraAttr.type)
        if isUsable then
            table.insert(usableItemList, item)
        end
        if isCooldown then
            table.insert(cooldownItemList, item)
        end
    end
    ---@type CbResult
    local cb
    -- 如果有冷却可用的item，随机选择一个
    if #cooldownItemList > 0 then
        local randomIndex = math.random(1, #cooldownItemList)
        local selectedItem = cooldownItemList[randomIndex]
        cb = ECB:CallbackByItemConfig(selectedItem)
    elseif #usableItemList > 0 then
        -- 没有没有冷却可用，则选择可用
        cb = ECB:CallbackByItemConfig(usableItemList[1])
    elseif #element.elements > 0 then
        -- 没有可用的item时返回第一个
        local item = E:ToItem(element.elements[1])
        cb = ECB:CallbackByItemConfig(item)
    else
        cb = ECB:NilCallback()
    end
    return cb
end

-- 顺序选择callback
---@param element ItemGroupConfig
---@param lastCbResult CbResult 上一次更新的结果
---@return CbResult
function ECB.CallbackOfSeqMode(element, lastCbResult)
    -- 如果上一次结果可用，则继续使用上一次的结果
    if lastCbResult and lastCbResult.item then
        local isUsable = Item:IsLearnedAndUsable(lastCbResult.item.id, lastCbResult.item.type)
        local isCooldown = Item:IsUseableAndCooldown(lastCbResult.item.id, lastCbResult.item.type)
        if isUsable and isCooldown then
            return lastCbResult
        end
    end
    ---@type CbResult
    local cb
    for _, ele in ipairs(element.elements) do
        local item = E:ToItem(ele)
        local isUsable = Item:IsLearnedAndUsable(item.extraAttr.id, item.extraAttr.type)
        if isUsable == true then
            local isCooldown = Item:IsUseableAndCooldown(item.extraAttr.id, item.extraAttr.type)
            if isCooldown then
                cb = ECB:CallbackByItemConfig(item)
                break
            end
        end
    end
    if cb == nil then
        if #element.elements > 0 then
            local item = E:ToItem(element.elements[1])
            cb = ECB:CallbackByItemConfig(item)
        else
            cb = ECB:NilCallback()
        end
    end
    return cb
end

-- 单个展示模式callback
---@param element ItemConfig
---@param _ CbResult
---@return CbResult
function ECB.CallbackOfSingleMode(element, _)
    local cb = ECB:CallbackByItemConfig(element)
    return cb
end

-- 脚本模式
---@param element ScriptConfig
---@param _ CbResult
---@return CbResult
function ECB.CallbackOfScriptMode(element, _)
    local script = E:ToScript(element)
    local func, loadstringErr = loadstring(script.extraAttr.script)
    if not func then
        local errMsg = L["Illegal script."] .. " " .. loadstringErr
        U.Print.PrintErrorText(errMsg)
        return ECB:NilCallback()
    end
    local cbStatus, cbResult = pcall(func())
    if not cbStatus then
        local errMsg = L["Illegal script."] .. " " .. tostring(cbResult)
        U.Print.PrintErrorText(errMsg)
        return ECB:NilCallback()
    end
    if not U.Table.IsArray(cbResult) then
        return cbResult ---@type CbResult
    else
        -- 兼容旧版本脚本返回一个cbResult列表
        return cbResult[1] ---@type CbResult
    end
end

---@param element ItemConfig
---@return CbResult
function ECB:CallbackByItemConfig(element)
    local item = E:ToItem(element)
    return {
        closeGUIAfterClick = nil,
        icon = item.extraAttr.icon,
        text = item.extraAttr.name or item.title,
        item = item.extraAttr,
        macro = nil,
        leftClickCallback = nil
    }
end

---@return CbResult
function ECB:NilCallback()
    return {
        closeGUIAfterClick = nil,
        icon = nil,
        text = nil,
        item = nil,
        macro = nil,
        leftClickCallback = nil
    }
end
