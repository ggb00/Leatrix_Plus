-- Frames.lua
local _, Leatrix_Plus = ...
local LeaPlusLC = Leatrix_Plus.LC
local LeaPlusCB = Leatrix_Plus.CB
local LeaLockList = Leatrix_Plus.LockList
local L = Leatrix_Plus.L

local Module = {}
Leatrix_Plus:RegisterModule("Frames", Module)

local GRID_SIZE = 16

local movers = {}
local grid
local gridRefCount = 0
local dragPlayer, dragTarget

local function SnapToGrid(value, size)
    return math.floor(value / size + 0.5) * size
end

local function BuildGridLines()
    if not grid then return end

    grid.lines = grid.lines or {}
    for _, line in ipairs(grid.lines) do
        line:Hide()
    end

    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    local lineIndex = 0

    for x = 0, screenWidth, GRID_SIZE do
        lineIndex = lineIndex + 1
        local line = grid.lines[lineIndex]
        if not line then
            line = grid:CreateTexture(nil, "BACKGROUND")
            line:SetTexture(0.6, 0.6, 0.6, 0.18)
            line:SetWidth(1)
            grid.lines[lineIndex] = line
        end
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", grid, "TOPLEFT", x, 0)
        line:SetPoint("BOTTOMLEFT", grid, "BOTTOMLEFT", x, 0)
        line:Show()
    end

    for y = 0, screenHeight, GRID_SIZE do
        lineIndex = lineIndex + 1
        local line = grid.lines[lineIndex]
        if not line then
            line = grid:CreateTexture(nil, "BACKGROUND")
            line:SetTexture(0.6, 0.6, 0.6, 0.18)
            line:SetHeight(1)
            grid.lines[lineIndex] = line
        end
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", grid, "TOPLEFT", 0, -y)
        line:SetPoint("TOPRIGHT", grid, "TOPRIGHT", 0, -y)
        line:Show()
    end
end

local function CreateGrid()
    if grid then return grid end

    grid = CreateFrame("Frame", "LeaPlus_Grid", UIParent)
    grid:SetAllPoints(UIParent)
    grid:SetFrameStrata("BACKGROUND")
    grid:EnableMouse(false)
    grid:Hide()

    local crossX = grid:CreateTexture(nil, "BACKGROUND")
    crossX:SetTexture(1, 0.82, 0, 0.35)
    crossX:SetPoint("TOP", grid, "TOP")
    crossX:SetPoint("BOTTOM", grid, "BOTTOM")
    crossX:SetWidth(1)

    local crossY = grid:CreateTexture(nil, "BACKGROUND")
    crossY:SetTexture(1, 0.82, 0, 0.35)
    crossY:SetPoint("LEFT", grid, "LEFT")
    crossY:SetPoint("RIGHT", grid, "RIGHT")
    crossY:SetHeight(1)

    grid:RegisterEvent("DISPLAY_SIZE_CHANGED")
    grid:RegisterEvent("UI_SCALE_CHANGED")
    grid:SetScript("OnEvent", BuildGridLines)

    BuildGridLines()
    return grid
end

local function AcquireGrid()
    gridRefCount = gridRefCount + 1
    if gridRefCount == 1 then
        CreateGrid():Show()
    end
end

local function ReleaseGrid()
    gridRefCount = gridRefCount - 1
    if gridRefCount <= 0 then
        gridRefCount = 0
        if grid then grid:Hide() end
    end
end

LeaPlusLC.AcquireGrid = AcquireGrid
LeaPlusLC.ReleaseGrid = ReleaseGrid

local function CreateMover(key, optKey, realFrame, dbA, dbR, dbX, dbY, dbScale, defaultWidth, defaultHeight, titleText)
    if not realFrame then return end

    local holder = CreateFrame("Frame", nil, UIParent)
    holder:SetPoint(LeaPlusLC[dbA] or "CENTER", UIParent, LeaPlusLC[dbR] or "CENTER", LeaPlusLC[dbX] or 0, LeaPlusLC[dbY] or 0)
    holder:SetSize(defaultWidth, defaultHeight)
    holder:SetMovable(true)
    holder:SetUserPlaced(true)
    holder:SetDontSavePosition(true)
    holder:SetClampedToScreen(false)

    if LeaPlusLC[optKey] == "On" then
        if InCombatLockdown() then
            local combatWait = CreateFrame("Frame")
            combatWait:RegisterEvent("PLAYER_REGEN_ENABLED")
            combatWait:SetScript("OnEvent", function(self)
                realFrame:SetMovable(true)
                realFrame:SetUserPlaced(true)
                realFrame:SetDontSavePosition(true)
                realFrame:ClearAllPoints()
                realFrame:SetPoint("CENTER", holder, "CENTER", 0, 0)
                realFrame:SetScale(LeaPlusLC[dbScale] or 1)
                self:UnregisterAllEvents()
            end)
        else
            realFrame:SetMovable(true)
            realFrame:SetUserPlaced(true)
            realFrame:SetDontSavePosition(true)
            realFrame:ClearAllPoints()
            realFrame:SetPoint("CENTER", holder, "CENTER", 0, 0)
            realFrame:SetScale(LeaPlusLC[dbScale] or 1)
        end
    end

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
    drag:RegisterForDrag("LeftButton", "RightButton")
    drag:Hide()

    drag.f = drag:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    drag.f:SetPoint("CENTER", 0, 0)
    drag.f:SetText(titleText)

    drag:SetScript("OnDragStart", function(self, btn)
        if InCombatLockdown() then return end
        self.dragBtn = btn
        holder:StartMoving()
    end)

    drag:SetScript("OnDragStop", function(self)
        if InCombatLockdown() then return end
        holder:StopMovingOrSizing()
        local a, _, r, x, y = holder:GetPoint()

        if self.dragBtn == "RightButton" then
            x = SnapToGrid(x, GRID_SIZE)
            y = SnapToGrid(y, GRID_SIZE)
        end

        LeaPlusLC[dbA], LeaPlusLC[dbR], LeaPlusLC[dbX], LeaPlusLC[dbY] = a, r, x, y
        holder:ClearAllPoints()
        holder:SetPoint(a, UIParent, r, x, y)
        drag:ClearAllPoints()
        drag:SetPoint("CENTER", holder, "CENTER", 0, 0)
    end)

    drag:HookScript("OnShow", AcquireGrid)
    drag:HookScript("OnHide", ReleaseGrid)

    movers[key] = {
        holder = holder,
        drag = drag,
        real = realFrame,
        scaleVar = dbScale,
        dbA = dbA, dbR = dbR, dbX = dbX, dbY = dbY,
    }
    return holder, drag
