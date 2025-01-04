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

---@class PlayerCache: AceModule
local PlayerCache = addon:GetModule("PlayerCache")

---@class ItemCacheInfo
---@field isLearned boolean | nil
---@field isUsable boolean | nil
---@field cooldownInfo CooldownInfo | nil
---@field borderColor RGBAColor | nil
---@field count number | nil

---@class ItemCacheTaskInfo
---@field item ItemCacheInfo
---@field listenIsLearned true | nil
---@field listenIsUsable true | nil
---@field listenIsCooldown true | nil
---@field listenCooldownRemainingTimes number[]

---@class ItemCacheGcd
---@field cooldownInfo CooldownInfo | nil


---@class ItemCache: AceModule
---@field cache table<number, table<number, ItemCacheTaskInfo>>
---@field gcd ItemCacheGcd
local ItemCache = addon:NewModule("ItemCache")

local GetTime = GetTime



function ItemCache:Initial()
    ItemCache.cache = {
        [const.ITEM_TYPE.ITEM] = {},
        [const.ITEM_TYPE.EQUIPMENT] = {},
        [const.ITEM_TYPE.SPELL] = {},
        [const.ITEM_TYPE.TOY] = {},
        [const.ITEM_TYPE.MOUNT] = {},
        [const.ITEM_TYPE.PET] = {},
    }
    ItemCache.gcd = {}
end


