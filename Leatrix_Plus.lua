-- Leatrix_Plus.lua
----------------------------------------------------------------------
-- Leatrix Plus 3.3.5 (Core Host & GUI Engine)
----------------------------------------------------------------------

LibCompat = LibStub:GetLibrary("LibCompat-1.0")
_G.LeaPlusDB = _G.LeaPlusDB or {}
LeaPlusDB = _G.LeaPlusDB

local void, Leatrix_Plus = ...
local L = Leatrix_Plus.L

-- Verify 3.3.5 Client
do
    local _, _, _, gametocversion = GetBuildInfo()
    if not gametocversion or gametocversion < 30000 or gametocversion > 39999 then
        LibCompat.After(2, function()
            print("|cffff0000LEATRIX PLUS: WRONG WOW VERSION INSTALLED! (Requires 3.3.5)|r")
        end)
        return
    end
end

-- Core registries & modules
local LeaPlusLC, LeaPlusCB, LeaDropList, LeaConfigList, LeaLockList = {}, {}, {}, {}, {}
LeaPlusLC["AddonVer"] = "3.3.5"
LeaPlusLC["NumberOfPages"] = 8  -- Pages 0 through 8 (Media removed)
LeaPlusLC["RaidColors"] = RAID_CLASS_COLORS

Leatrix_Plus.LC = LeaPlusLC
Leatrix_Plus.CB = LeaPlusCB
Leatrix_Plus.DropList = LeaDropList
Leatrix_Plus.ConfigList = LeaConfigList
Leatrix_Plus.LockList = LeaLockList
Leatrix_Plus.Modules = {}

function Leatrix_Plus:RegisterModule(name, mod)
    self.Modules[name] = mod
end

if IsAddOnLoaded("ElvUI") then LeaPlusLC.ElvUI = unpack(ElvUI) end
if IsAddOnLoaded("Glass") then LeaPlusLC.Glass = true end

-- Keybinding translations
_G.BINDING_HEADER_LEATRIX_PLUS = "Leatrix Plus"
_G.BINDING_NAME_LEATRIX_PLUS_GLOBAL_TOGGLE = L["Toggle panel"]
_G.BINDING_NAME_LEATRIX_PLUS_GLOBAL_WEBLINK = L["Show web link"]
_G.BINDING_NAME_LEATRIX_PLUS_GLOBAL_RARE = L["Announce rare"]

----------------------------------------------------------------------
-- UI Tooling Library
----------------------------------------------------------------------
function LeaPlusLC:Print(text)
    DEFAULT_CHAT_FRAME:AddMessage(L[text] or text, 1.0, 0.85, 0.0)
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

function LeaPlusLC:HideFrames()
    for i = 0, LeaPlusLC["NumberOfPages"] do
        if LeaPlusLC["Page" .. i] then
            LeaPlusLC["Page" .. i]:Hide()
        end
    end
    if LeaPlusLC["PageF"] then LeaPlusLC["PageF"]:Hide() end
end

function LeaPlusLC:IsPlusShowing()
    if LeaPlusLC["PageF"] and LeaPlusLC["PageF"]:IsShown() then return true end
    for _, v in pairs(LeaConfigList) do
        if v:IsShown() then return true end
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

function LeaPlusLC:IsInLFGQueue()
    return MiniMapLFGFrame and MiniMapLFGFrame:IsShown()
end

function LeaPlusLC:FriendCheck(name)
    if not name then return false end
    name = strlower(strsplit("-", name))

    for i = 1, GetNumFriends() do
        local friendName, _, _, _, connected = GetFriendInfo(i)
        if friendName and connected then
            if strlower(strsplit("-", friendName)) == name then
                return true
            end
        end
    end

    if LeaPlusLC["FriendlyGuild"] == "On" and IsInGuild() then
        for i = 1, GetNumGuildMembers() do
            local gName, _, _, _, _, _, _, _, gOnline = GetGuildRosterInfo(i)
            if gName and gOnline then
                if strlower(strsplit("-", gName)) == name then
                    return true
                end
            end
        end
    end
    return false
end

