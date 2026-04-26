local addonName, _ = ... ---@type string, table
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale("HappyButton")

---@class Utils: AceModule
local U = addon:GetModule('Utils')

---@class GUI: AceModule
local GUI = addon:NewModule("GUI")

-- Cache
local ipairs, unpack, type, tinsert, wipe = ipairs, unpack, type, table.insert, wipe
local CreateFrame = CreateFrame
local UIParent = UIParent
local GetPhysicalScreenSize = GetPhysicalScreenSize
local C_Timer = C_Timer
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local math_abs = math.abs
local string_gsub = string.gsub

-- Skin detection: flat style when ElvUI or NDui is loaded
local _IsAddOnLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
GUI.isSkinEnabled = _IsAddOnLoaded("ElvUI") or _IsAddOnLoaded("NDui")

-------------------------------------------------------------------------------
-- Skin Provider: lazy-resolved references to ElvUI / NDui skinning APIs
-- Call GUI:GetSkinProvider() to get a table: { SetBD, ReskinClose, Reskin, ... }
-- Returns nil if no skin addon is available.
-------------------------------------------------------------------------------
local skinProvider -- cached

function GUI:GetSkinProvider()
    if skinProvider ~= nil then return skinProvider end

    -- NDui: _G.NDui[1] is the B (base) module
    -- NDui B methods are mixin-style: self = target frame (e.g. function B:Reskin() → self is button)
    -- So direct references work: pcall(sp.Reskin, btn) → B.Reskin(btn) → self=btn ✓
    local NDui = _G.NDui
    if NDui then
        local B = NDui[1]
        if B then
            skinProvider = {
                name = "NDui",
                SetBD            = B.SetBD,
                StripTextures    = B.StripTextures,
                ReskinClose      = B.ReskinClose,
                Reskin           = B.Reskin,
                ReskinCheck      = B.ReskinCheck,
                ReskinEditBox    = B.ReskinEditBox,
                ReskinScroll     = B.ReskinTrimScroll or B.ReskinScroll,
                ReskinDropDown   = B.ReskinDropDown,
                CreateBDFrame    = B.CreateBDFrame,
            }
            return skinProvider
        end
    end

    -- ElvUI: unpack(_G.ElvUI) → E, E:GetModule("Skins") → S
    if _G.ElvUI then
        local ok, E = pcall(unpack, _G.ElvUI)
        if ok and E then
            local S = E:GetModule("Skins", true)
            if S then
                skinProvider = {
                    name = "ElvUI",
                    E = E,
                    S = S,
                    -- ElvUI methods are called with : (self) on S or on frame
                    SetBD = function(frame)
                        if frame.SetTemplate then
                            frame:SetTemplate("Transparent")
                        end
                    end,
                    StripTextures = function(frame)
                        if frame.StripTextures then frame:StripTextures() end
                    end,
                    ReskinClose = function(btn, parent, xOff, yOff)
                        if S.HandleCloseButton then
                            pcall(S.HandleCloseButton, S, btn)
                        end
                    end,
                    Reskin = function(btn)
                        if S.HandleButton then
                            pcall(S.HandleButton, S, btn)
                        end
                    end,
                    ReskinEditBox = function(editBox)
                        if S.HandleEditBox then
                            pcall(S.HandleEditBox, S, editBox)
                        end
                    end,
                    ReskinScroll = function(scrollBar)
                        if S.HandleScrollBar then
                            pcall(S.HandleScrollBar, S, scrollBar)
                        end
                    end,
                    ReskinDropDown = function(dropdown)
                        if S.HandleDropDownBox then
                            pcall(S.HandleDropDownBox, S, dropdown)
                        end
                    end,
                    CreateBDFrame = function(frame)
                        if frame.CreateBackdrop then
                            frame:CreateBackdrop("Transparent")
                        end
                    end,
                }
                return skinProvider
            end
        end
    end

    skinProvider = false -- mark as resolved (no provider)
    return nil
end

-------------------------------------------------------------------------------
-- Pixel Scaling
-------------------------------------------------------------------------------
GUI.PixelObjects = {}

function GUI:UpdatePixelScale()
    local _, height = GetPhysicalScreenSize()
    local scale = UIParent:GetEffectiveScale()
    if height and height > 0 then
        GUI.mult = 768 / height / scale
    else
        GUI.mult = 1
    end
    for _, obj in ipairs(GUI.PixelObjects) do
        if obj.UpdatePixelScale then
            obj:UpdatePixelScale()
        end
    end
end

GUI:UpdatePixelScale()

local pixelFrame = CreateFrame("Frame")
pixelFrame:RegisterEvent("UI_SCALE_CHANGED")
pixelFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
pixelFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
pixelFrame:SetScript("OnEvent", function()
    C_Timer.After(0.1, function() GUI:UpdatePixelScale() end)
end)

-------------------------------------------------------------------------------
-- Colors & Fonts
-------------------------------------------------------------------------------
GUI.Colors = {
    bg           = {0.10, 0.10, 0.10, 0.80},
    nav          = {0.06, 0.06, 0.06, 0.40},
    header       = {0.06, 0.06, 0.06, 0.50},
    border       = {0, 0, 0, 1},
    border_highlight = {0, 0.6, 1, 1},
    shadow       = {0, 0, 0, 0.8},
    text         = {0.9, 0.9, 0.9, 1},
    text_highlight   = {1, 0.82, 0, 1},
    button       = {0.20, 0.20, 0.20, 1},
    button_hover = {0.30, 0.30, 0.30, 1},
    button_active= {0.40, 0.40, 0.40, 1},
    disabled     = {0.5, 0.5, 0.5, 1},
    enabled      = {0, 0.6, 1, 1},
    selected     = {0, 0.6, 1, 0.20},
}

GUI.Fonts = {
    normal = STANDARD_TEXT_FONT,
    header = STANDARD_TEXT_FONT,
    size_normal = 13,
    size_header = 15,
    size_title  = 18,
}

-- Cache class color
do
    local r, g, b, a = U:GetPlayerClassColor()
    GUI.Colors.class = { r, g, b, a }
end

GUI.Colors_Hex = {}
for k, v in pairs(GUI.Colors) do
    GUI.Colors_Hex[k] = CreateColor(unpack(v)):GenerateHexColor()
end

-------------------------------------------------------------------------------
-- Basic Creators
-------------------------------------------------------------------------------

