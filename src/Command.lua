local addonName, _ = ...  ---@type string, table

---@class HappyToolkit: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class ToolkitCore: AceModule
local ToolkitCore = addon:GetModule("ToolkitCore")

---@class HtFrame: AceModule
local HtFrame = addon:GetModule("HtFrame")

-- 注册命令：更新冷却计时
-- /sethappytoolkitguicooldown 1 1
SlashCmdList["SETHAPPYTOOLKITGUICOOLDOWN"] = function(msg)
    local barGroupIndex, barIndex, btnIndex = msg:match("(%d+) (%d+) (%d+)")
    barGroupIndex = tonumber(barGroupIndex)
    local barIdx = tonumber(barIndex)
    local btnIdx = tonumber(btnIndex)
    local eFrame = HtFrame.EFrames[barGroupIndex]
    if eFrame == nil then
        return
    end
    local bar = eFrame.Bars[barIdx]
    if bar == nil then
        return
    end
    local btn = bar.BarBtns[btnIdx]
    if btn == nil then
        return
    end
    local ticker
    ticker = C_Timer.NewTicker(0.5, function()
        if not UnitCastingInfo("player") and not UnitChannelInfo("player") then
            ticker:Cancel()
            eFrame:SetPoolCooldown(btn)
        end
    end)
end
SLASH_SETHAPPYTOOLKITGUICOOLDOWN1 = "/sethappytoolkitguicooldown"
