local _, HT = ...
local U = HT.Utils
local HtItem = HT.HtItem

HT.ToolProfessionCallbackList = {}
local cookingList = {
    {itemID=818, itemType=U.Cate.SPELL}, -- [烹饪用火]
    {itemID=153039, itemType=U.Cate.TOY}, -- [晶化营火]
    {itemID=198402, itemType=U.Cate.TOY}, -- [马鲁克烹饪锅]
    {itemID=116757, itemType=U.Cate.TOY}, -- [蒸汽香肠烤架]
}
table.insert(HT.ToolProfessionCallbackList, function ()
    local prof1, prof2, archaeology, fishing, cooking = GetProfessions()
    if cooking == nil then
        return nil
    end
    return function ()
        local item = HT.RandomChooseItem(cookingList)
        return HtItem.CallbackByItem(item.itemID, item.itemType)
    end
end)

table.insert(HT.ToolProfessionCallbackList, function ()
    local item = {itemID=134020, itemType=U.Cate.TOY}  -- [大厨的帽子]
    local prof1, prof2, archaeology, fishing, cooking = GetProfessions()
    if cooking == nil then
        return nil
    end
    if not HtItem.IsLearned(item.itemID, item.itemType) then
        return nil
    end
    return function ()
        return HtItem.CallbackByItem(item.itemID, item.itemType)
    end
end)
