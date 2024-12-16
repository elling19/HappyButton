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
---@field isLearned boolean | nil
---@field isUsable boolean | nil
---@field isCooldown boolean | nil
---@field cooldownInfo CooldownInfo | nil
---@field borderColor RGBAColor | nil
---@field count number | nil

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


-- 通过itemAttr获取缓存数据，如果缓存没有则获取后返回
-- 获取的方式是渐进式的，只有缺少对应的属性才获取对应的属性，减少API的调用
---@param item ItemAttr
---@return ItemCacheInfo
function ItemCache:Get(item)
    if item.type == const.ITEM_TYPE.ITEM then
        if ItemCache.item[item.id] == nil then
            ItemCache.item[item.id] = {}
        end
        if ItemCache.item[item.id].count == nil then
            ItemCache.item[item.id].count = Api.GetItemCount(item.id, false)
            ItemCache.item[item.id].isLearned = ItemCache.item[item.id].count > 0
        end
        if ItemCache.item[item.id].isUsable == nil then
            local usable, _ = Api.IsUsableItem(item.id)
            ItemCache.item[item.id].isUsable = usable
        end
        if ItemCache.item[item.id].cooldownInfo == nil then
            ItemCache.item[item.id].cooldownInfo = Api.GetItemCooldown(item.id)
            ItemCache.item[item.id].isCooldown = Item:IsCooldown(ItemCache.item[item.id].cooldownInfo)
        end
        if ItemCache.item[item.id].borderColor == nil then
            local borderColor = const.DefaultItemColor
            local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent = Api.GetItemInfo(item.id)
            if itemQuality then
                borderColor = const.ItemQualityColor[itemQuality]
            end
            ItemCache.item[item.id].borderColor = borderColor
        end
        return ItemCache.item[item.id]
    elseif item.type == const.ITEM_TYPE.EQUIPMENT then
        if ItemCache.equipment[item.id] == nil then
            ItemCache.equipment[item.id] = {}
        end
        if ItemCache.equipment[item.id].count == nil then
            ItemCache.equipment[item.id].count = Api.GetItemCount(item.id, false)
        end
        if ItemCache.equipment[item.id].isLearned == nil then
            ItemCache.equipment[item.id].isLearned = ItemCache.equipment[item.id].count > 0 or Item:IsEquipped(item.id)
        end
        if ItemCache.equipment[item.id].isUsable == nil then
            local usable, _ = Api.IsUsableItem(item.id)
            ItemCache.equipment[item.id].isUsable = usable
        end
        if ItemCache.equipment[item.id].cooldownInfo == nil then
            ItemCache.equipment[item.id].cooldownInfo = Api.GetItemCooldown(item.id)
            ItemCache.equipment[item.id].isCooldown = Item:IsCooldown(ItemCache.equipment[item.id].cooldownInfo)
        end
        if ItemCache.equipment[item.id].borderColor == nil then
            local borderColor = const.DefaultItemColor
            local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent = Api.GetItemInfo(item.id)
            if itemQuality then
                borderColor = const.ItemQualityColor[itemQuality]
            end
            ItemCache.equipment[item.id].borderColor = borderColor
        end
        return ItemCache.equipment[item.id]
    elseif item.type == const.ITEM_TYPE.TOY then
        if ItemCache.toy[item.id] == nil then
            ItemCache.toy[item.id] = {}
        end
        if ItemCache.toy[item.id].isLearned == nil then
            ItemCache.toy[item.id].isLearned = PlayerHasToy(item.id)
        end
        if ItemCache.toy[item.id].isUsable == nil then
            ItemCache.toy[item.id].isUsable = C_ToyBox.IsToyUsable(item.id)
        end
        if ItemCache.toy[item.id].cooldownInfo == nil then
            ItemCache.toy[item.id].cooldownInfo = Api.GetItemCooldown(item.id)
            ItemCache.toy[item.id].isCooldown = Item:IsCooldown(ItemCache.toy[item.id].cooldownInfo)
        end
        if ItemCache.toy[item.id].borderColor == nil then
            local borderColor = const.DefaultItemColor
            local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent =
                    Api.GetItemInfo(item.id)
                if itemQuality then
                    borderColor = const.ItemQualityColor[itemQuality]
                end
            ItemCache.toy[item.id].borderColor = borderColor
        end
        return ItemCache.toy[item.id]
    elseif item.type == const.ITEM_TYPE.MOUNT then
        if ItemCache.mount[item.id] == nil then
            ItemCache.mount[item.id] = {}
        end
        if ItemCache.mount[item.id].isLearned == nil then
            local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight =
            C_MountJournal.GetMountInfoByID(item.id)
            ItemCache.mount[item.id].isLearned = isCollected
        end
        if ItemCache.mount[item.id].isUsable == nil then
            ItemCache.mount[item.id].isUsable = true
        end
        if ItemCache.mount[item.id].borderColor == nil then
            ItemCache.mount[item.id].borderColor = const.DefaultItemColor
        end
        return ItemCache.mount[item.id]
    elseif item.type == const.ITEM_TYPE.PET then
        if ItemCache.pet[item.id] == nil then
            ItemCache.pet[item.id] = {}
        end
        if ItemCache.pet[item.id].isLearned == nil then
            local isLearned = false
            for petIndex = 1, C_PetJournal.GetNumPets() do
                local _, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable =
                    C_PetJournal.GetPetInfoByIndex(petIndex)
                if speciesID == item.id then
                    isLearned = true
                    break
                end
            end
            ItemCache.pet[item.id].isLearned = isLearned
        end
        if ItemCache.pet[item.id].isUsable == nil then
            ItemCache.pet[item.id].isUsable = true
        end
        if ItemCache.pet[item.id].cooldownInfo == nil then
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
            ItemCache.pet[item.id].cooldownInfo = cooldownInfo
            ItemCache.pet[item.id].isCooldown = cooldownInfo and Item:IsCooldown(cooldownInfo) or nil
        end
        if ItemCache.pet[item.id].borderColor == nil then
            ItemCache.pet[item.id].borderColor = const.DefaultItemColor
        end
        return ItemCache.pet[item.id]
    else
        if ItemCache.spell[item.id] == nil then
            ItemCache.spell[item.id] = {}
        end
        if ItemCache.spell[item.id].isLearned == nil then
            ItemCache.spell[item.id].isLearned = IsSpellKnownOrOverridesKnown(item.id)
        end
        if ItemCache.spell[item.id].isUsable == nil then
            local isUsable, _ = Api.IsSpellUsable(item.id)
            ItemCache.spell[item.id].isUsable = isUsable
        end
        if ItemCache.spell[item.id].cooldownInfo == nil then
            local spellCooldownInfo = Api.GetSpellCooldown(item.id)
            local cooldownInfo = nil
            if spellCooldownInfo then
                cooldownInfo = {
                    startTime = spellCooldownInfo.startTime,
                    duration = spellCooldownInfo.duration,
                    enable = spellCooldownInfo.isEnabled
                }
            end
            ItemCache.spell[item.id].cooldownInfo = cooldownInfo
            ItemCache.spell[item.id].isCooldown = cooldownInfo and Item:IsCooldown(cooldownInfo) or nil
        end
        if ItemCache.spell[item.id].count == nil then
            local chargeInfo = Api.GetSpellCharges(item.id)
            local count = 1
            if chargeInfo then
                count = chargeInfo.currentCharges
            end
            ItemCache.spell[item.id].count = count
        end
        if ItemCache.spell[item.id].borderColor == nil then
            ItemCache.spell[item.id].borderColor = const.DefaultItemColor
        end
        return ItemCache.spell[item.id]
    end
