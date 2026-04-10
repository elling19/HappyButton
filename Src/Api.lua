---@diagnostic disable: undefined-field, undefined-global
local addonName, _ = ... ---@type string, table
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Client: AceModule
local Client = addon:GetModule("Client")

---@class Api: AceModule
local Api = addon:NewModule("Api")

local C_Spell = C_Spell
local C_Item = C_Item
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
---@return any | nil
Api.GetSpellCooldown = function (spellIdentifier)
    if C_Spell and C_Spell.GetSpellCooldown then
        local spellCooldownInfo = C_Spell.GetSpellCooldown(spellIdentifier)
        if spellCooldownInfo ~= nil then
            -- 优先返回客户端原生对象，供 SetCooldownFromDurationObject 使用
            return spellCooldownInfo
        end
    end
    if GetSpellCooldown then
        ---@diagnostic disable-next-line: deprecated
        local startTime, duration, enabled = GetSpellCooldown(spellIdentifier)
        if startTime ~= nil then
            return {
                startTime = startTime,
                duration = duration,
                enable = enabled == 1,
            }
        end
    end
    return nil
end

---@param itemIdentifier string | number
---@return any | nil
Api.GetItemCooldown = function (itemIdentifier)
    if C_Item and C_Item.GetItemCooldown then
        local cooldownInfo = C_Item.GetItemCooldown(itemIdentifier)
        if type(cooldownInfo) == "table" then
            -- 优先返回客户端原生对象，供 SetCooldownFromDurationObject 使用
            return cooldownInfo
        end

        local startTimeSeconds, durationSeconds, enableCooldownTimer = C_Item.GetItemCooldown(itemIdentifier)
        if startTimeSeconds ~= nil then
            return {
                startTime = startTimeSeconds,
                duration = durationSeconds,
                enable = enableCooldownTimer == 1 or enableCooldownTimer == true,
                isEnabled = enableCooldownTimer == 1 or enableCooldownTimer == true,
            }
        end
    end

    if GetItemCooldown then
        ---@diagnostic disable-next-line: deprecated
        local startTime, duration, enable = GetItemCooldown(itemIdentifier)
        if startTime ~= nil then
            return {
                startTime = startTime,
                duration = duration,
                enable = enable == 1,
            }
        end
    end

    return nil
end