end

local function ConnectMoverPanel(key, panelTitle, btnKey, scaleVar, sliderText, resetTo)
    local mover = movers[key]
    if not mover then return end

    local panel = LeaPlusLC:CreatePanel(panelTitle, key .. "Panel")
    LeaPlusLC:MakeTx(panel, "Scale", 16, -72)
    LeaPlusLC:MakeSL(panel, scaleVar, sliderText, 0.5, 2.0, 0.05, 16, -92, "%.2f")
    LeaPlusLC:MakeWD(panel, "Right-drag a frame to snap it to the grid.", 16, -140)

    if LeaPlusCB[scaleVar] then
        LeaPlusCB[scaleVar]:HookScript("OnValueChanged", function(_, val)
            if not InCombatLockdown() then
                mover.real:SetScale(val)
                if key == "Debuffs" then
                    for i = 1, (DEBUFF_MAX_DISPLAY or 16) do
                        local dbBtn = _G["DebuffButton" .. i]
                        if dbBtn then dbBtn:SetScale(val) end
                    end
                end
            end
            mover.drag:SetScale(val)
        end)
    end

    panel.h:Hide()
    panel:HookScript("OnHide", function()
        mover.drag:Hide()
    end)

    panel.b:SetScript("OnClick", function()
        panel:Hide(); mover.drag:Hide()
        LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page6"]:Show()
    end)

    local rp = (resetTo and resetTo.point) or "CENTER"
    local rr = (resetTo and resetTo.relative) or "CENTER"
    local rx = (resetTo and resetTo.x) or 0
    local ry = (resetTo and resetTo.y) or 0

    panel.r:SetScript("OnClick", function()
        LeaPlusLC[scaleVar] = 1
        if LeaPlusCB[scaleVar] then
            LeaPlusCB[scaleVar]:SetValue(1)
        end

        LeaPlusLC[mover.dbA], LeaPlusLC[mover.dbR] = rp, rr
        LeaPlusLC[mover.dbX], LeaPlusLC[mover.dbY] = rx, ry
        mover.holder:ClearAllPoints()
        mover.holder:SetPoint(rp, UIParent, rr, rx, ry)
        if not InCombatLockdown() then
            mover.real:SetScale(1)
        end
        mover.drag:SetScale(1)
        mover.drag:ClearAllPoints()
        mover.drag:SetPoint("CENTER", mover.holder, "CENTER", 0, 0)
        mover.drag:Show()
        mover.drag:Raise()
    end)

    if LeaPlusCB[btnKey] then
        LeaPlusCB[btnKey]:SetScript("OnClick", function()
            if not InCombatLockdown() and mover.holder and mover.real then
                mover.real:SetMovable(true)
                mover.real:SetUserPlaced(true)
                mover.real:SetDontSavePosition(true)
                mover.real:ClearAllPoints()
                mover.real:SetPoint("CENTER", mover.holder, "CENTER", 0, 0)
                mover.real:SetScale(LeaPlusLC[scaleVar] or 1)
            end
            panel:Show()
            mover.drag:Show()
            LeaPlusLC:HideFrames()
        end)
    end
end

