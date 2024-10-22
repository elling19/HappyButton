local addonName, _ = ...  ---@type string, table

---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class CONST: AceModule
local const = addon:GetModule('CONST')

---@class BarCore: AceModule
local BarCore = addon:GetModule("BarCore")

---@class HbFrame: AceModule
local HbFrame = addon:GetModule("HbFrame")

-- 注册命令：关闭窗口
-- /closeEframe xxxxxx
SlashCmdList["SETCLOSEEFRAME"] = function(configId)
    local eFrame = HbFrame.EFrames[configId]
    if eFrame == nil then
        return
    end
    if eFrame:IsBarGroup() then
        eFrame:HideAllBarFrame()
    else
        if eFrame.Config.isDisplayMouseEnter then
            eFrame:SetBarTransparency()
        end
    end
end
SLASH_SETCLOSEEFRAME1 = "/SETCLOSEEFRAME"
