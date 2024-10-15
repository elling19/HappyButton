local _, HT = ...

---@class UtilsTable
---@field Contains fun(table: table, element: any): boolean
---@field IsInArray fun(array: table, element: any): boolean
---@field DeepCopy fun(original: table): table
local UtilsTable = {}

---@class UtilsPrint
---@field Print fun(...): nil
---@field PrintColoredText fun(text: any, color: string): nil
---@field PrintSuccessText fun(text: any): nil
---@field PrintErrorText fun(text: any): nil
---@field PrintWarnText fun(text: any): nil
---@field PrintInfoText fun(text: any): nil
---@field PrintTable fun(table: table, indent: number | nil): nil
local UtilsPrint = {}

---@class UtilsString
---@field ToVertical fun(text: string | nil): string 将字符串转为竖形结构
local UtilsString = {}

---@class Utils
---@field Table UtilsTable
---@field Print UtilsPrint
---@field String UtilsString
local Utils = {
    Table = UtilsTable,
    Print = UtilsPrint,
    String = UtilsString
}

HT.Utils = Utils

-- 检查表中是否包含某个元素
function UtilsTable.Contains(table, element)
    for _, value in ipairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- 检查目标是否在数组中
function UtilsTable.IsInArray(array, target)
    for _, value in ipairs(array) do
        if value == target then
            return true
        end
    end
    return false
end

-- 深度复制table
function UtilsTable.DeepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == 'table' then
            copy[k] = UtilsTable.DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end


-- 修改全局打印方法，在打印信息前加上插件名称
function UtilsPrint.Print(...) _G.print("|cfffff700H|r|cffeeaf7aa|r|cffe38483pp|r|cffd966a6y|r|cffc84dcaT|r|cffb539e6o|r|cff9f2bffo|r|cffa636f3l|r|cffbb4ed2k|r|cffe38280i|r|cffffad75t|r" .. "|cfffff700:|r", ...) end

-- 打印彩色字体
function UtilsPrint.PrintColoredText(text, color)
    local coloredText = "|c" .. color .. text .. "|r"
    UtilsPrint.Print(coloredText)
end

-- 打印成功
function UtilsPrint.PrintSuccessText(text)
    local coloredText = "|cff00ff00" .. text .. "|r"
    UtilsPrint.Print(coloredText)
end

-- 打印错误
function UtilsPrint.PrintErrorText(text)
    local coloredText = "|cffff0000" .. text .. "|r"
    UtilsPrint.Print(coloredText)
end

-- 打印警告
function UtilsPrint.PrintWarnText(text)
    local coloredText = "|cffffd700" .. text .. "|r"
    UtilsPrint.Print(coloredText)
end

-- 打印信息
function UtilsPrint.PrintInfoText(text)
    UtilsPrint.Print(text)
end

-- 调试打印对象
function UtilsPrint.PrintTable(tbl, indent)
    -- 如果没有提供缩进级别，则初始化为2
    indent = indent or 2
    -- 遍历表
    if tbl == nil then
        UtilsPrint.Print(nil)
        return
    end
    for key, value in pairs(tbl) do
        -- 创建缩进字符串
        local formatting = string.rep("  ", indent) .. tostring(key) .. ": "

        if type(value) == "table" then
            -- 如果值是一个表，则递归调用 printTable
            UtilsPrint.Print(formatting .. "{")
            UtilsPrint.PrintTable(value, indent + 1)
            UtilsPrint.Print(string.rep("  ", indent) .. "}")
        else
            -- 否则，打印键和值
            UtilsPrint.Print(formatting .. tostring(value))
        end
    end
end


-- 函数：将 UTF-8 字符串拆分为单个字符表
local function Utf8ToTable(str)
    local charTable = {}
    local i = 1
    local length = #str

    while i <= length do
        local byte = string.byte(str, i)
        local charLength

        if byte >= 240 then       -- 4字节字符 (例如 emoji)
            charLength = 4
        elseif byte >= 224 then   -- 3字节字符 (中文、韩文等)
            charLength = 3
        elseif byte >= 192 then   -- 2字节字符 (部分拉丁字母等)
            charLength = 2
        else                      -- 1字节字符 (ASCII)
            charLength = 1
        end

        local char = str:sub(i, i + charLength - 1)
        table.insert(charTable, char)
        i = i + charLength
    end

    return charTable
end


function UtilsString.ToVertical(str)
    if str == nil then
        return ""
    end
    local chars = Utf8ToTable(str)
    local verticalStr = ""
    for _, char in ipairs(chars) do
        verticalStr = verticalStr .. char .. "\n"
    end
    return verticalStr
end