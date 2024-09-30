local _, HT = ...
local U = HT.Utils
local HtItem = HT.HtItem

HT.ToolMerchantCallbackList = {}

local MerchantList =
{
    {itemID=280, itemType=U.Cate.MOUNT}, -- [旅行者的苔原猛犸象]
    {itemID=460, itemType=U.Cate.MOUNT}, -- [雄壮远足牦牛]
    {itemID=2237, itemType=U.Cate.MOUNT}, -- [灰熊丘陵魁熊]
    {itemID=1039, itemType=U.Cate.MOUNT}, -- [雄壮商队雷龙的缰绳]
}

for _, thing in ipairs(MerchantList) do
    table.insert(HT.ToolMerchantCallbackList, function ()
        return HtItem.CallbackByItem(thing.itemID, thing.itemType)
    end)
end

-- 工程专业：[可充电的里弗斯电池]
local prof1, prof2, _, _, _ = GetProfessions()
if prof1 == 8 or prof2 == 8 then
    local EngineeringList =
    {
        {itemID=49040, itemType=U.Cate.ITEM}, -- [基维斯]
        {itemID=132523, itemType=U.Cate.ITEM}, -- [里弗斯电池]
        {itemID=221957, itemType=U.Cate.ITEM} -- [阿加修理机器人11O]
    }
    for _, thing in ipairs(EngineeringList) do
        table.insert(HT.ToolMerchantCallbackList, function ()
            return HtItem.CallbackByItem(thing.itemID, thing.itemType)
        end)
    end
end