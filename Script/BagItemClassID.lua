----------------------------------
-- 根据物品类型查找物品列表
----------------------------------
return function()
	local function isInArray(array, element)
		for i = 1, #array do
			if array[i] == element then
				return true
			end
		end
		return false
	end

    local GetItemInfo = (C_Item and C_Item.GetItemInfo) and C_Item.GetItemInfo or GetItemInfo
    local IsUsableItem = (C_Item and C_Item.IsUsableItem) and C_Item.IsUsableItem or IsUsableItem

    ---@param classId number 物品类别
    ---@param subclassIds table | nil 物品子类别
    ---@param isUsable boolean | nil 是否可使用
    local function GetItems(classId, subclassIds, isUsable)
        local items = {} ---@type table[]
        local itemIds = {} ---@type table<number, true>
        for bag = 0, NUM_BAG_SLOTS do
            local size = C_Container.GetContainerNumSlots(bag)
            for slot = 1, size do
                local itemID = C_Container.GetContainerItemID(bag, slot)
                if itemID then
                    local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent = GetItemInfo(itemID)
                    local isClassIdItem = (classID and classID == classId)
                    if isClassIdItem and itemIds[itemID] == nil then
						if subclassIds == nil or isInArray(subclassIds, subclassID) then
                            if isUsable == nil or select(1, IsUsableItem(itemID) == isUsable) then
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
        end
        return items
    end
    return GetItems(0) -- 消耗品
    -- return GetItems(15, nil, true)  -- 可以打开的杂项
end
