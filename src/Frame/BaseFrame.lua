local addonName, _ = ...  ---@type string, table

---@class HappyToolkit: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class LoadConfig: AceModule
local LoadConfig = addon:GetModule('LoadConfig')
---@type LoadConfig

---@class BaseFrame: AceModule
local BaseFrame = addon:NewModule("BaseFrame")


-- 更新pool的宏文案
function BaseFrame:SetPoolMacro(mode, pool)
    local callbackResult = pool._callbackResult
    if callbackResult == nil or callbackResult.item == nil then
        return
    end
    if pool.button == nil then
        return
    end
    -- 设置宏命令
    pool.button:SetAttribute("type", "macro") -- 设置按钮为宏类型
    if callbackResult.icon then
        pool.button:SetNormalTexture(callbackResult.icon)
    end
    local macroText = ""
    if callbackResult.item.type == const.ITEM_TYPE.ITEM then
        macroText = "/use item:" .. callbackResult.item.id
    elseif callbackResult.item.type == const.ITEM_TYPE.TOY then
        macroText = "/use item:" .. callbackResult.item.id
    elseif callbackResult.item.type == const.ITEM_TYPE.SPELL then
        macroText = "/cast " .. callbackResult.item.name
    elseif callbackResult.item.type == const.ITEM_TYPE.MOUNT then
        macroText = "/cast " .. callbackResult.item.name
    elseif callbackResult.item.type == const.ITEM_TYPE.PET then
        macroText = "/SummonPet " .. callbackResult.item.name
    end
    -- 宏命令附加更新冷却计时
    macroText = macroText .. "\r" .. ("/sethappytoolkitguicooldown %s %s %s"):format(mode, pool._cateIndex, pool._poolIndex)
    -- 宏命令附加关闭窗口
    if callbackResult.closeGUIAfterClick == nil or callbackResult.closeGUIAfterClick == true then
        macroText = macroText .. "\r" .. "/closehtmainframe"
    end
    pool.button:SetAttribute("macrotext", macroText)
    if callbackResult.text and pool.text then
        pool.text:SetText(U.String.ToVertical(callbackResult.text))
    end
end

-- 设置pool的冷却
function BaseFrame:SetPoolCooldown(pool)
    if pool.button == nil then
        return
    end
    local callbackResult = pool._callbackResult
    if callbackResult == nil or callbackResult.item == nil then
        return
    end
    if pool.button.cooldown == nil then
        -- 创建冷却效果
        pool.button.cooldown = CreateFrame("Cooldown", nil, pool.button, "CooldownFrameTemplate")
        pool.button.cooldown:SetAllPoints(pool.button)  -- 设置冷却效果覆盖整个按钮
        pool.button.cooldown:SetDrawEdge(true)  -- 显示边缘
        pool.button.cooldown:SetHideCountdownNumbers(true)  -- 隐藏倒计时数字
    end
    local item = callbackResult.item
    -- 更新冷却倒计时
    if item.type == const.ITEM_TYPE.ITEM then
        local startTimeSeconds, durationSeconds, enableCooldownTimer = C_Item.GetItemCooldown(item.id)
        if enableCooldownTimer and durationSeconds > 0 then
            pool.button.cooldown:SetCooldown(startTimeSeconds, durationSeconds)
        else
            pool.button.cooldown:Clear()
        end
    elseif item.type == const.ITEM_TYPE.TOY then
        local startTimeSeconds, durationSeconds, enableCooldownTimer = C_Item.GetItemCooldown(item.id)
        if enableCooldownTimer and durationSeconds > 0 then
            pool.button.cooldown:SetCooldown(startTimeSeconds, durationSeconds)
        else
            pool.button.cooldown:Clear()
        end
    elseif item.type == const.ITEM_TYPE.SPELL then
        local spellCooldownInfo = C_Spell.GetSpellCooldown(item.id)
        if spellCooldownInfo and spellCooldownInfo.isEnabled == true and spellCooldownInfo.duration > 0 then
            pool.button.cooldown:SetCooldown(spellCooldownInfo.startTime, spellCooldownInfo.duration)
        else
            pool.button.cooldown:Clear()
        end
    elseif item.type == const.ITEM_TYPE.PET then
        local speciesId, petGUID = C_PetJournal.FindPetIDByName(item.name)
        if petGUID then
            local start, duration, isEnabled = C_PetJournal.GetPetCooldownByGUID(petGUID)
            if isEnabled and duration > 0 then
                pool.button.cooldown:SetCooldown(start, duration)
            else
                pool.button.cooldown:Clear()
            end
        end
    end
end

