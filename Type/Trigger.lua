---@alias TriggerType  -- 触发器类型
--- | "self"
--- | "aura"

---@alias TriggerTarget  -- 触发器目标
--- | "player"
--- | "target"

---@alias AuraType -- 光环类型
--- | "buff"
--- | "defbuff"

---@alias CondOperator -- 触发器条件运算符
--- | "="
--- | "!="
--- | ">"
--- | ">="
--- | "<"
--- | "<="


---@alias CondExpr  --- 条件表达式
--- | "%cond.1"
--- | "%cond.1 and %cond.2"
--- | "%cond.1 or %cond.2"
--- | "%cond.1 and %cond.2 and %cond.3"
--- | "%cond.1 or %cond.2 or %cond.3"
--- | "(%cond.1 and %cond.2) or %cond.3"
--- | "(%cond.1 or %cond.2) and %cond.3"


---@alias EffectType
--- | "borderGlow"
--- | "btnHide"
--- | "btnDesaturate"