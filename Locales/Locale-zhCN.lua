local L = LibStub("AceLocale-3.0"):NewLocale("HappyButton", "zhCN")
if not L then return end

L["Version"] = "版本"
L["Welcome to use HappyButton."] = "欢迎使用插件HappyButton。"
L["Can not register Bar: must be a callback function."] = "无法注册：必须是回调函数。"
L["You cannot use this in combat."] = "你无法在战斗中使用。"
L["Settings"] = "设置"
L["Teleport"] = "传送"
L["Class"] = "职业"
L["Profession"] = "专业"
L["Mail"] = "邮箱"
L["Bank"] = "银行"
L["Merchant"] = "商人"
L["Others"] = "其他"
L["Yes"] = "是"
L["No"] = "否"
L["Please copy the configuration to the clipboard."] = "请将配置项复制到剪贴板。"
L["Items Bar"] = "物品条"
L["Default"] = "默认"
L["Title"] = "标题"
L["Icon"] = "图标"
L["New"] = "新建"
L["Delete"] = "删除"
L["Mode"] = "模式"
L["Select items to display"] = "选择展示项"
L["Macro"] = "宏"
L["Export"] = "导出"
L["Import Configuration"] = "导入配置"
L["Configuration string"] = "配置字符串"
L["Whether to overwrite the existing configuration."] = "覆盖旧配置"
L["Whether to import keybind settings."] = "导入按键设置"
L["Import failed: Invalid configuration string."] = "导入失败：非法配置字符串"
L["Whether to display only learned or owned items."] = "只展示已经学习或者拥有的物品。"
L["Wheter to use element title to replace item name."] = "使用元素标题替代物品名称。"
L["Add Item"] = "添加物品"
L["Item Type"] = "物品类型"
L["Alias"] = "别名"
L["Item name or item id"] = "物品名称或物品ID"
L["Please select item type."] = "请选择物品类型。"
L["Unable to get the id, please check the input."] = "无法获取物品ID，请检查输入项。"
L["Unable to get the name, please check the input."] = "无法获取物品名称，请检查输入项。"
L["Unable to get the icon, please check the input."] = "无法获取物品图标，请检查输入项。"
L["ID"] = "ID"
L["Name"] = "名称"
L["Type"] = "类型"
L["Configuration String Edit Box"] = "配置字符串编辑框"
L["Import/Export Configuration"] = "导入/导出配置"
L["General Settings"] = "基本设置"
L["Window Position X"] = "X轴位置"
L["Window Position Y"] = "Y轴位置"
L["Display one item, randomly selected."] = "展示随机选择的一项。"
L["Display one item, selected sequentially."] = "展示顺序选择的一项。"
L["Item"] = "物品"
L["Equipment"] = "装备"
L["Toy"] = "玩具"
L["Spell"] = "技能"
L["Mount"] = "坐骑"
L["Pet"] = "宠物"
L["Display"] = "显示"
L["ITEM_GROUP"] = "物品组"
L["Whether to display text."] = "显示文字。"
L["Illegal value."] = "输入内容错误。"
L["Whether to display item name."] = "展示物品名称。"
L["Whether to show the bar menu when the mouse enter."] = "鼠标移入后显示界面。"
L["Illegal script."] = "脚本错误。"
L["Hidden"] = "隐藏"
L["Display as alone items bar"] = "作为独立物品条显示。"
L["Append to the main frame"] = "挂载在主框体上。"
L["Toggle Edit Mode"] = "切换编辑模式"
L["Main frame"] = "主窗口"
L["Left-click to drag and move, right-click to exit edit mode."] = "左键拖拽移动位置，右键点击关闭编辑模式。"
L["Element Settings"]  = "元素设置"
L["Bar"] = "物品条"
L["ItemGroup"] = "物品组"
L["Script"] = "脚本"
L["New Bar"] = "创建物品条"
L["New ItemGroup"] = "创建物品组"
L["New Item"] = "创建物品"
L["New Script"] = "创建脚本"
L["New Macro"] = "创建宏"
L["Select type"] = "选择类型"
L["Element Title"] = "元素标题"
L["Element Icon ID or Path"] = "元素图标ID或路径"
L["Grid Layout"] = "平铺式"
L["Drawer Layout"] = "抽屉式"
L["Direction of elements growth"] = "子元素生长方向"
L["Horizontal"] = "水平方向"
L["Vertical"] = "垂直方向"
L["Icon Width"] = "图标宽度"
L["Icon Height"] = "图标高度"
L["Display Rule"] = "展示规则"
L["Load"] = "启用"
L["Load Rule"] = "载入规则"
L["Add Child Elements"] = "添加子元素"
L["Edit Child Elements"] = "编辑子元素"
L["Select Item"] = "选择物品"

-- 宏设置
L["Macro Statement Settings"] = "宏设置"
L["Temporary Targeting"] = "临时目标"
L["Boolean Conditions"] = "布尔条件"

-- 位置
L["TOPLEFT"] = "上左"
L["TOPRIGHT"] = "上右"
L["BOTTOMLEFT"] = "下左"
L["BOTTOMRIGHT"] = "下右"
L["LEFTTOP"] = "左上"
L["LEFTBOTTOM"] = "左下"
L["RIGHTTOP"] = "右上"
L["RIGHTBOTTOM"] = "右下"
L["TOP"] = "上"
L["BOTTOM"] = "下"
L["LEFT"] = "左"
L["RIGHT"] = "右"
L["CENTER"] = "中"
L["Relative X-Offset"] = "相对 X 偏移"
L["Relative Y-Offset"] = "相对 Y 偏移"
-- 依附框体
L["UIParent"] = "主屏幕"
L["GameMenuFrame"] = "游戏菜单"
L["Minimap"] = "小地图"
L["ProfessionsBookFrame"] = "专业"
L["WorldMapFrame"] = "世界地图"
L["CollectionsJournal"] = "收集箱"
L["PVEFrame"] = "地下城和团队副本"


