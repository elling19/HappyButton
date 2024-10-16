local addonName, _ = ...  ---@type string, table

---@class HappyToolkit: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class BaseFrame: AceModule
local BaseFrame = addon:GetModule('BaseFrame')

---@class MainFrame: AceModule
local MainFrame = addon:GetModule("MainFrame")

---@class MainFrame: AceModule
local AloneBarsFrame = addon:GetModule("AloneBarsFrame")

---@class ToolkitCore: AceModule
local ToolkitCore = addon:GetModule("ToolkitCore")

-- 注册命令：关闭gui
SlashCmdList["CLOSEHTITMAINFRAME"] = function ()
    MainFrame:HideAllIconFrame()
end
SLASH_CLOSEHTITMAINFRAME1 = "/closehtmainframe"

-- 注册命令：更新冷却计时
-- /sethappytoolkitguicooldown 1 1
SlashCmdList["SETHAPPYTOOLKITGUICOOLDOWN"] = function(msg)
    local barDisplayMode, barIndex, buttonIndex = msg:match("(%d+) (%d+) (%d+)")
    barDisplayMode = tonumber(barDisplayMode)
    local barIdx = tonumber(barIndex)
    local buttonIdx = tonumber(buttonIndex)
    local button
    if barDisplayMode == const.BAR_DISPLAY_MODE.Mount then
        button = MainFrame:GetButtonByIndex(barIdx, buttonIdx)
    end
    if barDisplayMode == const.BAR_DISPLAY_MODE.Alone then
        button = AloneBarsFrame:GetButtonByIndex(barIdx, buttonIdx)
    end
    if button == nil then
        return
    end
    local ticker
    ticker = C_Timer.NewTicker(0.5, function()
        if not UnitCastingInfo("player") and not UnitChannelInfo("player") then
            ticker:Cancel()
            BaseFrame:SetPoolCooldown(button)
        end
    end)
end
SLASH_SETHAPPYTOOLKITGUICOOLDOWN1 = "/sethappytoolkitguicooldown"


-- 注册命令：/click [nocombat] ToggleHtMainFrame
local toggleMainFrameButton = CreateFrame("Button", "ToggleHtMainFrame", UIParent, "SecureActionButtonTemplate")

toggleMainFrameButton:SetScript("OnClick", function()
    ToolkitCore:ToggleMainFrame()
end)
