local _, HT = ...
local L = LibStub("AceLocale-3.0"):GetLocale("HappyToolkit", false)

---@class ItemOfHtItem
---@field type integer | nil
---@field id integer | nil
---@field icon integer | string | nil
---@field name string | nil
---@field alias string | nil
local ItemOfHtItem = {}


---@class CallbackOfHtItem
---@field closeGUIAfterClick boolean | nil
---@field icon string | number
---@field text string
---@field item ItemOfHtItem
---@field leftClickCallback function | nil
local CallbackOfHtItem = {}

---@class HtItem
---@field Type {ITEM: 1, EQUIPMENT: 2, TOY: 3, SPELL: 4, MOUNT: 5, PET: 6}
---@field TypeOptions table
---@field ItemGroupMode { RANDOM: 1, SEQ: 2, MULTIPLE: 3, SINGLE: 4 }
---@field ItemGroupModeOptions table
---@field CallbackOfRandomMode fun(source: IconSource): CallbackOfHtItem
---@field CallbackOfSeqMode fun(source: IconSource): CallbackOfHtItem
---@field CallbackOfSingleMode fun(source: IconSource): CallbackOfHtItem
---@field CallbackOfMultipleMode fun(source: IconSource): CallbackOfHtItem
---@field CallbackOfScriptMode fun(source: IconSource): CallbackOfHtItem
---@field IsLearned fun(item: ItemOfHtItem): boolean
---@field IsLearnedAndUsable fun(item: ItemOfHtItem): boolean
---@field IsUseableAndCooldown fun(item: ItemOfHtItem): boolean
---@field CallbackByItem fun(item: ItemOfHtItem): CallbackOfHtItem
local HtItem = {
}

HT.HtItem = HtItem

-- 分类
HtItem.Type = {
    ITEM = 1,
    EQUIPMENT = 2,
    TOY = 3,
    SPELL = 4,
    MOUNT = 5,
    PET = 6,
}

-- 添加物品类型选项
HtItem.TypeOptions = {
    [HtItem.Type.ITEM]=L["Item"],
    [HtItem.Type.EQUIPMENT]=L["Equipment"],
    [HtItem.Type.TOY]=L["Toy"],
    [HtItem.Type.SPELL]=L["Spell"],
    [HtItem.Type.MOUNT]=L["Mount"],
    [HtItem.Type.PET]=L["Pet"],
}

-- 物品组分类
HtItem.ItemGroupMode = {
    RANDOM = 1,
    SEQ = 2,
    MULTIPLE = 3,
    SINGLE = 4
}

-- 添加物品组类型选项
HtItem.ItemGroupModeOptions = {
    [HtItem.ItemGroupMode.RANDOM] = L["Display only one item, randomly selected."] ,
    [HtItem.ItemGroupMode.SEQ] = L["Display only one item, selected sequentially."],
    [HtItem.ItemGroupMode.MULTIPLE] = L["Display multiple items."]
}

