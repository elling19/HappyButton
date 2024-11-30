local addonName, _ = ...


---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

local L = LibStub("AceLocale-3.0"):GetLocale(addonName, false)

---@class Result: AceModule
local R = addon:GetModule("Result")

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class Item: AceModule
local Item = addon:NewModule("Item")

---@class Api: AceModule
local Api = addon:GetModule("Api")

---@class Client: AceModule
local Client = addon:GetModule("Client")

-- 判断玩家是否拥有/学习某个物品
---@param itemID number
---@param itemType ItemType
---@return boolean
function Item:IsLearned(itemID, itemType)
    if itemID == nil then
        return false
    end
    if itemType == const.ITEM_TYPE.ITEM then
        local bagCount = Api.GetItemCount(itemID, false) -- 检查背包中是否拥有
        if bagCount > 0 then
            return true
        end
    elseif itemType == const.ITEM_TYPE.EQUIPMENT then
        local bagCount = Api.GetItemCount(itemID, false)
        local isEquipped = self:IsEquipped(itemID)
        return bagCount > 0 or isEquipped == true
    elseif itemType == const.ITEM_TYPE.TOY then
        if PlayerHasToy(itemID) then
            return true
        end
    elseif itemType == const.ITEM_TYPE.SPELL then
        if IsSpellKnownOrOverridesKnown(itemID) then
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
---@param itemID number
---@param itemType ItemType
---@return boolean
function Item:IsLearnedAndUsable(itemID, itemType)
    if itemID == nil or itemType == nil then
        return false
    end
    if not self:IsLearned(itemID, itemType) then
        return false
    end
    if itemType == const.ITEM_TYPE.ITEM or itemType == const.ITEM_TYPE.EQUIPMENT then
        local usable, _ = Api.IsUsableItem(itemID) -- 检查是否可用
        if usable == true then
            return true
        end
    elseif itemType == const.ITEM_TYPE.TOY then
        if C_ToyBox.IsToyUsable(itemID) then
            return true
        end
    elseif itemType == const.ITEM_TYPE.SPELL then
        local isUsable, _ = Api.IsSpellUsable(itemID)
        if isUsable then
            return true
        end
    elseif itemType == const.ITEM_TYPE.MOUNT then
        -- 根据玩家职业、种族判断是否可用
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight
        = C_MountJournal.GetMountInfoByID(itemID)
        if not isUsable then
            return false
        end
        -- 室内无法使用坐骑
        if not IsOutdoors() then
            return false
        end
        local creatureDisplayInfoID, description, source, isSelfMount, mountTypeID, uiModelSceneID, animID, spellVisualKitID, disablePlayerMountPreview =
        C_MountJournal.GetMountInfoExtraByID(mountID)
        -- 判断当前位置是否可以使用坐骑
        -- 不是御龙术区域无法使用御龙术
        if Client:IsRetail() then
            if not IsAdvancedFlyableArea() and mountTypeID == const.MOUNT_TYPE_ID.DRAGON then
                return false
            end
        end
        return true
    elseif itemType == const.ITEM_TYPE.PET then
        return true
    end
    return false
end

-- 确认物品是否可以使用并且不在冷却中
-- 判断物品是否可用
---@param itemID number
---@param itemType ItemType
---@return boolean
function Item:IsUseableAndCooldown(itemID, itemType)
    if not self:IsLearnedAndUsable(itemID, itemType) then
        return false
    end
    if itemID == nil then
        return false
    end
    if itemType == const.ITEM_TYPE.ITEM or itemType == const.ITEM_TYPE.EQUIPMENT or itemType == const.ITEM_TYPE.TOY then
        local _, duration, enableCooldownTimer = Api.GetItemCooldown(itemID) -- 检查是否冷却中
        if enableCooldownTimer == false then
            return true
        end
        if duration ~= 0 and duration > 1.5 then -- 需要判断是否是公共冷却
            return false
        end
        return true
    elseif itemType == const.ITEM_TYPE.SPELL then
        local spellCooldownInfo = Api.GetSpellCooldown(itemID)
        if spellCooldownInfo.isEnabled == false then
            return true
        end
        if spellCooldownInfo.duration ~= 0 and spellCooldownInfo.duration > 1.5 then -- 需要判断是否是公共冷却
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