local function SetupEnhanceUnitFrames()
    if LeaPlusLC["EnhanceUnitFrames"] ~= "On" or LeaLockList["EnhanceUnitFrames"] then return end

    local ASSET_PATH = "Interface\\AddOns\\Leatrix_Plus\\Assets\\"
    local pendingPlayerStyle = false

    local function FormatCapValue(value)
        if not value then return "" end
        if value >= 1e9 then
            return string.format("%.1fG", value / 1e9)
        elseif value >= 1e6 then
            return string.format("%.1fM", value / 1e6)
        elseif value >= 1e3 then
            return string.format("%.1fk", value / 1e3)
        end
        return tostring(value)
    end

    local function GetUnitColor(unit)
        if not unit or not UnitExists(unit) then
            return 0.5, 0.5, 0.5
        end
        if not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit) then
            return 0.5, 0.5, 0.5
        end
        if UnitIsPlayer(unit) then
            local _, class = UnitClass(unit)
            local c = class and RAID_CLASS_COLORS[class]
            if c then
                return c.r, c.g, c.b
            end
        elseif UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then
            return 0.5, 0.5, 0.5
        else
            return UnitSelectionColor(unit)
        end
        return 0.5, 0.5, 0.5
    end

    local function UpdateBarColor(statusbar)
        if not statusbar then return end
        local unit
        if statusbar == PlayerFrameHealthBar then
            if UnitHasVehicleUI and UnitHasVehicleUI("player") then
                unit = "vehicle"
            else
                unit = "player"
            end
        elseif statusbar == TargetFrameHealthBar then
            unit = TargetFrame.unit or "target"
        elseif statusbar == FocusFrameHealthBar then
            unit = FocusFrame.unit or "focus"
        elseif statusbar.GetParent then
            local parent = statusbar:GetParent()
            unit = parent and parent.unit
        end

        if not unit then return end
        local r, g, b = GetUnitColor(unit)
        statusbar:SetStatusBarColor(r, g, b)
    end

    local function StylePlayerFrame()
        if InCombatLockdown() then
            pendingPlayerStyle = true
            return
        end
        PlayerFrameHealthBar.lockColor = true
        PlayerFrameHealthBar.capNumericDisplay = true
        PlayerFrameHealthBar:SetWidth(119)
        PlayerFrameHealthBar:SetHeight(29)
        PlayerFrameHealthBar:ClearAllPoints()
        PlayerFrameHealthBar:SetPoint("TOPLEFT", 106, -22)

        if PlayerFrameManaBar then
            PlayerFrameManaBar.capNumericDisplay = true
            PlayerFrameManaBar:ClearAllPoints()
            PlayerFrameManaBar:SetPoint("TOPLEFT", 106, -52)
        end

        if PlayerFrameAlternateManaBar then
            PlayerFrameAlternateManaBar.capNumericDisplay = true
            if PlayerFrameAlternateManaBarText then
                PlayerFrameAlternateManaBarText:ClearAllPoints()
                PlayerFrameAlternateManaBarText:SetPoint("CENTER", PlayerFrameAlternateManaBar, "CENTER", 0, 0)
            end
        end

        if PlayerName then
            PlayerName:ClearAllPoints()
            PlayerName:SetPoint("CENTER", PlayerFrame, "CENTER", 50, 19)
        end
        if PlayerFrameHealthBarText then
            PlayerFrameHealthBarText:ClearAllPoints()
            PlayerFrameHealthBarText:SetPoint("CENTER", PlayerFrame, "CENTER", 50, 6)
        end
        if PlayerFrameHealthBarTextLeft then
            PlayerFrameHealthBarTextLeft:ClearAllPoints()
            PlayerFrameHealthBarTextLeft:SetPoint("LEFT", PlayerFrameHealthBar, "LEFT", 4, -6)
        end
        if PlayerFrameHealthBarTextRight then
            PlayerFrameHealthBarTextRight:ClearAllPoints()
            PlayerFrameHealthBarTextRight:SetPoint("RIGHT", PlayerFrameHealthBar, "RIGHT", -4, -6)
        end

        if LeaPlusLC["ShowPlayerChain"] ~= "On" then
            PlayerFrameTexture:SetTexture(ASSET_PATH .. "UI-TargetingFrame")
            PlayerFrameTexture:SetTexCoord(1.0, 0.09375, 0.0, 0.78125)
        end

        if PlayerStatusTexture then
            PlayerStatusTexture:SetTexture(nil)
            PlayerStatusTexture:Hide()
        end
        if PlayerAttackBackground then
            PlayerAttackBackground:SetTexture(nil)
            PlayerAttackBackground:Hide()
        end

        UpdateBarColor(PlayerFrameHealthBar)
    end

    local function StyleTargetFrame(frame)
        if not frame or not frame.healthbar or InCombatLockdown() then return end
        local unit = frame.unit or "target"
        local classification = UnitClassification(unit)

        frame.healthbar.lockColor = true
        frame.healthbar.capNumericDisplay = true
        frame.healthbar:SetWidth(119)

        if frame.manabar then
            frame.manabar.capNumericDisplay = true
        end

        if classification == "minus" then
            frame.healthbar:SetHeight(12)
            frame.healthbar:ClearAllPoints()
            frame.healthbar:SetPoint("TOPLEFT", 7, -41)
            if frame.healthbar.TextString then
                frame.healthbar.TextString:ClearAllPoints()
                frame.healthbar.TextString:SetPoint("CENTER", frame, "CENTER", -50, 4)
            end
            if frame.deadText then
                frame.deadText:ClearAllPoints()
                frame.deadText:SetPoint("CENTER", frame, "CENTER", -50, 4)
            end
            if frame.name then
                frame.name:ClearAllPoints()
                frame.name:SetPoint("CENTER", frame, "CENTER", -50, 19)
            end
        else
            frame.healthbar:SetHeight(29)
            frame.healthbar:ClearAllPoints()
            frame.healthbar:SetPoint("TOPLEFT", 7, -22)

            if frame.manabar then
                frame.manabar:ClearAllPoints()
                frame.manabar:SetPoint("TOPLEFT", 7, -52)
            end

            if frame.name then
                frame.name:ClearAllPoints()
                frame.name:SetPoint("CENTER", frame, "CENTER", -50, 19)
                frame.name:SetWidth(110)
                frame.name:SetWordWrap(false)
            end
            if frame.healthbar.TextString then
                frame.healthbar.TextString:ClearAllPoints()
                frame.healthbar.TextString:SetPoint("CENTER", frame, "CENTER", -50, 6)
            end
            if frame.deadText then
                frame.deadText:ClearAllPoints()
                frame.deadText:SetPoint("CENTER", frame, "CENTER", -50, 6)
            end
            local frameName = frame:GetName()
            if frameName then
                local textLeft = _G[frameName .. "TextureFrameHealthBarTextLeft"]
                if textLeft then
                    textLeft:ClearAllPoints()
                    textLeft:SetPoint("LEFT", frame.healthbar, "LEFT", 4, -6)
                end
                local textRight = _G[frameName .. "TextureFrameHealthBarTextRight"]
                if textRight then
                    textRight:ClearAllPoints()
                    textRight:SetPoint("RIGHT", frame.healthbar, "RIGHT", -4, -6)
                end
                local leaderIcon = _G[frameName .. "TextureFrameLeaderIcon"]
                if leaderIcon then
                    leaderIcon:ClearAllPoints()
                    leaderIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -10)
                end
                local looterIcon = _G[frameName .. "TextureFrameMasterLooterIcon"]
                if looterIcon then
                    looterIcon:ClearAllPoints()
                    looterIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -10)
                end
            end
            if frame.nameBackground then
                frame.nameBackground:Hide()
            end

            if frame == TargetFrame and ComboPoint1 and not InCombatLockdown() then
                ComboPoint1:ClearAllPoints()
                ComboPoint1:SetPoint("TOPRIGHT", TargetFrame, "TOPRIGHT", -44, -9)
            end
        end

        UpdateBarColor(frame.healthbar)
    end

    local function StyleBossFrame(frame)
        if not frame or InCombatLockdown() then return end
        if frame.borderTexture then
            frame.borderTexture:SetTexture(ASSET_PATH .. "UI-UnitFrame-Boss")
        end
        StyleTargetFrame(frame)
    end

    local function UpdateClassification(frame, forceNormalTexture)
        if not frame or not frame.unit then return end
        local texture
        local classification = UnitClassification(frame.unit)
        local frameName = frame:GetName()
        local isBoss = frameName and frameName:find("Boss")

        if isBoss then
            texture = ASSET_PATH .. "UI-UnitFrame-Boss"
        elseif classification == "worldboss" or classification == "elite" then
            texture = ASSET_PATH .. "UI-TargetingFrame-Elite"
        elseif classification == "rareelite" then
            texture = ASSET_PATH .. "UI-TargetingFrame-Rare-Elite"
        elseif classification == "rare" then
            texture = ASSET_PATH .. "UI-TargetingFrame-Rare"
        end

        if frame.borderTexture then
            if texture and not forceNormalTexture then
                frame.borderTexture:SetTexture(texture)
            else
                frame.borderTexture:SetTexture(ASSET_PATH .. "UI-TargetingFrame")
            end
        end

        if not InCombatLockdown() then
            StyleTargetFrame(frame)
        end
    end

    if not LeaPlusLC.__leaStatusTextureHooked then
        LeaPlusLC.__leaStatusTextureHooked = true
        if PlayerStatusTexture then
            hooksecurefunc(PlayerStatusTexture, "Show", function(self)
                if LeaPlusLC["EnhanceUnitFrames"] == "On" then
                    self:Hide()
                end
            end)
        end
        if PlayerAttackBackground then
            hooksecurefunc(PlayerAttackBackground, "Show", function(self)
                if LeaPlusLC["EnhanceUnitFrames"] == "On" then
                    self:Hide()
                end
            end)
        end
    end

    hooksecurefunc("UnitFrameHealthBar_Update", function(statusbar)
        UpdateBarColor(statusbar)
    end)

    hooksecurefunc("TextStatusBar_UpdateTextString", function(statusBar)
        if not statusBar or statusBar.pauseUpdates then return end

        local isHealth = (statusBar == PlayerFrameHealthBar or statusBar == TargetFrameHealthBar or statusBar == FocusFrameHealthBar)
        local isMana = (statusBar == PlayerFrameManaBar or statusBar == TargetFrameManaBar or statusBar == FocusFrameManaBar or statusBar == PlayerFrameAlternateManaBar)

        if not isHealth and not isMana and not statusBar.capNumericDisplay then return end

        local textString = statusBar.TextString
        if not textString or not textString:IsShown() then return end

        local val = statusBar:GetValue()
        local _, maxVal = statusBar:GetMinMaxValues()
        if not val or not maxVal or maxVal <= 0 then return end

        if val == 0 and statusBar.zeroText then
            textString:SetText(statusBar.zeroText)
        elseif GetCVarBool("statusTextPercentage") or statusBar.showPercentage then
            local pct = math.ceil((val / maxVal) * 100)
            textString:SetText(string.format("%s (%d%%)", FormatCapValue(val), pct))
        else
            textString:SetText(string.format("%s / %s", FormatCapValue(val), FormatCapValue(maxVal)))
        end
    end)

    hooksecurefunc("PlayerFrame_ToPlayerArt", function()
        if InCombatLockdown() then
            pendingPlayerStyle = true
        else
            StylePlayerFrame()
        end
    end)
    hooksecurefunc("PlayerFrame_ToVehicleArt", function()
        if InCombatLockdown() then
            pendingPlayerStyle = true
        else
            PlayerFrameHealthBar:SetHeight(12)
            if PlayerFrameHealthBarText then
                PlayerFrameHealthBarText:ClearAllPoints()
                PlayerFrameHealthBarText:SetPoint("CENTER", PlayerFrame, "CENTER", 50, 3)
            end
            if PlayerName then
                PlayerName:ClearAllPoints()
                PlayerName:SetPoint("CENTER", PlayerFrame, "CENTER", 50, 19)
            end
            if PlayerFrameManaBar then
                PlayerFrameManaBar:ClearAllPoints()
                PlayerFrameManaBar:SetPoint("TOPLEFT", 106, -52)
            end
            UpdateBarColor(PlayerFrameHealthBar)
        end
    end)

    hooksecurefunc("TargetFrame_Update", function(self)
        if not InCombatLockdown() then
            StyleTargetFrame(self)
        else
            UpdateBarColor(self.healthbar)
        end
    end)
    hooksecurefunc("TargetFrame_CheckFaction", function(self)
        if not self or not self.unit then return end
        UpdateBarColor(self.healthbar)
        if not self.pvpIcon then return end
        local factionGroup = UnitFactionGroup(self.unit)
        if UnitIsPVPFreeForAll(self.unit) or (factionGroup and UnitIsPVP(self.unit) and UnitIsEnemy("player", self.unit)) then
            self.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA")
            self.pvpIcon:Show()
        elseif factionGroup and UnitIsPVP(self.unit) then
            self.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-" .. factionGroup)
            self.pvpIcon:Show()
        else
            self.pvpIcon:Hide()
        end
    end)
    hooksecurefunc("TargetFrame_CheckDead", function(self)
        UpdateBarColor(self.healthbar)
    end)
    hooksecurefunc("TargetFrame_CheckClassification", UpdateClassification)

    if FocusFrame_SetSmallSize then
        local inFocusHook = false
        hooksecurefunc("FocusFrame_SetSmallSize", function(smallSize)
            if inFocusHook then return end
            if LeaPlusLC["EnhanceUnitFrames"] == "On" and smallSize then
                if not InCombatLockdown() then
                    inFocusHook = true
                    FocusFrame_SetSmallSize(false, true)
                    StyleTargetFrame(FocusFrame)
                    inFocusHook = false
                end
            end
        end)
    end

    local eventWatcher = CreateFrame("Frame")
    eventWatcher:RegisterEvent("UNIT_FACTION")
    eventWatcher:RegisterEvent("PLAYER_ALIVE")
    eventWatcher:RegisterEvent("PLAYER_UNGHOST")
    eventWatcher:RegisterEvent("PLAYER_DEAD")
    eventWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventWatcher:SetScript("OnEvent", function(_, event, unit)
        if event == "UNIT_FACTION" then
            if unit == "target" then
                UpdateBarColor(TargetFrame.healthbar)
            elseif unit == "focus" then
                UpdateBarColor(FocusFrame.healthbar)
            elseif unit == "player" or unit == "vehicle" then
                UpdateBarColor(PlayerFrameHealthBar)
            end
        elseif event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" or event == "PLAYER_DEAD" or event == "PLAYER_ENTERING_WORLD" then
            UpdateBarColor(PlayerFrameHealthBar)
        end
    end)

    local combatWait = CreateFrame("Frame")
    combatWait:RegisterEvent("PLAYER_REGEN_ENABLED")
    combatWait:SetScript("OnEvent", function()
        if pendingPlayerStyle then
            pendingPlayerStyle = false
            if UnitHasVehicleUI and UnitHasVehicleUI("player") then
                PlayerFrameHealthBar:SetHeight(12)
                UpdateBarColor(PlayerFrameHealthBar)
            else
                StylePlayerFrame()
            end
        end
        if FocusFrame_SetSmallSize and FocusFrame.smallSize and not InCombatLockdown() then
            FocusFrame_SetSmallSize(false, true)
        end
        StyleTargetFrame(TargetFrame)
        StyleTargetFrame(FocusFrame)
    end)

    if not InCombatLockdown() then
        if FocusFrame_SetSmallSize then
            FocusFrame_SetSmallSize(false, true)
        end
        StylePlayerFrame()
        StyleTargetFrame(TargetFrame)
        StyleTargetFrame(FocusFrame)
        for i = 1, 4 do
            local boss = _G["Boss" .. i .. "TargetFrame"]
            if boss then StyleBossFrame(boss) end
        end
    else
        pendingPlayerStyle = true
    end