end


---@param event EventString
---@param eventArgs any
---@return EventString, any
function ItemCache:Update(event, eventArgs)
    if event == "NEW_TOY_ADDED" then
        local itemId = tonumber(eventArgs[1])
        if itemId then
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
        local mountID = eventArgs[1]
        if mountID then
            ItemCache.mount[mountID] = nil
        end
    end
    if event == "BAG_UPDATE" then
        for id, _ in pairs(ItemCache.item) do
            ItemCache.item[id].isLearned = nil
            ItemCache.item[id].count = nil
        end
        for id, _ in pairs(ItemCache.equipment) do
            ItemCache.equipment[id].isLearned = nil
            ItemCache.equipment[id].count = nil
        end
    end
    if event == "SPELLS_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
        for id, _ in pairs(ItemCache.spell) do
            ItemCache.spell[id] = nil
        end
    end
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        for id, _ in pairs(ItemCache.spell) do
            ItemCache.spell[id].cooldownInfo = nil
            ItemCache.spell[id].isCooldown = nil
            ItemCache.spell[id].count = nil
        end
        for id, _ in pairs(ItemCache.equipment) do
            ItemCache.equipment[id].cooldownInfo = nil
            ItemCache.equipment[id].isCooldown = nil
        end
        for id, _ in pairs(ItemCache.item) do
            ItemCache.item[id].cooldownInfo = nil
            ItemCache.item[id].isCooldown = nil
        end
        for id, _ in pairs(ItemCache.pet) do
            ItemCache.pet[id].cooldownInfo = nil
            ItemCache.pet[id].isCooldown = nil
        end
    end
    if event == "SPELL_UPDATE_CHARGES" then
        for id, _ in pairs(ItemCache.spell) do
            ItemCache.spell[id].count = nil
        end
    end
    return event, eventArgs
end