-- 通过类型ID和类型Identifier获取ItemAttr
---@param identifier string | number
---@param itemType number | nil
---@return Result
function Item:GetFromVal(identifier, itemType)
    local item = {} ---@type ItemAttr
    item.type = itemType
    -- 说明：print(type(C_ToyBox.GetToyInfo(item.id))) 返回的是number，和文档定义的不一致，无法通过API获取玩具信息，因此只能使用物品的API来获取
    if itemType == const.ITEM_TYPE.ITEM or itemType == const.ITEM_TYPE.TOY or itemType == const.ITEM_TYPE.EQUIPMENT then
        local itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subClassID = Api.GetItemInfoInstant(identifier)
        if itemID then
            item.id = itemID
            item.icon = icon
            item.name = C_Item.GetItemNameByID(item.id)
        else
            return R:Err(L["Unable to get the id, please check the input."])
        end
        return R:Ok(item)
    elseif itemType == const.ITEM_TYPE.SPELL then
        if Client:IsRetail() then
            local spellID = C_Spell.GetSpellIDForSpellIdentifier(identifier)
            if spellID then
                item.id = spellID
                item.name = C_Spell.GetSpellName(item.id)
                item.icon = select(1, C_Spell.GetSpellTexture(item.id))
            else
                return R:Err(L["Unable to get the id, please check the input."])
            end
        else
            local spellInfo = Api.GetSpellInfo(identifier)
            if spellInfo then
                item.id = spellInfo.spellID
                item.name = spellInfo.name
                item.icon = spellInfo.iconID
            else
                return R:Err(L["Unable to get the id, please check the input."])
            end
        end
        return R:Ok(item)
    elseif item.type == const.ITEM_TYPE.MOUNT then
        item.id = tonumber(identifier)
        if item.id == nil then
            for mountDisplayIndex = 1, C_MountJournal.GetNumDisplayedMounts() do
                local name, spellID, icon, isActive, isUsable, sourceType,
                isFavorite, isFactionSpecific, faction, shouldHideOnChar,
                isCollected, mountID, isSteadyFlight =
                    C_MountJournal.GetDisplayedMountInfo(mountDisplayIndex)
                if name == identifier then
                    item.id = mountID
                    item.name = name
                    item.icon = icon
                    break
                end
            end
        end
        if item.id == nil then
            return R:Err(L["Unable to get the id, please check the input."])
        end
        if item.icon == nil then
            local name, spellID, icon, active, isUsable, sourceType, isFavorite,
            isFactionSpecific, faction, shouldHideOnChar, isCollected,
            mountID = C_MountJournal.GetMountInfoByID(item.id)
            if name then
                item.id = mountID
                item.name = name
                item.icon = icon
            else
                return R:Err("Can not get the name, please check your input.")
            end
        end
        return R:Ok(item)
    elseif item.type == const.ITEM_TYPE.PET then
        item.id = tonumber(identifier)
        if item.id == nil then
            local speciesId, petGUID = C_PetJournal.FindPetIDByName(tostring(identifier))
            if speciesId then item.id = speciesId end
        end
        if item.id == nil then
            return R:Err(L["Unable to get the id, please check the input."])
        end
        local speciesName, speciesIcon, petType, companionID, tooltipSource,
        tooltipDescription, isWild, canBattle, isTradeable, isUnique,
        obtainable, creatureDisplayID =
            C_PetJournal.GetPetInfoBySpeciesID(item.id)
        if speciesName then
            item.name = speciesName
            item.icon = speciesIcon
        else
            return R:Err(L["Unable to get the name, please check the input."])
        end
        return R:Ok(item)
    -- 如果没有提供类型，则依次判断技能、物品
    elseif item.type == nil then
        -- 如果没有提供类型，则依次判断技能、物品、坐骑
        -- 判断技能
        if Client:IsRetail() then
            local spellID = C_Spell.GetSpellIDForSpellIdentifier(identifier)
            if spellID then
                item.id = spellID
                item.name = C_Spell.GetSpellName(item.id)
                item.icon = select(1, C_Spell.GetSpellTexture(item.id))
                item.type = const.ITEM_TYPE.SPELL
                return R:Ok(item)
            end
        else
            local spellInfo = Api.GetSpellInfo(identifier)
            if spellInfo then
                item.id = spellInfo.spellID
                item.name = spellInfo.name
                item.icon = spellInfo.iconID
                item.type = const.ITEM_TYPE.SPELL
                return R:Ok(item)
            end
        end
        -- 判断物品
        local itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subClassID = Api.GetItemInfoInstant(identifier)
        if itemID then
            item.id = itemID
            item.icon = icon
            item.name = C_Item.GetItemNameByID(item.id)
            item.type = const.ITEM_TYPE.ITEM
            return R:Ok(item)
        end
        -- 判断坐骑
        local id = tonumber(identifier)
        if id == nil then
            for mountDisplayIndex = 1, C_MountJournal.GetNumDisplayedMounts() do
                local name, spellID, icon, isActive, isUsable, sourceType,
                isFavorite, isFactionSpecific, faction, shouldHideOnChar,
                isCollected, mountID, isSteadyFlight =
                    C_MountJournal.GetDisplayedMountInfo(mountDisplayIndex)
                if name == identifier then
                    item.id = mountID
                    item.name = name
                    item.icon = icon
                    item.type = const.ITEM_TYPE.MOUNT
                    return R:Ok(item)
                end
            end
        else
            local name, spellID, icon, active, isUsable, sourceType, isFavorite,
            isFactionSpecific, faction, shouldHideOnChar, isCollected,
            mountID = C_MountJournal.GetMountInfoByID(id)
            if name then
                item.id = mountID
                item.name = name
                item.icon = icon
                item.type = const.ITEM_TYPE.MOUNT
                return R:Ok(item)
            end
        end
        return R:Err(L["Macro Error: Can not find this identifier: %s"]:format(identifier))
    end
    return R:Err(L["Macro Error: Can not find this identifier: %s"]:format(identifier))
end
