local addonName, _ = ...


---@class HappyToolkit: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class Element: AceModule
---@field title string
---@field icon string | number | nil
---@field type ElementType
---@field attachFrame string | nil --依附框体
---@field anchorPos string | nil --锚点位置
---@field posX number  -- X轴位置
---@field posY number  -- Y轴位置
---@field arrange Arrange | nil -- 排列方向
---@field elements Element[]
local Element = addon:NewModule("Element")

---@return Element
---@param title string
---@param type ElementType
function Element:New(title, type)
    local obj = setmetatable({}, {__index = self})
    obj.title = title
    obj.type = type
    obj.elements = {}
    print(obj.elements)
    return obj
  end
