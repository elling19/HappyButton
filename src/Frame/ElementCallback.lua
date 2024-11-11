local addonName, _ = ... ---@type string, table
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class E: AceModule
local E = addon:GetModule("Element")

---@class Item: AceModule
local Item = addon:GetModule("Item")

---@class Utils: AceModule
local U = addon:GetModule('Utils')

local L = LibStub("AceLocale-3.0"):GetLocale(addonName, false)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class Trigger: AceModule
local Trigger = addon:GetModule("Trigger")

---@class Condition: AceModule
local Condition = addon:GetModule("Condition")

---@class Effect: AceModule
local Effect = addon:GetModule("Effect")

---@class Api: AceModule
local Api = addon:GetModule("Api")

---@class ElementCallback: AceModule
local ECB = addon:NewModule("ElementCallback")

---@class CbResult
---@field icon string | number
---@field text string
---@field borderColor RGBAColor | nil
---@field isLearned boolean | nil 是否学习或者拥有
---@field isUsable boolean | nil 是否可以使用
---@field count number | nil 物品堆叠数量|技能充能次数
---@field item ItemAttr | nil
---@field macro string | nil
---@field effects EffectConfig[] | nil
---@field leftClickCallback function | nil
local CbResult = {}

-- 随机选择callback
-- 函数永远只能返回包含一个CbResult的列表
---@param element ItemGroupConfig
---@param lastCbResults CbResult[] 上一次更新的结果
---@return CbResult[]
function ECB.CallbackOfRandomMode(element, lastCbResults)
    -- 如果上一次结果可用，则继续使用上一次的结果
    if lastCbResults and #lastCbResults then
        local r = lastCbResults[1]
        if r and r.item then
            local isUsable = Item:IsLearnedAndUsable(r.item.id, r.item.type)
            local isCooldown = Item:IsUseableAndCooldown(r.item.id, r.item.type)
            if isUsable and isCooldown then
                return lastCbResults
            end
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
        local randomIndex = math.random(1, #usableItemList)
        local selectedItem = usableItemList[randomIndex]
        cb = ECB:CallbackByItemConfig(selectedItem)
    elseif #element.elements > 0 then
        -- 没有可用的item时随机返回一个
        local randomIndex = math.random(1, #element.elements)
        local selectedItem = E:ToItem(element.elements[randomIndex])
        cb = ECB:CallbackByItemConfig(selectedItem)
    else
        cb = ECB:NilCallback()
    end
    return { cb, }
end

-- 顺序选择callback
-- 函数永远只能返回包含一个CbResult的列表
---@param element ItemGroupConfig
---@param lastCbResults CbResult[] 上一次更新的结果
---@return CbResult[]
function ECB.CallbackOfSeqMode(element, lastCbResults)
    if lastCbResults and #lastCbResults then
        local r = lastCbResults[1]
        if r and r.item then
            local isUsable = Item:IsLearnedAndUsable(r.item.id, r.item.type)
            local isCooldown = Item:IsUseableAndCooldown(r.item.id, r.item.type)
            if isUsable and isCooldown then
                return lastCbResults
            end
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
            local randomIndex = math.random(1, #element.elements)
            local selectedItem = E:ToItem(element.elements[randomIndex])
            cb = ECB:CallbackByItemConfig(selectedItem)
        else
            cb = ECB:NilCallback()
        end
    end
    return { cb, }
end

-- 单个展示模式callback
-- 函数永远只能返回包含一个CbResult的列表
---@param element ItemConfig
---@param _ CbResult[]
---@return CbResult[]
function ECB.CallbackOfSingleMode(element, _)
    local cb = ECB:CallbackByItemConfig(element)
    return { cb, }
end

-- 脚本模式
---@param element ScriptConfig
---@param _ CbResult[]
---@return CbResult[]
function ECB.CallbackOfScriptMode(element, _)
    local script = E:ToScript(element)
    local cbResults = {} ---@type CbResult[]
    local func, loadstringErr = loadstring(script.extraAttr.script)
    if not func then
        local errMsg = L["Illegal script."] .. " " .. loadstringErr
        U.Print.PrintErrorText(errMsg)
        return cbResults
    end
    local cbStatus, cbResult = pcall(func())
    if not cbStatus then
        local errMsg = L["Illegal script."] .. " " .. tostring(cbResult)
        U.Print.PrintErrorText(errMsg)
        return cbResults
    end
    -- 兼容返回列表和单个cbResult
    if not U.Table.IsArray(cbResult) then
        table.insert(cbResults, cbResult)
        return cbResults
    end
    for _, cb in ipairs(cbResult) do
        if cb then
            table.insert(cbResults, cb)
        end
    end
    return cbResults
end

---@param element ItemConfig
---@return CbResult
function ECB:CallbackByItemConfig(element)
    local item = E:ToItem(element)
    ---@type CbResult
    local cbResult = {
        icon = item.extraAttr.icon,
        text = item.extraAttr.name or item.title,
        item = item.extraAttr,
    }
    return cbResult
end

---@return CbResult
function ECB:NilCallback()
    ---@type CbResult
    return {
        icon = 134400,
        text = "",
        isLearned = false,
        isUsable = false,
        count = 0,
        item = nil,
        macro = nil,
        leftClickCallback = nil
    }
end

-- 更新自身触发器
---@param cbResult CbResult
function ECB:UpdateSelfTrigger(cbResult)
    -- 更新物品是否已经学习
    if cbResult.item then
        cbResult.isLearned = Item:IsLearned(cbResult.item.id, cbResult.item.type)
    else
        cbResult.isLearned = false
    end
    -- 更新物品是否可以使用
    if cbResult.item then
        cbResult.isUsable = Item:IsLearnedAndUsable(cbResult.item.id, cbResult.item.type)
    else
        cbResult.isUsable = false
    end
    -- 更新物品数量
    if cbResult.item then
        if cbResult.item.type == const.ITEM_TYPE.ITEM then
            cbResult.count = Api.GetItemCount(cbResult.item.id, false)
        end
        if cbResult.item.type == const.ITEM_TYPE.SPELL then
            local chargeInfo = Api.GetSpellCharges(cbResult.item.id)
            if chargeInfo then
                cbResult.count = chargeInfo.currentCharges
            end
        end
    end
    -- 更新物品边框
    if cbResult.item then
        if cbResult.item.type == const.ITEM_TYPE.ITEM or cbResult.item.type == const.ITEM_TYPE.TOY or cbResult.item.type == const.ITEM_TYPE.EQUIPMENT then
            local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent =
            Api.GetItemInfo(cbResult.item.id)
            if itemQuality then
                cbResult.borderColor = const.ItemQualityColor[itemQuality]
            end
        elseif cbResult.item.type == const.ITEM_TYPE.MOUNT then
            cbResult.borderColor = const.ItemQualityColor[Enum.ItemQuality.Epic]
        elseif cbResult.item.type == const.ITEM_TYPE.PET then
            cbResult.borderColor = const.ItemQualityColor[Enum.ItemQuality.Rare]
        end
    end
    if cbResult.borderColor == nil then
        cbResult.borderColor = const.DefaultItemColor
    end
end

-- 对cbResult进行触发器处理
---@param eleConfig ElementConfig
---@param cbResult CbResult
---@return EffectConfig[]
function ECB:UseTrigger(eleConfig, cbResult)
    local effects = {} ---@type EffectConfig[]
    if not eleConfig.triggers or #eleConfig.triggers == 0 then
        return effects
    end
    if not eleConfig.condGroups or #eleConfig.condGroups == 0 then
        cbResult.effects = effects
        return effects
    end
    local triggers = {} ---@type table<string, TriggerConfig>
    for _, trigger in ipairs(eleConfig.triggers) do
        triggers[trigger.id] = trigger
    end
    for _, condGroup in ipairs(eleConfig.condGroups) do
        if condGroup.effects and #condGroup.effects > 0 and condGroup.conditions and #condGroup.conditions and condGroup.expression then
            local condResults = {} ---@type boolean[]
            for _, cond in ipairs(condGroup.conditions) do
                local condResult = false ---@type boolean
                if cond.leftTriggerId and cond.leftVal and triggers[cond.leftTriggerId] then
                    local leftTrigger = triggers[cond.leftTriggerId] ---@type TriggerConfig
                    if leftTrigger.type == "self" then
                        local leftValue = cbResult[cond.leftVal]
                        if type(cond.rightValue) == "number" or type(cond.rightValue) == "boolean" then
                            -- 判断条件返回真/假
                            ---@diagnostic disable-next-line: param-type-mismatch
                            local r = Condition:ExecOperator(leftValue, cond.operator, cond.rightValue)
                            if r:is_ok() then
                                condResult = r:unwrap()
                            end
                        end
                    end
                    if leftTrigger.type == "aura" then
                        local auraTriggerCond = Trigger:GetAuraTriggerCond(leftTrigger)
                        local leftValue = auraTriggerCond[cond.leftVal]
                        ---@diagnostic disable-next-line: param-type-mismatch
                        local r = Condition:ExecOperator(leftValue, cond.operator, cond.rightValue)
                        if r:is_ok() then
                            condResult = r:unwrap()
                        end
                    end
                end
                table.insert(condResults, condResult)
            end
            -- 判断条件组返回真/假
            local condGroupR = Condition:ExecExpression(condResults, condGroup.expression)
            if condGroupR then
                for _, effect in ipairs(condGroup.effects) do
                    -- 首先判断状态，如果状态为nil则不处理
                    if effect.status ~= nil then
                        -- 判断是否有相同的效果，如果有则替换，没有则添加
                        local hasSame = false
                        for index, _effect in ipairs(effects) do
                            if _effect.type == effect.type then
                                hasSame = true
                                effects[index] = effect
                                break
                            end
                        end
                        if hasSame == false then
                            table.insert(effects, effect)
                        end
                    end
                end
            end
        end
    end
    return effects
end
