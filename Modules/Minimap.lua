-- Minimap.lua
local _, Leatrix_Plus = ...
local LeaPlusLC = Leatrix_Plus.LC
local LeaPlusCB = Leatrix_Plus.CB
local LeaLockList = Leatrix_Plus.LockList
local L = Leatrix_Plus.L

local Module = {}
Leatrix_Plus:RegisterModule("Minimap", Module)

local function SetupMinimapBase()
    MinimapCluster:EnableMouse(false)
    Minimap:Raise()
end

local function SetupMinimapControls()
    Minimap:EnableMouseWheel(true)
    Minimap:SetScript("OnMouseWheel", function(self, delta)
        local zoom = self:GetZoom()
        local maxZoom = self:GetZoomLevels() - 1
        if delta > 0 and zoom < maxZoom then
            if MinimapZoomOut then MinimapZoomOut:Enable() end
            self:SetZoom(zoom + 1)
            if self:GetZoom() == maxZoom and MinimapZoomIn then
                MinimapZoomIn:Disable()
            end
        elseif delta < 0 and zoom > 0 then
            if MinimapZoomIn then MinimapZoomIn:Enable() end
            self:SetZoom(zoom - 1)
            if self:GetZoom() == 0 and MinimapZoomOut then
                MinimapZoomOut:Disable()
            end
        end
    end)

    if not LeaPlusLC["MinimapPositionCaptured"] then
        local point, _, relativePoint, x, y = MinimapCluster:GetPoint()
        LeaPlusLC["MinimapA"] = point or "TOPRIGHT"
        LeaPlusLC["MinimapR"] = relativePoint or "TOPRIGHT"
        LeaPlusLC["MinimapX"] = x or 0
        LeaPlusLC["MinimapY"] = y or 0
        LeaPlusLC["MinimapPositionCaptured"] = true
    end

    MinimapCluster:SetMovable(true)
    MinimapCluster:SetUserPlaced(true)
    MinimapCluster:SetDontSavePosition(true)
    MinimapCluster:SetClampedToScreen(true)

    MinimapCluster:ClearAllPoints()
    MinimapCluster:SetPoint(
        LeaPlusLC["MinimapA"] or "TOPRIGHT",
        UIParent,
        LeaPlusLC["MinimapR"] or "TOPRIGHT",
        LeaPlusLC["MinimapX"] or 0,
        LeaPlusLC["MinimapY"] or 0
    )

    local isMovingMinimap = false
    Minimap:RegisterForDrag("LeftButton")
    Minimap:SetScript("OnDragStart", function(_, btn)
        if InCombatLockdown() then return end
        if IsAltKeyDown() and btn == "LeftButton" then
            isMovingMinimap = true
            MinimapCluster:StartMoving()
        end
    end)
    Minimap:SetScript("OnDragStop", function()
        if isMovingMinimap then
            isMovingMinimap = false
            MinimapCluster:StopMovingOrSizing()
            local a, _, r, x, y = MinimapCluster:GetPoint()
            LeaPlusLC["MinimapA"], LeaPlusLC["MinimapR"] = a, r
            LeaPlusLC["MinimapX"], LeaPlusLC["MinimapY"] = x, y
            LeaPlusLC["MinimapPositionCaptured"] = true
        end
    end)
end

