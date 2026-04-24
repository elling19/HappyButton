local addonName, _ = ...

---@class HappyButton: AceAddon
---@field G table | nil
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

local FONT_PATH = DAMAGE_TEXT_FONT or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local TEXT_COLOR_WHITE = { 1, 1, 1, 1 }


---@class Btn: AceModule
---@diagnostic disable-next-line: undefined-doc-name
---@field Button table|Button|SecureActionButtonTemplate
---@field EFrame ElementFrame
---@field Icon Texture  -- 图标纹理
---@field Texts table[] -- 文字提示(存储文本frame和对应的FontString)
---@diagnostic disable-next-line: undefined-doc-name
---@field Cooldown table|Cooldown|CooldownFrameTemplate  -- 冷却倒计时
---@field Border table | Frame -- 边框
---@field IconBorder Texture | nil -- Masque边框层（用于品质色）
---@field ProfessionQualityOverlay Texture | nil -- 制造/采集物品星级品质覆盖层
---@field CbResult CbResult
---@field CbInfo ElementCbInfo
---@field effects table<EffectType, boolean>
---@field BindkeyString FontString | nil  -- 显示绑定快捷键信息
---@field BindKey string | nil
---@field MasqueGroup table | nil
---@field isMasqueSkinned boolean | nil
---@field SkinProvider string | nil
---@field isSkinApplied boolean | nil
---@field didRenderSkinApply boolean | nil
---@field didDeferredSkinApply boolean | nil
---@field BindkeyEventHandler Frame | nil
local Btn = addon:NewModule("Btn")

-- 按键绑定相关事件：仅监听战斗状态切换
local bindkeyListenEvents = {
    ["PLAYER_REGEN_DISABLED"] = true,
    ["PLAYER_REGEN_ENABLED"] = true,
}

---@return number
function Btn:GetIconBaseSize()
    local w = self.Button and self.Button:GetWidth() or self.EFrame.IconWidth or 0
    local h = self.Button and self.Button:GetHeight() or self.EFrame.IconHeight or 0
    local base = math.min(w, h)
    if base <= 0 then
        base = math.min(self.EFrame.IconWidth or 36, self.EFrame.IconHeight or 36)
    end
    return base
end

---@param ratio number
---@param minSize number
---@param maxSize number
---@return number
function Btn:GetDynamicFontSize(ratio, minSize, maxSize)
    local size = math.floor(self:GetIconBaseSize() * ratio + 0.5)
    if size < minSize then
        return minSize
    end
    if size > maxSize then
        return maxSize
    end
    return size
end

---@param ratio number
---@param minMargin number
---@param maxMargin number
---@return number
function Btn:GetDynamicMargin(ratio, minMargin, maxMargin)
    local margin = math.floor(self:GetIconBaseSize() * ratio + 0.5)
    if margin < minMargin then
        return minMargin
    end
    if margin > maxMargin then
        return maxMargin
    end
    return margin
end

---@param fString FontString
---@param ratio number
---@param minSize number
---@param maxSize number
---@param isDim boolean|nil
function Btn:ApplyFontStyle(fString, ratio, minSize, maxSize, isDim)
    if fString == nil then
        return
    end
    local fontSize = self:GetDynamicFontSize(ratio, minSize, maxSize)
    fString:SetFont(FONT_PATH, fontSize, "")
    fString:SetTextColor(unpack(TEXT_COLOR_WHITE))
    fString:SetShadowColor(0, 0, 0, 0)
    fString:SetShadowOffset(0, 0)
end

---@return string
function Btn:GetSkinProvider()
    if addon.G == nil then
        return "native"
    end
    if addon.G.Masque then
        return "masque"
    end
    if addon.G.ElvUI then
        return "elvui"
    end
    if addon.G.NDui then
        return "ndui"
    end
    return "native"
end

function Btn:BindSkinReferences()
    if self.Button == nil or self.Icon == nil then
        return
    end
    ---@diagnostic disable-next-line: undefined-field
    self.Button.icon = self.Icon
    ---@diagnostic disable-next-line: undefined-field
    self.Button.Icon = self.Icon
end

function Btn:ApplyFallbackButtonTextures(highlightAlpha)
    if self.Button == nil then
        return
    end
    local white8x8 = "Interface\\Buttons\\WHITE8x8"
    if addon.G and addon.G.ElvUI and addon.G.ElvUI.Media and addon.G.ElvUI.Media.Textures and addon.G.ElvUI.Media.Textures.White8x8 then
        white8x8 = addon.G.ElvUI.Media.Textures.White8x8
    end
    self.Button:SetHighlightTexture(white8x8)
    self.Button:GetHighlightTexture():SetVertexColor(1, 1, 1, highlightAlpha)
    self.Button:SetPushedTexture(white8x8)
    self.Button:GetPushedTexture():SetVertexColor(1, 1, 1, highlightAlpha)
