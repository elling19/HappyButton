---@alias SpellName string
---@alias SpellID number

---@meta _
---@class DurationObject
---@field startTime number
---@field duration number
---@field isEnabled boolean
---@field enable boolean
---@field modRate number
DurationObject = {}

---@class CooldownInfo
---@field startTime number
---@field duration number
---@field enable boolean
---@field isEnabled boolean
---@field modRate number
CooldownInfo = {}

---@alias SpellCooldownDuration DurationObject
---@alias NonSpellCooldownInfo CooldownInfo
---@alias ItemCooldownValue SpellCooldownDuration | NonSpellCooldownInfo