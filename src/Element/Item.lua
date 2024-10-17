local addonName, _ = ...


---@class HappyToolkit: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

local Element = addon:GetModule("Element", true)

---@class CONST: AceModule
local const = addon:GetModule('CONST')


---@class Item: Element
---@field type integer | nil
---@field id integer | nil
---@field icon integer | string | nil
---@field name string | nil
---@field alias string | nil
local Item = addon:NewModule("Item", Element)


---@param item ItemOfHtItem
---@return Item
function Item:New(item)
    local obj = setmetatable({}, {__index = self})
    obj.type = item.type
    obj.id = item.id
    obj.icon = item.icon
    obj.name = item.name
    obj.alias = item.alias
    return obj
  end