end

function Btn:ApplyIconCropByProvider(provider)
    if self.Icon == nil then
        return
    end
    if provider == "elvui" then
        ---@diagnostic disable-next-line: undefined-field
        local coords = addon.G and addon.G.ElvUI and addon.G.ElvUI.TexCoords
        if type(coords) == "table" and #coords >= 4 then
            self.Icon:SetTexCoord(unpack(coords))
        else
            self.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end
        return
    end
    if provider == "ndui" then
        self.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        return
    end
    self.Icon:SetTexCoord(0, 1, 0, 1)
end

---@param provider string
function Btn:ResetSkinApplyState(provider)
    local prevProvider = self.SkinProvider
    if prevProvider == "masque" and provider ~= "masque" then
        if self.isMasqueSkinned and self.MasqueGroup and self.MasqueGroup.RemoveButton and self.Button then
            pcall(self.MasqueGroup.RemoveButton, self.MasqueGroup, self.Button)
        end
        self.isMasqueSkinned = nil
    end
    self.SkinProvider = provider
    self.isSkinApplied = nil
    self.didRenderSkinApply = nil
    self.didDeferredSkinApply = nil
end

---@return string
function Btn:SyncSkinProviderState()
    local provider = self:GetSkinProvider()
    if self.SkinProvider ~= provider then
        self:ResetSkinApplyState(provider)
    end
    return provider
end

---@return boolean
function Btn:ApplyElvUISkin()
    if self.Button == nil then
        return false
    end
    self:BindSkinReferences()
    local skinned = false
    local skins = addon.G and addon.G.ElvUISkins
    ---@diagnostic disable-next-line: undefined-field
    if skins and skins.HandleButton then
        ---@diagnostic disable-next-line: undefined-field
        local ok, ret = pcall(skins.HandleButton, skins, self.Button)
        skinned = ok and ret ~= false and ret ~= nil
    end
    ---@diagnostic disable-next-line: undefined-field
    if skins and skins.HandleIcon and self.Icon then
        ---@diagnostic disable-next-line: undefined-field
        pcall(skins.HandleIcon, skins, self.Icon)
    end
    if not skinned then
        self:ApplyFallbackButtonTextures(0.3)
        skinned = true
    end
    return skinned
end

---@return boolean
function Btn:ApplyNDuiSkin()
    if self.Button == nil then
        return false
    end
    self:BindSkinReferences()
    self:ApplyFallbackButtonTextures(0.25)
    return true
end

---@param provider string
---@return boolean
function Btn:ApplySkinByProvider(provider)
    if provider == "masque" then
        return self:ApplyMasqueSkin()
    end
    if provider == "elvui" then
        return self:ApplyElvUISkin()
    end
    if provider == "ndui" then
        return self:ApplyNDuiSkin()
    end
    return true
end

---@param phase "create"|"render"
---@return boolean
function Btn:ApplyButtonSkin(phase)
    local provider = self:SyncSkinProviderState()
    if self.isSkinApplied then
        return true
    end

    if phase == "create" then
        local applied = self:ApplySkinByProvider(provider)
        if provider == "native" then
            self.isSkinApplied = applied
            self.didRenderSkinApply = true
            self.didDeferredSkinApply = true
        end
        return applied
    end

    if self.didRenderSkinApply then
        return false
    end

    self.didRenderSkinApply = true
    local applied = self:ApplySkinByProvider(provider)
    if provider == "native" then
        self.isSkinApplied = applied
        self.didDeferredSkinApply = true
        return applied
    end

    if not self.didDeferredSkinApply then
        self.didDeferredSkinApply = true
        C_Timer.After(0, function()
            if self.Button ~= nil and self.Icon ~= nil then
                local currentProvider = self:SyncSkinProviderState()
                self.isSkinApplied = self:ApplySkinByProvider(currentProvider)
            end
        end)
    end

    return applied
end

function Btn:EnsureSkinAppliedOnRender()
    self:ApplyButtonSkin("render")
end

function Btn:GetMasqueGroup()
    if self.MasqueGroup then
        return self.MasqueGroup
    end
    if not addon.G.Masque then
        return nil
    end
    -- 直接使用插件分组，不使用额外子分组
    self.MasqueGroup = addon.G.Masque:Group(addonName)
    return self.MasqueGroup
end