-- TODO: 通过itemAttr获取缓存数据，如果缓存没有则获取后返回
-- 获取的方式是渐进式的，只有缺少对应的属性才获取对应的属性，减少API的调用
---@param item ItemAttr
---@return ItemCacheInfo
function ItemCache:Get(item)
    if item.type == const.ITEM_TYPE.ITEM then
        if ItemCache.cache[const.ITEM_TYPE.ITEM][item.id] == nil then
            ItemCache.cache[const.ITEM_TYPE.ITEM][item.id] = {}
        end
        if ItemCache.cache[const.ITEM_TYPE.ITEM][item.id].count == nil then
            ItemCache.cache[const.ITEM_TYPE.ITEM][item.id].count = Api.GetItemCount(item.id, false)
            ItemCache.cache[const.ITEM_TYPE.ITEM][item.id].isLearned = ItemCache.cache[const.ITEM_TYPE.ITEM][item.id].count > 0
        end
        if ItemCache.cache[const.ITEM_TYPE.ITEM][item.id].isUsable == nil then
            local usable, _ = Api.IsUsableItem(item.id)
            ItemCache.cache[const.ITEM_TYPE.ITEM][item.id].isUsable = usable
        end
        if ItemCache.cache[const.ITEM_TYPE.ITEM][item.id].cooldownInfo == nil then
            ItemCache.cache[const.ITEM_TYPE.ITEM][item.id].cooldownInfo = Api.GetItemCooldown(item.id)
            ItemCache.cache[const.ITEM_TYPE.ITEM][item.id].isCooldown = Item:IsCooldown(ItemCache.cache[const.ITEM_TYPE.ITEM][item.id].cooldownInfo)
        end
        if ItemCache.cache[const.ITEM_TYPE.ITEM][item.id].borderColor == nil then
            local borderColor = const.DefaultItemColor
            local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent = Api.GetItemInfo(item.id)
            if itemQuality then
                borderColor = const.ItemQualityColor[itemQuality]
            end
            ItemCache.cache[const.ITEM_TYPE.ITEM][item.id].borderColor = borderColor
        end
        return ItemCache.cache[const.ITEM_TYPE.ITEM][item.id]
    elseif item.type == const.ITEM_TYPE.EQUIPMENT then
        if ItemCache.cache[const.ITEM_TYPE.EQUIPMENT][item.id] == nil then
            ItemCache.cache[const.ITEM_TYPE.EQUIPMENT][item.id] = {}
        end
        if ItemCache.cache[const.ITEM_TYPE.EQUIPMENT][item.id].count == nil then
            ItemCache.cache[const.ITEM_TYPE.EQUIPMENT][item.id].count = Api.GetItemCount(item.id, false)
        end
        if ItemCache.cache[const.ITEM_TYPE.EQUIPMENT][item.id].isLearned == nil then
            ItemCache.cache[const.ITEM_TYPE.EQUIPMENT][item.id].isLearned = ItemCache.cache[const.ITEM_TYPE.EQUIPMENT][item.id].count > 0 or Item:IsEquipped(item.id)
        end
        if ItemCache.cache[const.ITEM_TYPE.EQUIPMENT][item.id].isUsable == nil then
            local usable, _ = Api.IsUsableItem(item.id)
            ItemCache.cache[const.ITEM_TYPE.EQUIPMENT][item.id].isUsable = usable
        end
        if ItemCache.cache[const.ITEM_TYPE.EQUIPMENT][item.id].cooldownInfo == nil then
            ItemCache.cache[const.ITEM_TYPE.EQUIPMENT][item.id].cooldownInfo = Api.GetItemCooldown(item.id)
            ItemCache.cache[const.ITEM_TYPE.EQUIPMENT][item.id].isCooldown = Item:IsCooldown(ItemCache.cache[const.ITEM_TYPE.EQUIPMENT][item.id].cooldownInfo)
        end
        if ItemCache.cache[const.ITEM_TYPE.EQUIPMENT][item.id].borderColor == nil then
            local borderColor = const.DefaultItemColor
            local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent = Api.GetItemInfo(item.id)
            if itemQuality then
                borderColor = const.ItemQualityColor[itemQuality]
            end
            ItemCache.cache[const.ITEM_TYPE.EQUIPMENT][item.id].borderColor = borderColor
        end
        return ItemCache.cache[const.ITEM_TYPE.EQUIPMENT][item.id]
    elseif item.type == const.ITEM_TYPE.TOY then
        if ItemCache.cache[const.ITEM_TYPE.TOY][item.id] == nil then
            ItemCache.cache[const.ITEM_TYPE.TOY][item.id] = {}
        end
        if ItemCache.cache[const.ITEM_TYPE.TOY][item.id].isLearned == nil then
            ItemCache.cache[const.ITEM_TYPE.TOY][item.id].isLearned = PlayerHasToy(item.id)
        end
        if ItemCache.cache[const.ITEM_TYPE.TOY][item.id].isUsable == nil then
            ItemCache.cache[const.ITEM_TYPE.TOY][item.id].isUsable = C_ToyBox.IsToyUsable(item.id)
        end
        if ItemCache.cache[const.ITEM_TYPE.TOY][item.id].cooldownInfo == nil then
            ItemCache.cache[const.ITEM_TYPE.TOY][item.id].cooldownInfo = Api.GetItemCooldown(item.id)
            ItemCache.cache[const.ITEM_TYPE.TOY][item.id].isCooldown = Item:IsCooldown(ItemCache.cache[const.ITEM_TYPE.TOY][item.id].cooldownInfo)
        end
        if ItemCache.cache[const.ITEM_TYPE.TOY][item.id].borderColor == nil then
            local borderColor = const.DefaultItemColor
            local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent =
                    Api.GetItemInfo(item.id)
                if itemQuality then
                    borderColor = const.ItemQualityColor[itemQuality]
                end
            ItemCache.cache[const.ITEM_TYPE.TOY][item.id].borderColor = borderColor
        end
        return ItemCache.cache[const.ITEM_TYPE.TOY][item.id]
    elseif item.type == const.ITEM_TYPE.MOUNT then
        if ItemCache.cache[const.ITEM_TYPE.MOUNT][item.id] == nil then
            ItemCache.cache[const.ITEM_TYPE.MOUNT][item.id] = {}
        end
        if ItemCache.cache[const.ITEM_TYPE.MOUNT][item.id].isLearned == nil then
            local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight =
            C_MountJournal.GetMountInfoByID(item.id)
            ItemCache.cache[const.ITEM_TYPE.MOUNT][item.id].isLearned = isCollected
        end
        if ItemCache.cache[const.ITEM_TYPE.MOUNT][item.id].isUsable == nil then
            ItemCache.cache[const.ITEM_TYPE.MOUNT][item.id].isUsable = true
        end
        if ItemCache.cache[const.ITEM_TYPE.MOUNT][item.id].borderColor == nil then
            ItemCache.cache[const.ITEM_TYPE.MOUNT][item.id].borderColor = const.DefaultItemColor
        end
        return ItemCache.cache[const.ITEM_TYPE.MOUNT][item.id]
    elseif item.type == const.ITEM_TYPE.PET then
        if ItemCache.cache[const.ITEM_TYPE.PET][item.id] == nil then
            ItemCache.cache[const.ITEM_TYPE.PET][item.id] = {}
        end
        if ItemCache.cache[const.ITEM_TYPE.PET][item.id].isLearned == nil then
            local isLearned = false
            for petIndex = 1, C_PetJournal.GetNumPets() do
                local _, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable =
                    C_PetJournal.GetPetInfoByIndex(petIndex)
                if speciesID == item.id then
                    isLearned = true
                    break
                end
            end
            ItemCache.cache[const.ITEM_TYPE.PET][item.id].isLearned = isLearned
        end
        if ItemCache.cache[const.ITEM_TYPE.PET][item.id].isUsable == nil then
            ItemCache.cache[const.ITEM_TYPE.PET][item.id].isUsable = true
        end
        if ItemCache.cache[const.ITEM_TYPE.PET][item.id].cooldownInfo == nil then
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
            ItemCache.cache[const.ITEM_TYPE.PET][item.id].cooldownInfo = cooldownInfo
            ItemCache.cache[const.ITEM_TYPE.PET][item.id].isCooldown = cooldownInfo and Item:IsCooldown(cooldownInfo) or nil
        end
        if ItemCache.cache[const.ITEM_TYPE.PET][item.id].borderColor == nil then
            ItemCache.cache[const.ITEM_TYPE.PET][item.id].borderColor = const.DefaultItemColor
        end
        return ItemCache.cache[const.ITEM_TYPE.PET][item.id]
    else
        if ItemCache.cache[const.ITEM_TYPE.SPELL][item.id] == nil then
            ItemCache.cache[const.ITEM_TYPE.SPELL][item.id] = {}
        end
        if ItemCache.cache[const.ITEM_TYPE.SPELL][item.id].isLearned == nil then
            ItemCache.cache[const.ITEM_TYPE.SPELL][item.id].isLearned = IsSpellKnownOrOverridesKnown(item.id)
        end
        if ItemCache.cache[const.ITEM_TYPE.SPELL][item.id].isUsable == nil then
            local isUsable, _ = Api.IsSpellUsable(item.id)
            ItemCache.cache[const.ITEM_TYPE.SPELL][item.id].isUsable = isUsable
        end
        if ItemCache.cache[const.ITEM_TYPE.SPELL][item.id].cooldownInfo == nil then
            local cooldownInfo = Api.GetSpellCooldown(item.id)
            ItemCache.cache[const.ITEM_TYPE.SPELL][item.id].cooldownInfo = cooldownInfo
            ItemCache.cache[const.ITEM_TYPE.SPELL][item.id].isCooldown = cooldownInfo and Item:IsCooldown(cooldownInfo) or nil
        end
        if ItemCache.cache[const.ITEM_TYPE.SPELL][item.id].count == nil then
            local chargeInfo = Api.GetSpellCharges(item.id)
            local count = 1
            if chargeInfo then
                count = chargeInfo.currentCharges
            end
            ItemCache.cache[const.ITEM_TYPE.SPELL][item.id].count = count
        end
        if ItemCache.cache[const.ITEM_TYPE.SPELL][item.id].borderColor == nil then
            ItemCache.cache[const.ITEM_TYPE.SPELL][item.id].borderColor = const.DefaultItemColor
        end
        return ItemCache.cache[const.ITEM_TYPE.SPELL][item.id]
    end