end

local function SetupUnitFrames()
    local SideFrames = LeaPlusLC:CreatePanel("Manage frames", "SideFrames")
    LeaPlusLC:MakeTx(SideFrames, "Scale", 16, -72)
    LeaPlusLC:MakeSL(SideFrames, "PlayerTargetScale", "Scale player and target frames.", 0.5, 2.0, 0.05, 16, -92, "%.2f")
    LeaPlusLC:MakeWD(SideFrames, "Right-drag a frame to snap it to the grid.", 16, -140)

    if LeaPlusCB["PlayerTargetScale"] then
        LeaPlusCB["PlayerTargetScale"]:HookScript("OnValueChanged", function(_, val)
            if not InCombatLockdown() then
                PlayerFrame:SetScale(val)
                TargetFrame:SetScale(val)
                if ComboFrame then ComboFrame:SetScale(val) end
                if dragPlayer then dragPlayer:SetScale(val) end
                if dragTarget then dragTarget:SetScale(val) end
            end
        end)
    end

    local function MakeUnitDrag(frame, labelText)
        local drag = CreateFrame("Frame", nil, UIParent)
        drag:SetSize(frame:GetWidth(), frame:GetHeight())
        drag:SetPoint("CENTER", frame, "CENTER", 0, 0)
        drag:SetScale(frame:GetScale())
        drag:SetFrameStrata("DIALOG")
        drag:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, tileSize = 0, edgeSize = 16,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        drag:SetBackdropColor(0.0, 0.5, 1.0, 0.5)
        drag:EnableMouse(true)
        drag:RegisterForDrag("LeftButton", "RightButton")
        drag:Hide()

        drag.f = drag:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        drag.f:SetPoint("CENTER", 0, 0)
        drag.f:SetText(labelText)

        drag:SetScript("OnDragStart", function(self, btn)
            if InCombatLockdown() then return end
            self.dragBtn = btn
            frame:StartMoving()
        end)

        drag:SetScript("OnDragStop", function(self)
            if InCombatLockdown() then return end
            frame:StopMovingOrSizing()
            local a, _, r, x, y = frame:GetPoint()

            if self.dragBtn == "RightButton" then
                x = SnapToGrid(x, GRID_SIZE)
                y = SnapToGrid(y, GRID_SIZE)
                frame:ClearAllPoints()
                frame:SetPoint(a, UIParent, r, x, y)
            end

            local vf = frame:GetName()
            local DB = Leatrix_Plus.DB
            local charKey = (UnitName("player") or "Unknown") .. " - " .. (GetRealmName() or "Unknown")
            local activeProf = (DB["ProfileKeys"] and DB["ProfileKeys"][charKey]) or "Default"
            local container = (DB["Profiles"] and DB["Profiles"][activeProf]) or DB

            container["Frames"] = container["Frames"] or {}
            container["Frames"][vf] = { Point = a, Relative = r, XOffset = x, YOffset = y, Scale = frame:GetScale() }

            drag:ClearAllPoints()
            drag:SetPoint("CENTER", frame, "CENTER", 0, 0)
        end)

        drag:HookScript("OnShow", AcquireGrid)
        drag:HookScript("OnHide", ReleaseGrid)

        return drag
    end

    if LeaPlusLC["FrmEnabled"] == "On" and not LeaLockList["FrmEnabled"] then
        PlayerFrame:SetMovable(true); PlayerFrame:SetUserPlaced(true); PlayerFrame:SetDontSavePosition(true)
        TargetFrame:SetMovable(true); TargetFrame:SetUserPlaced(true); TargetFrame:SetDontSavePosition(true)
    end

    dragPlayer = MakeUnitDrag(PlayerFrame, L["Player"])
    dragTarget = MakeUnitDrag(TargetFrame, L["Target"])

    SideFrames.h:Hide()
    SideFrames:HookScript("OnHide", function()
        dragPlayer:Hide()
        dragTarget:Hide()
    end)

    SideFrames.b:SetScript("OnClick", function()
        SideFrames:Hide(); dragPlayer:Hide(); dragTarget:Hide()
        LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page6"]:Show()
    end)

    SideFrames.r:SetScript("OnClick", function()
        if not InCombatLockdown() then
            LeaPlusLC["PlayerTargetScale"] = 1
            if LeaPlusCB["PlayerTargetScale"] then
                LeaPlusCB["PlayerTargetScale"]:SetValue(1)
            end

            local DB = Leatrix_Plus.DB
            local charKey = (UnitName("player") or "Unknown") .. " - " .. (GetRealmName() or "Unknown")
            local activeProf = (DB["ProfileKeys"] and DB["ProfileKeys"][charKey]) or "Default"
            if DB["Profiles"] and DB["Profiles"][activeProf] then
                DB["Profiles"][activeProf]["Frames"] = nil
            end
            DB["Frames"] = nil

            PlayerFrame:ClearAllPoints()
            PlayerFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -19, -4)
            PlayerFrame:SetScale(1)

            TargetFrame:ClearAllPoints()
            TargetFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 250, -4)
            TargetFrame:SetScale(1)

            if ComboFrame then ComboFrame:SetScale(1) end

            dragPlayer:SetScale(1); dragTarget:SetScale(1)
            dragPlayer:ClearAllPoints(); dragPlayer:SetPoint("CENTER", PlayerFrame, "CENTER", 0, 0)
            dragTarget:ClearAllPoints(); dragTarget:SetPoint("CENTER", TargetFrame, "CENTER", 0, 0)
        end
    end)

    if LeaPlusCB["MoveFramesButton"] then
        LeaPlusCB["MoveFramesButton"]:SetScript("OnClick", function()
            PlayerFrame:SetMovable(true); PlayerFrame:SetUserPlaced(true); PlayerFrame:SetDontSavePosition(true)
            TargetFrame:SetMovable(true); TargetFrame:SetUserPlaced(true); TargetFrame:SetDontSavePosition(true)
            SideFrames:Show(); dragPlayer:Show(); dragTarget:Show(); LeaPlusLC:HideFrames()
        end)
    end

    local function ApplyUnitFramePositions()
        local DB = Leatrix_Plus.DB
        if not DB or LeaPlusLC["FrmEnabled"] ~= "On" or LeaLockList["FrmEnabled"] or InCombatLockdown() then return end

        local userScale = LeaPlusLC["PlayerTargetScale"] or 1
        if userScale ~= 1 then
            PlayerFrame:SetScale(userScale)
            TargetFrame:SetScale(userScale)
            if ComboFrame then ComboFrame:SetScale(userScale) end
            if dragPlayer then dragPlayer:SetScale(userScale) end
            if dragTarget then dragTarget:SetScale(userScale) end
        end

        local charKey = (UnitName("player") or "Unknown") .. " - " .. (GetRealmName() or "Unknown")
        local activeProf = (DB["ProfileKeys"] and DB["ProfileKeys"][charKey]) or "Default"
        local container = (DB["Profiles"] and DB["Profiles"][activeProf]) or DB
        local frameData = container["Frames"] or DB["Frames"]

        if frameData then
            local pf = frameData["PlayerFrame"]
            if pf then
                PlayerFrame:ClearAllPoints()
                PlayerFrame:SetPoint(pf.Point or "TOPLEFT", UIParent, pf.Relative or "TOPLEFT", pf.XOffset or -19, pf.YOffset or -4)
                PlayerFrame:SetScale(pf.Scale or userScale)
                if dragPlayer then dragPlayer:SetScale(pf.Scale or userScale) end
            end

            local tf = frameData["TargetFrame"]
            if tf then
                TargetFrame:ClearAllPoints()
                TargetFrame:SetPoint(tf.Point or "TOPLEFT", UIParent, tf.Relative or "TOPLEFT", tf.XOffset or 250, tf.YOffset or -4)
                TargetFrame:SetScale(tf.Scale or userScale)
                if dragTarget then dragTarget:SetScale(tf.Scale or userScale) end
                if ComboFrame then ComboFrame:SetScale(tf.Scale or userScale) end
            end
        end
    end

    ApplyUnitFramePositions()
    Module.ApplyUnitFramePositions = ApplyUnitFramePositions

    if not LeaPlusLC.__leaPlayerFrameFixInstalled then
        LeaPlusLC.__leaPlayerFrameFixInstalled = true

        local function GetSavedPlayerFrame()
            local DB = Leatrix_Plus.DB
            local charKey = (UnitName("player") or "Unknown") .. " - " .. (GetRealmName() or "Unknown")
            local activeProf = (DB["ProfileKeys"] and DB["ProfileKeys"][charKey]) or "Default"
            local container = (DB["Profiles"] and DB["Profiles"][activeProf]) or DB
            local frameData = container["Frames"] or DB["Frames"]
            return frameData and frameData["PlayerFrame"]
        end

        local bugFrame = CreateFrame("Frame")

        local function RestorePlayerFramePosition()
            if LeaPlusLC["FrmEnabled"] ~= "On" then return end
            if InCombatLockdown() then
                bugFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
                return
            end
            local pf = GetSavedPlayerFrame()
            local point = (pf and pf.Point) or "TOPLEFT"
            local rel = (pf and pf.Relative) or "TOPLEFT"
            local x = (pf and pf.XOffset) or -19
            local y = (pf and pf.YOffset) or -4
            local scale = (pf and pf.Scale) or LeaPlusLC["PlayerTargetScale"] or 1

            PlayerFrame:ClearAllPoints()
            PlayerFrame:SetPoint(point, UIParent, rel, x, y)
            PlayerFrame:SetScale(scale)
            if dragPlayer then dragPlayer:SetScale(scale) end
        end

        bugFrame:SetScript("OnEvent", function(self, event)
            if event == "PLAYER_REGEN_ENABLED" then
                RestorePlayerFramePosition()
                self:UnregisterEvent("PLAYER_REGEN_ENABLED")
            else
                RestorePlayerFramePosition()
            end
        end)

        bugFrame:RegisterEvent("UNIT_ENTERING_VEHICLE")
        bugFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
        bugFrame:RegisterEvent("UNIT_EXITING_VEHICLE")
        bugFrame:RegisterEvent("UNIT_EXITED_VEHICLE")
        bugFrame:RegisterEvent("VEHICLE_UPDATE")

        hooksecurefunc("PlayerFrame_SequenceFinished", RestorePlayerFramePosition)
        hooksecurefunc("PlayerFrame_ToVehicleArt", RestorePlayerFramePosition)
        hooksecurefunc("PlayerFrame_ToPlayerArt", RestorePlayerFramePosition)
    end
