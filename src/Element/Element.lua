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
  local icon
  local iconPath = "Interface\\AddOns\\HappyToolkit\\Media\\"
  if type == const.ELEMENT_TYPE.BAR_GROUP then
      icon = iconPath .. "BarGroup.blp"
  elseif type == const.ELEMENT_TYPE.BAR then
      icon = iconPath .. "Bar.blp"
  elseif type == const.ELEMENT_TYPE.ITEM_GROUP or type == const.ELEMENT_TYPE.SCRIPT then
      icon = iconPath .. "ItemGroup.blp"
  elseif type == const.ELEMENT_TYPE.ITEM then
      icon = iconPath .. "Item.blp"
  else
      icon = 134400
  end
  ---@type ElementConfig
  local config = {
    title = title,
    type = type,
    icon = icon,
    elements = {}
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