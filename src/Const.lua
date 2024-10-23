local addonName, _ = ... ---@type string, table
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
    Hidden = 0, -- 隐藏
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
    [const.ITEM_TYPE.ITEM] = L["Item"],
    [const.ITEM_TYPE.EQUIPMENT] = L["Equipment"],
    [const.ITEM_TYPE.TOY] = L["Toy"],
    [const.ITEM_TYPE.SPELL] = L["Spell"],
    [const.ITEM_TYPE.MOUNT] = L["Mount"],
    [const.ITEM_TYPE.PET] = L["Pet"],
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
    [const.ITEMS_GROUP_MODE.RANDOM] = L["Display one item, randomly selected."],
    [const.ITEMS_GROUP_MODE.SEQ] = L["Display one item, selected sequentially."],
}

--[[
-- 排列方向
]]
---@enum Arrange
const.ARRANGE = {
    HORIZONTAL = 1, -- 水平
    VERTICAL = 2,   -- 垂直
}

-- 排列方向类型选项
---@class ArrangeOptions
---@type table<number, string>
const.ArrangeOptions = {
    [const.ARRANGE.HORIZONTAL] = L["Horizontal"],
    [const.ARRANGE.VERTICAL] = L["Vertical"],
}

--[[
生长方向
]]
---@enum Growth
const.GROWTH = {
    TOPLEFT = "TOPLEFT",
    TOPRIGHT = "TOPRIGHT",
    BOTTOMLEFT = "BOTTOMLEFT",
    BOTTOMRIGHT = "BOTTOMRIGHT",
    LEFTTOP = "LEFTTOP",
    LEFTBOTTOM = "LEFTBOTTOM",
    RIGHTTOP = "RIGHTTOP",
    RIGHTBOTTOM = "RIGHTBOTTOM"
}

-- 生长方向类型选项
---@class ArrangeOptions
---@type table<number, string>
const.GrowthOptions = {
    [const.GROWTH.TOPLEFT] = L["TOPLEFT"],
    [const.GROWTH.TOPRIGHT] = L["TOPRIGHT"],
    [const.GROWTH.BOTTOMLEFT] = L["BOTTOMLEFT"],
    [const.GROWTH.BOTTOMRIGHT] = L["BOTTOMRIGHT"],
    [const.GROWTH.LEFTTOP] = L["LEFTTOP"],
    [const.GROWTH.LEFTBOTTOM] = L["LEFTBOTTOM"],
    [const.GROWTH.RIGHTTOP] = L["RIGHTTOP"],
    [const.GROWTH.RIGHTBOTTOM] = L["RIGHTBOTTOM"],
}

-- 依附锚点位置
---@enum AnchorPos
const.ANCHOR_POS = {
    TOPLEFT = "TOPLEFT",
    TOPRIGHT = "TOPRIGHT",
    BOTTOMLEFT = "BOTTOMLEFT",
    BOTTOMRIGHT = "BOTTOMRIGHT",
    TOP = "TOP",
    BOTTOM = "BOTTOM",
    LEFT = "LEFT",
    RIGHT = "RIGHT",
    CENTER = "CENTER"
}

-- 依附锚点位置选项
---@class AnchorPosOptions
---@type table<number, string>
const.AnchorPosOptions = {
    [const.ANCHOR_POS.TOPLEFT] = L["TOPLEFT"],
    [const.ANCHOR_POS.TOPRIGHT] = L["TOPRIGHT"],
    [const.ANCHOR_POS.BOTTOMLEFT] = L["BOTTOMLEFT"],
    [const.ANCHOR_POS.BOTTOMRIGHT] = L["BOTTOMRIGHT"],
    [const.ANCHOR_POS.TOP] = L["TOP"],
    [const.ANCHOR_POS.BOTTOM] = L["BOTTOM"],
    [const.ANCHOR_POS.LEFT] = L["LEFT"],
    [const.ANCHOR_POS.RIGHT] = L["RIGHT"],
    [const.ANCHOR_POS.CENTER] = L["CENTER"],
}


---
--[[
战斗状态加载条件
]]
---@enum CombatLoadCond
const.COMBAT_LOAD_COND = {
    ALWAYS_LOAD = 1,     -- 总是显示
    OUT_COMBAT_LOAD = 2, -- 战斗外显示
    IN_COMBAT_LOAD = 3   -- 战斗中显示
}


---@class CombatLoadCondOptions
const.CombatLoadCondOptions = {
    [const.COMBAT_LOAD_COND.ALWAYS_LOAD] = L["Always load"],
    [const.COMBAT_LOAD_COND.OUT_COMBAT_LOAD] = L["Load when out of combat"],
    [const.COMBAT_LOAD_COND.IN_COMBAT_LOAD] = L["Load when in combat"],
}

---@enum AttachFrame
const.ATTACH_FRAME = {
    UIParent = "UIParent"
}

-- 常见依附框体
---@class AttachFrameOptions
---@type table<number, string>
const.AttachFrameOptions = {
    ["UIParent"] = L["UIParent"],
    ["GameMenuFrame"] = L["GameMenuFrame"],
    ["Minimap"] = L["Minimap"],
    ["ProfessionsBookFrame"] = L["ProfessionsBookFrame"],
    ["WorldMapFrame"] = L["WorldMapFrame"],
    ["PVEFrame"] = L["PVEFrame"],
    ["CollectionsJournal"] = L["CollectionsJournal"]
}


--[[
-- 事件常量
]]
const.EVENT = {
    EXIT_EDIT_MODE = "EXIT_EDIT_MODE", -- 退出编辑模式
}