end

local function SetupClassColFrames()
    local ClassFrame = LeaPlusLC:CreatePanel("Class Colored Unit Frames", "ClassFrame")
    LeaPlusLC:MakeTx(ClassFrame, "Settings", 16, -72)
    LeaPlusLC:MakeCB(ClassFrame, "ClassColPlayer", "Color Player Frame", 16, -92, false, "Adds a class-colored nameplate background to the player frame.")
    LeaPlusLC:MakeCB(ClassFrame, "ClassColTarget", "Color Target and Focus Frames", 16, -112, false, "Colors the target and focus frame nameplate backgrounds according to target class.")

    ClassFrame.h:Hide()
    ClassFrame.b:SetScript("OnClick", function()
        ClassFrame:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page6"]:Show()
    end)
    ClassFrame.r:SetScript("OnClick", function()
        LeaPlusLC["ClassColPlayer"] = "On"
        LeaPlusLC["ClassColTarget"] = "On"
        ClassFrame:Hide(); ClassFrame:Show()
    end)

    if LeaPlusCB["ClassColFramesBtn"] then
        LeaPlusCB["ClassColFramesBtn"]:SetScript("OnClick", function()
            ClassFrame:Show(); LeaPlusLC:HideFrames()
        end)
    end

    if LeaPlusLC["ClassColFrames"] ~= "On" or LeaLockList["ClassColFrames"] then return end
    if not TargetFrameNameBackground then return end

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
    if c then PlayFN.t:SetVertexColor(c.r, c.g, c.b) end

    local function UpdateUnitClassColor(frame)
        if LeaPlusLC["ClassColFrames"] == "On" and LeaPlusLC["ClassColTarget"] == "On" and frame and frame.unit then
            if UnitIsPlayer(frame.unit) then
                local _, unitClass = UnitClass(frame.unit)
                local c = unitClass and RAID_CLASS_COLORS[unitClass]
                if c then
                    local bg = _G[frame:GetName() .. "NameBackground"]
                    if bg then bg:SetVertexColor(c.r, c.g, c.b) end
                end
            end
        end
    end

    if not LeaPlusLC.__leaTargetCheckFactionHooked then
        LeaPlusLC.__leaTargetCheckFactionHooked = true
        hooksecurefunc("TargetFrame_CheckFaction", UpdateUnitClassColor)
    end

    local function SetClassColFrames()
        if LeaPlusLC["ClassColPlayer"] == "On" then PlayFN:Show() else PlayFN:Hide() end
        TargetFrame_CheckFaction(TargetFrame)
        if FocusFrame then TargetFrame_CheckFaction(FocusFrame) end
    end

    if LeaPlusCB["ClassColPlayer"] then LeaPlusCB["ClassColPlayer"]:HookScript("OnClick", SetClassColFrames) end
    if LeaPlusCB["ClassColTarget"] then LeaPlusCB["ClassColTarget"]:HookScript("OnClick", SetClassColFrames) end
    SetClassColFrames()
