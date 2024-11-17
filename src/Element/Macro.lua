local addonName, _ = ...

---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class Result: AceModule
local R = addon:GetModule("Result")

---@class Macro: AceModule
local Macro = addon:NewModule("Macro")

---@class MacroCond
---@field targets string[] | nil
---@field conds string[] | nil

---@class MacroParam
---@field reset string | nil  -- 队列宏使用
---@field slot  number | nil  -- 装备装备使用
---@field script string | nil -- 非cast/use/castsqueue/equit宏使用，例如/click、/say
---@field items ItemAttr[] | nil

---@class MacroStat
---@field commmand string
---@field conds nil | MacroCond[]
---@field params MacroParam

--- 根据语句生成条件
---@param cond MacroCond
---@return string
function Macro:BuildMacroCondString(cond)
    local condString = "["
    if cond.targets and #cond.targets > 0 then
        condString = condString .. "@" .. cond.targets[1]
    end
    if cond.conds and #cond.conds > 0 then
        if cond.targets and #cond.targets > 0 then
            condString = condString .. ","
        end
        for _, condCond in ipairs(cond.conds) do
            condString = condString .. condCond .. ","
        end
    end
    condString = condString .. "]"
    return condString
end

--- 根据语句生成宏语句
---@param stat MacroStat
---@return string
function Macro:BuildMacroString(stat)
    local statDesc = ""
    statDesc = statDesc .. "/" .. stat.commmand .. " "
    if stat.conds ~= nil and #stat.conds > 0 then
        for _, cond in ipairs(stat.conds) do
            local condDesc = Macro:BuildMacroCondString(cond)
            statDesc = statDesc .. condDesc
        end
        statDesc = statDesc .. " "
    end
    if stat.params.reset then
        statDesc = statDesc .. "reset=" + stat.params.reset .. " "
    end
    if stat.params.script then
        statDesc = statDesc .. stat.params.reset .. " "
    end
    if stat.params.slot then
        statDesc = statDesc .. stat.params.slot .. " "
    end
    if stat.params.items then
        local itemDesc = ""
        for _, item in ipairs(stat.params.items) do
            itemDesc = itemDesc .. item.name .. ","
        end
        itemDesc = string.sub(itemDesc, 1, -2)  -- 移除最后一个字符
        statDesc = statDesc .. itemDesc
    end
    return statDesc
end

---@return MacroStat
function Macro:NewStat()
    ---@type MacroStat
    local stat = {
        commmand = "cast",
        conds = nil,
        params = {
        }
    }
    return stat
end

---return MacroCond
function Macro:NewCond()
    ---@type MacroCond
    local cond = {
        targets = nil,
        conds = nil
    }
    return cond
end

---@class MacroParseResult
---@field cmd string[]
---@field conds string[][]
---@field remaining string[]


---@class MacroCommand
---@field cmd string           -- 宏命令类型
---@field conds string[]      -- 条件
---@field items ItemAttr[]      -- 存储技能、物品或装备槽位的列表
---@field reset number | nil      -- reset 参数（可选）

local function pT(t)
    local s = ""
    for _, _t in ipairs(t) do
        s = s .. _t
    end
    print(s)
end

---@param macro string
function Macro:Ast(macro)
    local result = {
        showtooltip = nil, -- 用于存储 showtooltip 的参数（如果有的话）
        commands = {}      -- 用于存储宏的其他命令
    }
    local _macroString = U.String.Utf8ToTable(macro)
    -- 移除空字符
    local startIndex = 1
    for i = 1, #_macroString do
        if _macroString[i] ~= " " then
            startIndex = i
            break
        end
    end
    local macroString = {}
    for i = startIndex, #_macroString do
        table.insert(macroString, _macroString[i])
    end
    _macroString = {}

    --------------------------
    ---- 找到第一个命名符号：/
    --------------------------
    local firstCmdPreIndex = 1
    for index, char in ipairs(macroString) do
        if char == "/" then
            firstCmdPreIndex = index
            break
        end
    end

    --------------------------
    ---- 获取宏图标
    --------------------------
    -- 如果第一个字符就是/，则表示没有#showtooltip，使用智能图标
    if firstCmdPreIndex == 1 then
        result.showtooltip = nil
        -- 否则解析`#showtooltip <icon>`来获取需要展示的图标
    else
        local showtooltipString = ""
        for i = 1, firstCmdPreIndex - 1 do
            showtooltipString = showtooltipString .. macroString[i]
        end
        local param = macro:match("#showtooltip%s*(%S+)")
        if param then
            param = param:match("^%s*(.-)%s*$")
            if param ~= "" then
                result.showtooltip = param
            end
        end
    end

    ---------------------------
    ---- 遍历获取命令字符串列表
    ---------------------------
    local statStrings = {} ---@type table[]
    local statString = {} ---@type table
    for i = firstCmdPreIndex, #macroString do
        local s = macroString[i]
        if s == "/" then -- 表示新语句的开始，将旧的stat写入到stats中
            if #statString ~= 0 then
                table.insert(statStrings, U.Table.DeepCopyList(statString))
                statString = {}
            end
        end
        table.insert(statString, s)
    end
    table.insert(statStrings, U.Table.DeepCopyList(statString))


    ---------------------------------
    ---- 遍历命令字符串列表，组成AST
    ---------------------------------
    for _, stat in ipairs(statStrings) do
        local r = Macro:AstParse(stat)
        if r:is_err() then
            return r
        end
        local p = r:unwrap() ---@type MacroParseResult
    end
