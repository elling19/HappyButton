local addonName, _ = ...

---@class HappyToolkit: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)
---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class (exact) HtItem: AceModule
---@field type integer | nil
---@field id integer | nil
---@field icon integer | string | nil
---@field name string | nil
---@field alias string | nil
local HtItem = addon:NewModule('HtItem')

---@class ItemOfHtItem
---@field type integer | nil
---@field id integer | nil
---@field icon integer | string | nil
---@field name string | nil
---@field alias string | nil
local ItemOfHtItem = {}


---@param item ItemOfHtItem
---@return HtItem
function HtItem:New(item)
    local obj = setmetatable({}, {__index = self})
    obj.type = item.type
    obj.id = item.id
    obj.icon = item.icon
    obj.name = item.name
    obj.alias = item.alias
    return obj
  end


function HtItem:ToTable()
    local t = {} ---@type ItemOfHtItem
    t.type = self.type
    t.id = self.id
    t.icon = self.icon
    t.name = self.name
    t.alias = self.alias
    return t
end

-- 判断玩家是否拥有/学习某个物品
function HtItem:IsLearned()
    local itemID, itemType = self.id, self.type
    if itemID == nil then
        return false
    end
    if itemType == const.ITEM_TYPE.ITEM then
        local count = C_Item.GetItemCount(itemID, false)  -- 检查背包中是否拥有
        if count > 0 then
            return true
        end
    elseif itemType == const.ITEM_TYPE.TOY then
        if PlayerHasToy(itemID) then
            return true
        end
    elseif itemType == const.ITEM_TYPE.SPELL then
        if IsSpellKnown(itemID) then
            return true
        end
    elseif itemType == const.ITEM_TYPE.MOUNT then
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(itemID)
        if isCollected then
            return true
        end
    elseif itemType == const.ITEM_TYPE.PET then
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
function HtItem:IsLearnedAndUsable()
    local itemID, itemType = self.id, self.type
    if itemID == nil then
        return false
    end
    if not self:IsLearned() then
        return false
    end
    if itemType == const.ITEM_TYPE.ITEM then
        local usable, _ = C_Item.IsUsableItem(itemID)  -- 检查是否可用
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
function HtItem:IsUseableAndCooldown()
    if not self:IsLearnedAndUsable() then
        return false
    end
    if self.id == nil then
        return false
    end
    if self.type == const.ITEM_TYPE.ITEM then
        local _, duration, _ = C_Item.GetItemCooldown(self.id)  -- 检查是否冷却中
        if not duration == 0 then
            return false
        end
        return true
    elseif self.type == const.ITEM_TYPE.TOY then
        local _, duration, _ = C_Container.GetItemCooldown(self.id)
        if not duration == 0 then
            return false
        end
        return true
    elseif self.type == const.ITEM_TYPE.SPELL then
        local spellCooldownInfo = C_Spell.GetSpellCooldown(self.id)
        if not spellCooldownInfo.duration == 0 then
            return false
        end
        return true
    else
        return false
    end
end