end

local function SetupManagedContainers()
    local masterBuff = (ConsolidatedBuffs and ConsolidatedBuffs:IsShown()) and ConsolidatedBuffs or BuffFrame
    if masterBuff then
        CreateMover("Buffs", "ManageBuffs", masterBuff, "BuffFrameA", "BuffFrameR", "BuffFrameX", "BuffFrameY", "BuffFrameScale", 280, 225, L["Buffs"])
        ConnectMoverPanel("Buffs", "Manage buffs", "ManageBuffsButton", "BuffFrameScale", "Scale the buffs frame.",
            { point = "TOPRIGHT", relative = "TOPRIGHT", x = -205, y = -13 })

        if not LeaPlusLC.__leaBuffPositionsHooked and BuffFrame_UpdatePositions then
            LeaPlusLC.__leaBuffPositionsHooked = true
            hooksecurefunc("BuffFrame_UpdatePositions", function()
                if LeaPlusLC["ManageBuffs"] == "On" and not InCombatLockdown() then
                    local mover = movers["Buffs"]
                    if mover and mover.holder then
                        local activeBuff = (ConsolidatedBuffs and ConsolidatedBuffs:IsShown()) and ConsolidatedBuffs or BuffFrame
                        activeBuff:ClearAllPoints()
                        activeBuff:SetPoint("CENTER", mover.holder, "CENTER", 0, 0)
                    end
                end
            end)
        end
    end

    local debuffTarget = DebuffButton1 or CreateFrame("Frame", nil, UIParent)
    if not DebuffButton1 then
        debuffTarget:SetSize(120, 40)
        debuffTarget:Hide()
    end

    if not LeaPlusLC.__leaDebuffSwapInstalled then
        LeaPlusLC.__leaDebuffSwapInstalled = true
        if DebuffButton_UpdateAnchors then
            hooksecurefunc("DebuffButton_UpdateAnchors", function(buttonName, index)
                if buttonName == "DebuffButton" and LeaPlusLC["ManageDeBuffs"] == "On" then
                    local mover = movers["Debuffs"]
                    if mover and mover.holder and DebuffButton1 then
                        mover.real = DebuffButton1
                        DebuffButton1:ClearAllPoints()
                        DebuffButton1:SetPoint("CENTER", mover.holder, "CENTER", 0, 0)
                        local scale = LeaPlusLC["DebuffButton1Scale"] or 1
                        for i = 1, (DEBUFF_MAX_DISPLAY or 16) do
                            local dbBtn = _G["DebuffButton" .. i]
                            if dbBtn then dbBtn:SetScale(scale) end
                        end
                    end
                end
            end)
        end
    end

    CreateMover("Debuffs", "ManageDeBuffs", debuffTarget, "DebuffButton1A", "DebuffButton1R", "DebuffButton1X", "DebuffButton1Y", "DebuffButton1Scale", 120, 40, L["Debuffs"])
    ConnectMoverPanel("Debuffs", "Manage debuffs", "ManageDeBuffsButton", "DebuffButton1Scale", "Scale the debuffs frame.",
        { point = "TOPRIGHT", relative = "TOPRIGHT", x = -205, y = -205 })

    local debuffMover = movers["Debuffs"]
    if debuffMover then
        debuffMover.drag:HookScript("OnShow", function()
            if DebuffButton1 and debuffMover.real ~= DebuffButton1 then
                debuffMover.real = DebuffButton1
                if LeaPlusLC["ManageDeBuffs"] == "On" then
                    DebuffButton1:ClearAllPoints()
                    DebuffButton1:SetPoint("CENTER", debuffMover.holder, "CENTER", 0, 0)
                end
            end
        end)
    end

    if VehicleSeatIndicator then
        local vHolder = CreateMover("Vehicle", "ManageVehicle", VehicleSeatIndicator, "VehicleA", "VehicleR", "VehicleX", "VehicleY", "VehicleScale", 128, 128, L["Vehicle"])
        ConnectMoverPanel("Vehicle", "Manage Vehicle Indicator", "ManageVehicleButton", "VehicleScale", "Scale vehicle indicator.",
            { point = "TOPRIGHT", relative = "TOPRIGHT", x = -100, y = -192 })

        local inVehicleHook = false
        hooksecurefunc(VehicleSeatIndicator, "SetPoint", function(self, _, relTo)
            if inVehicleHook then return end
            if LeaPlusLC["ManageVehicle"] == "On" and not InCombatLockdown() then
                if vHolder and relTo ~= vHolder then
                    inVehicleHook = true
                    self:ClearAllPoints()
                    self:SetPoint("CENTER", vHolder, "CENTER", 0, 0)
                    inVehicleHook = false
                end
            end
        end)
    end

    if DurabilityFrame then
        CreateMover("Durability", "ManageDurability", DurabilityFrame, "DurabilityA", "DurabilityR", "DurabilityX", "DurabilityY", "DurabilityScale", 92, 75, L["Durability"])
        ConnectMoverPanel("Durability", "Manage durability", "ManageDurabilityButton", "DurabilityScale", "Scale durability frame.",
            { point = "TOPRIGHT", relative = "TOPRIGHT", x = 0, y = -170 })
    end

    if WorldStateAlwaysUpFrame then
        CreateMover("Widget", "ManageWidget", WorldStateAlwaysUpFrame, "WidgetA", "WidgetR", "WidgetX", "WidgetY", "WidgetScale", 280, 60, L["Widget"])
        ConnectMoverPanel("Widget", "Manage widget", "ManageWidgetButton", "WidgetScale", "Scale the widget frame.",
            { point = "TOP", relative = "TOP", x = 0, y = -15 })
    end

    if FocusFrame then
        CreateMover("Focus", "ManageFocus", FocusFrame, "FocusA", "FocusR", "FocusX", "FocusY", "FocusScale", 196, 76, L["Focus"])
        ConnectMoverPanel("Focus", "Manage focus", "ManageFocusButton", "FocusScale", "Scale the focus frame.",
            { point = "CENTER", relative = "CENTER", x = 0, y = 0 })
    end

    if MirrorTimer1 then
        CreateMover("Timer", "ManageTimer", MirrorTimer1, "TimerA", "TimerR", "TimerX", "TimerY", "TimerScale", 180, 20, L["Timer"])
        ConnectMoverPanel("Timer", "Manage timer", "ManageTimerButton", "TimerScale", "Scale the timer bar.",
            { point = "TOP", relative = "TOP", x = -5, y = -96 })
    end

    if WatchFrame then
        local function UpdateWatchFrameDimensions()
            local top = WatchFrame:GetTop() or GetScreenHeight()
            local availableHeight = math.max(200, math.min(top - 50, 800))
            WatchFrame:SetHeight(availableHeight)
        end

        local tHolder, tDrag = CreateMover("Tracker", "ManageTracker", WatchFrame, "TrackerA", "TrackerR", "TrackerX", "TrackerY", "TrackerScale", 220, 400, L["Tracker"])
        ConnectMoverPanel("Tracker", "Manage Quest Tracker", "ManageTrackerButton", "TrackerScale", "Scale the quest tracker.",
            { point = "TOPRIGHT", relative = "TOPRIGHT", x = 0, y = -170 })

        if tDrag then
            tDrag:HookScript("OnDragStop", UpdateWatchFrameDimensions)
        end

        if not LeaPlusLC.__leaWatchFrameHooked then
            LeaPlusLC.__leaWatchFrameHooked = true
            hooksecurefunc("UIParent_ManageFramePositions", function()
                if not InCombatLockdown() then
                    if LeaPlusLC["ManageTracker"] == "On" then
                        local mover = movers["Tracker"]
                        if mover and mover.holder then
                            WatchFrame:ClearAllPoints()
                            WatchFrame:SetPoint("CENTER", mover.holder, "CENTER", 0, 0)
                            UpdateWatchFrameDimensions()
                        end
                    end
                    if LeaPlusLC["ManageDurability"] == "On" then
                        local dMover = movers["Durability"]
                        if dMover and dMover.holder then
                            DurabilityFrame:ClearAllPoints()
                            DurabilityFrame:SetPoint("CENTER", dMover.holder, "CENTER", 0, 0)
                        end
                    end
                end
            end)
        end
    end
