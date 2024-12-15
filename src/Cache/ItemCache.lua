local addonName, _ = ...


---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class Api: AceModule
local Api = addon:GetModule("Api")

---@class Item: AceModule
local Item = addon:GetModule("Item")

---@class ItemCacheInfo
---@field refCount number 引用计数
---@field isLearned boolean
---@field isUsable boolean
---@field isCooldown boolean
---@field cooldownInfo CooldownInfo | nil
---@field borderColor RGBAColor
---@field count number

---@class ItemCache: AceModule
---@field item table<number, ItemCacheInfo>
---@field equipment table<number, ItemCacheInfo>
---@field spell table<number, ItemCacheInfo>
---@field toy table<number, ItemCacheInfo>
---@field mount table<number, ItemCacheInfo>
---@field pet table<number, ItemCacheInfo>
local ItemCache = addon:NewModule("ItemCache")


function ItemCache:Initial()
    ItemCache.item = {}
    ItemCache.equipment = {}
    ItemCache.spell = {}
    ItemCache.toy = {}
    ItemCache.mount = {}
    ItemCache.pet = {}
end

---@param id number
function ItemCache:GetItemCacheInfo(id)
    local bagCount = Api.GetItemCount(id, false)
    local usable, _ = Api.IsUsableItem(id)
    local cooldownInfo = Api.GetItemCooldown(id)
    local isCooldown = Item:IsCooldown(cooldownInfo)
    local borderColor = const.DefaultItemColor
    local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent =
            Api.GetItemInfo(id)
        if itemQuality then
            borderColor = const.ItemQualityColor[itemQuality]
        end
    return {
        isLearned = bagCount > 0,
        isUsable = usable,
        cooldownInfo = cooldownInfo,
        isCooldown = isCooldown,
        borderColor = borderColor,
        count = bagCount
    }
end

---@param id number
function ItemCache:GetEquipmentCacheInfo(id)
    local bagCount = Api.GetItemCount(id, false)
    local isEquipped = Item:IsEquipped(id)
    local usable, _ = Api.IsUsableItem(id)
    local cooldownInfo = Api.GetItemCooldown(id)
    local isCooldown = Item:IsCooldown(cooldownInfo)
    local borderColor = const.DefaultItemColor
    local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent =
            Api.GetItemInfo(id)
        if itemQuality then
            borderColor = const.ItemQualityColor[itemQuality]
        end
    return {
        isLearned = bagCount > 0 or isEquipped == true,
        isUsable = usable,
        cooldownInfo = cooldownInfo,
        isCooldown = isCooldown,
        borderColor = borderColor,
        count = bagCount
    }
end

---@param id number
function ItemCache:GetToyCacheInfo(id)
    local cooldownInfo = Api.GetItemCooldown(id)
    local isCooldown = Item:IsCooldown(cooldownInfo)
    local borderColor = const.DefaultItemColor
    local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent =
            Api.GetItemInfo(id)
        if itemQuality then
            borderColor = const.ItemQualityColor[itemQuality]
        end
    return {
        isLearned = PlayerHasToy(id),
        isUsable = C_ToyBox.IsToyUsable(id),
        cooldownInfo = cooldownInfo,
        isCooldown = isCooldown,
        borderColor = borderColor,
        count = nil
    }
end

---@param id number
function ItemCache:GetMountCacheInfo(id)
    local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight =
            C_MountJournal.GetMountInfoByID(id)
    return {
        isLearned = isCollected,
        isUsable = true,
        cooldownInfo = nil,
        isCooldown = nil,
        borderColor = const.DefaultItemColor,
        count = nil
    }
end

