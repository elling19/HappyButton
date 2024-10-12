local _, HT = ...

local ToolkitGUI = HT.ToolkitGUI
local ToolkitCore = HT.ToolkitCore


-- 注册命令：关闭gui
SlashCmdList["CLOSEHAPPYTOOLKITGUI"] = ToolkitGUI.HideWindow
SLASH_CLOSEHAPPYTOOLKITGUI1 = "/closehappytoolkitgui"


-- 注册命令：更新冷却计时
-- /sethappytoolkitguicooldown 1 1 1
SlashCmdList["SETHAPPYTOOLKITGUICOOLDOWN"] = function(msg)
    local cateIndex, poolIndex = msg:match("(%d+) (%d+)")
    local cateIdx = tonumber(cateIndex)
    local poolIdx = tonumber(poolIndex)
    local pool = ToolkitGUI.GetPoolByIndex(cateIdx, poolIdx)
    local ticker
    ticker = C_Timer.NewTicker(0.5, function()
        if not UnitCastingInfo("player") and not UnitChannelInfo("player") then
            ticker:Cancel()
            ToolkitGUI.SetPoolCooldown(pool)
        end
    end)
end
SLASH_SETHAPPYTOOLKITGUICOOLDOWN1 = "/sethappytoolkitguicooldown"


-- 注册命令：/click [nocombat] ToggleHappyToolkitGUIButton
local toggleHanppyToolkitGUIButton = CreateFrame("Button", "ToggleHappyToolkitGUIButton", UIParent, "SecureActionButtonTemplate")

toggleHanppyToolkitGUIButton:SetScript("OnClick", function()
    ToolkitCore.ToggleToolkitGUI()
end)

ToolkitCore.Start()


-- 全局变量、提供给按键绑定使用
G_HAPPY_TOOLKIT = {}

-- 按键绑定
function G_HAPPY_TOOLKIT.RunWishByKeyBinding()
    ToolkitCore.ToggleToolkitGUI()
end