-- 设置脚本模式的点击事件
function BaseFrame:SetScriptEvent(pool)
    if pool == nil or pool.button == nil then
        return
    end
    local cbResult = pool._callbackResult
    if cbResult == nil then
        return
    end
    if cbResult.leftClickCallback then
        pool.button:SetScript("OnClick", function()
            cbResult.leftClickCallback()
        end)
    elseif cbResult.macro then
        pool.button:SetAttribute("type", "macro")
        local macroText = ""
        macroText = macroText .. cbResult.macro
        if cbResult.closeGUIAfterClick == nil or cbResult.closeGUIAfterClick == true then
            macroText = macroText .. "\r" .. "/closehtmainframe"
        end
        pool.button:SetAttribute("macrotext", macroText)
    end
    if cbResult.icon then
        pool.button:SetNormalTexture(cbResult.icon)
    end
    if cbResult.text and pool.text then
        pool.text:SetText(U.String.ToVertical(cbResult.text))
    end
end

-- 当pool上的技能没有学习的时候，置为灰色
function BaseFrame:SetPoolLearnable(pool)
    if pool == nil then
        return
    end
    local callbackResult = pool._callbackResult
    if callbackResult == nil or callbackResult.item == nil then
        return
    end
    local item = callbackResult.item
    local hasThisThing = false
    if item.type == const.ITEM_TYPE.ITEM then
        local count = C_Item.GetItemCount(item.id, false)
        if not (count == 0) then
            hasThisThing = true
        end
    elseif item.type == const.ITEM_TYPE.TOY then
        if PlayerHasToy(item.id) then
            hasThisThing = true
        end
    elseif item.type == const.ITEM_TYPE.SPELL then
        if IsSpellKnown(item.id) then
            hasThisThing = true
        end
    elseif item.type == const.ITEM_TYPE.MOUNT then
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(item.id)
        if isCollected then
            hasThisThing = true
        end
    elseif item.type == const.ITEM_TYPE.PET then
        for petIndex = 1, C_PetJournal.GetNumPets() do
            local _, speciesID, owned, customName, level, favorite, isRevoked, speciesName, icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByIndex(petIndex)
            if speciesID == item.id then
                hasThisThing = true
                break
            end
        end
    end
    -- 如果没有学习这个技能，则将图标和文字改成灰色半透明
    if hasThisThing == false then
        if pool.button then
            pool.button:SetEnabled(false)
            pool.button:SetAlpha(0.5)
        end
        if pool.text then
            pool.text:SetTextColor(0.5, 0.5, 0.5)
        end
    else
        if pool.button then
            pool.button:SetEnabled(true)
            pool.button:SetAlpha(1)
        end
        if pool.text then
            pool.text:SetTextColor(1, 1, 1)
        end
    end
end

-- 设置button鼠标移入事件
function BaseFrame:SetShowGameTooltip(pool)
    local callbackResult = pool._callbackResult
    if callbackResult == nil or callbackResult.item == nil then
        return
    end
    local item = callbackResult.item
    GameTooltip:SetOwner(pool.button, "ANCHOR_RIGHT") -- 设置提示显示的位置
    if item.type == const.ITEM_TYPE.ITEM then
        GameTooltip:SetItemByID(item.id)
    elseif item.type == const.ITEM_TYPE.TOY then
        GameTooltip:SetToyByItemID(item.id)
    elseif item.type == const.ITEM_TYPE.SPELL then
        GameTooltip:SetSpellByID(item.id)
    elseif item.type == const.ITEM_TYPE.MOUNT then
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(item.id)
        GameTooltip:SetMountBySpellID(spellID)
    elseif item.type == const.ITEM_TYPE.PET then
        local speciesName, speciesIcon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable, creatureDisplayID = C_PetJournal.GetPetInfoBySpeciesID(item.id)
        local speciesId, petGUID = C_PetJournal.FindPetIDByName(speciesName)
        GameTooltip:SetCompanionPet(petGUID)
    end
end

-- 设置button的鼠标移入移出事件
function BaseFrame:SetButtonMouseEvent(pool)
    if pool == nil or pool.button == nil then
        return
    end
    pool.button:SetScript("OnLeave", function(_)
        GameTooltip:Hide() -- 隐藏提示
    end)
    pool.button:SetScript("OnEnter", function (_)
        BaseFrame:SetShowGameTooltip(pool)
        -- 设置鼠标移入时候的高亮效果为白色半透明效果
        local highlightTexture = pool.button:CreateTexture()
        highlightTexture:SetColorTexture(255, 255, 255, 0.2)
        pool.button:SetHighlightTexture(highlightTexture)
    end)
end