function GUI:CreateText(parent, text, fontSize, justifyH)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    local size = fontSize or GUI.Fonts.size_normal
    if size >= GUI.Fonts.size_header then
        fs:SetFont(GUI.Fonts.header, size, "OUTLINE")
        fs:SetShadowColor(0, 0, 0, 1)
        fs:SetShadowOffset(1, -1)
    else
        fs:SetFont(GUI.Fonts.normal, size)
        fs:SetShadowColor(0, 0, 0, 1)
        fs:SetShadowOffset(1, -1)
    end
    if justifyH then fs:SetJustifyH(justifyH) end
    if text then fs:SetText(text) end
    fs:SetTextColor(unpack(GUI.Colors.text))
    return fs
end

-- VGroup: vertical label-on-top wrapper
-- Wraps an existing widget with a label above it.
-- Returns a container frame with .label, .widget, SetValue, GetValue proxied.
---@param help string | nil 可选帮助说明（鼠标悬停问号显示 tooltip）
function GUI:VGroup(parent, label, widget, help)
    local LABEL_H = 18
    local container = CreateFrame("Frame", nil, parent)

    local lbl = GUI:CreateText(container, label, GUI.Fonts.size_normal)
    lbl:SetPoint("TOPLEFT", 0, 0)
    lbl:SetTextColor(unpack(GUI.Colors.text))
    container.label = lbl

    -- 可选帮助问号：统一在组件层处理，避免业务代码重复创建。
    if help and help ~= "" then
        local helpBtn = CreateFrame("Button", nil, container, "BackdropTemplate")
        helpBtn:SetSize(16, 16)
        helpBtn:SetPoint("LEFT", lbl, "RIGHT", 4, 0)

        if GUI.isSkinEnabled then
            helpBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
            helpBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
            GUI:CreateBorder(helpBtn, unpack(GUI.Colors.border))
        else
            helpBtn:SetBackdrop({
                bgFile  = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 3, right = 3, top = 3, bottom = 3 },
            })
            helpBtn:SetBackdropColor(0, 0, 0, 0.7)
            helpBtn:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
        end

        local helpText = helpBtn:CreateFontString(nil, "OVERLAY")
        helpText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
        helpText:SetPoint("CENTER")
        helpText:SetText("?")
        helpText:SetTextColor(1, 0.82, 0, 1)

        helpBtn:SetScript("OnEnter", function(self)
            if GUI.isSkinEnabled then
                GUI:SetBorderColor(self, unpack(GUI.Colors.border_highlight))
            end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(help, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        helpBtn:SetScript("OnLeave", function(self)
            if GUI.isSkinEnabled then
                GUI:SetBorderColor(self, unpack(GUI.Colors.border))
            end
            if GameTooltip:IsOwned(self) then
                GameTooltip:Hide()
            end
        end)
        helpBtn:SetScript("OnHide", function(self)
            if GameTooltip:IsOwned(self) then
                GameTooltip:Hide()
            end
        end)

        container.helpBtn = helpBtn
    end

    widget:SetParent(container)
    widget:ClearAllPoints()
    widget:SetPoint("TOPLEFT", 0, -LABEL_H)

    local ww = widget:GetWidth()
    local wh = widget:GetHeight()
    container:SetSize(ww, LABEL_H + wh)

    -- Proxy common methods from inner widget
    container.widget = widget
    if widget.SetValue then container.SetValue = function(_, ...) widget:SetValue(...) end end
    if widget.GetValue then container.GetValue = function() return widget:GetValue() end end
    if widget.editbox then container.editbox = widget.editbox end
    if widget.dropdown then container.dropdown = widget.dropdown end
    return container
end

function GUI:CreateTexture(parent, texture, width, height, layer, isAtlas)
    local tex = parent:CreateTexture(nil, layer or "ARTWORK")
    if width and height then
        tex:SetSize(width, height)
    elseif width then
        tex:SetWidth(width)
    elseif height then
        tex:SetHeight(height)
    end
    if texture then
        if isAtlas then
            tex:SetAtlas(texture)
        else
            tex:SetTexture(texture)
        end
    end
    return tex
end

-------------------------------------------------------------------------------
-- Backdrop / Border / Shadow
-------------------------------------------------------------------------------

function GUI:CreateBackdrop(frame, shadow)
    if not frame.backdrop then
        frame.backdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        frame.backdrop:SetAllPoints()
        frame.backdrop:SetFrameLevel(math_max(0, frame:GetFrameLevel() - 1))
    end

    if GUI.isSkinEnabled then
        frame.backdrop:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        frame.backdrop:SetBackdropColor(unpack(GUI.Colors.bg))
        GUI:CreateBorder(frame.backdrop, unpack(GUI.Colors.border))
    else
        frame.backdrop:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        frame.backdrop:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        frame.backdrop:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    end

    if shadow ~= false and GUI.isSkinEnabled then
        GUI:CreateShadow(frame)
    end
end

function GUI:CreateNativeBackdrop(frame)
    local bg = CreateFrame("Frame", nil, frame, "NineSlicePanelTemplate")
    bg:SetAllPoints()
    bg:SetFrameLevel(math_max(0, frame:GetFrameLevel() - 5))
    NineSliceUtil.ApplyLayoutByName(bg, "ButtonFrameTemplateNoPortrait")

    local tex = bg:CreateTexture(nil, "BACKGROUND", nil, -7)
    tex:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock")
    tex:SetPoint("TOPLEFT", bg, "TOPLEFT", 6, -2)
    tex:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -2, 2)
    tex:SetHorizTile(true)
    tex:SetVertTile(true)

    frame.nativeBg = bg
end

function GUI:StyleFrame(frame, shadow)
    local sp = GUI:GetSkinProvider()
    if sp then
        -- Strip existing textures, then use our own backdrop (not sp.SetBD)
        -- This avoids NDui/ElvUI's semi-transparent backdrop
        if sp.StripTextures then pcall(sp.StripTextures, frame) end
        GUI:CreateBackdrop(frame, shadow)
    elseif GUI.isSkinEnabled then
        -- Skin addon detected but no API available, fallback to manual flat style
        GUI:CreateBackdrop(frame, shadow)
    else
        GUI:CreateNativeBackdrop(frame)
    end
end

function GUI:CreateShadow(frame)
    if frame.shadow then return end
    local s = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    s:SetPoint("TOPLEFT", -3, 3)
    s:SetPoint("BOTTOMRIGHT", 3, -3)
    s:SetFrameLevel(math_max(0, frame:GetFrameLevel() - 2))
    s:SetBackdrop({
        bgFile = nil,
        edgeFile = "Interface\\GLUES\\Common\\TextPanel-GenericBorder",
        edgeSize = 4,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    s:SetBackdropBorderColor(0, 0, 0, 0.6)
    frame.shadow = s
end

function GUI:CreateBorder(f, r, g, b, a)
    if f.borders then return end
    f.borders = {}

    local top = f:CreateTexture(nil, "OVERLAY")
    top:SetTexture("Interface\\Buttons\\WHITE8x8")
    top:SetPoint("TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", 0, 0)

    local bottom = f:CreateTexture(nil, "OVERLAY")
    bottom:SetTexture("Interface\\Buttons\\WHITE8x8")
    bottom:SetPoint("BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", 0, 0)

    local left = f:CreateTexture(nil, "OVERLAY")
    left:SetTexture("Interface\\Buttons\\WHITE8x8")
    left:SetPoint("TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", 0, 0)

    local right = f:CreateTexture(nil, "OVERLAY")
    right:SetTexture("Interface\\Buttons\\WHITE8x8")
    right:SetPoint("TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", 0, 0)

    f.borders = {top, bottom, left, right}

    function f:UpdatePixelScale()
        local m = GUI.mult or 1
        top:SetHeight(m)
        bottom:SetHeight(m)
        left:SetWidth(m)
        right:SetWidth(m)
    end

    tinsert(GUI.PixelObjects, f)
    f:UpdatePixelScale()
    GUI:SetBorderColor(f, r or 0, g or 0, b or 0, a or 1)
end

function GUI:SetBorderColor(f, r, g, b, a)
    if not f.borders then return end
    for _, tex in ipairs(f.borders) do
        tex:SetColorTexture(r, g, b, a)
    end
end

-------------------------------------------------------------------------------
-- Button
-------------------------------------------------------------------------------

function GUI:CreateButton(parent, text, width, height)
    width  = width  or 100
    height = height or 24

    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width, height)
    btn:SetText(text or "")

    -- Let skin addon restyle the button
    local sp = GUI:GetSkinProvider()
    if sp and sp.Reskin then
        pcall(sp.Reskin, btn)
    end

    return btn
end

-------------------------------------------------------------------------------
-- TabGroup
-- Creates a horizontal tab bar. Returns { frame, buttons, Select(key) }
-- tabs: array of { key, label }
-- item: { width, height, selected, onClick(key) }
-------------------------------------------------------------------------------
function GUI:CreateTabGroup(parent, tabs, item)
    local barW = item and item.width or 400
    local barH = item and item.height or 26
    local selected = item and item.selected
    local onClick = item and item.onClick
    local tabW = barW / #tabs

    local bar = CreateFrame("Frame", nil, parent)
    bar:SetSize(barW, barH)

    -- Bottom border
    local barLine = bar:CreateTexture(nil, "ARTWORK")
    barLine:SetHeight(1)
    barLine:SetPoint("BOTTOMLEFT", 0, 0)
    barLine:SetPoint("BOTTOMRIGHT", 0, 0)
    barLine:SetColorTexture(unpack(GUI.Colors.border))

    local buttons = {}
    for i, td in ipairs(tabs) do
        local btn = CreateFrame("Button", nil, bar)
        btn:SetSize(tabW, barH)
        btn:SetPoint("LEFT", bar, "LEFT", (i - 1) * tabW, 0)

        local fs = GUI:CreateText(btn, td.label, GUI.Fonts.size_normal)
        fs:SetPoint("CENTER")
        btn.text = fs

        local selBg = btn:CreateTexture(nil, "BACKGROUND")
        selBg:SetAllPoints()
        selBg:SetColorTexture(1, 0.82, 0, 0.15)
        selBg:Hide()
        btn.selBg = selBg

        local hoverBg = btn:CreateTexture(nil, "HIGHLIGHT")
        hoverBg:SetAllPoints()
        hoverBg:SetColorTexture(1, 1, 1, 0.05)

        btn.tabKey = td.key
        btn:SetScript("OnClick", function()
            if onClick then onClick(td.key) end
        end)

        buttons[i] = btn
    end

    local function Select(key)
        for _, btn in ipairs(buttons) do
            if btn.tabKey == key then
                btn.selBg:Show()
                btn.text:SetTextColor(unpack(GUI.Colors.text_highlight))
            else
                btn.selBg:Hide()
                btn.text:SetTextColor(unpack(GUI.Colors.text))
            end
        end
    end

    if selected then Select(selected) end

    local result = { frame = bar, buttons = buttons, Select = Select }
    bar:SetHeight(barH)
    bar:SetWidth(barW)
    return result
end

function GUI:CreateCloseButton(parent, onClick)
    local sp = GUI:GetSkinProvider()

    -- Always create a standard close button first
    local btn = CreateFrame("Button", nil, parent, "UIPanelCloseButton")
    if onClick then btn:SetScript("OnClick", onClick) end

    -- Let the skin addon restyle it
    if sp and sp.ReskinClose then
        pcall(sp.ReskinClose, btn)
    end

    return btn
end

-------------------------------------------------------------------------------
-- ScrollFrame (custom implementation with Slider-based scrollbar)
-------------------------------------------------------------------------------

-- Create a scrollable container.
-- Returns a table: { frame, content, scrollBar, scrollTrack, Refresh }
-- - frame: the outer container (anchor this)
-- - content: parent your widgets to this; set its height when content changes
-- - ScrollToTop(): reset scroll position
-- - Refresh(): recalculate scrollbar after content height changes
function GUI:CreateScrollFrame(parent)
    local SCROLL_TRACK_W = 6
    local SCROLL_STEP = 40

    -- Outer container
    local frame = CreateFrame("Frame", nil, parent)
    frame:EnableMouseWheel(true)

    -- Clip child: everything inside is clipped to the frame bounds
    local clipChild = CreateFrame("Frame", nil, frame)
    clipChild:SetClipsChildren(true)
    clipChild:SetPoint("TOPLEFT", 0, 0)
    clipChild:SetPoint("BOTTOMRIGHT", 0, 0)

    -- Content (caller parents widgets to this, sets height)
    local content = CreateFrame("Frame", nil, clipChild)
    content:SetPoint("TOPLEFT", 0, 0)
    content:SetWidth(frame:GetWidth())

    -- Scroll track (right side)
    local scrollTrack = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    scrollTrack:SetWidth(SCROLL_TRACK_W)
    scrollTrack:SetPoint("TOPRIGHT", 0, 0)
    scrollTrack:SetPoint("BOTTOMRIGHT", 0, 0)
    scrollTrack:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    scrollTrack:SetBackdropColor(0.12, 0.12, 0.15, 0.4)
    scrollTrack:Hide()

    -- Slider (scrollbar)
    local scrollBar = CreateFrame("Slider", nil, scrollTrack)
    scrollBar:SetAllPoints()
    scrollBar:SetOrientation("VERTICAL")
    scrollBar:SetMinMaxValues(0, 1)
    scrollBar:SetValueStep(1)
    if scrollBar.SetObeyStepOnDrag then scrollBar:SetObeyStepOnDrag(true) end
    scrollBar:SetValue(0)

    -- Thumb texture
    local thumb = scrollBar:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\WHITE8x8")
    thumb:SetVertexColor(0.40, 0.40, 0.45, 0.8)
    thumb:SetWidth(SCROLL_TRACK_W)
    thumb:SetHeight(40)
    scrollBar:SetThumbTexture(thumb)

    -- State
    local scrollOffset = 0

    local function GetMaxScroll()
        local contentH = content:GetHeight() or 0
        local frameH = frame:GetHeight() or 0
        return math_max(0, contentH - frameH)
    end

    local function ClampOffset()
        scrollOffset = math_max(0, math_min(scrollOffset, GetMaxScroll()))
    end

    local function UpdateContentPos()
        content:ClearAllPoints()
        content:SetPoint("TOPLEFT", 0, scrollOffset)
    end

    local function UpdateScrollBar()
        local maxScroll = GetMaxScroll()
        if maxScroll <= 0 then
            scrollTrack:Hide()
            return
        end
        scrollTrack:Show()
        scrollBar:SetMinMaxValues(0, maxScroll)
        scrollBar:SetValue(scrollOffset)

        -- Dynamic thumb size
        local frameH = frame:GetHeight() or 1
        local contentH = content:GetHeight() or 1
        if contentH > 0 and frameH > 0 then
            local thumbH = math_max(20, (frameH / contentH) * frameH)
            thumb:SetHeight(thumbH)
        end
    end

    scrollBar:SetScript("OnValueChanged", function(_, value)
        scrollOffset = math_floor(value + 0.5)
        ClampOffset()
        UpdateContentPos()
    end)

    frame:SetScript("OnMouseWheel", function(_, delta)
        scrollOffset = scrollOffset - delta * SCROLL_STEP
        ClampOffset()
        UpdateScrollBar()
        UpdateContentPos()
    end)

    -- Public methods on frame
    frame.content = content
    frame.scrollBar = scrollBar
    frame.scrollTrack = scrollTrack

    function frame:ScrollToTop()
        scrollOffset = 0
        UpdateScrollBar()
        UpdateContentPos()
    end

    function frame:Refresh()
        -- Update content width
        local fw = frame:GetWidth()
        local needsScroll = GetMaxScroll() > 0
        content:SetWidth(needsScroll and (fw - SCROLL_TRACK_W - 2) or fw)
        ClampOffset()
        UpdateScrollBar()
        UpdateContentPos()
    end

    -- Update on size change
    frame:SetScript("OnSizeChanged", function()
        local fw = frame:GetWidth()
        local needsScroll = GetMaxScroll() > 0
        content:SetWidth(needsScroll and (fw - SCROLL_TRACK_W - 2) or fw)
        ClampOffset()
        UpdateScrollBar()
        UpdateContentPos()
    end)

    return frame
end

-------------------------------------------------------------------------------
-- Divider
-------------------------------------------------------------------------------

function GUI:CreateDivider(parent, width, height, label, alignLeft)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width or 300, height or 20)

    if alignLeft then
        local text
        if label then
            text = GUI:CreateText(container, label, GUI.Fonts.size_normal)
            text:SetTextColor(unpack(GUI.Colors.text_highlight))
            text:SetPoint("LEFT", 0, 0)
        end
        local line = container:CreateTexture(nil, "ARTWORK")
        line:SetHeight(1)
        if text then
            line:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -2)
            line:SetPoint("RIGHT", container, "RIGHT", 0, 0)
        else
            line:SetPoint("LEFT", 0, 0); line:SetPoint("RIGHT", 0, 0)
        end
        line:SetColorTexture(1, 1, 1, 1)
        if line.SetGradient then
            line:SetGradient("HORIZONTAL", CreateColor(1, 0.82, 0, 1), CreateColor(1, 0.82, 0, 0))
        end
    else
        -- Centered text
        local text
        if label then
            text = GUI:CreateText(container, label, GUI.Fonts.size_normal)
            text:SetTextColor(unpack(GUI.Colors.text_highlight))
            text:SetPoint("CENTER", 0, 0)
        end

        -- Left gradient line (gold fading in from left → solid near text)
        local ll = container:CreateTexture(nil, "ARTWORK")
        ll:SetHeight(2)
        ll:SetPoint("LEFT", 0, 0)
        if text then
            ll:SetPoint("RIGHT", text, "LEFT", -8, 0)
        else
            ll:SetPoint("RIGHT", container, "CENTER", -2, 0)
        end
        ll:SetColorTexture(1, 0.82, 0, 1)
        if ll.SetGradient then
            ll:SetGradient("HORIZONTAL", CreateColor(1, 0.82, 0, 0), CreateColor(1, 0.82, 0, 0.8))
        end

        -- Right gradient line (solid near text → gold fading out to right)
        local rl = container:CreateTexture(nil, "ARTWORK")
        rl:SetHeight(2)
        if text then
            rl:SetPoint("LEFT", text, "RIGHT", 8, 0)
        else
            rl:SetPoint("LEFT", container, "CENTER", 2, 0)
        end
        rl:SetPoint("RIGHT", 0, 0)
        rl:SetColorTexture(1, 0.82, 0, 1)
        if rl.SetGradient then
            rl:SetGradient("HORIZONTAL", CreateColor(1, 0.82, 0, 0.8), CreateColor(1, 0.82, 0, 0))
        end
    end
    return container
