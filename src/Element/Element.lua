local addonName, _ = ...


---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')


---@class E: AceModule
local E = addon:NewModule("Element")

--[[
生成时间戳+8位随机字符串来标识配置的唯一性
]]
---@return string
function E:GenerateID()
    local chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local result = {}
    -- 生成随机部分
    for _ = 1, 8 do
        local index = math.random(#chars)
        table.insert(result, chars:sub(index, index))
    end
    -- 获取时间戳
    local timestamp = time()
    -- 拼接随机字符串和时间戳
    return timestamp .. '_' .. table.concat(result)
end

---@return ElementConfig
---@param title string
---@param type ElementType
function E:New(title, type)
    ---@type ElementConfig
    local config = {
        id = self:GenerateID(),
        isLoad = true,
        title = title,
        type = type,
        icon = 134400,
        elements = {},
        isDisplayMouseEnter = false,
        isDisplayText = false,
        elesGrowth = const.GROWTH.RIGHTBOTTOM,
        attachFrame = const.ATTACH_FRAME.UIParent,
        anchorPos = const.ANCHOR_POS.CENTER,
        attachFrameAnchorPos = const.ANCHOR_POS.CENTER,
        combatLoadCond = const.COMBAT_LOAD_COND.OUT_COMBAT_LOAD,
        texts = {},
        useParentTexts = false,
        configSelectedTextIndex = 1,
    }
    return config
end

---@private
---@param config ElementConfig
---@return ElementConfig
function E:InitExtraAttr(config)
    if config.extraAttr == nil then
        config.extraAttr = {}
    end
    return config
end

---@param config ElementConfig
---@return ScriptConfig
function E:ToScript(config)
    return E:InitExtraAttr(config) ---@type ScriptConfig
end

---@param config ElementConfig
---@return ItemGroupConfig
function E:ToItemGroup(config)
    return E:InitExtraAttr(config) ---@type ItemGroupConfig
end

---@param config ElementConfig
---@return ItemConfig
function E:ToItem(config)
    return E:InitExtraAttr(config) ---@type ItemConfig
end

---@param title string
---@return ItemGroupConfig
function E:NewItemGroup(title)
    local e = E:New(title, const.ELEMENT_TYPE.ITEM_GROUP)
    e = E:ToItemGroup(e)
    e.extraAttr.mode = const.ITEMS_GROUP_MODE.RANDOM
    e.extraAttr.displayUnLearned = false
    e.extraAttr.configSelectedItemIndex = 1
    return e
end

---@param config ElementConfig
---@return BarConfig
function E:ToBar(config)
    return E:InitExtraAttr(config) ---@type BarConfig
end

---@param config ElementConfig
---@return BarGroupConfig
function E:ToBarGroup(config)
    return E:InitExtraAttr(config) ---@type BarGroupConfig
end
