local _, HT = ...
local L = LibStub("AceLocale-3.0"):GetLocale("HappyToolkit", false)

local HtItem = HT.HtItem
local U = HT.Utils

-- 装扮玩具列表
local SpecialdressToyList =
{
    {itemID=173984, itemType=U.Cate.TOY}, -- [万世卷轴]
    {itemID=129149, itemType=U.Cate.TOY}, -- [死亡之门护符]
    {itemID=108739, itemType=U.Cate.TOY}, -- [漂亮的德拉诺珍珠]
    {itemID=163775, itemType=U.Cate.TOY}, -- [穆罗克头盔]
    {itemID=116115, itemType=U.Cate.TOY}, -- [炽燃之翼]
    {itemID=130158, itemType=U.Cate.TOY}, -- [埃洛瑟尔之径]
    {itemID=179393, itemType=U.Cate.TOY}, -- [妒梦之镜]
    {itemID=113375, itemType=U.Cate.TOY}, -- [守备官盔甲打磨包]
    {itemID=108743, itemType=U.Cate.TOY}, -- [德塞普提亚的冒烟靴子]
    {itemID=201435, itemType=U.Cate.TOY}, -- [跃舞流沙]
    {itemID=86589, itemType=U.Cate.TOY}, -- [艾利的天镜]
}

local function randomChooseItem()
    local usableItemList = {}
    for _, item in ipairs(SpecialdressToyList) do
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
   -- 没有可用的item时返回第一个
   return SpecialdressToyList[0]
end


HT.ToolRandomSpecialdressCallbak = function ()
    local item = randomChooseItem()
    if item then
        local result = HtItem.CallbackByItem(item.itemID, item.itemType)
        result.text = L["Special Dress Toy"]
        return result
    else
        return nil
    end
end

