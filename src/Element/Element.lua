local addonName, _ = ...


---@class HappyToolkit: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')


---@class E: AceModule
local E = addon:NewModule("Element")


---@return ElementConfig
---@param title string
---@param type ElementType
function E:New(title, type)
  ---@type ElementConfig
  local config = {
    title = title,
    type = type,
    icon = 134400,
    elements = {},
    isDisplayMouseEnter = false,
    isDisplayText = false,
    elesGrowth=const.GROWTH.RIGHT_BOTTOM,
    combatDisplayCond = const.COMBAT_LOAD_COND.OUT_COMBAT_LOAD,
  }
  config.title = title
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