end


-- TODO: 目前物品更新由各个itemBtn负责处理，后续考虑是否需要统一处理
---@param event EventString
---@param eventArgs any
---@return EventString, any
function ItemCache:Update1(event, eventArgs)
    if event == "NEW_TOY_ADDED" then
        local itemId = tonumber(eventArgs[1])
        if itemId then
            ItemCache.cache[const.ITEM_TYPE.TOY][itemId] = nil
        end
    end
    if event == "NEW_PET_ADDED" then
        local battlePetGUID = eventArgs[1]
        local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, sourceText, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByPetID(battlePetGUID)
        if speciesID then
            ItemCache.cache[const.ITEM_TYPE.PET][speciesID] = nil
        end
    end
    if event == "NEW_MOUNT_ADDED" then
        local mountID = eventArgs[1]
        if mountID then
            ItemCache.cache[const.ITEM_TYPE.MOUNT][mountID] = nil
        end
    end
    if event == "BAG_UPDATE" then
        for id, _ in pairs(ItemCache.cache[const.ITEM_TYPE.ITEM]) do
            ItemCache.cache[const.ITEM_TYPE.ITEM][id].item.isLearned = nil
            ItemCache.cache[const.ITEM_TYPE.ITEM][id].item.count = nil
        end
        for id, _ in pairs(ItemCache.cache[const.ITEM_TYPE.EQUIPMENT]) do
            ItemCache.cache[const.ITEM_TYPE.EQUIPMENT][id].item.isLearned = nil
            ItemCache.cache[const.ITEM_TYPE.EQUIPMENT][id].item.count = nil
        end
    end
    if event == "SPELLS_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
        for id, _ in pairs(ItemCache.cache[const.ITEM_TYPE.SPELL]) do
            ItemCache.cache[const.ITEM_TYPE.SPELL][id] = nil
        end
    end
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        for id, _ in pairs(ItemCache.cache[const.ITEM_TYPE.SPELL]) do
            ItemCache.cache[const.ITEM_TYPE.SPELL][id].item.cooldownInfo = nil
            ItemCache.cache[const.ITEM_TYPE.SPELL][id].item.count = nil
        end
        for id, _ in pairs(ItemCache.cache[const.ITEM_TYPE.EQUIPMENT]) do
            ItemCache.cache[const.ITEM_TYPE.EQUIPMENT][id].item.cooldownInfo = nil
        end
        for id, _ in pairs(ItemCache.cache[const.ITEM_TYPE.ITEM]) do
            ItemCache.cache[const.ITEM_TYPE.ITEM][id].item.cooldownInfo = nil
        end
        for id, _ in pairs(ItemCache.cache[const.ITEM_TYPE.PET]) do
            ItemCache.cache[const.ITEM_TYPE.PET][id].item.cooldownInfo = nil
        end
    end
    if event == "SPELL_UPDATE_CHARGES" then
        for id, _ in pairs(ItemCache.cache[const.ITEM_TYPE.SPELL]) do
            ItemCache.cache[const.ITEM_TYPE.SPELL][id].item.count = nil
        end
    end
    return event, eventArgs
