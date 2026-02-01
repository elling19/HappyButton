local addonName, _ = ...

---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class E: AceModule
local E = addon:GetModule("Element")

---@class Item: AceModule
local Item = addon:GetModule("Item")

---@class ElementCallback: AceModule
local ECB = addon:GetModule('ElementCallback')

---@class Client: AceModule
local Client = addon:GetModule("Client")

---@class Api: AceModule
local Api = addon:GetModule("Api")

---@type LibCustomGlow
---@diagnostic disable-next-line: assign-type-mismatch
local LCG = LibStub("LibCustomGlow-1.0")


---@class Btn: AceModule
---@diagnostic disable-next-line: undefined-doc-name
---@field Button table|Button|SecureActionButtonTemplate
---@field EFrame ElementFrame
---@field Icon Texture  -- 图标纹理
---@field Texts table[] -- 文字提示(存储文本frame和对应的FontString)
---@diagnostic disable-next-line: undefined-doc-name
---@field Cooldown table|Cooldown|CooldownFrameTemplate  -- 冷却倒计时
---@field Border table | Frame -- 边框
---@field CbResult CbResult
---@field CbInfo ElementCbInfo
---@field effects table<EffectType, boolean>
---@field BindkeyString FontString | nil  -- 显示绑定快捷键信息
---@field BindKey string | nil
local Btn = addon:NewModule("Btn")

---@param eFrame ElementFrame
--- @param cbInfo ElementCbInfo
---@param cbIndex number
---@return Btn
function Btn:New(eFrame, cbInfo, cbIndex)
    local obj = setmetatable({}, { __index = self })
    obj.EFrame = eFrame
    obj.CbInfo = cbInfo
    obj.CbResult = cbInfo.r[cbIndex]
    obj.Button = CreateFrame("Button", ("HB-%s-%s-%s"):format(eFrame.Config.id, cbInfo.p.id, cbIndex),
        eFrame.Bar.BarFrame,
        "SecureActionButtonTemplate")
    obj.Button:SetSize(eFrame.IconWidth, eFrame.IconHeight)
    obj.effects = {}
    Btn.CreateIcon(obj)
    Btn.CreateBorder(obj)
    Btn.UpdateRegisterForClicks(obj)
    Btn.SetMouseEvent(obj)
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
--- @param cbIndex number 当前callback的下标
--- @param btnIndex number 当前按钮下标，用来更新位置
---@param event EventString
---@param eventArgs any[]
function Btn:UpdateByElementFrame(cbIndex, btnIndex, event, eventArgs)
    self.CbResult = self.CbInfo.r[cbIndex]
    local bar = self.EFrame.Bar
    if self.EFrame.Config.elesGrowth == const.GROWTH.LEFTTOP or self.EFrame.Config.elesGrowth == const.GROWTH.LEFTBOTTOM then
        self.Button:SetPoint("RIGHT", bar.BarFrame, "RIGHT", -self.EFrame.IconWidth * (btnIndex - 1), 0)
    elseif self.EFrame.Config.elesGrowth == const.GROWTH.TOPLEFT or self.EFrame.Config.elesGrowth == const.GROWTH.TOPRIGHT then
        self.Button:SetPoint("BOTTOM", bar.BarFrame, "BOTTOM", 0, self.EFrame.IconHeight * (btnIndex - 1))
    elseif self.EFrame.Config.elesGrowth == const.GROWTH.BOTTOMLEFT or self.EFrame.Config.elesGrowth == const.GROWTH.BOTTOMRIGHT then
        self.Button:SetPoint("TOP", bar.BarFrame, "TOP", 0, -self.EFrame.IconHeight * (btnIndex - 1))
    elseif self.EFrame.Config.elesGrowth == const.GROWTH.RIGHTBOTTOM or self.EFrame.Config.elesGrowth == const.GROWTH.RIGHTTOP then
        self.Button:SetPoint("LEFT", bar.BarFrame, "LEFT", self.EFrame.IconWidth * (btnIndex - 1), 0)
    else
        -- 默认右下
        self.Button:SetPoint("LEFT", bar.BarFrame, "LEFT", self.EFrame.IconWidth * (btnIndex - 1), 0)
    end
    if self.CbInfo.e[event] == nil or not E:CompareEventParam(self.CbInfo.e[event], eventArgs) then
        return
    end
    self:Update(event, eventArgs)
