-- Leatrix_Plus.lua
LibCompat = LibStub:GetLibrary("LibCompat-1.0")

-- Create global database
_G.LeaPlusDB = _G.LeaPlusDB or {}
LeaPlusDB = _G.LeaPlusDB
LeaPlusDB["ListenedTracks"] = LeaPlusDB["ListenedTracks"] or {}

-- Namespace and locals
local _, Leatrix_Plus = ...
local L = Leatrix_Plus.L

local LeaPlusLC, LeaPlusCB, LeaDropList, LeaConfigList, LeaLockList = {}, {}, {}, {}, {}
local ClientVersion = GetBuildInfo()
local GameLocale = GetLocale()
local void

-- Expose to Leatrix_Plus namespace for module access
Leatrix_Plus.LC = LeaPlusLC
Leatrix_Plus.CB = LeaPlusCB
Leatrix_Plus.DropList = LeaDropList
Leatrix_Plus.ConfigList = LeaConfigList
Leatrix_Plus.LockList = LeaLockList
Leatrix_Plus.Modules = {}

function Leatrix_Plus:RegisterModule(name, mod)
    self.Modules[name] = mod
end

-- Version constant
LeaPlusLC["AddonVer"] = "3.3.5"

-- Version guard
do
    local _, _, _, gametocversion = GetBuildInfo()
    if gametocversion and (gametocversion < 30000 or gametocversion > 30300) then
        LibCompat.After(2, function()
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000LEATRIX PLUS: WRONG VERSION INSTALLED (Requires 3.3.5)!|r")
        end)
        return
    end
end

-- Addon integration checks
if IsAddOnLoaded("ElvUI") and ElvUI then
    LeaPlusLC.ElvUI = unpack(ElvUI)
end
if IsAddOnLoaded("Glass") then
    LeaPlusLC.Glass = true
end

----------------------------------------------------------------------
--	L00: Core Variables & Bindings
----------------------------------------------------------------------

LeaPlusLC["ShowErrorsFlag"] = 1
LeaPlusLC["NumberOfPages"] = 9
LeaPlusLC["RaidColors"] = RAID_CLASS_COLORS

local LpEvt = CreateFrame("FRAME")
LpEvt:RegisterEvent("ADDON_LOADED")
LpEvt:RegisterEvent("PLAYER_LOGIN")
LpEvt:RegisterEvent("PLAYER_ENTERING_WORLD")

_G.BINDING_HEADER_LEATRIX_PLUS = "Leatrix Plus"
_G.BINDING_NAME_LEATRIX_PLUS_GLOBAL_TOGGLE = L["Toggle panel"]
_G.BINDING_NAME_LEATRIX_PLUS_GLOBAL_WEBLINK = L["Show web link"]
_G.BINDING_NAME_LEATRIX_PLUS_GLOBAL_RARE = L["Announce rare"]

----------------------------------------------------------------------
--	L01: Core Utility Functions
----------------------------------------------------------------------

function LeaPlusLC:Print(text)
    DEFAULT_CHAT_FRAME:AddMessage(L[text], 1.0, 0.85, 0.0)
end

function LeaPlusLC:LockItem(item, lock)
    if not item then return end
    if lock then
        item:Disable()
        item:SetAlpha(0.3)
    else
        item:Enable()
        item:SetAlpha(1.0)
    end
end

function LeaPlusLC:HideConfigPanels()
    for _, v in pairs(LeaConfigList) do
        v:Hide()
    end
end

function LeaPlusLC:CheckIfQuestIsSharedAndShouldBeDeclined()
    if LeaPlusLC["NoSharedQuests"] == "On" then
        local npcName = UnitName("questnpc")
        if npcName and (UnitInParty(npcName) or UnitInRaid(npcName)) then
            if not LeaPlusLC:FriendCheck(npcName) then
                DeclineQuest()
            end
        end
    end
end

function LeaPlusLC:ShowSystemEditBox(word, focuschat)
    if not LeaPlusLC.FactoryEditBox then
        local eFrame = CreateFrame("FRAME", nil, UIParent)
        LeaPlusLC.FactoryEditBox = eFrame
        eFrame:SetSize(700, 110)
        eFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
        eFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        eFrame:EnableMouse(true)
        eFrame:EnableKeyboard(true)
        eFrame:SetScript("OnMouseDown", function(_, btn)
            if btn == "RightButton" then eFrame:Hide() end
        end)

        eFrame.t = eFrame:CreateTexture(nil, "BACKGROUND")
        eFrame.t:SetAllPoints()
        eFrame.t:SetTexture(0.05, 0.05, 0.05, 0.9)

        eFrame.f = eFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        eFrame.f:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 12, -52)
        eFrame.f:SetWidth(676)
        eFrame.f:SetJustifyH("LEFT")
        eFrame.f:SetWordWrap(false)

        eFrame.c = eFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        eFrame.c:SetText(L["Press CTRL/C to copy"])
        eFrame.c:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 12, -82)

        local feedback = eFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        feedback:SetText("|cff00ff00Feedback Discord:|r |cffadd8e6sattva108|r")
        feedback:SetPoint("TOPRIGHT", eFrame, "TOPRIGHT", -12, -52)

        hooksecurefunc(eFrame.f, "SetText", function()
            eFrame.f:SetWidth(676 - feedback:GetStringWidth() - 26)
        end)

        local cancelLabel = eFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        cancelLabel:SetText(L["Right-click to close"])
        cancelLabel:SetPoint("TOPRIGHT", eFrame, "TOPRIGHT", -12, -82)

        eFrame.b = CreateFrame("EditBox", "LeatrixSystemEditBox", eFrame, "InputBoxTemplate")
        eFrame.b:ClearAllPoints()
        eFrame.b:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 16, -12)
        eFrame.b:SetSize(672, 24)
        eFrame.b:SetFontObject("GameFontNormalLarge")
        eFrame.b:SetTextColor(1.0, 1.0, 1.0, 1)
        eFrame.b:DisableDrawLayer("BACKGROUND")
        eFrame.b:SetHitRectInsets(99, 99, 99, 99)
        eFrame.b:SetAutoFocus(true)
        eFrame.b:SetAltArrowKeyMode(true)
        eFrame.b:EnableMouse(true)
        eFrame.b:EnableKeyboard(true)

        eFrame.bg = CreateFrame("FRAME", nil, eFrame.b)
        eFrame.bg:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, tileSize = 16, edgeSize = 16,
            insets = { left = 5, right = 5, top = 5, bottom = 5 }
        })
        eFrame.bg:SetPoint("LEFT", -6, 0)
        eFrame.bg:SetWidth(eFrame.b:GetWidth() + 6)
        eFrame.bg:SetHeight(eFrame.b:GetHeight())
        eFrame.bg:SetBackdropColor(1.0, 1.0, 1.0, 0.3)

        eFrame.b:SetScript("OnChar", function()
            eFrame.b:SetText(word)
            eFrame.b:HighlightText()
        end)
        eFrame.b:SetScript("OnMouseUp", function()
            eFrame.b:HighlightText()
        end)
        eFrame.b:SetScript("OnEscapePressed", function()
            eFrame:Hide()
        end)
    end

    LeaPlusLC.FactoryEditBox:Show()
    LeaPlusLC.FactoryEditBox.b:SetText(word)
    LeaPlusLC.FactoryEditBox.b:SetFocus(true)
    LeaPlusLC.FactoryEditBox.b:HighlightText()
end

function LeaPlusLC:LoadVarChk(var, def)
    if LeaPlusDB[var] and type(LeaPlusDB[var]) == "string" and (LeaPlusDB[var] == "On" or LeaPlusDB[var] == "Off") then
        LeaPlusLC[var] = LeaPlusDB[var]
    else
        LeaPlusLC[var] = def
        LeaPlusDB[var] = def
    end
end

function LeaPlusLC:LoadVarNum(var, def, valmin, valmax)
    if LeaPlusDB[var] and type(LeaPlusDB[var]) == "number" and LeaPlusDB[var] >= valmin and LeaPlusDB[var] <= valmax then
        LeaPlusLC[var] = LeaPlusDB[var]
    else
        LeaPlusLC[var] = def
        LeaPlusDB[var] = def
    end
end

function LeaPlusLC:LoadVarAnc(var, def)
    local v = LeaPlusDB[var]
    if v and (v == "CENTER" or v == "TOP" or v == "BOTTOM" or v == "LEFT" or v == "RIGHT" or v == "TOPLEFT" or v == "TOPRIGHT" or v == "BOTTOMLEFT" or v == "BOTTOMRIGHT") then
        LeaPlusLC[var] = v
    else
        LeaPlusLC[var] = def
        LeaPlusDB[var] = def
    end
end

function LeaPlusLC:LoadVarStr(var, def)
    if LeaPlusDB[var] and type(LeaPlusDB[var]) == "string" then
        LeaPlusLC[var] = LeaPlusDB[var]
    else
        LeaPlusLC[var] = def
        LeaPlusDB[var] = def
    end
end

function LeaPlusLC:TipSee()
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    local parent = self:GetParent()
    local pscale = parent:GetEffectiveScale()
    local gscale = UIParent:GetEffectiveScale()
    local tscale = GameTooltip:GetEffectiveScale()
    local gap = ((UIParent:GetRight() * gscale) - (parent:GetRight() * pscale))
    if gap < (250 * tscale) then
        GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
    else
        GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
    end
    GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
end

function LeaPlusLC:ShowDropTip()
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    local parent = self:GetParent():GetParent():GetParent()
    local pscale = parent:GetEffectiveScale()
    local gscale = UIParent:GetEffectiveScale()
    local tscale = GameTooltip:GetEffectiveScale()
    local gap = ((UIParent:GetRight() * gscale) - (parent:GetRight() * pscale))
    if gap < (250 * tscale) then
        GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
    else
        GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
    end
    GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
end

function LeaPlusLC:ShowTooltip()
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    local parent = LeaPlusLC["PageF"]
    local pscale = parent:GetEffectiveScale()
    local gscale = UIParent:GetEffectiveScale()
    local tscale = GameTooltip:GetEffectiveScale()
    local gap = ((UIParent:GetRight() * gscale) - (LeaPlusLC["PageF"]:GetRight() * pscale))
    if gap < (250 * tscale) then
        GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
    else
        GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
    end
    GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
end

function LeaPlusLC:CfgBtn(name, parent)
    local btn = CreateFrame("BUTTON", nil, parent)
    LeaPlusCB[name] = btn
    btn:SetWidth(20)
    btn:SetHeight(20)
    btn:SetPoint("LEFT", parent.f, "RIGHT", 0, 0)

    btn.t = btn:CreateTexture(nil, "BORDER")
    btn.t:SetAllPoints()
    btn.t:SetTexture("Interface\\WorldMap\\Gear_64.png")
    btn.t:SetTexCoord(0, 0.50, 0, 0.50)
    btn.t:SetVertexColor(1.0, 0.82, 0, 1.0)

    btn:SetHighlightTexture("Interface\\WorldMap\\Gear_64.png")
    btn:GetHighlightTexture():SetTexCoord(0, 0.50, 0, 0.50)

    btn.tiptext = L["Click to configure the settings for this option."]
    btn:SetScript("OnEnter", LeaPlusLC.ShowTooltip)
    btn:SetScript("OnLeave", GameTooltip_Hide)
end

function LeaPlusLC:CreateHelpButton(frame, panel, parent, tip)
    LeaPlusLC:CfgBtn(frame, panel)
    LeaPlusCB[frame]:ClearAllPoints()
    LeaPlusCB[frame]:SetPoint("LEFT", parent, "RIGHT", -parent:GetWidth() + parent:GetStringWidth(), 0)
    LeaPlusCB[frame]:SetSize(25, 25)
    LeaPlusCB[frame].t:SetTexture("Interface\\COMMON\\help-i.blp")
    LeaPlusCB[frame].t:SetTexCoord(0, 1, 0, 1)
    LeaPlusCB[frame].t:SetVertexColor(0.9, 0.8, 0.0)
    LeaPlusCB[frame]:SetHighlightTexture("Interface\\COMMON\\help-i.blp")
    LeaPlusCB[frame]:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
    LeaPlusCB[frame].tiptext = L[tip]
    LeaPlusCB[frame]:SetScript("OnEnter", LeaPlusLC.TipSee)
end

local function toggleFrameStack(msg)
    UIParentLoadAddOn("Blizzard_DebugTools")
    if msg == tostring(true) then
        FrameStackTooltip_Toggle(true)
    else
        FrameStackTooltip_Toggle()
    end
end
SLASH_FRAMESTACK1 = "/fs"
SlashCmdList["FRAMESTACK"] = toggleFrameStack

function LeaPlusLC:MakeFT(frame, text, left, width)
    local footer = LeaPlusLC:MakeTx(frame, text, left, 96)
    footer:SetWidth(width)
    footer:SetJustifyH("LEFT")
    footer:SetWordWrap(true)
    footer:ClearAllPoints()
    footer:SetPoint("BOTTOMLEFT", left, 96)
end

function LeaPlusLC:CapFirst(str)
    return gsub(string.lower(str), "^%l", strupper)
end

function LeaPlusLC:ZygorToggle()
    local name = select(2, GetAddOnInfo("ZygorGuidesViewer")) and "ZygorGuidesViewer" or "ZygorGuidesViewerClassic"
    if select(2, GetAddOnInfo(name)) then
        if not IsAddOnLoaded(name) then
            if LeaPlusLC:PlayerInCombat() then return end
            EnableAddOn(name)
            ReloadUI()
        else
            DisableAddOn(name)
            ReloadUI()
        end
    else
        LeaPlusLC:Print("Zygor addon not found.")
    end
end

function LeaPlusLC:ShowMemoryUsage(frame, anchor, x, y)
    local memframe = CreateFrame("FRAME", nil, frame)
    memframe:ClearAllPoints()
    memframe:SetPoint(anchor, x, y)
    memframe:SetWidth(100)
    memframe:SetHeight(20)

    local pretext = memframe:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    pretext:SetPoint("TOPLEFT", 0, 0)
    pretext:SetText(L["Memory Usage"])

    local memtext = memframe:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    memtext:SetPoint("TOPLEFT", 0, -30)

    local memstat = memframe:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    memstat:SetPoint("BOTTOMLEFT", memtext, "BOTTOMRIGHT")
    memstat:SetText("(calculating...)")

    local memtime = -1
    memframe:SetScript("OnUpdate", function(self, elapsed)
        if memtime > 2 or memtime == -1 then
            UpdateAddOnMemoryUsage()
            local usage = GetAddOnMemoryUsage("Leatrix_Plus")
            memstat:SetText(math.floor(usage + 0.5) .. " KB")
            memtime = 0
        end
        memtime = memtime + elapsed
    end)
    LeaPlusLC.ShowMemoryUsage = nil
end

function LeaPlusLC:IsInLFGQueue()
    if MiniMapLFGFrame and MiniMapLFGFrame:IsShown() then
        return true
    end
    return false
end

function LeaPlusLC:PlayerInCombat()
    if UnitAffectingCombat("player") then
        LeaPlusLC:Print("You cannot do that in combat.")
        return true
    end
    return false
end

function LeaPlusLC:HideFrames()
    for i = 0, LeaPlusLC["NumberOfPages"] do
        if LeaPlusLC["Page" .. i] then
            LeaPlusLC["Page" .. i]:Hide()
        end
    end
    LeaPlusLC["PageF"]:Hide()
end

function LeaPlusLC:IsPlusShowing()
    if LeaPlusLC["PageF"]:IsShown() then return true end
    for _, v in pairs(LeaConfigList) do
        if v:IsShown() then return true end
    end
    return false
end

