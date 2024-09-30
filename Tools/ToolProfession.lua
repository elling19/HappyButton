local _, HT = ...
local U = HT.Utils
local HtItem = HT.HtItem

local prof1, prof2, archaeology, fishing, cooking = GetProfessions()

HT.ToolProfessionCallbackList = {}

if not (cooking == nil) then
    local cookingList = {
        {itemID=818, itemType=U.Cate.SPELL}, -- [烹饪用火]
        {itemID=153039, itemType=U.Cate.TOY}, -- [晶化营火]
        {itemID=198402, itemType=U.Cate.TOY}, -- [马鲁克烹饪锅]
        {itemID=116757, itemType=U.Cate.TOY}, -- [蒸汽香肠烤架]
    }
    local cookingCallback = function ()
        local item = HT.RandomChooseItem(cookingList)
        if item then
            return HtItem.CallbackByItem(item.itemID, item.itemType)
        else
            return nil
        end
    end
    table.insert(HT.ToolProfessionCallbackList, cookingCallback)
end