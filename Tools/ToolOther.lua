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
    {itemID=224554, itemType=U.Cate.TOY}, -- [银白核丝节杖]
}
local fallingCallback = function ()
    local item = HT.RandomChooseItem(fallingList)
    if item then
        local result = HtItem.CallbackByItem(item.itemID, item.itemType)
        result.text = L["Prevent Falling"]
    else
        return nil
    end
end
table.insert(HT.ToolOtherCallbackList, fallingCallback)




local otherUsefulThingList = {
    {itemID=8529, itemType=U.Cate.ITEM}, -- [诺格弗格药剂] 1.0
    {itemID=95566, itemType=U.Cate.ITEM}, -- [拉沙的献祭之匕]
    {itemID=137663, itemType=U.Cate.TOY}, -- [柔软的泡沫塑料剑]
    {itemID=85500, itemType=U.Cate.TOY}, -- [垂钓翁钓鱼筏]
}
for _, thing in ipairs(otherUsefulThingList) do
    table.insert(HT.ToolOtherCallbackList, function ()
        return HtItem.CallbackByItem(thing.itemID, thing.itemType)
    end)
end