function LeaPlusLC:FriendCheck(name)
    if not name or name == "" then return false end
    name = strsplit("-", name, 2)
    local lowerName = strlower(name)

    -- Character friends
    for i = 1, GetNumFriends() do
        local fName, _, _, _, fConnected = GetFriendInfo(i)
        if fName then
            fName = strsplit("-", fName, 2)
            if strlower(fName) == lowerName and fConnected then
                return true
            end
        end
    end

    -- Guild members
    if LeaPlusLC["FriendlyGuild"] == "On" and IsInGuild() then
        for i = 1, GetNumGuildMembers() do
            local gName, _, _, _, _, _, _, _, gOnline = GetGuildRosterInfo(i)
            if gName and gOnline then
                gName = strsplit("-", gName, 2)
                if strlower(gName) == lowerName then
                    return true
                end
            end
        end
    end

    return false
end

----------------------------------------------------------------------
--	L02: Lock State
----------------------------------------------------------------------

function LeaPlusLC:LockOption(option, item, reloadreq)
    if reloadreq then
        if LeaPlusLC[option] ~= LeaPlusDB[option] or LeaPlusLC[option] == "Off" then
            LeaPlusLC:LockItem(LeaPlusCB[item], true)
        else
            LeaPlusLC:LockItem(LeaPlusCB[item], false)
        end
    else
        if LeaPlusLC[option] == "Off" then
            LeaPlusLC:LockItem(LeaPlusCB[item], true)
        else
            LeaPlusLC:LockItem(LeaPlusCB[item], false)
        end
    end
end

function LeaPlusLC:SetDim()
    LeaPlusLC:LockOption("AutomateQuests", "AutomateQuestsBtn", false)
    LeaPlusLC:LockOption("AutoAcceptRes", "AutoAcceptResBtn", false)
    LeaPlusLC:LockOption("AutoReleasePvP", "AutoReleasePvPBtn", false)
    LeaPlusLC:LockOption("AutoSellJunk", "AutoSellJunkBtn", false)
    LeaPlusLC:LockOption("AutoRepairGear", "AutoRepairBtn", false)
    LeaPlusLC:LockOption("InviteFromWhisper", "InvWhisperBtn", false)
    LeaPlusLC:LockOption("FilterChatMessages", "FilterChatMessagesBtn", true)
    LeaPlusLC:LockOption("MailFontChange", "MailTextBtn", true)
    LeaPlusLC:LockOption("QuestFontChange", "QuestTextBtn", true)
    LeaPlusLC:LockOption("BookFontChange", "BookTextBtn", true)
    LeaPlusLC:LockOption("MinimapModder", "ModMinimapBtn", true)
    LeaPlusLC:LockOption("TipModEnable", "MoveTooltipButton", true)
    LeaPlusLC:LockOption("EnhanceQuestLog", "EnhanceQuestLogBtn", true)
    LeaPlusLC:LockOption("EnhanceTrainers", "EnhanceTrainersBtn", true)
    LeaPlusLC:LockOption("ShowPlayerChain", "ModPlayerChain", true)
    LeaPlusLC:LockOption("ShowWowheadLinks", "ShowWowheadLinksBtn", true)
    LeaPlusLC:LockOption("ShowFlightTimes", "ShowFlightTimesBtn", true)
    LeaPlusLC:LockOption("FrmEnabled", "MoveFramesButton", true)
    LeaPlusLC:LockOption("ManageBuffs", "ManageBuffsButton", true)
    LeaPlusLC:LockOption("ManageDeBuffs", "ManageDeBuffsButton", true)
    LeaPlusLC:LockOption("ManageWidget", "ManageWidgetButton", true)
    LeaPlusLC:LockOption("ManageFocus", "ManageFocusButton", true)
    LeaPlusLC:LockOption("ManageTimer", "ManageTimerButton", true)
    LeaPlusLC:LockOption("ManageDurability", "ManageDurabilityButton", true)
    LeaPlusLC:LockOption("ManageTracker", "ManageTrackerButton", true)
    LeaPlusLC:LockOption("ManageVehicle", "ManageVehicleButton", true)
    LeaPlusLC:LockOption("ClassColFrames", "ClassColFramesBtn", true)
    LeaPlusLC:LockOption("SetWeatherDensity", "SetWeatherDensityBtn", false)
    LeaPlusLC:LockOption("ViewPortEnable", "ModViewportBtn", true)
    LeaPlusLC:LockOption("FasterLooting", "ModFasterLootingBtn", true)
end

----------------------------------------------------------------------
--	L03: Reload Detection
----------------------------------------------------------------------

function LeaPlusLC:ReloadCheck()
    if (LeaPlusLC["UseEasyChatResizing"] ~= LeaPlusDB["UseEasyChatResizing"])
            or (LeaPlusLC["NoCombatLogTab"] ~= LeaPlusDB["NoCombatLogTab"])
            or (LeaPlusLC["NoChatButtons"] ~= LeaPlusDB["NoChatButtons"])
            or (LeaPlusLC["UnclampChat"] ~= LeaPlusDB["UnclampChat"])
            or (LeaPlusLC["MoveChatEditBoxToTop"] ~= LeaPlusDB["MoveChatEditBoxToTop"])
            or (LeaPlusLC["MoreFontSizes"] ~= LeaPlusDB["MoreFontSizes"])
            or (LeaPlusLC["AltClickInv"] ~= LeaPlusDB["AltClickInv"])
            or (LeaPlusLC["NoStickyChat"] ~= LeaPlusDB["NoStickyChat"])
            or (LeaPlusLC["UseArrowKeysInChat"] ~= LeaPlusDB["UseArrowKeysInChat"])
            or (LeaPlusLC["NoChatFade"] ~= LeaPlusDB["NoChatFade"])
            or (LeaPlusLC["ClassColorsInChat"] ~= LeaPlusDB["ClassColorsInChat"])
            or (LeaPlusLC["RecentChatWindow"] ~= LeaPlusDB["RecentChatWindow"])
            or (LeaPlusLC["MaxChatHstory"] ~= LeaPlusDB["MaxChatHstory"])
            or (LeaPlusLC["FilterChatMessages"] ~= LeaPlusDB["FilterChatMessages"])
            or (LeaPlusLC["RestoreChatMessages"] ~= LeaPlusDB["RestoreChatMessages"])
            or (LeaPlusLC["NoHitIndicators"] ~= LeaPlusDB["NoHitIndicators"])
            or (LeaPlusLC["HideZoneText"] ~= LeaPlusDB["HideZoneText"])
            or (LeaPlusLC["HideKeybindText"] ~= LeaPlusDB["HideKeybindText"])
            or (LeaPlusLC["HideMacroText"] ~= LeaPlusDB["HideMacroText"])
            or (LeaPlusLC["MailFontChange"] ~= LeaPlusDB["MailFontChange"])
            or (LeaPlusLC["QuestFontChange"] ~= LeaPlusDB["QuestFontChange"])
            or (LeaPlusLC["BookFontChange"] ~= LeaPlusDB["BookFontChange"])
            or (LeaPlusLC["MinimapModder"] ~= LeaPlusDB["MinimapModder"])
            or (LeaPlusLC["HideMiniAddonButtons"] ~= LeaPlusDB["HideMiniAddonButtons"])
            or (LeaPlusLC["SquareMinimap"] ~= LeaPlusDB["SquareMinimap"])
            or (LeaPlusLC["CombineAddonButtons"] ~= LeaPlusDB["CombineAddonButtons"])
            or (LeaPlusLC["HideMiniTracking"] ~= LeaPlusDB["HideMiniTracking"])
            or (LeaPlusLC["HideMiniCalendar"] ~= LeaPlusDB["HideMiniCalendar"])
            or (LeaPlusLC["MiniExcludeList"] ~= LeaPlusDB["MiniExcludeList"])
            or (LeaPlusLC["TipModEnable"] ~= LeaPlusDB["TipModEnable"])
            or (LeaPlusLC["TipNoHealthBar"] ~= LeaPlusDB["TipNoHealthBar"])
            or (LeaPlusLC["EnhanceDressup"] ~= LeaPlusDB["EnhanceDressup"])
            or (LeaPlusLC["EnhanceQuestLog"] ~= LeaPlusDB["EnhanceQuestLog"])
            or (LeaPlusLC["EnhanceProfessions"] ~= LeaPlusDB["EnhanceProfessions"])
            or (LeaPlusLC["EnhanceTrainers"] ~= LeaPlusDB["EnhanceTrainers"])
            or (LeaPlusLC["ShowVolume"] ~= LeaPlusDB["ShowVolume"])
            or (LeaPlusLC["AhExtras"] ~= LeaPlusDB["AhExtras"])
            or (LeaPlusLC["DurabilityStatus"] ~= LeaPlusDB["DurabilityStatus"])
            or (LeaPlusLC["ShowVanityControls"] ~= LeaPlusDB["ShowVanityControls"])
            or (LeaPlusLC["ShowBagSearchBox"] ~= LeaPlusDB["ShowBagSearchBox"])
            or (LeaPlusLC["ShowPlayerChain"] ~= LeaPlusDB["ShowPlayerChain"])
            or (LeaPlusLC["ShowReadyTimer"] ~= LeaPlusDB["ShowReadyTimer"])
            or (LeaPlusLC["ShowWowheadLinks"] ~= LeaPlusDB["ShowWowheadLinks"])
            or (LeaPlusLC["ShowFlightTimes"] ~= LeaPlusDB["ShowFlightTimes"])
            or (LeaPlusLC["FrmEnabled"] ~= LeaPlusDB["FrmEnabled"])
            or (LeaPlusLC["ManageBuffs"] ~= LeaPlusDB["ManageBuffs"])
            or (LeaPlusLC["ManageDeBuffs"] ~= LeaPlusDB["ManageDeBuffs"])
            or (LeaPlusLC["ManageWidget"] ~= LeaPlusDB["ManageWidget"])
            or (LeaPlusLC["ManageFocus"] ~= LeaPlusDB["ManageFocus"])
            or (LeaPlusLC["ManageTimer"] ~= LeaPlusDB["ManageTimer"])
            or (LeaPlusLC["ManageDurability"] ~= LeaPlusDB["ManageDurability"])
            or (LeaPlusLC["ManageTracker"] ~= LeaPlusDB["ManageTracker"])
            or (LeaPlusLC["ManageVehicle"] ~= LeaPlusDB["ManageVehicle"])
            or (LeaPlusLC["ClassColFrames"] ~= LeaPlusDB["ClassColFrames"])
            or (LeaPlusLC["NoAlerts"] ~= LeaPlusDB["NoAlerts"])
            or (LeaPlusLC["NoGryphons"] ~= LeaPlusDB["NoGryphons"])
            or (LeaPlusLC["NoClassBar"] ~= LeaPlusDB["NoClassBar"])
            or (LeaPlusLC["ViewPortEnable"] ~= LeaPlusDB["ViewPortEnable"])
            or (LeaPlusLC["NoRestedEmotes"] ~= LeaPlusDB["NoRestedEmotes"])
            or (LeaPlusLC["NoBagAutomation"] ~= LeaPlusDB["NoBagAutomation"])
            or (LeaPlusLC["FasterLooting"] ~= LeaPlusDB["FasterLooting"])
            or (LeaPlusLC["FasterMovieSkip"] ~= LeaPlusDB["FasterMovieSkip"])
            or (LeaPlusLC["CombatPlates"] ~= LeaPlusDB["CombatPlates"])
            or (LeaPlusLC["EasyItemDestroy"] ~= LeaPlusDB["EasyItemDestroy"])
    then
        LeaPlusLC:LockItem(LeaPlusCB["ReloadUIButton"], false)
        LeaPlusCB["ReloadUIButton"].f:Show()
    else
        LeaPlusLC:LockItem(LeaPlusCB["ReloadUIButton"], true)
        LeaPlusCB["ReloadUIButton"].f:Hide()
    end
end

----------------------------------------------------------------------
--	L20: Live Toggles
----------------------------------------------------------------------

function LeaPlusLC:Live()
    if LeaPlusLC["InviteFromWhisper"] == "On" then
        LpEvt:RegisterEvent("CHAT_MSG_WHISPER")
    else
        LpEvt:UnregisterEvent("CHAT_MSG_WHISPER")
    end

    if LeaPlusLC["NoDuelRequests"] == "On" then
        LpEvt:RegisterEvent("DUEL_REQUESTED")
    else
        LpEvt:UnregisterEvent("DUEL_REQUESTED")
    end

    if LeaPlusLC["NoPartyInvites"] == "On" or LeaPlusLC["AcceptPartyFriends"] == "On" then
        LpEvt:RegisterEvent("PARTY_INVITE_REQUEST")
    else
        LpEvt:UnregisterEvent("PARTY_INVITE_REQUEST")
    end

    if LeaPlusLC["NoGuildInvites"] == "On" then
        LpEvt:RegisterEvent("GUILD_INVITE_REQUEST")
    else
        LpEvt:UnregisterEvent("GUILD_INVITE_REQUEST")
    end

    if LeaPlusLC["AutoAcceptSummon"] == "On" then
        LpEvt:RegisterEvent("CONFIRM_SUMMON")
    else
        LpEvt:UnregisterEvent("CONFIRM_SUMMON")
    end

    if LeaPlusLC["NoConfirmLoot"] == "On" then
        LpEvt:RegisterEvent("CONFIRM_LOOT_ROLL")
        LpEvt:RegisterEvent("LOOT_BIND_CONFIRM")
        LpEvt:RegisterEvent("CONFIRM_DISENCHANT_ROLL")
    else
        LpEvt:UnregisterEvent("CONFIRM_LOOT_ROLL")
        LpEvt:UnregisterEvent("LOOT_BIND_CONFIRM")
        LpEvt:UnregisterEvent("CONFIRM_DISENCHANT_ROLL")
    end
end

----------------------------------------------------------------------
--	L30: Isolated Features
----------------------------------------------------------------------

