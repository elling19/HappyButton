local addonName, _ = ...

---@class HappyButton: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class DbCache: AceModule
local DbCache = addon:NewModule("DbCache")

-- 炉石共享CD
---@type SpellID[]
local hearthstoneSpellIds = {
    8690,   -- [炉石],
    463481, -- [恶名丝线炉石]
    401802, -- [炉之石]
    286353, -- [美酒节狂欢者的炉石]
    285362, -- [春节长者的炉石]
    278559, -- [无头骑士的炉石]
    285424, -- [小匹德菲特的可爱炉石]
    286031, -- [复活节的炉石]
    286331, -- [吞火者的炉石]
    278244, -- [冬天爷爷的炉石]
    422284, -- [烈焰炉石]
    420418, -- [幽邃住民的土灵炉石]
    391042, -- [欧恩伊尔轻风贤者的炉石]
    375357, -- [时光旅行者的炉石]
    367013, -- [掮灵传送矩阵]
    366945, -- [开悟者炉石]
    342122, -- [温西尔罪碑]
    363799, -- [被统御的炉石]
    340200, -- [通灵领主炉石]
    326064, -- [法夜炉石]
    345393, -- [格里恩炉石]
    308742, -- [永恒旅者的炉石]
    298068, -- [全息数字化炉石]
    94719,  -- [旅店老板的女儿]
}

-- 药水共享CD
---@type SpellID[]
local pointSpellIds = {

}

---@type table<stringView, table>>
DbCache.ShareCD = {
    Hearthstone = hearthstoneSpellIds,
    Potion = pointSpellIds,
}
