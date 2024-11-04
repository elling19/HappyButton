local addonName, _ = ...

---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class Item: AceModule
local Item = addon:GetModule("Item")

---@class ElementCallback: AceModule
local ECB = addon:GetModule('ElementCallback')

---@class Client: AceModule
local Client = addon:GetModule("Client")

---@type LibCustomGlow
---@diagnostic disable-next-line: assign-type-mismatch
local LCG = LibStub("LibCustomGlow-1.0")


---@class Btn: AceModule
---@diagnostic disable-next-line: undefined-doc-name
---@field Button table|Button|SecureActionButtonTemplate
---@field EFrame ElementFrame
---@field Icon Texture  -- 图标纹理
---@field Texts FontString[] -- 文字提示
---@diagnostic disable-next-line: undefined-doc-name
---@field Cooldown table|Cooldown|CooldownFrameTemplate  -- 冷却倒计时
---@field Border table | Frame -- 边框
---@field CbResult CbResult
---@field CbInfo ElementCbInfo
---@field effects table<EffectType, boolean>
local Btn = addon:NewModule("Btn")

---@param eFrame ElementFrame
---@param barIndex number
---@param cbIndex number
---@return Btn
function Btn:New(eFrame, barIndex, cbIndex)
    local bar = eFrame.Bars[barIndex]
    local obj = setmetatable({}, { __index = self })
    obj.EFrame = eFrame
    obj.Button = CreateFrame("Button", ("Button-%s-%s-%s"):format(eFrame.Config.id, barIndex, cbIndex), bar.BarFrame,
        "SecureActionButtonTemplate")
    obj.Button:SetSize(eFrame.IconWidth, eFrame.IconHeight)
    obj.effects = {}
    Btn.CreateIcon(obj)
    Btn.CreateBorder(obj)

    if eFrame.Config.type == const.ELEMENT_TYPE.BAR_GROUP then
        if eFrame.Config.elesGrowth == const.GROWTH.LEFTTOP or eFrame.Config.elesGrowth == const.GROWTH.RIGHTTOP then
            obj.Button:SetPoint("BOTTOM", bar.BarFrame, "BOTTOM", 0, eFrame.IconHeight * (cbIndex - 1))
        elseif eFrame.Config.elesGrowth == const.GROWTH.LEFTBOTTOM or eFrame.Config.elesGrowth == const.GROWTH.RIGHTBOTTOM then
            obj.Button:SetPoint("TOP", bar.BarFrame, "TOP", 0, -eFrame.IconHeight * (cbIndex - 1))
        elseif eFrame.Config.elesGrowth == const.GROWTH.BOTTOMLEFT or eFrame.Config.elesGrowth == const.GROWTH.TOPLEFT then
            obj.Button:SetPoint("RIGHT", bar.BarFrame, "RIGHT", -eFrame.IconWidth * (cbIndex - 1), 0)
        elseif eFrame.Config.elesGrowth == const.GROWTH.BOTTOMRIGHT or eFrame.Config.elesGrowth == const.GROWTH.TOPRIGHT then
            obj.Button:SetPoint("LEFT", bar.BarFrame, "LEFT", eFrame.IconWidth * (cbIndex - 1), 0)
        else
            -- 默认右下
            obj.Button:SetPoint("TOP", bar.BarFrame, "TOP", 0, -eFrame.IconHeight * (cbIndex - 1))
        end
    else
        if eFrame.Config.elesGrowth == const.GROWTH.LEFTTOP or eFrame.Config.elesGrowth == const.GROWTH.LEFTBOTTOM then
            obj.Button:SetPoint("RIGHT", bar.BarFrame, "RIGHT", -eFrame.IconWidth * (cbIndex - 1), 0)
        elseif eFrame.Config.elesGrowth == const.GROWTH.TOPLEFT or eFrame.Config.elesGrowth == const.GROWTH.TOPRIGHT then
            obj.Button:SetPoint("BOTTOM", bar.BarFrame, "BOTTOM", 0, eFrame.IconHeight * (cbIndex - 1))
        elseif eFrame.Config.elesGrowth == const.GROWTH.BOTTOMLEFT or eFrame.Config.elesGrowth == const.GROWTH.BOTTOMRIGHT then
            obj.Button:SetPoint("TOP", bar.BarFrame, "TOP", 0, -eFrame.IconHeight * (cbIndex - 1))
        elseif eFrame.Config.elesGrowth == const.GROWTH.RIGHTBOTTOM or eFrame.Config.elesGrowth == const.GROWTH.RIGHTTOP then
            obj.Button:SetPoint("LEFT", bar.BarFrame, "LEFT", eFrame.IconWidth * (cbIndex - 1), 0)
        else
            -- 默认右下
            obj.Button:SetPoint("LEFT", bar.BarFrame, "LEFT", eFrame.IconWidth * (cbIndex - 1), 0)
        end
    end

    obj.Button:RegisterForClicks("AnyDown", "AnyUp")
    obj.Button:SetAttribute("type", "macro")
    obj.Button:SetAttribute("macrotext", "")

    if addon.G.ElvUI then
        obj.Button:SetHighlightTexture(addon.G.ElvUI.Media.Textures.White8x8)
        obj.Button:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.3)
        obj.Button:SetPushedTexture(addon.G.ElvUI.Media.Textures.White8x8)
        obj.Button:GetPushedTexture():SetVertexColor(1, 1, 1, 0.3)
    else
        local highlightTexture = obj.Button:CreateTexture()
        highlightTexture:SetColorTexture(255, 255, 255, 0.5)
        obj.Button:SetHighlightTexture(highlightTexture)
        obj.Button:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.5)
        local pushedTexture = obj.Button:CreateTexture()
        pushedTexture:SetColorTexture(255, 255, 255, 0.5)
        obj.Button:SetPushedTexture(pushedTexture)
        obj.Button:GetPushedTexture():SetVertexColor(1, 1, 1, 0.5)
    end
    return obj ---@type Btn
