----------------------------------
-- 坐骑狂欢：这个我也有
----------------------------------
return function()
    local itemList = {}
    for i = 1, 100 do
        local aura = C_UnitAuras.GetBuffDataByIndex("target", i)
        if not aura then
            break
        end
        local spellID = aura.spellId
        if spellID then
            local mountID = C_MountJournal.GetMountFromSpell(spellID)
            if mountID then
                local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight =
                C_MountJournal.GetMountInfoByID(mountID)
                table.insert(itemList, {
                    icon = icon,
                    text = name,
                    item = {
                        type=5,
                        id=mountID,
                        icon=icon,
                        name=name,
                        alias=nil,
                    }
                })
                break
            end
        end
    end
    return itemList
end
