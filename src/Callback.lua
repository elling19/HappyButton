local addonName, _ = ...  ---@type string, table
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)


---@class HtItem: AceModule
local HtItem = addon:GetModule('HtItem')

---@class Callback: AceModule
local Callback = addon:NewModule("Callback")

---@class CbResult
---@field closeGUIAfterClick boolean | nil
---@field icon string | number
---@field text string
---@field item ItemOfHtItem
---@field macro string | nil
---@field leftClickCallback function | nil
local CbResult = {}

-- 随机选择callback
function Callback.CallbackOfRandomMode(source)
    local usableItemList = {}
    local cooldownItemList = {}
    for _, item in ipairs(source.attrs.itemList) do
        local hTitem = HtItem:New(item)
        local isUsable = hTitem:IsLearnedAndUsable()
        local isCooldown = hTitem:IsUseableAndCooldown()
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
        local randomIndex = math.random(1, #usableItemList)
        local selectedItem = cooldownItemList[randomIndex]
        cb = Callback:CallbackByItem(selectedItem)
    elseif #usableItemList > 0  then
        -- 没有没有冷却可用，则选择可用
        cb = Callback:CallbackByItem(usableItemList[1])
    else
        -- 没有可用的item时返回第一个
        cb = Callback:CallbackByItem(source.attrs.itemList[1])
    end
    if source.attrs.replaceName == true then
        cb.text = source.title
    end
    return cb
end

-- 顺序选择callback
function Callback.CallbackOfSeqMode(source)
    ---@type CbResult
    local cb
    for _, item in ipairs(source.attrs.itemList) do
        local hTitem = HtItem:New(item)
        local isUsable = hTitem:IsLearnedAndUsable()
        if isUsable == true then
            local isCooldown = hTitem:IsUseableAndCooldown()
            if isCooldown then
                cb = Callback:CallbackByItem(item)
                break
            end
        end
    end
    if cb == nil then
         -- 没有可用的item时返回第一个
        cb = Callback:CallbackByItem(source.attrs.itemList[1])
    end
    if source.attrs.replaceName then
        cb.text = source.title
    end
    return cb
end

-- 全展示模式
function Callback.CallbackOfMultipleMode(source)
    ---@type CbResult
    local cb = Callback:CallbackByItem(source.attrs.itemList)
    if source.attrs.replaceName then
        cb.text = source.title
    end
    return cb
end

-- 单个展示模式
function Callback.CallbackOfSingleMode(source)
    ---@type CbResult
    local cb = Callback:CallbackByItem(source.attrs.item)
    if source.attrs.replaceName then
        cb.text = source.title
    end
    return cb
end

-- 脚本模式
function Callback.CallbackOfScriptMode(cb)
    return cb
end

function Callback:CallbackByItem(item)
    return {
        closeGUIAfterClick = nil,
        icon = item.icon,
        text = item.alias or item.name,
        item = item,
        macro = nil,
        leftClickCallback = nil
    }
end
