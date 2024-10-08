local _, HT = ...

local L = LibStub("AceLocale-3.0"):GetLocale("HappyToolkit", false)
local HtItem = HT.HtItem
local U = HT.Utils

-- 变形玩具列表
local MorphItemTable =
    {
        {itemID=122117, itemType=U.Cate.TOY}, -- [伊克赞的诅咒之羽]
        {itemID=120276, itemType=U.Cate.TOY}, -- [侦察骑兵的缰绳]
        {itemID=118937, itemType=U.Cate.TOY}, -- [加摩尔的发辫]
        {itemID=183847, itemType=U.Cate.TOY}, -- [助祭的伪装]
        {itemID=128462, itemType=U.Cate.TOY}, -- [卡拉波议员礼服]
        {itemID=68806, itemType=U.Cate.TOY}, -- [卡莱莎的魂萦坠饰]
        {itemID=139337, itemType=U.Cate.TOY}, -- [即抛型冬幕节服装]
        {itemID=190457, itemType=U.Cate.TOY}, -- [原型拓扑方块]
        {itemID=224783, itemType=U.Cate.TOY}, -- [君主华服之箱]
        {itemID=191891, itemType=U.Cate.TOY}, -- [啾讽教授完美得无可置喙的鹰身人伪装]
        {itemID=141862, itemType=U.Cate.TOY}, -- [圣光微粒]
        {itemID=127668, itemType=U.Cate.TOY}, -- [地狱火珠宝]
        {itemID=128807, itemType=U.Cate.TOY}, -- [多面硬币]
        {itemID=103685, itemType=U.Cate.TOY}, -- [天神防御者的奖章]
        {itemID=64651, itemType=U.Cate.TOY}, -- [小精灵护符]
        {itemID=166779, itemType=U.Cate.TOY}, -- [幻变者道标]
        {itemID=225641, itemType=U.Cate.TOY}, -- [幻象蜃鱼人诱饵]
        {itemID=127659, itemType=U.Cate.TOY}, -- [幽灵钢铁海盗帽]
        {itemID=133511, itemType=U.Cate.TOY}, -- [戈博格的闪光宝贝]
        {itemID=187155, itemType=U.Cate.TOY}, -- [拟态者的伪装]
        {itemID=134831, itemType=U.Cate.TOY}, -- [末日预言者长袍]
        {itemID=119215, itemType=U.Cate.TOY}, -- [机械仿真侏儒]
        {itemID=1973, itemType=U.Cate.TOY}, -- [欺诈宝珠]
        {itemID=142452, itemType=U.Cate.TOY}, -- [残余的虫语精华]
        {itemID=118938, itemType=U.Cate.TOY}, -- [法力风暴的复印机]
        {itemID=140780, itemType=U.Cate.TOY}, -- [法多雷蛛卵]
        {itemID=129926, itemType=U.Cate.TOY}, -- [灰舌印记]
        {itemID=66888, itemType=U.Cate.TOY}, -- [熊怪变形棒]
        {itemID=52201, itemType=U.Cate.TOY}, -- [穆拉丁的礼物]
        {itemID=163750, itemType=U.Cate.TOY}, -- [考沃克装束]
        {itemID=127709, itemType=U.Cate.TOY}, -- [脉动的鲜血宝珠]
        {itemID=200857, itemType=U.Cate.TOY}, -- [莎尔佳护符]
        {itemID=71259, itemType=U.Cate.TOY}, -- [莱雅娜的坠饰]
        {itemID=119134, itemType=U.Cate.TOY}, -- [萨格雷伪装]
        {itemID=130147, itemType=U.Cate.TOY}, -- [蓟叶树枝]
        {itemID=184223, itemType=U.Cate.TOY}, -- [被统御者的头盔]
        {itemID=129938, itemType=U.Cate.TOY}, -- [诺森德的意志]
        {itemID=147843, itemType=U.Cate.TOY}, -- [赛拉的备用斗篷]
        {itemID=35275, itemType=U.Cate.TOY}, -- [辛多雷宝珠]
        {itemID=116067, itemType=U.Cate.TOY}, -- [违誓之戒]
        {itemID=104294, itemType=U.Cate.TOY}, -- [迷时水手结晶]
        {itemID=86568, itemType=U.Cate.TOY}, -- [重拳先生的铜罗盘]
        {itemID=118244, itemType=U.Cate.TOY}, -- [钢铁海盗帽]
        {itemID=43499, itemType=U.Cate.TOY}, -- [铁靴烈酒]
        {itemID=128471, itemType=U.Cate.TOY}, -- [霜狼蛮兵战甲]
        {itemID=118716, itemType=U.Cate.TOY}, -- [鬣蜥人伪装]
        {itemID=72159, itemType=U.Cate.TOY}, -- [魔法食人魔玩偶]
        {itemID=127394, itemType=U.Cate.TOY}, -- [魔荚人伪装]
        {itemID=122283, itemType=U.Cate.TOY}, -- [鲁克玛的神圣回忆]
        {itemID=129093, itemType=U.Cate.TOY}, -- [鸦熊伪装]
        {itemID=166544, itemType=U.Cate.TOY}, -- [黑暗游侠的备用罩帽]
        {itemID=164374, itemType=U.Cate.TOY}, -- [魔法猴子香蕉]
        {itemID=164373, itemType=U.Cate.TOY}, -- [魔法汤石]
        {itemID=174873, itemType=U.Cate.TOY}, -- [魔古变身器]
        {itemID=140160, itemType=U.Cate.TOY}, -- [雷铸维库号角]
        {itemID=32782, itemType=U.Cate.TOY}, -- [迷时雕像]
        {itemID=37254, itemType=U.Cate.TOY}, -- [超级猴子球]
        {itemID=208658, itemType=U.Cate.TOY}, -- [谦逊之镜]
        {itemID=113096, itemType=U.Cate.TOY}, -- [血鬃符咒]
        {itemID=228705, itemType=U.Cate.TOY}, -- [蛛类血清]
        {itemID=202253, itemType=U.Cate.TOY}, -- [爪皮原始手杖]
        {itemID=116440, itemType=U.Cate.TOY}, -- [炽燃防御者的勋章]
        {itemID=119421, itemType=U.Cate.TOY}, -- [沙塔尔防御者勋章]
        {itemID=105898, itemType=U.Cate.TOY}, -- [月牙的爪子]
        {itemID=208421, itemType=U.Cate.TOY}, -- [新月纲要]
        {itemID=200960, itemType=U.Cate.TOY}, -- [新生灵魂之种]
        {itemID=86573, itemType=U.Cate.TOY}, -- [拱石碎片]
        {itemID=79769, itemType=U.Cate.TOY}, -- [恶魔猎手的守护]
        {itemID=200636, itemType=U.Cate.TOY}, -- [原始祈咒精华]
        {itemID=164375, itemType=U.Cate.TOY}, -- [劣质魔精香蕉]
        {itemID=205904, itemType=U.Cate.TOY}, -- [充满活力的啪嗒作响之爪]
        {itemID=163795, itemType=U.Cate.TOY}, -- [乌古特仪祭之鼓]
        {itemID=166308, itemType=U.Cate.TOY}, -- [为了血神！]
        {itemID=200178, itemType=U.Cate.TOY}, -- [僵化药水]
    }

HT.ToolRandomMorphCallbak = function ()
    return function ()
        local item = HT.RandomChooseItem(MorphItemTable)
        local result = HtItem.CallbackByItem(item.itemID, item.itemType)
        result.text = L["Random Morph"]
        return result
    end
end