function LeaPlusLC:Isolated()
    -- Easy item destroy
    if LeaPlusLC["EasyItemDestroy"] == "On" then
        hooksecurefunc("StaticPopup_Show", function(which)
            if which == "DELETE_GOOD_ITEM" or which == "DELETE_ITEM" then
                local dialog = StaticPopup_Visible(which)
                if dialog and _G[dialog .. "Button1"] then
                    local editBox = _G[dialog .. "EditBox"]
                    if editBox and editBox:IsShown() then
                        editBox:Hide()
                    end
                    _G[dialog .. "Button1"]:Enable()
                end
            end
        end)
    end

    -- Faster movie skip
    if LeaPlusLC["FasterMovieSkip"] == "On" and CinematicFrame then
        CinematicFrame:HookScript("OnShow", function(self)
            HideUIPanel(self)
            LibCompat.After(0.01, function()
                StopCinematic()
            end)
        end)
    end

    -- Unclamp chat frame
    if LeaPlusLC["UnclampChat"] == "On" and not LeaLockList["UnclampChat"] then
        for i = 1, NUM_CHAT_WINDOWS do
            local cf = _G["ChatFrame" .. i]
            if cf then cf:SetClampRectInsets(0, 0, 0, 0) end
        end
        hooksecurefunc("FCF_OpenTemporaryWindow", function()
            local cf = FCF_GetCurrentChatFrame()
            if cf then cf:SetClampRectInsets(0, 0, 0, 0) end
        end)
    end

    -- Disable bag automation
    if LeaPlusLC["NoBagAutomation"] == "On" and not LeaLockList["NoBagAutomation"] then
        local bAuto = CreateFrame("Frame")
        bAuto:RegisterEvent("MERCHANT_SHOW")
        bAuto:RegisterEvent("MERCHANT_CLOSED")
        local wasOpen = false
        bAuto:SetScript("OnEvent", function(_, event)
            if event == "MERCHANT_SHOW" then
                wasOpen = IsBagOpen(0)
                CloseBackpack()
            elseif event == "MERCHANT_CLOSED" and not wasOpen then
                CloseBackpack()
            end
        end)
    end

    -- Resize Fonts
    if LeaPlusLC["QuestFontChange"] == "On" and not LeaLockList["QuestFontChange"] then
        local function UpdateQuestFont()
            local fontName, _, fontFlags = QuestFont:GetFont()
            local size = LeaPlusLC["LeaPlusQuestFontSize"] or 12
            QuestTitleFont:SetFont(fontName, size + 3, fontFlags)
            QuestFont:SetFont(fontName, size + 1, fontFlags)
            QuestFontNormalSmall:SetFont(fontName, size, fontFlags)
        end
        UpdateQuestFont()
        if LeaPlusCB["LeaPlusQuestFontSize"] then
            LeaPlusCB["LeaPlusQuestFontSize"]:HookScript("OnValueChanged", UpdateQuestFont)
        end
    end

    if LeaPlusLC["MailFontChange"] == "On" then
        local function UpdateMailFont()
            local fontName, _, fontFlags = QuestFont:GetFont()
            local size = LeaPlusLC["LeaPlusMailFontSize"] or 15
            OpenMailBodyText:SetFont(fontName, size, fontFlags)
            SendMailBodyEditBox:SetFont(fontName, size, fontFlags)
        end
        UpdateMailFont()
        if LeaPlusCB["LeaPlusMailFontSize"] then
            LeaPlusCB["LeaPlusMailFontSize"]:HookScript("OnValueChanged", UpdateMailFont)
        end
    end

    if LeaPlusLC["BookFontChange"] == "On" then
        local function UpdateBookFont()
            local fontName, _, fontFlags = QuestFont:GetFont()
            local size = LeaPlusLC["LeaPlusBookFontSize"] or 15
            ItemTextFontNormal:SetFont(fontName, size, fontFlags)
        end
        UpdateBookFont()
        if LeaPlusCB["LeaPlusBookFontSize"] then
            LeaPlusCB["LeaPlusBookFontSize"]:HookScript("OnValueChanged", UpdateBookFont)
        end
    end

    -- Hide Zone Text
    if LeaPlusLC["HideZoneText"] == "On" then
        ZoneTextFrame:SetScript("OnShow", ZoneTextFrame.Hide)
        SubZoneTextFrame:SetScript("OnShow", SubZoneTextFrame.Hide)
    end

    LeaPlusLC.Isolated = nil
end

----------------------------------------------------------------------
--	L40: Player Login Initializations
----------------------------------------------------------------------

function LeaPlusLC:Player()
    -- Durability status tooltip on character frame
    if LeaPlusLC["DurabilityStatus"] == "On" and PaperDollFrame then
        local dBtn = CreateFrame("BUTTON", nil, PaperDollFrame)
        dBtn:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -40, 80)
        dBtn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
        dBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        dBtn:SetSize(32, 32)

        local slots = { "HeadSlot", "ShoulderSlot", "ChestSlot", "WristSlot", "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "MainHandSlot", "SecondaryHandSlot", "RangedSlot" }
        dBtn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(dBtn, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["Durability"], 1.0, 0.85, 0.0)

            local totalCur, totalMax = 0, 0
            for _, slotName in ipairs(slots) do
                local slotID = GetInventorySlotInfo(slotName)
                if slotID then
                    local cur, maxDur = GetInventoryItemDurability(slotID)
                    if cur and maxDur and maxDur > 0 then
                        totalCur = totalCur + cur
                        totalMax = totalMax + maxDur
                        local pct = floor(cur / maxDur * 100)
                        local col = (pct >= 80 and "|cff00ff00") or (pct >= 40 and "|cffffff00") or "|cffff2000"
                        GameTooltip:AddDoubleLine(_G[string.upper(slotName)] or slotName, col .. pct .. "%|r")
                    end
                end
            end
            if totalMax > 0 then
                local totalPct = floor(totalCur / totalMax * 100)
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine(L["Overall"], totalPct .. "%", 1, 1, 1, 0, 1, 0)
            else
                GameTooltip:AddLine(L["No items with durability equipped."], 1, 1, 1)
            end
            GameTooltip:Show()
        end)
        dBtn:SetScript("OnLeave", GameTooltip_Hide)
    end

    -- Vanity controls (helm/cloak checkboxes)
    if LeaPlusLC["ShowVanityControls"] == "On" and PaperDollFrame then
        LeaPlusLC:MakeCB(PaperDollFrame, "ShowHelm", L["Helm"], 65, -246, false, "")
        LeaPlusLC:MakeCB(PaperDollFrame, "ShowCloak", L["Cloak"], 275, -246, false, "")
        LeaPlusCB["ShowHelm"]:SetFrameStrata("HIGH")
        LeaPlusCB["ShowCloak"]:SetFrameStrata("HIGH")

        LeaPlusCB["ShowHelm"]:SetScript("OnClick", function(self)
            ShowHelm(self:GetChecked())
        end)
        LeaPlusCB["ShowCloak"]:SetScript("OnClick", function(self)
            ShowCloak(self:GetChecked())
        end)
        PaperDollFrame:HookScript("OnShow", function()
            LeaPlusCB["ShowHelm"]:SetChecked(ShowingHelm())
            LeaPlusCB["ShowCloak"]:SetChecked(ShowingCloak())
        end)
    end

    -- Volume Slider
    if LeaPlusLC["ShowVolume"] == "On" and CharacterModelFrame then
        LeaPlusLC["LeaPlusMaxVol"] = tonumber(GetCVar("Sound_MasterVolume")) or 1
        LeaPlusLC:MakeSL(CharacterModelFrame, "LeaPlusMaxVol", "", 0, 1, 0.05, -42, -328, "%.2f")
        LeaPlusCB["LeaPlusMaxVol"]:SetWidth(64)
        LeaPlusCB["LeaPlusMaxVol"]:HookScript("OnValueChanged", function(_, val)
            SetCVar("Sound_MasterVolume", val)
        end)
    end

    -- Tooltip Unit Class and Target fixes
    if LeaPlusLC["TipModEnable"] == "On" and not LeaLockList["TipModEnable"] then
        GameTooltip:HookScript("OnTooltipSetUnit", function(self)
            local _, unit = self:GetUnit()
            if not unit then return end

            if LeaPlusLC["TipShowTarget"] == "On" then
                local targetUnit = unit .. "target"
                if UnitExists(targetUnit) then
                    local targetName = UnitName(targetUnit)
                    local _, targetClass = UnitClass(targetUnit)
                    local color = targetClass and RAID_CLASS_COLORS[targetClass] or NORMAL_FONT_COLOR
                    self:AddDoubleLine(L["Target"] .. ":", targetName, 1, 0.82, 0, color.r, color.g, color.b)
                end
            end
        end)
    end

    -- Minimap Icon via LibDBIcon
    local ldb = LibStub("LibDataBroker-1.1", true)
    local dbIcon = LibStub("LibDBIcon-1.0", true)
    if ldb and dbIcon and not LeaPlusLC.LDBRegistered then
        LeaPlusLC.LDBRegistered = true
        local ltpObj = ldb:NewDataObject("Leatrix_Plus", {
            type = "data source",
            text = "Leatrix Plus",
            icon = "Interface\\addons\\Leatrix_Plus\\assets\\reportlagicon-movement",
            OnClick = function(_, btn)
                if btn == "RightButton" then
                    ReloadUI()
                else
                    if LeaPlusLC:IsPlusShowing() then
                        LeaPlusLC:HideFrames()
                        LeaPlusLC:HideConfigPanels()
                    else
                        LeaPlusLC:HideFrames()
                        LeaPlusLC["PageF"]:Show()
                        LeaPlusLC["Page" .. (LeaPlusLC["LeaStartPage"] or 0)]:Show()
                    end
                end
            end,
            OnTooltipShow = function(tip)
                tip:AddLine("Leatrix Plus")
                tip:AddLine("|cffeda55fClick|r to toggle options.", 0.2, 1, 0.2)
                tip:AddLine("|cffeda55fRight-Click|r to reload UI.", 0.2, 1, 0.2)
            end,
        })
        dbIcon:Register("Leatrix_Plus", ltpObj, LeaPlusDB)
    end

    LeaPlusLC.Player = nil
end

----------------------------------------------------------------------
--	L45: World Initializations
----------------------------------------------------------------------

function LeaPlusLC:World()
    if LeaPlusLC["MaxCameraZoom"] == "On" then
        SetCVar("cameraDistanceMaxFactor", 4.0)
    end
    if LeaPlusLC["NoScreenGlow"] == "On" then
        SetCVar("ffxGlow", "0")
    end
    if LeaPlusLC["NoScreenEffects"] == "On" then
        SetCVar("ffxDeath", "0")
        SetCVar("ffxNetherWorld", "0")
    end
    if LeaPlusLC["SetWeatherDensity"] == "On" then
        SetCVar("weatherDensity", LeaPlusLC["WeatherLevel"] or 3)
    end
end

----------------------------------------------------------------------
-- 	L50: RunOnce (Media & UI Tools)
----------------------------------------------------------------------