local function SetupMinimapVisibility()
    if LeaPlusLC["HideMiniZoneText"] == "On" then
        if MinimapBorderTop then
            MinimapBorderTop:Hide()
            hooksecurefunc(MinimapBorderTop, "Show", MinimapBorderTop.Hide)
        end
        if MinimapZoneTextButton then
            MinimapZoneTextButton:Hide()
            hooksecurefunc(MinimapZoneTextButton, "Show", MinimapZoneTextButton.Hide)
        end
    end

    if LeaPlusLC["HideMiniZoomBtns"] == "On" then
        if MinimapZoomIn then
            MinimapZoomIn:Hide()
            hooksecurefunc(MinimapZoomIn, "Show", MinimapZoomIn.Hide)
        end
        if MinimapZoomOut then
            MinimapZoomOut:Hide()
            hooksecurefunc(MinimapZoomOut, "Show", MinimapZoomOut.Hide)
        end
    end

    if LeaPlusLC["HideMiniMapButton"] == "On" and MiniMapWorldMapButton then
        MiniMapWorldMapButton:Hide()
        hooksecurefunc(MiniMapWorldMapButton, "Show", MiniMapWorldMapButton.Hide)
    end

    if LeaPlusLC["HideMiniTracking"] == "On" and MiniMapTracking then
        MiniMapTracking:Hide()
        hooksecurefunc(MiniMapTracking, "Show", MiniMapTracking.Hide)
        Minimap:HookScript("OnMouseUp", function(_, button)
            if button == "RightButton" and MiniMapTrackingDropDown then
                ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, "cursor", -3, -3)
            end
        end)
    end

    if LeaPlusLC["HideMiniCalendar"] == "On" and GameTimeFrame then
        GameTimeFrame:Hide()
        hooksecurefunc(GameTimeFrame, "Show", GameTimeFrame.Hide)
        Minimap:HookScript("OnMouseUp", function(_, button)
            if button == "MiddleButton" and IsShiftKeyDown() and GameTimeFrame_OnClick then
                GameTimeFrame_OnClick(GameTimeFrame)
            end
        end)
    end

    local function InitClockMouseover()
        if not TimeManagerClockButton then return end
        if LeaPlusLC["ClockMouseover"] == "On" then
            TimeManagerClockButton:SetAlpha(0)
        else
            TimeManagerClockButton:SetAlpha(1)
        end
        if not TimeManagerClockButton.__leaClockHooked then
            TimeManagerClockButton.__leaClockHooked = true
            local function ShowClock()
                if LeaPlusLC["ClockMouseover"] == "On" then
                    TimeManagerClockButton:SetAlpha(1)
                end
            end
            local function HideClock()
                if LeaPlusLC["ClockMouseover"] == "On" then
                    if not MouseIsOver(Minimap) and not MouseIsOver(TimeManagerClockButton) then
                        TimeManagerClockButton:SetAlpha(0)
                    end
                end
            end
            Minimap:HookScript("OnEnter", ShowClock)
            Minimap:HookScript("OnLeave", HideClock)
            TimeManagerClockButton:HookScript("OnEnter", ShowClock)
            TimeManagerClockButton:HookScript("OnLeave", HideClock)
        end
    end

    if TimeManagerClockButton then
        InitClockMouseover()
    else
        local clockWatcher = CreateFrame("Frame")
        clockWatcher:RegisterEvent("ADDON_LOADED")
        clockWatcher:SetScript("OnEvent", function(self, _, addon)
            if addon == "Blizzard_TimeManager" then
                InitClockMouseover()
                self:UnregisterAllEvents()
            end
        end)
    end

    if LeaPlusCB["ClockMouseover"] then
        LeaPlusCB["ClockMouseover"]:HookScript("OnClick", function(self)
            if TimeManagerClockButton then
                TimeManagerClockButton:SetAlpha(self:GetChecked() and 0 or 1)
            end
        end)
    end

    local function UpdatePOIArrows()
        if LeaPlusLC["HideMiniPOIArrows"] == "On" then
            Minimap:SetStaticPOIArrowTexture("Interface\\AddOns\\Leatrix_Plus\\Assets\\ROTATING-MINIMAPARROW")
        else
            Minimap:SetStaticPOIArrowTexture("Interface\\Minimap\\Rotating-MinimapArrow")
        end
    end

    UpdatePOIArrows()

    if LeaPlusCB["HideMiniPOIArrows"] then
        LeaPlusCB["HideMiniPOIArrows"]:HookScript("OnClick", UpdatePOIArrows)
    end

    local poiFrame = CreateFrame("Frame")
    poiFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    poiFrame:SetScript("OnEvent", UpdatePOIArrows)
end