function LeaPlusLC:ShowSystemEditBox(word)
    if not LeaPlusLC.FactoryEditBox then
        local eFrame = CreateFrame("Frame", nil, UIParent)
        LeaPlusLC.FactoryEditBox = eFrame
        eFrame:SetSize(700, 110)
        eFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
        eFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        eFrame:EnableMouse(true)

        eFrame.t = eFrame:CreateTexture(nil, "BACKGROUND")
        eFrame.t:SetAllPoints()
        eFrame.t:SetTexture(0.05, 0.05, 0.05, 0.9)

        eFrame.f = eFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        eFrame.f:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 12, -52)
        eFrame.f:SetWidth(676)
        eFrame.f:SetJustifyH("LEFT")

        eFrame.c = eFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        eFrame.c:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 12, -82)
        eFrame.c:SetText(L["Press CTRL/C to copy"])

        local cancelLabel = eFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        cancelLabel:SetPoint("TOPRIGHT", eFrame, "TOPRIGHT", -12, -82)
        cancelLabel:SetText(L["Right-click to close"])

        eFrame.b = CreateFrame("EditBox", "LeatrixSystemEditBox", eFrame, "InputBoxTemplate")
        eFrame.b:SetPoint("TOPLEFT", eFrame, "TOPLEFT", 16, -12)
        eFrame.b:SetSize(672, 24)
        eFrame.b:SetFontObject("GameFontNormalLarge")
        eFrame.b:SetAutoFocus(true)
        eFrame.b:SetScript("OnEscapePressed", function() eFrame:Hide() end)
        eFrame:SetScript("OnMouseDown", function(_, btn) if btn == "RightButton" then eFrame:Hide() end end)
    end

    LeaPlusLC.FactoryEditBox:Show()
    LeaPlusLC.FactoryEditBox.b:SetText(word)
    LeaPlusLC.FactoryEditBox.b:HighlightText()
    LeaPlusLC.FactoryEditBox.b:SetFocus(true)
end

function LeaPlusLC:TipSee()
    GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
    GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
end

function LeaPlusLC:ShowTooltip()
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
end

function LeaPlusLC:CfgBtn(name, parent)
    local btn = CreateFrame("Button", nil, parent)
    LeaPlusCB[name] = btn
    btn:SetWidth(20); btn:SetHeight(20)
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

function LeaPlusLC:CreatePanel(title, globref)
    local Side = CreateFrame("Frame", "LeaPlusGlobalPanel_" .. globref, UIParent)
    tinsert(UISpecialFrames, "LeaPlusGlobalPanel_" .. globref)
    tinsert(LeaConfigList, Side)

    Side:Hide(); Side:SetSize(570, 370); Side:SetClampedToScreen(true)
    Side:SetFrameStrata("FULLSCREEN_DIALOG")

    Side.t = Side:CreateTexture(nil, "BACKGROUND")
    Side.t:SetAllPoints(); Side.t:SetTexture(0.05, 0.05, 0.05, 0.9)

    Side.c = CreateFrame("Button", nil, Side, "UIPanelCloseButton")
    Side.c:SetSize(30, 30); Side.c:SetPoint("TOPRIGHT", 0, 0)
    Side.c:SetScript("OnClick", function() Side:Hide() end)

    Side.r = LeaPlusLC:CreateButton("ResetButton", Side, "Reset", "TOPLEFT", 16, -292, 0, 25, true, "Reset settings on this page.")
    Side.h = LeaPlusLC:CreateButton("HelpButton", Side, "Help", "TOPLEFT", 76, -292, 0, 25, true, "Page help.")
    Side.h:ClearAllPoints(); Side.h:SetPoint("LEFT", Side.r, "RIGHT", 10, 0)
    Side.b = LeaPlusLC:CreateButton("BackButton", Side, "Back to Main Menu", "TOPRIGHT", -16, -292, 0, 25, true, "Return to main menu.")

    Side.f = Side:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    Side.f:SetPoint("TOPLEFT", 16, -16); Side.f:SetText(L[title])

    Side:EnableMouse(true); Side:SetMovable(true); Side:RegisterForDrag("LeftButton")
    Side:SetScript("OnDragStart", Side.StartMoving)
    Side:SetScript("OnDragStop", Side.StopMovingOrSizing)

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

function LeaPlusLC:MakeFT(frame, text, left, width)
    local footer = LeaPlusLC:MakeTx(frame, text, left, 96)
    footer:SetWidth(width); footer:SetJustifyH("LEFT"); footer:SetWordWrap(true)
    footer:ClearAllPoints(); footer:SetPoint("BOTTOMLEFT", left, 96)
end

function LeaPlusLC:MakeCB(parent, field, caption, x, y, reload, tip)
    local Cbox = CreateFrame("CheckButton", nil, parent, "ChatConfigCheckButtonTemplate")
    LeaPlusCB[field] = Cbox
    Cbox:SetPoint("TOPLEFT", x, y)
    Cbox:SetScript("OnEnter", LeaPlusLC.TipSee)
    Cbox:SetScript("OnLeave", GameTooltip_Hide)

    Cbox.f = Cbox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    Cbox.f:SetPoint("LEFT", 23, 0)
    Cbox.f:SetText(L[caption] .. (reload and "*" or ""))
    Cbox.tiptext = L[tip] .. (reload and ("|n|n* " .. L["Requires UI reload."]) or "")

    Cbox:SetScript("OnShow", function(self)
        self:SetChecked(LeaPlusLC[field] == "On")
    end)
    Cbox:SetScript("OnClick", function(self)
        LeaPlusLC[field] = self:GetChecked() and "On" or "Off"
        LeaPlusLC:SetDim()
        LeaPlusLC:ReloadCheck()
    end)