function Btn:ApplyMasqueSkin()
    local masqueGroup = self:GetMasqueGroup()
    if not masqueGroup or not self.Button or not self.Icon then
        return false
    end
    if self.isMasqueSkinned then
        return true
    end
    local ok = pcall(masqueGroup.AddButton, masqueGroup, self.Button, {
        Icon = self.Icon,
        Cooldown = self.Cooldown,
        IconBorder = self.IconBorder,
    })
    if ok then
        self.isMasqueSkinned = true
    end
    return ok
end

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
    if addon.G.Masque then
        Btn.CreateCoolDown(obj)
    end
    Btn.UpdateRegisterForClicks(obj)
    Btn.SetMouseEvent(obj)
    Btn.RegisterBindkeyEvents(obj)
    obj.Button:SetAttribute("type", "macro")
    obj.Button:SetAttribute("macrotext", "")
    obj:ResetSkinApplyState(obj:GetSkinProvider())
    obj:ApplyButtonSkin("create")
    return obj ---@type Btn
end

-- 注册按钮自身监听事件，用于按键绑定抢先刷新
function Btn:RegisterBindkeyEvents()
    if self.BindkeyEventHandler ~= nil then
        return
    end
    self.BindkeyEventHandler = CreateFrame("Frame", nil, self.Button)
    for eventName, _ in pairs(bindkeyListenEvents) do
        self.BindkeyEventHandler:RegisterEvent(eventName)
    end
    self.BindkeyEventHandler:SetScript("OnEvent", function(_, event, ...)
        -- 战斗中无法修改安全绑定，进入战斗事件仅作为边界信号处理
        if InCombatLockdown() then
            return
        end
        self:UpdateBindkey(event)
    end)
end

function Btn:UnregisterBindkeyEvents()
    if self.BindkeyEventHandler == nil then
        return
    end
    self.BindkeyEventHandler:UnregisterAllEvents()
    self.BindkeyEventHandler:SetScript("OnEvent", nil)
    self.BindkeyEventHandler:SetParent(nil)
    self.BindkeyEventHandler = nil
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
    self:EnsureSkinAppliedOnRender()
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
    ECB:UseTrigger(self.CbInfo.p, self.CbResult, self.CbInfo.root)
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
        end
        -- 角落边距建议比例：图标最短边 * 0.06
        local bindKeyMargin = self:GetDynamicMargin(0.06, 2, 8)
        self.BindkeyString:ClearAllPoints()
        self.BindkeyString:SetPoint("TOPRIGHT", self.Button, "TOPRIGHT", -bindKeyMargin, -bindKeyMargin)
        -- 绑定键建议字号比例：图标最短边 * 0.38（整体再放大）
        self:ApplyFontStyle(self.BindkeyString, 0.38, 11, 24)
        -- 仅按键文字保留轻微阴影，提升纯白字体可读性
        self.BindkeyString:SetShadowColor(0, 0, 0, 0.95)
        self.BindkeyString:SetShadowOffset(1, -1)
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
        if self.EFrame.attachFrame == nil then
            return false
        end
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

    -- 合并修饰键和数字/字母，不使用连接符（例如 A1、CS2）
    return table.concat(parts, "")
end

-- 创建图标Icon
function Btn:CreateIcon()
    if self.Icon == nil then
        self.Icon = self.Button:CreateTexture(nil, "ARTWORK")
        self.Icon:SetTexture(134400)
        self.Icon:SetSize(self.Button:GetWidth(), self.Button:GetHeight())
        self.Icon:SetPoint("CENTER")
        self:BindSkinReferences()
        self:ApplyIconCropByProvider(self:GetSkinProvider())
    end
    if self.ProfessionQualityOverlay == nil then
        self.ProfessionQualityOverlay = self.Button:CreateTexture(nil, "OVERLAY")
        self.ProfessionQualityOverlay:SetPoint("BOTTOM", self.Icon, "BOTTOM", 0, 1)
        self.ProfessionQualityOverlay:Hide()
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
            table.insert(self.Texts, {textFrame, fString})
        end
        local textFrame, fString = unpack(self.Texts[tIndex])
        if text.text == "%n" then
            -- 名称文本建议字号比例：图标最短边 * 0.30（整体放大）
            self:ApplyFontStyle(fString, 0.30, 11, 24)
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
            -- 未学会时使用更深灰色，提高状态辨识度
            if self.CbResult.isLearned == false then
                self:ApplyFontStyle(fString, 0.30, 11, 24, true)
            else
                self:ApplyFontStyle(fString, 0.30, 11, 24)
            end
        end
        if text.text == "%s" then
            -- 数量文本建议字号比例：图标最短边 * 0.36（同步放大）
            self:ApplyFontStyle(fString, 0.36, 12, 28)
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
        if addon.G.Masque then
            -- Masque 模式下使用IconBorder承载品质色，避免方形Backdrop边框
            if self.IconBorder == nil then
                self.IconBorder = self.Button:CreateTexture(nil, "OVERLAY")
                self.IconBorder:SetAllPoints(self.Icon)
                self.IconBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
                self.IconBorder:SetBlendMode("ADD")
                self.IconBorder:Hide()
            end
            self.Border:Hide()
            return
        end
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
        pcall(self.Cooldown.SetDrawSwipe, self.Cooldown, true) -- 关闭圆形遮罩
        pcall(self.Cooldown.SetDrawEdge, self.Cooldown, true)  -- 关闭边缘圈
        pcall(self.Cooldown.SetDrawBling, self.Cooldown, true) -- 关闭结束闪光
        self.Cooldown:SetHideCountdownNumbers(false) -- 显示倒计时数字
        if addon.G.Masque then
            self:ApplyMasqueSkin()
        end
    end
