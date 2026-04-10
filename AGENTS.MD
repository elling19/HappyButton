# AGENTS

## 1. 插件概览
HappyButton 是基于 Ace3 的魔兽世界插件，核心目标是把物品、技能、宏和脚本统一抽象成元素树，并在运行时生成按钮进行显示与交互。

主要能力：
- 通过配置创建条形栏、分组、单物品、宏、脚本元素
- 按事件更新元素回调结果（CbResult）
- 按结果更新按钮图标、文本、边框与可视效果
- 支持导入导出配置

## 2. 关键目录与职责
- Src/Config.lua
  - 配置面板构建与配置写回
- Src/Element/Element.lua
  - 元素模型创建、类型转换、事件列表
- Src/Frame/ElementCallback.lua
  - 运行时回调与 CbResult 更新
- Src/Frame/Btn.lua
  - 按钮渲染与效果落地（隐藏、灰化、发光等）
- Src/Const.lua
  - 共享常量和选项表
- Locales/
  - 多语言键值

## 3. 运行链路（高层）
1. 配置层生成 ElementConfig 树并保存
2. Frame 层为元素树创建按钮
3. 事件到达后，ElementCallback 更新 CbResult
4. Btn 根据 CbResult 刷新图标、文本、效果

## 4. 12.0 版本约束与当前策略
由于 12.0 对技能冷却相关 API 调整，原“触发器设置”和“条件组设置”不再作为可配置能力暴露。

当前改为简化展示规则（放在展示规则分组中）：
- 未拥有：可选开启，开启后默认隐藏，可切换为灰色
- 物品不可用：可选开启，开启后默认灰色，可切换为隐藏

实现要点：
- 使用 ElementConfig.displayRule 保存规则
- ElementCallback:UseTrigger 按 isLearned/isUsable 直接生成 btnHide 或 btnDesaturate 效果
- Btn 继续沿用既有效果渲染逻辑

## 5. 配置兼容性说明
- 旧配置中的 triggers 与 condGroups 字段仍可存在，但配置 UI 不再编辑它们
- 新创建元素默认不启用展示规则（displayRule 字段为空）
- 当用户开启对应规则时，默认值为：
  - unlearned = hide
  - unusable = gray

## 6. 开发建议
- 如果没有特殊要求，请不要修改Libs库中的第三方源代码
- 优先在 Config 层做最小可见变更，在 Callback 层做最小行为变更
- 任何新增展示逻辑，尽量复用 Btn 现有效果类型
- 本项目依赖事件驱动，修改逻辑时优先检查事件触发频率与战斗状态限制
- 多语言键必须同步更新 enUS 与 zhCN

## 7. 回归检查清单
- 配置面板中不再出现触发器设置与条件组设置
- 展示规则中出现两条新选项，并具备默认值
- 未学会时按规则隐藏或灰化
- 不可用时按规则隐藏或灰化
- 根元素/脚本元素原有配置项不受影响
