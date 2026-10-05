-- Tooltip.lua
local _, Leatrix_Plus = ...
local LeaPlusLC = Leatrix_Plus.LC
local LeaPlusCB = Leatrix_Plus.CB
local L = Leatrix_Plus.L

local Module = {}
Leatrix_Plus:RegisterModule("Tooltip", Module)

local LT = {}
local LevelString = string.lower(TOOLTIP_UNIT_LEVEL:gsub("%%s", ".+"))

local ttYou       = "YOU"
local ttLevel     = "Level"
local ttBoss      = "Boss"
local ttElite     = "Elite"
local ttRare      = "Rare"
local ttRareElite = "Rare Elite"
local ttRareBoss  = "Rare Boss"
local ttTarget    = "Target"

local TipDrag
local SideTip
local SetTipScale
local UpdateDragFrameVisibility

UpdateDragFrameVisibility = function()
    if not TipDrag then return end
    local isOpen = SideTip and SideTip:IsShown()
    local isOverlay = (LeaPlusLC["TooltipAnchorMenu"] or 1) == 2
    if isOpen and isOverlay then
        TipDrag:Show()
    else
        TipDrag:Hide()
        if LeaPlusLC.ReleaseGrid then LeaPlusLC.ReleaseGrid() end
    end
end

local function OpenTooltipPanel()
    if not SideTip then return end
    SideTip:Show()
    LeaPlusLC:HideFrames()
    if SetTipScale then SetTipScale() end
    if TipDrag then
        TipDrag:ClearAllPoints()
        TipDrag:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT",
            LeaPlusLC["TipOffsetX"] or -13, LeaPlusLC["TipOffsetY"] or 94)
    end
    UpdateDragFrameVisibility()
end

local function EnsureGearWired()
    if not LeaPlusCB["TipModEnable"] then return end

    if not LeaPlusCB["MoveTooltipButton"] then
        LeaPlusLC:CfgBtn("MoveTooltipButton", LeaPlusCB["TipModEnable"])
    end

    local gear = LeaPlusCB["MoveTooltipButton"]
    if gear then
        gear:SetScript("OnClick", OpenTooltipPanel)
    end
end

