local _, HT = ...
local L = LibStub("AceLocale-3.0"):GetLocale("HappyToolkit", false)
local U = HT.Utils
local HtItem = HT.HtItem

HT.ToolTeleportCallbackList = {}


local englishFaction, _ = UnitFactionGroup("player")  -- 获取阵营
local _, classFileName = UnitClass("player")  -- 获取职业

-- 炉石玩具列表
local HearthstoneItemList =
{
    {itemID=6948, itemType=U.Cate.ITEM}, -- [炉石]
    {itemID=64488, itemType=U.Cate.TOY}, -- [旅店老板的女儿]
    {itemID=168907, itemType=U.Cate.TOY}, -- [全息数字化炉石] 8.0 垃圾场
    {itemID=172179, itemType=U.Cate.TOY}, -- [永恒旅者的炉石] 9.0
    {itemID=184353, itemType=U.Cate.TOY}, -- [格里恩炉石] 9.0
    {itemID=180290, itemType=U.Cate.TOY}, -- [法夜炉石] 9.0
    {itemID=182773, itemType=U.Cate.TOY}, -- [通灵领主炉石] 9.0
    {itemID=188952, itemType=U.Cate.TOY}, -- [被统御的炉石] 9.0
    {itemID=193588, itemType=U.Cate.TOY}, -- [时光旅行者的炉石] 10.0
    {itemID=200630, itemType=U.Cate.TOY}, -- [欧恩伊尔轻风贤者的炉石] 10.0
    {itemID=209035, itemType=U.Cate.TOY}, -- [烈焰炉石] 10.0
    {itemID=162973, itemType=U.Cate.TOY}, -- [冬天爷爷的炉石] 节日
    {itemID=166746, itemType=U.Cate.TOY}, -- [吞火者的炉石] 节日
    {itemID=165802, itemType=U.Cate.TOY}, -- [复活节的炉石] 节日
    {itemID=165670, itemType=U.Cate.TOY}, -- [小匹德菲特的可爱炉石] 节日
    {itemID=163045, itemType=U.Cate.TOY}, -- [无头骑士的炉石] 节日
    {itemID=165669, itemType=U.Cate.TOY}, -- [春节长者的炉石] 节日
    {itemID=166747, itemType=U.Cate.TOY}, -- [美酒节狂欢者的炉石] 节日
}

