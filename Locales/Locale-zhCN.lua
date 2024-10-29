local L = LibStub("AceLocale-3.0"):NewLocale("HappyButton", "zhCN")
if not L then return end

L["Version"] = "版本"
L["Welcome to use HappyButton."] = "欢迎使用插件HappyButton。"
L["Can not register Bar: must be a callback function."] = "无法注册：必须是回调函数。"
L["You cannot use this in combat."] = "你无法在战斗中使用。"
L["Teleport"] = "传送"
L["Class"] = "职业"
L["Profession"] = "专业"
L["Mail"] = "邮箱"
L["Bank"] = "银行"
L["Merchant"] = "商人"
L["Others"] = "其他"
L["Yes"] = "是"
L["No"] = "否"
L["Configuration imported. Would you like to switch to the new configuration?"] = "配置已导入，是否切换到新配置？"
L["Please copy the configuration to the clipboard."] = "请将配置项复制到剪贴板。"
L["Items Bar"] = "物品条"
L["Default"] = "默认"
L["Title"] = "标题"
L["Icon"] = "图标"
L["Delete"] = "删除"
L["Mode"] = "模式"
L["Select items to display"] = "选择展示项"
L["Items Source"] = "物品源"
L["Items Group"] = "物品组"
L["New Items Group"] = "创建物品组"
L["Export"] = "导出"
L["Import Configuration"] = "导入配置"
L["Configuration string"] = "配置字符串"
L["Whether to overwrite the existing configuration."] = "覆盖旧配置"
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
L["Equipment"]="装备"
L["Toy"]="玩具"
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
L["BarGroup"] = "物品条组"
L["Bar"] = "物品条"
L["ItemGroup"] = "物品组"
L["Script"] = "脚本"
L["New BarGroup"] = "创建物品条组"
L["New Bar"] = "创建物品条"
L["New ItemGroup"] = "创建物品组"
L["New Script"] = "创建脚本"
L["New Item"] = "创建物品"
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
L["Always load"] = "总是加载"
L["Load when out of combat"] = "战斗外加载"
L["Load when in combat"] = "战斗中加载"
L["BarGroup only load when out of combat"] = "物品条组仅在战斗外加载"
L["Localize the name of items"] = "物品名称本地化"


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

L["Aura Trigger"] = "光环触发器"
L["Aura ID"] = "光环ID"
L["Aura Remaining Time"] = "光环剩余时间"
L["Select Aura Type"] = "选择光环类型"
L["Player"] = "玩家"
L["Target"] = "目标"
L["Buff"] = "增益"
L["Debuff"] = "减益"

L["Condition Settings"] = "条件设置"
L["Condition"] = "条件"
L["New Condition"] = "添加条件"
L["No Trigger"] = "不使用触发器"
L["Left Value Settings"] = "左值设置"
L["Operate"] = "运算符"
L["Right Value Settings"] = "右值设置"
L["True"] = "真"
L["False"] = "假"