local function BuildTooltipPanel()
    SideTip = LeaPlusLC:CreatePanel("Enhance Tooltips", "SideTip")
    EnsureGearWired()

    -- Drag frame (only shown when the panel is open in Overlay mode)
    TipDrag = CreateFrame("Frame", nil, UIParent)
    TipDrag:SetToplevel(true)
    TipDrag:SetClampedToScreen(false)
    TipDrag:SetSize(130, 64)
    TipDrag:Hide()
    TipDrag:SetFrameStrata("TOOLTIP")
    TipDrag:SetMovable(true)
    TipDrag:EnableMouse(true)
    TipDrag:RegisterForDrag("LeftButton", "RightButton")
    TipDrag:SetBackdropColor(0.0, 0.5, 1.0)
    TipDrag:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, tileSize = 0, edgeSize = 16,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    TipDrag.f = TipDrag:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    TipDrag.f:SetPoint("CENTER", 0, 0)
    TipDrag.f:SetText(L["Tooltip"])
    TipDrag.t = TipDrag:CreateTexture(nil, "BACKGROUND")
    TipDrag.t:SetAllPoints()
    TipDrag.t:SetTexture(0.0, 0.5, 1.0, 0.5)

    TipDrag:HookScript("OnShow", function()
        if LeaPlusLC.AcquireGrid then LeaPlusLC.AcquireGrid() end
    end)
    TipDrag:HookScript("OnHide", function()
        if LeaPlusLC.ReleaseGrid then LeaPlusLC.ReleaseGrid() end
    end)

    -- Scale function (strict 3.3.5 frame targets)
    SetTipScale = function()
        local size = LeaPlusLC["LeaPlusTipSize"] or 1.0
        if GameTooltip then GameTooltip:SetScale(size) end
        if FriendsTooltip then FriendsTooltip:SetScale(size) end
        if ItemRefTooltip then ItemRefTooltip:SetScale(size) end
        if ItemRefShoppingTooltip1 then ItemRefShoppingTooltip1:SetScale(size) end
        if ItemRefShoppingTooltip2 then ItemRefShoppingTooltip2:SetScale(size) end
        if ShoppingTooltip1 then ShoppingTooltip1:SetScale(size) end
        if ShoppingTooltip2 then ShoppingTooltip2:SetScale(size) end
        if ComparisonTooltip1 then ComparisonTooltip1:SetScale(size) end
        if ComparisonTooltip2 then ComparisonTooltip2:SetScale(size) end
        if TipDrag then TipDrag:SetScale(size) end
    end

    -- Settings column
    LeaPlusLC:MakeTx(SideTip, "Settings", 16, -72)
    LeaPlusLC:MakeCB(SideTip, "TipShowRank", "Show Guild Ranks for Your Guild", 16, -92, false, "Shows guild rank titles for members of your guild.")
    LeaPlusLC:MakeCB(SideTip, "TipShowOtherRank", "Show Guild Ranks for Other Guilds", 16, -112, false, "Shows guild rank titles for members of other guilds.")
    LeaPlusLC:MakeCB(SideTip, "TipShowTarget", "Show Unit Targets", 16, -132, false, "Shows the current target of the unit, highlighting yourself in orange.")
    LeaPlusLC:MakeCB(SideTip, "TipNoHealthBar", "Hide Health Bar", 16, -152, true, "Hides the health bar under unit tooltips.")

    LeaPlusLC:MakeTx(SideTip, "Hide tooltips", 16, -192)
    LeaPlusLC:MakeCB(SideTip, "TipHideInCombat", "Hide World Unit Tooltips in Combat", 16, -212, false, "Hides 3D world unit mouseover tooltips during combat while leaving action bar and inventory tooltips visible.")
    LeaPlusLC:MakeCB(SideTip, "TipHideShiftOverride", "Show Tooltips with Shift Key", 16, -232, false, "Allows holding Shift while in combat to temporarily show world unit tooltips.")

    local function SetTipHideShiftOverrideFunc()
        if LeaPlusLC["TipHideInCombat"] == "On" then
            LeaPlusLC:LockItem(LeaPlusCB["TipHideShiftOverride"], false)
        else
            LeaPlusLC:LockItem(LeaPlusCB["TipHideShiftOverride"], true)
        end
    end
    if LeaPlusCB["TipHideInCombat"] then
        LeaPlusCB["TipHideInCombat"]:HookScript("OnClick", SetTipHideShiftOverrideFunc)
    end
    SetTipHideShiftOverrideFunc()

    -- Anchor dropdown
    local anchorDrop = LeaPlusLC:CreateDropDown("TooltipAnchorMenu", "Anchor", SideTip, 146, "TOPLEFT", 356, -115,
        { L["None"], L["Overlay"], L["Cursor"], L["Cursor Right"] }, "")

    local XOffsetHeading = LeaPlusLC:MakeTx(SideTip, "X Offset", 356, -132)
    LeaPlusLC:MakeSL(SideTip, "TipCursorX", "Drag to set the cursor X offset.", -128, 128, 1, 356, -152, "%.0f")
    local YOffsetHeading = LeaPlusLC:MakeTx(SideTip, "Y Offset", 356, -182)
    LeaPlusLC:MakeSL(SideTip, "TipCursorY", "Drag to set the cursor Y offset.", -128, 128, 1, 356, -202, "%.0f")

    LeaPlusLC:MakeTx(SideTip, "Scale", 356, -232)
    LeaPlusLC:MakeSL(SideTip, "LeaPlusTipSize", "Drag to set the tooltip scale.", 0.50, 2.00, 0.05, 356, -252, "%.2f")

    local function SetAnchorControls()
        local menu = LeaPlusLC["TooltipAnchorMenu"] or 1
        if menu ~= 4 then
            LeaPlusLC:LockItem(LeaPlusCB["TipCursorX"], true)
            LeaPlusLC:LockItem(LeaPlusCB["TipCursorY"], true)
            XOffsetHeading:SetAlpha(0.3)
            YOffsetHeading:SetAlpha(0.3)
        else
            LeaPlusLC:LockItem(LeaPlusCB["TipCursorX"], false)
            LeaPlusLC:LockItem(LeaPlusCB["TipCursorY"], false)
            XOffsetHeading:SetAlpha(1.0)
            YOffsetHeading:SetAlpha(1.0)
        end
        UpdateDragFrameVisibility()
    end

    anchorDrop.OnSelect = function()
        SetAnchorControls()
    end
    SetAnchorControls()

    -- Back button
    SideTip.h:Hide()
    SideTip.b:SetScript("OnClick", function()
        if TipDrag then TipDrag:Hide() end
        SideTip:Hide()
        LeaPlusLC["PageF"]:Show()
        LeaPlusLC["Page5"]:Show()
    end)

    -- Close button (top right 'X')
    if SideTip.c then
        SideTip.c:HookScript("OnClick", function()
            if TipDrag then TipDrag:Hide() end
            if LeaPlusLC.ReleaseGrid then LeaPlusLC.ReleaseGrid() end
        end)
    end

    -- Reset button
    SideTip.r:SetScript("OnClick", function()
        LeaPlusLC["TipShowRank"] = "On"
        LeaPlusLC["TipShowOtherRank"] = "Off"
        LeaPlusLC["TipShowTarget"] = "On"
        LeaPlusLC["TipHideInCombat"] = "Off"
        SetTipHideShiftOverrideFunc()
        LeaPlusLC["TipHideShiftOverride"] = "On"
        LeaPlusLC["LeaPlusTipSize"] = 1.00
        LeaPlusLC["TipOffsetX"] = -13
        LeaPlusLC["TipOffsetY"] = 94
        LeaPlusLC["TooltipAnchorMenu"] = 1
        LeaPlusLC["TipCursorX"] = 0
        LeaPlusLC["TipCursorY"] = 0
        TipDrag:ClearAllPoints()
        TipDrag:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT",
            LeaPlusLC["TipOffsetX"], LeaPlusLC["TipOffsetY"])
        anchorDrop.RefreshList()
        SetAnchorControls()
        SetTipScale()
        SideTip:Hide(); SideTip:Show()
    end)

    -- Show / hide drag frame with panel
    SideTip:HookScript("OnShow", function()
        UpdateDragFrameVisibility()
    end)
    SideTip:HookScript("OnHide", function()
        if TipDrag then TipDrag:Hide() end
        if LeaPlusLC.ReleaseGrid then LeaPlusLC.ReleaseGrid() end
    end)

    -- Drag frame movement (Left-Drag to move freely, Right-Drag to snap to 16px grid)
    local function SnapToGrid(value, size)
        return math.floor(value / size + 0.5) * size
    end

    local dragButton = "LeftButton"
    local _, LTax, LTay, LTbx, LTby, LTcx, LTcy

    TipDrag:SetScript("OnDragStart", function(self, btn)
        dragButton = btn
        _, _, _, LTax, LTay = TipDrag:GetPoint()
        TipDrag:StartMoving()
        _, _, _, LTbx, LTby = TipDrag:GetPoint()
    end)

    TipDrag:SetScript("OnDragStop", function(self)
        _, _, _, LTcx, LTcy = TipDrag:GetPoint()
        TipDrag:StopMovingOrSizing()

        local newX = LTcx - LTbx + LTax
        local newY = LTcy - LTby + LTay

        if dragButton == "RightButton" then
            newX = SnapToGrid(newX, 16)
            newY = SnapToGrid(newY, 16)
        end

        LeaPlusLC["TipOffsetX"] = newX
        LeaPlusLC["TipOffsetY"] = newY

        TipDrag:ClearAllPoints()
        TipDrag:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", newX, newY)
    end)

    if LeaPlusCB["LeaPlusTipSize"] then
        LeaPlusCB["LeaPlusTipSize"]:HookScript("OnValueChanged", SetTipScale)
    end
    SetTipScale()

    LT["ColorBlind"] = GetCVar("colorblindMode")
    TipDrag:RegisterEvent("CVAR_UPDATE")
    TipDrag:SetScript("OnEvent", function(_, _, arg1)
        if arg1 == "colorblindMode" or arg1 == "USE_COLORBLIND_MODE" then
            LT["ColorBlind"] = GetCVar("colorblindMode")
        end
    end)