function LeaPlusLC:RunOnce()
    -- Grid Frame
    local grid = CreateFrame("FRAME", nil, UIParent)
    LeaPlusLC.grid = grid
    grid:Hide()
    grid:SetAllPoints(UIParent)

    -- Media player setup
    function LeaPlusLC:MediaFunc()
        local scrollFrame, LastPlayed, LastFolder, TempFolder
        local ShowRandomList
        local sBox
        local numButtons = 15
        local ListData, playlist = {}, {}
        local ZoneList = Leatrix_Plus["ZoneList"] or {}

        local function UpdateList()
            FauxScrollFrame_Update(scrollFrame, #ListData, numButtons, 16)
            for index = 1, numButtons do
                local offset = index + FauxScrollFrame_GetOffset(scrollFrame)
                local button = scrollFrame.buttons[index]
                button.index = offset

                if offset <= #ListData then
                    local rawItem = ListData[offset]
                    local displayText = (type(rawItem) == "table" and rawItem.zone) or tostring(rawItem)
                    button:SetText(displayText)
                    button:Show()
                else
                    button:Hide()
                end
            end
        end

        scrollFrame = CreateFrame("ScrollFrame", "LeaPlusScrollFrame", LeaPlusLC["Page9"], "FauxScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 0, -32)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
        scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
            FauxScrollFrame_OnVerticalScroll(self, offset, 16, UpdateList)
        end)

        sBox = LeaPlusLC:CreateEditBox("MusicSearchBox", LeaPlusLC["Page9"], 100, 24, "TOPLEFT", 135, -292, "MusicSearchBox", "MusicSearchBox", 50)

        scrollFrame.buttons = {}
        for i = 1, numButtons do
            scrollFrame.buttons[i] = CreateFrame("Button", nil, LeaPlusLC["Page9"])
            local btn = scrollFrame.buttons[i]
            btn:SetSize(450, 16)
            btn:SetNormalFontObject("GameFontHighlightLeft")
            btn:SetPoint("TOPLEFT", 246, -62 + -(i - 1) * 16 - 8)
            btn:SetScript("OnClick", function(self)
                local item = ListData[self.index]
                if type(item) == "string" and item:find("#") then
                    local file = item:match("([^,]+)%#")
                    if file then
                        PlayMusic("sound/music/" .. file)
                    end
                elseif type(item) == "table" and item.tracks then
                    ListData = item.tracks
                    UpdateList()
                end
            end)
        end
    end

    if LeaPlusLC.MediaFunc then
        LeaPlusLC:MediaFunc()
        LeaPlusLC.MediaFunc = nil
    end

    UpdateAddOnMemoryUsage()
    LeaPlusLC.RunOnce = nil
end

----------------------------------------------------------------------
-- 	L60: Core Events Dispatcher
----------------------------------------------------------------------

local function eventHandler(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == "Leatrix_Plus" then
        -- Load Database defaults
        LeaPlusLC:LoadVarChk("AutomateQuests", "Off")
        LeaPlusLC:LoadVarChk("AutoQuestShift", "Off")
        LeaPlusLC:LoadVarChk("AutoQuestAvailable", "On")
        LeaPlusLC:LoadVarChk("AutoQuestCompleted", "On")
        LeaPlusLC:LoadVarNum("AutoQuestKeyMenu", 1, 1, 3)
        LeaPlusLC:LoadVarChk("AutomateGossip", "Off")
        LeaPlusLC:LoadVarChk("AutoAcceptSummon", "Off")
        LeaPlusLC:LoadVarChk("AutoAcceptRes", "Off")
        LeaPlusLC:LoadVarChk("AutoResNoCombat", "On")
        LeaPlusLC:LoadVarChk("AutoReleasePvP", "Off")
        LeaPlusLC:LoadVarChk("AutoReleaseNoAlterac", "Off")
        LeaPlusLC:LoadVarChk("AutoReleaseShiftCancel", "On")
        LeaPlusLC:LoadVarNum("AutoReleaseDelay", 200, 200, 3000)
        LeaPlusLC:LoadVarChk("AutoSpiritRes", "Off")
        LeaPlusLC:LoadVarChk("AutoSellJunk", "Off")
        LeaPlusLC:LoadVarChk("AutoSellShowSummary", "On")
        LeaPlusLC:LoadVarStr("AutoSellExcludeList", "")
        LeaPlusLC:LoadVarChk("AutoRepairGear", "Off")
        LeaPlusLC:LoadVarChk("AutoRepairGuildFunds", "On")
        LeaPlusLC:LoadVarChk("AutoRepairShowSummary", "On")
        LeaPlusLC:LoadVarChk("NoDuelRequests", "Off")
        LeaPlusLC:LoadVarChk("NoPartyInvites", "Off")
        LeaPlusLC:LoadVarChk("NoGuildInvites", "Off")
        LeaPlusLC:LoadVarChk("NoSharedQuests", "Off")
        LeaPlusLC:LoadVarChk("AcceptPartyFriends", "Off")
        LeaPlusLC:LoadVarChk("InviteFromWhisper", "Off")
        LeaPlusLC:LoadVarChk("InviteFriendsOnly", "Off")
        LeaPlusLC:LoadVarStr("InvKey", "inv")
        LeaPlusLC:LoadVarChk("FriendlyGuild", "On")
        LeaPlusLC:LoadVarChk("UseEasyChatResizing", "Off")
        LeaPlusLC:LoadVarChk("NoCombatLogTab", "Off")
        LeaPlusLC:LoadVarChk("NoChatButtons", "Off")
        LeaPlusLC:LoadVarChk("UnclampChat", "Off")
        LeaPlusLC:LoadVarChk("MoveChatEditBoxToTop", "Off")
        LeaPlusLC:LoadVarChk("MoreFontSizes", "Off")
        LeaPlusLC:LoadVarChk("AltClickInv", "Off")
        LeaPlusLC:LoadVarChk("NoStickyChat", "Off")
        LeaPlusLC:LoadVarChk("UseArrowKeysInChat", "Off")
        LeaPlusLC:LoadVarChk("NoChatFade", "Off")
        LeaPlusLC:LoadVarChk("UnivGroupColor", "Off")
        LeaPlusLC:LoadVarChk("ClassColorsInChat", "Off")
        LeaPlusLC:LoadVarChk("RecentChatWindow", "Off")
        LeaPlusLC:LoadVarNum("RecentChatSize", 170, 170, 600)
        LeaPlusLC:LoadVarChk("MaxChatHstory", "Off")
        LeaPlusLC:LoadVarChk("FilterChatMessages", "Off")
        LeaPlusLC:LoadVarChk("RestoreChatMessages", "Off")
        LeaPlusLC:LoadVarChk("HideErrorMessages", "Off")
        LeaPlusLC:LoadVarChk("NoHitIndicators", "Off")
        LeaPlusLC:LoadVarChk("HideZoneText", "Off")
        LeaPlusLC:LoadVarChk("HideKeybindText", "Off")
        LeaPlusLC:LoadVarChk("HideMacroText", "Off")
        LeaPlusLC:LoadVarChk("MailFontChange", "Off")
        LeaPlusLC:LoadVarNum("LeaPlusMailFontSize", 15, 10, 36)
        LeaPlusLC:LoadVarChk("QuestFontChange", "Off")
        LeaPlusLC:LoadVarNum("LeaPlusQuestFontSize", 12, 10, 36)
        LeaPlusLC:LoadVarChk("BookFontChange", "Off")
        LeaPlusLC:LoadVarNum("LeaPlusBookFontSize", 15, 10, 36)
        LeaPlusLC:LoadVarChk("MinimapModder", "Off")
        LeaPlusLC:LoadVarChk("SquareMinimap", "Off")
        LeaPlusLC:LoadVarChk("ShowWhoPinged", "On")
        LeaPlusLC:LoadVarChk("CombineAddonButtons", "Off")
        LeaPlusLC:LoadVarStr("MiniExcludeList", "")
        LeaPlusLC:LoadVarChk("HideMiniZoomBtns", "Off")
        LeaPlusLC:LoadVarChk("HideMiniZoneText", "Off")
        LeaPlusLC:LoadVarChk("HideMiniAddonButtons", "On")
        LeaPlusLC:LoadVarChk("HideMiniMapButton", "On")
        LeaPlusLC:LoadVarChk("HideMiniTracking", "Off")
        LeaPlusLC:LoadVarChk("HideMiniCalendar", "Off")
        LeaPlusLC:LoadVarChk("HideMiniPOIArrows", "Off")
        LeaPlusLC:LoadVarChk("ClockMouseover", "Off")
        LeaPlusLC:LoadVarNum("MinimapScale", 1, 1, 4)
        LeaPlusLC:LoadVarNum("MinimapSize", 140, 140, 560)
        LeaPlusLC:LoadVarNum("MiniClusterScale", 1, 1, 2)
        LeaPlusLC:LoadVarAnc("MinimapA", "TOPRIGHT")
        LeaPlusLC:LoadVarAnc("MinimapR", "TOPRIGHT")
        LeaPlusLC:LoadVarNum("MinimapX", -17, -5000, 5000)
        LeaPlusLC:LoadVarNum("MinimapY", -22, -5000, 5000)
        LeaPlusLC:LoadVarChk("TipModEnable", "Off")
        LeaPlusLC:LoadVarChk("TipShowRank", "On")
        LeaPlusLC:LoadVarChk("TipShowOtherRank", "Off")
        LeaPlusLC:LoadVarChk("TipShowTarget", "On")
        LeaPlusLC:LoadVarChk("TipHideInCombat", "Off")
        LeaPlusLC:LoadVarChk("TipHideShiftOverride", "On")
        LeaPlusLC:LoadVarChk("TipNoHealthBar", "Off")
        LeaPlusLC:LoadVarNum("LeaPlusTipSize", 1.00, 0.50, 2.00)
        LeaPlusLC:LoadVarNum("TipOffsetX", -13, -5000, 5000)
        LeaPlusLC:LoadVarNum("TipOffsetY", 94, -5000, 5000)
        LeaPlusLC:LoadVarNum("TooltipAnchorMenu", 1, 1, 5)
        LeaPlusLC:LoadVarChk("EnhanceQuestLog", "Off")
        LeaPlusLC:LoadVarChk("EnhanceQuestHeaders", "On")
        LeaPlusLC:LoadVarChk("EnhanceQuestLevels", "On")
        LeaPlusLC:LoadVarChk("EnhanceQuestDifficulty", "On")
        LeaPlusLC:LoadVarChk("EnhanceProfessions", "Off")
        LeaPlusLC:LoadVarChk("EnhanceTrainers", "Off")
        LeaPlusLC:LoadVarChk("ShowTrainAllBtn", "On")
        LeaPlusLC:LoadVarChk("ShowVolume", "Off")
        LeaPlusLC:LoadVarChk("AhExtras", "Off")
        LeaPlusLC:LoadVarChk("DurabilityStatus", "Off")
        LeaPlusLC:LoadVarChk("ShowVanityControls", "Off")
        LeaPlusLC:LoadVarChk("ShowBagSearchBox", "Off")
        LeaPlusLC:LoadVarChk("ShowPlayerChain", "Off")
        LeaPlusLC:LoadVarNum("PlayerChainMenu", 2, 1, 3)
        LeaPlusLC:LoadVarChk("ShowReadyTimer", "Off")
        LeaPlusLC:LoadVarChk("ShowWowheadLinks", "Off")
        LeaPlusLC:LoadVarChk("ShowFlightTimes", "Off")
        LeaPlusLC:LoadVarChk("FrmEnabled", "Off")
        LeaPlusLC:LoadVarChk("ManageBuffs", "Off")
        LeaPlusLC:LoadVarAnc("BuffFrameA", "TOPRIGHT")
        LeaPlusLC:LoadVarAnc("BuffFrameR", "TOPRIGHT")
        LeaPlusLC:LoadVarNum("BuffFrameX", -205, -5000, 5000)
        LeaPlusLC:LoadVarNum("BuffFrameY", -13, -5000, 5000)
        LeaPlusLC:LoadVarNum("BuffFrameScale", 1, 0.5, 2)
        LeaPlusLC:LoadVarChk("ManageDeBuffs", "Off")
        LeaPlusLC:LoadVarAnc("DebuffButton1A", "TOPRIGHT")
        LeaPlusLC:LoadVarAnc("DebuffButton1R", "TOPRIGHT")
        LeaPlusLC:LoadVarNum("DebuffButton1X", -205, -5000, 5000)
        LeaPlusLC:LoadVarNum("DebuffButton1Y", -13, -5000, 5000)
        LeaPlusLC:LoadVarNum("DebuffButton1Scale", 1, 0.5, 2)
        LeaPlusLC:LoadVarChk("ManageWidget", "Off")
        LeaPlusLC:LoadVarAnc("WidgetA", "TOP")
        LeaPlusLC:LoadVarAnc("WidgetR", "TOP")
        LeaPlusLC:LoadVarNum("WidgetX", 0, -5000, 5000)
        LeaPlusLC:LoadVarNum("WidgetY", -15, -5000, 5000)
        LeaPlusLC:LoadVarNum("WidgetScale", 1, 0.5, 2)
        LeaPlusLC:LoadVarChk("ManageFocus", "Off")
        LeaPlusLC:LoadVarAnc("FocusA", "CENTER")
        LeaPlusLC:LoadVarAnc("FocusR", "CENTER")
        LeaPlusLC:LoadVarNum("FocusX", 0, -5000, 5000)
        LeaPlusLC:LoadVarNum("FocusY", 0, -5000, 5000)
        LeaPlusLC:LoadVarNum("FocusScale", 1, 0.5, 2)
        LeaPlusLC:LoadVarChk("ManageTimer", "Off")
        LeaPlusLC:LoadVarAnc("TimerA", "TOP")
        LeaPlusLC:LoadVarAnc("TimerR", "TOP")
        LeaPlusLC:LoadVarNum("TimerX", -5, -5000, 5000)
        LeaPlusLC:LoadVarNum("TimerY", -96, -5000, 5000)
        LeaPlusLC:LoadVarNum("TimerScale", 1, 0.5, 2)
        LeaPlusLC:LoadVarChk("ManageDurability", "Off")
        LeaPlusLC:LoadVarAnc("DurabilityA", "TOPRIGHT")
        LeaPlusLC:LoadVarAnc("DurabilityR", "TOPRIGHT")
        LeaPlusLC:LoadVarNum("DurabilityX", 0, -5000, 5000)
        LeaPlusLC:LoadVarNum("DurabilityY", -170, -5000, 5000)
        LeaPlusLC:LoadVarNum("DurabilityScale", 1, 0.5, 2)
        LeaPlusLC:LoadVarChk("ManageTracker", "Off")
        LeaPlusLC:LoadVarAnc("TrackerA", "TOPRIGHT")
        LeaPlusLC:LoadVarAnc("TrackerR", "TOPRIGHT")
        LeaPlusLC:LoadVarNum("TrackerX", 0, -5000, 5000)
        LeaPlusLC:LoadVarNum("TrackerY", -170, -5000, 5000)
        LeaPlusLC:LoadVarNum("TrackerScale", 1, 0.5, 2)
        LeaPlusLC:LoadVarChk("ManageVehicle", "Off")
        LeaPlusLC:LoadVarAnc("VehicleA", "TOPRIGHT")
        LeaPlusLC:LoadVarAnc("VehicleR", "TOPRIGHT")
        LeaPlusLC:LoadVarNum("VehicleX", -100, -5000, 5000)
        LeaPlusLC:LoadVarNum("VehicleY", -192, -5000, 5000)
        LeaPlusLC:LoadVarNum("VehicleScale", 1, 0.5, 2)
        LeaPlusLC:LoadVarChk("ClassColFrames", "Off")
        LeaPlusLC:LoadVarChk("ClassColPlayer", "On")
        LeaPlusLC:LoadVarChk("ClassColTarget", "On")
        LeaPlusLC:LoadVarChk("NoAlerts", "Off")
        LeaPlusLC:LoadVarChk("NoGryphons", "Off")
        LeaPlusLC:LoadVarChk("NoClassBar", "Off")
        LeaPlusLC:LoadVarChk("NoScreenGlow", "Off")
        LeaPlusLC:LoadVarChk("NoScreenEffects", "Off")
        LeaPlusLC:LoadVarChk("SetWeatherDensity", "Off")
        LeaPlusLC:LoadVarNum("WeatherLevel", 3, 0, 3)
        LeaPlusLC:LoadVarChk("MaxCameraZoom", "Off")
        LeaPlusLC:LoadVarChk("ViewPortEnable", "Off")
        LeaPlusLC:LoadVarNum("ViewPortTop", 0, 0, 300)
        LeaPlusLC:LoadVarNum("ViewPortBottom", 0, 0, 300)
        LeaPlusLC:LoadVarNum("ViewPortLeft", 0, 0, 300)
        LeaPlusLC:LoadVarNum("ViewPortRight", 0, 0, 300)
        LeaPlusLC:LoadVarNum("ViewPortResizeTop", 0, 0, 300)
        LeaPlusLC:LoadVarNum("ViewPortResizeBottom", 0, 0, 300)
        LeaPlusLC:LoadVarNum("ViewPortAlpha", 0, 0, 0.9)
        LeaPlusLC:LoadVarChk("SmallerErrorFrame", "Off")
        LeaPlusLC:LoadVarChk("FasterErrorFrame", "Off")
        LeaPlusLC:LoadVarChk("NoRestedEmotes", "Off")
        LeaPlusLC:LoadVarChk("NoBagAutomation", "Off")
        LeaPlusLC:LoadVarChk("NoConfirmLoot", "Off")
        LeaPlusLC:LoadVarChk("FasterLooting", "Off")
        LeaPlusLC:LoadVarChk("FasterMovieSkip", "Off")
        LeaPlusLC:LoadVarChk("CombatPlates", "Off")
        LeaPlusLC:LoadVarChk("EasyItemDestroy", "Off")
        LeaPlusLC:LoadVarChk("ShowMinimapIcon", "On")
        LeaPlusLC:LoadVarNum("PlusPanelScale", 1, 1, 2)
        LeaPlusLC:LoadVarNum("PlusPanelAlpha", 0, 0, 1)
        LeaPlusLC:LoadVarAnc("MainPanelA", "CENTER")
        LeaPlusLC:LoadVarAnc("MainPanelR", "CENTER")
        LeaPlusLC:LoadVarNum("MainPanelX", 0, -5000, 5000)
        LeaPlusLC:LoadVarNum("MainPanelY", 0, -5000, 5000)
        LeaPlusLC:LoadVarNum("LeaStartPage", 0, 0, LeaPlusLC["NumberOfPages"])

        LeaPlusLC:Live()
        LeaPlusLC:Isolated()
        LeaPlusLC:RunOnce()
        LeaPlusLC:SetDim()

        for _, mod in pairs(Leatrix_Plus.Modules) do
            if mod.OnEnable then mod:OnEnable() end
        end
        return
    end

    if event == "PLAYER_LOGIN" then
        LeaPlusLC:Player()
        for _, mod in pairs(Leatrix_Plus.Modules) do
            if mod.OnLogin then mod:OnLogin() end
        end
        collectgarbage()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        LeaPlusLC:World()
        LpEvt:UnregisterEvent("PLAYER_ENTERING_WORLD")
        return
    end

    if event == "PLAYER_LOGOUT" then
        LeaPlusLC:PlayerLogout(false)
        for _, mod in pairs(Leatrix_Plus.Modules) do
            if mod.OnLogout then mod:OnLogout(false) end
        end

        for k, v in pairs(LeaPlusLC) do
            if type(v) ~= "table" and type(v) ~= "function" then
                LeaPlusDB[k] = v
            end
        end
        -- Sync specific variables
        LeaPlusDB["SmallerErrorFrame"] = LeaPlusLC["SmallerErrorFrame"]
        LeaPlusDB["FasterErrorFrame"] = LeaPlusLC["FasterErrorFrame"]
    end
end

LpEvt:SetScript("OnEvent", eventHandler)

----------------------------------------------------------------------
--	L70: Logout & Reset Handlers
----------------------------------------------------------------------

function LeaPlusLC:PlayerLogout(wipeData)
    if wipeData then
        SetCVar("ffxGlow", "1")
        SetCVar("ffxDeath", "1")
        SetCVar("ffxNetherWorld", "1")
        SetCVar("weatherDensity", "3")
        SetCVar("cameraDistanceMaxFactor", 1.9)
        ChangeChatColor("RAID", 1, 0.50, 0)
        ChangeChatColor("RAID_LEADER", 1, 0.28, 0.04)
    end
end

----------------------------------------------------------------------
-- 	UI Elements Creation Helpers
----------------------------------------------------------------------

function LeaPlusLC:CreateBar(name, parent, width, height, anchor, r, g, b, alp, tex)
    local ft = parent:CreateTexture(nil, "BORDER")
    ft:SetTexture(tex)
    ft:SetSize(width, height)
    ft:SetPoint(anchor)
    ft:SetVertexColor(r, g, b, alp)
    if name == "MainTexture" then
        ft:SetTexCoord(0.09, 1, 0, 1)
    end
end

function LeaPlusLC:CreatePanel(title, globref)
    local Side = CreateFrame("Frame", nil, UIParent)
    _G["LeaPlusGlobalPanel_" .. globref] = Side
    tinsert(UISpecialFrames, "LeaPlusGlobalPanel_" .. globref)
    tinsert(LeaConfigList, Side)

    Side:Hide()
    Side:SetSize(570, 370)
    Side:SetClampedToScreen(true)
    Side:SetFrameStrata("FULLSCREEN_DIALOG")

    Side.t = Side:CreateTexture(nil, "BACKGROUND")
    Side.t:SetAllPoints()
    Side.t:SetTexture(0.05, 0.05, 0.05, 0.9)

    Side.c = CreateFrame("Button", nil, Side, "UIPanelCloseButton")
    Side.c:SetSize(30, 30)
    Side.c:SetPoint("TOPRIGHT", 0, 0)
    Side.c:SetScript("OnClick", function() Side:Hide() end)

    Side.r = LeaPlusLC:CreateButton("ResetButton", Side, "Reset", "TOPLEFT", 16, -292, 0, 25, true, "Click to reset the settings on this page.")
    Side.h = LeaPlusLC:CreateButton("HelpButton", Side, "Help", "TOPLEFT", 76, -292, 0, 25, true, "No help is available for this page.")
    Side.b = LeaPlusLC:CreateButton("BackButton", Side, "Back to Main Menu", "TOPRIGHT", -16, -292, 0, 25, true, "Click to return to the main menu.")

    Side.h:ClearAllPoints()
    Side.h:SetPoint("LEFT", Side.r, "RIGHT", 10, 0)

    local reloadb = LeaPlusLC:CreateButton("ConfigReload", Side, "Reload", "BOTTOMRIGHT", -16, 10, 0, 25, true, LeaPlusCB["ReloadUIButton"].tiptext)
    LeaPlusLC:LockItem(reloadb, true)
    reloadb:SetScript("OnClick", ReloadUI)

    reloadb.f = reloadb:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    reloadb.f:SetHeight(32)
    reloadb.f:SetPoint("RIGHT", reloadb, "LEFT", -10, 0)
    reloadb.f:SetText(LeaPlusCB["ReloadUIButton"].f:GetText())
    reloadb.f:Hide()

    LeaPlusCB["ReloadUIButton"]:HookScript("OnEnable", function()
        LeaPlusLC:LockItem(reloadb, false)
        reloadb.f:Show()
    end)
    LeaPlusCB["ReloadUIButton"]:HookScript("OnDisable", function()
        LeaPlusLC:LockItem(reloadb, true)
        reloadb.f:Hide()
    end)

    LeaPlusLC:CreateBar("FootTexture", Side, 570, 48, "BOTTOM", 0.5, 0.5, 0.5, 1.0, "Interface\\addons\\Leatrix_Plus\\assets\\ui-guildachievement-parchment-horizontal-desaturated.blp")
    LeaPlusLC:CreateBar("MainTexture", Side, 570, 323, "TOPRIGHT", 0.7, 0.7, 0.7, 0.9, "Interface\\addons\\Leatrix_Plus\\assets\\ui-guildachievement-parchment-horizontal-desaturated.blp")

    Side:EnableMouse(true)
    Side:SetMovable(true)
    Side:RegisterForDrag("LeftButton")
    Side:SetScript("OnDragStart", Side.StartMoving)
    Side:SetScript("OnDragStop", function()
        Side:StopMovingOrSizing()
        Side:SetUserPlaced(false)
        LeaPlusLC["MainPanelA"], void, LeaPlusLC["MainPanelR"], LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"] = Side:GetPoint()
    end)

    Side:SetScript("OnShow", function()
        Side:ClearAllPoints()
        Side:SetPoint(LeaPlusLC["MainPanelA"], UIParent, LeaPlusLC["MainPanelR"], LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"])
        Side:SetScale(LeaPlusLC["PlusPanelScale"] or 1)
        Side.t:SetAlpha(1 - (LeaPlusLC["PlusPanelAlpha"] or 0))
    end)

    Side.f = Side:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    Side.f:SetPoint("TOPLEFT", 16, -16)
    Side.f:SetText(L[title])

    Side.v = Side:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    Side.v:SetHeight(32)
    Side.v:SetPoint("TOPLEFT", Side.f, "BOTTOMLEFT", 0, -8)
    Side.v:SetPoint("RIGHT", Side, -32, 0)
    Side.v:SetJustifyH("LEFT")
    Side.v:SetJustifyV("TOP")
    Side.v:SetText(L["Configuration Panel"])

    LeaPlusLC["PageF"]:HookScript("OnShow", function()
        if Side:IsShown() then LeaPlusLC["PageF"]:Hide() end
    end)

    return Side
end

function LeaPlusLC:MakeTx(frame, title, x, y)
    local text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("TOPLEFT", x, y)
    text:SetText(L[title])
    return text
end

function LeaPlusLC:MakeWD(frame, title, x, y)
    local text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("TOPLEFT", x, y)
    text:SetText(L[title])
    text:SetJustifyH("LEFT")
    return text
end

function LeaPlusLC:MakeSL(frame, field, caption, low, high, step, x, y, form)
    local Slider = CreateFrame("Slider", "LeaPlusGlobalSlider" .. field, frame, "OptionssliderTemplate")
    LeaPlusCB[field] = Slider
    Slider:SetMinMaxValues(low, high)
    Slider:SetValueStep(step)
    Slider:EnableMouseWheel(true)
    Slider:SetPoint("TOPLEFT", x, y)
    Slider:SetWidth(100)
    Slider:SetHeight(20)
    Slider.tiptext = L[caption]
    Slider:SetScript("OnEnter", LeaPlusLC.TipSee)
    Slider:SetScript("OnLeave", GameTooltip_Hide)

    _G[Slider:GetName() .. "Low"]:SetText("")
    _G[Slider:GetName() .. "High"]:SetText("")

    Slider.f = Slider:CreateFontString(nil, "BACKGROUND")
    Slider.f:SetFontObject("GameFontHighlight")
    Slider.f:SetPoint("LEFT", Slider, "RIGHT", 12, 0)

    Slider:SetScript("OnMouseWheel", function(self, delta)
        if Slider:IsEnabled() then
            local val = self:GetValue()
            if delta > 0 then
                self:SetValue(min(val + step, high))
            else
                self:SetValue(max(val - step, low))
            end
        end
    end)

    Slider:SetScript("OnValueChanged", function(self, value)
        local val = floor((value - low) / step + 0.5) * step + low
        Slider.f:SetFormattedText(form, val)
        LeaPlusLC[field] = val
    end)

    Slider:SetScript("OnShow", function(self)
        self:SetValue(LeaPlusLC[field] or low)
    end)
end

function LeaPlusLC:MakeCB(parent, field, caption, x, y, reload, tip, extratip)
    local Cbox = CreateFrame("CheckButton", nil, parent, "ChatConfigCheckButtonTemplate")
    LeaPlusCB[field] = Cbox
    Cbox:SetPoint("TOPLEFT", x, y)
    Cbox:SetScript("OnEnter", LeaPlusLC.TipSee)
    Cbox:SetScript("OnLeave", GameTooltip_Hide)

    Cbox.f = Cbox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    Cbox.f:SetPoint("LEFT", 23, 0)
    local tooltipText = L[tip]
    if extratip and extratip ~= "" then
        tooltipText = tooltipText .. "|n|n" .. L[extratip]
    end
    if reload then
        Cbox.f:SetText(L[caption] .. "*")
        tooltipText = tooltipText .. "|n|n* " .. L["Requires UI reload."]
    else
        Cbox.f:SetText(L[caption])
    end
    Cbox.tiptext = tooltipText
    Cbox.f:SetJustifyH("LEFT")
    Cbox.f:SetWordWrap(false)

    if parent:GetParent() == LeaPlusLC["PageF"] then
        if Cbox.f:GetWidth() > 152 then Cbox.f:SetWidth(152) end
        Cbox:SetHitRectInsets(0, -min(Cbox.f:GetStringWidth(), 152), 0, 0)
    else
        if Cbox.f:GetWidth() > 302 then Cbox.f:SetWidth(302) end
        Cbox:SetHitRectInsets(0, -min(Cbox.f:GetStringWidth(), 302), 0, 0)
    end

    Cbox:SetScript("OnShow", function(self)
        self:SetChecked(LeaPlusLC[field] == "On")
    end)

    Cbox:SetScript("OnClick", function(self)
        LeaPlusLC[field] = self:GetChecked() and "On" or "Off"
        LeaPlusLC:SetDim()
        LeaPlusLC:ReloadCheck()
        LeaPlusLC:Live()
    end)
end

function LeaPlusLC:CreateEditBox(frame, parent, width, height, anchor, x, y, tab, shifttab, maxchars)
    local eb = CreateFrame("EditBox", nil, parent)
    eb:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    eb:SetBackdropColor(0, 0, 0, 0.5)
    eb:SetTextInsets(6, 6, 0, 0)
    LeaPlusCB[frame] = eb
    eb:SetPoint(anchor, x, y)
    eb:SetWidth(width)
    eb:SetHeight(height)
    eb:SetFontObject("GameFontNormal")
    eb:SetTextColor(1, 1, 1)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(maxchars)
    eb:SetScript("OnEscapePressed", eb.ClearFocus)
    eb:SetScript("OnEnterPressed", eb.ClearFocus)
    return eb
end

function LeaPlusLC:CreateButton(name, frame, label, anchor, x, y, width, height, reskin, tip)
    local btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    LeaPlusCB[name] = btn
    btn:SetSize(width > 0 and width or 100, height)
    btn:SetPoint(anchor, x, y)
    btn:SetText(L[label])

    btn.f = btn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    btn.f:SetText(L[label])
    if width <= 0 then
        btn:SetWidth(btn.f:GetStringWidth() + 20)
    end

    btn.tiptext = L[tip]
    btn:SetScript("OnEnter", LeaPlusLC.TipSee)
    btn:SetScript("OnLeave", GameTooltip_Hide)
    return btn
end

function LeaPlusLC:CreateDropDown(ddname, label, parent, width, anchor, x, y, items, tip)
    tinsert(LeaDropList, ddname)
    LeaPlusLC[ddname .. "Table"] = items

    local frame = CreateFrame("FRAME", nil, parent)
    frame:SetWidth(width)
    frame:SetHeight(42)
    frame:SetPoint("BOTTOMLEFT", parent, anchor, x, y)

    local dd = CreateFrame("Frame", nil, frame)
    dd:SetPoint("BOTTOMLEFT", -16, -8)
    dd:SetPoint("BOTTOMRIGHT", 15, -4)
    dd:SetHeight(32)

    local lt = dd:CreateTexture(nil, "ARTWORK")
    lt:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
    lt:SetTexCoord(0, 0.1953125, 0, 1)
    lt:SetPoint("TOPLEFT", dd, 0, 17)
    lt:SetSize(25, 64)

    local rt = dd:CreateTexture(nil, "BORDER")
    rt:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
    rt:SetTexCoord(0.8046875, 1, 0, 1)
    rt:SetPoint("TOPRIGHT", dd, 0, 17)
    rt:SetSize(25, 64)

    local mt = dd:CreateTexture(nil, "BORDER")
    mt:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
    mt:SetTexCoord(0.1953125, 0.8046875, 0, 1)
    mt:SetPoint("LEFT", lt, "RIGHT")
    mt:SetPoint("RIGHT", rt, "LEFT")
    mt:SetHeight(64)

    local lf = dd:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lf:SetPoint("TOPLEFT", frame, 0, 0)
    lf:SetText(L[label])

    local value = dd:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    value:SetPoint("LEFT", lt, 26, 2)
    value:SetPoint("RIGHT", rt, -43, 0)
    value:SetJustifyH("LEFT")
    dd:SetScript("OnShow", function()
        value:SetText(LeaPlusLC[ddname .. "Table"][LeaPlusLC[ddname] or 1])
    end)

    local dbtn = CreateFrame("Button", nil, dd)
    dbtn:SetPoint("TOPRIGHT", rt, -16, -18)
    dbtn:SetSize(24, 24)
    dbtn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    dbtn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
    dbtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    dbtn.tiptext = tip
    dbtn:SetScript("OnEnter", LeaPlusLC.ShowDropTip)
    dbtn:SetScript("OnLeave", GameTooltip_Hide)

    local ddlist = CreateFrame("Frame", nil, frame)
    LeaPlusCB["ListFrame" .. ddname] = ddlist
    ddlist:SetPoint("TOP", 0, -42)
    ddlist:SetWidth(frame:GetWidth())
    ddlist:SetHeight((#items * 16) + 32)
    ddlist:SetFrameStrata("FULLSCREEN_DIALOG")
    ddlist:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false, tileSize = 0, edgeSize = 32,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    ddlist:Hide()
    parent:HookScript("OnHide", function() ddlist:Hide() end)

    for k, text in pairs(items) do
        local dditem = CreateFrame("Button", nil, ddlist)
        LeaPlusCB["Drop" .. ddname .. k] = dditem
        dditem:SetWidth(ddlist:GetWidth() - 22)
        dditem:SetHeight(16)
        dditem:SetPoint("TOPLEFT", 12, -k * 16)

        dditem.f = dditem:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        dditem.f:SetPoint("LEFT", 16, 0)
        dditem.f:SetText(text)

        dditem:SetScript("OnClick", function()
            LeaPlusLC[ddname] = k
            value:SetText(items[k])
            ddlist:Hide()
        end)
    end

    dbtn:SetScript("OnClick", function()
        if ddlist:IsShown() then ddlist:Hide() else ddlist:Show() end
    end)
    return frame
end

----------------------------------------------------------------------
-- 	Main Navigation & Option Panels Construction
----------------------------------------------------------------------

function LeaPlusLC:MakeMN(name, text, parent, anchor, x, y, width, height)
    local mbtn = CreateFrame("Button", nil, parent)
    LeaPlusLC[name] = mbtn
    mbtn:SetSize(width, height)
    mbtn:SetPoint(anchor, x, y)

    mbtn.t = mbtn:CreateTexture(nil, "BACKGROUND")
    mbtn.t:SetAllPoints()
    mbtn.t:SetTexture("Interface\\Buttons\\WHITE8X8")
    mbtn.t:SetVertexColor(1.0, 0.5, 0.0, 0.8)
    mbtn.t:Hide()

    mbtn.s = mbtn:CreateTexture(nil, "BACKGROUND")
    mbtn.s:SetAllPoints()
    mbtn.s:SetTexture("Interface\\Buttons\\WHITE8X8")
    mbtn.s:SetVertexColor(1.0, 0.5, 0.0, 0.8)
    mbtn.s:Hide()

    mbtn.f = mbtn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    mbtn.f:SetPoint("LEFT", 16, 0)
    mbtn.f:SetText(L[text])

    mbtn:SetScript("OnEnter", function() mbtn.t:Show() end)
    mbtn:SetScript("OnLeave", function() mbtn.t:Hide() end)
    return mbtn, mbtn.s
end

function LeaPlusLC:MakePage(name, title, menu, menuname, menuparent, menuanchor, menux, menuy, menuwidth, menuheight)
    local oPage = CreateFrame("Frame", nil, LeaPlusLC["PageF"])
    LeaPlusLC[name] = oPage
    oPage:SetAllPoints(LeaPlusLC["PageF"])
    oPage:Hide()

    oPage.s = oPage:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    oPage.s:SetPoint("TOPLEFT", 146, -16)
    oPage.s:SetText(L[title])

    if menu then
        LeaPlusLC[menu], LeaPlusLC[menu .. ".s"] = LeaPlusLC:MakeMN(menu, menuname, menuparent, menuanchor, menux, menuy, menuwidth, menuheight)
        oPage:SetScript("OnShow", function() LeaPlusLC[menu .. ".s"]:Show() end)
        oPage:SetScript("OnHide", function() LeaPlusLC[menu .. ".s"]:Hide() end)
    end
    return oPage
end

function LeaPlusLC:CreateMainPanel()
    local PageF = CreateFrame("Frame", nil, UIParent)
    _G["LeaPlusGlobalPanel"] = PageF
    tinsert(UISpecialFrames, "LeaPlusGlobalPanel")

    LeaPlusLC["PageF"] = PageF
    PageF:SetSize(570, 370)
    PageF:Hide()
    PageF:SetFrameStrata("FULLSCREEN_DIALOG")
    PageF:SetClampedToScreen(true)
    PageF:EnableMouse(true)
    PageF:SetMovable(true)
    PageF:RegisterForDrag("LeftButton")
    PageF:SetScript("OnDragStart", PageF.StartMoving)
    PageF:SetScript("OnDragStop", function()
        PageF:StopMovingOrSizing()
        PageF:SetUserPlaced(false)
        LeaPlusLC["MainPanelA"], void, LeaPlusLC["MainPanelR"], LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"] = PageF:GetPoint()
    end)

    PageF.t = PageF:CreateTexture(nil, "BACKGROUND")
    PageF.t:SetAllPoints()
    PageF.t:SetTexture(0.05, 0.05, 0.05, 0.9)

    LeaPlusLC:CreateBar("FootTexture", PageF, 570, 42, "BOTTOM", 0.5, 0.5, 0.5, 1.0, "Interface\\addons\\Leatrix_Plus\\assets\\ui-guildachievement-parchment-horizontal-desaturated.blp")
    LeaPlusLC:CreateBar("MainTexture", PageF, 440, 348, "TOPRIGHT", 0.7, 0.7, 0.7, 0.7, "Interface\\addons\\Leatrix_Plus\\assets\\ui-guildachievement-parchment-horizontal-desaturated.blp")
    LeaPlusLC:CreateBar("MenuTexture", PageF, 130, 348, "TOPLEFT", 0.7, 0.7, 0.7, 0.7, "Interface\\addons\\Leatrix_Plus\\assets\\ui-guildachievement-parchment-horizontal-desaturated.blp")

    PageF:SetScript("OnShow", function()
        PageF:ClearAllPoints()
        PageF:SetPoint(LeaPlusLC["MainPanelA"] or "CENTER", UIParent, LeaPlusLC["MainPanelR"] or "CENTER", LeaPlusLC["MainPanelX"] or 0, LeaPlusLC["MainPanelY"] or 0)
    end)

    PageF.mt = PageF:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    PageF.mt:SetPoint("TOPLEFT", 16, -16)
    PageF.mt:SetText("Leatrix Plus")

    PageF.v = PageF:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    PageF.v:SetPoint("TOPLEFT", PageF.mt, "BOTTOMLEFT", 0, -8)
    PageF.v:SetText(L["Version"] .. " " .. LeaPlusLC["AddonVer"])

    local reloadb = LeaPlusLC:CreateButton("ReloadUIButton", PageF, "Reload", "BOTTOMRIGHT", -16, 10, 0, 25, true, "Your UI needs to be reloaded.")
    LeaPlusLC:LockItem(reloadb, true)
    reloadb:SetScript("OnClick", ReloadUI)

    reloadb.f = reloadb:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    reloadb.f:SetPoint("RIGHT", reloadb, "LEFT", -10, 0)
    reloadb.f:SetText(L["Your UI needs to be reloaded."])
    reloadb.f:Hide()

    local CloseB = CreateFrame("Button", nil, PageF, "UIPanelCloseButton")
    CloseB:SetSize(30, 30)
    CloseB:SetPoint("TOPRIGHT", 0, 0)
    CloseB:SetScript("OnClick", LeaPlusLC.HideFrames)

    -- Build all pages
    LeaPlusLC["Page0"] = LeaPlusLC:MakePage("Page0", "Home", "LeaPlusNav0", "Home", PageF, "TOPLEFT", 16, -72, 112, 20)
    LeaPlusLC["Page1"] = LeaPlusLC:MakePage("Page1", "Automation", "LeaPlusNav1", "Automation", PageF, "TOPLEFT", 16, -112, 112, 20)
    LeaPlusLC["Page2"] = LeaPlusLC:MakePage("Page2", "Social", "LeaPlusNav2", "Social", PageF, "TOPLEFT", 16, -132, 112, 20)
    LeaPlusLC["Page3"] = LeaPlusLC:MakePage("Page3", "Chat", "LeaPlusNav3", "Chat", PageF, "TOPLEFT", 16, -152, 112, 20)
    LeaPlusLC["Page4"] = LeaPlusLC:MakePage("Page4", "Text", "LeaPlusNav4", "Text", PageF, "TOPLEFT", 16, -172, 112, 20)
    LeaPlusLC["Page5"] = LeaPlusLC:MakePage("Page5", "Interface", "LeaPlusNav5", "Interface", PageF, "TOPLEFT", 16, -192, 112, 20)
    LeaPlusLC["Page6"] = LeaPlusLC:MakePage("Page6", "Frames", "LeaPlusNav6", "Frames", PageF, "TOPLEFT", 16, -212, 112, 20)
    LeaPlusLC["Page7"] = LeaPlusLC:MakePage("Page7", "System", "LeaPlusNav7", "System", PageF, "TOPLEFT", 16, -232, 112, 20)
    LeaPlusLC["Page8"] = LeaPlusLC:MakePage("Page8", "Settings", "LeaPlusNav8", "Settings", PageF, "TOPLEFT", 16, -272, 112, 20)
    LeaPlusLC["Page9"] = LeaPlusLC:MakePage("Page9", "Media", "LeaPlusNav9", "Media", PageF, "TOPLEFT", 16, -292, 112, 20)

    for i = 0, LeaPlusLC["NumberOfPages"] do
        LeaPlusLC["LeaPlusNav" .. i]:SetScript("OnClick", function()
            LeaPlusLC:HideFrames()
            LeaPlusLC["PageF"]:Show()
            LeaPlusLC["Page" .. i]:Show()
            LeaPlusLC["LeaStartPage"] = i
        end)
    end

    -- Page 0 (Home)
    local pg = "Page0"
    LeaPlusLC:MakeTx(LeaPlusLC[pg], "Welcome to Leatrix Plus.", 146, -72)
    LeaPlusLC:MakeWD(LeaPlusLC[pg], "To begin, choose an options page.", 146, -92)
    LeaPlusLC:MakeTx(LeaPlusLC[pg], "Support", 146, -132)
    LeaPlusLC:MakeWD(LeaPlusLC[pg], "|cff00ff00Feedback Discord:|r |cffadd8e6sattva108|r", 146, -152)

    -- Page 1 (Automation)
    pg = "Page1"
    LeaPlusLC:MakeTx(LeaPlusLC[pg], "Character", 146, -72)
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutomateQuests", "Automate quests", 146, -92, false, "Quests will be accepted and turned-in automatically.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutomateGossip", "Automate gossip", 146, -112, false, "Hold Alt to select gossip options automatically.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoAcceptSummon", "Accept summon", 146, -132, false, "Accept summon automatically after 10s.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoAcceptRes", "Accept resurrection", 146, -152, false, "Accept resurrection automatically.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoReleasePvP", "Release in PvP", 146, -172, false, "Release automatically upon dying in PvP.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoSpiritRes", "Auto Spirit Res Confirm", 146, -192, false, "Resurrect automatically at Spirit Healer.")
    LeaPlusLC:MakeTx(LeaPlusLC[pg], "Vendors", 340, -72)
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoSellJunk", "Sell junk automatically", 340, -92, false, "Sell grey items automatically when visiting a merchant.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoRepairGear", "Repair automatically", 340, -112, false, "Repair gear automatically.")
    LeaPlusLC:CfgBtn("AutomateQuestsBtn", LeaPlusCB["AutomateQuests"])
    LeaPlusLC:CfgBtn("AutoAcceptResBtn", LeaPlusCB["AutoAcceptRes"])
    LeaPlusLC:CfgBtn("AutoReleasePvPBtn", LeaPlusCB["AutoReleasePvP"])
    LeaPlusLC:CfgBtn("AutoSellJunkBtn", LeaPlusCB["AutoSellJunk"])
    LeaPlusLC:CfgBtn("AutoRepairBtn", LeaPlusCB["AutoRepairGear"])

    -- Page 2 (Social)
    pg = "Page2"
    LeaPlusLC:MakeTx(LeaPlusLC[pg], "Blocks", 146, -72)
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoDuelRequests", "Block duels", 146, -92, false, "Block duel requests from non-friends.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoPartyInvites", "Block party invites", 146, -112, false, "Block party invites from non-friends.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoGuildInvites", "Block guild invites", 146, -132, false, "Block guild invites from non-friends.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoSharedQuests", "Block shared quests", 146, -152, false, "Block shared quests from non-friends.")
    LeaPlusLC:MakeTx(LeaPlusLC[pg], "Groups", 340, -72)
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "AcceptPartyFriends", "Party from friends", 340, -92, false, "Automatically accept party invites from friends.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "InviteFromWhisper", "Invite from whispers", 340, -112, false, "Invite players who whisper you an invite keyword.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "FriendlyGuild", "Guild", 146, -282, false, "Treat guild members as friends.")
    LeaPlusLC:CfgBtn("InvWhisperBtn", LeaPlusCB["InviteFromWhisper"])

    -- Page 3 (Chat)
    pg = "Page3"
    LeaPlusLC:MakeTx(LeaPlusLC[pg], "Chat Frame", 146, -72)
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "UseEasyChatResizing", "Use easy resizing", 146, -92, true, "Drag chat tab to resize chat.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoCombatLogTab", "Hide the combat log", 146, -112, true, "Hide the combat log tab.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoChatButtons", "Hide chat buttons", 146, -132, true, "Hide chat buttons and enable mousewheel scroll.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "UnclampChat", "Unclamp chat frame", 146, -152, true, "Move chat frame freely to the screen edges.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "MoveChatEditBoxToTop", "Move editbox to top", 146, -172, true, "Move editbox to top of chat frame.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "MoreFontSizes", "More font sizes", 146, -192, true, "Extra font sizes for chat.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "AltClickInv", "Alt click for Party Invite", 146, -212, true, "Alt-click names in chat to invite.")
    LeaPlusLC:MakeTx(LeaPlusLC[pg], "Mechanics", 340, -72)
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoStickyChat", "Disable sticky chat", 340, -92, true, "Disable sticky chat.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "UseArrowKeysInChat", "Use arrow keys in chat", 340, -112, true, "Use arrow keys directly in chat.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoChatFade", "Disable chat fade", 340, -132, true, "Keep chat lines permanently visible.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "UnivGroupColor", "Universal group color", 340, -152, false, "Color raid chat blue.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "ClassColorsInChat", "Use class colors in chat", 340, -172, true, "Use class colors in chat.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "RecentChatWindow", "Recent chat window", 340, -192, true, "Ctrl-click chat tabs to copy recent chat.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "MaxChatHstory", "Increase chat history", 340, -212, true, "Increase chat history lines to 4096.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "FilterChatMessages", "Filter chat messages", 340, -232, true, "Filter spam, duel, and drunk text.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "RestoreChatMessages", "Restore chat messages", 340, -252, true, "Restore chat history across sessions.")
    LeaPlusLC:CfgBtn("FilterChatMessagesBtn", LeaPlusCB["FilterChatMessages"])

    -- Page 4 (Text)
    pg = "Page4"
    LeaPlusLC:MakeTx(LeaPlusLC[pg], "Visibility", 146, -72)
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "HideErrorMessages", "Hide error messages", 146, -92, false, "Hide red error text.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoHitIndicators", "Hide portrait numbers", 146, -112, true, "Hide portrait damage numbers.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "HideZoneText", "Hide zone text", 146, -132, true, "Hide zone banners.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "HideKeybindText", "Hide keybind text", 146, -152, true, "Hide keybind text on action bars.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "HideMacroText", "Hide macro text", 146, -172, true, "Hide macro text on action bars.")
    LeaPlusLC:MakeTx(LeaPlusLC[pg], "Text Size", 340, -72)
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "MailFontChange", "Resize mail text", 340, -92, true, "Resize mail font size.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "QuestFontChange", "Resize quest text", 340, -112, true, "Resize quest font size.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "BookFontChange", "Resize book text", 340, -132, true, "Resize book font size.")
    LeaPlusLC:CfgBtn("MailTextBtn", LeaPlusCB["MailFontChange"])
    LeaPlusLC:CfgBtn("QuestTextBtn", LeaPlusCB["QuestFontChange"])
    LeaPlusLC:CfgBtn("BookTextBtn", LeaPlusCB["BookFontChange"])

    -- Page 5 (Interface)
    pg = "Page5"
    LeaPlusLC:MakeTx(LeaPlusLC[pg], "Enhancements", 146, -72)
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "MinimapModder", "Enhance minimap", 146, -92, true, "Custom square minimap and scaling.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "TipModEnable", "Enhance tooltip", 146, -112, true, "Color-coded tooltips and scaling.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "EnhanceQuestLog", "Enhance quest log", 146, -132, true, "Quest levels and header toggle.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "EnhanceProfessions", "Enhance professions", 146, -152, true, "Enlarge trade skills frame.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "EnhanceTrainers", "Enhance trainers", 146, -172, true, "Enlarge trainer frame with Train All.")
    LeaPlusLC:MakeTx(LeaPlusLC[pg], "Extras", 340, -72)
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowVolume", "Show volume slider", 340, -92, true, "Show master volume slider on character sheet.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "AhExtras", "Show auction controls", 340, -112, true, "Buyout only, gold only, and item search.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "DurabilityStatus", "Show durability status", 340, -132, true, "Durability tooltip on character sheet.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowVanityControls", "Toggle helm / cloak", 340, -152, true, "Helm and cloak checkboxes on character sheet.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowBagSearchBox", "Show bag search box", 340, -172, true, "Search editbox in bags.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowPlayerChain", "Show player chain", 340, -192, true, "Elite dragon border on player frame.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowReadyTimer", "Show ready timer", 340, -212, true, "Timer bar on battlefield ready popup.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowWowheadLinks", "Show Wowhead links", 340, -232, true, "Wowhead URLs on quest log and achievements.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowFlightTimes", "Show flight times", 340, -252, true, "Flight progress bar and times.")
    LeaPlusLC:CfgBtn("ModMinimapBtn", LeaPlusCB["MinimapModder"])
    LeaPlusLC:CfgBtn("MoveTooltipButton", LeaPlusCB["TipModEnable"])
    LeaPlusLC:CfgBtn("EnhanceQuestLogBtn", LeaPlusCB["EnhanceQuestLog"])
    LeaPlusLC:CfgBtn("EnhanceTrainersBtn", LeaPlusCB["EnhanceTrainers"])
    LeaPlusLC:CfgBtn("ModPlayerChain", LeaPlusCB["ShowPlayerChain"])
    LeaPlusLC:CfgBtn("ShowWowheadLinksBtn", LeaPlusCB["ShowWowheadLinks"])
    LeaPlusLC:CfgBtn("ShowFlightTimesBtn", LeaPlusCB["ShowFlightTimes"])

    -- Page 6 (Frames)
    pg = "Page6"
    LeaPlusLC:MakeTx(LeaPlusLC[pg], "Features", 146, -72)
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "FrmEnabled", "Manage frames", 146, -92, true, "Move and scale player and target frames.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageBuffs", "Manage buffs", 146, -112, true, "Move and scale buffs frame.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageWidget", "Manage widget", 146, -132, true, "Move and scale capture bar / PvP widget.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageFocus", "Manage focus", 146, -152, true, "Move and scale focus frame.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageTimer", "Manage timer", 146, -172, true, "Move and scale breath/fatigue timer.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageDurability", "Manage durability", 146, -192, true, "Move and scale armored man.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageVehicle", "Manage vehicle", 146, -212, true, "Move and scale vehicle seat indicator.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "ClassColFrames", "Class colored frames", 146, -232, true, "Class color player, target and focus names.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageTracker", "Manage Quest Tracker", 146, -252, true, "Move and scale objective tracker.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageDeBuffs", "Manage Debuffs", 146, -272, true, "Move and scale debuffs frame.")
    LeaPlusLC:MakeTx(LeaPlusLC[pg], "Visibility", 340, -72)
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoAlerts", "Hide alerts", 340, -92, true, "Hide achievement popups.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoGryphons", "Hide gryphons", 340, -112, true, "Hide main bar end caps.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoClassBar", "Hide stance bar", 340, -132, true, "Hide stance / shapeshift bar.")
    LeaPlusLC:CfgBtn("MoveFramesButton", LeaPlusCB["FrmEnabled"])
    LeaPlusLC:CfgBtn("ManageBuffsButton", LeaPlusCB["ManageBuffs"])
    LeaPlusLC:CfgBtn("ManageWidgetButton", LeaPlusCB["ManageWidget"])
    LeaPlusLC:CfgBtn("ManageFocusButton", LeaPlusCB["ManageFocus"])
    LeaPlusLC:CfgBtn("ManageTimerButton", LeaPlusCB["ManageTimer"])
    LeaPlusLC:CfgBtn("ManageDurabilityButton", LeaPlusCB["ManageDurability"])
    LeaPlusLC:CfgBtn("ManageVehicleButton", LeaPlusCB["ManageVehicle"])
    LeaPlusLC:CfgBtn("ClassColFramesBtn", LeaPlusCB["ClassColFrames"])
    LeaPlusLC:CfgBtn("ManageTrackerButton", LeaPlusCB["ManageTracker"])
    LeaPlusLC:CfgBtn("ManageDeBuffsButton", LeaPlusCB["ManageDeBuffs"])

    -- Page 7 (System)
    pg = "Page7"
    LeaPlusLC:MakeTx(LeaPlusLC[pg], "Graphics and Sound", 146, -72)
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoScreenGlow", "Disable screen glow", 146, -92, false, "Disable screen glow and drunk blur.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoScreenEffects", "Disable screen effects", 146, -112, false, "Disable death grey and nether effects.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "SetWeatherDensity", "Set weather density", 146, -132, false, "Set weather density.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "MaxCameraZoom", "Max camera zoom", 146, -152, false, "Maximize camera zoom distance.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "ViewPortEnable", "Enable viewport", 146, -172, true, "Add adjustable borders around game screen.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoRestedEmotes", "Silence rested emotes", 146, -192, true, "Silence emote sounds while resting.")
    LeaPlusLC:MakeTx(LeaPlusLC[pg], "Game Options", 340, -72)
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoBagAutomation", "Disable bag automation", 340, -92, true, "Do not auto open/close bags at vendors.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoConfirmLoot", "Disable loot warnings", 340, -112, false, "Disable loot roll and BoP warnings.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "FasterLooting", "Faster auto loot", 340, -132, true, "Instantly loot all creature items.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "FasterMovieSkip", "Faster movie skip", 340, -152, true, "Skip cinematics without confirmation.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "CombatPlates", "Combat plates", 340, -172, true, "Automatically toggle nameplates in combat.")
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "EasyItemDestroy", "Easy item destroy", 340, -192, true, "No delete typing needed for rare items.")
    LeaPlusLC:CfgBtn("SetWeatherDensityBtn", LeaPlusCB["SetWeatherDensity"])
    LeaPlusLC:CfgBtn("ModViewportBtn", LeaPlusCB["ViewPortEnable"])
    LeaPlusLC:CfgBtn("ModFasterLootingBtn", LeaPlusCB["FasterLooting"])

    -- Page 8 (Settings)
    pg = "Page8"
    LeaPlusLC:MakeTx(LeaPlusLC[pg], "Addon", 146, -72)
    LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowMinimapIcon", "Show minimap button", 146, -92, false, "Show LibDBIcon on minimap.")
    LeaPlusLC:MakeTx(LeaPlusLC[pg], "Scale", 340, -72)
    LeaPlusLC:MakeSL(LeaPlusLC[pg], "PlusPanelScale", "Drag to set panel scale.", 1, 2, 0.1, 340, -92, "%.1f")
    LeaPlusLC:MakeTx(LeaPlusLC[pg], "Transparency", 340, -132)
    LeaPlusLC:MakeSL(LeaPlusLC[pg], "PlusPanelAlpha", "Drag to set panel transparency.", 0, 1, 0.1, 340, -152, "%.1f")

    LeaPlusLC.CreateMainPanel = nil
