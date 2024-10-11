local _, HT = ...
HT.AceAddonName = "HappyToolkit"
HT.AceAddonConfigDB = "HappyToolkitDB"
HT.AceAddon = LibStub("AceAddon-3.0"):NewAddon(HT.AceAddonName, "AceConsole-3.0", "AceEvent-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- 添加物品类型选项
local itemTypeOptions = {
    ITEM="Item",
    TOY="Toy",
    SPELL="Spell",
    PET="Pet",
    MOUNT="Mount",
    SCRIPT="Script",
}
local selectedCategoryIndex = 1 -- 用于存储当前选择的分类索引
local selectedItemIndex = 1

local options = {
    name = "HappyToolkit Options",
    handler = HT.AceAddon,
    type = 'group',
    args = {
        general = {
            order=1,
            type = 'group',
            name = "General",
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
        categoryList = {
            order=2,
            type = 'group',
            name = "Category",
            args = {
                addCategory = {
                    order=2,
                    type = 'input',
                    name = "New Category",
                    width = "full",
                    desc = "Input category title to a new category",
                    set = function(info, val)
                        table.insert(HT.AceAddon.db.profile.categoryList, { title=val, icon=nil, itemList={} })
                        selectedCategoryIndex = #HT.AceAddon.db.profile.categoryList
                        HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].title = val
                    end,
                },
                selectCategory = {
                    order=4,
                    width = 1,
                    type = 'select',
                    name = "Edit Category",
                    desc = "Choose a category to edit",
                    values = function()
                        local categoryValues = {}
                        for i, category in ipairs(HT.AceAddon.db.profile.categoryList) do
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
                    hidden = function()
                        return #HT.AceAddon.db.profile.categoryList == 0
                    end,
                },
                deleteCategory = {
                    order=5,
                    width = 1,
                    type = 'execute',
                    name = "Delete",
                    func = function()
                        table.remove(HT.AceAddon.db.profile.categoryList, selectedCategoryIndex)
                        -- 更新下拉列表
                        selectedCategoryIndex = #HT.AceAddon.db.profile.categoryList
                    end,
                    hidden = function()
                        return #HT.AceAddon.db.profile.categoryList == 0
                    end,
                },
                editCategoryTitle = {
                    order=7,
                    type = 'input',
                    name = "Category Title:",
                    width = 1,
                    desc = "Edit the title of the selected category",
                    set = function(info, val)
                        HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].title = val
                    end,
                    get = function()
                        return HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].title
                    end,
                    hidden = function()
                        return #HT.AceAddon.db.profile.categoryList == 0
                    end,
                },
                editCategoryIcon = {
                    order=9,
                    type = 'input',
                    name = "Category Icon:",
                    width = 1,
                    desc = "Edit the icon path of the selected category",
                    set = function(info, val)
                        HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].icon = val
                    end,
                    get = function()
                        return HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].icon
                    end,
                    hidden = function()
                        return #HT.AceAddon.db.profile.categoryList == 0
                    end,
                },
                itemHeading = {
                    order = 11,
                    type = 'header',
                    name = "Item Management",
                    hidden = function()
                        return #HT.AceAddon.db.profile.categoryList == 0
                    end,
                },
                addItem = {
                    order=12,
                    type = 'input',
                    name = "New Item",
                    width = "full",
                    desc = "Input item title to a new item",
                    set = function(info, val)
                        table.insert(HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].itemList, { title=val })
                        selectedItemIndex = #HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].itemList
                    end,
                    hidden = function()
                        return #HT.AceAddon.db.profile.categoryList == 0
                    end,
                },
                selectItem = {
                    order=13,
                    type = 'select',
                    name = "",
                    desc = "Choose a item to edit",
                    width = 1,
                    values = function()
                        local itemValues = {}
                        for i, item in ipairs(HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].itemList) do
                            itemValues[i] = item.title
                        end
                        return itemValues
                    end,
                    set = function(info, val)
                        selectedItemIndex = val
                    end,
                    get = function()
                        return selectedItemIndex
                    end,
                    hidden = function()
                        return #HT.AceAddon.db.profile.categoryList == 0 or #HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].itemList == 0
                    end,
                },
                deleteItem = {
                    order=14,
                    type = 'execute',
                    name = "Delete",
                    func = function()
                        table.remove(HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].itemList, selectedItemIndex)
                        -- 更新下拉列表
                        selectedItemIndex = #HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].itemList
                    end,
                    width = 1,
                    hidden = function()
                        return #HT.AceAddon.db.profile.categoryList == 0 or #HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].itemList == 0
                    end,
                },
                editItemType = {
                    order=15,
                    type = 'select',
                    name = "Item Type",
                    values = itemTypeOptions,
                    set = function(info, val) HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].itemList[selectedItemIndex].itemType = val end,
                    get = function(info)
                        if #HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].itemList == 0 then
                            return nil
                        else
                            return HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].itemList[selectedItemIndex].itemType
                        end
                    end,
                    hidden = function()
                        if #HT.AceAddon.db.profile.categoryList == 0 or #HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].itemList == 0 then
                            return true
                        end
                        return false
                    end,
                },
                editItemId = {
                    order=16,
                    type = 'input',
                    name = "Item ID:",
                    width = "harf",
                    desc = "Edit the icon path of the selected item",
                    set = function(info, val)
                        HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].itemList[selectedItemIndex].itemID = val
                    end,
                    get = function()
                        if #HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].itemList == 0 then
                            return ""
                        else
                            return HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].itemList[selectedItemIndex].itemID
                        end
                    end,
                    hidden = function()
                        if #HT.AceAddon.db.profile.categoryList == 0 or #HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].itemList == 0 then
                            return true
                        end
                        if HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].itemList[selectedItemIndex].itemType == "SCRIPT" then
                            return true
                        end
                        return false
                    end,
                },
                editItemScript = {
                    type = 'input', -- 使用 input 类型以支持富文本输入
                    name = "Script:",
                    multiline = true, -- 允许多行输入
                    width = "full",
                    set = function(info, val)
                        -- 存储输入的脚本
                        HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].itemList[selectedItemIndex].script = val
                    end,
                    get = function()
                        return HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].itemList[selectedItemIndex].script
                    end,
                    hidden = function()
                        if #HT.AceAddon.db.profile.categoryList == 0 or #HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].itemList == 0 then
                            return true
                        end
                        return HT.AceAddon.db.profile.categoryList[selectedCategoryIndex].itemList[selectedItemIndex].itemType ~= "SCRIPT" -- 只有当选择为 SCRIPT 类型时显示
                    end,
                },
            },
        },
        itemGroupList = {
            order=2,
            type = 'group',
            name = "ItemGroup",
            args = {
            }
        }
    },
}

function HT.AceAddon:OnInitialize()
    -- 注册数据库，添加分类设置
    self.db = LibStub("AceDB-3.0"):New(HT.AceAddonConfigDB, { 
        profile = {
            enable = true, threshold = 50,
            windowPositionX = 500, -- 默认X位置
            windowPositionY = 500, -- 默认Y位置
            categoryList = {}, -- 默认分类
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