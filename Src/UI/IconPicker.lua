local addonName = ...
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale("HappyButton")

---@class GUI: AceModule
local GUI = addon:GetModule("GUI")

local CreateFrame = CreateFrame
local UIParent = UIParent
local GameTooltip = GameTooltip
local OKAY, CANCEL = OKAY, CANCEL
local math_max, math_min, math_ceil, math_floor = math.max, math.min, math.ceil, math.floor
local tinsert = table.insert

-------------------------------------------------------------------------------
-- 布局常量
-------------------------------------------------------------------------------
local ICON_COLS    = 10
local ICON_SIZE    = 36
local ICON_PAD     = 4
local ROW_H        = ICON_SIZE + ICON_PAD   -- 40
local VISIBLE_ROWS = 8
local GRID_W       = ICON_COLS * (ICON_SIZE + ICON_PAD) -- 400 (含最后一列右侧间距)
local SCROLL_W     = 12
local SCROLL_GAP   = 6
local H_PAD        = 10
local V_PAD        = 8
local TITLE_H      = 32
local PREVIEW_SZ   = 52
local FIRST_ROW_H  = PREVIEW_SZ + V_PAD * 2
local GRID_H       = VISIBLE_ROWS * ROW_H   -- 320
local FOOTER_H     = 44
local FRAME_W      = H_PAD + GRID_W + SCROLL_GAP + SCROLL_W + H_PAD  -- 448
local FRAME_H      = TITLE_H + V_PAD + FIRST_ROW_H + V_PAD + GRID_H + V_PAD + FOOTER_H  -- 488

-------------------------------------------------------------------------------
-- 模块级状态（单例）
-------------------------------------------------------------------------------
local pickerFrame      = nil     -- 全局单例 Frame
local btnPool          = {}      -- 图标按钮池
local filteredIcons    = {}      -- 当前过滤后的图标 fileID 列表
local scrollRow        = 0       -- 当前可视区顶行索引（0-based）
local selectedId       = nil     -- 当前选中的图标 fileID
local onSelectCallback = nil     -- 选择确认时的回调
local iconCache        = {}      -- [filterType] -> { fileID, ... }
local curFilter        = "all"   -- 当前类型过滤："all" / "spell" / "item"

-------------------------------------------------------------------------------
-- 图标数据:复用 WoW 原生 IconDataProviderMixin
-------------------------------------------------------------------------------
local function GetIconList(filterType)
    if iconCache[filterType] then return iconCache[filterType] end

    local types
    if filterType == "spell" then
        types = { IconDataProviderIconType.Spell }
    elseif filterType == "item" then
        types = { IconDataProviderIconType.Item }
    else
        types = IconDataProvider_GetAllIconTypes()
    end

    local provider = CreateAndInitFromMixin(IconDataProviderMixin, nil, false, types)
    local t = {}
    for i = 1, provider:GetNumIcons() do
        t[i] = provider:GetIconByIndex(i)
    end
    iconCache[filterType] = t
    return t
end