end

function LeaPlusLC:MakeSL(frame, field, caption, low, high, step, x, y, form)
    local Slider = CreateFrame("Slider", "LeaPlusGlobalSlider" .. field, frame, "OptionssliderTemplate")
    LeaPlusCB[field] = Slider
    Slider:SetMinMaxValues(low, high); Slider:SetValueStep(step)
    Slider:SetPoint("TOPLEFT", x, y); Slider:SetWidth(100); Slider:SetHeight(20)
    Slider.tiptext = L[caption]
    Slider:SetScript("OnEnter", LeaPlusLC.TipSee); Slider:SetScript("OnLeave", GameTooltip_Hide)

    _G[Slider:GetName() .. "Low"]:SetText("")
    _G[Slider:GetName() .. "High"]:SetText("")

    Slider.f = Slider:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
    Slider.f:SetPoint("LEFT", Slider, "RIGHT", 12, 0)

    Slider:SetScript("OnValueChanged", function(self, value)
        local val = floor((value - low) / step + 0.5) * step + low
        Slider.f:SetFormattedText(form, val)
        LeaPlusLC[field] = val
    end)
    Slider:SetScript("OnShow", function(self)
        self:SetValue(LeaPlusLC[field] or low)
    end)
end

function LeaPlusLC:CreateEditBox(frame, parent, width, height, anchor, x, y, tab, shifttab, maxchars)
    local eb = CreateFrame("EditBox", nil, parent)
    eb:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12, insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    eb:SetBackdropColor(0, 0, 0, 0.5)
    eb:SetTextInsets(6, 6, 0, 0)
    LeaPlusCB[frame] = eb
    eb:SetPoint(anchor, x, y); eb:SetWidth(width); eb:SetHeight(height)
    eb:SetFontObject("GameFontNormal"); eb:SetTextColor(1, 1, 1); eb:SetAutoFocus(false)
    eb:SetMaxLetters(maxchars or 0)
    eb:SetScript("OnEscapePressed", eb.ClearFocus)
    eb:SetScript("OnEnterPressed", eb.ClearFocus)
    return eb
end

function LeaPlusLC:CreateButton(name, frame, label, anchor, x, y, width, height, reskin, tip)
    local mbtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    LeaPlusCB[name] = mbtn
    mbtn:SetSize(width > 0 and width or 100, height)
    mbtn:SetPoint(anchor, x, y)
    mbtn:SetText(L[label])
    mbtn.tiptext = L[tip]
    mbtn:SetScript("OnEnter", LeaPlusLC.TipSee); mbtn:SetScript("OnLeave", GameTooltip_Hide)
    return mbtn
end