end

-- 按钮自身更新CbResult
---@param event EventString
---@param eventArgs any[]
function Btn:UpdateBySelf(event, eventArgs)
    if self.CbInfo.e[event] == nil or not E:CompareEventParam(self.CbInfo.e[event], eventArgs) then
        return
    end
    -- 宏在更新的时候需要改变宏图标
    if self.CbInfo.p.type == const.ELEMENT_TYPE.MACRO then
        self.CbResult.item = ECB.UpdateMacroItemInfo(self.CbInfo.p)
    end
    ECB:UpdateSelfTrigger(self.CbResult, event, eventArgs)
    ECB:UseTrigger(self.CbInfo.p, self.CbResult)
    self:Update(event, eventArgs)
end

---@param event EventString
---@param eventArgs any[]
function Btn:Update(event, eventArgs)
    if not InCombatLockdown() then
        self:UpdateBindkey(event)
    end
    if self.CbResult == nil then
        return
    end
    self:SetIcon()
    if self.CbResult.item ~= nil then
        self:SetCooldown()
        -- ⚠️ 非战斗状态才能更新macro
        if not InCombatLockdown() then
            self:SetMacro()
        end
    else
        if not InCombatLockdown() then
            self:SetScriptEvent()
        end
    end
    self:UpdateTexts()
    self:UpdateEffects()
end

-- 当修改Cvar的时候改变绑定事件
function Btn:UpdateRegisterForClicks()
    if (C_CVar.GetCVar("ActionButtonUseKeyDown") == "1") then
        -- 鼠标点击执行
        self.Button:RegisterForClicks("AnyDown")
    else
        -- 鼠标弹起执行
        self.Button:RegisterForClicks("AnyUp")
    end
end

-- 按键绑定
---@param event EventString
function Btn:UpdateBindkey(event)
    local bindKey = self.CbInfo.p.bindKey
    if not bindKey then
        self:ClearOverrideBinding()
        return
    end
    if self:PassBindKeyCond(event) then
        if self.BindkeyString == nil then
            self.BindkeyString = self.Button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.BindkeyString:SetTextColor(1, 1, 1)
            local fontSize = self.EFrame.IconWidth / 3
            self.BindkeyString:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
            self.BindkeyString:SetPoint("TOPRIGHT", self.Button, "TOPRIGHT", -2, -2)
        end
        if self.BindKey ~= bindKey.key then
            self:SetOverrideBinding(bindKey.key)
            self.BindkeyString:SetText(self:GetBindKeyShort(bindKey.key))
        else
            self.BindkeyString:SetText(self:GetBindKeyShort(bindKey.key))
        end
    else
        self:ClearOverrideBinding()
    end
end

-- 判断是否满足按键绑定条件
---@param event EventString
function Btn:PassBindKeyCond(event)
    local bindKey = self.CbInfo.p.bindKey
    -- 是否设置了绑定按键
    if bindKey == nil or bindKey.key == nil or bindKey.key == "" then
        return false
    end
    -- 如果设置了绑定角色，但是当前角色不在绑定角色中，职业也不再绑定职业中
    if bindKey.characters ~= nil and (bindKey.characters[UnitGUID("player")] == nil and bindKey.classes[select(2, UnitClassBase("player"))] == nil) then
        return false
    end
    -- 战斗中加载条件不满足
    if bindKey.combat ~= nil then
        if event == "PLAYER_REGEN_DISABLED" then
            if bindKey.combat == false then
                return false
            end
        else
            if bindKey.combat ~= InCombatLockdown() then
                return false
            end
        end
    end
    -- 依附框体显示条件不满足
    if bindKey.attachFrame ~= nil then
        if bindKey.attachFrame ~= self.EFrame.attachFrame:IsShown() then
            return false
        end
    end
    return true