end


function ItemCache:Update(event, eventArgs)
    local now = GetTime()
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        for _, item_type in ipairs({const.ITEM_TYPE.ITEM, const.ITEM_TYPE.EQUIPMENT, const.ITEM_TYPE.TOY}) do
            for id, taskInfo in pairs(ItemCache.cache[item_type]) do
                if taskInfo.listenIsCooldown == true or #taskInfo.listenCooldownRemainingTimes ~= 0 then
                    local cooldownInfo = Api.GetItemCooldown(id)
                    if cooldownInfo ~= nil then
                        local lastCooldownInfo = taskInfo.item.cooldownInfo
                        if lastCooldownInfo == nil then
                            ItemCache:CreateTickerTask(item_type, id)
                        else
                            if lastCooldownInfo.startTime ~= cooldownInfo.startTime then
                                -- 如果上一个冷却事件还没有结束，那么重新触发
                                if lastCooldownInfo.startTime + lastCooldownInfo.duration > now then
                                    ItemCache:CreateTickerTask(item_type, id)
                                end
                            end
                        end
                        taskInfo.item.cooldownInfo = cooldownInfo
                    end
                end
            end
        end
        for id, taskInfo in pairs(ItemCache.cache[const.ITEM_TYPE.SPELL]) do
            if taskInfo.listenIsCooldown == true or #taskInfo.listenCooldownRemainingTimes ~= 0 then
                local cooldownInfo = Api.GetSpellCooldown(id)
                if cooldownInfo ~= nil then
                    local needSendMessageNow = false
                    local lastCooldownInfo = taskInfo.item.cooldownInfo
                    if lastCooldownInfo == nil then
                        needSendMessageNow = true
                    else
                        if lastCooldownInfo.startTime ~= cooldownInfo.startTime then
                            needSendMessageNow = true
                        end
                    end
                    taskInfo.item.cooldownInfo = cooldownInfo
                    if needSendMessageNow == true then
                        ItemCache:CreateTickerTask(const.ITEM_TYPE.SPELL, id)
                    end
                end
            end
        end
    end
