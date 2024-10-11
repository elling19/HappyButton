local _, HT = ...
HT.AceAddonName = "HappyToolkit"
HT.AceAddonConfigDB = "HappyToolkitDB"
HT.AceAddon = LibStub("AceAddon-3.0"):NewAddon(HT.AceAddonName, "AceConsole-3.0", "AceEvent-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- 准备分类的默认数据库结构
local defaultCategories = {
    { title = "Category 1", icon = "Interface\\Icons\\INV_Misc_QuestionMark" },
    { title = "Category 2", icon = "Interface\\Icons\\INV_Misc_QuestionMark" },
}

local selectedCategoryIndex = 1 -- 用于存储当前选择的分类索引

local options = {
    name = "HappyToolkit Options",
    handler = HT.AceAddon,
    type = 'group',
    args = {
        general = {
            order=1,
            type = 'group',
            name = "General Settings",
            args = {
                enable = {
                    type = 'toggle',
                    name = "Enable",
                    desc = "Enable or disable the addon",
                    set = function(info, val) HT.AceAddon.db.profile.enable = val end,
                    get = function(info) return HT.AceAddon.db.profile.enable end,
                },
                threshold = {
                    type = 'range',
                    name = "Threshold",
                    desc = "Set the threshold value",
                    min = 0,
                    max = 100,
                    step = 1,
                    set = function(info, val) HT.AceAddon.db.profile.threshold = val end,
                    get = function(info) return HT.AceAddon.db.profile.threshold end,
                },
                -- 设置窗口位置：x 和 y 值
                windowPositionX = {
                    type = 'range',
                    name = "Window Position X",
                    desc = "Set the X position of the window",
                    min = 0,
                    max = 1920,
                    step = 1,
                    set = function(info, val) HT.AceAddon.db.profile.windowPositionX = val end,
                    get = function(info) return HT.AceAddon.db.profile.windowPositionX end,
                },
                windowPositionY = {
                    type = 'range',
                    name = "Window Position Y",
                    desc = "Set the Y position of the window",
                    min = 0,
                    max = 1080,
                    step = 1,
                    set = function(info, val) HT.AceAddon.db.profile.windowPositionY = val end,
                    get = function(info) return HT.AceAddon.db.profile.windowPositionY end,
                },
            },
        },
        categories = {
            order=2,
            type = 'group',
            name = "Categories Settings",
            args = {
                addCategory = {
                    order=2,
                    type = 'execute',
                    name = "Add New Category",
                    func = function()
                        -- 检查是否输入了标题和图标
                        local title = "New Category"
                        local icon = "Interface\\Icons\\INV_Misc_QuestionMark"
                        -- 将新的分类添加到数据库中
                        table.insert(HT.AceAddon.db.profile.categories, { title = title, icon = icon })
                        -- 获取刚添加的分类索引
                        selectedCategoryIndex = #HT.AceAddon.db.profile.categories
                    end,
                    width = "double",
                },
                 -- 在这里添加一个heading，显示在Add Category按钮下方
                heading = {
                    order = 3,
                    type = 'header',
                    name = "Category Management",
                },
                selectCategory = {
                    order=4,
                    type = 'select',
                    name = "",
                    desc = "Choose a category to edit",
                    width = 1,
                    values = function()
                        local categoryValues = {}
                        for i, category in ipairs(HT.AceAddon.db.profile.categories) do
                            categoryValues[i] = category.title
                        end
                        return categoryValues
                    end,
                    set = function(info, val)
                        selectedCategoryIndex = val
                    end,
                    get = function()
                        return selectedCategoryIndex
                    end,
                },
                deleteCategory = {
                    order=5,
                    type = 'execute',
                    name = "Delete",
                    func = function()
                        table.remove(HT.AceAddon.db.profile.categories, selectedCategoryIndex)
                        -- 更新下拉列表
                        selectedCategoryIndex = #HT.AceAddon.db.profile.categories
                    end,
                    width = 1,
                },
                editTitle = {
                    order=7,
                    type = 'input',
                    name = "Category Title:",
                    width = "harf",
                    desc = "Edit the title of the selected category",
                    set = function(info, val)
                        HT.AceAddon.db.profile.categories[selectedCategoryIndex].title = val
                    end,
                    get = function()
                        return HT.AceAddon.db.profile.categories[selectedCategoryIndex].title
                    end,
                },
                editIcon = {
                    order=9,
                    type = 'input',
                    name = "Category Icon:",
                    width = "harf",
                    desc = "Edit the icon path of the selected category",
                    set = function(info, val)
                        HT.AceAddon.db.profile.categories[selectedCategoryIndex].icon = val
                    end,
                    get = function()
                        return HT.AceAddon.db.profile.categories[selectedCategoryIndex].icon
                    end,
                },
            },
        },
    },
}

function HT.AceAddon:OnInitialize()
    -- 注册数据库，添加分类设置
    self.db = LibStub("AceDB-3.0"):New(HT.AceAddonConfigDB, { 
        profile = {
            enable = true, threshold = 50,
            windowPositionX = 500, -- 默认X位置
            windowPositionY = 500, -- 默认Y位置
            categories = defaultCategories, -- 默认分类
        }
    }, true)

    -- 注册选项表
    AceConfig:RegisterOptionsTable(HT.AceAddonName, options)
    -- 在Blizzard界面选项中添加一个子选项
    self.optionsFrame = AceConfigDialog:AddToBlizOptions(HT.AceAddonName, HT.AceAddonName)
    -- 输入 /HappyToolkit 打开配置
    self:RegisterChatCommand(HT.AceAddonName, "OpenConfig")
end

function HT.AceAddon:OpenConfig()
    AceConfigDialog:Open(HT.AceAddonName)
end


















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


-- 全局变量、提供给外部插件、按键绑定使用
G_HAPPY_TOOLKIT = {}

-- 按键绑定
function G_HAPPY_TOOLKIT.RunWishByKeyBinding()
    ToolkitCore.ToggleToolkitGUI()
end


-- -- 支持外部插件注册
-- function G_HAPPY_TOOLKIT.Register(cate, callback)
--     ToolkitCore.Register(cate, callback)
-- end


-- local optionsFrame
-- ---@class optionsFrame : Frame
-- optionsFrame = CreateFrame("Frame", nil, nil, "VerticalLayoutFrame")
-- optionsFrame.spacing = 4
-- local category, layout = Settings.RegisterCanvasLayoutCategory(optionsFrame, "|cfffff700H|r|cffeeaf7aa|r|cffe38483pp|r|cffd966a6y|r|cffc84dcaT|r|cffb539e6o|r|cff9f2bffo|r|cffa636f3l|r|cffbb4ed2k|r|cffe38280i|r|cffffad75t|r");
-- category.ID = "HappyToolkit"
-- Settings.RegisterAddOnCategory(category)