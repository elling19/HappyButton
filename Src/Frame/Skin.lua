local addonName, _ = ...

---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Skin: AceModule
local Skin = addon:NewModule("Skin")

---@return string
function Skin:ResolveSkinProvider()
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

---@param btn Btn | nil
---@return string
function Skin:GetSkinProvider(btn)
    -- provider 按模块单例缓存，创建后全局复用，避免不同调用时机出现不一致。
    if self.Provider == nil then
        self.Provider = self:ResolveSkinProvider()
    end
    return self.Provider
end

---@param btn Btn | nil
function Skin:BindSkinReferences(btn)
    if btn == nil or btn.Button == nil or btn.Icon == nil then
        return
    end
    ---@diagnostic disable-next-line: undefined-field
    btn.Button.icon = btn.Icon
    ---@diagnostic disable-next-line: undefined-field
    btn.Button.Icon = btn.Icon
end

---@param btn Btn | nil
---@param highlightAlpha number
function Skin:ApplyFallbackButtonTextures(btn, highlightAlpha)
    if btn == nil or btn.Button == nil then
        return
    end
    local white8x8 = "Interface\\Buttons\\WHITE8x8"
    if addon.G and addon.G.ElvUI and addon.G.ElvUI.Media and addon.G.ElvUI.Media.Textures and addon.G.ElvUI.Media.Textures.White8x8 then
        white8x8 = addon.G.ElvUI.Media.Textures.White8x8
    end
    btn.Button:SetHighlightTexture(white8x8)
    btn.Button:GetHighlightTexture():SetVertexColor(1, 1, 1, highlightAlpha)
    btn.Button:SetPushedTexture(white8x8)
    btn.Button:GetPushedTexture():SetVertexColor(1, 1, 1, highlightAlpha)
end

---@param btn Btn | nil
---@param provider string
function Skin:ApplyIconCropByProvider(btn, provider)
    if btn == nil then
        return
    end
    self:ApplyIconTexCoordByProvider(btn.Icon, provider)
end

---@param icon Texture | nil
---@param provider string
function Skin:ApplyIconTexCoordByProvider(icon, provider)
    if icon == nil then
        return
    end
    if provider == "elvui" then
        ---@diagnostic disable-next-line: undefined-field
        local coords = addon.G and addon.G.ElvUI and addon.G.ElvUI.TexCoords
        if type(coords) == "table" and #coords >= 4 then
            icon:SetTexCoord(unpack(coords))
        else
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end
        return
    end
    if provider == "ndui" then
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        return
    end
    icon:SetTexCoord(0, 1, 0, 1)
end

---@param btn Btn | nil
---@return table | nil
function Skin:GetMasqueGroup(btn)
    if btn == nil then
        return nil
    end
    if btn.MasqueGroup then
        return btn.MasqueGroup
    end
    if not addon.G.Masque then
        return nil
    end
    -- 直接使用插件分组，不使用额外子分组。
    btn.MasqueGroup = addon.G.Masque:Group(addonName)
    return btn.MasqueGroup
end

---@param btn Btn | nil
---@return boolean
function Skin:ApplyMasqueSkin(btn)
    local masqueGroup = self:GetMasqueGroup(btn)
    if not masqueGroup or btn == nil or not btn.Button or not btn.Icon then
        return false
    end
    if btn.isMasqueSkinned then
        return true
    end
    local ok = pcall(masqueGroup.AddButton, masqueGroup, btn.Button, {
        Icon = btn.Icon,
        Cooldown = btn.Cooldown,
        IconBorder = btn.IconBorder,
    })
    if ok then
        btn.isMasqueSkinned = true
    end
    return ok
end

---@param btn Btn | nil
---@return boolean
function Skin:ApplyElvUISkin(btn)
    if btn == nil or btn.Button == nil then
        return false
    end
    self:BindSkinReferences(btn)
    local skinned = false
    local skins = addon.G and addon.G.ElvUISkins
    ---@diagnostic disable-next-line: undefined-field
    if skins and skins.HandleButton then
        ---@diagnostic disable-next-line: undefined-field
        local ok, ret = pcall(skins.HandleButton, skins, btn.Button)
        skinned = ok and ret ~= false and ret ~= nil
    end
    ---@diagnostic disable-next-line: undefined-field
    if skins and skins.HandleIcon and btn.Icon then
        ---@diagnostic disable-next-line: undefined-field
        pcall(skins.HandleIcon, skins, btn.Icon)
    end
    if not skinned then
        self:ApplyFallbackButtonTextures(btn, 0.3)
        skinned = true
    end
    return skinned
end

---@param btn Btn | nil
---@return boolean
function Skin:ApplyNDuiSkin(btn)
    if btn == nil or btn.Button == nil then
        return false
    end
    self:BindSkinReferences(btn)
    self:ApplyFallbackButtonTextures(btn, 0.25)
    return true
end

---@param btn Btn | nil
---@param provider string | nil
---@return boolean
function Skin:ApplySkin(btn, provider)
    if btn == nil or btn.Button == nil or btn.Icon == nil then
        return false
    end
    local skinProvider = provider or self:GetSkinProvider(btn)
    self:BindSkinReferences(btn)
    self:ApplyIconTexCoordByProvider(btn.Icon, skinProvider)
    local applied = self:ApplySkinByProvider(btn, skinProvider)
    ---@diagnostic disable-next-line: undefined-field
    if btn.ForceFallbackTexture == true then
        ---@diagnostic disable-next-line: undefined-field
        self:ApplyFallbackButtonTextures(btn, btn.FallbackHighlightAlpha or 0.3)
    end
    return applied
end

---@param btn Btn | nil
---@param provider string
---@return boolean
function Skin:ApplySkinByProvider(btn, provider)
    if provider == "masque" then
        return self:ApplyMasqueSkin(btn)
    end
    if provider == "elvui" then
        return self:ApplyElvUISkin(btn)
    end
    if provider == "ndui" then
        return self:ApplyNDuiSkin(btn)
    end
    return true
end
