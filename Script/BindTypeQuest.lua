----------------------------------
-- 获取可以点击的任务物品
----------------------------------
return function()
    local function GetQuestItems()
        ---@diagnostic disable-next-line: deprecated
        local GetItemInfo = (C_Item and C_Item.GetItemInfo) and C_Item.GetItemInfo or GetItemInfo
        ---@diagnostic disable-next-line: deprecated
        local IsUsableItem = (C_Item and C_Item.IsUsableItem) and C_Item.IsUsableItem or IsUsableItem
        local items = {} ---@type table[]
        local itemIds = {} ---@type table<number, true>
        for bag = 0, NUM_BAG_SLOTS do
            local size = C_Container.GetContainerNumSlots(bag)
            for slot = 1, size do
                local itemID = C_Container.GetContainerItemID(bag, slot)
                if itemID then
                    local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent = GetItemInfo(itemID)
                    if bindType == 4 and itemIds[itemID] == nil then
                        local usable, _ = IsUsableItem(itemID)
                        if usable then
                            table.insert(items, {
                                icon = itemTexture,
                                text = itemName,
                                item = {
                                    id = itemID,
                                    icon = itemTexture,
                                    name = itemName,
                                    type = 1
                                }
                            })
                            itemIds[itemID] = true
                        end
                    end
                end
            end
        end
        return items
    end
    return GetQuestItems()
end