end

--- 按aura来更新目标任务
---@param type number
---@param itemId number
function ItemCache:CreateTickerTask(type, itemId)
    if ItemCache.cache[type][itemId] == nil then
        return
    end
    local taskInfo = ItemCache.cache[type][itemId]
    local cooldownInfo = taskInfo.item.cooldownInfo
    if cooldownInfo == nil then
        return
    end
    local now = GetTime()
    local cooldownTime = cooldownInfo.startTime + cooldownInfo.duration
    if taskInfo.listenIsCooldown == true then
        if cooldownTime > now then
            C_Timer.NewTimer(cooldownTime - now + 0.05, function ()
                addon:SendMessage(const.EVENT.HB_ITEM_COOLDOWN_CHNAGED)
            end)
        end
    end
    if taskInfo.listenCooldownRemainingTimes then
        for _, remainingTime in ipairs(taskInfo.listenCooldownRemainingTimes) do
            if cooldownTime - remainingTime > now then
                C_Timer.NewTimer(cooldownTime - remainingTime - now + 0.05, function ()
                    addon:SendMessage(const.EVENT.HB_ITEM_COOLDOWN_CHNAGED)
                end)
            end
        end
    end
end

-- 在缓存中添加新的追踪信息
---@param item ItemAttr
function ItemCache:PutTask(item, isLearned, isUsable, isCooldown, remainingTime)
    if ItemCache.cache[item.type][item.id] == nil then
        ---@type ItemCacheTaskInfo
        ItemCache.cache[item.type][item.id] = {
            item = {},
            listenCooldownRemainingTimes = {},
        }
    end
    if isLearned ~= nil then
        ItemCache.cache[item.type][item.id].listenIsLearned = true
    end
    if isUsable ~= nil then
        ItemCache.cache[item.type][item.id].listenIsUsable = true
    end
    if isCooldown ~= nil then
        ItemCache.cache[item.type][item.id].listenIsCooldown = true
    end
    if remainingTime ~= nil then
        if U.Table.IsInArray(ItemCache.cache[item.type][item.id].listenCooldownRemainingTimes, remainingTime) == false then
            table.insert(ItemCache.cache[item.type][item.id].listenCooldownRemainingTimes, remainingTime)
        end
    end
end


function ItemCache:UpdateGcd()
    local cooldownInfo = Api.GetSpellCooldown(PlayerCache.gcdSpellId)
    if cooldownInfo == nil then
        return
    end
    local needSendMessage = false
    if ItemCache.gcd == nil or ItemCache.gcd.cooldownInfo == nil or ItemCache.gcd.cooldownInfo.startTime == nil then
        -- 如果上一次的GCD信息无效，则更新
        needSendMessage = true
    elseif ItemCache.gcd.cooldownInfo.startTime ~= cooldownInfo.startTime then
        -- 重新触发GCD，则更新
        if cooldownInfo.startTime ~= 0 then
            needSendMessage = true
        else
            -- 如果是GCD完成，或者取消
            -- 如果上一次的GCD开始事件+GCD事件<当前时间，表示上一个GCD已经完成，无须更新
            if ItemCache.gcd.cooldownInfo.startTime + ItemCache.gcd.cooldownInfo.duration > GetTime() then
                needSendMessage = true
            end
        end
    end
    ItemCache.gcd.cooldownInfo = cooldownInfo
    if needSendMessage == true then
        addon:SendMessage(const.EVENT.HB_GCD_UPDATE)
    end
end