end

LeaPlusLC:CreateMainPanel()

----------------------------------------------------------------------
-- 	L80: Slash Commands (Clean 3.3.5 Native APIs)
----------------------------------------------------------------------

function LeaPlusLC:SlashFunc(str)
    if not str or str == "" then
        if LeaPlusLC:IsPlusShowing() then
            LeaPlusLC:HideFrames()
            LeaPlusLC:HideConfigPanels()
        else
            LeaPlusLC:HideFrames()
            LeaPlusLC["PageF"]:Show()
            LeaPlusLC["Page" .. (LeaPlusLC["LeaStartPage"] or 0)]:Show()
        end
        return
    end

    local cmd, arg1 = strsplit(" ", strtrim(str:lower():gsub("%s+", " ")))

    if cmd == "wipe" then
        wipe(LeaPlusDB)
        ReloadUI()
    elseif cmd == "reset" then
        LeaPlusLC["MainPanelA"], LeaPlusLC["MainPanelR"], LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"] = "CENTER", "CENTER", 0, 0
        LeaPlusLC["PlusPanelScale"] = 1
        LeaPlusLC["PageF"]:ClearAllPoints()
        LeaPlusLC["PageF"]:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        LeaPlusLC["PageF"]:SetScale(1)
    elseif cmd == "rl" then
        ReloadUI()
    elseif cmd == "id" then
        local focus = GetMouseFocus()
        local tip = (focus == ItemRefTooltip) and ItemRefTooltip or GameTooltip
        if tip and tip:IsShown() then
            local _, link = tip:GetItem()
            if link then
                local id = link:match("item:(%d+)")
                if id then
                    LeaPlusLC:ShowSystemEditBox("https://www.wowhead.com/wotlk/item=" .. id, false)
                    return
                end
            end
            local name, _, spellID = tip:GetSpell()
            if spellID then
                LeaPlusLC:ShowSystemEditBox("https://www.wowhead.com/wotlk/spell=" .. spellID, false)
                return
            end
            local guid = UnitGUID("mouseover")
            if guid then
                local npcID = tonumber(guid:sub(9, 12), 16)
                if npcID then
                    LeaPlusLC:ShowSystemEditBox("https://www.wowhead.com/wotlk/npc=" .. npcID, false)
                    return
                end
            end
        end
    elseif cmd == "ra" then
        if UnitExists("target") then
            SetMapToCurrentZone()
            local x, y = GetPlayerMapPosition("player")
            local hp = floor(UnitHealth("target") / max(UnitHealthMax("target"), 1) * 100)
            local msg = string.format("%s (%d%%) at %.1f, %.1f", UnitName("target"), hp, x * 100, y * 100)
            SendChatMessage(msg, "CHANNEL", nil, GetChannelName("General"))
        end
    else
        LeaPlusLC:Print("Unknown command. Type /ltp for options.")
    end
