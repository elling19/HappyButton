local _, HT = ...
local U = HT.Utils
local HtItem = HT.HtItem

HT.ToolBankCallbackList = {}


local _, _, raceID = UnitRace("player")

-- 地精种族技能：[戏法]
if raceID == 9 then
    table.insert(HT.ToolBankCallbackList, function ()
        return HtItem.CallbackByItem(69046, U.Cate.SPELL)
    end)
end

local BankList =
{
    {itemID=83958, itemType=U.Cate.SPELL}, -- [移动银行]
    {itemID=460905, itemType=U.Cate.SPELL}, -- [战团银行距离抑制器]
    {itemID="BattlePet-0-000009A487CA", itemType=U.Cate.PET} -- [银色侍从] 1号
}

for _, thing in ipairs(BankList) do
    table.insert(HT.ToolBankCallbackList, function ()
        return HtItem.CallbackByItem(thing.itemID, thing.itemType)
    end)
end

-- 工程专业：[可充电的里弗斯电池]
local prof1, prof2, _, _, _ = GetProfessions()
if prof1 == 8 or prof2 == 8 then
    table.insert(HT.ToolBankCallbackList, function ()
        return HtItem.CallbackByItem(144341, U.Cate.ITEM)
    end)
end
