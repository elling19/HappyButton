
local _, HT = ...
local Config = {
}

-- 将目标和Config进行比较，填充缺失的属性
function Config.initial(target)
    if target == nil then
        target = Config
        return target
    end
    for k, v in pairs(Config) do
        if target[k] == nil then
            target[k] = v
        end
    end
    return target
end

HT.Config = Config

return Config
