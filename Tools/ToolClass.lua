local _, HT = ...
local U = HT.Utils
local HtItem = HT.HtItem

HT.ToolClassCallbackList = {}
local _, classFileName = UnitClass("player")  -- 获取职业

local ClassSpellList = {
    {itemID=190336, itemType=U.Cate.SPELL, class="MAGE"}, -- [造餐术]
    {itemID=1459, itemType=U.Cate.SPELL, class="MAGE"}, -- [奥术智慧]
    {itemID=130, itemType=U.Cate.SPELL, class="MAGE"}, -- [缓落术]
}

for _, thing in ipairs(ClassSpellList) do
    if thing.class == classFileName then
        table.insert(HT.ToolClassCallbackList, function ()
            return HtItem.CallbackByItem(thing.itemID, thing.itemType)
        end)
    end
end
