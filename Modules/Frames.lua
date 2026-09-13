-- Frames.lua
local _, Leatrix_Plus = ...
local LeaPlusLC = Leatrix_Plus.LC
local LeaPlusCB = Leatrix_Plus.CB
local LeaLockList = Leatrix_Plus.LockList
local L = Leatrix_Plus.L

local Module = {}
Leatrix_Plus:RegisterModule("Frames", Module)

----------------------------------------------------------------------
-- 1. Helper: Create Move/Scale Frame Container
----------------------------------------------------------------------
local function CreateMover(name, realFrame, dbA, dbR, dbX, dbY, dbScale, defaultWidth, defaultHeight, titleText, snapW, snapH)
    local holder = CreateFrame("Frame", nil, UIParent)
    holder:SetPoint(LeaPlusLC[dbA], UIParent, LeaPlusLC[dbR], LeaPlusLC[dbX], LeaPlusLC[dbY])
    holder:SetSize(defaultWidth, defaultHeight)
    holder:SetMovable(true)
    holder:SetUserPlaced(true)
    holder:SetDontSavePosition(true)
    holder:SetClampedToScreen(false)

    realFrame:ClearAllPoints()
    realFrame:SetPoint("CENTER", holder, "CENTER", 0, 0)
    realFrame:SetScale(LeaPlusLC[dbScale] or 1)
    holder:SetScale(LeaPlusLC[dbScale] or 1)

    -- Overlay drag frame
    local drag = CreateFrame("Frame", nil, UIParent)
    drag:SetSize(defaultWidth, defaultHeight)
    drag:SetPoint("CENTER", holder, "CENTER", 0, 0)
    drag:SetScale(LeaPlusLC[dbScale] or 1)
    drag:SetFrameStrata("DIALOG")
    drag:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 0, edgeSize = 16,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    drag:SetBackdropColor(0.0, 0.5, 1.0, 0.5)
    drag:EnableMouse(true)
    drag:Hide()

    drag.f = drag:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    drag.f:SetPoint("CENTER", 0, 0)
    drag.f:SetText(titleText)

    drag:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" then
            holder:StartMoving()
        end
    end)

    drag:SetScript("OnMouseUp", function(self)
        holder:StopMovingOrSizing()
        local a, _, r, x, y = holder:GetPoint()
        LeaPlusLC[dbA], LeaPlusLC[dbR], LeaPlusLC[dbX], LeaPlusLC[dbY] = a, r, x, y
        holder:ClearAllPoints()
        holder:SetPoint(a, UIParent, r, x, y)
        drag:ClearAllPoints()
        drag:SetPoint("CENTER", holder, "CENTER", 0, 0)
    end)

    -- Snap-to-grid with RightButton
    drag:RegisterForDrag("RightButton")
    drag:HookScript("OnDragStart", function()
        drag:SetScript("OnUpdate", function()
            local scale, uiscale = drag:GetScale(), UIParent:GetScale()
            local xpos, ypos = GetCursorPosition()
            local grid = 10
            xpos = floor((xpos / scale / uiscale) / grid) * grid - (snapW or defaultWidth) / 2
            ypos = ceil((ypos / scale / uiscale) / grid) * grid + (snapH or defaultHeight) / 2
            holder:ClearAllPoints()
            holder:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", xpos, ypos)
        end)
    end)
    drag:HookScript("OnDragStop", function()
        drag:SetScript("OnUpdate", nil)
        drag:GetScript("OnMouseUp")(drag)
    end)

    return holder, drag
end

