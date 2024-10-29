---@class EffectAttr  -- 满足触发器条件的效果

---@class BorderEeffectAttr: EffectAttr  -- 边框效果
---@field isEnable boolean | nil -- 是否启用
---@field width number | nil -- 边框大小
---@field glowType string | nil -- 边框发光类型

---@class EffectConfig
---@field type EffectType
---@field attr EffectAttr