end

-- 设置绑定按键
---@param key string 绑定按键
function Btn:SetOverrideBinding(key)
    ---@diagnostic disable-next-line: param-type-mismatch
    SetOverrideBinding(self.Button, true, key, "CLICK " .. self.Button:GetName() .. ":LeftButton")
    self.BindKey = key
end

-- 取消绑定按键
function Btn:ClearOverrideBinding()
    if self.BindKey ~= nil then
        ---@diagnostic disable-next-line: param-type-mismatch
        SetOverrideBinding(self.Button, true, self.BindKey, nil)
        self.BindKey = nil
    end
    if self.BindkeyString ~= nil then
        self.BindkeyString:SetText("")
    end
end

-- 获取绑定按键的缩写
function Btn:GetBindKeyShort(bindkey)
    -- 定义修饰键与简写的映射
    local modifierMap = {
        ["ALT"] = "A",
        ["CTRL"] = "C",
        ["SHIFT"] = "S",
        ["MOUSEWHEELUP"] = "MU",
        ["MOUSEWHEELDOWN"] = "MD"
    }

    -- 使用 "-" 来分割键位
    local parts = {}
    for modifier in string.gmatch(bindkey, "[^%-]+") do
        table.insert(parts, modifier)
    end

    -- 处理修饰键部分并转换为简写
    for i, part in ipairs(parts) do
        if modifierMap[part] then
            parts[i] = modifierMap[part]
        end
    end

    -- 合并修饰键和数字/字母，使用"-"连接
    return table.concat(parts, "-")
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
    local margin = 5 -- 距离btn偏移量
    if self.Texts == nil then
        self.Texts = {}
    end
    local texts = self.EFrame.Config.texts or {}
    if self.CbInfo.p.isUseRootTexts == false then
        texts = self.CbInfo.p.texts or {}
    end
    for tIndex, text in ipairs(texts) do
        if tIndex > #self.Texts then
            local textFrame = CreateFrame("Frame", nil, self.Button)
            local fString = textFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            fString:SetPoint("CENTER", textFrame, "CENTER")
            fString:SetTextColor(1, 1, 1) -- 默认使用白色
            table.insert(self.Texts, {textFrame, fString})
        end
        local textFrame, fString = unpack(self.Texts[tIndex])
        if text.text == "%n" then
            local t = self.CbResult.text or (self.CbResult.item and self.CbResult.item.name) or self.CbInfo.p.title or ""
            if text.growth == const.TEXT_GROWTH.TOP then
                fString:SetText(U.String.ToVertical(t))
                textFrame:ClearAllPoints()
                textFrame:SetSize(self.EFrame.IconWidth, fString:GetStringHeight())
                textFrame:SetPoint("BOTTOM", self.Button, "TOP", 0, margin)
            elseif text.growth == const.TEXT_GROWTH.BOTTOM then
                fString:SetText(U.String.ToVertical(t))
                textFrame:ClearAllPoints()
                textFrame:SetSize(self.EFrame.IconWidth, fString:GetStringHeight())
                textFrame:SetPoint("TOP", self.Button, "BOTTOM", 0, -margin)
            elseif text.growth == const.TEXT_GROWTH.LEFT then
                fString:SetText(t)
                textFrame:ClearAllPoints()
                textFrame:SetSize(fString:GetStringWidth(), self.EFrame.IconHeight)
                textFrame:SetPoint("RIGHT", self.Button, "LEFT", -margin, 0)
            elseif text.growth == const.TEXT_GROWTH.RIGHT then
                fString:SetText(t)
                textFrame:ClearAllPoints()
                textFrame:SetSize(fString:GetStringWidth(), self.EFrame.IconHeight)
                textFrame:SetPoint("LEFT", self.Button, "RIGHT", margin, 0)
            else
                -- 如果没有配置生长方向，使用下面的默认方向
                if self.EFrame:IsHorizontal() then
                    fString:SetText(U.String.ToVertical(t))
                    textFrame:ClearAllPoints()
                    textFrame:SetSize(fString:GetStringWidth(), fString:GetStringHeight())
                    textFrame:SetPoint("TOP", self.Button, "BOTTOM", 0, -margin)
                else
                    fString:SetText(t)
                    textFrame:ClearAllPoints()
                    textFrame:SetSize(fString:GetStringWidth(), fString:GetStringHeight())
                    textFrame:SetPoint("LEFT", self.Button, "RIGHT", margin, 0)
                end
            end
            -- 如果没有学习这个技能，则将文字改成灰色半透明
            if self.CbResult.isLearned == false then
                fString:SetTextColor(0.8, 0.8, 0.8)
            else
                fString:SetTextColor(1, 1, 1)
            end
        end
        if text.text == "%s" then
            if self.CbResult.count ~= nil then
                fString:SetText(tostring(self.CbResult.count))
            else
                fString:SetText("")
            end
            textFrame:ClearAllPoints()
            textFrame:SetSize(fString:GetStringWidth(), fString:GetStringHeight())
            textFrame:SetPoint("BOTTOMRIGHT", self.Button, "BOTTOMRIGHT", -2, 2)
        end
    end
    if #texts < #self.Texts then
        for i = #self.Texts, #texts + 1, -1 do
            local textFrame, fString = unpack(self.Texts[i])
            textFrame:Hide()
            textFrame:SetParent(nil)
            textFrame = nil
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
    local btnAlpha = effects["btnAlpha"]
    local btnVertexColor = effects["btnVertexColor"]
    local borderGlow = effects["borderGlow"]
    -- 透明和隐藏需要在一起处理，因为都是改变button的透明度
    if btnAlpha or btnHide then
        if btnHide and btnHide.status == true then
            -- ⚠️ 关于按钮隐藏的特殊说明：
            -- 如果设置了按钮隐藏，当在战斗外的时候ElementFrame🍃会监测到隐藏按钮并且会移除按钮，因此战斗外的按钮隐藏等于🟰移除按钮
            -- 当战斗中的时候，由于API限制，无法设置移除按钮，因此战斗中隐藏按钮的设置为“透明度为0”，这样同样实现了按钮隐藏，但是实际上按钮还是可以被点击的
            self.Button:SetAlpha(0)
        elseif btnAlpha and btnAlpha.status == true then
            self.Button:SetAlpha(0.5)
        else
            self.Button:SetAlpha(1)
        end
    else
        self.Button:SetAlpha(1)
    end
    if btnDesaturate and btnDesaturate.status == true then
        self.Icon:SetDesaturated(true)
    else
        self.Icon:SetDesaturated(false)
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
            edgeSize = 1, -- 边框大小
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
        self.Cooldown:SetHideCountdownNumbers(false) -- 显示倒计时数字
    end
