local addonName, _ = ...  ---@type string, table
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, false)

---@class CONST: AceModule
local const = addon:NewModule("CONST")

---@enum ElementType
const.ELEMENT_TYPE = {
    ITEM = 1,
    ITEM_GROUP = 2,
    SCRIPT = 3,
    BAR = 4,
    BAR_GROUP = 5
}

-- 元素分类选项
---@class ElementTypeOptions
---@type table<number, string>
const.ElementTypeOptions = {
    [const.ELEMENT_TYPE.ITEM] = L["Item"],
    [const.ELEMENT_TYPE.ITEM_GROUP] = L["Script"],
    [const.ELEMENT_TYPE.SCRIPT] = L["ItemGroup"],
    [const.ELEMENT_TYPE.BAR] = L["Bar"],
    [const.ELEMENT_TYPE.BAR_GROUP] = L["BarGroup"],
}

---@enum BarDisplayMode
const.BAR_DISPLAY_MODE = {
    Hidden = 0,  -- 隐藏
    Alone = 1,  -- 独立的
    Mount = 2,  -- 挂载
}


-- 物品条分类选项
---@class BarDisplayModeOptions
---@type table<number, string>
const.BarDisplayModeOptions = {
    [const.BAR_DISPLAY_MODE.Hidden] = L["Hidden"],
    [const.BAR_DISPLAY_MODE.Alone] = L["Display as alone items bar"],
    [const.BAR_DISPLAY_MODE.Mount] = L["Append to the main frame"],
}

-- 物品分类
---@enum ItemType
const.ITEM_TYPE = {
    ITEM = 1,
    EQUIPMENT = 2,
    TOY = 3,
    SPELL = 4,
    MOUNT = 5,
    PET = 6,
}

-- 物品类型选项
---@class ItemTypeptions
---@type table<number, string>
const.ItemTypeOptions = {
    [const.ITEM_TYPE.ITEM]=L["Item"],
    [const.ITEM_TYPE.EQUIPMENT]=L["Equipment"],
    [const.ITEM_TYPE.TOY]=L["Toy"],
    [const.ITEM_TYPE.SPELL]=L["Spell"],
    [const.ITEM_TYPE.MOUNT]=L["Mount"],
    [const.ITEM_TYPE.PET]=L["Pet"],
}

-- 物品组分类
---@enum ItemsGroupMode
const.ITEMS_GROUP_MODE = {
    RANDOM = 1,
    SEQ = 2,
    MULTIPLE = 3,
    SINGLE = 4
}

-- 物品组类型选项
---@class ItemsGroupModeOptions
---@type table<number, string>
const.ItemsGroupModeOptions = {
    [const.ITEMS_GROUP_MODE.RANDOM] = L["Display only one item, randomly selected."] ,
    [const.ITEMS_GROUP_MODE.SEQ] = L["Display only one item, selected sequentially."],
}

--[[
-- 排列方向
]]
---@enum Arrange
const.ARRANGE = {
    HORIZONTAL = 1,  -- 水平
    VERTICAL = 2,  -- 垂直
}

-- 排列方向类型选项
---@class ArrangeOptions
---@type table<number, string>
const.ArrangeOptions = {
    [const.ARRANGE.HORIZONTAL] = L["Horizontal"] ,
    [const.ARRANGE.VERTICAL] = L["Vertical"],
}

--[[
生长方向
]]
---@enum Growth
const.GROWTH = {
    TOP_LEFT = "TOP_LEFT",
    TOP_RIGHT = "TOP_RIGHT",
    BOTTOM_LEFT = "BOTTOM_LEFT",
    BOTTOM_RIGHT = "BOTTOM_RIGHT",
    LEFT_TOP = "LEFT_TOP",
    LEFT_BOTTOM = "LEFT_BOTTOM",
    RIGHT_TOP = "RIGHT_TOP",
    RIGHT_BOTTOM = "RIGHT_BOTTOM"
}

-- 生长方向类型选项
---@class ArrangeOptions
---@type table<number, string>
const.GrowthOptions = {
    [const.GROWTH.TOP_LEFT] = L["TOP_LEFT"] ,
    [const.GROWTH.TOP_RIGHT] = L["TOP_RIGHT"],
    [const.GROWTH.BOTTOM_LEFT] = L["BOTTOM_LEFT"],
    [const.GROWTH.BOTTOM_RIGHT] = L["BOTTOM_RIGHT"],
    [const.GROWTH.LEFT_TOP] = L["LEFT_TOP"] ,
    [const.GROWTH.LEFT_BOTTOM] = L["LEFT_BOTTOM"],
    [const.GROWTH.RIGHT_TOP] = L["RIGHT_TOP"],
    [const.GROWTH.RIGHT_BOTTOM] = L["RIGHT_BOTTOM"],
}

--[[
战斗状态加载条件
]]
---@enum CombatLoadCond
const.COMBAT_LOAD_COND = {
    ALWAYS_LOAD = 1,  -- 总是显示
    OUT_COMBAT_LOAD = 2,  -- 战斗外显示
    IN_COMBAT_LOAD = 3  -- 战斗中显示
}


---@class CombatLoadCondOptions
const.CombatLoadCondOptions = {
    [const.COMBAT_LOAD_COND.ALWAYS_LOAD] = L["Always load"],
    [const.COMBAT_LOAD_COND.OUT_COMBAT_LOAD] = L["Load when out of combat"],
    [const.COMBAT_LOAD_COND.IN_COMBAT_LOAD] = L["Load when in combat"],
}


--[[
-- 事件常量
]]
const.EVENT = {
    EXIT_EDIT_MODE = "EXIT_EDIT_MODE",  -- 退出编辑模式
}