-------------------------------------------------------------------------------
-- 网格刷新
-------------------------------------------------------------------------------
local function GetMaxScroll()
    return math_max(0, math_ceil(#filteredIcons / ICON_COLS) - VISIBLE_ROWS)
end

local function UpdateGrid()
    local base = scrollRow * ICON_COLS
    for i, btn in ipairs(btnPool) do
        local id = filteredIcons[base + i]
        if id then
            btn:SetNormalTexture(id)
            local nt = btn:GetNormalTexture()
            if nt then nt:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
            btn:Show()
            btn.iconId = id
            btn.selOverlay:SetShown(id == selectedId)
        else
            btn:Hide()
            btn.iconId = nil
            btn.selOverlay:Hide()
        end
    end
    -- 更新滚动条
    if pickerFrame then
        local maxS = GetMaxScroll()
        pickerFrame.scrollSlider:SetMinMaxValues(0, maxS)
        pickerFrame.scrollSlider:SetValue(scrollRow)
        pickerFrame.scrollTrack:SetShown(maxS > 0)
    end
end

local function DoScroll(delta)
    local max = GetMaxScroll()
    scrollRow = math_max(0, math_min(scrollRow + delta, max))
    UpdateGrid()
end

-------------------------------------------------------------------------------
-- 创建选择器主 Frame（懒创建，只执行一次）
-------------------------------------------------------------------------------
local function CreatePickerFrame()
    local f = CreateFrame("Frame", "HbIconPickerFrame", UIParent)
    f:SetSize(FRAME_W, FRAME_H)
    f:SetPoint("CENTER")
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(250)
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:Hide()

    -- 应用 HappyButton 统一皮肤背景
    GUI:StyleFrame(f, true)

    -- 可拖动
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    f:EnableMouseWheel(true)
    f:SetScript("OnMouseWheel", function(_, delta) DoScroll(-delta) end)

    -- ── 标题 ──────────────────────────────────────────────────────
    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(GUI.Fonts.header, GUI.Fonts.size_title, "OUTLINE")
    title:SetShadowColor(0, 0, 0, 1)
    title:SetShadowOffset(1, -1)
    title:SetPoint("TOP", f, "TOP", 0, -8)
    title:SetTextColor(unpack(GUI.Colors.text_highlight))
    title:SetText(L["Icon Picker"])

    -- 关闭按钮
    local closeBtn = GUI:CreateCloseButton(f, function() f:Hide() end)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 2, 2)

    -- ── 第一行：预览图标 + 类型过滤 Tab ──────────────────────────
    local ROW1_Y = -(TITLE_H + V_PAD)

    -- 预览大图标按钮
    local previewBtn = CreateFrame("Button", nil, f)
    previewBtn:SetSize(PREVIEW_SZ, PREVIEW_SZ)
    previewBtn:SetPoint("TOPLEFT", f, "TOPLEFT", H_PAD, ROW1_Y)
    previewBtn:SetNormalTexture(134400)
    local pnt = previewBtn:GetNormalTexture()
    if pnt then pnt:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    GUI:CreateBackdrop(previewBtn, false)
    f.previewBtn = previewBtn

    -- 类型过滤 Tab 按钮：全部 / 技能 / 物品
    local TAB_W = 62
    local TAB_H = 24
    local TAB_GAP = 5
    local tabFilters = {
        { key = "all",   label = L["All"] },
        { key = "spell", label = L["Spell"] },
        { key = "item",  label = L["Item"] },
    }
    local filterBtns = {}
    f.filterBtns = filterBtns

    for i, fd in ipairs(tabFilters) do
        local tb = CreateFrame("Button", nil, f)
        tb:SetSize(TAB_W, TAB_H)
        tb:SetPoint("TOPLEFT", f, "TOPLEFT",
            H_PAD + PREVIEW_SZ + 8 + (i - 1) * (TAB_W + TAB_GAP),
            ROW1_Y)
        GUI:CreateBackdrop(tb, false)

        local tbFS = tb:CreateFontString(nil, "OVERLAY")
        tbFS:SetFont(GUI.Fonts.normal, GUI.Fonts.size_normal)
        tbFS:SetAllPoints()
        tbFS:SetJustifyH("CENTER")
        tbFS:SetJustifyV("MIDDLE")
        tbFS:SetText(fd.label)
        tbFS:SetTextColor(unpack(GUI.Colors.text))
        tb.textFS = tbFS
        tb.filterKey = fd.key

        tb:SetScript("OnEnter", function(self)
            if GUI.isSkinEnabled and self.backdrop then
                GUI:SetBorderColor(self.backdrop, unpack(GUI.Colors.border_highlight))
            end
        end)
        tb:SetScript("OnLeave", function(self)
            if GUI.isSkinEnabled and self.backdrop and self.filterKey ~= curFilter then
                GUI:SetBorderColor(self.backdrop, unpack(GUI.Colors.border))
            end
        end)
        tb:SetScript("OnClick", function(self)
            -- 中文注释：切换类型过滤时重建列表并刷新网格。
            curFilter = self.filterKey
            filteredIcons = GetIconList(curFilter)
            scrollRow = 0
            UpdateGrid()
            for _, fb in ipairs(filterBtns) do
                local active = fb.filterKey == curFilter
                fb.textFS:SetTextColor(unpack(active and GUI.Colors.text_highlight or GUI.Colors.text))
                if GUI.isSkinEnabled and fb.backdrop then
                    GUI:SetBorderColor(fb.backdrop,
                        unpack(active and GUI.Colors.border_highlight or GUI.Colors.border))
                end
            end
        end)
        filterBtns[i] = tb
    end

    -- ── 图标网格区 ────────────────────────────────────────────────
    local GRID_Y = ROW1_Y - FIRST_ROW_H - V_PAD

    -- 网格背景（仅视觉用）
    local gridBg = CreateFrame("Frame", nil, f)
    gridBg:SetSize(GRID_W, GRID_H)
    gridBg:SetPoint("TOPLEFT", f, "TOPLEFT", H_PAD, GRID_Y)
    gridBg:EnableMouseWheel(true)
    gridBg:SetScript("OnMouseWheel", function(_, delta) DoScroll(-delta) end)
    GUI:CreateBackdrop(gridBg, false)

    -- 滚动条轨道
    local scrollTrack = CreateFrame("Frame", nil, f, "BackdropTemplate")
    scrollTrack:SetSize(SCROLL_W, GRID_H)
    scrollTrack:SetPoint("TOPLEFT", f, "TOPLEFT", H_PAD + GRID_W + SCROLL_GAP, GRID_Y)
    scrollTrack:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    scrollTrack:SetBackdropColor(0.10, 0.10, 0.12, 0.5)
    scrollTrack:Hide()
    f.scrollTrack = scrollTrack

    -- 滚动条 Slider
    local slider = CreateFrame("Slider", nil, scrollTrack)
    slider:SetAllPoints()
    slider:SetOrientation("VERTICAL")
    slider:SetMinMaxValues(0, 1)
    slider:SetValueStep(1)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    slider:SetValue(0)
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\WHITE8x8")
    thumb:SetVertexColor(0.4, 0.4, 0.5, 0.9)
    thumb:SetWidth(SCROLL_W)
    thumb:SetHeight(40)
    slider:SetThumbTexture(thumb)
    slider:SetScript("OnValueChanged", function(_, val)
        local r = math_floor(val + 0.5)
        if r ~= scrollRow then
            scrollRow = r
            UpdateGrid()
        end
    end)
    f.scrollSlider = slider

    -- 图标按钮池（ICON_COLS × VISIBLE_ROWS，直接复用不销毁）
    for row = 0, VISIBLE_ROWS - 1 do
        for col = 0, ICON_COLS - 1 do
            local btn = CreateFrame("Button", nil, f)
            btn:SetSize(ICON_SIZE, ICON_SIZE)
            btn:SetPoint("TOPLEFT", f, "TOPLEFT",
                H_PAD + col * (ICON_SIZE + ICON_PAD),
                GRID_Y - row * ROW_H)

            btn:SetNormalTexture(134400)
            local nt = btn:GetNormalTexture()
            if nt then nt:SetTexCoord(0.08, 0.92, 0.08, 0.92) end

            -- 悬停高亮
            local hl = btn:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetColorTexture(1, 1, 1, 0.25)

            -- 选中高亮
            local sel = btn:CreateTexture(nil, "OVERLAY")
            sel:SetAllPoints()
            sel:SetColorTexture(0, 0.6, 1, 0.45)
            sel:Hide()
            btn.selOverlay = sel
            btn.iconId = nil

            btn:SetScript("OnClick", function(self)
                if not self.iconId then return end
                selectedId = self.iconId
                -- 更新预览图标
                f.previewBtn:SetNormalTexture(selectedId)
                local pnt2 = f.previewBtn:GetNormalTexture()
                if pnt2 then pnt2:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
                UpdateGrid()
            end)
            btn:SetScript("OnEnter", function(self)
                if self.iconId then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(tostring(self.iconId), 1, 1, 1)
                    GameTooltip:Show()
                end
            end)
            btn:SetScript("OnLeave", function(self)
                if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
            end)
            tinsert(btnPool, btn)
        end
    end

    -- ── 底部按钮 ──────────────────────────────────────────────────
    local cancelBtn = GUI:CreateButton(f, CANCEL, 80, 28)
    cancelBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -H_PAD, V_PAD)
    cancelBtn:SetScript("OnClick", function() f:Hide() end)

    local okayBtn = GUI:CreateButton(f, OKAY, 80, 28)
    okayBtn:SetPoint("RIGHT", cancelBtn, "LEFT", -6, 0)
    okayBtn:SetScript("OnClick", function()
        f:Hide()
        if onSelectCallback and selectedId then
            onSelectCallback({ icon = selectedId })
        end
    end)

    return f
