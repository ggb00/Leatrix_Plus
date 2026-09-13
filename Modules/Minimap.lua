-- Minimap.lua
local _, Leatrix_Plus = ...
local LeaPlusLC = Leatrix_Plus.LC
local LeaPlusCB = Leatrix_Plus.CB
local LeaPlusDB = _G.LeaPlusDB
local L = Leatrix_Plus.L

local Module = {}
Leatrix_Plus:RegisterModule("Minimap", Module)

----------------------------------------------------------------------
-- 1. Square Minimap & Element Styling
----------------------------------------------------------------------
local function SetupSquareMinimap()
    if LeaPlusLC["SquareMinimap"] ~= "On" then
        GetMinimapShape = function() return "ROUND" end
        Minimap:SetMaskTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
        return
    end

    GetMinimapShape = function() return "SQUARE" end
    Minimap:SetMaskTexture("Interface\\ChatFrame\\ChatFrameBackground")

    if MinimapBorder then MinimapBorder:Hide() end
    if MinimapNorthTag then
        hooksecurefunc(MinimapNorthTag, "Show", function(self) self:Hide() end)
        MinimapNorthTag:Hide()
    end

    -- Clean dark square border
    local border = CreateFrame("Frame", nil, Minimap)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetAlpha(0.8)
    border:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeSize = 3,
    })

    -- Position standard buttons for square layout
    if MiniMapTracking then
        MiniMapTracking:SetScale(0.75)
        MiniMapTracking:ClearAllPoints()
        MiniMapTracking:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -20, -40)
    end

    if MiniMapBattlefieldFrame then
        MiniMapBattlefieldFrame:SetScale(0.75)
        MiniMapBattlefieldFrame:ClearAllPoints()
        MiniMapBattlefieldFrame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 5, -5)
    end

    if MiniMapLFGFrame then
        MiniMapLFGFrame:SetScale(0.75)
        MiniMapLFGFrame:ClearAllPoints()
        MiniMapLFGFrame:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 5, 5)
    end

    if MinimapZoomIn then
        MinimapZoomIn:SetScale(0.75)
        MinimapZoomIn:ClearAllPoints()
        MinimapZoomIn:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 19, -120)
    end

    if MinimapZoomOut and MinimapZoomIn then
        MinimapZoomOut:SetScale(0.75)
        MinimapZoomOut:ClearAllPoints()
        MinimapZoomOut:SetPoint("TOP", MinimapZoomIn, "BOTTOM", 0, 0)
    end

    -- Mail icon styling
    if MiniMapMailFrame then
        MiniMapMailFrame:DisableDrawLayer("OVERLAY")
        local mailIcon = MiniMapMailFrame:GetRegions()
        if mailIcon and mailIcon.SetTexture then
            mailIcon:SetTexture("Interface\\Minimap\\TRACKING\\Mailbox")
        end
        MiniMapMailFrame:SetScale(1.1)
        MiniMapMailFrame:ClearAllPoints()
        MiniMapMailFrame:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", 19, 14)
    end

    -- Clock placement
    if TimeManagerClockButton then
        local regions = { TimeManagerClockButton:GetRegions() }
        if regions[1] then regions[1]:Hide() end
        TimeManagerClockButton:ClearAllPoints()
        TimeManagerClockButton:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 10, -6)
        TimeManagerClockButton:SetFrameLevel(100)
    end
end

----------------------------------------------------------------------
-- 2. Mousewheel Zoom & Drag Positioning
----------------------------------------------------------------------
local function SetupMinimapControls()
    -- Mousewheel zoom
    Minimap:EnableMouseWheel(true)
    Minimap:SetScript("OnMouseWheel", function(self, delta)
        local zoom = self:GetZoom()
        if delta > 0 and zoom < (self:GetZoomLevels() - 1) then
            self:SetZoom(zoom + 1)
        elseif delta < 0 and zoom > 0 then
            self:SetZoom(zoom - 1)
        end
    end)

    -- Alt-drag to move
    Minimap:SetMovable(true)
    Minimap:SetUserPlaced(true)
    Minimap:SetDontSavePosition(true)
    Minimap:SetClampedToScreen(true)
    Minimap:RegisterForDrag("LeftButton")

    Minimap:ClearAllPoints()
    Minimap:SetPoint(LeaPlusLC["MinimapA"] or "TOPRIGHT", UIParent, LeaPlusLC["MinimapR"] or "TOPRIGHT", LeaPlusLC["MinimapX"] or -17, LeaPlusLC["MinimapY"] or -22)

    Minimap:SetScript("OnDragStart", function(self, btn)
        if IsAltKeyDown() and btn == "LeftButton" then
            self:StartMoving()
        end
    end)

    Minimap:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local a, _, r, x, y = self:GetPoint()
        LeaPlusLC["MinimapA"], LeaPlusLC["MinimapR"], LeaPlusLC["MinimapX"], LeaPlusLC["MinimapY"] = a, r, x, y
        self:ClearAllPoints()
        self:SetPoint(a, UIParent, r, x, y)
    end)
