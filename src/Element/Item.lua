local addonName, _ = ...


---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

local E = addon:GetModule("Element", true)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class Item: E
local Item = addon:NewModule("Item", E)

-- 判断玩家是否拥有/学习某个物品
---@param itemID number
---@param itemType ItemType
---@return boolean
function Item:IsLearned(itemID, itemType)
    if itemID == nil then
        return false
    end
    if itemType == const.ITEM_TYPE.ITEM then
        local bagCount = C_Item.GetItemCount(itemID, false) -- 检查背包中是否拥有
        if bagCount > 0 then
            return true
        end
    elseif itemType == const.ITEM_TYPE.EQUIPMENT then
        local bagCount = C_Item.GetItemCount(itemID, false)
        local isEquipped = self:IsEquipped(itemID)
        return bagCount > 0 or isEquipped == true
    elseif itemType == const.ITEM_TYPE.TOY then
        if PlayerHasToy(itemID) then
            return true
        end
    elseif itemType == const.ITEM_TYPE.SPELL then
        if IsSpellKnown(itemID) then
            return true
        end
    elseif itemType == const.ITEM_TYPE.MOUNT then
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight =
        C_MountJournal.GetMountInfoByID(itemID)
        if isCollected then
            return true
        end
    elseif itemType == const.ITEM_TYPE.PET then
        for petIndex = 1, C_PetJournal.GetNumPets() do
            local _, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable =
            C_PetJournal.GetPetInfoByIndex(petIndex)
            if speciesID == itemID then
                return true
            end
        end
    end
    return false
end

-- 判断物品是否可用
---@param item ItemConfig
---@return boolean
function Item:IsLearnedAndUsable(item)
    local itemID, itemType = item.extraAttr.id, item.extraAttr.type
    if itemID == nil or itemType == nil then
        return false
    end
    if not self:IsLearned(itemID, itemType) then
        return false
    end
    if itemType == const.ITEM_TYPE.ITEM then
        local usable, _ = C_Item.IsUsableItem(itemID) -- 检查是否可用
        if usable == true then
            return true
        end
    elseif itemType == const.ITEM_TYPE.TOY then
        if C_ToyBox.IsToyUsable(itemID) then
            return true
        end
    elseif itemType == const.ITEM_TYPE.SPELL then
        local isUsable, _ = C_Spell.IsSpellUsable(itemID)
        if isUsable then
            return true
        end
    end
    return false
end

-- 确认物品是否可以使用并且不在冷却中
-- 判断物品是否可用
---@param item ItemConfig
---@return boolean
function Item:IsUseableAndCooldown(item)
    if not self:IsLearnedAndUsable(item) then
        return false
    end
    if item.extraAttr.id == nil then
        return false
    end
    if item.extraAttr.type == const.ITEM_TYPE.ITEM then
        local _, duration, _ = C_Item.GetItemCooldown(item.extraAttr.id) -- 检查是否冷却中
        if not duration == 0 then
            return false
        end
        return true
    elseif item.extraAttr.type == const.ITEM_TYPE.TOY then
        local _, duration, _ = C_Container.GetItemCooldown(item.extraAttr.id)
        if not duration == 0 then
            return false
        end
        return true
    elseif item.extraAttr.type == const.ITEM_TYPE.SPELL then
        local spellCooldownInfo = C_Spell.GetSpellCooldown(item.extraAttr.id)
        if not spellCooldownInfo.duration == 0 then
            return false
        end
        return true
    else
        return false
    end
end

-- 判断物品是否被装备
---@param itemId number
---@return boolean
function Item:IsEquipped(itemId)
    -- 检查物品是否已装备
    -- 检查所有装备槽: https://warcraft.wiki.gg/wiki/InventorySlotID
    local isEquipped = false
    for i = 1, 30 do
        local equippedItemID = GetInventoryItemID("player", i)
        if equippedItemID == itemId then
            isEquipped = true
            break
        end
    end
    return isEquipped
end
