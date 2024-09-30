local _, HT = ...

Result = {_value = nil, _error = nil}
Result.__index = Result

-- 定义 Result 的 Ok 构造函数
function Result:Ok(value)
    local obj = {}
    setmetatable(obj, Result)
    obj._value = value
    return obj
end

-- 定义 Result 的 Err 构造函数
function Result:Err(err)
    local obj = {}
    setmetatable(obj, Result)
    if err == nil then
        error("err must not be nil.")
    end
    obj._error = err
    return obj
end

function Result:is_ok()
    return self._error == nil
end

function Result:is_err()
    return not self._error == nil
end

-- 定义方法来处理 Result
function Result:unwrap()
    if self:is_ok() then
        return self._value
    else
        error("Called unwrap on an Err: " .. tostring(self._error))
    end
end

function Result:unwrap_or(default)
    if self:is_ok() then
        return self._value
    else
        return default
    end
end

function Result:unwrap_err()
    if not self:is_ok() then
        return self._error
    else
        error("Called unwrap_err on an Ok: " .. tostring(self._value))
    end
end

HT.Result = Result

return Result