end

_G.SLASH_Leatrix_Plus1 = "/ltp"
SlashCmdList["Leatrix_Plus"] = function(msg)
    LeaPlusLC:SlashFunc(msg)
end

-- Slash command for UI reload
_G.SLASH_LEATRIX_PLUS_RL1 = "/rl"
SlashCmdList["LEATRIX_PLUS_RL"] = function()
    ReloadUI()
end

-- Fallback alias function
function leaplus(msg)
    LeaPlusLC:SlashFunc(msg)
end

----------------------------------------------------------------------
-- 	L90: Create options panel pages
----------------------------------------------------------------------

-- Function to add menu button
function LeaPlusLC:MakeMN(name, text, parent, anchor, x, y, width, height)
    local mbtn = CreateFrame("Button", nil, parent)
    LeaPlusLC[name] = mbtn
    mbtn:Show()
    mbtn:SetSize(width, height)
    mbtn:SetAlpha(1.0)
    mbtn:SetPoint(anchor, x, y)

    mbtn.t = mbtn:CreateTexture(nil, "BACKGROUND")
    mbtn.t:SetAllPoints()
    mbtn.t:SetTexture("Interface\\Buttons\\WHITE8X8")
    mbtn.t:SetVertexColor(1.0, 0.5, 0.0, 0.8)
    mbtn.t:SetAlpha(0.7)
    mbtn.t:Hide()

    mbtn.s = mbtn:CreateTexture(nil, "BACKGROUND")
    mbtn.s:SetAllPoints()
    mbtn.s:SetTexture("Interface\\Buttons\\WHITE8X8")
    mbtn.s:SetVertexColor(1.0, 0.5, 0.0, 0.8)
    mbtn.s:Hide()

    mbtn.f = mbtn:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    mbtn.f:SetPoint('LEFT', 16, 0)
    mbtn.f:SetText(L[text])

    mbtn:SetScript("OnEnter", function()
        mbtn.t:Show()
    end)

    mbtn:SetScript("OnLeave", function()
        mbtn.t:Hide()
    end)

    return mbtn, mbtn.s
