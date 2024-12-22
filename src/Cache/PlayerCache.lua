local addonName, _ = ...


---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class Api: AceModule
local Api = addon:GetModule("Api")

---@class Client: AceModule
local Client = addon:GetModule("Client")


---@class PlayerCache: AceModule
---@field className string 本地名称，例如：战士
---@field classFileName string 英文大写，例如 DEMONHUNTER
---@field classId Class 职业编号
---@field gcdSpellId SpellID 玩家的gcd技能编号
local PlayerCache = addon:NewModule("PlayerCache")


function PlayerCache:Initial()
    local className, classFileName, classID = UnitClass("player")
    PlayerCache.className = className
    PlayerCache.classFileName = classFileName
    PlayerCache.classId = classID
    if Client:IsEra() then
        -- 怀旧服没有明确的gcd技能编号
        if PlayerCache.classId == const.CLASS.MAGE then
            PlayerCache.gcdSpellId = 168 -- 霜甲术
        else
            PlayerCache.gcdSpellId = 168
        end
    else
        PlayerCache.gcdSpellId = 61304  -- https://wowpedia.fandom.com/wiki/API_GetSpellCooldown
    end
end