end

local function ApplyTooltipRuntime()
    local TipMClass = LOCALIZED_CLASS_NAMES_MALE or {}
    local TipFClass = LOCALIZED_CLASS_NAMES_FEMALE or TipMClass

    -- Safe 3.3.5 anchor hook
    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
        if not tooltip or not parent then return end
        local menu = LeaPlusLC["TooltipAnchorMenu"] or 1
        if menu == 1 then return end

        if menu == 2 then
            -- Custom fixed screen position (Overlay mode)
            tooltip:ClearAllPoints()
            tooltip:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT",
                LeaPlusLC["TipOffsetX"] or -13, LeaPlusLC["TipOffsetY"] or 94)
        elseif menu == 3 then
            -- Follow cursor directly
            tooltip:SetOwner(parent, "ANCHOR_CURSOR")
        elseif menu == 4 then
            -- Cursor with custom X and Y offsets (native 3.3.5 C-engine syntax)
            local x = LeaPlusLC["TipCursorX"] or 0
            local y = LeaPlusLC["TipCursorY"] or 0
            tooltip:SetOwner(parent, "ANCHOR_CURSOR", x, y)
        end
    end)

    if LeaPlusLC["TipNoHealthBar"] == "On" and GameTooltipStatusBar then
        GameTooltipStatusBar:HookScript("OnShow", function(self) self:Hide() end)
        GameTooltipStatusBar:Hide()
    end

    SetTipScale()

    local function ShowTip()
        if IsControlKeyDown() and IsAltKeyDown() and IsShiftKeyDown() then return end

        -- Clear transient unit data between inspections
        LT["Unit"] = nil
        LT["Reaction"] = nil
        LT["TipUnitName"] = nil
        LT["TipUnitRealm"] = nil
        LT["TipIsPlayer"] = nil
        LT["UnitLevel"] = nil
        LT["PlayerControl"] = nil
        LT["PlayerRace"] = nil
        LT["GuildName"] = nil
        LT["GuildRank"] = nil
        LT["GuildLine"] = nil
        LT["InfoLine"] = nil
        LT["Sex"] = nil
        LT["Class"] = nil
        LT["ClassCol"] = nil
        LT["LpTipClassColor"] = nil
        LT["NameColor"] = nil
        LT["NameText"] = nil
        LT["InfoText"] = nil
        LT["LevelColor"] = nil
        LT["MobInfoLine"] = nil
        LT["MobColor"] = nil
        LT["CreatureType"] = nil
        LT["Special"] = nil
        LT["Target"] = nil
        LT["TargetCol"] = nil

        if GetMouseFocus() == WorldFrame then
            if not UnitExists("mouseover") then return end
            LT["Unit"] = "mouseover"
            if LeaPlusLC["TipHideInCombat"] == "On" and UnitAffectingCombat("player") then
                if not IsShiftKeyDown() or LeaPlusLC["TipHideShiftOverride"] == "Off" then
                    GameTooltip:Hide()
                    return
                end
            end
        else
            LT["Unit"] = select(2, GameTooltip:GetUnit())
            if not LT["Unit"] or not UnitExists(LT["Unit"]) then return end
        end

        LT["Reaction"] = UnitReaction(LT["Unit"], "player")
        if not LT["Reaction"] then return end

        LT["TipUnitName"], LT["TipUnitRealm"] = UnitName(LT["Unit"])
        if not LT["TipUnitName"] then return end

        LT["TipIsPlayer"] = UnitIsPlayer(LT["Unit"])
        LT["UnitLevel"] = UnitLevel(LT["Unit"])
        local _, TipUnitClass = UnitClass(LT["Unit"])
        LT["PlayerControl"] = UnitPlayerControlled(LT["Unit"])
        LT["PlayerRace"] = UnitRace(LT["Unit"])

        if LT["TipIsPlayer"] then
            local unitGuild, unitRank = GetGuildInfo(LT["Unit"])
            if unitGuild and unitRank then
                if LT["ColorBlind"] == "1" then
                    LT["GuildLine"], LT["InfoLine"] = 2, 4
                else
                    LT["GuildLine"], LT["InfoLine"] = 2, 3
                end
                LT["GuildName"], LT["GuildRank"] = unitGuild, unitRank
            else
                LT["GuildName"] = nil
                if LT["ColorBlind"] == "1" then
                    LT["GuildLine"], LT["InfoLine"] = 0, 3
                else
                    LT["GuildLine"], LT["InfoLine"] = 0, 2
                end
            end
            if UnitIsCharmed(LT["Unit"]) then
                LT["InfoLine"] = LT["InfoLine"] + 1
            end
        end

        if TipUnitClass then
            LT["Sex"] = UnitSex(LT["Unit"])
            if LT["Sex"] == 2 then
                LT["Class"] = TipMClass[TipUnitClass]
            else
                LT["Class"] = TipFClass[TipUnitClass]
            end
            LT["ClassCol"] = RAID_CLASS_COLORS[TipUnitClass]
            if LT["ClassCol"] then
                LT["LpTipClassColor"] = "|cff" .. string.format("%02x%02x%02x",
                    math.floor(LT["ClassCol"].r * 255),
                    math.floor(LT["ClassCol"].g * 255),
                    math.floor(LT["ClassCol"].b * 255))
            end
        end

        if LT["TipIsPlayer"] or LT["PlayerControl"] or LT["Reaction"] > 4 then
            if LT["TipIsPlayer"] then
                LT["NameColor"] = LT["LpTipClassColor"]
            else
                if UnitIsPVP(LT["Unit"]) then
                    LT["NameColor"] = "|cff00ff00"
                else
                    LT["NameColor"] = "|cff00aaff"
                end
            end
            LT["NameText"] = UnitPVPName(LT["Unit"]) or LT["TipUnitName"]
            if LT["TipUnitRealm"] then
                LT["NameText"] = LT["NameText"] .. " - " .. LT["TipUnitRealm"]
            end
            if UnitIsDeadOrGhost(LT["Unit"]) then
                LT["NameColor"] = "|c88888888"
            end
            local nameColor = LT["NameColor"] or "|cffffffff"
            local nameText = LT["NameText"] or LT["TipUnitName"] or ""
            local line1 = _G["GameTooltipTextLeft1"]
            if line1 then
                line1:SetText(nameColor .. nameText .. "|cffffffff|r")
            end
        elseif UnitIsDeadOrGhost(LT["Unit"]) then
            local line1 = _G["GameTooltipTextLeft1"]
            if line1 then
                line1:SetText("|c88888888" .. (line1:GetText() or "") .. "|cffffffff|r")
            end
            return
        end

        if LT["TipIsPlayer"] and LT["GuildName"] and LT["GuildLine"] and LT["GuildLine"] > 0 then
            local gLine = _G["GameTooltipTextLeft" .. LT["GuildLine"]]
            if gLine then
                local showRank = (UnitIsInMyGuild(LT["Unit"]) and LeaPlusLC["TipShowRank"] == "On")
                    or (not UnitIsInMyGuild(LT["Unit"]) and LeaPlusLC["TipShowOtherRank"] == "On")
                if showRank and LT["GuildRank"] then
                    gLine:SetText("|c00aaaaff" .. LT["GuildName"] .. " - " .. LT["GuildRank"] .. "|r")
                else
                    gLine:SetText("|c00aaaaff" .. LT["GuildName"] .. "|cffffffff|r")
                end
            end
        end

        if LT["TipIsPlayer"] then
            if LT["Reaction"] < 5 then
                if LT["UnitLevel"] == -1 then
                    LT["InfoText"] = "|cffff3333" .. ttLevel .. " ??|cffffffff"
                else
                    LT["LevelColor"] = GetQuestDifficultyColor(LT["UnitLevel"])
                    LT["LevelColor"] = string.format("%02x%02x%02x",
                        math.floor(LT["LevelColor"].r * 255),
                        math.floor(LT["LevelColor"].g * 255),
                        math.floor(LT["LevelColor"].b * 255))
                    LT["InfoText"] = "|cff" .. LT["LevelColor"] .. ttLevel .. " " ..
                        LT["UnitLevel"] .. "|cffffffff"
                end
            else
                LT["InfoText"] = ttLevel .. " " .. LT["UnitLevel"]
            end
            if LT["PlayerRace"] then
                LT["InfoText"] = LT["InfoText"] .. " " .. LT["PlayerRace"]
            end
            LT["InfoText"] = LT["InfoText"] .. " " ..
                (LT["LpTipClassColor"] or "") .. (LT["Class"] or "")
            if LT["InfoLine"] and LT["InfoLine"] > 0 and _G["GameTooltipTextLeft" .. LT["InfoLine"]] then
                _G["GameTooltipTextLeft" .. LT["InfoLine"]]:SetText(LT["InfoText"] .. "|cffffffff|r")
            end
        end

        if not LT["TipIsPlayer"] and LT["Reaction"] < 4 and not LT["PlayerControl"] then
            if UnitIsTapped(LT["Unit"]) and not UnitIsTappedByPlayer(LT["Unit"]) then
                LT["NameText"] = "|c8888bbbb" .. LT["TipUnitName"] .. "|r"
            else
                LT["NameText"] = "|cffff3333" .. LT["TipUnitName"] .. "|r"
            end
            local line1 = _G["GameTooltipTextLeft1"]
            if line1 then
                line1:SetText(LT["NameText"])
            end
        end

        if UnitCanAttack(LT["Unit"], "player") and not LT["TipIsPlayer"]
            and LT["Reaction"] < 5 and not LT["PlayerControl"] then
            LT["MobInfoLine"] = 0
            local line2 = _G["GameTooltipTextLeft2"] and _G["GameTooltipTextLeft2"]:GetText()
            local line3 = _G["GameTooltipTextLeft3"] and _G["GameTooltipTextLeft3"]:GetText()
            local line4 = _G["GameTooltipTextLeft4"] and _G["GameTooltipTextLeft4"]:GetText()
            if line2 and string.lower(line2):find(LevelString) then LT["MobInfoLine"] = 2 end
            if line3 and string.lower(line3):find(LevelString) then LT["MobInfoLine"] = 3 end
            if line4 and string.lower(line4):find(LevelString) then LT["MobInfoLine"] = 4 end

            if LT["MobInfoLine"] > 1 then
                if LT["UnitLevel"] == -1 then
                    LT["InfoText"] = "|cffff3333" .. ttLevel .. " ??|cffffffff "
                else
                    LT["MobColor"] = GetQuestDifficultyColor(LT["UnitLevel"])
                    LT["MobColor"] = string.format("%02x%02x%02x",
                        math.floor(LT["MobColor"].r * 255),
                        math.floor(LT["MobColor"].g * 255),
                        math.floor(LT["MobColor"].b * 255))
                    LT["InfoText"] = "|cff" .. LT["MobColor"] .. ttLevel .. " " ..
                        LT["UnitLevel"] .. "|cffffffff "
                end
                LT["CreatureType"] = UnitCreatureType(LT["Unit"])
                if LT["CreatureType"] and LT["CreatureType"] ~= "Not specified" then
                    LT["InfoText"] = LT["InfoText"] .. "|cffffffff" ..
                        LT["CreatureType"] .. "|cffffffff "
                end

                LT["Special"] = UnitClassification(LT["Unit"])
                if LT["Special"] then
                    local mobLine = _G["GameTooltipTextLeft" .. LT["MobInfoLine"]]
                    local existingText = mobLine and mobLine:GetText()
                    if LT["Special"] == "elite" then
                        if existingText and strfind(existingText, "(" .. ttBoss .. ")") then
                            LT["Special"] = "(" .. ttBoss .. ")"
                        else
                            LT["Special"] = "(" .. ttElite .. ")"
                        end
                    elseif LT["Special"] == "rare" then
                        LT["Special"] = "|c00e066ff(" .. ttRare .. ")|r"
                    elseif LT["Special"] == "rareelite" then
                        if existingText and strfind(existingText, "(" .. ttBoss .. ")") then
                            LT["Special"] = "|c00e066ff(" .. ttRareBoss .. ")|r"
                        else
                            LT["Special"] = "|c00e066ff(" .. ttRareElite .. ")|r"
                        end
                    elseif LT["Special"] == "worldboss" then
                        LT["Special"] = "(" .. ttBoss .. ")"
                    elseif LT["UnitLevel"] == -1 and LT["Special"] == "normal"
                        and existingText and strfind(existingText, "(" .. ttBoss .. ")") then
                        LT["Special"] = "(" .. ttBoss .. ")"
                    else
                        LT["Special"] = nil
                    end
                    if LT["Special"] then
                        LT["InfoText"] = LT["InfoText"] .. LT["Special"]
                    end
                end
                local mobLine = _G["GameTooltipTextLeft" .. LT["MobInfoLine"]]
                if mobLine then
                    mobLine:SetText(LT["InfoText"])
                end
            end
        end

        if LeaPlusLC["TipShowTarget"] == "On" then
            local targetUnit = LT["Unit"] .. "target"
            LT["Target"] = UnitName(targetUnit)
            if LT["Target"] == nil or LT["Target"] == "" then return end
            if UnitIsUnit(targetUnit, "player") then
                LT["Target"] = "|c12ff4400" .. ttYou .. "|r"
            elseif UnitIsPlayer(targetUnit) then
                local _, TargetBase = UnitClass(targetUnit)
                LT["TargetCol"] = RAID_CLASS_COLORS[TargetBase]
                if LT["TargetCol"] then
                    LT["TargetCol"] = "|cff" .. string.format("%02x%02x%02x",
                        math.floor(LT["TargetCol"].r * 255),
                        math.floor(LT["TargetCol"].g * 255),
                        math.floor(LT["TargetCol"].b * 255))
                    LT["Target"] = LT["TargetCol"] .. LT["Target"] .. "|r"
                end
            end
            GameTooltip:AddLine(ttTarget .. ": " .. LT["Target"])
            GameTooltip:Show()
        end
    end

    GameTooltip:HookScript("OnTooltipSetUnit", ShowTip)
end

local function SetupTooltip()
    BuildTooltipPanel()

    if LeaPlusCB["TipModEnable"] and not LeaPlusCB["TipModEnable"].__leaTooltipHook then
        LeaPlusCB["TipModEnable"].__leaTooltipHook = true
        LeaPlusCB["TipModEnable"]:HookScript("OnShow", EnsureGearWired)
    end

    EnsureGearWired()

    if LeaPlusLC["TipModEnable"] == "On" then
        ApplyTooltipRuntime()
    end
end

function Module:OnEnable()
    SetupTooltip()
end

function Module:OnLogin() end
function Module:OnLogout(wipeData) end