end

-- Function to create individual options panel pages
function LeaPlusLC:MakePage(name, title, menu, menuname, menuparent, menuanchor, menux, menuy, menuwidth, menuheight)
    local oPage = CreateFrame("Frame", nil, LeaPlusLC["PageF"])
    LeaPlusLC[name] = oPage
    oPage:SetAllPoints(LeaPlusLC["PageF"])
    oPage:Hide()

    -- Add page title
    oPage.s = oPage:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
    oPage.s:SetPoint('TOPLEFT', 146, -16)
    oPage.s:SetText(L[title])

    -- Add menu item if needed
    if menu then
        LeaPlusLC[menu], LeaPlusLC[menu .. ".s"] = LeaPlusLC:MakeMN(menu, menuname, menuparent, menuanchor, menux, menuy, menuwidth, menuheight)
        LeaPlusLC[name]:SetScript("OnShow", function()
            LeaPlusLC[menu .. ".s"]:Show()
        end)
        LeaPlusLC[name]:SetScript("OnHide", function()
            LeaPlusLC[menu .. ".s"]:Hide()
        end)
    end

    return oPage
end

-- Create options pages
LeaPlusLC["Page0"] = LeaPlusLC:MakePage("Page0", "Home", "LeaPlusNav0", "Home", LeaPlusLC["PageF"], "TOPLEFT", 16, -72, 112, 20)
LeaPlusLC["Page1"] = LeaPlusLC:MakePage("Page1", "Automation", "LeaPlusNav1", "Automation", LeaPlusLC["PageF"], "TOPLEFT", 16, -112, 112, 20)
LeaPlusLC["Page2"] = LeaPlusLC:MakePage("Page2", "Social", "LeaPlusNav2", "Social", LeaPlusLC["PageF"], "TOPLEFT", 16, -132, 112, 20)
LeaPlusLC["Page3"] = LeaPlusLC:MakePage("Page3", "Chat", "LeaPlusNav3", "Chat", LeaPlusLC["PageF"], "TOPLEFT", 16, -152, 112, 20)
LeaPlusLC["Page4"] = LeaPlusLC:MakePage("Page4", "Text", "LeaPlusNav4", "Text", LeaPlusLC["PageF"], "TOPLEFT", 16, -172, 112, 20)
LeaPlusLC["Page5"] = LeaPlusLC:MakePage("Page5", "Interface", "LeaPlusNav5", "Interface", LeaPlusLC["PageF"], "TOPLEFT", 16, -192, 112, 20)
LeaPlusLC["Page6"] = LeaPlusLC:MakePage("Page6", "Frames", "LeaPlusNav6", "Frames", LeaPlusLC["PageF"], "TOPLEFT", 16, -212, 112, 20)
LeaPlusLC["Page7"] = LeaPlusLC:MakePage("Page7", "System", "LeaPlusNav7", "System", LeaPlusLC["PageF"], "TOPLEFT", 16, -232, 112, 20)
LeaPlusLC["Page8"] = LeaPlusLC:MakePage("Page8", "Settings", "LeaPlusNav8", "Settings", LeaPlusLC["PageF"], "TOPLEFT", 16, -272, 112, 20)
LeaPlusLC["Page9"] = LeaPlusLC:MakePage("Page9", "Media", "LeaPlusNav9", "Media", LeaPlusLC["PageF"], "TOPLEFT", 16, -292, 112, 20)

-- Page navigation mechanism
for i = 0, LeaPlusLC["NumberOfPages"] do
    LeaPlusLC["LeaPlusNav" .. i]:SetScript("OnClick", function()
        LeaPlusLC:HideFrames()
        LeaPlusLC["PageF"]:Show()
        LeaPlusLC["Page" .. i]:Show()
        LeaPlusLC["LeaStartPage"] = i
    end)
end

local pg

----------------------------------------------------------------------
-- 	LC0: Welcome
----------------------------------------------------------------------

pg = "Page0"

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Welcome to Leatrix Plus.", 146, -72)
LeaPlusLC:MakeWD(LeaPlusLC[pg], "To begin, choose an options page.", 146, -92)

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Support", 146, -132)
LeaPlusLC:MakeWD(LeaPlusLC[pg], "|cff00ff00Feedback Discord:|r |cffadd8e6sattva108|r", 146, -152)
LeaPlusLC:MakeWD(LeaPlusLC[pg], "|cff00ff00Original Author:|r |cffadd8e6www.leatrix.com|r", 146, -172)

----------------------------------------------------------------------
-- 	LC1: Automation
----------------------------------------------------------------------

pg = "Page1"

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Character", 146, -72)
LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutomateQuests", "Automate quests", 146, -92, false, "If checked, quests will be selected, accepted and turned-in automatically.|n|nQuests which have a gold requirement will not be turned-in automatically.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutomateGossip", "Automate gossip", 146, -112, false, "If checked, single gossip options will be selected automatically. Hold Shift to override.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoAcceptSummon", "Accept summon", 146, -132, false, "If checked, summon requests will be accepted automatically unless you are in combat.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoAcceptRes", "Accept resurrection", 146, -152, false, "If checked, resurrection requests will be accepted automatically.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoReleasePvP", "Release in PvP", 146, -172, false, "If checked, you will release automatically after you die in a battleground.|n|nYou will not release automatically if you have the ability to self-resurrect.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoSpiritRes", "Auto Spirit Res Confirm", 146, -192, false, "If checked, you will resurrect automatically after talking to a Spirit Healer.")

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Vendors", 340, -72)
LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoSellJunk", "Sell junk automatically", 340, -92, false, "If checked, all grey items in your bags will be sold automatically when you visit a merchant.|n|nYou can hold the Shift key down when talking to a merchant to override this setting.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "AutoRepairGear", "Repair automatically", 340, -112, false, "If checked, your gear will be repaired automatically when you visit a suitable merchant.|n|nYou can hold the Shift key down when talking to a merchant to override this setting.")

LeaPlusLC:CfgBtn("AutomateQuestsBtn", LeaPlusCB["AutomateQuests"])
LeaPlusLC:CfgBtn("AutoAcceptResBtn", LeaPlusCB["AutoAcceptRes"])
LeaPlusLC:CfgBtn("AutoReleasePvPBtn", LeaPlusCB["AutoReleasePvP"])
LeaPlusLC:CfgBtn("AutoSellJunkBtn", LeaPlusCB["AutoSellJunk"])
LeaPlusLC:CfgBtn("AutoRepairBtn", LeaPlusCB["AutoRepairGear"])

----------------------------------------------------------------------
-- 	LC2: Social
----------------------------------------------------------------------