end

-------------------------------------------------------------------------------
-- GUI:OpenIconPicker(callback, options)
--   callback  : function(sel) → sel.icon = fileID
--   options   : { icon = currentFileID }
-------------------------------------------------------------------------------
function GUI:OpenIconPicker(callback, options)
    -- 中文注释：首次调用时懒创建选择器，后续直接复用同一 Frame，避免重复建立按钮池。
    if not pickerFrame then
        pickerFrame = CreatePickerFrame()
    end

    onSelectCallback = callback
    local opt = options or {}
    selectedId = opt.icon and tonumber(opt.icon) or nil

    -- 重置到"全部"过滤
    curFilter = "all"
    filteredIcons = GetIconList("all")
    scrollRow = 0

    -- 同步过滤 Tab 高亮状态
    for _, fb in ipairs(pickerFrame.filterBtns) do
        local active = fb.filterKey == "all"
        fb.textFS:SetTextColor(unpack(active and GUI.Colors.text_highlight or GUI.Colors.text))
        if GUI.isSkinEnabled and fb.backdrop then
            GUI:SetBorderColor(fb.backdrop,
                unpack(active and GUI.Colors.border_highlight or GUI.Colors.border))
        end
    end

    -- 更新预览按钮
    local dispIcon = selectedId or 134400
    pickerFrame.previewBtn:SetNormalTexture(dispIcon)
    local pnt = pickerFrame.previewBtn:GetNormalTexture()
    if pnt then pnt:SetTexCoord(0.08, 0.92, 0.08, 0.92) end

    -- 尝试滚动到当前选中图标所在行（居中显示）
    if selectedId then
        for i, id in ipairs(filteredIcons) do
            if id == selectedId then
                local row = math_floor((i - 1) / ICON_COLS)
                scrollRow = math_max(0, row - math_floor(VISIBLE_ROWS / 2))
                break
            end
        end
    end

    UpdateGrid()

    pickerFrame:ClearAllPoints()
    pickerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    pickerFrame:Show()
    pickerFrame:Raise()
end