end

function Btn:SetIcon()
    local r = self.CbResult
    if r == nil then
        return
    end
    if self.Icon == nil then
        self:CreateIcon()
    end
    self.Icon:SetTexture(r.icon or (r.item and r.item.icon) or 134400)
    -- 设置物品边框
    if self.CbInfo.p.isShowQualityBorder == true and self.CbResult.borderColor then
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
    if r.macro then
        self.Button:SetAttribute("macrotext", r.macro)
        return
    end
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
        macroText = "/SummonPet " .. r.item.name -- 可以使用/sp替代 支持petNameOrGUID
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
    -- 更新冷却倒计时
    if r.itemCooldown then
        self.Cooldown:SetCooldown(r.itemCooldown.startTime, r.itemCooldown.duration)
    end
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
    -- 删除文本
    if self.Texts then
        for _, text in ipairs(self.Texts) do
            local textFrame, fString = unpack(text)
            textFrame:Hide()
            textFrame:ClearAllPoints()
            textFrame = nil
        end
    end
    self.Texts = nil
    self:ClearOverrideBinding()
    self.Button:Hide()
    self.Button:ClearAllPoints()
    self.Border:Hide()
    self.Border:ClearAllPoints()
    self.Border = nil
    self.Icon = nil
    self.BindkeyString = nil
    self.Cooldown = nil
    self.Button = nil
end
