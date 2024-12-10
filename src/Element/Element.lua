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

--- 获取ItemAttr的Event列表
---@param itemAttr ItemAttr
---@return table<EventString, any[][]>
function E:GetItemAttrEvents(itemAttr)
    ---@type table<string, any[]>
    local events = {}
    if itemAttr == nil then
        return events
    end
    if itemAttr.type == const.ITEM_TYPE.ITEM then
        events["BAG_UPDATE"] = {}
        events["UNIT_SPELLCAST_SUCCEEDED"] = {{"player"}, }
        return events
    end
    if itemAttr.type == const.ITEM_TYPE.EQUIPMENT then
        events["BAG_UPDATE"] = {}
        events["PLAYER_EQUIPMENT_CHANGED"] = {}
        events["UNIT_SPELLCAST_SUCCEEDED"] = {{"player"}, }
        return events
    end
    if itemAttr.type == const.ITEM_TYPE.TOY then
        events["NEW_TOY_ADDED"] = {}
        events["UNIT_SPELLCAST_SUCCEEDED"] = {{"player"}, }
        return events
    end
    if itemAttr.type == const.ITEM_TYPE.SPELL then
        events["SPELLS_CHANGED"] = {}
        events["UNIT_SPELLCAST_SUCCEEDED"] = {{"player"}, }
        events["SPELL_UPDATE_COOLDOWN"] = {}
        return events
    end
    if itemAttr.type == const.ITEM_TYPE.MOUNT then
        events["MOUNT_JOURNAL_USABILITY_CHANGED"] = {}
        events["NEW_MOUNT_ADDED"] = {}
        return events
    end
    if itemAttr.type == const.ITEM_TYPE.PET then
        events["PET_BAR_UPDATE_COOLDOWN"] = {}
        events["NEW_PET_ADDED"] = {}
        events["UNIT_SPELLCAST_SUCCEEDED"] = {{"player"}, }
        return events
    end
    return events
end

--- 获取Macro的event列表
---@param macroAttr MacroAttr
---@return table<EventString, any[][]>
function E:GetMacroEvents(macroAttr)
    local events = {}
    if macroAttr.ast == nil then
        return events
    end
    if macroAttr.ast.tooltip ~= nil then
        E:MergeEvents(events, E:GetItemAttrEvents(macroAttr.ast.tooltip))
    end
    if macroAttr.ast.commands == nil then
        return events
    end
    for _, command in ipairs(macroAttr.ast.commands) do
        if command.conds then
            for _, cond in ipairs(command.conds) do
                if cond and cond.booleanConds then
                    for _, booleanCond in ipairs(cond.booleanConds) do
                        if booleanCond.type == "mod" then
                            E:MergeEvents(events, {["MODIFIER_STATE_CHANGED"] = {}})
                        end
                        if booleanCond.isTarget == true then
                            E:MergeEvents(events, {["PLAYER_TARGET_CHANGED"] = {}})
                        end
                    end
                end
                if cond and cond.targetConds then
                    for _, targetCond in ipairs(cond.targetConds) do
                        if targetCond.type == "mouseover" then
                            E:MergeEvents(events, {["UPDATE_MOUSEOVER_UNIT"] = {}})
                        end
                    end
                end
            end
        end
        if command.cmd == "use" then
            if command.param and command.param.items then
                for _, item in ipairs(command.param.items) do
                    if item then
                        E:MergeEvents(events, E:GetItemAttrEvents(item))
                    end
                end
            end
        end
    end
    return events
end

--- 合并events列表
---@param events table<EventString, any[][]> 合并后的events列表
---@param mergedEvents table<EventString, any[][]>  被合并的events列表
function E:MergeEvents(events, mergedEvents)
    for k, tt in pairs(mergedEvents) do
        if events[k] == nil then
            events[k] = U.Table.DeepCopy(tt)
        else
            for _, t in ipairs(tt) do
                local hasSame = false
                for _, _t in ipairs(events[k]) do
                    if U.Table.Equal(t, _t) then
                        hasSame = true
                        break
                    end
                end
                if hasSame == false then
                    table.insert(events[k], t)
                end
                hasSame = false
            end
        end
    end
    
end

--- 获取config的监听事件
--- @param config ElementConfig
--- @return table<EventString, any[][]> -- key为事件名称，value为一个二维数组，每一个数组表示一组事件参数。当数组为空的时候表示不限制
function E:GetEvents(config)
    ---@type table<string, any[]>
    local events = {
        ["PLAYER_ENTERING_WORLD"] = {},  -- 读蓝条
        ["PLAYER_REGEN_DISABLED"] = {},  -- 进入战斗
        ["PLAYER_REGEN_ENABLED"] = {}, -- 退出战斗
    }
    if config.listenEvents ~= nil then
        for event, _ in pairs(config.listenEvents) do
            events[event] = {}
        end
    end
    if config.type == const.ELEMENT_TYPE.ITEM then
        local item = E:ToItem(config)
        if item.extraAttr then
            E:MergeEvents(events, E:GetItemAttrEvents(item.extraAttr))
        end
    end
    if config.type == const.ELEMENT_TYPE.MACRO then
        local macro = E:ToMacro(config)
        E:MergeEvents(events, E:GetMacroEvents(macro.extraAttr))
    end
    if config.triggers and #config.triggers > 0 then
        for _, trigger in ipairs(config.triggers) do
            if trigger.type == "aura" then
                events["UNIT_AURA"] = {}
            end
            if trigger.type == "item" then
                local confine = Trigger:ToItemConfine(trigger.confine)
                local item = confine.item
                E:MergeEvents(events, E:GetItemAttrEvents(item))
            end
        end
    end
    -- 递归查找，并且合并去除重复的参数列表
    if config.elements and #config.elements then
        for _, childEle in ipairs(config.elements) do
            E:MergeEvents(events, E:GetEvents(childEle))
        end
    end
    return events
end


--- 获取config的是否加载监听事件
--- @param config ElementConfig
--- @return table<EventString, any[][]> -- key为事件名称，value为一个二维数组，每一个数组表示一组事件参数。当数组为空的时候表示不限制
function E:GetLoadCondEvents(config)
    ---@type table<string, any[]>
    local events = {
        ["HB_UPDATE_CONFIG"] = {},  -- 自定义事件
        ["PLAYER_ENTERING_WORLD"] = {},  -- 读蓝条
    }
    if config.loadCond == nil then
        return events
    end
    -- 开启战斗检查
    if config.loadCond.CombatCond ~= nil then
        events["PLAYER_REGEN_DISABLED"] = {}
        events["PLAYER_REGEN_ENABLED"] = {}
    end
    return events
end


--- 比较元素的events对象参数和事件参数，如果能够匹配返回true
---@param elementEventParams any[][]
---@param eventParam any[]
---@return boolean
function E:CompareEventParam(elementEventParams, eventParam)
    -- 如果元素参数二维数据为空，表示不设置条件
    if #elementEventParams == 0 then
        return true
    end
    for _, elementEventParam in ipairs(elementEventParams) do
        local met = true
        for k, param in ipairs(elementEventParam) do
            -- 当元素参数为-1的时候，表示这个参数不比较
            if param ~= -1 and param ~= eventParam[k] then
                met = false
                break
            end
        end
        if met == true then
            return true
        end
    end
    return false
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