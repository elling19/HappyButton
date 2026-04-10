---@class TriggerConfine  -- 触发器限制

---@class TriggerCondition  -- 触发器条件

---@class TriggerConfig
---@field id string
---@field type TriggerType -- 触发器类型
---@field confine TriggerConfine  -- 触发器限制


---------------------------------------------
--- 自身触发器配置
---------------------------------------------
---@class SelfTriggerConfine: TriggerConfine
---@class SelfTriggerConfig: TriggerConfig
---@field id string
---@field type TriggerType
---@field confine SelfTriggerConfine

---------------------------------------------
--- 物品触发器
---------------------------------------------
---@class ItemTriggerConfine: TriggerConfine
---@field item ItemAttr  -- 选择物品


---@class ItemTriggerConfig: TriggerConfig
---@field id string
---@field type TriggerType
---@field confine ItemTriggerConfine