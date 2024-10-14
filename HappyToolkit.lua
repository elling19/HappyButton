local _, HT = ...

---@type ToolkitCore
local ToolkitCore = HT.ToolkitCore

ToolkitCore.Start()

-- 全局变量、提供给按键绑定使用
G_HAPPY_TOOLKIT = {}

-- 按键绑定
function G_HAPPY_TOOLKIT.RunWishByKeyBinding()
    ToolkitCore.ToggleToolkitGUI()
end