function LeaPlusLC:CreateDropDown(ddname, label, parent, width, anchor, x, y, items, tip)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetWidth(width); frame:SetHeight(42)
    frame:SetPoint("BOTTOMLEFT", parent, anchor, x, y)

    local lf = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lf:SetPoint("TOPLEFT", frame, 0, 0); lf:SetText(L[label])

    local value = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    value:SetPoint("BOTTOMLEFT", 10, 5)

    local dbtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    dbtn:SetSize(width, 22); dbtn:SetPoint("BOTTOMLEFT", 0, 0)
    dbtn:SetText(items[LeaPlusLC[ddname] or 1] or "")

    dbtn:SetScript("OnClick", function()
        local current = LeaPlusLC[ddname] or 1
        current = (current % #items) + 1
        LeaPlusLC[ddname] = current
        dbtn:SetText(items[current])
    end)
    return frame
end

function LeaPlusLC:LockOption(option, item, reloadreq)
    if not LeaPlusCB[item] then return end
    if LeaPlusLC[option] == "Off" then
        LeaPlusLC:LockItem(LeaPlusCB[item], true)
    else
        LeaPlusLC:LockItem(LeaPlusCB[item], false)
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
    LeaPlusLC:LockOption("MinimapModder", "ModMinimapBtn", true)
    LeaPlusLC:LockOption("TipModEnable", "MoveTooltipButton", true)
    LeaPlusLC:LockOption("EnhanceQuestLog", "EnhanceQuestLogBtn", true)
    LeaPlusLC:LockOption("EnhanceTrainers", "EnhanceTrainersBtn", true)
    LeaPlusLC:LockOption("ShowPlayerChain", "ModPlayerChain", true)
    LeaPlusLC:LockOption("ShowFlightTimes", "ShowFlightTimesBtn", true)
    LeaPlusLC:LockOption("FrmEnabled", "MoveFramesButton", true)
    LeaPlusLC:LockOption("ClassColFrames", "ClassColFramesBtn", true)
    LeaPlusLC:LockOption("ViewPortEnable", "ModViewportBtn", true)
end

function LeaPlusLC:ReloadCheck()
    local needsReload = false
    local checkKeys = {
        "UseEasyChatResizing", "NoCombatLogTab", "NoChatButtons", "UnclampChat",
        "MoveChatEditBoxToTop", "MoreFontSizes", "AltClickInv", "NoStickyChat",
        "UseArrowKeysInChat", "NoChatFade", "ClassColorsInChat", "RecentChatWindow",
        "MaxChatHstory", "FilterChatMessages", "RestoreChatMessages", "NoHitIndicators",
        "HideZoneText", "HideKeybindText", "HideMacroText", "MailFontChange",
        "QuestFontChange", "BookFontChange", "MinimapModder", "SquareMinimap",
        "TipModEnable", "EnhanceQuestLog", "EnhanceProfessions", "EnhanceTrainers",
        "ShowVolume", "AhExtras", "DurabilityStatus", "ShowVanityControls",
        "ShowBagSearchBox", "ShowPlayerChain", "ShowReadyTimer", "ShowFlightTimes",
        "FrmEnabled", "ClassColFrames", "NoAlerts", "NoGryphons", "NoClassBar",
        "ViewPortEnable", "NoRestedEmotes", "NoBagAutomation", "FasterLooting",
        "FasterMovieSkip", "CombatPlates", "EasyItemDestroy"
    }

    for _, k in ipairs(checkKeys) do
        if LeaPlusLC[k] ~= LeaPlusDB[k] then
            needsReload = true
            break
        end
    end

    if LeaPlusCB["ReloadUIButton"] then
        LeaPlusLC:LockItem(LeaPlusCB["ReloadUIButton"], not needsReload)
        if needsReload then LeaPlusCB["ReloadUIButton"].f:Show() else LeaPlusCB["ReloadUIButton"].f:Hide() end
    end
end

----------------------------------------------------------------------
-- Profile / Settings DB Persistence
----------------------------------------------------------------------
local function LoadSettings()
    local function LoadChk(k, def) LeaPlusLC[k] = (LeaPlusDB[k] == "On" or LeaPlusDB[k] == "Off") and LeaPlusDB[k] or def end
    local function LoadNum(k, def) LeaPlusLC[k] = (type(LeaPlusDB[k]) == "number") and LeaPlusDB[k] or def end
    local function LoadStr(k, def) LeaPlusLC[k] = (type(LeaPlusDB[k]) == "string") and LeaPlusDB[k] or def end

    -- Automation
    LoadChk("AutomateQuests", "Off"); LoadChk("AutoQuestShift", "Off"); LoadChk("AutoQuestAvailable", "On")
    LoadChk("AutoQuestCompleted", "On"); LoadNum("AutoQuestKeyMenu", 1); LoadChk("AutomateGossip", "Off")
    LoadChk("AutoAcceptSummon", "Off"); LoadChk("AutoAcceptRes", "Off"); LoadChk("AutoResNoCombat", "On")
    LoadChk("AutoReleasePvP", "Off"); LoadChk("AutoReleaseNoAlterac", "Off"); LoadChk("AutoReleaseShiftCancel", "On")
    LoadNum("AutoReleaseDelay", 200); LoadChk("AutoSpiritRes", "Off"); LoadChk("AutoSellJunk", "Off")
    LoadChk("AutoSellShowSummary", "On"); LoadStr("AutoSellExcludeList", ""); LoadChk("AutoRepairGear", "Off")
    LoadChk("AutoRepairGuildFunds", "On"); LoadChk("AutoRepairShowSummary", "On")

    -- Social
    LoadChk("NoDuelRequests", "Off"); LoadChk("NoPartyInvites", "Off"); LoadChk("NoGuildInvites", "Off")
    LoadChk("NoSharedQuests", "Off"); LoadChk("AcceptPartyFriends", "Off"); LoadChk("InviteFromWhisper", "Off")
    LoadChk("InviteFriendsOnly", "Off"); LoadStr("InvKey", "inv"); LoadChk("FriendlyGuild", "On")

    -- Chat
    LoadChk("UseEasyChatResizing", "Off"); LoadChk("NoCombatLogTab", "Off"); LoadChk("NoChatButtons", "Off")
    LoadChk("UnclampChat", "Off"); LoadChk("MoveChatEditBoxToTop", "Off"); LoadChk("MoreFontSizes", "Off")
    LoadChk("AltClickInv", "Off"); LoadChk("NoStickyChat", "Off"); LoadChk("UseArrowKeysInChat", "Off")
    LoadChk("NoChatFade", "Off"); LoadChk("UnivGroupColor", "Off"); LoadChk("ClassColorsInChat", "Off")
    LoadChk("RecentChatWindow", "Off"); LoadNum("RecentChatSize", 170); LoadChk("MaxChatHstory", "Off")
    LoadChk("FilterChatMessages", "Off"); LoadChk("RestoreChatMessages", "Off")

    -- Text
    LoadChk("HideErrorMessages", "Off"); LoadChk("NoHitIndicators", "Off"); LoadChk("HideZoneText", "Off")
    LoadChk("HideKeybindText", "Off"); LoadChk("HideMacroText", "Off")

    -- Interface & Minimap
    LoadChk("MinimapModder", "Off"); LoadChk("SquareMinimap", "Off"); LoadChk("ShowWhoPinged", "On")
    LoadChk("HideMiniZoomBtns", "Off"); LoadChk("HideMiniZoneText", "Off"); LoadChk("HideMiniMapButton", "On")
    LoadChk("HideMiniTracking", "Off"); LoadChk("HideMiniCalendar", "Off"); LoadChk("ClockMouseover", "Off")
    LoadNum("MinimapScale", 1); LoadNum("MiniClusterScale", 1)

    -- Frames
    LoadChk("FrmEnabled", "Off"); LoadChk("ManageBuffs", "Off"); LoadChk("ManageDeBuffs", "Off")
    LoadChk("ManageVehicle", "Off"); LoadChk("ManageWidget", "Off"); LoadChk("ManageFocus", "Off")
    LoadChk("ManageTimer", "Off"); LoadChk("ManageDurability", "Off"); LoadChk("ManageTracker", "Off")
    LoadChk("ClassColFrames", "Off"); LoadChk("ClassColPlayer", "On"); LoadChk("ClassColTarget", "On")
    LoadChk("NoAlerts", "Off"); LoadChk("NoGryphons", "Off"); LoadChk("NoClassBar", "Off")
    LoadChk("ShowPlayerChain", "Off"); LoadNum("PlayerChainMenu", 2)

    -- System
    LoadChk("NoScreenGlow", "Off"); LoadChk("NoScreenEffects", "Off"); LoadChk("SetWeatherDensity", "Off")
    LoadNum("WeatherLevel", 3); LoadChk("MaxCameraZoom", "Off"); LoadChk("ViewPortEnable", "Off")
    LoadNum("ViewPortTop", 0); LoadNum("ViewPortBottom", 0); LoadNum("ViewPortLeft", 0); LoadNum("ViewPortRight", 0)
    LoadNum("ViewPortAlpha", 0); LoadChk("NoRestedEmotes", "Off"); LoadChk("FasterLooting", "Off")
    LoadChk("FasterMovieSkip", "Off"); LoadChk("CombatPlates", "Off"); LoadChk("EasyItemDestroy", "Off")
    LoadChk("ShowVolume", "Off"); LoadChk("AhExtras", "Off"); LoadChk("DurabilityStatus", "Off")
    LoadChk("ShowVanityControls", "Off"); LoadChk("ShowBagSearchBox", "Off"); LoadChk("ShowFlightTimes", "Off")
    LoadChk("EnhanceTrainers", "Off"); LoadChk("EnhanceProfessions", "Off"); LoadChk("EnhanceQuestLog", "Off")
    LoadChk("ShowMinimapIcon", "On"); LoadNum("PlusPanelScale", 1)
end

local function SaveSettings()
    for k, v in pairs(LeaPlusLC) do
        LeaPlusDB[k] = v
    end
end

----------------------------------------------------------------------
-- Main Frame & Navigation Setup
----------------------------------------------------------------------
local function CreateMainPanel()
    local PageF = CreateFrame("Frame", "LeaPlusGlobalPanel", UIParent)
    LeaPlusLC["PageF"] = PageF
    PageF:SetSize(570, 370); PageF:Hide(); PageF:SetFrameStrata("FULLSCREEN_DIALOG")
    PageF:SetClampedToScreen(true); PageF:EnableMouse(true); PageF:SetMovable(true)
    PageF:RegisterForDrag("LeftButton")
    PageF:SetScript("OnDragStart", PageF.StartMoving)
    PageF:SetScript("OnDragStop", PageF.StopMovingOrSizing)
    tinsert(UISpecialFrames, "LeaPlusGlobalPanel")

    PageF.t = PageF:CreateTexture(nil, "BACKGROUND")
    PageF.t:SetAllPoints(); PageF.t:SetTexture(0.05, 0.05, 0.05, 0.9)

    PageF.mt = PageF:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    PageF.mt:SetPoint("TOPLEFT", 16, -16); PageF.mt:SetText("Leatrix Plus")

    PageF.v = PageF:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    PageF.v:SetPoint("TOPLEFT", PageF.mt, "BOTTOMLEFT", 0, -4)
    PageF.v:SetText(L["Version"] .. " " .. LeaPlusLC["AddonVer"])

    local CloseB = CreateFrame("Button", nil, PageF, "UIPanelCloseButton")
    CloseB:SetSize(30, 30); CloseB:SetPoint("TOPRIGHT", 0, 0)
    CloseB:SetScript("OnClick", LeaPlusLC.HideFrames)

    local reloadb = LeaPlusLC:CreateButton("ReloadUIButton", PageF, "Reload", "BOTTOMRIGHT", -16, 10, 0, 25, true, "Reload UI to apply pending changes.")
    reloadb:SetScript("OnClick", ReloadUI)
    reloadb.f = reloadb:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    reloadb.f:SetPoint("RIGHT", reloadb, "LEFT", -10, 0)
    reloadb.f:SetText(L["Your UI needs to be reloaded."])
    reloadb.f:Hide()
    LeaPlusLC:LockItem(reloadb, true)

    local function MakePage(name, title, idx)
        local p = CreateFrame("Frame", nil, PageF)
        LeaPlusLC[name] = p; p:SetAllPoints(PageF); p:Hide()
        p.s = p:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        p.s:SetPoint("TOPLEFT", 146, -16); p.s:SetText(L[title])

        local nav = CreateFrame("Button", nil, PageF)
        nav:SetSize(112, 20); nav:SetPoint("TOPLEFT", 16, -72 + -(idx * 20))
        nav.f = nav:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        nav.f:SetPoint("LEFT", 8, 0); nav.f:SetText(L[title])

        nav.s = nav:CreateTexture(nil, "BACKGROUND")
        nav.s:SetAllPoints(); nav.s:SetTexture("Interface\\Buttons\\WHITE8X8")
        nav.s:SetVertexColor(1.0, 0.5, 0.0, 0.8); nav.s:Hide()

        p:SetScript("OnShow", function() nav.s:Show() end)
        p:SetScript("OnHide", function() nav.s:Hide() end)

        nav:SetScript("OnClick", function()
            LeaPlusLC:HideFrames()
            PageF:Show(); p:Show()
            LeaPlusLC["LeaStartPage"] = idx
        end)
        return p
    end

    -- Create pages (Media removed)
    MakePage("Page0", "Home", 0)
    MakePage("Page1", "Automation", 1)
    MakePage("Page2", "Social", 2)
    MakePage("Page3", "Chat", 3)
    MakePage("Page4", "Text", 4)
    MakePage("Page5", "Interface", 5)
    MakePage("Page6", "Frames", 6)
    MakePage("Page7", "System", 7)
    MakePage("Page8", "Settings", 8)

    -- Populate Checkboxes across pages
    -- Page 0 (Home)
    LeaPlusLC:MakeTx(LeaPlusLC["Page0"], "Welcome to Leatrix Plus.", 146, -72)
    LeaPlusLC:MakeWD(LeaPlusLC["Page0"], "Quality of life addon for Wrath of the Lich King 3.3.5.", 146, -92)

    -- Page 1 (Automation)
    LeaPlusLC:MakeTx(LeaPlusLC["Page1"], "Character", 146, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page1"], "AutomateQuests", "Automate quests", 146, -92, false, "Automate quest accepting and turn-in.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page1"], "AutomateGossip", "Automate gossip", 146, -112, false, "Skip dialogue when opening gossip.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page1"], "AutoAcceptSummon", "Accept summon", 146, -132, false, "Accept summon automatically out of combat.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page1"], "AutoAcceptRes", "Accept resurrection", 146, -152, false, "Accept resurrection automatically.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page1"], "AutoReleasePvP", "Release in PvP", 146, -172, false, "Release spirit automatically in battlegrounds.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page1"], "AutoSpiritRes", "Auto Spirit Res Confirm", 146, -192, false, "Resurrect automatically at spirit healer.")
    LeaPlusLC:MakeTx(LeaPlusLC["Page1"], "Vendors", 340, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page1"], "AutoSellJunk", "Sell junk automatically", 340, -92, false, "Sell grey items automatically.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page1"], "AutoRepairGear", "Repair automatically", 340, -112, false, "Repair gear automatically.")

    -- Page 2 (Social)
    LeaPlusLC:MakeTx(LeaPlusLC["Page2"], "Blocks", 146, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page2"], "NoDuelRequests", "Block duels", 146, -92, false, "Block duels from strangers.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page2"], "NoPartyInvites", "Block party invites", 146, -112, false, "Block party invites from strangers.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page2"], "NoGuildInvites", "Block guild invites", 146, -132, false, "Block guild invites.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page2"], "NoSharedQuests", "Block shared quests", 146, -152, false, "Decline shared quests from strangers.")
    LeaPlusLC:MakeTx(LeaPlusLC["Page2"], "Groups", 340, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page2"], "AcceptPartyFriends", "Party from friends", 340, -92, false, "Accept party invites from friends.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page2"], "InviteFromWhisper", "Invite from whispers", 340, -112, false, "Invite when someone whispers the keyword.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page2"], "FriendlyGuild", "Guild members are friends", 146, -282, false, "Treat guild members as friends.")

    -- Page 3 (Chat)
    LeaPlusLC:MakeTx(LeaPlusLC["Page3"], "Chat Frame", 146, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "UseEasyChatResizing", "Use easy resizing", 146, -92, true, "Drag tab to resize chat.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "NoCombatLogTab", "Hide the combat log", 146, -112, true, "Hide docked combat log tab.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "NoChatButtons", "Hide chat buttons", 146, -132, true, "Hide side chat buttons.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "UnclampChat", "Unclamp chat frame", 146, -152, true, "Move chat frame to screen edges.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "MoveChatEditBoxToTop", "Move editbox to top", 146, -172, true, "Move editbox above chat.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "MoreFontSizes", "More font sizes", 146, -192, true, "Allow extra chat font sizes.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "AltClickInv", "Alt click for Party Invite", 146, -212, true, "Alt-click player names to invite.")
    LeaPlusLC:MakeTx(LeaPlusLC["Page3"], "Mechanics", 340, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "NoStickyChat", "Disable sticky chat", 340, -92, true, "Disable sticky chat channels.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "UseArrowKeysInChat", "Use arrow keys in chat", 340, -112, true, "Navigate chat with arrow keys.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "NoChatFade", "Disable chat fade", 340, -132, true, "Stop chat text from fading.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "UnivGroupColor", "Universal group color", 340, -152, false, "Color raid chat blue.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "ClassColorsInChat", "Use class colors in chat", 340, -172, true, "Class color names in chat.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "RecentChatWindow", "Recent chat window", 340, -192, true, "Ctrl-click chat tab to view recent chat.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "RestoreChatMessages", "Restore chat messages", 340, -252, true, "Restore recent chat on reload.")

    -- Page 4 (Text)
    LeaPlusLC:MakeTx(LeaPlusLC["Page4"], "Visibility", 146, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page4"], "HideErrorMessages", "Hide error messages", 146, -92, false, "Hide red error text.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page4"], "NoHitIndicators", "Hide portrait numbers", 146, -112, true, "Hide combat text on portraits.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page4"], "HideZoneText", "Hide zone text", 146, -132, true, "Hide zone change banner text.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page4"], "HideKeybindText", "Hide keybind text", 146, -152, true, "Hide action button hotkey text.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page4"], "HideMacroText", "Hide macro text", 146, -172, true, "Hide action button macro text.")

    -- Page 5 (Interface)
    LeaPlusLC:MakeTx(LeaPlusLC["Page5"], "Enhancements", 146, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page5"], "MinimapModder", "Enhance minimap", 146, -92, true, "Customize and shape minimap.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page5"], "SquareMinimap", "Square minimap", 146, -112, true, "Set minimap to square shape.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page5"], "ShowWhoPinged", "Show who pinged", 146, -132, false, "Show name of player pinging map.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page5"], "EnhanceQuestLog", "Enhance quest log", 146, -152, true, "Expand quest log with levels.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page5"], "EnhanceProfessions", "Enhance professions", 146, -172, true, "Expand professions frame.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page5"], "EnhanceTrainers", "Enhance trainers", 146, -192, true, "Expand trainers frame with Train All.")
    LeaPlusLC:MakeTx(LeaPlusLC["Page5"], "Extras", 340, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page5"], "ShowVolume", "Show volume slider", 340, -92, true, "Volume control in character sheet.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page5"], "AhExtras", "Show auction controls", 340, -112, true, "Enhance auction house interface.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page5"], "DurabilityStatus", "Show durability status", 340, -132, true, "Show durability on character frame.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page5"], "ShowVanityControls", "Toggle helm / cloak", 340, -152, true, "Quick toggles for helm and cloak.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page5"], "ShowBagSearchBox", "Show bag search box", 340, -172, true, "Search box in container frame.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page5"], "ShowFlightTimes", "Show flight times", 340, -192, true, "Flight duration progress bar.")

    -- Page 6 (Frames)
    LeaPlusLC:MakeTx(LeaPlusLC["Page6"], "Frames", 146, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page6"], "FrmEnabled", "Manage frames", 146, -92, true, "Move and scale player and target frames.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page6"], "ManageBuffs", "Manage buffs", 146, -112, true, "Move and scale buffs frame.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page6"], "ManageDeBuffs", "Manage debuffs", 146, -132, true, "Move and scale debuffs frame.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page6"], "ManageVehicle", "Manage vehicle", 146, -152, true, "Move and scale vehicle seat indicator.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page6"], "ClassColFrames", "Class colored frames", 146, -172, true, "Color unit frames by class.")
    LeaPlusLC:MakeTx(LeaPlusLC["Page6"], "Visibility", 340, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page6"], "NoAlerts", "Hide alerts", 340, -92, true, "Hide achievement alert popups.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page6"], "NoGryphons", "Hide gryphons", 340, -112, true, "Hide action bar gryphons.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page6"], "NoClassBar", "Hide stance bar", 340, -132, true, "Hide shapeshift/stance bar.")

    -- Page 7 (System)
    LeaPlusLC:MakeTx(LeaPlusLC["Page7"], "Graphics and Sound", 146, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page7"], "NoScreenGlow", "Disable screen glow", 146, -92, false, "Disable fullscreen glow effects.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page7"], "NoScreenEffects", "Disable screen effects", 146, -112, false, "Disable death and nether effects.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page7"], "SetWeatherDensity", "Set weather density", 146, -132, false, "Adjust weather effect density.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page7"], "MaxCameraZoom", "Max camera zoom", 146, -152, false, "Extend camera distance factor.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page7"], "ViewPortEnable", "Enable viewport", 146, -172, true, "Adjustable letterbox screen borders.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page7"], "NoRestedEmotes", "Silence rested emotes", 146, -192, true, "Silence emote sounds while resting.")
    LeaPlusLC:MakeTx(LeaPlusLC["Page7"], "Game Options", 340, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page7"], "FasterLooting", "Faster auto loot", 340, -92, true, "Instant auto-looting.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page7"], "FasterMovieSkip", "Faster movie skip", 340, -112, true, "Skip cinematics without confirmation.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page7"], "CombatPlates", "Combat plates", 340, -132, true, "Show nameplates only during combat.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page7"], "EasyItemDestroy", "Easy item destroy", 340, -152, true, "Delete items without typing DELETE.")

    -- Page 8 (Settings)
    LeaPlusLC:MakeTx(LeaPlusLC["Page8"], "Addon", 146, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page8"], "ShowMinimapIcon", "Show minimap button", 146, -92, false, "Display minimap launcher button.")
    LeaPlusLC:MakeTx(LeaPlusLC["Page8"], "Scale", 340, -72)
    LeaPlusLC:MakeSL(LeaPlusLC["Page8"], "PlusPanelScale", "Panel scale", 1, 2, 0.1, 340, -92, "%.1f")

    -- Attach configuration gear buttons
    LeaPlusLC:CfgBtn("AutomateQuestsBtn", LeaPlusCB["AutomateQuests"])
    LeaPlusLC:CfgBtn("AutoAcceptResBtn", LeaPlusCB["AutoAcceptRes"])
    LeaPlusLC:CfgBtn("AutoReleasePvPBtn", LeaPlusCB["AutoReleasePvP"])
    LeaPlusLC:CfgBtn("AutoSellJunkBtn", LeaPlusCB["AutoSellJunk"])
    LeaPlusLC:CfgBtn("AutoRepairBtn", LeaPlusCB["AutoRepairGear"])
    LeaPlusLC:CfgBtn("InvWhisperBtn", LeaPlusCB["InviteFromWhisper"])
end

----------------------------------------------------------------------
-- Slash Commands & Minimap Launcher
----------------------------------------------------------------------
SLASH_Leatrix_Plus1 = "/ltp"
SlashCmdList["Leatrix_Plus"] = function(msg)
    msg = strtrim(msg or ""):lower()
    if msg == "reset" then
        LeaPlusLC["PageF"]:ClearAllPoints()
        LeaPlusLC["PageF"]:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        LeaPlusLC:Print("Panel position reset.")
    elseif msg == "wipe" then
        wipe(LeaPlusDB)
        ReloadUI()
    else
        if LeaPlusLC:IsPlusShowing() then
            LeaPlusLC:HideFrames()
            LeaPlusLC:HideConfigPanels()
        else
            LeaPlusLC:HideFrames()
            LeaPlusLC["PageF"]:Show()
            local startPage = LeaPlusLC["LeaStartPage"] or 0
            if LeaPlusLC["Page" .. startPage] then
                LeaPlusLC["Page" .. startPage]:Show()
            end
        end
    end
end

SLASH_LEATRIX_PLUS_RL1 = "/rl"
SlashCmdList["LEATRIX_PLUS_RL"] = function() ReloadUI() end

----------------------------------------------------------------------
-- Core Event Broker
----------------------------------------------------------------------
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:RegisterEvent("PLAYER_LOGIN")
EventFrame:RegisterEvent("PLAYER_LOGOUT")

EventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Leatrix_Plus" then
        LoadSettings()
        CreateMainPanel()
        LeaPlusLC:SetDim()

        for _, mod in pairs(Leatrix_Plus.Modules) do
            if mod.OnEnable then mod:OnEnable() end
        end

    elseif event == "PLAYER_LOGIN" then
        for _, mod in pairs(Leatrix_Plus.Modules) do
            if mod.OnLogin then mod:OnLogin() end
        end
        collectgarbage()

    elseif event == "PLAYER_LOGOUT" then
        SaveSettings()
        for _, mod in pairs(Leatrix_Plus.Modules) do
            if mod.OnLogout then mod:OnLogout(false) end
        end
    end
end)