----------------------------------------------------------------------
-- 2. Player & Target Frame Movement (Taint-Safe)
----------------------------------------------------------------------
local function SetupUnitFrames()
    if LeaPlusLC["FrmEnabled"] ~= "On" or LeaLockList["FrmEnabled"] then return end

    local FrameTable = { DragPlayerFrame = PlayerFrame, DragTargetFrame = TargetFrame }
    LeaPlusDB["Frames"] = LeaPlusDB["Frames"] or {}

    for k, v in pairs(FrameTable) do
        local vf = v:GetName()
        LeaPlusDB["Frames"][vf] = LeaPlusDB["Frames"][vf] or {}
        LeaPlusDB["Frames"][vf]["Scale"] = LeaPlusDB["Frames"][vf]["Scale"] or 1.0
        v:SetScale(LeaPlusDB["Frames"][vf]["Scale"])
        v:SetMovable(true)
        v:SetUserPlaced(true)
        v:SetDontSavePosition(true)
        v:SetClampedToScreen(false)
    end

    -- Restore saved positions
    if LeaPlusDB["Frames"]["PlayerFrame"]["Point"] then
        local p = LeaPlusDB["Frames"]["PlayerFrame"]
        PlayerFrame:ClearAllPoints()
        PlayerFrame:SetPoint(p.Point, UIParent, p.Relative, p.XOffset, p.YOffset)
    end
    if LeaPlusDB["Frames"]["TargetFrame"]["Point"] then
        local p = LeaPlusDB["Frames"]["TargetFrame"]
        TargetFrame:ClearAllPoints()
        TargetFrame:SetPoint(p.Point, UIParent, p.Relative, p.XOffset, p.YOffset)
        if ComboFrame then
            ComboFrame:SetScale(LeaPlusDB["Frames"]["TargetFrame"]["Scale"] or 1.0)
        end
    end

    -- Out-of-combat vehicle art listener that does NOT taint PlayerFrame
    local vehWatcher = CreateFrame("Frame")
    vehWatcher:RegisterEvent("UNIT_ENTERED_VEHICLE")
    vehWatcher:RegisterEvent("UNIT_EXITED_VEHICLE")
    vehWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
    vehWatcher:SetScript("OnEvent", function(self, event, unit)
        if (event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE") and unit == "player" then
            if InCombatLockdown() then
                self.pending = true
            elseif PlayerFrame and PlayerFrame_UpdateArt then
                PlayerFrame_UpdateArt(PlayerFrame)
            end
        elseif event == "PLAYER_REGEN_ENABLED" and self.pending then
            self.pending = nil
            if PlayerFrame and PlayerFrame_UpdateArt then
                PlayerFrame_UpdateArt(PlayerFrame)
            end
        end
    end)
end

----------------------------------------------------------------------
-- 3. Class Colored Frames (3.3.5 Native Events & API)
----------------------------------------------------------------------
local function SetupClassColFrames()
    if LeaPlusLC["ClassColFrames"] ~= "On" or LeaLockList["ClassColFrames"] then return end

    local PlayFN = CreateFrame("Frame", nil, PlayerFrame)
    PlayFN:Hide()
    PlayFN:SetWidth(TargetFrameNameBackground:GetWidth())
    PlayFN:SetHeight(TargetFrameNameBackground:GetHeight())
    local _, _, _, x, y = TargetFrameNameBackground:GetPoint()
    PlayFN:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", -x, y)

    PlayFN.t = PlayFN:CreateTexture(nil, "BORDER")
    PlayFN.t:SetAllPoints()
    PlayFN.t:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-LevelBackground")

    local _, playerClass = UnitClass("player")
    local c = RAID_CLASS_COLORS[playerClass]
    if c then
        PlayFN.t:SetVertexColor(c.r, c.g, c.b)
    end

    local function TargetFrameCol()
        if UnitIsPlayer("target") then
            local _, targetClass = UnitClass("target")
            local tc = targetClass and RAID_CLASS_COLORS[targetClass]
            if tc then
                TargetFrameNameBackground:SetVertexColor(tc.r, tc.g, tc.b)
            end
        end
        if UnitIsPlayer("focus") and FocusFrameNameBackground then
            local _, focusClass = UnitClass("focus")
            local fc = focusClass and RAID_CLASS_COLORS[focusClass]
            if fc then
                FocusFrameNameBackground:SetVertexColor(fc.r, fc.g, fc.b)
            end
        end
    end

    local ColTar = CreateFrame("Frame")
    ColTar:SetScript("OnEvent", TargetFrameCol)

    local function SetClassColFrames()
        if LeaPlusLC["ClassColPlayer"] == "On" then
            PlayFN:Show()
        else
            PlayFN:Hide()
        end

        if LeaPlusLC["ClassColTarget"] == "On" then
            ColTar:RegisterEvent("PARTY_MEMBERS_CHANGED")
            ColTar:RegisterEvent("RAID_ROSTER_UPDATE")
            ColTar:RegisterEvent("PLAYER_TARGET_CHANGED")
            ColTar:RegisterEvent("PLAYER_FOCUS_CHANGED")
            ColTar:RegisterEvent("UNIT_FACTION")
            TargetFrameCol()
        else
            ColTar:UnregisterAllEvents()
            TargetFrame_CheckFaction(TargetFrame)
            if FocusFrame then TargetFrame_CheckFaction(FocusFrame) end
        end
    end

    LeaPlusCB["ClassColPlayer"]:HookScript("OnClick", SetClassColFrames)
    LeaPlusCB["ClassColTarget"]:HookScript("OnClick", SetClassColFrames)
    SetClassColFrames()
end

----------------------------------------------------------------------
-- 4. Managed Widgets, Buffs, Vehicles, Durability & Tracker
----------------------------------------------------------------------
local function SetupManagedContainers()
    -- Buffs
    if LeaPlusLC["ManageBuffs"] == "On" and not LeaLockList["ManageBuffs"] and ConsolidatedBuffs then
        CreateMover("Buffs", ConsolidatedBuffs, "BuffFrameA", "BuffFrameR", "BuffFrameX", "BuffFrameY", "BuffFrameScale", 280, 225, L["Buffs"])
        if BuffFrame then BuffFrame:SetScale(LeaPlusLC["BuffFrameScale"] or 1) end
    end

    -- Debuffs
    if LeaPlusLC["ManageDeBuffs"] == "On" and not LeaLockList["ManageDeBuffs"] and DebuffButton_UpdateAnchors then
        hooksecurefunc("DebuffButton_UpdateAnchors", function()
            local d1 = _G.DebuffButton1
            if d1 and not d1.__leaMoved then
                d1.__leaMoved = true
                d1:ClearAllPoints()
                d1:SetPoint(LeaPlusLC["DebuffButton1A"] or "TOPRIGHT", UIParent, LeaPlusLC["DebuffButton1R"] or "TOPRIGHT", LeaPlusLC["DebuffButton1X"] or -205, LeaPlusLC["DebuffButton1Y"] or -205)
                for i = 1, DEBUFF_MAX_DISPLAY do
                    local btn = _G["DebuffButton" .. i]
                    if btn then btn:SetScale(LeaPlusLC["DebuffButton1Scale"] or 1) end
                end
            end
        end)
    end

    -- Vehicle Seat Indicator
    if LeaPlusLC["ManageVehicle"] == "On" and not LeaLockList["ManageVehicle"] and VehicleSeatIndicator then
        CreateMover("Vehicle", VehicleSeatIndicator, "VehicleA", "VehicleR", "VehicleX", "VehicleY", "VehicleScale", 128, 128, L["Vehicle"])
    end

    -- World State Always Up (Widget)
    if LeaPlusLC["ManageWidget"] == "On" and not LeaLockList["ManageWidget"] and WorldStateAlwaysUpFrame then
        CreateMover("Widget", WorldStateAlwaysUpFrame, "WidgetA", "WidgetR", "WidgetX", "WidgetY", "WidgetScale", 160, 79, L["Widget"])
    end

    -- Focus Frame
    if LeaPlusLC["ManageFocus"] == "On" and not LeaLockList["ManageFocus"] and FocusFrame then
        CreateMover("Focus", FocusFrame, "FocusA", "FocusR", "FocusX", "FocusY", "FocusScale", 196, 76, L["Focus"])
    end

    -- Mirror Timer (Breath / Fatigue)
    if LeaPlusLC["ManageTimer"] == "On" and not LeaLockList["ManageTimer"] and MirrorTimer1 then
        CreateMover("Timer", MirrorTimer1, "TimerA", "TimerR", "TimerX", "TimerY", "TimerScale", 206, 20, L["Timer"])
    end

    -- Durability Figure
    if LeaPlusLC["ManageDurability"] == "On" and not LeaLockList["ManageDurability"] and DurabilityFrame then
        CreateMover("Durability", DurabilityFrame, "DurabilityA", "DurabilityR", "DurabilityX", "DurabilityY", "DurabilityScale", 92, 75, L["Durability"])
    end

    -- Quest WatchFrame (Tracker)
    if LeaPlusLC["ManageTracker"] == "On" and not LeaLockList["ManageTracker"] and WatchFrame then
        local top = WatchFrame:GetTop() or 0
        local screenHeight = GetScreenHeight()
        local watchHeight = min(screenHeight - (screenHeight - top), 800)
        WatchFrame:SetHeight(watchHeight)
        CreateMover("Tracker", WatchFrame, "TrackerA", "TrackerR", "TrackerX", "TrackerY", "TrackerScale", 92, 75, L["Tracker"])
    end
end

----------------------------------------------------------------------
-- 5. Cosmetic Toggles (Gryphons, Stance Bar, Alerts, Dragon Border)
----------------------------------------------------------------------
local function SetupCosmetics()
    -- Hide Main Bar Gryphons
    if LeaPlusLC["NoGryphons"] == "On" and not LeaLockList["NoGryphons"] then
        if MainMenuBarLeftEndCap then MainMenuBarLeftEndCap:Hide() end
        if MainMenuBarRightEndCap then MainMenuBarRightEndCap:Hide() end
    end

    -- Hide Stance Bar
    if LeaPlusLC["NoClassBar"] == "On" and not LeaLockList["NoClassBar"] and ShapeshiftBarFrame then
        local h = CreateFrame("Frame")
        h:Hide()
        ShapeshiftBarFrame:UnregisterAllEvents()
        ShapeshiftBarFrame:SetParent(h)
    end

    -- Hide Portrait Damage/Healing Indicators
    if LeaPlusLC["NoHitIndicators"] == "On" and not LeaLockList["NoHitIndicators"] then
        if PlayerHitIndicator then hooksecurefunc(PlayerHitIndicator, "Show", PlayerHitIndicator.Hide) end
        if PetHitIndicator then hooksecurefunc(PetHitIndicator, "Show", PetHitIndicator.Hide) end
    end

    -- Hide Achievement Alerts (and output clean link to chat instead)
    if LeaPlusLC["NoAlerts"] == "On" and AlertFrame then
        AlertFrame:UnregisterAllEvents()
        hooksecurefunc(AlertFrame, "RegisterEvent", function(self, event)
            self:UnregisterEvent(event)
        end)
        local aFrame = CreateFrame("Frame")
        aFrame:RegisterEvent("ACHIEVEMENT_EARNED")
        aFrame:SetScript("OnEvent", function(_, _, id)
            if id then
                local link = GetAchievementLink(id)
                if link then
                    LeaPlusLC:Print(string.format(NEW_ACHIEVEMENT_EARNED:gsub("'", ""), link))
                    PlaySound(12891)
                end
            end
        end)
    end

    -- Player Dragon Chain (Elite / Rare / Rare Elite Border)
    if LeaPlusLC["ShowPlayerChain"] == "On" and not LeaLockList["ShowPlayerChain"] and PlayerFrameTexture then
        if PetPortrait and PetPortrait:GetParent() then
            PetPortrait:GetParent():SetFrameLevel(4)
        end
        local function SetChain()
            local chain = LeaPlusLC["PlayerChainMenu"] or 2
            if chain == 1 then
                PlayerFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare.blp")
                PlayerFrameTexture:SetTexCoord(1, .09375, 0, .78125)
            elseif chain == 2 then
                PlayerFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Elite.blp")
                PlayerFrameTexture:SetTexCoord(1, .09375, 0, .78125)
            elseif chain == 3 then
                PlayerFrameTexture:SetTexture("Interface\\AddOns\\Leatrix_Plus\\Leatrix_Plus.blp")
                PlayerFrameTexture:SetTexCoord(0.25, 0.0234375, 0, 0.1953125)
            end
        end
        SetChain()
        if LeaPlusCB["ListFramePlayerChainMenu"] then
            LeaPlusCB["ListFramePlayerChainMenu"]:HookScript("OnHide", SetChain)
        end
    end
end

----------------------------------------------------------------------
-- Lifecycle Hooks
----------------------------------------------------------------------
function Module:OnEnable()
    SetupUnitFrames()
    SetupClassColFrames()
    SetupCosmetics()
end

function Module:OnLogin()
    SetupManagedContainers()
end

function Module:OnLogout(wipeData)
    -- Frame coordinates are continuously saved to LeaPlusDB["Frames"]
end