L["Combat Load Condition"] = "战斗状态加载条件"
L["Load when out of combat"] = "战斗外加载"
L["Load when in combat"] = "战斗中加载"

L["Position Settings"] = "位置设置"
L["Element Anchor Position"] = "元素锚点"
L["AttachFrame"] = "依附框体"
L["AttachFrame Anchor Position"] = "依附框体锚点"

L["Text Settings"] = "文本设置"
L["Use root element settings"] = "使用根元素的设置"
L["Item Name"] = "物品名称"
L["Item Count"] = "物品数量"
L["Add Text"] = "添加文本"
L["Select Text"] = "选择文本"

L["Trigger"] = "触发器"
L["Trigger Settings"] = "触发器设置"
L["New Trigger"] = "添加触发器"
L["Trigger Title"] = "触发器标题"
L["Select Trigger"] = "选择触发器"
L["Select Target"] = "选择目标"
L["Select Trigger Type"] = "选择触发器类型"

L["Self Trigger"] = "自身触发器"
L["Count/Charge"] = "数量/充能"
L["Is Learned"] = "已学会"
L["Is Cooldown"] = "冷却完毕"

L["Aura Trigger"] = "光环触发器"
L["Aura ID"] = "光环ID"
L["Aura Remaining Time"] = "光环剩余时间"
L["Select Aura Type"] = "选择光环类型"
L["Player"] = "玩家"
L["Target"] = "目标"
L["Buff"] = "增益"
L["Debuff"] = "减益"

L["Item Trigger"] = "物品触发器"
L["Select Item"] = "选择物品"

L["Condition Group Settings"] = "条件组设置"
L["Condition Settings"] = "条件设置"
L["Condition Group"] = "条件组"
L["Condition"] = "条件"
L["New Condition Group"] = "添加条件组"
L["New Condition"] = "添加条件"
L["No Trigger"] = "不使用触发器"
L["Left Value Settings"] = "左值设置"
L["Operate"] = "运算符"
L["Right Value Settings"] = "右值设置"
L["True"] = "真"
L["False"] = "假"
L["Expression Settings"] = "表达式设置"
L["Effect Settings"] = "效果设置"

-- 触发器表达式
L["Cond1"] = "条件1"
L["Cond1 and Cond2"] = "条件1 且 条件2"
L["Cond1 or Cond2"] = "条件1 或 条件2"
L["Cond1 and Cond2 and Cond3"] = "条件1 且 条件2 且 条件3"
L["Cond1 or Cond2 or Cond3"] = "条件1 或 条件2 或 条件3"
L["(Cond1 and Cond2) or Cond3"] = "(条件1 且 条件2) 或 条件3"
L["(Cond1 or Cond2) and Cond3"] = "(条件1 或 条件2) 且 条件3"


-- 触发器条件列表
L["count"] = "数量"
L["isLearned"] = "已学会"
L["isUsable"] = "可用"
L["isCooldown"] = "冷却完毕"
L["remainingTime"] = "剩余时间"
L["targetIsEnemy"] = "目标是否敌对"
L["targetCanAttack"] = "目标是否可攻击"
L["exist"] = "存在"

-- 触发器效果
L["Border Glow"] = "边框发光"
L["Btn Hide"] = "按钮隐藏"
L["Btn Desaturate"] = "按钮褪色"
L["Btn Vertex Red Color"] = "顶点红色"
L["Btn Alpha"] = "按钮半透明"

L["Open"] = "开启"
L["Close"] = "关闭"

L["Move Up"] = "上移"
L["Move Down"] = "下移"
L["Move Top Level"] = "移到顶层"
L["Move Down Level"] = "移到下层"

-- 事件监听设置
L["Event Settings"] = "事件监听设置"
L["Enable Event Listening"] = "开启事件监听"

-- 职业
L["Enable Class Settings"] = "开启职业设置"
L["Warrior"] = "战士"
L["Paladin"] = "圣骑士"
L["Hunter"] = "猎人"
L["Rogue"] = "潜行者"
L["Priest"] = "牧师"
L["Death Knight"] = "死亡骑士"
L["Shaman"] = "萨满"
L["Mage"] = "法师"
L["Warlock"] = "术士"
L["Monk"] = "武僧"
L["Druid"] = "德鲁伊"
L["Demon Hunter"] = "恶魔猎手"
L["Evoker"] = "唤魔师"

-- 按键绑定设置
L["Bindkey Settings"] = "绑定按键设置"
L["Bindkey"] = "绑定按键"
L["Bind For Account"] = "为所有角色绑定"
L["Bind For Current Character"] = "为当前角色绑定"
L["Bind For Current Class"] = "为当前职业绑定"

-- 宏错误提示
L["Macro Error"] = "宏错误"
L["Macro Error: Invalid equipment slot: %s"] = "宏错误：无效的装备编号：%s"
L["Macro Error: Can not find this identifier: %s"] = "宏错误：无法获取此物品：%s"