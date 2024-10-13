local _, HT = ...
local U = HT.Utils
local L = LibStub("AceLocale-3.0"):GetLocale("HappyToolkit", false)

local HtItem = {}

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
}
-- 添加物品组类型选项
HtItem.ItemGroupModeOptions = {
    [HtItem.ItemGroupMode.RANDOM] = L["Display only one item, randomly selected."] ,
    [HtItem.ItemGroupMode.SEQ] = L["Display only one item, selected sequentially."],
    [HtItem.ItemGroupMode.MULTIPLE] = L["Display multiple items."]
}

-- 随机选择callback
function HtItem.CallbackOfRandomMode(itemList)
    local usableItemList = {}
    local cooldownItemList = {}
    for _, item in ipairs(itemList) do
        local isUsable = HtItem.IsLearnedAndUsable(item)
        local isCooldown = HtItem.IsUseableAndCooldown(item)
        if isUsable then
            table.insert(usableItemList, item)
        end
        if isCooldown then
            table.insert(cooldownItemList, item)
        end
    end
    -- 如果有冷却可用的item，随机选择一个
    if #cooldownItemList > 0 then
        local randomIndex = math.random(1, #usableItemList)
        local selectedItem = cooldownItemList[randomIndex]
        return HtItem.CallbackByItem(selectedItem)
    end
    -- 没有没有冷却可用，则选择可用
    if #usableItemList > 0 then
        return HtItem.CallbackByItem(usableItemList[1])
    end
    -- 没有可用的item时返回第一个
    return HtItem.CallbackByItem(itemList[1])
end

-- 顺序选择callback
function HtItem.CallbackOfSeqMode(itemList)
    for _, item in ipairs(itemList) do
        local isUsable = HtItem.IsLearnedAndUsable(item)
        if isUsable == true then
            local isCooldown = HtItem.IsUseableAndCooldown(item)
            if isCooldown then
                return HtItem.CallbackByItem(item)
            end
        end
    end
    -- 没有可用的item时返回第一个
    return HtItem.CallbackByItem(itemList[1])
end

-- 全展示模式
function HtItem.CallbackOfMultipleMode(item)
    return HtItem.CallbackByItem(item)
end

-- 脚本模式
function HtItem.CallbackOfScriptMode(script)
    return nil
end


-- 判断玩家是否拥有/学习某个物品
function HtItem.IsLearned(itemID, itemType)
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
    if not HtItem.IsLearned(itemID, itemType) then
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
-- @return boolean 是否可用
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


function HtItem.GetItemInfo(itemID, itemType, itemIcon)
    ---@class ItemInfo
    ---@field id number 物品id
    ---@field type number 物品类型
    ---@field name string? 物品名称（用于显示宏图标，鼠标悬浮提示）
    ---@field icon number? 物品图标ID（用于显示技能图标）
    local ItemInfo = {
        id = itemID,
        type = itemType,
        icon = itemIcon,
        name = nil,
    }
    if itemType == HtItem.Type.ITEM or itemType == HtItem.Type.TOY then
        local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent = C_Item.GetItemInfo(itemID)
        if itemName then
            ItemInfo.name = itemName
            ItemInfo.icon = itemTexture
            return ItemInfo
        else
            local item = Item:CreateFromItemID(itemID)
                item:ContinueOnItemLoad(function()
                ItemInfo.name = item:GetItemName()
                ItemInfo.icon = item:GetItemIcon()
                return ItemInfo
            end)
            return ItemInfo
        end
    elseif itemType == HtItem.Type.SPELL then
        local spellInfo = C_Spell.GetSpellInfo(itemID)
        if spellInfo then
            ItemInfo.name = spellInfo.name
            ItemInfo.icon = spellInfo.iconID
            return ItemInfo
        else
            local spell = Spell:CreateFromSpellID(itemID)
            spell:ContinueOnSpellLoad(function()
                ItemInfo.name = spell:GetSpellName()
                ItemInfo.icon = spell:GetSpellTexture()
                return ItemInfo
            end)
            return ItemInfo
        end
    elseif itemType == HtItem.Type.MOUNT then
        local name, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID = C_MountJournal.GetMountInfoByID(itemID)
        if name then
            ItemInfo.name = name
            ItemInfo.icon = icon
            return ItemInfo
        else
            return ItemInfo
        end
    elseif itemType == HtItem.Type.PET then
        -- local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByPetID(itemID)
        local speciesName, speciesIcon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable, creatureDisplayID = C_PetJournal.GetPetInfoBySpeciesID(itemID)
        if speciesName then
            ItemInfo.name = speciesName
            ItemInfo.icon = speciesIcon
            return ItemInfo
        else
            return ItemInfo
        end
    else
        return ItemInfo
    end
end

function HtItem.CallbackByItem(item)
    return {
        closeGUIAfterClick = nil,
        icon = item.icon,
        text = item.name,
        item = item,
        leftClickCallback = nil
    }
end