pg = "Page2"

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Blocks", 146, -72)
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoDuelRequests", "Block duels", 146, -92, false, "If checked, duel requests will be blocked unless the player requesting the duel is a friend.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoPartyInvites", "Block party invites", 146, -112, false, "If checked, party invitations will be blocked unless the player inviting you is a friend.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoGuildInvites", "Block guild invites", 146, -132, false, "If checked, guild invitations will be blocked unless the player inviting you is a friend.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoSharedQuests", "Block shared quests", 146, -152, false, "If checked, shared quests will be declined unless the player sharing the quest is a friend.")

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Groups", 340, -72)
LeaPlusLC:MakeCB(LeaPlusLC[pg], "AcceptPartyFriends", "Party from friends", 340, -92, false, "If checked, party invitations from friends will be automatically accepted unless you are queued for a battleground.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "InviteFromWhisper", "Invite from whispers", 340, -112, false, "If checked, a group invite will be sent to anyone who whispers you with a set keyword as long as you are ungrouped, group leader or raid assistant and not queued for a battleground.")

LeaPlusLC:MakeFT(LeaPlusLC[pg], "For all of the social options above, you can treat guild members as friends too.", 146, 380)
LeaPlusLC:MakeCB(LeaPlusLC[pg], "FriendlyGuild", "Guild", 146, -282, false, "If checked, members of your guild will be treated as friends for all of the options on this page.")

if LeaPlusCB["FriendlyGuild"].f:GetStringWidth() > 90 then
    LeaPlusCB["FriendlyGuild"].f:SetWidth(90)
    LeaPlusCB["FriendlyGuild"]:SetHitRectInsets(0, -84, 0, 0)
end

LeaPlusLC:CfgBtn("InvWhisperBtn", LeaPlusCB["InviteFromWhisper"])

----------------------------------------------------------------------
-- 	LC3: Chat
----------------------------------------------------------------------

pg = "Page3"

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Chat Frame", 146, -72)
LeaPlusLC:MakeCB(LeaPlusLC[pg], "UseEasyChatResizing", "Use easy resizing", 146, -92, true, "If checked, dragging the General chat tab while the chat frame is locked will expand the chat frame upwards.|n|nIf the chat frame is unlocked, dragging the General chat tab will move the chat frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoCombatLogTab", "Hide the combat log", 146, -112, true, "If checked, the combat log will be hidden.|n|nThe combat log must be docked in order for this option to work.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoChatButtons", "Hide chat buttons", 146, -132, true, "If checked, chat frame buttons will be hidden.|n|nUse the mouse wheel to scroll through the chat history. Hold down SHIFT for page jump or CTRL to jump to the top or bottom.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "UnclampChat", "Unclamp chat frame", 146, -152, true, "If checked, you will be able to drag the chat frame to the edge of the screen.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "MoveChatEditBoxToTop", "Move editbox to top", 146, -172, true, "If checked, the editbox will be moved to the top of the chat frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "MoreFontSizes", "More font sizes", 146, -192, true, "If checked, additional font sizes will be available in the chat frame font size menu.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "AltClickInv", "Alt click for Party Invite", 146, -212, true, "If checked, holding ALT while clicking a player's name in chat will invite them to your party.")

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Mechanics", 340, -72)
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoStickyChat", "Disable sticky chat", 340, -92, true, "If checked, sticky chat will be disabled for whispers and channels.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "UseArrowKeysInChat", "Use arrow keys in chat", 340, -112, true, "If checked, you can press the arrow keys to move the insertion point left and right in the chat frame without holding Alt.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoChatFade", "Disable chat fade", 340, -132, true, "If checked, chat text will not fade out over time.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "UnivGroupColor", "Universal group color", 340, -152, false, "If checked, raid chat will be colored blue to match party chat.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ClassColorsInChat", "Use class colors in chat", 340, -172, true, "If checked, class colors will be used in the chat frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "RecentChatWindow", "Recent chat window", 340, -192, true, "If checked, you can hold down the Control key and click a chat tab to view recent chat in a copy-friendly window.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "MaxChatHstory", "Increase chat history", 340, -212, true, "If checked, your chat history will increase to 4096 lines.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "FilterChatMessages", "Filter chat messages", 340, -232, true, "If checked, you can block spell links, drunken spam, and duel spam.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "RestoreChatMessages", "Restore chat messages", 340, -252, true, "If checked, recent chat messages will be restored when you reload your interface.")

LeaPlusLC:CfgBtn("FilterChatMessagesBtn", LeaPlusCB["FilterChatMessages"])

----------------------------------------------------------------------
-- 	LC4: Text
----------------------------------------------------------------------

pg = "Page4"

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Visibility", 146, -72)
LeaPlusLC:MakeCB(LeaPlusLC[pg], "HideErrorMessages", "Hide error messages", 146, -92, false, "If checked, most red error messages will not be shown. Alt-click the minimap button to toggle this setting on the fly.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoHitIndicators", "Hide portrait numbers", 146, -112, true, "If checked, damage and healing numbers in the player and pet portrait frames will be hidden.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "HideZoneText", "Hide zone text", 146, -132, true, "If checked, zone text banner will not be shown when entering a new zone.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "HideKeybindText", "Hide keybind text", 146, -152, true, "If checked, keybind text will not be shown on action buttons.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "HideMacroText", "Hide macro text", 146, -172, true, "If checked, macro names will not be shown on action buttons.")

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Text Size", 340, -72)
LeaPlusLC:MakeCB(LeaPlusLC[pg], "MailFontChange", "Resize mail text", 340, -92, true, "If checked, you will be able to change the font size of standard mail text.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "QuestFontChange", "Resize quest text", 340, -112, true, "If checked, you will be able to change the font size of quest text.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "BookFontChange", "Resize book text", 340, -132, true, "If checked, you will be able to change the font size of book text.")

LeaPlusLC:CfgBtn("MailTextBtn", LeaPlusCB["MailFontChange"])
LeaPlusLC:CfgBtn("QuestTextBtn", LeaPlusCB["QuestFontChange"])
LeaPlusLC:CfgBtn("BookTextBtn", LeaPlusCB["BookFontChange"])

----------------------------------------------------------------------
-- 	LC5: Interface
----------------------------------------------------------------------

pg = "Page5"

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Enhancements", 146, -72)
LeaPlusLC:MakeCB(LeaPlusLC[pg], "MinimapModder", "Enhance minimap", 146, -92, true, "If checked, you will be able to customise the minimap scale, square shape, and button layout.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "TipModEnable", "Enhance tooltip", 146, -112, true, "If checked, the tooltip will be color coded and you will be able to modify its anchor and scale.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "EnhanceDressup", "Enhance dressup", 146, -132, true, "If checked, you can pan and zoom in the character and dressup frames, toggle clothing, and toggle character stats.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "EnhanceQuestLog", "Enhance quest log", 146, -152, true, "If checked, quest levels and collapse headers will be available in the quest log.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "EnhanceProfessions", "Enhance professions", 146, -172, true, "If checked, the professions window will display a double-wide layout.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "EnhanceTrainers", "Enhance trainers", 146, -192, true, "If checked, the skill trainer window will be larger and include a Train All button.")

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Extras", 146, -232)
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowVolume", "Show volume slider", 146, -252, true, "If checked, a master volume slider will be shown in the character frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "AhExtras", "Show auction controls", 146, -272, true, "If checked, additional auction controls (Buyout Only, Gold Only, Tab to Confirm, Find Item) will be added to the auction house.")

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Extras", 340, -72)
LeaPlusLC:MakeCB(LeaPlusLC[pg], "DurabilityStatus", "Show durability status", 340, -112, true, "If checked, an item durability breakdown will be available on the character frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowVanityControls", "Toggle helm / cloak", 340, -132, true, "If checked, helm and cloak toggle checkboxes will be shown on the character frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowBagSearchBox", "Show bag search box", 340, -152, true, "If checked, a bag search box will be shown on the backpack and bank frames.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowPlayerChain", "Show player chain", 340, -192, true, "If checked, you can display a Rare, Elite, or Rare Elite dragon border around the player portrait.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowReadyTimer", "Show ready timer", 340, -212, true, "If checked, a countdown timer bar will appear under the battleground ready popup.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowWowheadLinks", "Show Wowhead links", 340, -232, true, "If checked, copyable Wowhead URLs will appear on quest logs and achievement frames.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ShowFlightTimes", "Show flight times", 340, -252, true, "If checked, flight times will be shown on flight master maps and during in-flight travel.")

LeaPlusLC:CfgBtn("ModMinimapBtn", LeaPlusCB["MinimapModder"])
LeaPlusLC:CfgBtn("MoveTooltipButton", LeaPlusCB["TipModEnable"])
LeaPlusLC:CfgBtn("EnhanceQuestLogBtn", LeaPlusCB["EnhanceQuestLog"])
LeaPlusLC:CfgBtn("EnhanceTrainersBtn", LeaPlusCB["EnhanceTrainers"])
LeaPlusLC:CfgBtn("ModPlayerChain", LeaPlusCB["ShowPlayerChain"])
LeaPlusLC:CfgBtn("ShowWowheadLinksBtn", LeaPlusCB["ShowWowheadLinks"])
LeaPlusLC:CfgBtn("ShowFlightTimesBtn", LeaPlusCB["ShowFlightTimes"])

----------------------------------------------------------------------
-- 	LC6: Frames
----------------------------------------------------------------------

pg = "Page6"

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Features", 146, -72)
LeaPlusLC:MakeCB(LeaPlusLC[pg], "FrmEnabled", "Manage frames", 146, -92, true, "If checked, you will be able to change the position and scale of the player frame and target frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageBuffs", "Manage buffs", 146, -112, true, "If checked, you will be able to change the position and scale of the buffs frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageWidget", "Manage widget", 146, -132, true, "If checked, you will be able to change the position and scale of the top-center widget frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageFocus", "Manage focus", 146, -152, true, "If checked, you will be able to change the position and scale of the focus frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageTimer", "Manage timer", 146, -172, true, "If checked, you will be able to change the position and scale of the mirror breath/fatigue timer bar.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageDurability", "Manage durability", 146, -192, true, "If checked, you will be able to change the position and scale of the durability figure.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageVehicle", "Manage vehicle", 146, -212, true, "If checked, you will be able to change the position and scale of the vehicle seat indicator frame.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ClassColFrames", "Class colored frames", 146, -232, true, "If checked, class coloring will be used in the player, target, and focus frames.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageTracker", "Manage Quest Tracker", 146, -252, true, "If checked, you will be able to change the position and scale of the objective quest tracker.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ManageDeBuffs", "Manage Debuffs", 146, -272, true, "If checked, you will be able to change the position and scale of the debuffs frame.")

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Visibility", 340, -72)
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoAlerts", "Hide alerts", 340, -92, true, "If checked, achievement popups will be hidden and clean links will be printed in chat instead.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoGryphons", "Hide gryphons", 340, -112, true, "If checked, the main action bar end cap gryphons will be hidden.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoClassBar", "Hide stance bar", 340, -132, true, "If checked, the stance/shapeshift bar will be hidden.")

LeaPlusLC:CfgBtn("MoveFramesButton", LeaPlusCB["FrmEnabled"])
LeaPlusLC:CfgBtn("ManageBuffsButton", LeaPlusCB["ManageBuffs"])
LeaPlusLC:CfgBtn("ManageWidgetButton", LeaPlusCB["ManageWidget"])
LeaPlusLC:CfgBtn("ManageFocusButton", LeaPlusCB["ManageFocus"])
LeaPlusLC:CfgBtn("ManageTimerButton", LeaPlusCB["ManageTimer"])
LeaPlusLC:CfgBtn("ManageDurabilityButton", LeaPlusCB["ManageDurability"])
LeaPlusLC:CfgBtn("ManageVehicleButton", LeaPlusCB["ManageVehicle"])
LeaPlusLC:CfgBtn("ClassColFramesBtn", LeaPlusCB["ClassColFrames"])
LeaPlusLC:CfgBtn("ManageTrackerButton", LeaPlusCB["ManageTracker"])
LeaPlusLC:CfgBtn("ManageDeBuffsButton", LeaPlusCB["ManageDeBuffs"])

----------------------------------------------------------------------
-- 	LC7: System
----------------------------------------------------------------------

pg = "Page7"

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Graphics and Sound", 146, -72)
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoScreenGlow", "Disable screen glow", 146, -92, false, "If checked, full-screen glow and drunken haze will be disabled.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoScreenEffects", "Disable screen effects", 146, -112, false, "If checked, the grey screen of death and netherworld effects will be disabled.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "SetWeatherDensity", "Set weather density", 146, -132, false, "If checked, you can adjust the density of weather effects.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "MaxCameraZoom", "Max camera zoom", 146, -152, false, "If checked, maximum camera distance will be increased to the hardware limit.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "ViewPortEnable", "Enable viewport", 146, -172, true, "If checked, you can add adjustable cinematic black borders around the game world.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoRestedEmotes", "Silence rested emotes", 146, -192, true, "If checked, emote sounds will be silenced while resting.")

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Game Options", 340, -72)
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoBagAutomation", "Disable bag automation", 340, -92, true, "If checked, bags will not automatically open or close when interacting with merchants, banks, or mailboxes.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "NoConfirmLoot", "Disable loot warnings", 340, -132, false, "If checked, confirmations will no longer appear when choosing loot roll options, looting bind-on-pickup items, or disenchanting.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "FasterLooting", "Faster auto loot", 340, -152, true, "If checked, the amount of time it takes to auto loot will be significantly reduced.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "FasterMovieSkip", "Faster movie skip", 340, -172, true, "If checked, cinematics can be skipped instantly with Escape.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "CombatPlates", "Combat plates", 340, -232, true, "If checked, enemy nameplates will be displayed during combat and hidden outside combat.")
LeaPlusLC:MakeCB(LeaPlusLC[pg], "EasyItemDestroy", "Easy item destroy", 340, -252, true, "If checked, you will not need to type DELETE to destroy items.")

LeaPlusLC:CfgBtn("SetWeatherDensityBtn", LeaPlusCB["SetWeatherDensity"])
LeaPlusLC:CfgBtn("ModViewportBtn", LeaPlusCB["ViewPortEnable"])
LeaPlusLC:CfgBtn("ModFasterLootingBtn", LeaPlusCB["FasterLooting"])

----------------------------------------------------------------------
-- 	LC8: Settings
----------------------------------------------------------------------

pg = "Page8"

-- Panel Controls (Left Column)
LeaPlusLC:MakeTx(LeaPlusLC[pg], "Addon", 146, -72)
LeaPlusLC:MakeCB(
    LeaPlusLC[pg],
    "ShowMinimapIcon",
    "Show minimap button",
    146,
    -92,
    false,
    "If checked, the minimap button will be shown.|n|nLeft-Click: Toggle options panel.|nRight-Click: Reload UI.|nAlt-Click: Toggle error messages."
)

-- Reset Anchor & Scale Button
local resetLayoutBtn = LeaPlusLC:CreateButton(
    "ResetLayoutBtn",
    LeaPlusLC[pg],
    "Reset Layout",
    "TOPLEFT",
    146,
    -122,
    140,
    22,
    true,
    "Click to reset the Leatrix Plus panel position and scale to default."
)
resetLayoutBtn:SetScript("OnClick", function()
    LeaPlusLC:SlashFunc("reset")
end)

-- Memory Usage Display (Embedded on Settings Page)
if LeaPlusLC.ShowMemoryUsage then
    LeaPlusLC:ShowMemoryUsage(LeaPlusLC[pg], "TOPLEFT", 146, -170)
end

-- Panel Appearance (Right Column)
LeaPlusLC:MakeTx(LeaPlusLC[pg], "Scale", 340, -72)
LeaPlusLC:MakeSL(
    LeaPlusLC[pg],
    "PlusPanelScale",
    "Drag to set the scale of the Leatrix Plus panel.",
    1,
    2,
    0.1,
    340,
    -92,
    "%.1f"
)

LeaPlusLC:MakeTx(LeaPlusLC[pg], "Transparency", 340, -132)
LeaPlusLC:MakeSL(
    LeaPlusLC[pg],
    "PlusPanelAlpha",
    "Drag to set the transparency of the Leatrix Plus panel.",
    0,
    1,
    0.1,
    340,
    -152,
    "%.1f"
)