local function RandomChooseItem()
    local usableItemList = {}
    for _, item in ipairs(HearthstoneItemList) do
        local itemID, itemType = item.itemID, item.itemType
        local isUsable = HtItem.CheckUseable(itemID, itemType)
        if isUsable then
            table.insert(usableItemList, item)
        end
    end
    -- 如果有可用的item，随机选择一个
    if #usableItemList > 0 then
        local randomIndex = math.random(1, #usableItemList)
        local selectedItem = usableItemList[randomIndex]
        return selectedItem
    end
    -- 没有可用的item时返回 nil
    return nil
end


local toolRandomHearthstoneCallback = function ()
    local item = RandomChooseItem()
    if not item then
        return nil
    end
    if item then
        local result = HtItem.CallbackByItem(item.itemID, item.itemType)
        result.text = L["Random Hearthstone"]
        return result
    else
        return nil
    end
end


table.insert(HT.ToolTeleportCallbackList, toolRandomHearthstoneCallback)



-- 传送玩具列表
local teleportList =
{
    {itemID=140192, itemType=U.Cate.TOY}, -- [达拉然炉石]
    {itemID=110560, itemType=U.Cate.TOY}, -- [要塞炉石]
    {itemID=212337, itemType=U.Cate.TOY}, -- [炉之石]
    {itemID=141605, itemType=U.Cate.ITEM}, -- [飞行管理员的哨子]
    {itemID=30544, itemType=U.Cate.TOY}, -- [超级安全传送器：托什雷的基地]
    {itemID=172924, itemType=U.Cate.TOY}, -- [虫洞发生器：暗影界]
    {itemID=87215, itemType=U.Cate.TOY}, -- [虫洞发生器：潘达利亚]
    {itemID=48933, itemType=U.Cate.TOY}, -- [虫洞发生器：诺森德]
    {itemID=112059, itemType=U.Cate.TOY}, -- [虫洞离心机：德拉诺]
    {itemID=63206, itemType=U.Cate.ITEM}, -- [协和披风]
    {itemID=52251, itemType=U.Cate.ITEM}, -- [吉安娜的吊坠]
}

for _, teleport in ipairs(teleportList) do
    table.insert(HT.ToolTeleportCallbackList, function ()
        return HtItem.CallbackByItem(teleport.itemID, teleport.itemType)
    end)
end


if classFileName == "MAGE" then
    if englishFaction == "Alliance" then
        -- 联盟法师专属传送门
        local allianceTeleprotList = {
            {itemID=3561, itemType=U.Cate.SPELL}, -- [传送：暴风城]
            {itemID=10059, itemType=U.Cate.SPELL}, -- [传送门：暴风城]
            {itemID=3562, itemType=U.Cate.SPELL}, -- [传送：铁炉堡]
            {itemID=11416, itemType=U.Cate.SPELL}, -- [传送门：铁炉堡]
            {itemID=3565, itemType=U.Cate.SPELL}, -- [传送：达纳苏斯]
            {itemID=11419, itemType=U.Cate.SPELL}, -- [传送门：达纳苏斯]
            {itemID=32271, itemType=U.Cate.SPELL}, -- [传送：埃索达]
            {itemID=32266, itemType=U.Cate.SPELL}, -- [传送门：埃索达]
            {itemID=49359, itemType=U.Cate.SPELL}, -- [传送：塞拉摩]
            {itemID=49360, itemType=U.Cate.SPELL}, -- [传送门：塞拉摩]
            {itemID=281403, itemType=U.Cate.SPELL}, -- [传送：伯拉勒斯]
            {itemID=281400, itemType=U.Cate.SPELL}, -- [传送门：伯拉勒斯]
            {itemID=395277, itemType=U.Cate.SPELL}, -- [传送：瓦德拉肯]
            {itemID=395289, itemType=U.Cate.SPELL}, -- [传送门：瓦德拉肯]
            {itemID=446540, itemType=U.Cate.SPELL}, -- [传送：多恩诺嘉尔]
            {itemID=446534, itemType=U.Cate.SPELL}, -- [传送门：多恩诺嘉尔]
        }
        for _, teleport in ipairs(allianceTeleprotList) do
            table.insert(HT.ToolTeleportCallbackList, function ()
                return HtItem.CallbackByItem(teleport.itemID, teleport.itemType)
            end)
        end
    end
    if englishFaction == "Horde" then
        -- 部落法师专属传送门
        local hordeTeleprotList = {
            {itemID=32272, itemType=U.Cate.SPELL}, -- [传送：银月城]
            {itemID=32267, itemType=U.Cate.SPELL}, -- [传送门：银月城]
        }
        for _, teleport in ipairs(hordeTeleprotList) do
            table.insert(HT.ToolTeleportCallbackList, function ()
                return HtItem.CallbackByItem(teleport.itemID, teleport.itemType)
            end)
        end
    end
       -- 添加全职业法师传送门
       local allFactionTeleportList = {
        {itemID=33690, itemType=U.Cate.SPELL}, -- [传送：沙塔斯]
        {itemID=33691, itemType=U.Cate.SPELL}, -- [传送门：沙塔斯]
        {itemID=53140, itemType=U.Cate.SPELL}, -- [传送：达拉然-诺森德]
        {itemID=53142, itemType=U.Cate.SPELL}, -- [传送门：达拉然-诺森德]
        {itemID=88342, itemType=U.Cate.SPELL}, -- [传送：托尔巴拉德]
        {itemID=88345, itemType=U.Cate.SPELL}, -- [传送门：托尔巴拉德]
        {itemID=132621, itemType=U.Cate.SPELL}, -- [传送：锦绣谷]
        {itemID=132620, itemType=U.Cate.SPELL}, -- [传送门：锦绣谷]
        {itemID=176248, itemType=U.Cate.SPELL}, -- [传送：暴风之盾]
        {itemID=176246, itemType=U.Cate.SPELL}, -- [传送门：暴风之盾]
        {itemID=193759, itemType=U.Cate.SPELL}, -- [传送：守护者圣殿]
        {itemID=224869, itemType=U.Cate.SPELL}, -- [传送：达拉然-破碎群岛]
        {itemID=224871, itemType=U.Cate.SPELL}, -- [传送门：达拉然-破碎群岛]
        {itemID=344587, itemType=U.Cate.SPELL}, -- [传送：奥利波斯]
        {itemID=344597, itemType=U.Cate.SPELL}, -- [传送门：奥利波斯]
    }
    for _, teleport in ipairs(allFactionTeleportList) do
        table.insert(HT.ToolTeleportCallbackList, function ()
            return HtItem.CallbackByItem(teleport.itemID, teleport.itemType)
        end)
    end
end

if classFileName == "SHAMAN" then
     local shamanTeleportList = {
        {itemID=556, itemType=U.Cate.SPELL}, -- [星界传送]
    }
    for _, teleport in ipairs(shamanTeleportList) do
        table.insert(HT.ToolTeleportCallbackList, function ()
            return HtItem.CallbackByItem(teleport.itemID, teleport.itemType)
        end)
    end
end