end

function Btn:UpdateCraftingQualityOverlay()
    if self.ProfessionQualityOverlay then
        self.ProfessionQualityOverlay:Hide()
    end
    local r = self.CbResult
    if r == nil or r.item == nil then
        return
    end
    if not Client:IsRetail() or type(SetItemCraftingQualityOverlay) ~= "function" then
        return
    end
    local itemType = r.item.type
    if itemType ~= const.ITEM_TYPE.ITEM and itemType ~= const.ITEM_TYPE.EQUIPMENT and itemType ~= const.ITEM_TYPE.TOY then
        return
    end
    local itemInfo = r.item.id
    if C_Item and C_Item.GetItemLinkByID and r.item.id then
        itemInfo = C_Item.GetItemLinkByID(r.item.id) or r.item.id
    end
    if itemInfo == nil then
        return
    end
    pcall(SetItemCraftingQualityOverlay, self.Button, itemInfo)
    if self.ProfessionQualityOverlay and self.ProfessionQualityOverlay:GetAtlas() == nil then
        self.ProfessionQualityOverlay:Hide()
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
    local isDesaturated = false
    if r.effects then
        for _, effect in ipairs(r.effects) do
            if effect.type == "btnDesaturate" and effect.status == true then
                isDesaturated = true
                break
            end
        end
    end
    -- 设置物品边框
    if addon.G.Masque then
        self.Border:Hide()
        if (not isDesaturated) and self.EFrame.Config.isShowQualityBorder == true and self.CbResult.borderColor and self.IconBorder then
            self.IconBorder:SetVertexColor(unpack(self.CbResult.borderColor))
            self.IconBorder:Show()
        elseif self.IconBorder then
            self.IconBorder:Hide()
        end
    elseif (not isDesaturated) and self.EFrame.Config.isShowQualityBorder == true and self.CbResult.borderColor then
        self.Border:Show()
        self.Border:SetBackdropBorderColor(unpack(self.CbResult.borderColor))
    else
        self.Border:Show()
        self.Border:SetBackdropBorderColor(unpack(const.DefaultItemColor))
    end
    self:UpdateCraftingQualityOverlay()
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
        -- 判断是否是DurationObject类型
        if r.itemCooldown.IsZero ~= nil then
            self.Cooldown:SetCooldownFromDurationObject(r.itemCooldown)
        else
            local startTime = r.itemCooldown.startTime or 0
            local duration = r.itemCooldown.duration or 0
            self.Cooldown:SetCooldown(startTime, duration)
        end
    else
        self.Cooldown:SetCooldown(0, 0)
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
    ---@diagnostic disable-next-line: param-type-mismatch
    GameTooltip:SetOwner(self.Button, "ANCHOR_RIGHT") -- 设置提示显示的位置
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
    if self.isMasqueSkinned and self.MasqueGroup and self.MasqueGroup.RemoveButton and self.Button then
        pcall(self.MasqueGroup.RemoveButton, self.MasqueGroup, self.Button)
    end
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
    self:UnregisterBindkeyEvents()
    self:ClearOverrideBinding()
    self.Button:Hide()
    self.Button:ClearAllPoints()
    self.Border:Hide()
    self.Border:ClearAllPoints()
    self.Border = nil
    self.Icon = nil
    self.BindkeyString = nil
    self.Cooldown = nil
    self.IconBorder = nil
    self.ProfessionQualityOverlay = nil
    self.MasqueGroup = nil
    self.isMasqueSkinned = nil
    self.SkinProvider = nil
    self.isSkinApplied = nil
    self.didRenderSkinApply = nil
    self.didDeferredSkinApply = nil
    self.Button = nil
end
