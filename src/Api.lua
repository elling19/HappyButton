---@diagnostic disable: undefined-field
local addonName, _ = ... ---@type string, table
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Client: AceModule
local Client = addon:GetModule("Client")

---@class Api: AceModule
local Api = addon:NewModule("Api")

Api.GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) and C_Item.GetItemInfoInstant or GetItemInfoInstant
Api.GetItemInfo = (C_Item and C_Item.GetItemInfo) and C_Item.GetItemInfo or GetItemInfo
Api.GetItemCooldown = (C_Item and C_Item.GetItemCooldown) and C_Item.GetItemCooldown or C_Container.GetItemCooldown or GetItemCooldown
Api.GetItemCount = (C_Item and C_Item.GetItemCount) and C_Item.GetItemCount or GetItemCount
Api.IsUsableItem = (C_Item and C_Item.IsUsableItem) and C_Item.IsUsableItem or IsUsableItem
Api.GetSpellCharges = (C_Spell and C_Spell.GetSpellCharges) and C_Spell.GetSpellCharges or GetSpellCharges
Api.IsSpellUsable = (C_Spell and C_Spell.IsSpellUsable) and C_Spell.IsSpellUsable or IsUsableSpell
Api.GetSpellTexture = (C_Spell and C_Spell.GetSpellTexture) and C_Spell.GetSpellTexture or GetSpellTexture

---@param spellIdentifier string | number
---@return SpellInfo?
Api.GetSpellInfo = function (spellIdentifier)
    if C_Spell and C_Spell.GetSpellInfo then
        return C_Spell.GetSpellInfo(spellIdentifier)
    else
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
---@return SpellCooldownInfo
Api.GetSpellCooldown = function (spellIdentifier)
    if C_Spell and C_Spell.GetSpellCooldown then
        return C_Spell.GetSpellCooldown(spellIdentifier)
    else
        local start, duration, enabled, modRate = GetSpellCooldown(spellIdentifier)
        ---@type SpellCooldownInfo
        local spellCooldownInfo = {
            duration = duration,
            isEnabled = enabled == 1,
            modRate = modRate,
            startTime = start
        }
        return spellCooldownInfo
    end
end

---@param unitId UnitToken
---@param index number UnitAura 支持index和name，C_UnitAuras.GetBuffDataByIndex只支持number，
---@param filter string? UnitAura 支持“|”和“空格”拆分，C_UnitAuras.GetBuffDataByIndex支持管道符和空格
---@return {expirationTime: number, spellId: number}?
Api.GetBuffDataByIndex = function (unitId, index, filter)
    if C_UnitAuras and C_UnitAuras.GetBuffDataByIndex then
        local auraData = C_UnitAuras.GetBuffDataByIndex(unitId, index, filter)
        if auraData == nil then
            return nil
        end
        local result = {
            expirationTime = auraData.expirationTime,
            spellId = auraData.spellId
        }
        return result
    else
        local name, icon, count, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod = UnitAura(unitId, index, filter)
        if name then
            local result = {
                expirationTime = expirationTime,
                spellId = spellId
            }
            return result
        end
        return nil
    end
end