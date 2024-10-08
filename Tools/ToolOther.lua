local _, HT = ...
local L = LibStub("AceLocale-3.0"):GetLocale("HappyToolkit", false)
local U = HT.Utils
local HtItem = HT.HtItem

-- 其他实用物品
HT.ToolOtherCallbackList = {}

-- 防止摔落
local fallingList =
{
    {itemID=182696, itemType=U.Cate.TOY}, -- [女伯爵的阳伞] 9.0
    {itemID=182694, itemType=U.Cate.TOY}, -- [时髦的黑色遮阳伞] 9.0
    {itemID=182695, itemType=U.Cate.TOY}, -- [饱经风霜的紫色遮阳伞] 9.0
    {itemID=182729, itemType=U.Cate.TOY}, -- [健壮巨龙飞羽] 9.0
    {itemID=224554, itemType=U.Cate.TOY}, -- [银白核丝节杖]
}
table.insert(HT.ToolOtherCallbackList, function ()
    return function ()
        local item = HT.RandomChooseItem(fallingList)
        local result = HtItem.CallbackByItem(item.itemID, item.itemType)
        result.text = L["Prevent Falling"]
        return result
    end
end)


-- 战斗假人
local combatDummyList = {
    {itemID=144339, itemType=U.Cate.TOY}, -- [结实的爱情娃娃] 情人节
    {itemID=88375, itemType=U.Cate.TOY},  -- [芜菁沙袋]
    {itemID=219387, itemType=U.Cate.TOY},  -- [一桶烟花]
    {itemID=201933, itemType=U.Cate.TOY},  -- [黑龙的挑战假人]
    {itemID=199896, itemType=U.Cate.TOY},  -- [橡胶鱼头]
    {itemID=89614, itemType=U.Cate.TOY},  -- [解剖用假人]
    {itemID=163201, itemType=U.Cate.TOY},  -- [豺狼人标靶木桶]
    {itemID=199830, itemType=U.Cate.TOY},  -- [海象人训练假人]
}
table.insert(HT.ToolOtherCallbackList, function ()
    return function ()
        local item = HT.RandomChooseItem(combatDummyList)
        local result = HtItem.CallbackByItem(item.itemID, item.itemType)
        result.text = L["Combat Dummy"]
        return result
    end
end)


-- 音乐&舞蹈
local randomMusicDanceList = {
    {itemID=52253, itemType=U.Cate.TOY}, -- [希尔瓦娜斯的音乐盒]
    {itemID=166702, itemType=U.Cate.TOY}, -- [普罗德摩尔音乐盒]
    {itemID=115501, itemType=U.Cate.TOY}, -- [科瓦斯基的音乐盒]
    {itemID=122700, itemType=U.Cate.TOY}, -- [便携式播放器]
    {itemID=201435, itemType=U.Cate.TOY}, -- [跃舞流沙]
    {itemID=34686, itemType=U.Cate.TOY}, -- [烈焰舞娘火盆]
    {itemID=160751, itemType=U.Cate.TOY}, -- [亡者之舞]
    {itemID=38301, itemType=U.Cate.TOY}, -- [跳舞球]
    {itemID=187689, itemType=U.Cate.TOY}, -- [劲舞暗月]
    {itemID=206038, itemType=U.Cate.TOY}, -- [光鲜的燃焰之环]
}
table.insert(HT.ToolOtherCallbackList, function ()
    return function ()
        local item = HT.RandomChooseItem(randomMusicDanceList)
        local result = HtItem.CallbackByItem(item.itemID, item.itemType)
        result.text = L["Music And Dance"]
        return result
    end
end)


-- 猪队友
local deadPartyList = {
    {itemID=194052, itemType=U.Cate.TOY}, -- [被遗忘的葬礼棺罩]
    {itemID=187174, itemType=U.Cate.TOY}, -- [便携式审判石]
    {itemID=215145, itemType=U.Cate.TOY}, -- [纪念之石]
    {itemID=166784, itemType=U.Cate.TOY}, -- [纳拉辛的灵魂宝石]
    {itemID=184410, itemType=U.Cate.TOY}, -- [候选者担架]
}
table.insert(HT.ToolOtherCallbackList, function ()
    return function ()
        local item = HT.RandomChooseItem(deadPartyList)
        local result = HtItem.CallbackByItem(item.itemID, item.itemType)
        result.text = L["Remember Dead Party"]
        return result
    end
end)


local otherUsefulThingList = {
    {itemID=8529, itemType=U.Cate.ITEM}, -- [诺格弗格药剂] 1.0
    {itemID=95566, itemType=U.Cate.ITEM}, -- [拉沙的献祭之匕]
    {itemID=137663, itemType=U.Cate.TOY}, -- [柔软的泡沫塑料剑]
    {itemID=85500, itemType=U.Cate.TOY}, -- [垂钓翁钓鱼筏]
}
for _, thing in ipairs(otherUsefulThingList) do
    table.insert(HT.ToolOtherCallbackList, function ()
        return function ()
            return HtItem.CallbackByItem(thing.itemID, thing.itemType)
        end
    end)
end