end

--- 按钮🔘从Frame中获取CbResult并更新
--- @param cbInfo ElementCbInfo
--- @param event string | nil
function Btn:UpdateByElementFrame(cbInfo, event)
    self.CbInfo = cbInfo
    self.CbResult = cbInfo.r[1]
    if event and self.CbInfo.e[event] == nil then
        return
    end
    self:Update()
end

-- 按钮自身更新CbResult
---@param event string | nil
function Btn:UpdateBySelf(event)
    if event and self.CbInfo.e[event] == nil then
        return
    end
    ECB:UpdateSelfTrigger(self.CbResult)
    self.CbResult.effects = ECB:UseTrigger(self.CbInfo.p, self.CbResult)
    self:Update()
end

function Btn:Update()
    if self.CbResult == nil then
        return
    end
    if self.CbResult.item ~= nil then
        self:SetIcon()
        self:SetCooldown()
        self:SetMouseEvent()
        -- ⚠️ 非战斗状态才能更新macro
        if not InCombatLockdown() then
            self:SetMacro()
        end
    else
        self:SetScriptEvent()
    end
    self:UpdateTexts()
    self:UpdateEffects()
end

-- 创建图标Icon
function Btn:CreateIcon()
    if self.Icon == nil then
        self.Icon = self.Button:CreateTexture(nil, "ARTWORK")
        self.Icon:SetTexture(134400)
        self.Icon:SetSize(self.Button:GetWidth(), self.Button:GetHeight())
        self.Icon:SetPoint("CENTER")
        self.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- 裁剪图标
    end
end

-- 创建文本Text
function Btn:UpdateTexts()
    if self.Texts == nil then
        self.Texts = {}
    end
    local texts = self.EFrame.Config.texts or {}
    if self.CbInfo.p.isUseRootTexts == false then
        texts = self.CbInfo.p.texts or {}
    end
    for tIndex, text in ipairs(texts) do
        if tIndex > #self.Texts then
            local fString = self.Button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            fString:SetTextColor(1, 1, 1) -- 默认使用白色
            table.insert(self.Texts, fString)
        end
        local tString = self.Texts[tIndex]
        if text.text == "%n" then
            if self.EFrame:IsIconsHorizontal() then
                tString:SetWidth(self.EFrame.IconWidth)
            else
                tString:SetHeight(self.EFrame.IconHeight)
            end
            if self.EFrame:IsIconsHorizontal() then
                tString:SetPoint("TOP", self.Button, "BOTTOM", 0, -5)
            else
                tString:SetPoint("LEFT", self.Button, "RIGHT", 5, 0)
            end
            if self.CbResult.text then
                if self.EFrame:IsIconsHorizontal() then
                    tString:SetText(U.String.ToVertical(self.CbResult.text))
                else
                    tString:SetText(self.CbResult.text)
                end
            end
            -- 如果没有学习这个技能，则将文字改成灰色半透明
            if self.CbResult.isLearned == false then
                tString:SetTextColor(0.8, 0.8, 0.8)
            else
                tString:SetTextColor(1, 1, 1)
            end
        end
        if text.text == "%s" then
            tString:SetPoint("BOTTOMRIGHT", self.Button, "BOTTOMRIGHT", -2, 2)
            if self.CbResult.count ~= nil then
                tString:SetText(tostring(self.CbResult.count))
            else
                tString:SetText("")
            end
        end
    end
    if #texts < #self.Texts then
        for i = #self.Texts, #texts + 1, -1 do
            local tString = self.Texts[i]
            tString:SetParent(nil)
            self.Texts[i] = nil
        end
    end
end

