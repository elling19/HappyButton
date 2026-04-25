---@class ItemAttr
---@field type ItemType | nil
---@field id integer | nil
---@field icon integer | string | nil
---@field name string | nil

---@class ItemGroupAttr
---@field mode ItemsGroupMode
---@field configSelectedItemIndex number 编辑子元素的时候选中的下标

---@class ScriptAttr
---@field script string | nil  -- 原始脚本文件

---@class DisplayRuleConfig
---@field unlearned "hide" | "gray" | nil  -- 未拥有时的展示规则
---@field unusable "hide" | "gray" | nil  -- 不可用时的展示规则
---@field uncooled "hide" | "gray" | nil  -- 未冷却时的展示规则（技能在战斗中无效）

---@class MacroAttr
---@field macro string | nil -- 宏脚本
---@field ast MacroAst | nil -- 宏语法树


---@class ElementConfig
---@field id string
---@field isDisplayMouseEnter boolean --是否鼠标移入显示
---@field iconWidth number | nil
---@field iconHeight number | nil
---@field isShowQualityBorder boolean | nil --是否显示边框染色（默认不染色）
---@field title string
---@field type ElementType
---@field extraAttr any | nil
---@field elements ElementConfig[]
---@field icon string | number | nil
---@field flyout boolean | nil -- 根Bar是否使用flyout模式
---@field flyoutAutoCollapse boolean | nil -- flyout按钮列表点击后是否自动收起；nil视为默认开启
---@field anchorPos string  --锚点位置
---@field attachFrame string  --依附框体
---@field attachFrameAnchorPos string -- 依附框体锚点位置
---@field posX number | nil -- X轴位置
---@field posY number | nil  -- Y轴位置
---@field elesGrowth Growth --子元素生长方向
---@field loadCond LoadConditionConfig  -- 加载条件
---@field displayRule DisplayRuleConfig | nil -- 展示规则
---@field isUseRootTexts boolean -- 是否使用根元素文本的设置
---@field texts TextConfig[]  -- 文本设置
---@field configSelectedTextIndex number -- 编辑文本的时候选中的下标
---@field triggers TriggerConfig[]  -- 触发器设置
---@field configSelectedTriggerIndex number -- 编辑触发器的时候选中的下标
---@field condGroups ConditionGroupConfig[]  -- 触发器条件组
---@field configSelectedCondGroupIndex number -- 编辑条件设置的时候选中的下标
---@field configSelectedCondIndex number
---@field listenEvents table<EventString, {}> | nil -- 自定义监听事件，key为事件名称，value为事件参数的列表，暂时定位`{}`，后续需要优化的时候改成payload列表
---@field bindKey BindKeyConfig | nil -- 自定义按键绑定
local ElementConfig = {}


---@class ItemConfig: ElementConfig
---@field extraAttr ItemAttr
local ItemConfig = {}

---@class ScriptConfig: ElementConfig
---@field extraAttr ScriptAttr
local ScriptConfig = {}

---@class MacroConfig: ElementConfig
---@field extraAttr MacroAttr
local MacroConfig = {}

---@class ItemGroupConfig: ElementConfig
---@field extraAttr ItemGroupAttr
local ItemGroupConfig = {}


---@class BarConfig: ElementConfig
---@field flyout boolean | nil  -- 是否使用抽屉模式；nil表示不启用
---@field flyoutAutoCollapse boolean | nil -- 按钮点击后自动收起；nil表示默认开启
local BarConfig = {}

