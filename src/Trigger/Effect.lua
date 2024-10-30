local addonName, _ = ...


---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')


---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class Effect: AceModule
local Effect = addon:NewModule("Effect")

-- 创建边框发光效果
---@return EffectConfig
function Effect:NewBorderGlowEffect()
    ---@type EffectConfig
    local effect = {
        type = "borderGlow",
        attr = {}
    }
    return effect
end


-- 创建图标隐藏效果
---@return EffectConfig
function Effect:NewBtnHideEffect()
    ---@type EffectConfig
    local effect = {
        type = "btnHide",
        attr = {}
    }
    return effect
end


-- 创建图标褪色
---@return EffectConfig
function Effect:NewBtnDesaturateEffect()
    ---@type EffectConfig
    local effect = {
        type = "btnDesaturate",
        attr = {}
    }
    return effect
end