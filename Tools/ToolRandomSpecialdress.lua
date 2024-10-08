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
    {itemID=187840, itemType=U.Cate.TOY}, -- [炫光之翼]
    {itemID=130158, itemType=U.Cate.TOY}, -- [埃洛瑟尔之径]
    {itemID=179393, itemType=U.Cate.TOY}, -- [妒梦之镜]
    {itemID=113375, itemType=U.Cate.TOY}, -- [守备官盔甲打磨包]
    {itemID=108743, itemType=U.Cate.TOY}, -- [德塞普提亚的冒烟靴子]
    {itemID=86589, itemType=U.Cate.TOY}, -- [艾利的天镜]
}


HT.ToolRandomSpecialdressCallbak = function ()
    return function ()
        local item = HT.RandomChooseItem(SpecialdressToyList)
        local result = HtItem.CallbackByItem(item.itemID, item.itemType)
        result.text = L["Special Dress Toy"]
        return result
    end
end