local function SetupWhoPinged()
    local pFrame = CreateFrame("Frame", nil, Minimap)
    pFrame:SetSize(100, 20)
    pFrame:SetFrameStrata("TOOLTIP")
    pFrame:SetFrameLevel(100)
    pFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    pFrame:SetBackdropColor(0, 0, 0, 0.75)
    pFrame:SetBackdropBorderColor(0, 0, 0, 0)
    pFrame:Hide()

    pFrame.t = pFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    pFrame.t:SetPoint("CENTER", pFrame, "CENTER", 0, 0)

    pFrame.lastX = nil
    pFrame.lastY = nil

    local function Reposition()
        pFrame:ClearAllPoints()
        local mode = LeaPlusLC["ShowWhoPingedMode"] or 1

        if mode == 3 and pFrame.lastX and pFrame.lastY then
            local mapW = Minimap:GetWidth() or 140
            local mapH = Minimap:GetHeight() or 140
            local halfW = mapW / 2
            local halfH = mapH / 2
            local x = pFrame.lastX * mapW
            local y = pFrame.lastY * mapH
            local xOff = math.max(-halfW + 20, math.min(halfW - 20, x))
            local yOff = math.max(-halfH + 12, math.min(halfH - 12, y))
            pFrame:SetPoint("CENTER", Minimap, "CENTER", xOff, yOff)
        elseif mode == 2 then
            pFrame:SetPoint("TOP", Minimap, "TOP", 0, -4)
        else
            pFrame:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, 6)
        end
    end

    LeaPlusLC.RepositionShowWhoPinged = Reposition

    local lastUnit = nil
    local lastTime = 0

    pFrame:SetScript("OnEvent", function(_, _, unit, pingX, pingY)
        if not unit then return end
        local now = GetTime()
        if unit == lastUnit and (now - lastTime < 1.0) then return end
        lastUnit = unit
        lastTime = now

        pFrame.lastX = pingX
        pFrame.lastY = pingY

        local _, unitClass = UnitClass(unit)
        local color = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[unitClass]) or (unitClass and RAID_CLASS_COLORS[unitClass]) or NORMAL_FONT_COLOR
        local name = UnitName(unit) or "Unknown"

        local maxLen = LeaPlusLC["ShowWhoPingedTruncate"] or 6
        if strlenutf8 and strlenutf8(name) > maxLen then
            local b = 1
            local chars = 0
            while b <= #name and chars < maxLen do
                local c = string.byte(name, b)
                if c >= 240 then b = b + 4
                elseif c >= 224 then b = b + 3
                elseif c >= 192 then b = b + 2
                else b = b + 1 end
                chars = chars + 1
            end
            name = string.sub(name, 1, b - 1) .. "..."
        elseif #name > maxLen then
            name = string.sub(name, 1, maxLen) .. "..."
        end

        pFrame.t:SetFormattedText("|cff%02x%02x%02x%s|r",
            math.floor(color.r * 255),
            math.floor(color.g * 255),
            math.floor(color.b * 255),
            name)
        pFrame:SetWidth(math.max(pFrame.t:GetStringWidth() + 14, 40))
        Reposition()
        pFrame:Show()

        LibCompat.After(3, function()
            if GetTime() - lastTime >= 2.9 then
                pFrame:Hide()
            end
        end)
    end)

    local function SetPingFunc()
        if LeaPlusLC["ShowWhoPinged"] == "On" then
            pFrame:RegisterEvent("MINIMAP_PING")
        else
            pFrame:UnregisterEvent("MINIMAP_PING")
            pFrame:Hide()
        end
    end

    if LeaPlusCB["ShowWhoPinged"] then
        LeaPlusCB["ShowWhoPinged"]:HookScript("OnClick", SetPingFunc)
    end
    SetPingFunc()
end

