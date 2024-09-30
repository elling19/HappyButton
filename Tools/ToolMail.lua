local _, HT = ...
local U = HT.Utils
local HtItem = HT.HtItem

HT.ToolMailCallbackList = {}

local _, _, raceID = UnitRace("player")

-- 夜之子种族技能：[戏法]
if raceID == 27 then
    table.insert(HT.ToolMailCallbackList, function ()
        return HtItem.CallbackByItem(255661, U.Cate.SPELL)
    end)
end

local MailList =
{
    {itemID=156833, itemType=U.Cate.TOY}, -- [凯蒂的印哨]
    {itemID=194885, itemType=U.Cate.TOY}, -- [欧胡纳栖枝]
    {itemID="BattlePet-0-000009A487CA", itemType=U.Cate.PET} -- [银色侍从] 1号
}

for _, thing in ipairs(MailList) do
    table.insert(HT.ToolMailCallbackList, function ()
        return HtItem.CallbackByItem(thing.itemID, thing.itemType)
    end)
end