end

-------------------------------------------------------------------------------
-- Keybinding
-------------------------------------------------------------------------------

local _keyCaptureFrame = nil

local function EnsureKeyCaptureFrame()
    if _keyCaptureFrame then
        return _keyCaptureFrame
    end
    local capture = CreateFrame("Frame", nil, UIParent)
    capture:SetAllPoints(UIParent)
    capture:SetFrameStrata("FULLSCREEN_DIALOG")
    capture:EnableMouse(false)
    capture:EnableKeyboard(false)
    capture:Hide()
    _keyCaptureFrame = capture

    return _keyCaptureFrame
end

function GUI:CreateKeybinding(parent, item)
    local width = item.width or 200
    local height = item.height or 26
    local emptyText = item.emptyText or "Bindkey"
    local cancelWidth = 70
    local gap = 8

    local container = CreateFrame("Frame", nil, parent)
    container:SetWidth(width + gap + cancelWidth)
    container:SetHeight(height)

    local btn = GUI:CreateButton(container, emptyText, width, height)
    btn:SetPoint("LEFT", container, "LEFT", 0, 0)

    local cancelText = (L and L["Cancel"]) or CANCEL or "Cancel"
    local cancelBtn = GUI:CreateButton(container, cancelText, cancelWidth, height)
    cancelBtn:SetPoint("LEFT", btn, "RIGHT", gap, 0)
    cancelBtn:Hide()
    local isCapturing = false

    local function getCurrentBinding()
        return item.get and item.get() or nil
    end

    local function refreshCancelButton()
        local key = getCurrentBinding()
        if isCapturing or (key and key ~= "") then
            cancelBtn:Show()
        else
            cancelBtn:Hide()
        end
    end

    local function refreshText()
        local key = getCurrentBinding()
        if key and key ~= "" then
            btn:SetText(key)
        else
            btn:SetText(emptyText)
        end
        refreshCancelButton()
    end

    local function stopCapture()
        local capture = _keyCaptureFrame
        if not capture then
            return
        end
        capture:SetScript("OnKeyDown", nil)
        capture:SetScript("OnMouseDown", nil)
        capture:EnableKeyboard(false)
        capture:EnableMouse(false)
        if capture.SetPropagateKeyboardInput then
            capture:SetPropagateKeyboardInput(true)
        end
        capture:Hide()
        isCapturing = false
        refreshCancelButton()
        if item.onCaptureEnd then
            item.onCaptureEnd(btn)
        end
    end

    local function cancelBinding()
        if item.set then item.set(nil) end
        stopCapture()
        refreshText()
    end

    btn:SetScript("OnClick", function()
        local capture = EnsureKeyCaptureFrame()

        isCapturing = true
        btn:SetText("|cffff8800...|r")
        refreshCancelButton()
        if item.onCaptureStart then
            item.onCaptureStart(btn)
        end

        capture:Show()
        capture:EnableMouse(true)
        capture:EnableKeyboard(true)
        if capture.SetPropagateKeyboardInput then
            capture:SetPropagateKeyboardInput(false)
        end

        capture:SetScript("OnMouseDown", function()
            stopCapture()
            refreshText()
        end)

        capture:SetScript("OnKeyDown", function(_, key)
            if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" then
                return
            end

            local bindStr = ""
            if IsShiftKeyDown() then bindStr = "SHIFT-" end
            if IsControlKeyDown() then bindStr = bindStr .. "CTRL-" end
            if IsAltKeyDown() then bindStr = bindStr .. "ALT-" end
            bindStr = bindStr .. key

            -- 先清除脚本防止重复触发，再延迟一帧后停止捕获
            -- 避免在 OnKeyDown 回调内重新开启 propagation 导致按键被游戏执行
            capture:SetScript("OnKeyDown", nil)
            if item.set then item.set(bindStr) end
            C_Timer.After(0, function()
                stopCapture()
                refreshText()
            end)
        end)
    end)

    cancelBtn:SetScript("OnClick", function()
        cancelBinding()
    end)

    container.RefreshBindingText = refreshText
    container.button = btn
    container.cancelButton = cancelBtn
    btn.RefreshBindingText = refreshText
    refreshText()
    return container
