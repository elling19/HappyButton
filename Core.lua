local _, HT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("HappyToolkit", false)

local Config = HT.Config
local U = HT.Utils
local ToolkitGUI = HT.ToolkitGUI
local ToolkitPool = HT.ToolkitPool

local ToolkitCore = {
    Frame = CreateFrame("Frame"),
}

-- 初始化配置
function ToolkitCore.Initial()
    -- 初始化SavedVariables配置信息
    ConfigDB = nil
    ConfigDB = Config.initial(ConfigDB)
    ToolkitGUI.Initial()
end


function ToolkitCore.Register(cate, callback)
    if type(callback) == "function" then
        local hasCate = false
        local cateIndex = nil
        for index, catePool in ipairs(ToolkitPool) do
            if catePool.cate == cate then
                hasCate = true
                cateIndex = index
                break
            end
        end
        if hasCate == false then
            U.PrintErrorText("Can not register toolkit, wrong category.")
        else
            table.insert(ToolkitPool[cateIndex].cbPool, callback) -- {callback=callback, execButton=nil, showButton=nil, text=nil}
        end
    else
        U.PrintErrorText(L["Can not register toolkit: must be a callback function."])
    end
end


-- 切换GUI显示状态
function ToolkitCore.ToggleToolkitGUI()
    if ToolkitGUI.IsOpen == false then
        if not InCombatLockdown() then
            ToolkitGUI.ShowWindow()
        else
            U.PrintInfoText(L["You cannot use this in combat."])
        end
    else
        ToolkitGUI.HideWindow()
    end
end

-- 注册事件
function ToolkitCore.Start()
    -- 注册相关事件以立即更新宏（如玩家登录或冷却更新）
    ToolkitCore.Frame:RegisterEvent("ADDON_LOADED")  -- 插件加载
    ToolkitCore.Frame:RegisterEvent("PLAYER_LOGIN")  -- 登录
    ToolkitCore.Frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")  -- 触发冷却
    ToolkitCore.Frame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- 进入战斗事件
    ToolkitCore.Frame:SetScript("OnEvent", function(self, event, arg1)
        if event == "PLAYER_LOGIN" then
            ToolkitCore.Initial()
        end
        if event == "ADDON_LOADED" and arg1 == "HappyToolkit" then
        end
        if event == "SPELL_UPDATE_COOLDOWN" then
        end
        if event == "PLAYER_REGEN_DISABLED" then
            ToolkitGUI.HideWindow()
        end
    end)
end

HT.ToolkitCore = ToolkitCore

return ToolkitCore