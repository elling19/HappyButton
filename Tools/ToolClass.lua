local _, HT = ...
local U = HT.Utils
local HtItem = HT.HtItem

HT.ToolClassCallbackList = {}


local ClassSpellList = {
    {itemID=190336, itemType=U.Cate.SPELL, class="MAGE"}, -- [造餐术]
    {itemID=1459, itemType=U.Cate.SPELL, class="MAGE"}, -- [奥术智慧]
    {itemID=130, itemType=U.Cate.SPELL, class="MAGE"}, -- [缓落术]
    {itemID=1804, itemType=U.Cate.SPELL, class="ROGUE"}, -- [开锁]
    {itemID=364342, itemType=U.Cate.SPELL, class="EVOKER"}, -- [青铜龙的祝福]
    {itemID=1126, itemType=U.Cate.SPELL, class="DRUID"}, -- [野性印记]
    {itemID=164862, itemType=U.Cate.SPELL, class="DRUID"}, -- [振翅]
    {itemID=6673, itemType=U.Cate.SPELL, class="WARRIOR"}, -- [战斗怒吼]
    {itemID=32223, itemType=U.Cate.SPELL, class="PALADIN"}, -- [十字军光环]
    {itemID=465, itemType=U.Cate.SPELL, class="PALADIN"}, -- [虔诚光环]
    {itemID=317920, itemType=U.Cate.SPELL, class="PALADIN"}, -- [专注光环]
    {itemID=3714, itemType=U.Cate.SPELL, class="DEATHKNIGHT"}, --[冰霜之路]
    {itemID=29893, itemType=U.Cate.SPELL, class="WARLOCK"}, --[制造灵魂之井]
    {itemID=6201, itemType=U.Cate.SPELL, class="WARLOCK"}, --[制造治疗石]
    {itemID=698, itemType=U.Cate.SPELL, class="WARLOCK"}, --[召唤仪式]
    {itemID=462854, itemType=U.Cate.SPELL, class="SHAMAN"}, --[天怒]
    {itemID=21562, itemType=U.Cate.SPELL, class="PRIEST"}, --[真言术：韧]
    {itemID=1706, itemType=U.Cate.SPELL, class="PRIEST"}, --[漂浮术]
    {itemID=212036, itemType=U.Cate.SPELL, class="PRIEST"}, -- [群体复活]
    {itemID=2006, itemType=U.Cate.SPELL, class="PRIEST"}, -- [复活术]
    {itemID=212051, itemType=U.Cate.SPELL, class="MONK"} -- [死而复生]
}

for _, thing in ipairs(ClassSpellList) do
    local _, classFileName = UnitClass("player")  -- 获取职业
    table.insert(HT.ToolClassCallbackList, function ()
        if thing.class == classFileName then
            return function ()
                return HtItem.CallbackByItem(thing.itemID, thing.itemType)
            end
        else
            return nil
        end
    end)
end