end

-------------------------------------------------------------------------------
-- Switch
-------------------------------------------------------------------------------

function GUI:CreateSwitch(parent, item)
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(26)

    local cb = CreateFrame("CheckButton", nil, container, "UICheckButtonTemplate")
    cb:SetSize(26, 26)
    cb:SetPoint("LEFT", 0, 0)

    local totalW = 26
    if item.label then
        local lbl = cb.text or _G[cb:GetName() and (cb:GetName() .. "Text") or ""]
        if not lbl then
            lbl = GUI:CreateText(container, item.label, GUI.Fonts.size_normal)
            lbl:SetPoint("LEFT", cb, "RIGHT", 4, 0)
            lbl:SetTextColor(unpack(GUI.Colors.text))
        else
            lbl:SetText(item.label)
            lbl:SetFontObject(GameFontNormal) -- use default WoW font
        end
        container.label = lbl
        totalW = 26 + 4 + (lbl.GetStringWidth and lbl:GetStringWidth() or 120)
    end
    container:SetWidth(totalW)

    local offValue = item.offValue ~= nil and item.offValue or false
    local onValue  = item.onValue  ~= nil and item.onValue  or true

    local function GetCurrentValue()
        if item.get then return item.get() end
        return cb:GetChecked() and onValue or offValue
    end

    local initial = GetCurrentValue()
    cb:SetChecked(initial == onValue)

    cb:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        local nv = checked and onValue or offValue
        if item.set then item.set(nv) end
        if item.onChange then item.onChange(self, nv) end
    end)

    -- Skin the checkbox if provider available
    local sp = GUI:GetSkinProvider()
    if sp and sp.ReskinCheck then
        pcall(sp.ReskinCheck, cb)
    end

    container.switch = cb
    container.SetValue = function(_, v)
        cb:SetChecked(v == onValue)
    end
    container.GetValue = function() return GetCurrentValue() end
    return container