local function SetupMinimapPanel()
    local SideMinimap = LeaPlusLC:CreatePanel("Enhance Minimap", "SideMinimap")
    LeaPlusLC:MakeTx(SideMinimap, "Settings", 16, -72)

    LeaPlusLC:MakeCB(SideMinimap, "HideMiniZoomBtns", "Hide Zoom Buttons", 16, -92, true, "Hides the zoom in and zoom out buttons.")
    LeaPlusLC:MakeCB(SideMinimap, "HideMiniZoneText", "Hide Zone Text Bar", 16, -112, true, "Hides the top zone text header bar.")
    LeaPlusLC:MakeCB(SideMinimap, "HideMiniMapButton", "Hide World Map Button", 16, -132, true, "Hides the world map globe icon.")
    LeaPlusLC:MakeCB(SideMinimap, "HideMiniTracking", "Hide Tracking Button", 16, -152, true, "Hides the tracking icon and opens the tracking menu by Right-Clicking the minimap.")

    LeaPlusLC:MakeCB(SideMinimap, "ShowWhoPinged", "Show Who Pinged", 16, -192, false,
        "Displays the class-colored character name of group members who ping the minimap.")

    local PingPanel = LeaPlusLC:CreatePanel("Show Who Pinged", "PingPanel")
    LeaPlusLC:MakeTx(PingPanel, "Settings", 16, -72)
    local pingModeDrop = LeaPlusLC:CreateDropDown("ShowWhoPingedMode", "Ping Label Position", PingPanel, 146, "TOPLEFT", 16, -145,
        { "Bottom of minimap", "Top of minimap", "At ping location" },
        "Where the pinged player name appears.")

    pingModeDrop.OnSelect = function()
        if LeaPlusLC.RepositionShowWhoPinged then
            LeaPlusLC.RepositionShowWhoPinged()
        end
    end

    LeaPlusLC:MakeTx(PingPanel, "Name length", 16, -165)
    LeaPlusLC:MakeSL(PingPanel, "ShowWhoPingedTruncate",
        "Maximum characters shown for the pinged player name.",
        1, 8, 1, 16, -185, "%.0f")

    PingPanel.h:Hide()
    PingPanel.b:SetScript("OnClick", function()
        PingPanel:Hide()
        SideMinimap:Show()
    end)
    PingPanel.r:SetScript("OnClick", function()
        LeaPlusLC["ShowWhoPingedMode"] = 1
        LeaPlusLC["ShowWhoPingedTruncate"] = 6
        if LeaPlusLC.RepositionShowWhoPinged then
            LeaPlusLC.RepositionShowWhoPinged()
        end
        PingPanel:Hide()
        PingPanel:Show()
    end)

    LeaPlusLC:CfgBtn("ShowWhoPingedBtn", LeaPlusCB["ShowWhoPinged"])
    if LeaPlusCB["ShowWhoPingedBtn"] then
        LeaPlusCB["ShowWhoPingedBtn"]:SetScript("OnClick", function()
            SideMinimap:Hide()
            PingPanel:Show()
        end)
    end

    LeaPlusLC:MakeCB(SideMinimap, "HideMiniCalendar", "Hide Calendar Button", 226, -92, true, "Hides the calendar icon and opens the calendar by Shift + Middle-Clicking the minimap.")
    LeaPlusLC:MakeCB(SideMinimap, "ClockMouseover", "Show Clock on Mouseover", 226, -112, false, "Keeps the minimap clock hidden until hovering over the minimap or clock.")
    LeaPlusLC:MakeCB(SideMinimap, "HideMiniPOIArrows", "Hide POI Arrows", 226, -132, false, "Hides edge quest and point-of-interest tracking arrows on the minimap.")

    LeaPlusLC:MakeTx(SideMinimap, "Scale", 406, -72)
    LeaPlusLC:MakeSL(SideMinimap, "MinimapScale", "Scale of the minimap.", 0.5, 2.0, 0.05, 406, -92, "%.2f")

    if LeaPlusCB["MinimapScale"] then
        LeaPlusCB["MinimapScale"]:HookScript("OnValueChanged", function(_, val)
            MinimapCluster:SetScale(val)
        end)
    end

    SideMinimap.h.tiptext = "Alt-drag the minimap to move it.  Right-click the minimap to open the tracking menu."

    SideMinimap.h:Hide()
    SideMinimap.b:SetScript("OnClick", function()
        SideMinimap:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page5"]:Show()
    end)
    SideMinimap.r:SetScript("OnClick", function()
        LeaPlusLC["MinimapA"] = nil
        LeaPlusLC["MinimapR"] = nil
        LeaPlusLC["MinimapX"] = nil
        LeaPlusLC["MinimapY"] = nil
        LeaPlusLC["MinimapPositionCaptured"] = nil

        LeaPlusLC["HideMiniZoomBtns"] = "Off"
        LeaPlusLC["HideMiniZoneText"] = "Off"
        LeaPlusLC["HideMiniMapButton"] = "On"
        LeaPlusLC["HideMiniTracking"] = "Off"
        LeaPlusLC["HideMiniCalendar"] = "Off"
        LeaPlusLC["ClockMouseover"] = "Off"
        LeaPlusLC["HideMiniPOIArrows"] = "Off"
        LeaPlusLC["ShowWhoPinged"] = "On"
        LeaPlusLC["ShowWhoPingedMode"] = 1
        LeaPlusLC["ShowWhoPingedTruncate"] = 6
        LeaPlusLC["MinimapScale"] = 1

        ReloadUI()
    end)

    if LeaPlusCB["ModMinimapBtn"] then
        LeaPlusCB["ModMinimapBtn"]:SetScript("OnClick", function()
            SideMinimap:Show(); LeaPlusLC:HideFrames()
        end)
    end
end

function Module:OnEnable()
    SetupMinimapPanel()

    if LeaPlusLC["MinimapModder"] == "On" and not LeaLockList["MinimapModder"] then
        SetupMinimapBase()
        SetupMinimapControls()
        SetupMinimapVisibility()
        SetupWhoPinged()

        if MinimapCluster and LeaPlusLC["MinimapScale"] then
            MinimapCluster:SetScale(LeaPlusLC["MinimapScale"])
        end
    end
end

function Module:OnLogin() end
function Module:OnLogout(wipeData) end