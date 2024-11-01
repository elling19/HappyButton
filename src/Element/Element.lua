local addonName, _ = ...


---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class E: AceModule
local E = addon:NewModule("Element")

---@class Trigger: AceModule
local Trigger = addon:GetModule("Trigger")


---@return ElementConfig
---@param title string
---@param type ElementType
function E:New(title, type)
    ---@type ElementConfig
    local config = {
        id = U.String.GenerateID(),
        isDisplayMouseEnter = false,
        title = title,
        type = type,
        icon = 134400,
        elements = {},
        elesGrowth = const.GROWTH.RIGHTBOTTOM,
        attachFrame = const.ATTACH_FRAME.UIParent,
        anchorPos = const.ANCHOR_POS.CENTER,
        attachFrameAnchorPos = const.ANCHOR_POS.CENTER,
        loadCond = {
            LoadCond = true,
        },
        isUseRootTexts = true,
        texts = {},
        configSelectedTextIndex = 1,
        triggers = {},
        configSelectedTriggerIndex = 1,
        condGroups = {},
        configSelectedCondGroupIndex = 1,
        configSelectedCondIndex = 1,
    }

    -- 🍃 创建叶子节点时：
    -- 🍃 默认创建“自身触发器”，并且同时添加两个条件组：
    --    1. “是否学会为假”的条件，并且添加上“隐藏”的特效；
    --    2. 添加上“是否可用为假”的条件，并且添加上“顶点着色”的特效；
    -- 🍃 也就是创建物品的时候，当物品不存在或者没有学习的时候，默认不显示。当物品不可用，显示红色按钮
    if self:IsLeaf(config) then
        local defaultTriiger = Trigger:NewSelfTriggerConfig()
        ---@type ConditionConfig
        local isLearnedCond = {
            leftTriggerId = defaultTriiger.id,
            leftVal = "isLearned",
            operator = "=",
            rightValue = false,
        }
        ---@type EffectConfig
        local btnHideEffectConfig = {
            type = "btnHide",
            attr = {},
            status = true
        }
        ---@type ConditionGroupConfig
        local btnHideCondGroupConfig = {
            conditions = {
                isLearnedCond,
            },
            expression = "%cond.1",
            effects = {btnHideEffectConfig, },
        }
        ---@type ConditionConfig
        local isUsableCond = {
            leftTriggerId = defaultTriiger.id,
            leftVal = "isUsable",
            operator = "=",
            rightValue = false,
        }
        ---@type EffectConfig
        local btnVertexColorEffectConfig = {
            type = "btnVertexColor",
            attr = {},
            status = true
        }
        ---@type ConditionGroupConfig
        local btnVertexColorCondGroupConfig = {
            conditions = {
                isUsableCond,
            },
            expression = "%cond.1",
            effects = {btnVertexColorEffectConfig, },
        }

        config.triggers = {defaultTriiger, }
        config.condGroups = {btnHideCondGroupConfig, btnVertexColorCondGroupConfig}
    end
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


---@param config ElementConfig
---@return boolean
function E:IsLeaf(config)
    if config.type == const.ELEMENT_TYPE.ITEM or config.type == const.ELEMENT_TYPE.ITEM_GROUP or config.type == const.ELEMENT_TYPE.SCRIPT then
        return true
    end
    return false
end