local addonName, _ = ...

---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class Result: AceModule
local R = addon:GetModule("Result")

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class Macro: AceModule
local Macro = addon:NewModule("Macro")

---@alias MC string  --- MC:MacroChar宏字符的简称，用来将宏字符串按UTF-8格式拆分成一个个字符
---@alias MCList MC[]


---@class MacroParam
---@field reset string | nil  -- 队列宏使用
---@field slot  number | nil  -- 装备装备使用
---@field script string | nil -- 非cast/use/castsqueue/equit宏使用，例如/click、/say
---@field items ItemAttr[] | nil


---@class TargetCond
---@field type MacroTargetCondType

---@class BooleanCond
---@field type MacroBooleanCondType
---@field isTarget boolean -- 是否是目标条件还是玩家条件
---@field params nil | boolean | number[] | string[] | string | number


---@class MacroCond
---@field targetConds TargetCond[] | nil
---@field booleanConds BooleanCond[] | nil


---@class MacroCommand
---@field cmd string           -- 宏命令类型
---@field conds MacroCond[] | nil     -- 条件
---@field param MacroParam  -- 宏参数


---@class MacroParseResult
---@field cmd string[]
---@field conds string[][]
---@field remaining string[]


local function pT(t)
    local s = ""
    for _, _t in ipairs(t) do
        s = s .. _t
    end
    print(s)
end

---@param mcList MCList
---@return string
function Macro:MCListToString(mcList)
    local s = ""
    for _, _t in ipairs(mcList) do
        s = s .. _t
    end
    return s
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
    local macroString = {} ---@type MC[]
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
        local cmd = Macro:MCListToString(p.cmd)
        cmd = Macro:AstCmd(cmd)
        local conds = {} ---@type MacroCond[]
        for _, cond in ipairs(p.conds) do
            local c = Macro:MCListToString(cond)
            table.insert(conds, Macro:AstCondition(c))
        end
        ---@type MacroCommand
        local macroCommand = {
            cmd = cmd,
            conds = conds,
        }
    end
end

--------------------
--- 第一步解析：
--- 生成cmd：例如 "/cast"、"/use"
--- 生成conds：例如["@target", "@mouseover, dead"]
--- 生成remaining：例如"reset=60 item:224464, item:211880; reset=60 item:5512, item:211880"、"疾跑"
--------------------
---@param statement MC[]
---@return Result
function Macro:AstParse(statement)
    local cmd = {}  ---@type MC[]
    local cmdEnd = false
    local conds = {} ---@type MC[][]
    local condsEnd = false
    local cond = {}---@type MC[]
    local condStart = false
    local remainings = {} ---@type MC[][]
    local remaining = {} ---@type MC[]
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
    end
    ---@type MacroParseResult
    local result = {
        cmd = cmd,
        conds = conds,
        remaining = remaining
    }
    return R:Ok(result)
end

--- 将宏语句中的条件分解成宏target、宏mod、宏booleanCond
---@param condString string
---@return MacroCond
function Macro:AstCondition(condString)
    local macroCond = {booleanConds = {}, targetConds = {}} ---@type MacroCond
    if condString == nil or #condString == 0 then
        return macroCond
    end
    local conds = U.String.Split(condString, ",")
    for _, cond in ipairs(conds) do
        if string.sub(cond, 1, 7) == "target=" then
            local c = string.sub(cond, 8)
            c = U.String.Trim(c)
            local targetCond = { type=c }  ---@type TargetCond
            table.insert(macroCond.targetConds, targetCond)
        elseif string.sub(cond, 1, 1) == "@" then
            local c = string.sub(cond, 1)
            c = U.String.Trim(c)
            local targetCond = { type=c }  ---@type TargetCond
            table.insert(macroCond.targetConds, targetCond)
        else
            table.insert(macroCond.booleanConds, Macro:AstStringToBooleanCond(cond))
        end
    end
    return macroCond
end


