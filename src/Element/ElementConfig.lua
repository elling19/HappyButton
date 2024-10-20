
---@class ItemAttr
---@field type integer | nil
---@field id integer | nil
---@field icon integer | string | nil
---@field name string | nil
---@field replaceName string | nil

---@class ItemGroupAttr
---@field mode ItemsGroupMode
---@field displayUnLearned boolean
---@field replaceName string | nil

---@class ScriptAttr
---@field script string | nil  -- 原始脚本文件

---@class ElementConfig
---@field iconWidth number | nil
---@field iconHeight number | nil
---@field title string
---@field type ElementType
---@field extraAttr any | nil
---@field elements ElementConfig[]
---@field icon string | number | nil
---@field anchorPos string | nil --锚点位置
---@field attachFrame string | nil --依附框体
---@field attachFrameAnchorPos string | nil -- 依附框体锚点位置
---@field posX number | nil -- X轴位置
---@field posY number | nil  -- Y轴位置
---@field elesGrowth string --子元素生长方向
---@field isDisplayMouseEnter boolean --是否鼠标移入显示
---@field isDisplayText boolean  -- 是否显示文字
local ElementConfig = {}


---@class ItemConfig: ElementConfig
---@field extraAttr ItemAttr
local ItemConfig = {}

---@class ScriptConfig: ElementConfig
---@field extraAttr ScriptAttr
local ScriptConfig = {}

---@class ItemGroupConfig: ElementConfig
---@field extraAttr ItemGroupAttr
local ItemGroupConfig = {}


---@class BarConfig: ElementConfig
local BarConfig = {}

---@class BarGroupConfig: ElementConfig
local BarGroupConfig = {}