-- 随机选择callback
function HtItem.CallbackOfRandomMode(source)
    local usableItemList = {}
    local cooldownItemList = {}
    for _, item in ipairs(source.attrs.itemList) do
        local isUsable = HtItem.IsLearnedAndUsable(item)
        local isCooldown = HtItem.IsUseableAndCooldown(item)
        if isUsable then
            table.insert(usableItemList, item)
        end
        if isCooldown then
            table.insert(cooldownItemList, item)
        end
    end
    ---@type CallbackOfHtItem
    local cb
    -- 如果有冷却可用的item，随机选择一个
    if #cooldownItemList > 0 then
        local randomIndex = math.random(1, #usableItemList)
        local selectedItem = cooldownItemList[randomIndex]
        cb = HtItem.CallbackByItem(selectedItem)
    elseif #usableItemList > 0  then
        -- 没有没有冷却可用，则选择可用
        cb = HtItem.CallbackByItem(usableItemList[1])
    else
        -- 没有可用的item时返回第一个
        cb = HtItem.CallbackByItem(source.attrs.itemList[1])
    end
    if source.attrs.replaceName == true then
        cb.text = source.title
    end
    return cb
end

-- 顺序选择callback
function HtItem.CallbackOfSeqMode(source)
    ---@type CallbackOfHtItem
    local cb
    for _, item in ipairs(source.attrs.itemList) do
        local isUsable = HtItem.IsLearnedAndUsable(item)
        if isUsable == true then
            local isCooldown = HtItem.IsUseableAndCooldown(item)
            if isCooldown then
                cb = HtItem.CallbackByItem(item)
                break
            end
        end
    end
    if cb == nil then
         -- 没有可用的item时返回第一个
        cb = HtItem.CallbackByItem(source.attrs.itemList[1])
    end
    if source.attrs.replaceName then
        cb.text = source.title
    end
    return cb
end

-- 全展示模式
function HtItem.CallbackOfMultipleMode(source)
    ---@type CallbackOfHtItem
    local cb = HtItem.CallbackByItem(source.attrs.itemList)
    if source.attrs.replaceName then
        cb.text = source.title
    end
    return cb
end

-- 单个展示模式
function HtItem.CallbackOfSingleMode(source)
    ---@type CallbackOfHtItem
    local cb = HtItem.CallbackByItem(source.attrs.item)
    if source.attrs.replaceName then
        cb.text = source.title
    end
    return cb
end

-- 脚本模式
function HtItem.CallbackOfScriptMode(source)
    return source.attrs.script
end


-- 判断玩家是否拥有/学习某个物品
function HtItem.IsLearned(item)
    local itemID, itemType = item.id, item.type
    if itemType == HtItem.Type.ITEM then
        local count = C_Item.GetItemCount(itemID, false)  -- 检查背包中是否拥有
        if count > 0 then
            return true
        end
    elseif itemType == HtItem.Type.TOY then
        if PlayerHasToy(itemID) then
            return true
        end
    elseif itemType == HtItem.Type.SPELL then
        if IsSpellKnown(itemID) then
            return true
        end
    elseif itemType == HtItem.Type.MOUNT then
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(itemID)
        if isCollected then
            return true
        end
    elseif itemType == HtItem.Type.PET then
        for petIndex = 1, C_PetJournal.GetNumPets() do
            local _, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByIndex(petIndex)
            if speciesID == itemID then
                return true
            end
        end
    end
    return false
end

-- 判断物品是否可用
function HtItem.IsLearnedAndUsable(item)
    local itemID, itemType = item.id, item.type
    if not HtItem.IsLearned(item) then
        return false
    end
    if itemType == HtItem.Type.ITEM then
        local usable, _ = C_Item.IsUsableItem(itemID)  -- 检查是否可用
        if usable == true then
            return true
        end
    elseif itemType == HtItem.Type.TOY then
        if C_ToyBox.IsToyUsable(itemID) then
            return true
        end
    elseif itemType == HtItem.Type.SPELL then
        local isUsable, _ = C_Spell.IsSpellUsable(itemID)
        if isUsable then
            return true
        end
    end
    return false
end


-- 确认物品是否可以使用并且不在冷却中
function HtItem.IsUseableAndCooldown(item)
    if not HtItem.IsLearnedAndUsable(item) then
        return false
    end
    local itemID, itemType = item.id, item.type
    if itemType == HtItem.Type.ITEM then
        local _, duration, _ = C_Item.GetItemCooldown(itemID)  -- 检查是否冷却中
        if not duration == 0 then
            return false
        end
        return true
    elseif itemType == HtItem.Type.TOY then
        local _, duration, _ = C_Container.GetItemCooldown(itemID)
        if not duration == 0 then
            return false
        end
        return true
    elseif itemType == HtItem.Type.SPELL then
        local spellCooldownInfo = C_Spell.GetSpellCooldown(itemID)
        if not spellCooldownInfo.duration == 0 then
            return false
        end
        return true
    else
        return false
    end
end

function HtItem.CallbackByItem(item)
    return {
        closeGUIAfterClick = nil,
        icon = item.icon,
        text = item.alias or item.name,
        item = item,
        leftClickCallback = nil
    }
end


