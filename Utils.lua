local _, HT = ...

local Utils = {}

HT.Utils = Utils

-- 检查表中是否包含某个元素
function Utils.Contains(table, element)
    for _, value in ipairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- 检查目标是否在数组中
function Utils.IsInArray(target, array)
    for _, value in ipairs(array) do
        if value == target then
            return true
        end
    end
    return false
end


-- 修改全局打印方法，在打印信息前加上插件名称
function Utils.print(...) _G.print("|cfffff700H|r|cffeeaf7ap|r|cffe38483p|r|cffd966a6y|r|cffc84dcaT|r|cffb539e6o|r|cff9f2bffo|r|cffa636f3l|r|cffbb4ed2k|r|cffe38280i|r|cffffad75t|r" .. "|cfffff700:|r", ...) end

-- 打印彩色字体
function Utils.PrintColoredText(text, color)
    local coloredText = "|c" .. color .. text .. "|r"
    Utils.print(coloredText)
end

-- 打印成功
function Utils.PrintSuccessText(text)
    local coloredText = "|cff00ff00" .. text .. "|r"
    Utils.print(coloredText)
end

-- 打印错误
function Utils.PrintErrorText(text)
    local coloredText = "|cffff0000" .. text .. "|r"
    Utils.print(coloredText)
end

-- 打印警告
function Utils.PrintWarnText(text)
    local coloredText = "|cffffd700" .. text .. "|r"
    Utils.print(coloredText)
end

-- 打印信息
function Utils.PrintInfoText(text)
    Utils.print(text)
end

-- 调试打印对象
function Utils.PrintTable(tbl, indent)
    -- 如果没有提供缩进级别，则初始化为2
    indent = indent or 2
    -- 遍历表
    if tbl == nil then
        Utils.print(nil)
        return
    end
    for key, value in pairs(tbl) do
        -- 创建缩进字符串
        local formatting = string.rep("  ", indent) .. tostring(key) .. ": "

        if type(value) == "table" then
            -- 如果值是一个表，则递归调用 printTable
            Utils.print(formatting .. "{")
            Utils.PrintTable(value, indent + 1)
            Utils.print(string.rep("  ", indent) .. "}")
        else
            -- 否则，打印键和值
            Utils.print(formatting .. tostring(value))
        end
    end
end



return Utils