end

local function SetupCosmetics()
    if LeaPlusLC["NoGryphons"] == "On" and not LeaLockList["NoGryphons"] then
        if MainMenuBarLeftEndCap then
            MainMenuBarLeftEndCap:Hide()
            hooksecurefunc(MainMenuBarLeftEndCap, "Show", MainMenuBarLeftEndCap.Hide)
        end
        if MainMenuBarRightEndCap then
            MainMenuBarRightEndCap:Hide()
            hooksecurefunc(MainMenuBarRightEndCap, "Show", MainMenuBarRightEndCap.Hide)
        end
    end

    if LeaPlusLC["NoClassBar"] == "On" and not LeaLockList["NoClassBar"] and ShapeshiftBarFrame then
        local h = CreateFrame("Frame")
        h:Hide()
        ShapeshiftBarFrame:UnregisterAllEvents()
        ShapeshiftBarFrame:SetParent(h)
    end

    if LeaPlusLC["NoAlerts"] == "On" and not LeaLockList["NoAlerts"] then
        if AlertFrame then AlertFrame:UnregisterAllEvents() end
        if AchievementAlertFrame1 then AchievementAlertFrame1:UnregisterAllEvents() end
        if AchievementAlertFrame2 then AchievementAlertFrame2:UnregisterAllEvents() end
        if DungeonCompletionAlertFrame1 then DungeonCompletionAlertFrame1:UnregisterAllEvents() end
        if AchievementAlertFrame_ShowAlert then AchievementAlertFrame_ShowAlert = function() end end
        if DungeonCompletionAlertFrame_ShowAlert then DungeonCompletionAlertFrame_ShowAlert = function() end end

        local achFrame = CreateFrame("Frame")
        achFrame:RegisterEvent("ACHIEVEMENT_EARNED")
        achFrame:SetScript("OnEvent", function(_, _, id)
            if id then
                local link = GetAchievementLink(id)
                if link then
                    LeaPlusLC:Print(string.format(NEW_ACHIEVEMENT_EARNED:gsub("'", ""), link))
                    PlaySound("AchievementSound")
                end
            end
        end)
    end
end

function Module:OnEnable()
    SetupUnitFrames()
    SetupEnhanceUnitFrames()
    SetupClassColFrames()
    SetupCosmetics()
end

function Module:OnLogin()
    if Module.ApplyUnitFramePositions then
        Module.ApplyUnitFramePositions()
    end
    SetupManagedContainers()
end

function Module:OnLogout(wipeData) end