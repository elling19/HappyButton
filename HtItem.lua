local _, HT = ...
local U = HT.Utils

local HtItem = {}

HT.HtItem = HtItem

-- 确认物品是否可以使用
-- @param itemID number 物品ID
-- @param itemType number 物品类型
-- @return boolean 是否可用
function HtItem.CheckUseable(itemID, itemType)
    if itemType == U.Cate.ITEM then
        local count = C_Item.GetItemCount(itemID, false)  -- 检查背包中是否拥有
        if count == 0 then
            return false
        end
        local _, duration, _ = C_Item.GetItemCooldown(itemID)  -- 检查是否冷却中
        if not duration == 0 then
            return false
        end
        local usable, _ = C_Item.IsUsableItem(itemID)  -- 检查是否可用
            if usable == false then
                return false
            end
        return true
    elseif itemType == U.Cate.TOY then
        if not PlayerHasToy(itemID) then
            return false
        end
        if not C_ToyBox.IsToyUsable(itemID) then
            return false
        end
        local _, duration, _ = C_Container.GetItemCooldown(itemID)
        if not duration == 0 then
            return false
        end
        return true
    elseif itemType == U.Cate.SPELL then
        local isUsable, _ = C_Spell.IsSpellUsable(itemID)
        if not isUsable then
            return false
        end
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
        local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByPetID(itemID)
        if name then
            ItemInfo.name = name
            ItemInfo.icon = icon
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
    for _, item in ipairs(itemList) do
        local itemID, itemType = item.itemID, item.itemType
        local isUsable = HtItem.CheckUseable(itemID, itemType)
        if isUsable then
            table.insert(usableItemList, item)
        end
    end
    -- 如果有可用的item，随机选择一个
    if #usableItemList > 0 then
        local randomIndex = math.random(1, #usableItemList)
        local selectedItem = usableItemList[randomIndex]
        return selectedItem
    end
    -- 没有可用的item时返回第一个
    return itemList[0]
end