---@param item ItemAttr
function ItemCache:GetPetCacheInfo(item)
    local isLearned = false
    for petIndex = 1, C_PetJournal.GetNumPets() do
        local _, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable =
            C_PetJournal.GetPetInfoByIndex(petIndex)
        if speciesID == item.id then
            isLearned = true
            break
        end
    end
    local cooldownInfo = nil
    local _, petGUID = C_PetJournal.FindPetIDByName(item.name)
        if petGUID then
            local start, duration, isEnabled = C_PetJournal.GetPetCooldownByGUID(petGUID)
            cooldownInfo = {
                startTime = start,
                duration = duration,
                enable = isEnabled == 1
            }
        end
    local isCooldown = cooldownInfo and Item:IsCooldown(cooldownInfo) or nil
    return {
        isLearned = isLearned,
        isUsable = true,
        cooldownInfo = cooldownInfo,
        isCooldown = isCooldown,
        borderColor = const.DefaultItemColor,
        count = nil
    }
end

---@param item ItemAttr
function ItemCache:GetPetSpellInfo(item)
    local isLearned = IsSpellKnownOrOverridesKnown(item.id)
    local isUsable, _ = Api.IsSpellUsable(item.id)
    local spellCooldownInfo = Api.GetSpellCooldown(item.id)
    local cooldownInfo = nil
    if spellCooldownInfo then
        cooldownInfo = {
            startTime = spellCooldownInfo.startTime,
            duration = spellCooldownInfo.duration,
            enable = spellCooldownInfo.isEnabled
        }
    end
    local isCooldown = cooldownInfo and Item:IsCooldown(cooldownInfo) or nil
    local chargeInfo = Api.GetSpellCharges(item.id)
    local count = 1
    if chargeInfo then
        count = chargeInfo.currentCharges
    end
    return {
        isLearned = isLearned,
        isUsable = isUsable,
        cooldownInfo = cooldownInfo,
        isCooldown = isCooldown,
        borderColor = const.DefaultItemColor,
        count = count
    }
end

-- 通过itemAttr获取缓存数据，如果缓存没有则获取后返回
---@param item ItemAttr
---@return ItemCacheInfo
function ItemCache:Get(item)
    if item.type == const.ITEM_TYPE.ITEM then
        if ItemCache.item[item.id] ~= nil then
            return ItemCache.item[item.id]
        end
        ItemCache.item[item.id] = ItemCache:GetItemCacheInfo(item.id)
        return ItemCache.item[item.id]
    elseif item.type == const.ITEM_TYPE.EQUIPMENT then
        if ItemCache.equipment[item.id] ~= nil then
            return ItemCache.equipment[item.id]
        end
        ItemCache.equipment[item.id] = ItemCache:GetEquipmentCacheInfo(item.id)
        return ItemCache.equipment[item.id]
    elseif item.type == const.ITEM_TYPE.TOY then
        if ItemCache.toy[item.id] ~= nil then
            return ItemCache.toy[item.id]
        end
        ItemCache.toy[item.id] = ItemCache:GetToyCacheInfo(item.id)
        return ItemCache.toy[item.id]
    elseif item.type == const.ITEM_TYPE.MOUNT then
        if ItemCache.mount[item.id] ~= nil then
            return ItemCache.mount[item.id]
        end
        ItemCache.mount[item.id] = ItemCache:GetMountCacheInfo(item.id)
        return ItemCache.mount[item.id]
    elseif item.type == const.ITEM_TYPE.PET then
        if ItemCache.pet[item.id] ~= nil then
            return ItemCache.pet[item.id]
        end
        ItemCache.pet[item.id] = ItemCache:GetPetCacheInfo(item)
        return ItemCache.pet[item.id]
    else
        if ItemCache.spell[item.id] ~= nil then
            return ItemCache.spell[item.id]
        end
        ItemCache.spell[item.id] = ItemCache:GetPetSpellInfo(item)
        return ItemCache.spell[item.id]
    end
end


---@param event EventString
---@param eventArgs any
function ItemCache:Update(event, eventArgs)
    if event == "NEW_TOY_ADDED" then
        local itemId = tonumber(eventArgs[1])
        if itemId then
            if ItemCache.toy[itemId] ~= nil then
                
            end
            ItemCache.toy[itemId] = nil
        end
    end
    if event == "NEW_PET_ADDED" then
        local battlePetGUID = eventArgs[1]
        local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByPetID(battlePetGUID)
        if speciesID then
            ItemCache.pet[speciesID] = nil
        end
    end
    if event == "NEW_MOUNT_ADDED" then
        
    end
end