end

----------------------------------------------------------------------
-- 3. Visibility Toggles
----------------------------------------------------------------------
local function SetupMinimapVisibility()
    if LeaPlusLC["HideMiniZoomBtns"] == "On" then
        if MinimapZoomIn then MinimapZoomIn:Hide() end
        if MinimapZoomOut then MinimapZoomOut:Hide() end
    end

    if LeaPlusLC["HideMiniZoneText"] == "On" then
        if MinimapBorderTop then MinimapBorderTop:Hide() end
        if MinimapZoneTextButton then MinimapZoneTextButton:Hide() end
    end

    if LeaPlusLC["HideMiniMapButton"] == "On" and MiniMapWorldMapButton then
        MiniMapWorldMapButton:Hide()
        hooksecurefunc(MiniMapWorldMapButton, "Show", MiniMapWorldMapButton.Hide)
    end

    if LeaPlusLC["HideMiniTracking"] == "On" and MiniMapTracking then
        MiniMapTracking:Hide()
        Minimap:HookScript("OnMouseUp", function(self, button)
            if button == "RightButton" and MiniMapTrackingDropDown then
                ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, "cursor", -3, -3)
            end
        end)
    end

    if LeaPlusLC["HideMiniCalendar"] == "On" and GameTimeFrame then
        GameTimeFrame:Hide()
        Minimap:HookScript("OnMouseUp", function(self, button)
            if button == "MiddleButton" and IsShiftKeyDown() and GameTimeFrame_OnClick then
                GameTimeFrame_OnClick(self)
            end
        end)
    end

    if LeaPlusLC["ClockMouseover"] == "On" and TimeManagerClockButton then
        TimeManagerClockButton:SetAlpha(0)
        Minimap:HookScript("OnEnter", function() TimeManagerClockButton:SetAlpha(1) end)
        Minimap:HookScript("OnLeave", function() TimeManagerClockButton:SetAlpha(0) end)
    end
end

----------------------------------------------------------------------
-- 4. Show Who Pinged (Fixed 3.3.5 Native Ping Handling)
----------------------------------------------------------------------
local function SetupWhoPinged()
    if LeaPlusLC["ShowWhoPinged"] ~= "On" then return end

    local pFrame = CreateFrame("Frame", nil, Minimap)
    pFrame:SetSize(100, 20)
    pFrame:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, 2)
    pFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    pFrame:SetBackdropColor(0, 0, 0, 0.7)
    pFrame:SetBackdropBorderColor(0, 0, 0, 0)
    pFrame:Hide()

    pFrame.t = pFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    pFrame.t:SetAllPoints()

    local lastUnit = nil
    local lastTime = 0

    pFrame:SetScript("OnEvent", function(self, event, unit)
        if not unit or UnitIsUnit(unit, "player") then return end
        local now = GetTime()

        -- Debounce repeated pings from the same unit within 1 second
        if unit == lastUnit and (now - lastTime < 1.0) then
            return
        end
        lastUnit = unit
        lastTime = now

        local _, unitClass = UnitClass(unit)
        local color = unitClass and RAID_CLASS_COLORS[unitClass] or NORMAL_FONT_COLOR
        local name = UnitName(unit) or "Unknown"

        pFrame.t:SetFormattedText("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, name)
        pFrame:SetWidth(pFrame.t:GetStringWidth() + 14)
        pFrame:Show()

        LibCompat.After(3, function()
            if GetTime() - lastTime >= 2.9 then
                pFrame:Hide()
            end
        end)
    end)

    pFrame:RegisterEvent("MINIMAP_PING")
end

----------------------------------------------------------------------
-- Lifecycle Hooks
----------------------------------------------------------------------
function Module:OnEnable()
    if LeaPlusLC["MinimapModder"] ~= "On" or LeaLockList["MinimapModder"] then return end

    SetupSquareMinimap()
    SetupMinimapControls()
    SetupMinimapVisibility()
    SetupWhoPinged()

    -- Apply initial scales
    if MinimapCluster and LeaPlusLC["MiniClusterScale"] then
        MinimapCluster:SetScale(LeaPlusLC["MiniClusterScale"])
    end
    if Minimap and LeaPlusLC["MinimapScale"] then
        Minimap:SetScale(LeaPlusLC["MinimapScale"])
    end
end

function Module:OnLogin()
    -- Re-check clock skin after Blizzard_TimeManager loads
    if IsAddOnLoaded("Blizzard_TimeManager") and LeaPlusLC["SquareMinimap"] == "On" then
        SetupSquareMinimap()
    end
end

function Module:OnLogout(wipeData)
    -- Positions continuously saved
end