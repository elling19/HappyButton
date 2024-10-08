local _, HT = ...
local U = HT.Utils
local HtItem = HT.HtItem

HT.ToolBankCallbackList = {}

-- 地精种族技能：[戏法]
table.insert(HT.ToolBankCallbackList, function ()
    local _, _, raceID = UnitRace("player")
    if raceID == 9 then
        return function ()
            return HtItem.CallbackByItem(69046, U.Cate.SPELL)
        end
    else
        return nil
    end
end)


local BankList =
{
    {itemID=83958, itemType=U.Cate.SPELL}, -- [移动银行]
    {itemID=460905, itemType=U.Cate.SPELL}, -- [战团银行距离抑制器]
    {itemID=214, itemType=U.Cate.PET}, -- [银色侍从] 
}

for _, thing in ipairs(BankList) do
    table.insert(HT.ToolBankCallbackList, function ()
        if HtItem.IsLearned(thing.itemID, thing.itemType) then
            return function ()
                return HtItem.CallbackByItem(thing.itemID, thing.itemType)
            end
        else
            return nil
        end
    end)
end

-- 工程专业：[可充电的里弗斯电池]
table.insert(HT.ToolBankCallbackList, function ()
    local prof1, prof2, _, _, _ = GetProfessions()
    if prof1 == 8 or prof2 == 8 then
        return function ()
            return HtItem.CallbackByItem(144341, U.Cate.ITEM)
        end
    else
        return nil
    end
end)