-- 更新效果
function Btn:UpdateEffects()
    local effects = {} ---@type table<EffectType, EffectConfig>
    if self.CbResult.effects then
        for _, effect in ipairs(self.CbResult.effects) do
            effects[effect.type] = effect
        end
    end
    local btnDesaturate = effects["btnDesaturate"]
    local btnHide = effects["btnHide"]
    local btnVertexColor = effects["btnVertexColor"]
    local borderGlow = effects["borderGlow"]
    -- 褪色和隐藏需要在一起处理，因为都是改变button的透明度
    if btnDesaturate or btnHide then
        if btnHide and btnHide.status == true then
            -- ⚠️ 关于按钮隐藏的特殊说明：
            -- 如果设置了按钮隐藏，当在战斗外的时候ElementFrame🍃会监测到隐藏按钮并且会移除按钮，因此战斗外的按钮隐藏等于🟰移除按钮
            -- 当战斗中的时候，由于API限制，无法设置移除按钮，因此战斗中隐藏按钮的设置为“透明度为0”，这样同样实现了按钮隐藏，但是实际上按钮还是可以被点击的
            self.Button:SetAlpha(0)
        elseif btnDesaturate and btnDesaturate.status == true then
            self.Button:SetAlpha(0.5)
        else
            self.Button:SetAlpha(1)
        end
    else
        self.Button:SetAlpha(1)
    end
    if btnVertexColor and btnVertexColor.status == true then
        self.Icon:SetVertexColor(1, 0, 0, 1) -- 红色背景
    else
        self.Icon:SetVertexColor(1, 1, 1, 1) -- 清除效果
    end
    if borderGlow and borderGlow.status == true then
        if Client:IsRetail() then
            if not self.effects.borderGlow then
                LCG.ProcGlow_Start(self.Button, {})
                self.effects.borderGlow = true
            end
        else
            if not self.effects.borderGlow then
                LCG.ButtonGlow_Start(self.Button, { 1, 1, 0, 1 }, 0.5)
                self.effects.borderGlow = true
            end
        end
    else
        if Client:IsRetail() then
            LCG.ProcGlow_Stop(self.Button)
            self.effects.borderGlow = false
        else
            LCG.ButtonGlow_Stop(self.Button)
            self.effects.borderGlow = false
        end
    end
end

-- 创建边框背景框架
function Btn:CreateBorder()
    if self.Border == nil then
        self.Border = CreateFrame("Frame", nil, self.Button, "BackdropTemplate")
        self.Border:SetSize(self.EFrame.IconWidth, self.EFrame.IconHeight)
        self.Border:SetPoint("CENTER")
        self.Border:SetFrameLevel(self.Button:GetFrameLevel() + 1)
        self.Border:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",   -- 背景色
            edgeFile = "Interface\\Buttons\\WHITE8x8", -- 边框纹理
            tile = false,
            tileSize = 0,
            edgeSize = 1,                              -- 边框大小
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        self.Border:SetBackdropColor(0, 0, 0, 0) -- 背景透明（灰色）
        self.Border:SetBackdropBorderColor(unpack(const.DefaultItemColor))
    end
end

-- 创建冷却计时条
function Btn:CreateCoolDown()
    if self.Cooldown == nil then
        self.Cooldown = CreateFrame("Cooldown", nil, self.Button, "CooldownFrameTemplate")
        self.Cooldown:SetAllPoints()                -- 设置冷却效果覆盖整个按钮
        self.Cooldown:SetDrawEdge(true)             -- 显示边缘
        self.Cooldown:SetHideCountdownNumbers(true) -- 隐藏倒计时数字
    end
end

function Btn:SetIcon()
    local r = self.CbResult
    if r == nil then
        return
    end
    if r.icon then
        self.Icon:SetTexture(r.icon)
    else
        self.Icon:SetTexture(134400)
    end
    -- 设置物品边框
    if self.CbResult.borderColor then
        self.Border:SetBackdropBorderColor(unpack(self.CbResult.borderColor))
    else
        self.Border:SetBackdropBorderColor(unpack(const.DefaultItemColor))
    end
end

-- 更新按钮的宏文案
function Btn:SetMacro()
    local r = self.CbResult
    if r == nil or r.item == nil then
        return
    end
    -- 设置宏命令
    self.Button:SetAttribute("type", "macro")
    local macroText = ""
    if r.item.type == const.ITEM_TYPE.ITEM then
        macroText = "/use item:" .. r.item.id
    elseif r.item.type == const.ITEM_TYPE.EQUIPMENT then
        local isEquipped = Item:IsEquipped(r.item.id)
        if isEquipped then
            macroText = "/use item:" .. r.item.id
        else
            macroText = "/equip " .. r.item.name
        end
    elseif r.item.type == const.ITEM_TYPE.TOY then
        macroText = "/use item:" .. r.item.id
    elseif r.item.type == const.ITEM_TYPE.SPELL then
        macroText = "/cast " .. r.item.name
    elseif r.item.type == const.ITEM_TYPE.MOUNT then
        macroText = "/cast " .. r.item.name
    elseif r.item.type == const.ITEM_TYPE.PET then
        macroText = "/SummonPet " .. r.item.name
    end
    self.Button:SetAttribute("macrotext", macroText)
