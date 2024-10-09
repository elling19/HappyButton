local _, HT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("HappyToolkit", false)

local function getPlayerClassIcon()
    local classIcons = {
        WARRIOR=626008,
        PALADIN=626003,
        HUNTER=626000,
        ROGUE=626005,
        PRIEST=626004,
        DEATHKNIGHT=135771,
        SHAMAN=626006,
        MAGE=626001,
        WARLOCK=626007,
        MONK=626002,
        DRUID=625999,
        DEMONHUNTER=1260827,
        EVOKER=4574311
    }
    local _, classFileName = UnitClass("player")
    return classIcons[classFileName]

end

local ToolkitPool = {
    {cate="teleport", title=L["Teleport"], icon=134414, pool={}, cbPool={}},
    {cate="class", title=L["Class"], icon=getPlayerClassIcon(), pool={}, cbPool={}},
    {cate="profession", title=L["Profession"], icon=4620673, pool={}, cbPool={}},
    {cate="mail", title=L["Mail"] , icon=463542, pool={}, cbPool={}},
    {cate="bank", title=L["Bank"], icon=413587, pool={}, cbPool={}},
    {cate="merchant", title=L["Merchant"], icon=616692, pool={}, cbPool={}},
    {cate="other", title=L["Others"], icon=237285, pool={}, cbPool={}}
}

HT.ToolkitPool = ToolkitPool