end

-------------------------------------------------------------------------------
-- Input
-------------------------------------------------------------------------------

function GUI:CreateInput(parent, item)
    local width  = item.width  or 180
    local height = item.height or 26

    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(height)

    local editX = 0
    if item.label then
        local lbl = GUI:CreateText(container, item.label, GUI.Fonts.size_normal)
        lbl:SetPoint("LEFT", 0, 0)
        lbl:SetTextColor(unpack(GUI.Colors.text))
        container.label = lbl
        local lw = item.labelWidth or (lbl:GetStringWidth() + 8)
        lbl:SetWidth(lw)
        editX = lw
        container:SetWidth(lw + width)
    else
        container:SetWidth(width)
    end

    local eb = CreateFrame("EditBox", nil, container, "BackdropTemplate")
    eb:SetSize(width, height)
    eb:SetPoint("LEFT", editX, 0)
    eb:SetAutoFocus(false)
    eb:SetFont(GUI.Fonts.normal, GUI.Fonts.size_normal, "")
    eb:SetTextInsets(8, 8, 0, 0)
    eb:SetTextColor(unpack(GUI.Colors.text))

    local sp = GUI:GetSkinProvider()
    if sp and sp.ReskinEditBox then
        pcall(sp.ReskinEditBox, eb)
    elseif GUI.isSkinEnabled then
        eb:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        eb:SetBackdropColor(0.05, 0.05, 0.05, 1)
        GUI:CreateBorder(eb, unpack(GUI.Colors.border))
    else
        eb:SetBackdrop({
            bgFile  = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        eb:SetBackdropColor(0, 0, 0, 0.7)
        eb:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    end

    -- Parent to container (not eb) so EditBox doesn't eat mouse events
    local confirmBtn = GUI:CreateButton(container, OKAY, 50, height - 4)
    confirmBtn:SetPoint("RIGHT", eb, "RIGHT", -2, 0)
    confirmBtn:SetFrameStrata("TOOLTIP")
    confirmBtn:EnableMouse(true)
    confirmBtn:RegisterForClicks("AnyDown", "AnyUp")
    confirmBtn:Hide()

    local confirmed = false

    local function doConfirm()
        confirmed = true
        local text = eb:GetText()
        eb:ClearFocus()
        if item.set then item.set(text) end
        if item.onChange then item.onChange(eb, text) end
    end

    -- Use OnMouseDown instead of OnClick: OnMouseDown fires BEFORE
    -- the editbox loses focus, so `confirmed` is set before OnEditFocusLost runs.
    -- OnClick fires AFTER focus loss, by which time the button is already hidden.
    confirmBtn:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then doConfirm() end
    end)

    eb:SetScript("OnEditFocusGained", function(self)
        confirmed = false
        if GUI.isSkinEnabled then
            GUI:SetBorderColor(self, unpack(GUI.Colors.border_highlight))
        else
            self:SetBackdropBorderColor(unpack(GUI.Colors.border_highlight))
        end
        self:SetTextInsets(8, 58, 0, 0)
        confirmBtn:Show()
    end)
    eb:SetScript("OnEditFocusLost", function(self)
        if GUI.isSkinEnabled then
            GUI:SetBorderColor(self, unpack(GUI.Colors.border))
        else
            self:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
        end
        self:SetTextInsets(8, 8, 0, 0)
        -- Delay hide so that button's OnMouseDown/OnClick can fire first
        C_Timer.After(0.05, function()
            confirmBtn:Hide()
        end)
    end)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEnterPressed", doConfirm)

    if item.get then eb:SetText(item.get() or "") end

    container.editbox = eb
    container.SetValue = function(_, v) eb:SetText(v or "") end
    container.GetValue = function() return eb:GetText() end
    return container
end

-------------------------------------------------------------------------------
-- Icon Input
-------------------------------------------------------------------------------

local function BuildIconInputDisplayValue(iconValue, defaultIcon)
    local raw = iconValue and tostring(iconValue) or ""
    local icon = "|T" .. tostring(iconValue or defaultIcon or 134400) .. ":16|t"
    if raw ~= "" then
        return raw, icon .. " " .. raw
    end
    return raw, icon
end

---@param parent Frame
---@param item table
---@return Frame
function GUI:CreateIconInput(parent, item)
    local state = {
        raw = "",
        text = "",
    }

    local function syncDisplay(iconValue)
        state.raw, state.text = BuildIconInputDisplayValue(iconValue, item.defaultIcon)
    end

    local widget
    widget = GUI:CreateInput(parent, {
        label = item.label,
        labelWidth = item.labelWidth,
        width = item.width,
        height = item.height,
        get = function()
            local value = item.get and item.get() or nil
            syncDisplay(value)
            return state.text
        end,
        set = function(v)
            local raw = v or ""
            if raw == state.text then
                raw = state.raw or ""
            end
            raw = string_gsub(raw, "^|T.-|t%s*", "")
            raw = string_gsub(raw, "^%s+", "")
            raw = string_gsub(raw, "%s+$", "")

            local num = tonumber(raw)
            local normalized = num or (raw ~= "" and raw or nil)
            syncDisplay(normalized)

            if item.set then item.set(normalized, raw) end
            if item.onChangeValue then item.onChangeValue(normalized, raw) end

            if widget and widget.SetValue then
                widget:SetValue(state.text)
            end
        end,
    })

    widget.GetRawValue = function()
        return state.raw
    end

    return widget
end

-------------------------------------------------------------------------------
-- MultiLine Input (ScrollFrame + EditBox)
-------------------------------------------------------------------------------

--- Create a multiline text input with optional label above
---@param parent Frame
---@param item { label:string|nil, width:number|nil, height:number|nil, get:fun():string|nil, set:fun(v:string)|nil, validate:fun(v:string):boolean|string|nil }
---@return Frame container
function GUI:CreateMultiLineInput(parent, item)
    local width  = item.width  or 400
    local height = item.height or 180 -- ~10 lines

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, height)

    local labelH = 0
    if item.label then
        local lbl = GUI:CreateText(container, item.label, GUI.Fonts.size_normal)
        lbl:SetPoint("TOPLEFT", 0, 0)
        lbl:SetTextColor(unpack(GUI.Colors.text))
        container.label = lbl
        labelH = 18
    end

    -- Backdrop frame for the border
    local box = CreateFrame("Frame", nil, container, "BackdropTemplate")
    box:SetPoint("TOPLEFT", 0, -labelH)
    box:SetSize(width, height - labelH)

    local sp = GUI:GetSkinProvider()
    if sp and sp.CreateBDFrame then
        pcall(sp.CreateBDFrame, box, 0.05)
    elseif GUI.isSkinEnabled then
        box:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        box:SetBackdropColor(0.05, 0.05, 0.05, 1)
        GUI:CreateBorder(box, unpack(GUI.Colors.border))
    else
        box:SetBackdrop({
            bgFile  = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        box:SetBackdropColor(0, 0, 0, 0.7)
        box:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    end

    -- Use Blizzard InputScrollFrameTemplate: handles click-anywhere-to-focus,
    -- auto-scroll on cursor move, and proper content height management.
    local sf = CreateFrame("ScrollFrame", nil, box, "InputScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 4, -4)
    sf:SetPoint("BOTTOMRIGHT", -4, 4)

    -- Strip template's built-in border/background textures (we use our own backdrop)
    for _, region in pairs({sf:GetRegions()}) do
        if region:IsObjectType("Texture") then
            region:SetAlpha(0)
        end
    end

    -- Hide character count
    if sf.CharCount then sf.CharCount:Hide() end

    local eb = sf.EditBox
    eb:SetAutoFocus(false)
    eb:SetFont(GUI.Fonts.normal, GUI.Fonts.size_normal, "")
    eb:SetTextColor(unpack(GUI.Colors.text))
    eb:SetWidth(width - 18)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    -- Confirm button (inside box, bottom-right, shown on focus)
    local confirmBtn = GUI:CreateButton(box, OKAY, 60, 20)
    confirmBtn:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -4, 4)
    confirmBtn:Hide()

    local function doConfirm()
        eb:ClearFocus()
    end

    confirmBtn:SetScript("OnClick", doConfirm)

    eb:HookScript("OnEditFocusGained", function()
        if GUI.isSkinEnabled then
            GUI:SetBorderColor(box, unpack(GUI.Colors.border_highlight))
        else
            box:SetBackdropBorderColor(unpack(GUI.Colors.border_highlight))
        end
        confirmBtn:Show()
    end)
    eb:HookScript("OnEditFocusLost", function(self)
        if GUI.isSkinEnabled then
            GUI:SetBorderColor(box, unpack(GUI.Colors.border))
        else
            box:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
        end
        confirmBtn:Hide()
        local text = self:GetText()
        if item.validate then
            local ok = item.validate(text)
            if ok ~= true then return end
        end
        if item.set then item.set(text) end
    end)

    if item.get then eb:SetText(item.get() or "") end

    container.editbox = eb
    container.SetValue = function(_, v) eb:SetText(v or "") end
    container.GetValue = function() return eb:GetText() end
    return container
end

-------------------------------------------------------------------------------
-- Slider
-------------------------------------------------------------------------------

function GUI:CreateSlider(parent, item)
    local width  = item.width or 180
    local sliderH = 16
    local totalH  = 56

    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, totalH)

    if item.label then
        local lbl = GUI:CreateText(container, item.label, GUI.Fonts.size_normal)
        lbl:SetPoint("TOPLEFT", 0, 0)
        lbl:SetTextColor(unpack(GUI.Colors.text))
        container.label = lbl
    end

    local slider = CreateFrame("Slider", nil, container, "BackdropTemplate")
    slider:SetSize(width, sliderH)
    slider:SetPoint("BOTTOMLEFT", 0, 20)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(item.min or 0, item.max or 100)
    slider:SetValueStep(item.step or 1)
    slider:SetObeyStepOnDrag(true)

    if GUI.isSkinEnabled then
        slider:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        slider:SetBackdropColor(0.15, 0.15, 0.15, 1)
        GUI:CreateBorder(slider, unpack(GUI.Colors.border))
        local t = slider:CreateTexture(nil, "OVERLAY")
        t:SetSize(12, sliderH)
        t:SetColorTexture(unpack(GUI.Colors.border_highlight))
        slider:SetThumbTexture(t)
    else
        slider:SetBackdrop({
            bgFile   = "Interface\\Buttons\\UI-SliderBar-Background",
            edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 3, right = 3, top = 6, bottom = 6 },
        })
        slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    end

    -- 可直接输入数值的 EditBox（替代只读 valText）
    local ebW = 56
    local ebH = 16
    local eb
    if GUI.isSkinEnabled then
        eb = CreateFrame("EditBox", nil, container, "BackdropTemplate")
        eb:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        eb:SetBackdropColor(0.15, 0.15, 0.15, 1)
        GUI:CreateBorder(eb, unpack(GUI.Colors.border))
    else
        eb = CreateFrame("EditBox", nil, container, "InputBoxTemplate")
    end
    eb:SetSize(ebW, ebH)
    eb:SetPoint("TOP", slider, "BOTTOM", 0, -1)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(8)
    -- 允许输入负数（SetNumeric(true) 会吞掉负号，导致负值显示/输入异常）。
    eb:SetNumeric(false)
    eb:SetFont(GUI.Fonts.normal, GUI.Fonts.size_normal, "")
    eb:SetTextInsets(4, 4, 0, 0)
    eb:SetJustifyH("CENTER")
    eb:SetTextColor(unpack(GUI.Colors.text))

    eb:SetScript("OnEditFocusGained", function(self)
        if GUI.isSkinEnabled then
            GUI:SetBorderColor(self, unpack(GUI.Colors.border_highlight))
        end
    end)
    eb:SetScript("OnEditFocusLost", function(self)
        if GUI.isSkinEnabled then
            GUI:SetBorderColor(self, unpack(GUI.Colors.border))
        end
        -- 失焦时应用输入的值
        local v = tonumber(self:GetText())
        if v then
            local minV, maxV = slider:GetMinMaxValues()
            local step = item.step or 1
            v = math_max(minV, math_min(maxV, math_floor(v / step + 0.5) * step))
            slider:SetValue(v)
        else
            self:SetText(tostring(math_floor(slider:GetValue() + 0.5)))
        end
    end)
    eb:SetScript("OnEscapePressed", function(self)
        self:SetText(tostring(math_floor(slider:GetValue() + 0.5)))
        self:ClearFocus()
    end)
    eb:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    -- eb 顶部在 slider 底部偏移 -1，高度 ebH，故 eb 中心 y = -(1 + ebH/2)
    local ebCenterY = -(1 + ebH / 2)
    local minText = GUI:CreateText(container, tostring(item.min or 0), GUI.Fonts.size_normal - 3)
    minText:SetPoint("LEFT", slider, "BOTTOMLEFT", 0, ebCenterY)
    minText:SetTextColor(unpack(GUI.Colors.disabled))
    local maxText = GUI:CreateText(container, tostring(item.max or 100), GUI.Fonts.size_normal - 3)
    maxText:SetPoint("RIGHT", slider, "BOTTOMRIGHT", 0, ebCenterY)
    maxText:SetTextColor(unpack(GUI.Colors.disabled))

    slider:SetScript("OnValueChanged", function(_, value)
        value = math_floor(value + 0.5)
        eb:SetText(tostring(value))
        if item.set then item.set(value) end
        if item.onChange then item.onChange(slider, value) end
    end)

    if item.get then
        slider:SetValue(item.get() or item.min or 0)
    end

    container.slider = slider
    container.SetValue = function(_, v) slider:SetValue(v) end
    container.GetValue = function() return slider:GetValue() end
    return container