end

--------------------
--- 第一步解析：
--- 生成cmd：例如 "/cast"、"/use"
--- 生成conds：例如["@target", "@mouseover, dead"]
--- 生成remaining：例如"reset=60 item:224464, item:211880; reset=60 item:5512, item:211880"、"疾跑"
--------------------
---@param statement string[]
---@return Result
function Macro:AstParse(statement)
    local cmd = {}  ---@type string[]
    local cmdEnd = false
    local conds = {} ---@type string[][]
    local condsEnd = false
    local cond = {}---@type string[]
    local condStart = false
    local remainings = {} ---@type string[][]
    local remaining = {} ---@type string[]
    local remainingStart = false
    if statement and #statement ~= 0 or statement[1] == "/" then
        for _, s in ipairs(statement) do
            if s == "/" then
                if cmdEnd == false then
                    table.insert(cmd, s)
                else
                    print("/错误1。")
                    return R:Err("/错误。")
                end
            elseif s == " " then              -- 空格字符
                if cmdEnd == false then       -- 如果命令没有结束，此时空格表示结束命令语句
                    cmdEnd = true
                elseif condsEnd == false then -- 如果条件组没有结束
                    if condStart == true then -- 如果当前条件激活，追加到当前条件
                        table.insert(cond, s)
                    end                       -- 如果当前条件没有激活，则什么都不做，等待下一个"["来激活条件
                else                          -- 如果命令和条件组都结束了，则追加到剩余字符串中
                    table.insert(remaining, s)
                end
            elseif s == "[" then
                if cmdEnd == false then
                    print("[错误1。")
                    return R:Err("[错误。")
                end
                if condStart == true then
                    print("[错误2。")
                    return R:Err("[错误。")
                end
                if #cond ~= 0 then
                    print("[错误3。")
                    pT(cond)
                    return R:Err("[错误。")
                end
                if condsEnd == true then
                    table.insert(remaining, s)
                else
                    table.insert(cond, s)
                    condStart = true
                end
            elseif s == "]" then
                if cmdEnd == false then
                    print("]错误1。")
                    return R:Err("]错误。")
                end
                if condStart == false then
                    print("]错误2。")
                    return R:Err("]错误。")
                end
                if cond[1] ~= "[" then
                    print("]错误3。")
                    return R:Err("]错误。")
                end
                if condsEnd == true then
                    table.insert(remaining, s)
                else
                    table.insert(cond, s)
                    table.insert(conds, U.Table.DeepCopyList(cond))
                    cond = {}
                    condStart = false
                end
            elseif s == ";" then
                if cmdEnd == false then  -- 如果当前处在命令阶段，不能加入;分号
                    print(";错误1。")
                    return R:Err(";错误。")
                end
                if condStart == true then  -- 如果当前正处在条件激活阶段，不能加入;分号
                    print(";错误2。")
                    return R:Err(";错误。")
                end
                condsEnd = true
                table.insert(remainings, U.Table.DeepCopyList(remaining))
                remaining = {}
                remainingStart = false
            else
                if cmdEnd == false then       -- 如果命令cmd没有结束，追加到命令中
                    table.insert(cmd, s)
                elseif condsEnd == false then -- 如果条件组没有结束
                    if condStart == true then -- 如果当前条件处在激活状态，追加到当前条件
                        table.insert(cond, s)
                    else                      -- 如果当前条件组没有激活，此时表示条件组已经结束了，则结束条件组，追加到剩余字符串中
                        condsEnd = true
                        table.insert(remaining, s)
                        remainingStart = true
                    end
                else -- 命令和条件组都结束了，追加到剩余字符串中
                    table.insert(remaining, s)
                    remainingStart = true
                end
            end
        end
        print("cmd: ")
        local cmdString = ""
        for _, c in ipairs(cmd) do
            cmdString = cmdString .. c
        end
        print(cmdString)
        print("conds: ")
        for _, cond in ipairs(conds) do
            local condString = ""
            for _, d in ipairs(cond) do
                condString = condString .. d
            end
            print(condString)
        end
        print("remaining:")
        local remaingString = ""
        for _, r in ipairs(remaining) do
            remaingString = remaingString .. r
        end
        print(remaingString)
    end
    ---@type MacroParseResult
    local result = {
        cmd = cmd,
        conds = conds,
        remaining = remaining
    }
    return R:Ok(result)
end