-- 将宏条件字符串转为BooleanCond格式
---@param str string
---@return BooleanCond
function Macro:AstStringToBooleanCond(str)
    str = U.String.Trim(str)
    local boolCond = {type="unkonw", isTarget=false, params=str} ---@type BooleanCond
    -- 目标是否存在：exists、noexists
    if str == "exists" then
        boolCond.type = "exists"
        boolCond.isTarget = true
        boolCond.params = true
        return boolCond
    end
    if str == "noexists" then
        boolCond.type = "exists"
        boolCond.isTarget = true
        boolCond.params = false
        return boolCond
    end
    -- 目标是否友善：help、harm
    if str == "help" then
        boolCond.type = "help"
        boolCond.isTarget = true
        boolCond.params = true
        return boolCond
    end
    if str == "harm" then
        boolCond.type = "help"
        boolCond.isTarget = true
        boolCond.params = false
        return boolCond
    end
    -- 目标是否死亡：dead、nodead
    if str == "dead" then
        boolCond.type = "dead"
        boolCond.isTarget = true
        boolCond.params = true
        return boolCond
    end
    if str == "nodead" then
        boolCond.type = "dead"
        boolCond.isTarget = true
        boolCond.params = false
        return boolCond
    end
    -- 目标是否在队伍中
    if str == "party" then
        boolCond.type = "party"
        boolCond.isTarget = true
        boolCond.params = true
        return boolCond
    end
    -- 目标是否在团队中
    if str == "raid" then
        boolCond.type = "raid"
        boolCond.isTarget = true
        boolCond.params = true
        return boolCond
    end
    -- 目标是否在载具中
    if str == "unithasvehicleui" then
        boolCond.type = "unithasvehicleui"
        boolCond.isTarget = true
        boolCond.params = true
        return boolCond
    end
    -- 玩家是否处在御龙术区域
    if str == "advflyable" then
        boolCond.type = "advflyable"
        boolCond.params = true
        return boolCond
    end
    -- 玩家是否可以退出载具
    if str == "canexitvehicle" then
        boolCond.type = "canexitvehicle"
        boolCond.params = true
        return boolCond
    end
    -- 玩家是否在引导法术，是否在引导法术：法术名称
    if str == "channeling" then
        boolCond.type = "channeling"
        boolCond.params = true
        return boolCond
    end
    if string.sub(str, 1, 11) == "channeling:" then
        str = string.sub(str, 12)
        str = U.String.Trim(str)
        boolCond.type = "channeling"
        boolCond.params = str
        return boolCond
    end
    -- 玩家是否在战斗中：combat、outcombat
    if str == "combat" then
        boolCond.type = "combat"
        boolCond.params = true
        return boolCond
    end
    if str == "outcombat" then
        boolCond.type = "combat"
        boolCond.params = false
        return boolCond
    end
    -- 玩家是否装备了某个槽位装备
    if string.sub(str, 1, 9) == "equipped:" then
        str = string.sub(str, 10)
        str = U.String.Trim(str)
        boolCond.type = "equipped"
        boolCond.params = str
        return boolCond
    end
    -- 玩家是否装备了某个装备（不要求指定槽位）
    if string.sub(str, 1, 5) == "worn:" then
        str = string.sub(str, 6)
        str = U.String.Trim(str)
        boolCond.type = "worn"
        boolCond.params = str
        return boolCond
    end
    -- 玩家是否可以飞行
    if str == "flyable" then
        boolCond.type = "flyable"
        boolCond.params = true
        return boolCond
    end
    -- 玩家是否在飞行
    if str == "flying" then
        boolCond.type = "flying"
        boolCond.params = true
        return boolCond
    end
    -- 玩家处在何种形态（德鲁伊）
    if string.sub(str, 1, 5) == "form:" then
        str = string.sub(str, 6)
        str = U.String.Trim(str)
        local forms = U.String.Split(str, "/")
        boolCond.type = "form"
        boolCond.params = forms
        return boolCond
    end
    -- 玩家处在何种姿态（盗贼、战士）
    if string.sub(str, 1, 7) == "stance:" then
        str = string.sub(str, 8)
        str = U.String.Trim(str)
        local stances = U.String.Split(str, "/")
        boolCond.type = "stance"
        boolCond.params = stances
        return boolCond
    end
    -- 玩家是否处在队伍中：group、group:party、group:raid
    if string == "group" then
        boolCond.type = "group"
        boolCond.params = true
        return boolCond
    end
    if string == "group:party" then
        boolCond.type = "group"
        boolCond.params = "party"
        return boolCond
    end
    if string == "group:raid" then
        boolCond.type = "group"
        boolCond.params = "raid"
        return boolCond
    end
    -- 玩家是否在屋内：indoors、outdoors
    if str == "indoors" then
        boolCond.type = "indoors"
        boolCond.params = true
        return boolCond
    end
    if str == "outdoors" then
        boolCond.type = "indoors"
        boolCond.params = false
        return boolCond
    end
    -- 玩家是否学习了某个技能
    if string.sub(str, 1, 6) == "known:" then
        str = string.sub(str, 7)
        str = U.String.Trim(str)
        boolCond.type = "known"
        boolCond.params = str
        return boolCond
    end
    -- 玩家是否在坐骑上
    if str == "mounted" then
        boolCond.type = "mounted"
        boolCond.params = true
        return boolCond
    end
    -- 玩家是否召唤了名称为pet的宠物（猎人、术士）
    -- 玩家是否召唤了类型为petFamily的宠物？
    if string.sub(str, 1, 4) == "pet:" then
        if string.sub(str, 1, 11) == "pet:family=" then
            str = string.sub(str, 12)
            str = U.String.Trim(str)
            boolCond.type = "petFamily"
            boolCond.params = str
        else
            str = string.sub(str, 5)
            str = U.String.Trim(str)
            boolCond.type = "pet"
            boolCond.params = str
        end
        return boolCond
    end
    -- 玩家是否在宠物战斗中
    if str == "petbattle" then
        boolCond.type = "petbattle"
        boolCond.params = true
        return boolCond
    end
    -- 玩家是否开启了pvp
    if str == "pvpcombat" then
        boolCond.type = "pvpcombat"
        boolCond.params = true
        return boolCond
    end
    -- 玩家是否存在休息区域
    if str == "resting" then
        boolCond.type = "resting"
        boolCond.params = true
        return boolCond
    end
    -- 玩家处在何种专精
    if string.sub(str, 1, 5) == "spec:" then
        str = string.sub(str, 6)
        str = U.String.Trim(str)
        local specs = U.String.Split(str, "/")
        boolCond.type = "spec"
        boolCond.params = specs
        return boolCond
    end
    -- 玩家是否处在潜行状态
    if str == "stealth" then
        boolCond.type = "stealth"
        boolCond.params = true
        return boolCond
    end
    -- 玩家是否处在游泳状态
    if str == "swimming" then
        boolCond.type = "swimming"
        boolCond.params = true
        return boolCond
    end
    -- 当mod处在何种情况下激活
    if string == "nomod" or string == "nomodifier" then
        boolCond.type = "mod"
        boolCond.params = "nomod"
        return boolCond
    end
    if string.sub(str, 1, 9) == "modifier:" then
        str = string.sub(str, 10)
        str = U.String.Trim(str)
        boolCond.type = "mod"
        boolCond.params = str
        return boolCond
    end
    if string.sub(str, 1, 4) == "mod:" then
        str = string.sub(str, 5)
        str = U.String.Trim(str)
        boolCond.type = "mod"
        boolCond.params = str
        return boolCond
    end
    return boolCond
end

-- 处理宏命名
---@param str string 宏命令
---@return string 返回处理后的宏命名
function Macro:AstCmd(str)
    if string.sub(str, 1, 1) == "/" then
        str = string.sub(str, 2)
    end
    -- 将cast替换成use
    if str == "cast" then
        str = "use"
    end
    return str
end

-- 处理宏参数
---@param cmd string 宏命令
---@param str string 宏参数
function Macro:AstParam(cmd, str)
    str = U.String.Trim(str)
    local param = {} ---@type MacroParam
    if cmd == "use" then
        if param.items == nil then
            param.items = {}
        end
        if string.sub(str, 1, 5) == "item:" then
            local itemID = string.sub(str, 6)
            local itemType = const.ITEM_TYPE.ITEM
        else
        end
    end
end

-- 测试宏功能
function Macro:Test()
    local macro = "#showtooltip 疾跑\n/cast [nomod] 疾跑\n/use [mod:alt, target=player] 佯攻"
    Macro:Ast(macro)
end