end

-------------------------------------------------------------------------------
-- Dropdown
-------------------------------------------------------------------------------

function GUI:OpenDropdown(anchor, options)
    MenuUtil.CreateContextMenu(anchor, function(_, rootDescription)
        for _, opt in ipairs(options) do
            local btn = rootDescription:CreateButton(opt.text, function()
                if opt.func then opt.func() end
            end)
            if opt.disabled then
                btn:SetEnabled(false)
            end
        end
    end)
end

-------------------------------------------------------------------------------
-- Custom Dropdown (self-drawn, no UIDropDownMenuTemplate)
-------------------------------------------------------------------------------
local _activeDropdownList = nil  -- track currently open dropdown list

local function CloseActiveDropdown()
    if _activeDropdownList then
        _activeDropdownList:Hide()
        _activeDropdownList = nil
    end
end

function GUI:CreateDropdown(parent, item)
    local width = item.width or 180
    local btnH = item.height or 26

    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(btnH)

    local ddX = 0
    if item.label then
        local lbl = GUI:CreateText(container, item.label, GUI.Fonts.size_normal)
        lbl:SetPoint("LEFT", 0, 0)
        lbl:SetTextColor(unpack(GUI.Colors.text))
        container.label = lbl
        local lw = item.labelWidth or (lbl:GetStringWidth() + 8)
        lbl:SetWidth(lw)
        ddX = lw
        container:SetWidth(lw + width)
    else
        container:SetWidth(width)
    end

    local selectedValue
    if item.get then
        selectedValue = item.get()
    else
        selectedValue = item.default
    end

    -- Main button (acts as the dropdown toggle)
    local btn = CreateFrame("Button", nil, container, "BackdropTemplate")
    btn:SetSize(width, btnH)
    btn:SetPoint("LEFT", ddX, 0)

    local sp = GUI:GetSkinProvider()

    if sp and sp.CreateBDFrame then
        pcall(sp.CreateBDFrame, btn, 0.05, true)
    elseif GUI.isSkinEnabled then
        btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        btn:SetBackdropColor(0.05, 0.05, 0.05, 1)
        GUI:CreateBorder(btn, unpack(GUI.Colors.border))
    else
        btn:SetBackdrop({
            bgFile  = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        btn:SetBackdropColor(0, 0, 0, 0.7)
        btn:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    end

    -- Selected text
    local text = btn:CreateFontString(nil, "OVERLAY")
    text:SetFont(GUI.Fonts.normal, GUI.Fonts.size_normal, "")
    text:SetPoint("LEFT", 8, 0)
    text:SetPoint("RIGHT", -20, 0)
    text:SetJustifyH("LEFT")
    text:SetTextColor(unpack(GUI.Colors.text))
    text:SetWordWrap(false)

    -- Arrow indicator
    local arrow = btn:CreateFontString(nil, "OVERLAY")
    arrow:SetFont(GUI.Fonts.normal, GUI.Fonts.size_normal, "")
    arrow:SetPoint("RIGHT", -6, 0)
    arrow:SetTextColor(0.7, 0.7, 0.7, 1)
    arrow:SetText("▼")

    -- Hover highlight
    btn:SetScript("OnEnter", function(self)
        if GUI.isSkinEnabled then
            if self.bg then self.bg:SetBackdropColor(0.15, 0.15, 0.15, 1) end
        else
            self:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
        end
        arrow:SetTextColor(1, 1, 1, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        if GUI.isSkinEnabled then
            if self.bg then self.bg:SetBackdropColor(0.05, 0.05, 0.05, 1) end
        else
            self:SetBackdropColor(0, 0, 0, 0.7)
        end
        arrow:SetTextColor(0.7, 0.7, 0.7, 1)
    end)

    -- Helper: resolve display text for a value
    local function getDisplayText(v)
        local opts = item.options
        if type(opts) == "function" then opts = opts() end
        if opts then
            for _, o in ipairs(opts) do
                if o.value == v then return o.text end
            end
        end
        return ""
    end

    -- Set initial text
    text:SetText(getDisplayText(selectedValue))

    -- Dropdown list (created on first click, reused)
    local listFrame = nil
    local optItemH = 22

    local function BuildList()
        if listFrame then listFrame:Hide() end

        local opts = item.options
        if type(opts) == "function" then opts = opts() end
        if not opts or #opts == 0 then return end

        local listH = #opts * optItemH + 4
        if not listFrame then
            listFrame = CreateFrame("Frame", nil, btn, "BackdropTemplate")
            listFrame:SetFrameStrata("FULLSCREEN_DIALOG")
            listFrame:SetClampedToScreen(true)

            if sp and sp.CreateBDFrame then
                pcall(sp.CreateBDFrame, listFrame, 0.9, true)
            elseif GUI.isSkinEnabled then
                listFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
                listFrame:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
                GUI:CreateBorder(listFrame, unpack(GUI.Colors.border))
            else
                listFrame:SetBackdrop({
                    bgFile  = "Interface\\Tooltips\\UI-Tooltip-Background",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true, tileSize = 16, edgeSize = 16,
                    insets = { left = 4, right = 4, top = 4, bottom = 4 },
                })
                listFrame:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
                listFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
            end
        end

        -- Clear old option buttons
        if listFrame.optBtns then
            for _, ob in ipairs(listFrame.optBtns) do ob:Hide() end
            wipe(listFrame.optBtns)
        else
            listFrame.optBtns = {}
        end

        listFrame:SetSize(width, listH)
        listFrame:ClearAllPoints()
        listFrame:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)

        for i, o in ipairs(opts) do
            local ob = CreateFrame("Button", nil, listFrame)
            ob:SetSize(width - 4, optItemH)
            ob:SetPoint("TOPLEFT", 2, -(i - 1) * optItemH - 2)

            local oText = ob:CreateFontString(nil, "OVERLAY")
            oText:SetFont(GUI.Fonts.normal, GUI.Fonts.size_normal, "")
            oText:SetPoint("LEFT", 8, 0)
            oText:SetPoint("RIGHT", -8, 0)
            oText:SetJustifyH("LEFT")
            oText:SetTextColor(unpack(GUI.Colors.text))
            oText:SetText(o.text)

            -- Highlight selected
            if o.value == selectedValue then
                oText:SetTextColor(unpack(GUI.Colors.text_highlight))
            end

            local hl = ob:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetTexture("Interface\\Buttons\\WHITE8x8")
            hl:SetVertexColor(1, 1, 1, 0.1)

            ob:SetScript("OnClick", function()
                selectedValue = o.value
                text:SetText(o.text)
                listFrame:Hide()
                _activeDropdownList = nil
                if item.set then item.set(o.value) end
                if item.onChange then item.onChange(container, o.value) end
            end)
            tinsert(listFrame.optBtns, ob)
        end

        -- Close when clicking outside
        listFrame:SetScript("OnShow", function(self)
            CloseActiveDropdown()
            _activeDropdownList = self
        end)

        listFrame:Show()
    end

    btn:SetScript("OnClick", function()
        if listFrame and listFrame:IsShown() then
            listFrame:Hide()
            _activeDropdownList = nil
        else
            BuildList()
        end
    end)

    container.dropdown = btn
    container.SetValue = function(_, v)
        selectedValue = v
        text:SetText(getDisplayText(v))
    end
    container.GetValue = function() return selectedValue end
    return container
end
