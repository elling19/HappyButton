---@diagnostic disable: undefined-field, undefined-global
local addonName, _ = ... ---@type string, table
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Client: AceModule
local Client = addon:GetModule("Client")

---@class Api: AceModule
local Api = addon:NewModule("Api")

local C_Spell = C_Spell
local C_Item = C_Item
local C_ToyBox = C_ToyBox
---@diagnostic disable-next-line: deprecated
local GetSpellCooldown = GetSpellCooldown
---@diagnostic disable-next-line: deprecated
local GetItemCooldown = GetItemCooldown

---@diagnostic disable-next-line: deprecated
Api.GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) and C_Item.GetItemInfoInstant or GetItemInfoInstant
---@diagnostic disable-next-line: deprecated
Api.GetItemInfo = (C_Item and C_Item.GetItemInfo) and C_Item.GetItemInfo or GetItemInfo
---@diagnostic disable-next-line: deprecated
Api.GetItemCount = (C_Item and C_Item.GetItemCount) and C_Item.GetItemCount or GetItemCount
---@diagnostic disable-next-line: deprecated
Api.IsUsableItem = (C_Item and C_Item.IsUsableItem) and C_Item.IsUsableItem or IsUsableItem
---@diagnostic disable-next-line: deprecated
Api.GetSpellCharges = (C_Spell and C_Spell.GetSpellCharges) and C_Spell.GetSpellCharges or GetSpellCharges
---@diagnostic disable-next-line: deprecated
Api.IsSpellUsable = (C_Spell and C_Spell.IsSpellUsable) and C_Spell.IsSpellUsable or IsUsableSpell
---@diagnostic disable-next-line: deprecated
Api.GetSpellTexture = (C_Spell and C_Spell.GetSpellTexture) and C_Spell.GetSpellTexture or GetSpellTexture
---@diagnostic disable-next-line: deprecated
Api.IsEquippedItemType = (C_Item and C_Item.IsEquippedItemType) and C_Item.IsEquippedItemType or IsEquippedItemType

---@param spellIdentifier string | number
---@return SpellInfo?
Api.GetSpellInfo = function (spellIdentifier)
    if C_Spell and C_Spell.GetSpellInfo then
        return C_Spell.GetSpellInfo(spellIdentifier)
    else
        ---@diagnostic disable-next-line: deprecated
        local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(spellIdentifier)
        if spellID == nil then
            return nil
        end
        ---@type SpellInfo
        local spellInfo = {
            name = name,
            iconID = icon,
            originalIconID = originalIcon,
            castTime = castTime,
            minRange = minRange,
            maxRange = maxRange,
            spellID = spellID
        }
        return spellInfo
    end
end

---@param spellIdentifier string | number
---@return DurationObject | nil
Api.GetSpellCooldown = function (spellIdentifier)
    if C_Spell and C_Spell.GetSpellCooldownDuration then
        local durationObject = C_Spell.GetSpellCooldownDuration(spellIdentifier)
        if durationObject ~= nil then
            return durationObject
        end
    end

    if C_Spell and C_Spell.GetSpellCooldown then
        local spellCooldownInfo = C_Spell.GetSpellCooldown(spellIdentifier)
        if spellCooldownInfo ~= nil then
            local enabledValue = spellCooldownInfo.enable
            if enabledValue == nil then
                enabledValue = spellCooldownInfo.isEnabled
            end
            local isEnabled = enabledValue == 1 or enabledValue == true
            return {
                startTime = spellCooldownInfo.startTime or 0,
                duration = spellCooldownInfo.duration or 0,
                enable = isEnabled,
                isEnabled = isEnabled,
                modRate = spellCooldownInfo.modRate or 1,
            }
        end
    end
    if GetSpellCooldown then
        ---@diagnostic disable-next-line: deprecated
        local startTime, duration, enabled = GetSpellCooldown(spellIdentifier)
        local isEnabled = enabled == 1 or enabled == true
        return {
            startTime = startTime,
            duration = duration,
            enable = isEnabled,
            isEnabled = isEnabled,
            modRate = 1,
        }
    end
    return nil
end

---@param itemIdentifier string | number
---@return NonSpellCooldownInfo | nil
Api.GetItemCooldown = function (itemIdentifier)
    -- 物品/玩具走旧冷却数据路径，避免将 number 直接传入转换函数。
    if GetItemCooldown then
        local startTime, duration, enable = GetItemCooldown(itemIdentifier)
        local isEnabled = enable == 1 or enable == true
        return {
            startTime = startTime,
            duration = duration,
            enable = isEnabled,
            isEnabled = isEnabled,
            modRate = 1,
        }
    end

    if C_Item and C_Item.GetItemCooldown then
        local startTimeSeconds, durationSeconds, enableCooldownTimer = C_Item.GetItemCooldown(itemIdentifier)
        local isEnabled = enableCooldownTimer == 1 or enableCooldownTimer == true
        return {
            startTime = startTimeSeconds,
            duration = durationSeconds,
            enable = isEnabled,
            isEnabled = isEnabled,
            modRate = 1,
        }
    end

    return nil
end

---@param itemIdentifier string | number
---@return NonSpellCooldownInfo | nil
Api.GetToyCooldown = function (itemIdentifier)
    if C_ToyBox and C_ToyBox.GetToyCooldown then
        local startTime, duration, enable = C_ToyBox.GetToyCooldown(itemIdentifier)
        local isEnabled = enable == 1 or enable == true
        return {
            startTime = startTime,
            duration = duration,
            enable = isEnabled,
            isEnabled = isEnabled,
            modRate = 1,
        }
    end
    return nil
end
