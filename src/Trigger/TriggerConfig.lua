---@class TriggerConfine  -- 触发器限制

---@class TriggerCondition  -- 触发器条件

---@class TriggerConfig
---@field id string
---@field type TriggerType -- 触发器类型
---@field confine TriggerConfine  -- 触发器限制
---@field condition TriggerCondition  -- 触发器条件


--[[
自身触发器配置
]]
---@class SelfTriggerConfine: TriggerConfine

---@class SelfTriggerCondition: TriggerCondition
---@field count number | nil 物品数量/技能充能（nil表示不判断）
---@field isLearned boolean | nil 是否学习技能/拥有物品

---@class SelfTriggerConfig: TriggerConfig
---@field id string
---@field type TriggerType
---@field confine SelfTriggerConfine
---@field condition SelfTriggerCondition


--[[
光环触发器配置
]]
---@class AuraTriggerConfine: TriggerConfine
---@field target TriggerTarget
---@field type AuraType
---@field spellId number | nil  -- 光环ID


---@class AuraTriggerCondition: TriggerCondition
---@field remainingTime number | nil -- 剩余时间


---@class AuraTriggerConfig: TriggerConfig
---@field id string
---@field type TriggerType
---@field confine AuraTriggerConfine
---@field condition AuraTriggerCondition