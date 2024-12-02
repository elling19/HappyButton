local addonName, _ = ...


---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class E: AceModule
local E = addon:NewModule("Element")

---@class Item: AceModule
local Item = addon:GetModule("Item")

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
---@return MacroConfig
function E:ToMacro(config)
    return E:InitExtraAttr(config) ---@type MacroConfig
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

-- 是否是叶子节点
---@param config ElementConfig
---@return boolean
function E:IsLeaf(config)
    if config.type == const.ELEMENT_TYPE.ITEM or config.type == const.ELEMENT_TYPE.ITEM_GROUP or config.type == const.ELEMENT_TYPE.SCRIPT or config.type == const.ELEMENT_TYPE.MACRO then
        return true
    end
    return false
end

-- 是否是单一图标
---@param config ElementConfig
---@return boolean
function E:IsSingleIconConfig(config)
    if config.type == const.ELEMENT_TYPE.BAR or config.type == const.ELEMENT_TYPE.SCRIPT then
        return false
    else
        return true
    end
end


--- 获取config带图标的标题，使用在配置功能中
---@param config ElementConfig
---@return string
function E:GetTitleWithIcon(config)
    local icon = config.icon or 134400
    local iconPath = "|T" .. icon .. ":16|t"
    return iconPath .. config.title
end

--- 获取config的监听事件
--- @param config ElementConfig
--- @return table<string, boolean>
function E:GetEvents(config)
    ---@type table<string, boolean>
    local events = {
        ["PLAYER_REGEN_DISABLED"] = true,  -- 进入战斗
        ["PLAYER_REGEN_ENABLED"] = true, -- 退出战斗
        ["PLAYER_TARGET_CHANGED"] = true,
    }
    if config.listenEvents ~= nil then
        for event, _ in pairs(config.listenEvents) do
            events[event] = true
        end
    end
    local hasItem = false
    local hasEquipment = false
    local hasSpell = false
    local hasToy = false
    local hasMount = false
    local hasPet = false
    if config.type == const.ELEMENT_TYPE.ITEM then
        local item = E:ToItem(config)
        if item.extraAttr.type == const.ITEM_TYPE.ITEM then
            hasItem = true
        end
        if item.extraAttr.type == const.ITEM_TYPE.EQUIPMENT then
            hasEquipment = true
        end
        if item.extraAttr.type == const.ITEM_TYPE.TOY then
            hasToy = true
        end
        if item.extraAttr.type == const.ITEM_TYPE.SPELL then
            hasSpell = true
        end
        if item.extraAttr.type == const.ITEM_TYPE.MOUNT then
            hasMount = true
        end
        if item.extraAttr.type == const.ITEM_TYPE.PET then
            hasPet = true
        end
    end
    if hasItem or hasEquipment then
        events["BAG_UPDATE"] = true
    end
    if hasEquipment then
        events["PLAYER_EQUIPMENT_CHANGED"] = true
    end
    if hasSpell then
        events["SPELLS_CHANGED"] = true
        events["PLAYER_TALENT_UPDATE"] = true
        events["SPELL_UPDATE_COOLDOWN"] = true
    end
    if config.type == const.ELEMENT_TYPE.MACRO then
        events["MODIFIER_STATE_CHANGED"] = true
        events["UPDATE_MOUSEOVER_UNIT"] = true
        events["SPELL_UPDATE_COOLDOWN"] = true
    end
    if config.triggers and #config.triggers > 0 then
        for _, trigger in ipairs(config.triggers) do
            if trigger.type == "aura" then
                events["UNIT_AURA"] = true
            end
        end
    end
    -- 递归查找
    if config.elements and #config.elements then
        for _, childEle in ipairs(config.elements) do
            local childEvents = E:GetEvents(childEle)
            for k, v in pairs(childEvents) do
                events[k] = true
            end
        end
    end
    return events
end

-- 更新config的ItemAttr
function E:CompleteItemAttr(config)
    if config.type == const.ELEMENT_TYPE.BAR then
        if config.elements then
            for _, ele in ipairs(config.elements) do
                E:CompleteItemAttr(ele)
            end
        end
    end
    if config.type == const.ELEMENT_TYPE.MACRO then
        local macro = E:ToMacro(config)
        if macro.extraAttr.ast then
            if macro.extraAttr.ast.tooltip then
                Item:CompleteItemAttr(macro.extraAttr.ast.tooltip)
            end
            if macro.extraAttr.ast.commands then
                for _, command in ipairs(macro.extraAttr.ast.commands) do
                    if command.param and command.param.items then
                        for _, item in ipairs(command.param.items) do
                            Item:CompleteItemAttr(item)
                        end
                    end
                end
            end
        end
    end
end