end

-- 设置按钮冷却
function Btn:SetCooldown()
    local r = self.CbResult
    if r == nil then
        return
    end
    local item = r.item
    if item == nil then
        return
    end
    if self.Cooldown == nil then
        self:CreateCoolDown()
    end
    self.Button:SetScript("OnUpdate", function(_)
        -- 更新冷却倒计时
        if item.type == const.ITEM_TYPE.ITEM then
            local startTimeSeconds, durationSeconds, enableCooldownTimer = C_Item.GetItemCooldown(item.id)
            CooldownFrame_Set(self.Cooldown, startTimeSeconds, durationSeconds, enableCooldownTimer)
        elseif item.type == const.ITEM_TYPE.EQUIPMENT then
            local startTimeSeconds, durationSeconds, enableCooldownTimer = C_Item.GetItemCooldown(item.id)
            CooldownFrame_Set(self.Cooldown, startTimeSeconds, durationSeconds, enableCooldownTimer)
        elseif item.type == const.ITEM_TYPE.TOY then
            local startTimeSeconds, durationSeconds, enableCooldownTimer = C_Item.GetItemCooldown(item.id)
            CooldownFrame_Set(self.Cooldown, startTimeSeconds, durationSeconds, enableCooldownTimer)
        elseif item.type == const.ITEM_TYPE.SPELL then
            local spellCooldownInfo = C_Spell.GetSpellCooldown(item.id)
            if spellCooldownInfo then
                CooldownFrame_Set(self.Cooldown, spellCooldownInfo.startTime, spellCooldownInfo.duration,
                    spellCooldownInfo.isEnabled)
            end
        elseif item.type == const.ITEM_TYPE.PET then
            local speciesId, petGUID = C_PetJournal.FindPetIDByName(item.name)
            if petGUID then
                local start, duration, isEnabled = C_PetJournal.GetPetCooldownByGUID(petGUID)
                CooldownFrame_Set(self.Cooldown, start, duration, isEnabled)
            end
        end
    end)
end

-- 设置脚本模式的点击事件
function Btn:SetScriptEvent()
    local r = self.CbResult
    if r == nil then
        return
    end
    if r.leftClickCallback then
        self.Button:SetScript("OnClick", function()
            r.leftClickCallback()
        end)
    elseif r.macro then
        self.Button:SetAttribute("type", "macro")
        local macroText = ""
        macroText = macroText .. r.macro
        self.Button:SetAttribute("macrotext", macroText)
    end
end

-- 设置button鼠标移入事件
function Btn:SetShowGameTooltip()
    local r = self.CbResult
    if r == nil or r.item == nil then
        return
    end
    local item = r.item
    if item == nil then
        return
    end
    GameTooltip:SetOwner(self.Border, "ANCHOR_RIGHT") -- 设置提示显示的位置
    if item.type == const.ITEM_TYPE.ITEM then
        GameTooltip:SetItemByID(item.id)
    elseif item.type == const.ITEM_TYPE.EQUIPMENT then
        GameTooltip:SetItemByID(item.id)
    elseif item.type == const.ITEM_TYPE.TOY then
        GameTooltip:SetToyByItemID(item.id)
    elseif item.type == const.ITEM_TYPE.SPELL then
        GameTooltip:SetSpellByID(item.id)
    elseif item.type == const.ITEM_TYPE.MOUNT then
        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight =
            C_MountJournal.GetMountInfoByID(item.id)
        GameTooltip:SetMountBySpellID(spellID)
    elseif item.type == const.ITEM_TYPE.PET then
        local speciesName, speciesIcon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable, creatureDisplayID =
            C_PetJournal.GetPetInfoBySpeciesID(item.id)
        local speciesId, petGUID = C_PetJournal.FindPetIDByName(speciesName)
        GameTooltip:SetCompanionPet(petGUID)
    end
end

-- 设置button的鼠标移入移出事件
function Btn:SetMouseEvent()
    self.Button:SetScript("OnLeave", function(_)
        GameTooltip:Hide()
    end)
    self.Button:SetScript("OnEnter", function(_)
        self:SetShowGameTooltip()
    end)
end

function Btn:Delete()
    self.Button:Hide()
    self.Button:ClearAllPoints()
    self.Border:Hide()
    self.Border:ClearAllPoints()
    self.Border = nil
    self.Icon = nil
    self.Text = nil
    self.Cooldown = nil
    self.Button = nil
end
