local _, HT = ...
local U = HT.Utils

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
    [HtItem.Type.ITEM]="Item",
    [HtItem.Type.EQUIPMENT]="Equipment",
    [HtItem.Type.TOY]="Toy",
    [HtItem.Type.SPELL]="Spell",
    [HtItem.Type.MOUNT]="Mount",
    [HtItem.Type.PET]="Pet",
}


-- 判断玩家是否拥有/学习某个物品
function HtItem.IsLearned(itemID, itemType)
    if itemType == U.Cate.ITEM then
        local count = C_Item.GetItemCount(itemID, false)  -- 检查背包中是否拥有
        if count > 0 then
            return true
        end
    elseif itemType == U.Cate.TOY then
        if PlayerHasToy(itemID) then
            return true
        end
    elseif itemType == U.Cate.SPELL then
        if IsSpellKnown(itemID) then
            return true
        end
    elseif itemType == U.Cate.MOUNT then
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(itemID)
        if isCollected then
            return true
        end
    elseif itemType == U.Cate.PET then
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
function HtItem.IsLearnedAndUsable(itemID, itemType)
    if not HtItem.IsLearned(itemID, itemType) then
        return false
    end
    if itemType == U.Cate.ITEM then
        local usable, _ = C_Item.IsUsableItem(itemID)  -- 检查是否可用
        if usable == true then
            return true
        end
    elseif itemType == U.Cate.TOY then
        if C_ToyBox.IsToyUsable(itemID) then
            return true
        end
    elseif itemType == U.Cate.SPELL then
        local isUsable, _ = C_Spell.IsSpellUsable(itemID)
        if isUsable then
            return true
        end
    end
    return false
end


-- 确认物品是否可以使用并且不在冷却中
-- @param itemID number 物品ID
-- @param itemType number 物品类型
-- @return boolean 是否可用
function HtItem.IsUseableAndCooldown(itemID, itemType)
    if not HtItem.IsLearnedAndUsable(itemID, itemType) then
        return false
    end
    if itemType == U.Cate.ITEM then
        local _, duration, _ = C_Item.GetItemCooldown(itemID)  -- 检查是否冷却中
        if not duration == 0 then
            return false
        end
        return true
    elseif itemType == U.Cate.TOY then
        local _, duration, _ = C_Container.GetItemCooldown(itemID)
        if not duration == 0 then
            return false
        end
        return true
    elseif itemType == U.Cate.SPELL then
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
    if itemType == U.Cate.ITEM or itemType == U.Cate.TOY then
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
    elseif itemType == U.Cate.SPELL then
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
    elseif itemType == U.Cate.MOUNT then
        local name, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID = C_MountJournal.GetMountInfoByID(itemID)
        if name then
            ItemInfo.name = name
            ItemInfo.icon = icon
            return ItemInfo
        else
            return ItemInfo
        end
    elseif itemType == U.Cate.PET then
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

function HtItem.CallbackByItem(itemID, itemType, itemIcon)
    local itemInfo = HtItem.GetItemInfo(itemID, itemType, itemIcon)
    if itemInfo == nil then
        U.PrintWarnText(("Can not find itemInfo: id: %s, type: %s"):format(itemID, itemType))
        return nil
    end
    local result = {
        closeGUIAfterClick = nil,
        icon = nil,
        text = nil,
        macro = {
            itemID = nil,
            toyID = nil,
            spellID = nil,
            petID = nil,
            mountID = nil,
        },
        leftClickCallback = nil
    }
    result.icon = itemInfo.icon
    result.text = itemInfo.name
    if itemType == U.Cate.ITEM then
        result.macro.itemID = itemID
        return result
    elseif itemType == U.Cate.TOY  then
        result.macro.toyID = itemID
        return result
    elseif itemType == U.Cate.SPELL then
        result.macro.spellID = itemID
        return result
    elseif itemType == U.Cate.MOUNT then
        result.macro.mountID = itemID
        return result
    elseif itemType == U.Cate.PET then
        result.macro.petID = itemID
        return result
    else
        return nil
    end
end

function HT.RandomChooseItem(itemList)
    local usableItemList = {}
    local cooldownItemList = {}
    for _, item in ipairs(itemList) do
        local itemID, itemType = item.itemID, item.itemType
        local isUsable = HtItem.IsLearnedAndUsable(itemID, itemType)
        local isCooldown = HtItem.IsUseableAndCooldown(itemID, itemType)
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
        return selectedItem
    end
    -- 没有没有冷却可用，则选择可用
    if #usableItemList > 0 then
        return usableItemList[1]
    end
    -- 没有可用的item时返回第一个
    return itemList[1]
end