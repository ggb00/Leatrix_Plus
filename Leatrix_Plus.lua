-- Leatrix_Plus.lua
local LibCompat = LibStub:GetLibrary("LibCompat-1.0")
local void, Leatrix_Plus = ...
local L = Leatrix_Plus.L

_G.LeaPlusDB = _G.LeaPlusDB or {}
local LeaPlusDB = _G.LeaPlusDB

if not LibCompat.After then
    local timerFrame = CreateFrame("Frame")
    timerFrame:Hide()
    local timers = {}
    timerFrame:SetScript("OnUpdate", function(self, dt)
        for i = #timers, 1, -1 do
            local t = timers[i]
            t.elapsed = t.elapsed + dt
            if t.elapsed >= t.delay then
                local func = t.func
                table.remove(timers, i)
                local ok, err = pcall(func)
                if not ok and err then
                    geterrorhandler()(err)
                end
            end
        end
        if #timers == 0 then
            self:Hide()
        end
    end)
    LibCompat.After = function(delay, func)
        table.insert(timers, {delay = delay, elapsed = 0, func = func})
        timerFrame:Show()
    end
end

-- Core registries
local LeaPlusLC, LeaPlusCB, LeaConfigList, LeaLockList = {}, {}, {}, {}
LeaPlusLC["AddonVer"] = "1.0"
LeaPlusLC["NumberOfPages"] = 9

Leatrix_Plus.LC = LeaPlusLC
Leatrix_Plus.CB = LeaPlusCB
Leatrix_Plus.ConfigList = LeaConfigList
Leatrix_Plus.LockList = LeaLockList
Leatrix_Plus.Modules = {}
Leatrix_Plus.ModuleOrder = {}
Leatrix_Plus.DB = LeaPlusDB

function Leatrix_Plus:RegisterModule(name, mod)
    self.Modules[name] = mod
    tinsert(self.ModuleOrder, mod)
end

_G.BINDING_HEADER_LEATRIX_PLUS = "Leatrix Plus"
_G.BINDING_NAME_LEATRIX_PLUS_GLOBAL_TOGGLE = L["Toggle panel"]

-- UI tooling
function LeaPlusLC:Print(text)
    DEFAULT_CHAT_FRAME:AddMessage(L[text] or text, 1.0, 0.85, 0.0)
end

function LeaPlusLC:LockItem(item, lock)
    if not item then return end
    item.locked = lock
    if lock then
        item:SetAlpha(0.3)
    else
        item:SetAlpha(1.0)
    end
end

function LeaPlusLC:CreateBar(name, parent, width, height, anchor, r, g, b, alp, tex)
    local ft = parent:CreateTexture(nil, "BORDER")
    ft:SetTexture(tex)
    ft:SetSize(width, height)
    ft:SetPoint(anchor)
    ft:SetVertexColor(r, g, b, alp)
    if name == "MainTexture" then
        ft:SetTexCoord(0.09, 1, 0, 1)
    end
    parent.__leaBars = parent.__leaBars or {}
    parent.__leaBars[name] = ft
    return ft
end

function LeaPlusLC:ApplyPanelAlpha(panel)
    if not panel then return end
    local opacity = 1 - (LeaPlusLC["PlusPanelAlpha"] or 0)
    if panel.t then panel.t:SetAlpha(opacity) end
    if panel.__leaBars then
        for _, bar in pairs(panel.__leaBars) do
            bar:SetAlpha(opacity)
        end
    end
end

function LeaPlusLC:HideConfigPanels()
    for _, v in pairs(LeaConfigList) do
        v:Hide()
    end
end

function LeaPlusLC:HideFrames()
    for i = 0, LeaPlusLC["NumberOfPages"] do
        local page = LeaPlusLC["Page" .. i]
        if page then page:Hide() end
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

local GUILD_CACHE_TTL = 5
local guildMemberCache = { members = {}, time = 0 }

local function GetCachedGuildMembers()
    local now = GetTime()
    if guildMemberCache.time > 0 and (now - guildMemberCache.time) < GUILD_CACHE_TTL then
        return guildMemberCache.members
    end
    wipe(guildMemberCache.members)
    if IsInGuild() then
        local num = GetNumGuildMembers()
        if num == 0 and GuildRoster then
            GuildRoster()
        else
            for i = 1, num do
                local gName, _, _, _, _, _, _, _, gOnline = GetGuildRosterInfo(i)
                if gName and gOnline then
                    local nameOnly = strsplit("-", gName)
                    guildMemberCache.members[strlower(nameOnly)] = true
                end
            end
        end
    end
    guildMemberCache.time = now
    return guildMemberCache.members
end

function LeaPlusLC:FriendCheck(name)
    if not name then return false end
    local nameOnly = strsplit("-", name)
    name = strlower(nameOnly)

    for i = 1, GetNumFriends() do
        local friendName, _, _, _, connected = GetFriendInfo(i)
        if friendName and connected then
            local friendNameOnly = strsplit("-", friendName)
            if strlower(friendNameOnly) == name then
                return true
            end
        end
    end

    if LeaPlusLC["FriendlyGuild"] == "On" and IsInGuild() then
        local members = GetCachedGuildMembers()
        if members[name] then
            return true
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
        eFrame:SetScript("OnMouseDown", function(_, btn)
            if btn == "RightButton" then eFrame:Hide() end
        end)
    end

    LeaPlusLC.FactoryEditBox:Show()
    LeaPlusLC.FactoryEditBox.b:SetText(word)
    LeaPlusLC.FactoryEditBox.b:HighlightText()
    LeaPlusLC.FactoryEditBox.b:SetFocus(true)
end

local SUB_OPTION_CHECKS = {
    AutomateQuests = { "AutoQuestAvailable", "AutoQuestCompleted" },
    FilterChatMessages = { "BlockSpellLinks", "BlockDrunkenSpam", "BlockDuelSpam" },
    ClassColFrames = { "ClassColPlayer", "ClassColTarget" },
    EnhanceQuestLog = { "EnhanceQLShowLevel", "EnhanceQLDifficulty", "EnhanceQLHeaders", "EnhanceQLListDifficulty" },
}

local function AreAllSubOptionsDisabled(parentField)
    local subs = SUB_OPTION_CHECKS[parentField]
    if not subs then return false end
    for i = 1, #subs do
        if LeaPlusLC[subs[i]] == "On" then
            return false
        end
    end
    return true
end

function LeaPlusLC:TipSee()
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    local parent = self:GetParent() or self
    local pRight = parent.GetRight and parent:GetRight()
    local uRight = UIParent and UIParent:GetRight()

    if pRight and uRight and parent.GetEffectiveScale and UIParent.GetEffectiveScale and GameTooltip.GetEffectiveScale then
        local pscale = parent:GetEffectiveScale() or 1
        local gscale = UIParent:GetEffectiveScale() or 1
        local tscale = GameTooltip:GetEffectiveScale() or 1
        local gap = ((uRight * gscale) - (pRight * pscale))
        if gap < (250 * tscale) then
            GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
        else
            GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
        end
    else
        GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
    end

    local tip = self.tiptext or ""
    if self.field and LeaPlusLC[self.field] == "On" and AreAllSubOptionsDisabled(self.field) then
        tip = tip .. "|n|n|cffffcc00Warning: All sub-settings for this option are currently disabled.|r"
    end
    GameTooltip:SetText(tip, nil, nil, nil, nil, true)
end

function LeaPlusLC:ShowTooltip()
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    local parent = self:GetParent() or LeaPlusLC["PageF"] or UIParent
    local pRight = parent.GetRight and parent:GetRight()
    local uRight = UIParent and UIParent:GetRight()

    if pRight and uRight and parent.GetEffectiveScale and UIParent.GetEffectiveScale and GameTooltip.GetEffectiveScale then
        local pscale = parent:GetEffectiveScale() or 1
        local gscale = UIParent:GetEffectiveScale() or 1
        local tscale = GameTooltip:GetEffectiveScale() or 1
        local gap = ((uRight * gscale) - (pRight * pscale))
        if gap < (250 * tscale) then
            GameTooltip:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)
        else
            GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
        end
    else
        GameTooltip:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
    end
    GameTooltip:SetText(self.tiptext or "", nil, nil, nil, nil, true)
end

function LeaPlusLC:CfgBtn(name, parent)
    if not parent then return end
    local page = parent:GetParent()
    local btn = CreateFrame("Button", nil, page)
    LeaPlusCB[name] = btn
    btn:SetWidth(20)
    btn:SetHeight(20)
    btn:SetPoint("LEFT", parent.f, "RIGHT", 2, 0)
    btn:SetFrameLevel(parent:GetFrameLevel() + 2)

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

    parent:HookScript("OnShow", function() btn:Show() end)
    parent:HookScript("OnHide", function() btn:Hide() end)
end

function LeaPlusLC:CreatePanel(title, globref)
    local Side = CreateFrame("Frame", "LeaPlusGlobalPanel_" .. globref, UIParent)
    tinsert(UISpecialFrames, "LeaPlusGlobalPanel_" .. globref)
    tinsert(LeaConfigList, Side)

    Side:Hide()
    Side:SetSize(570, 370)
    Side:SetClampedToScreen(true)
    Side:SetPoint(
        LeaPlusLC["MainPanelA"] or "CENTER",
        UIParent,
        LeaPlusLC["MainPanelR"] or "CENTER",
        LeaPlusLC["MainPanelX"] or 0,
        LeaPlusLC["MainPanelY"] or 0
    )
    Side:SetScale(LeaPlusLC["PlusPanelScale"] or 1)
    Side:SetFrameStrata("FULLSCREEN_DIALOG")

    Side.t = Side:CreateTexture(nil, "BACKGROUND")
    Side.t:SetAllPoints()
    Side.t:SetTexture(0.05, 0.05, 0.05, 0.9)

    local texPath = "Interface\\AddOns\\Leatrix_Plus\\Assets\\ui-guildachievement-parchment-horizontal-desaturated.blp"
    LeaPlusLC:CreateBar("FootTexture", Side, 570, 48, "BOTTOM", 0.5, 0.5, 0.5, 1.0, texPath)
    LeaPlusLC:CreateBar("MainTexture", Side, 570, 323, "TOPRIGHT", 0.7, 0.7, 0.7, 0.9, texPath)

    Side.c = CreateFrame("Button", nil, Side, "UIPanelCloseButton")
    Side.c:SetSize(30, 30)
    Side.c:SetPoint("TOPRIGHT", 0, 0)
    Side.c:SetScript("OnClick", function() Side:Hide() end)

    Side.r = LeaPlusLC:CreateButton(globref .. "ResetButton", Side, "Reset", "TOPLEFT", 16, -292, 0, 25, true, "Click to reset the settings on this page.")
    Side.h = LeaPlusLC:CreateButton(globref .. "HelpButton", Side, "Help", "TOPLEFT", 76, -292, 0, 25, true, "No help is available for this page.")
    Side.h:ClearAllPoints()
    Side.h:SetPoint("LEFT", Side.r, "RIGHT", 10, 0)
    Side.b = LeaPlusLC:CreateButton(globref .. "BackButton", Side, "Back to Main Menu", "TOPRIGHT", -16, -292, 130, 25, true, "Click to return to the main menu.")
    Side.b:SetScript("OnClick", function()
        Side:Hide()
        if LeaPlusLC["PageF"] then LeaPlusLC["PageF"]:Show() end
    end)

    Side.f = Side:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    Side.f:SetPoint("TOPLEFT", 16, -16)
    Side.f:SetText(L[title] or title)

    Side.v = Side:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    Side.v:SetHeight(32)
    Side.v:SetPoint("TOPLEFT", Side.f, "BOTTOMLEFT", 0, -8)
    Side.v:SetPoint("RIGHT", Side, -32, 0)
    Side.v:SetJustifyH("LEFT")
    Side.v:SetJustifyV("TOP")
    Side.v:SetText(L["Configuration Panel"])

    Side:EnableMouse(true)
    Side:SetMovable(true)
    Side:RegisterForDrag("LeftButton")
    Side:SetScript("OnDragStart", function(self) self:StartMoving() end)
    Side:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local a, _, r, x, y = self:GetPoint()
        LeaPlusLC["MainPanelA"], LeaPlusLC["MainPanelR"], LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"] = a, r, x, y
        self:ClearAllPoints()
        self:SetPoint(a, UIParent, r, x, y)
        if LeaPlusLC["PageF"] then
            LeaPlusLC["PageF"]:ClearAllPoints()
            LeaPlusLC["PageF"]:SetPoint(a, UIParent, r, x, y)
        end
        for _, panel in pairs(LeaConfigList) do
            if panel ~= self then
                panel:ClearAllPoints()
                panel:SetPoint(a, UIParent, r, x, y)
            end
        end
    end)

    Side:HookScript("OnShow", function(self)
        self:ClearAllPoints()
        self:SetPoint(
            LeaPlusLC["MainPanelA"] or "CENTER",
            UIParent,
            LeaPlusLC["MainPanelR"] or "CENTER",
            LeaPlusLC["MainPanelX"] or 0,
            LeaPlusLC["MainPanelY"] or 0
        )
        self:SetScale(LeaPlusLC["PlusPanelScale"] or 1)
        LeaPlusLC:ApplyPanelAlpha(self)
    end)
    LeaPlusLC:ApplyPanelAlpha(Side)

    return Side
end

function LeaPlusLC:MakeTx(frame, title, x, y)
    local text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("TOPLEFT", x, y)
    text:SetText(L[title] or title)
    return text
end

function LeaPlusLC:MakeWD(frame, title, x, y)
    local text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("TOPLEFT", x, y)
    text:SetText(L[title] or title)
    text:SetJustifyH("LEFT")
    return text
end

function LeaPlusLC:MakeFT(frame, text, left, width)
    local footer = LeaPlusLC:MakeTx(frame, text, left, 96)
    footer:SetWidth(width)
    footer:SetJustifyH("LEFT")
    footer:SetWordWrap(true)
    footer:ClearAllPoints()
    footer:SetPoint("BOTTOMLEFT", left, 96)
end

function LeaPlusLC:MakeCB(parent, field, caption, x, y, reload, tip, extratip)
    local Cbox = CreateFrame("CheckButton", nil, parent, "ChatConfigCheckButtonTemplate")
    LeaPlusCB[field] = Cbox
    Cbox:SetPoint("TOPLEFT", x, y)
    Cbox:SetScript("OnEnter", LeaPlusLC.TipSee)
    Cbox:SetScript("OnLeave", GameTooltip_Hide)

    Cbox.f = Cbox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    Cbox.f:SetPoint("LEFT", 23, 0)

    local tooltipText = L[tip] or tip or ""
    if extratip and extratip ~= "" then
        tooltipText = tooltipText .. "|n|n" .. (L[extratip] or extratip)
    end
    local reloadText = reload and ("|n|n* " .. (L["Requires UI reload."] or "Requires UI reload.")) or ""
    Cbox.tiptext = tooltipText .. reloadText

    if reload then
        Cbox.f:SetText((L[caption] or caption) .. "*")
    else
        Cbox.f:SetText(L[caption] or caption)
    end

    Cbox.f:SetJustifyH("LEFT")
    Cbox.f:SetWordWrap(false)

    local maxWidth = (parent:GetParent() == LeaPlusLC["PageF"]) and 152 or 302
    if Cbox.f:GetWidth() > maxWidth then
        Cbox.f:SetWidth(maxWidth)
    end
    if Cbox.f:GetStringWidth() > maxWidth then
        Cbox:SetHitRectInsets(0, -(maxWidth - 10), 0, 0)
    else
        Cbox:SetHitRectInsets(0, -Cbox.f:GetStringWidth() + 4, 0, 0)
    end

    Cbox:SetScript("OnShow", function(self)
        self:SetChecked(LeaPlusLC[field] == "On")
    end)
    Cbox.field = field
    local function UpdateLabel()
        local baseText = L[caption] or caption
        if reload then baseText = baseText .. "*" end
        if LeaPlusLC[field] == "On" and AreAllSubOptionsDisabled(field) then
            Cbox.f:SetText(baseText .. " |cffffcc00(!)|r")
        else
            Cbox.f:SetText(baseText)
        end
    end

    Cbox:HookScript("OnShow", function(self)
        UpdateLabel()
    end)

    Cbox:SetScript("OnClick", function(self)
        if self.locked then
            self:SetChecked(LeaPlusLC[field] == "On")
            return
        end
        local newState = self:GetChecked() and "On" or "Off"
        LeaPlusLC[field] = newState
        LeaPlusLC:SetDim()
        LeaPlusLC:ReloadCheck()
        UpdateLabel()
    end)
end

function LeaPlusLC:MakeSL(frame, field, caption, low, high, step, x, y, form)
    local Slider = CreateFrame("Slider", "LeaPlusGlobalSlider" .. field, frame, "OptionsSliderTemplate")
    LeaPlusCB[field] = Slider
    Slider:SetMinMaxValues(low, high)
    Slider:SetValueStep(step)
    Slider:EnableMouseWheel(true)
    Slider:SetPoint("TOPLEFT", x, y)
    Slider:SetWidth(100)
    Slider:SetHeight(20)
    Slider:SetHitRectInsets(0, 0, 0, 0)
    Slider.tiptext = L[caption] or caption
    Slider:SetScript("OnEnter", LeaPlusLC.TipSee)
    Slider:SetScript("OnLeave", GameTooltip_Hide)

    if _G[Slider:GetName() .. "Text"] then _G[Slider:GetName() .. "Text"]:SetText("") end
    _G[Slider:GetName() .. "Low"]:SetText("")
    _G[Slider:GetName() .. "High"]:SetText("")

    Slider.f = Slider:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
    Slider.f:SetPoint("LEFT", Slider, "RIGHT", 12, 0)

    Slider:SetScript("OnMouseWheel", function(self, arg1)
        if self.locked or not self:IsEnabled() then return end
        local delta = step * arg1
        local value = self:GetValue()
        if delta > 0 then
            self:SetValue(min(value + delta, high))
        else
            self:SetValue(max(value + delta, low))
        end
    end)

    Slider:SetScript("OnValueChanged", function(self, value)
        if self.locked then return end
        local val = floor((value - low) / step + 0.5) * step + low
        Slider.f:SetFormattedText(form, val)
        LeaPlusLC[field] = tonumber(string.format(form, val)) or val
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
        edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
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
    mbtn:SetText(L[label] or label)
    mbtn.tiptext = L[tip] or tip
    mbtn:SetScript("OnEnter", LeaPlusLC.TipSee)
    mbtn:SetScript("OnLeave", GameTooltip_Hide)

    local origSetScript = mbtn.SetScript
    mbtn.SetScript = function(self, scriptType, handler)
        if scriptType == "OnClick" then
            origSetScript(self, "OnClick", function(btnSelf, ...)
                if btnSelf.locked then return end
                if handler then handler(btnSelf, ...) end
            end)
        else
            origSetScript(self, scriptType, handler)
        end
    end
    return mbtn
end

local LeaDropList = {}

function LeaPlusLC:CreateDropDown(ddname, label, parent, width, anchor, x, y, items, tip)
    tinsert(LeaDropList, ddname)
    LeaPlusLC[ddname .. "Table"] = items

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetWidth(width)
    frame:SetHeight(42)
    frame:SetPoint("BOTTOMLEFT", parent, anchor, x, y)

    local lf = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lf:SetPoint("TOPLEFT", frame, 0, 0)
    lf:SetText(L[label] or label)

    local dbtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    LeaPlusCB[ddname .. "Button"] = dbtn
    dbtn:SetSize(width, 22)
    dbtn:SetPoint("BOTTOMLEFT", 0, 0)
    dbtn.tiptext = tip
    dbtn:SetScript("OnEnter", LeaPlusLC.TipSee)
    dbtn:SetScript("OnLeave", GameTooltip_Hide)

    local ddlist = CreateFrame("Frame", nil, frame)
    LeaPlusCB["ListFrame" .. ddname] = ddlist
    ddlist:SetPoint("TOPLEFT", dbtn, "BOTTOMLEFT", 0, -2)
    ddlist:SetWidth(width)
    ddlist:SetFrameStrata("TOOLTIP")
    ddlist:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    ddlist:Hide()

    parent:HookScript("OnHide", function() ddlist:Hide() end)

    local function RefreshButtonText()
        local idx = LeaPlusLC[ddname] or 1
        local tbl = LeaPlusLC[ddname .. "Table"] or items
        dbtn:SetText(tbl[idx] or tostring(idx))
    end

    frame.itemButtons = {}
    frame.RefreshList = function(newItems)
        newItems = newItems or items
        LeaPlusLC[ddname .. "Table"] = newItems
        items = newItems
        ddlist:SetHeight((#items * 18) + 10)

        for i = 1, #items do
            local itemBtn = frame.itemButtons[i]
            if not itemBtn then
                itemBtn = CreateFrame("Button", nil, ddlist)
                frame.itemButtons[i] = itemBtn
                itemBtn:SetHeight(18)
                itemBtn:SetPoint("TOPLEFT", 6, -((i - 1) * 18 + 5))
                itemBtn:SetPoint("TOPRIGHT", -6, -((i - 1) * 18 + 5))

                itemBtn.t = itemBtn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
                itemBtn.t:SetPoint("LEFT", 4, 0)
                itemBtn.t:SetJustifyH("LEFT")

                local hTex = itemBtn:CreateTexture(nil, "BACKGROUND")
                hTex:SetAllPoints()
                hTex:SetTexture(1, 0.82, 0, 0.25)
                itemBtn:SetHighlightTexture(hTex)
            end

            itemBtn.t:SetText(items[i])
            itemBtn:Show()
            itemBtn:SetScript("OnClick", function()
                LeaPlusLC[ddname] = i
                RefreshButtonText()
                ddlist:Hide()
                if frame.OnSelect then frame.OnSelect(i, items[i]) end
            end)
        end

        for i = #items + 1, #frame.itemButtons do
            frame.itemButtons[i]:Hide()
        end

        RefreshButtonText()
    end

    dbtn:SetScript("OnClick", function()
        if ddlist:IsShown() then
            ddlist:Hide()
        else
            for _, name in ipairs(LeaDropList) do
                if LeaPlusCB["ListFrame" .. name] and LeaPlusCB["ListFrame" .. name] ~= ddlist then
                    LeaPlusCB["ListFrame" .. name]:Hide()
                end
            end
            frame.RefreshList(LeaPlusLC[ddname .. "Table"] or items)
            ddlist:Show()
        end
    end)

    frame:SetScript("OnShow", RefreshButtonText)
    frame.RefreshList(items)

    return frame
end

function LeaPlusLC:LockOption(option, item, reloadreq)
    if not LeaPlusCB[item] then return end
    LeaPlusLC:LockItem(LeaPlusCB[item], LeaPlusLC[option] == "Off")
end

local SETDIM_PAIRS = {
    {"AutomateQuests", "AutomateQuestsBtn"},
    {"AutoAcceptSummon", "AutoAcceptSummonBtn"},
    {"AutoAcceptRes", "AutoAcceptResBtn"},
    {"AutoReleasePvP", "AutoReleasePvPBtn"},
    {"ShowWhoPinged", "ShowWhoPingedBtn"},
    {"AutoSellJunk", "AutoSellJunkBtn"},
    {"AutoRepairGear", "AutoRepairBtn"},
    {"InviteFromWhisper", "InvWhisperBtn"},
    {"FilterChatMessages", "FilterChatMessagesBtn"},
    {"MinimapModder", "ModMinimapBtn"},
    {"TipModEnable", "MoveTooltipButton"},
    {"EnhanceQuestLog", "EnhanceQuestLogBtn"},
    {"EnhanceTrainers", "EnhanceTrainersBtn"},
    {"FrmEnabled", "MoveFramesButton"},
    {"ManageBuffs", "ManageBuffsButton"},
    {"ManageDeBuffs", "ManageDeBuffsButton"},
    {"ManageVehicle", "ManageVehicleButton"},
    {"ManageWidget", "ManageWidgetButton"},
    {"ManageFocus", "ManageFocusButton"},
    {"ManageTimer", "ManageTimerButton"},
    {"ManageTracker", "ManageTrackerButton"},
    {"ManageDurability", "ManageDurabilityButton"},
    {"ClassColFrames", "ClassColFramesBtn"},
    {"ShowPlayerChain", "ShowPlayerChainBtn"},
    {"ViewPortEnable", "ModViewportBtn"},
    {"SetWeatherDensity", "SetWeatherDensityBtn"},
}

local setDimFiltered = nil

function LeaPlusLC:InvalidateSetDimCache()
    setDimFiltered = nil
end

function LeaPlusLC:SetDim()
    if not setDimFiltered then
        setDimFiltered = {}
        for _, pair in ipairs(SETDIM_PAIRS) do
            local btn = LeaPlusCB[pair[2]]
            if btn then
                setDimFiltered[#setDimFiltered + 1] = { option = pair[1], btn = btn }
            end
        end
    end

    for _, entry in ipairs(setDimFiltered) do
        LeaPlusLC:LockItem(entry.btn, LeaPlusLC[entry.option] == "Off")
    end

    -- Explicit Incompatibility: Improved Unit Frames vs Class Colored Frames
    local classColBtn = LeaPlusCB["ClassColFramesBtn"]
    local classColBox = LeaPlusCB["ClassColFrames"]

    if LeaPlusLC["EnhanceUnitFrames"] == "On" then
        -- Lock checkbox and configuration gear button
        LeaPlusLC:LockItem(classColBox, true)
        LeaPlusLC:LockItem(classColBtn, true)

        if classColBox then
            classColBox.tiptext = L["Colors unit frame nameplate backgrounds according to character class."]
                .. "|n|n|cffff2222Disabled: Incompatible with 'Improved Unit Frames'.|r"
        end
        if classColBtn then
            classColBtn.tiptext = L["Disabled: Incompatible with 'Improved Unit Frames'."]
        end
    else
        -- Restore access
        LeaPlusLC:LockItem(classColBox, false)
        if classColBox then
            classColBox.tiptext = L["Colors unit frame nameplate backgrounds according to character class."]
        end
        if classColBtn then
            classColBtn.tiptext = L["Click to configure the settings for this option."]
            LeaPlusLC:LockItem(classColBtn, LeaPlusLC["ClassColFrames"] == "Off")
        end
    end
end

local RELOAD_CHECK_KEYS = {
    "UseEasyChatResizing", "NoCombatLogTab", "NoChatButtons", "UnclampChat",
    "MoveChatEditBoxToTop", "MoreFontSizes", "AltClickInv", "NoStickyChat",
    "UseArrowKeysInChat", "NoChatFade", "ClassColorsInChat",
    "RecentChatWindow", "MaxChatHstory", "FilterChatMessages", "RestoreChatMessages",
    "NoHitIndicators", "HideZoneText", "HideKeybindText", "HideMacroText",
    "MinimapModder",
    "HideMiniZoomBtns", "HideMiniZoneText", "HideMiniMapButton", "HideMiniTracking",
    "HideMiniCalendar",
    "TipModEnable", "TipNoHealthBar",
    "EnhanceQuestLog", "EnhanceProfessions", "EnhanceTrainers",
    "DurabilityStatus", "ShowVanityControls", "EnhanceDressup",
    "FrmEnabled", "EnhanceUnitFrames", "ManageBuffs", "ManageDeBuffs", "ManageVehicle",
    "ManageWidget", "ManageFocus", "ManageTimer", "ManageTracker", "ManageDurability",
    "ClassColFrames",
    "NoAlerts", "NoGryphons", "NoClassBar",
    "NoScreenGlow", "NoScreenEffects", "SetWeatherDensity", "MaxCameraZoom",
    "ViewPortEnable", "NoRestedEmotes",
    "NoBagAutomation", "FasterLooting",
}

local lastReloadState = nil
local initialSettings = {}

function LeaPlusLC:ReloadCheck()
    local needsReload = false
    for i = 1, #RELOAD_CHECK_KEYS do
        local k = RELOAD_CHECK_KEYS[i]
        if LeaPlusLC[k] ~= initialSettings[k] then
            needsReload = true
            break
        end
    end

    if needsReload == lastReloadState then return end
    lastReloadState = needsReload

    if LeaPlusCB["ReloadUIButton"] then
        LeaPlusLC:LockItem(LeaPlusCB["ReloadUIButton"], not needsReload)
        if needsReload then
            LeaPlusCB["ReloadUIButton"].f:Show()
        else
            LeaPlusCB["ReloadUIButton"].f:Hide()
        end
    end
end

local dbDefaults = {
    -- Automation
    AutomateQuests = "Off", AutoQuestShift = "Off", AutoQuestAvailable = "On",
    AutoQuestCompleted = "On", AutoQuestKeyMenu = 1, AutomateGossip = "Off",
    AutoAcceptSummon = "Off", AutoAcceptSummonDelay = 10, AutoAcceptRes = "Off", AutoResNoCombat = "On",
    AutoReleasePvP = "Off", AutoReleaseNoAlterac = "Off", AutoReleaseShiftCancel = "On",
    AutoReleaseDelay = 200,
    AutoSellJunk = "Off", AutoSellShowSummary = "On", AutoSellExcludeList = "",
    AutoRepairGear = "Off", AutoRepairGuildFunds = "On", AutoRepairShowSummary = "On",

    -- Social
    NoDuelRequests = "Off", NoPartyInvites = "Off", NoGuildInvites = "Off",
    NoSharedQuests = "Off", AcceptPartyFriends = "Off", InviteFromWhisper = "Off",
    InviteFriendsOnly = "Off", InvKey = "inv", InvMaxRaidSize = 25, FriendlyGuild = "On",

    -- Chat
    UseEasyChatResizing = "Off", NoCombatLogTab = "Off", NoChatButtons = "Off",
    UnclampChat = "Off", MoveChatEditBoxToTop = "Off", MoreFontSizes = "Off",
    AltClickInv = "Off", NoStickyChat = "Off", UseArrowKeysInChat = "Off",
    NoChatFade = "Off", UnivGroupColor = "Off", ClassColorsInChat = "Off",
    RecentChatWindow = "Off", RecentChatSize = 170, MaxChatHstory = "Off",
    FilterChatMessages = "Off", RestoreChatMessages = "Off",
    BlockSpellLinks = "Off", BlockDrunkenSpam = "Off", BlockDuelSpam = "Off",

    -- Text
    HideErrorMessages = "Off", NoHitIndicators = "Off", HideZoneText = "Off",
    HideKeybindText = "Off", HideMacroText = "Off",

    -- Interface / Minimap
    MinimapModder = "Off", ShowWhoPinged = "On",
    HideMiniZoomBtns = "Off", HideMiniZoneText = "Off", HideMiniMapButton = "On",
    HideMiniTracking = "Off", HideMiniCalendar = "Off", ClockMouseover = "Off",
    HideMiniPOIArrows = "Off",
    MinimapA = "TOPRIGHT", MinimapR = "TOPRIGHT", MinimapX = 0, MinimapY = 0,
    MinimapPositionCaptured = false,
    MinimapScale = 1, MiniClusterScale = 1,
    ShowWhoPingedMode = 1, ShowWhoPingedTruncate = 6,

    -- Tooltip
    TipModEnable = "Off", TipShowRank = "On", TipShowOtherRank = "Off",
    TipShowTarget = "On", TipHideInCombat = "Off", TipHideShiftOverride = "On",
    TipNoHealthBar = "Off", LeaPlusTipSize = 1.00,
    TooltipAnchorMenu = 1, TipOffsetX = -13, TipOffsetY = 94,
    TipCursorX = 0, TipCursorY = 0,

    -- Interface / Extras
    DurabilityStatus = "Off", ShowVanityControls = "Off", VanityAltLayout = "Off",
    EnhanceDressup = "Off", HideDressupStats = "Off",

    -- Frames
    FrmEnabled = "Off", EnhanceUnitFrames = "Off", ManageBuffs = "Off", ManageDeBuffs = "Off",
    ManageVehicle = "Off", ManageWidget = "Off", ManageFocus = "Off",
    ManageTimer = "Off", ManageDurability = "Off", ManageTracker = "Off",
    ClassColFrames = "Off", ClassColPlayer = "On", ClassColTarget = "On",
    ShowPlayerChain = "Off", PlayerChainMenu = 2,
    NoAlerts = "Off", NoGryphons = "Off", NoClassBar = "Off",
    PlayerTargetScale = 1,

    -- Frame coords
    BuffFrameA = "TOPRIGHT", BuffFrameR = "TOPRIGHT", BuffFrameX = -205, BuffFrameY = -13, BuffFrameScale = 1,
    DebuffButton1A = "TOPRIGHT", DebuffButton1R = "TOPRIGHT", DebuffButton1X = -205, DebuffButton1Y = -205, DebuffButton1Scale = 1,
    VehicleA = "TOPRIGHT", VehicleR = "TOPRIGHT", VehicleX = -100, VehicleY = -192, VehicleScale = 1,
    WidgetA = "TOP", WidgetR = "TOP", WidgetX = 0, WidgetY = -15, WidgetScale = 1,
    FocusA = "CENTER", FocusR = "CENTER", FocusX = 0, FocusY = 0, FocusScale = 1,
    TimerA = "TOP", TimerR = "TOP", TimerX = -5, TimerY = -96, TimerScale = 1,
    DurabilityA = "TOPRIGHT", DurabilityR = "TOPRIGHT", DurabilityX = 0, DurabilityY = -170, DurabilityScale = 1,
    TrackerA = "TOPRIGHT", TrackerR = "TOPRIGHT", TrackerX = 0, TrackerY = -170, TrackerScale = 1,

    -- System
    NoScreenGlow = "Off", NoScreenEffects = "Off", SetWeatherDensity = "Off",
    WeatherLevel = 3, MaxCameraZoom = "Off", ViewPortEnable = "Off",
    ViewPortTop = 0, ViewPortBottom = 0, ViewPortLeft = 0, ViewPortRight = 0,
    ViewPortAlpha = 0, NoRestedEmotes = "Off",
    NoBagAutomation = "Off", NoConfirmLoot = "Off",
    FasterLooting = "Off",
    EnhanceTrainers = "Off", EnhanceProfessions = "Off", EnhanceQuestLog = "Off",
    EnhanceQLShowLevel = "On", EnhanceQLDifficulty = "On",
    EnhanceQLHeaders = "On", EnhanceQLListDifficulty = "Off",
    ShowTrainAllBtn = "On",

    -- Settings
    ShowMinimapIcon = "On", PlusPanelScale = 1, PlusPanelAlpha = 0,
    MainPanelA = "CENTER", MainPanelR = "CENTER", MainPanelX = 0, MainPanelY = 0,
    LeaStartPage = 0,
    FirstRunMessageSeen = false,
}

local function GetCharacterKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    if not name or name == "" or name == "Unknown" then
        return "Default"
    end
    return name .. " - " .. (realm or "Unknown")
end

local function CopyTable(src, dest)
    dest = dest or {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            dest[k] = CopyTable(v)
        else
            dest[k] = v
        end
    end
    return dest
end

local function MigrateOldDatabase()
    if not LeaPlusDB["Profiles"] then
        local oldSettings = {}
        for k, v in pairs(LeaPlusDB) do
            if k ~= "ProfileKeys" and k ~= "Profiles" and k ~= "MinimapIcon" then
                oldSettings[k] = v
                LeaPlusDB[k] = nil
            end
        end

        LeaPlusDB["ProfileKeys"] = {}
        LeaPlusDB["Profiles"] = {}
        LeaPlusDB["Profiles"]["Default"] = CopyTable(oldSettings)
    end
end

local function GetActiveProfile()
    MigrateOldDatabase()
    local charKey = GetCharacterKey()
    local profileName = LeaPlusDB["ProfileKeys"][charKey] or "Default"

    if not LeaPlusDB["Profiles"][profileName] then
        LeaPlusDB["Profiles"][profileName] = CopyTable(LeaPlusDB["Profiles"]["Default"] or dbDefaults)
    end
    LeaPlusDB["ProfileKeys"][charKey] = profileName
    return profileName, LeaPlusDB["Profiles"][profileName]
end

local function LoadSettings()
    _G.LeaPlusDB = _G.LeaPlusDB or {}
    LeaPlusDB = _G.LeaPlusDB
    Leatrix_Plus.DB = LeaPlusDB

    local _, profileData = GetActiveProfile()

    for k, def in pairs(dbDefaults) do
        if profileData[k] == nil then
            profileData[k] = def
        end
        LeaPlusLC[k] = profileData[k]
        initialSettings[k] = profileData[k]
    end
end

local isProfileReload = false

local function SaveSettings()
    if isProfileReload then return end
    _G.LeaPlusDB = _G.LeaPlusDB or {}
    LeaPlusDB = _G.LeaPlusDB
    Leatrix_Plus.DB = LeaPlusDB

    local _, profileData = GetActiveProfile()
    for k in pairs(dbDefaults) do
        profileData[k] = LeaPlusLC[k]
    end
end

local function CreateMainPanel()
    local PageF = CreateFrame("Frame", "LeaPlusGlobalPanel", UIParent)
    LeaPlusLC["PageF"] = PageF
    PageF:SetSize(570, 370)
    PageF:Hide()
    PageF:SetFrameStrata("FULLSCREEN_DIALOG")
    PageF:SetClampedToScreen(true)
    PageF:EnableMouse(true)
    PageF:SetMovable(true)
    PageF:RegisterForDrag("LeftButton")
    PageF:SetScript("OnDragStart", function(self) self:StartMoving() end)
    PageF:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local a, _, r, x, y = self:GetPoint()
        LeaPlusLC["MainPanelA"], LeaPlusLC["MainPanelR"], LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"] = a, r, x, y
        self:ClearAllPoints()
        self:SetPoint(a, UIParent, r, x, y)
        for _, panel in pairs(LeaConfigList) do
            panel:ClearAllPoints()
            panel:SetPoint(a, UIParent, r, x, y)
        end
    end)
    PageF:HookScript("OnShow", function(self)
        self:ClearAllPoints()
        self:SetPoint(
            LeaPlusLC["MainPanelA"] or "CENTER",
            UIParent,
            LeaPlusLC["MainPanelR"] or "CENTER",
            LeaPlusLC["MainPanelX"] or 0,
            LeaPlusLC["MainPanelY"] or 0
        )
    end)
    PageF:SetPoint(
        LeaPlusLC["MainPanelA"] or "CENTER",
        UIParent,
        LeaPlusLC["MainPanelR"] or "CENTER",
        LeaPlusLC["MainPanelX"] or 0,
        LeaPlusLC["MainPanelY"] or 0
    )
    PageF:SetScale(LeaPlusLC["PlusPanelScale"] or 1)
    tinsert(UISpecialFrames, "LeaPlusGlobalPanel")

    PageF.t = PageF:CreateTexture(nil, "BACKGROUND")
    PageF.t:SetAllPoints()
    PageF.t:SetTexture(0.05, 0.05, 0.05, 0.9)

    local texPath = "Interface\\AddOns\\Leatrix_Plus\\Assets\\ui-guildachievement-parchment-horizontal-desaturated.blp"
    LeaPlusLC:CreateBar("FootTexture", PageF, 570, 42, "BOTTOM", 0.5, 0.5, 0.5, 1.0, texPath)
    LeaPlusLC:CreateBar("MainTexture", PageF, 440, 348, "TOPRIGHT", 0.7, 0.7, 0.7, 0.7, texPath)
    LeaPlusLC:CreateBar("MenuTexture", PageF, 130, 348, "TOPLEFT", 0.7, 0.7, 0.7, 0.7, texPath)

    PageF.mt = PageF:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    PageF.mt:SetPoint("TOPLEFT", 16, -16)
    PageF.mt:SetText("Leatrix Plus")

    PageF.v = PageF:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    PageF.v:SetPoint("TOPLEFT", PageF.mt, "BOTTOMLEFT", 0, -4)
    PageF.v:SetText("Version: " .. LeaPlusLC["AddonVer"])

    local CloseB = CreateFrame("Button", nil, PageF, "UIPanelCloseButton")
    CloseB:SetSize(30, 30)
    CloseB:SetPoint("TOPRIGHT", 0, 0)
    CloseB:SetScript("OnClick", LeaPlusLC.HideFrames)

    local reloadb = LeaPlusLC:CreateButton("ReloadUIButton", PageF, "Reload", "BOTTOMRIGHT", -16, 10, 0, 25, true, "Reload UI to apply pending changes.")
    reloadb:SetScript("OnClick", ReloadUI)
    reloadb.f = reloadb:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    reloadb.f:SetPoint("RIGHT", reloadb, "LEFT", -10, 0)
    reloadb.f:SetText(L["Your UI needs to be reloaded."])
    reloadb.f:Hide()
    LeaPlusLC:LockItem(reloadb, true)

    local function MakePage(name, title, idx, yOverride)
        local p = CreateFrame("Frame", nil, PageF)
        LeaPlusLC[name] = p
        p:SetAllPoints(PageF)
        p:Hide()
        p.s = p:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        p.s:SetPoint("TOPLEFT", 146, -16)
        p.s:SetText(L[title])

        local nav = CreateFrame("Button", nil, PageF)
        nav:SetSize(112, 20)
        nav:SetPoint("TOPLEFT", 16, yOverride or (-72 + -(idx * 20)))
        nav.f = nav:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        nav.f:SetPoint("LEFT", 8, 0)
        nav.f:SetText(L[title])

        nav.s = nav:CreateTexture(nil, "BACKGROUND")
        nav.s:SetAllPoints()
        nav.s:SetTexture("Interface\\Buttons\\WHITE8X8")
        nav.s:SetVertexColor(1.0, 0.5, 0.0, 0.8)
        nav.s:Hide()

        p:SetScript("OnShow", function() nav.s:Show() end)
        p:SetScript("OnHide", function() nav.s:Hide() end)

        nav:SetScript("OnClick", function()
            LeaPlusLC:HideFrames()
            PageF:Show()
            p:Show()
            LeaPlusLC["LeaStartPage"] = idx
        end)

        LeaPlusLC["LeaPlusNav" .. idx] = nav
        return p
    end

    MakePage("Page0", "Home", 0)
    MakePage("Page1", "Automation", 1)
    MakePage("Page2", "Social", 2)
    MakePage("Page3", "Chat", 3)
    MakePage("Page4", "Text", 4)
    MakePage("Page5", "Interface", 5)
    MakePage("Page6", "Frames", 6)
    MakePage("Page7", "System", 7)
    MakePage("Page8", "Settings", 8, -248)
    MakePage("Page9", "Profiles", 9, -268)

    LeaPlusLC:MakeTx(LeaPlusLC["Page0"], "Welcome to Leatrix Plus for Wrath of the Lich King.", 146, -72)
    LeaPlusLC:MakeWD(LeaPlusLC["Page0"], "To begin, choose an options page.", 146, -92)

    -- Automation
    LeaPlusLC:MakeTx(LeaPlusLC["Page1"], "Character", 146, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page1"], "AutomateQuests", "Automate Quests", 146, -92, false, "Automatically accept offered quests and turn in completed quests when speaking to NPCs.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page1"], "AutomateGossip", "Automate Gossip", 146, -112, false, "Automatically select dialogue when an NPC has only one gossip option and no active or available quests (such as flight masters or vendors).")
    LeaPlusLC:MakeCB(LeaPlusLC["Page1"], "AutoAcceptSummon", "Auto Accept Summons", 146, -132, false, "Automatically accept summons while outside of combat.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page1"], "AutoAcceptRes", "Auto Accept Resurrection", 146, -152, false, "Automatically accept resurrections.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page1"], "AutoReleasePvP", "Auto Release Spirit in BGs", 146, -172, false, "Automatically release spirit upon death inside Battlegrounds. You will not release if a Soulstone or Reincarnation is available.")
    LeaPlusLC:MakeTx(LeaPlusLC["Page1"], "Vendors", 340, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page1"], "AutoSellJunk", "Auto Sell Junk", 340, -92, false, "Automatically sell all gray quality items when visiting a vendor NPC.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page1"], "AutoRepairGear", "Auto Repair Gear", 340, -112, false, "Automatically repair all equipped and inventory gear when visiting a repair NPC.")

    -- Social
    LeaPlusLC:MakeTx(LeaPlusLC["Page2"], "Blocks", 146, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page2"], "NoDuelRequests", "Block Duel Requests", 146, -92, false, "Automatically decline duel requests from players who are not on your friends list.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page2"], "NoPartyInvites", "Block Party Invites", 146, -112, false, "Automatically decline group invites from players who are not on your friends list.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page2"], "NoGuildInvites", "Block Guild Invites", 146, -132, false, "Automatically decline guild invites from players who are not on your friends list.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page2"], "NoSharedQuests", "Block Shared Quests", 146, -152, false, "Automatically decline quest shares from players who are not on your friends list.")
    LeaPlusLC:MakeTx(LeaPlusLC["Page2"], "Groups", 340, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page2"], "AcceptPartyFriends", "Party Invites from Friends Only", 340, -92, false, "Automatically block party invites from strangers while automatically accepting invites from friends.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page2"], "InviteFromWhisper", "Invite from Whispers", 340, -112, false, "Automatically invite players to your group when they whisper you a specific keyword.")

    LeaPlusLC:MakeFT(LeaPlusLC["Page2"], "For all of the social options above, you can treat guild members as friends too.", 146, 380)
    LeaPlusLC:MakeCB(LeaPlusLC["Page2"], "FriendlyGuild", "Guild Members as Friends", 146, -282, false, "Treat guild members as friends for all social blocks and auto-invite options above.")

    if LeaPlusCB["FriendlyGuild"].f:GetStringWidth() > 180 then
        LeaPlusCB["FriendlyGuild"].f:SetWidth(180)
        LeaPlusCB["FriendlyGuild"]:SetHitRectInsets(0, -170, 0, 0)
    end

    -- Chat
    LeaPlusLC:MakeTx(LeaPlusLC["Page3"], "Chat Frame", 146, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "UseEasyChatResizing", "Resize Chat from Tab", 146, -92, true, "Allows dragging General chat tab upwards to resize the chat frame directly without unlocking it.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "NoCombatLogTab", "Hide Combat Log Tab", 146, -112, true, "Hide Combat Log chat tab.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "NoChatButtons", "Hide Chat Buttons", 146, -132, true, "Hide chat frame side buttons and enable mouse wheel scrolling controls (regular = 1 line, Shift = page, Ctrl = top/bottom).")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "UnclampChat", "Unclamp Chat Frame", 146, -152, true, "Allows chat frames to be moved directly against the screen edges.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "MoveChatEditBoxToTop", "Move Editbox to Top", 146, -172, true, "Positions the chat input editbox directly above the chat window instead of below it.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "MoreFontSizes", "More Font Sizes", 146, -192, true, "Adds 10pt, 20pt, 22pt, 24pt, and 26pt text size choices to the chat tab menu.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "AltClickInv", "Alt-Click to Invite", 146, -212, true, "Invite players to your group by holding Alt and Left-Clicking their name in chat.")
    LeaPlusLC:MakeTx(LeaPlusLC["Page3"], "Mechanics", 340, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "NoStickyChat", "Disable Sticky Chat", 340, -92, true, "Prevents chat channels (such as whispers and raid) from remaining active across messages.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "UseArrowKeysInChat", "Use Arrow Keys in Editbox", 340, -112, true, "Allows browsing sent message history with Up and Down arrow keys.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "NoChatFade", "Disable Chat Fade", 340, -132, true, "Keeps chat messages visible indefinitely instead of letting older lines fade out.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "UnivGroupColor", "Universal Group Color", 340, -152, false, "Changes Raid and Raid Leader chat text colors to blue shades matching Party chat.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "ClassColorsInChat", "Class Colors in Chat", 340, -172, true, "Colors character names by class across all standard chat windows and custom channels.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "RecentChatWindow", "Recent Chat Window", 340, -192, true, "Opens a resizable copy-paste window containing recent chat history by holding Ctrl and Left-Clicking any chat tab.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "FilterChatMessages", "Filter Chat Messages", 340, -212, true, "Filters repetitive spam such as combat spell links, drunken emotes, and duel announcements.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "MaxChatHstory", "Increase Chat History", 340, -232, true, "Expands chat scrollback buffer from the default line limit up to 4096 lines.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page3"], "RestoreChatMessages", "Restore Chat on Reload", 340, -252, true, "Preserves and re-displays recent chat messages from the past hour across UI reloads and relogs.")

    -- Text
    LeaPlusLC:MakeTx(LeaPlusLC["Page4"], "Visibility", 146, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page4"], "HideErrorMessages", "Hide Error Messages", 146, -92, false, "Hide red floating combat error messages (such as 'Not enough rage' or 'Ability not ready'). Important warnings (such as inventory full or disarmed) remain visible.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page4"], "NoHitIndicators", "Hide Portrait Numbers", 146, -112, true, "Hide floating damage and healing numbers over the player and pet portraits.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page4"], "HideZoneText", "Hide Zone Text", 146, -132, true, "Hide floating zone, subzone, and auto-subzone title banners when entering new areas.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page4"], "HideKeybindText", "Hide Keybind Text", 146, -152, true, "Hide keybind hotkey labels on action bars, stance bars, and vehicle action buttons.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page4"], "HideMacroText", "Hide Macro Text", 146, -172, true, "Hide macro names on action buttons across all action bars.")

    -- Interface
    LeaPlusLC:MakeTx(LeaPlusLC["Page5"], "Enhancements", 146, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page5"], "MinimapModder", "Enhance Minimap", 146, -92, true, "Unlocks minimap movement (Alt + Left-Drag), enables mouse wheel zooming, and allows customizing various minimap elements.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page5"], "TipModEnable", "Enhance Tooltips", 146, -112, true, "Colors unit tooltips by class and reaction, displays targets, flags tapped mobs, and allows custom positioning and scaling.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page5"], "EnhanceDressup", "Enhance Dressup", 146, -132, true, "Adds controls (Undress, Player, Target) to the Dressup Room, and provides a toggle button to expand the character sheet model view.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page5"], "EnhanceQuestLog", "Enhance Quest Log", 146, -152, true, "Displays quest levels and difficulty tags in the quest details and quest list, and adds a Collapse/Expand all headers button.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page5"], "EnhanceProfessions", "Enhance Professions", 146, -172, true, "Expands the professions window into a wider layout with more skill lines, and side-by-side recipes.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page5"], "EnhanceTrainers", "Enhance Trainers", 146, -192, true, "Expands the class trainer window into a wider layout with side-by-side skill details and an optional Train All button.")

    LeaPlusLC:MakeTx(LeaPlusLC["Page5"], "Extras", 340, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page5"], "DurabilityStatus", "Show Durability Status", 340, -92, true, "Adds a clickable button to the character pane showing equipment durability percentages, and prints overall durability upon death.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page5"], "ShowVanityControls", "Toggle Helm and Cloak", 340, -112, true, "Adds 'Helm' and 'Cloak' display checkboxes directly to the character pane.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page5"], "ShowPlayerChain", "Show Player Chain", 340, -132, false, "Displays a rare, elite, or rare elite dragon chain around the player portrait frame.")

    -- Frames
    LeaPlusLC:MakeTx(LeaPlusLC["Page6"], "Frames", 146, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page6"], "FrmEnabled", "Manage Unit Frames", 146, -92, true, "Allows moving and scaling the Player and Target frames with grid snapping.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page6"], "EnhanceUnitFrames", "Improved Unit Frames", 146, -112, true, "Enlarges player, target, and focus health bars with high-definition textures, custom status text, and class coloring.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page6"], "ManageBuffs", "Manage Buffs", 146, -132, true, "Allows moving and scaling the player buffs and consolidated buffs frame.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page6"], "ManageDeBuffs", "Manage Debuffs", 146, -152, true, "Allows moving and scaling the player debuffs frame.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page6"], "ManageVehicle", "Manage Vehicle Indicator", 146, -172, true, "Allows moving and scaling the vehicle seat indicator frame.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page6"], "ManageWidget", "Manage Battleground Objectives", 146, -192, true, "Allows moving and scaling the top battleground score and objective widget.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page6"], "ManageFocus", "Manage Focus Frame", 146, -212, true, "Allows moving and scaling the focus frame.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page6"], "ManageTimer", "Manage Mirror Timer", 146, -232, true, "Allows moving and scaling the breath, fatigue, and feign death timer bar.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page6"], "ManageDurability", "Manage Durability Doll", 146, -252, true, "Allows moving and scaling the default armor durability mannequin doll.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page6"], "ManageTracker", "Manage Quest Tracker", 146, -272, true, "Allows moving and scaling the objective quest watch frame.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page6"], "ClassColFrames", "Class Colored Unit Frames", 146, -292, true, "Colors unit frame nameplate backgrounds according to character class.")

    if LeaPlusCB["EnhanceUnitFrames"] then
        LeaPlusCB["EnhanceUnitFrames"]:HookScript("OnClick", function(self)
            if self:GetChecked() and LeaPlusLC["ClassColFrames"] == "On" then
                LeaPlusLC["ClassColFrames"] = "Off"
                if LeaPlusCB["ClassColFrames"] then
                    LeaPlusCB["ClassColFrames"]:SetChecked(false)
                end
                LeaPlusLC:Print("|cffff8800Class Colored Unit Frames disabled (incompatible with Improved Unit Frames).|r")
            end
            LeaPlusLC:SetDim()
        end)
    end

    if LeaPlusCB["ClassColFrames"] then
        LeaPlusCB["ClassColFrames"]:HookScript("OnClick", function(self)
            if LeaPlusLC["EnhanceUnitFrames"] == "On" then
                self:SetChecked(false)
                LeaPlusLC["ClassColFrames"] = "Off"
                LeaPlusLC:Print("|cffff2222Cannot enable Class Colored Frames while Improved Unit Frames is active.|r")
            end
        end)
    end

    LeaPlusLC:MakeTx(LeaPlusLC["Page6"], "Visibility", 340, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page6"], "NoAlerts", "Hide Achievement and Dungeon Alerts", 340, -92, true, "Hide achievements popups and dungeon completion alert banners.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page6"], "NoGryphons", "Hide Action Bar Gryphons", 340, -112, true, "Hide the decorative lion and gryphon endcaps on the main action bar.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page6"], "NoClassBar", "Hide Stance Bar", 340, -132, true, "Hide the stance, presence, aura, and shapeshift bar above the main action bar.")

    -- System
    LeaPlusLC:MakeTx(LeaPlusLC["Page7"], "Graphics and Sound", 146, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page7"], "NoScreenGlow", "Disable Full-Screen Glow", 146, -92, true, "Turns off full-screen bloom and glow effects to improve visibility and performance.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page7"], "NoScreenEffects", "Disable Death Screen Effects", 146, -112, true, "Turns off the black-and-white blur effect while dead and the netherworld visibility glow.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page7"], "SetWeatherDensity", "Set Weather Density", 146, -132, true, "Adjusts the particle density of weather effects.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page7"], "MaxCameraZoom", "Max Camera Zoom Distance", 146, -152, true, "Extends the maximum camera distance to the client maximum.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page7"], "ViewPortEnable", "Enable Viewport Letterbox", 146, -172, true, "Adds adjustable top and bottom black borders to letterbox the 3D rendered world without moving interface frames.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page7"], "NoRestedEmotes", "Silence Resting Emote Sounds", 146, -192, true, "Silences emote sounds while resting inside an inn or city, restoring sound settings upon leaving or logging out.")

    -- Game Options
    LeaPlusLC:MakeTx(LeaPlusLC["Page7"], "Game Options", 340, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page7"], "NoBagAutomation", "Disable Automatic Bag Opening", 340, -92, true, "Keeps bags closed when interacting with merchants, banks, or mailboxes. May conflict with addons that change inventory and/or bags.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page7"], "NoConfirmLoot", "Disable Loot Warnings", 340, -112, false, "Automatically confirms BoP loot roll warnings, corpse loot confirmations, disenchant prompts, and trade-timer merchant sales.")
    LeaPlusLC:MakeCB(LeaPlusLC["Page7"], "FasterLooting", "Faster Auto Loot", 340, -132, true, "Loots items from corpses and containers immediately without the standard auto-loot window delay.")

    -- Settings
    LeaPlusLC:MakeTx(LeaPlusLC["Page8"], "Addon", 146, -72)
    LeaPlusLC:MakeCB(LeaPlusLC["Page8"], "ShowMinimapIcon", "Show Minimap Button", 146, -92, false, "Displays the Leatrix Plus launcher button on the minimap.")

    if LeaPlusCB["ShowMinimapIcon"] then
        LeaPlusCB["ShowMinimapIcon"]:HookScript("OnClick", function(self)
            local iconLib = LibStub("LibDBIcon-1.0", true)
            if not iconLib then return end
            if self:GetChecked() then
                iconLib:Show("Leatrix_Plus")
            else
                iconLib:Hide("Leatrix_Plus")
            end
        end)
    end

    LeaPlusLC:MakeTx(LeaPlusLC["Page8"], "Scale", 340, -72)
    LeaPlusLC:MakeSL(LeaPlusLC["Page8"], "PlusPanelScale", "Sets the scale of the Leatrix Plus options panel and all configuration subpanels.", 1, 2, 0.1, 340, -92, "%.1f")

    -- Page 9: Profiles
    LeaPlusLC:MakeTx(LeaPlusLC["Page9"], "Profile Management", 146, -72)

    local function GetProfileList()
        local list = {}
        if LeaPlusDB["Profiles"] then
            for name in pairs(LeaPlusDB["Profiles"]) do
                list[#list + 1] = name
            end
        end
        table.sort(list)
        if #list == 0 then list[1] = "Default" end
        return list
    end

    local function GetDeletableProfileList(activeName)
        local list = {}
        if LeaPlusDB["Profiles"] then
            for name in pairs(LeaPlusDB["Profiles"]) do
                if name ~= activeName and name ~= "Default" then
                    list[#list + 1] = name
                end
            end
        end
        table.sort(list)
        if #list == 0 then list[1] = "None" end
        return list
    end

    local charKey = GetCharacterKey()
    local profileList = GetProfileList()

    local function GetProfileIndex(tbl, name)
        for i, pName in ipairs(tbl) do
            if pName == name then return i end
        end
        return 1
    end

    local curProf = LeaPlusDB["ProfileKeys"] and LeaPlusDB["ProfileKeys"][charKey] or "Default"
    LeaPlusLC["ActiveProfileDropdown"] = GetProfileIndex(profileList, curProf)
    LeaPlusLC["CopyProfileDropdown"] = 1
    LeaPlusLC["DeleteProfileDropdown"] = 1

    -- 1) Active Profile Dropdown
    local profileDrop = LeaPlusLC:CreateDropDown("ActiveProfileDropdown", "Active Profile", LeaPlusLC["Page9"], 180, "TOPLEFT", 146, -145,
        profileList, "Choose the active configuration profile for this character. Selecting a new profile will reload your UI.")

    profileDrop.OnSelect = function(idx, pName)
        local cKey = GetCharacterKey()
        curProf = LeaPlusDB["ProfileKeys"] and LeaPlusDB["ProfileKeys"][cKey] or "Default"
        if pName and pName ~= curProf and LeaPlusDB["Profiles"][pName] then
            SaveSettings()
            LeaPlusDB["ProfileKeys"][cKey] = pName
            isProfileReload = true
            ReloadUI()
        end
    end

    -- 2) Reset Current Profile Button
    local resetProfileBtn = LeaPlusLC:CreateButton("ResetCurrentProfileBtn", LeaPlusLC["Page9"], "Reset Profile", "TOPLEFT", 340, -125, 110, 22, false, "Reset all settings in your currently active profile to factory defaults.")
    resetProfileBtn:SetScript("OnClick", function()
        if InCombatLockdown() then
            LeaPlusLC:Print("You cannot do that in combat.")
            return
        end
        if not StaticPopupDialogs["LEATRIX_PLUS_RESET_PROFILE"] then
            StaticPopupDialogs["LEATRIX_PLUS_RESET_PROFILE"] = {
                text = "Are you sure you want to reset the active profile to factory defaults? This will reload your UI.",
                button1 = YES,
                button2 = NO,
                OnAccept = function()
                    if InCombatLockdown() then return end
                    local cKey = GetCharacterKey()
                    local activeName = (LeaPlusDB["ProfileKeys"] and LeaPlusDB["ProfileKeys"][cKey]) or "Default"
                    LeaPlusDB["Profiles"][activeName] = CopyTable(dbDefaults)
                    isProfileReload = true
                    ReloadUI()
                end,
                timeout = 0,
                whileDead = 1,
                hideOnEscape = 1,
                showAlert = 1,
                preferredIndex = 3,
            }
        end
        StaticPopup_Show("LEATRIX_PLUS_RESET_PROFILE")
    end)

    -- 3) Create New Profile (EditBox + Add Button)
    LeaPlusLC:MakeTx(LeaPlusLC["Page9"], "New Profile", 146, -165)
    local newProfBox = LeaPlusLC:CreateEditBox("NewProfileBox", LeaPlusLC["Page9"], 180, 24, "TOPLEFT", 146, -185, nil, nil, 32)
    newProfBox:SetAutoFocus(false)

    local createBtn = LeaPlusLC:CreateButton("CreateProfileBtn", LeaPlusLC["Page9"], "Create", "TOPLEFT", 340, -185, 80, 24, false, "Create a new profile with the entered name and switch to it.")
    createBtn:SetScript("OnClick", function()
        local name = strtrim(newProfBox:GetText() or "")
        if name == "" then
            LeaPlusLC:Print("Please enter a profile name.")
            return
        end
        if LeaPlusDB["Profiles"][name] then
            LeaPlusLC:Print("A profile with that name already exists.")
            return
        end
        SaveSettings()
        LeaPlusDB["Profiles"][name] = CopyTable(dbDefaults)
        LeaPlusDB["ProfileKeys"][charKey] = name
        newProfBox:SetText("")
        isProfileReload = true
        ReloadUI()
    end)

    -- 4) Copy Settings From Another Profile
    local copyDrop = LeaPlusLC:CreateDropDown("CopyProfileDropdown", "Copy Settings From", LeaPlusLC["Page9"], 180, "TOPLEFT", 146, -260,
        profileList, "Copy all settings from another profile into your currently active profile.")

    local copyBtn = LeaPlusLC:CreateButton("CopyProfileBtn", LeaPlusLC["Page9"], "Copy Profile", "TOPLEFT", 340, -240, 110, 22, false, "Copy all settings from the selected profile into your active profile.")
    copyBtn:SetScript("OnClick", function()
        local list = GetProfileList()
        local selectedSource = list[LeaPlusLC["CopyProfileDropdown"] or 1]
        local currentActive = LeaPlusDB["ProfileKeys"][charKey] or "Default"
        if not selectedSource or selectedSource == currentActive or not LeaPlusDB["Profiles"][selectedSource] then
            LeaPlusLC:Print("Cannot copy from the active profile or an invalid profile.")
            return
        end
        LeaPlusDB["Profiles"][currentActive] = CopyTable(LeaPlusDB["Profiles"][selectedSource])
        isProfileReload = true
        ReloadUI()
    end)

    -- 5) Delete Profile
    local deleteList = GetDeletableProfileList(curProf)
    local deleteDrop = LeaPlusLC:CreateDropDown("DeleteProfileDropdown", "Delete Profile", LeaPlusLC["Page9"], 180, "TOPLEFT", 146, -320,
        deleteList, "Select an unused profile to delete. Active and Default profiles cannot be deleted.")

    local deleteBtn = LeaPlusLC:CreateButton("DeleteProfileBtn", LeaPlusLC["Page9"], "Delete", "TOPLEFT", 340, -300, 80, 22, false, "Permanently delete the selected profile.")
    deleteBtn:SetScript("OnClick", function()
        local cKey = GetCharacterKey()
        curProf = (LeaPlusDB["ProfileKeys"] and LeaPlusDB["ProfileKeys"][cKey]) or "Default"
        local list = GetDeletableProfileList(curProf)
        local target = list[LeaPlusLC["DeleteProfileDropdown"] or 1]
        if not target or target == "None" or target == curProf or target == "Default" or not LeaPlusDB["Profiles"][target] then
            LeaPlusLC:Print("No deletable profile selected.")
            return
        end

        LeaPlusLC.ProfileToDelete = target

        if not StaticPopupDialogs["LEATRIX_PLUS_DELETE_PROFILE"] then
            StaticPopupDialogs["LEATRIX_PLUS_DELETE_PROFILE"] = {
                text = "Are you sure you want to permanently delete the profile '%s'?",
                button1 = YES,
                button2 = NO,
                OnAccept = function()
                    local toDelete = LeaPlusLC.ProfileToDelete
                    if not toDelete or toDelete == "Default" or not LeaPlusDB["Profiles"][toDelete] then return end
                    LeaPlusDB["Profiles"][toDelete] = nil
                    for charK, pName in pairs(LeaPlusDB["ProfileKeys"]) do
                        if pName == toDelete then
                            LeaPlusDB["ProfileKeys"][charK] = "Default"
                        end
                    end
                    LeaPlusLC:Print(string.format("Profile '%s' deleted.", toDelete))
                    local pList = GetProfileList()
                    local dList = GetDeletableProfileList(curProf)
                    LeaPlusLC["ActiveProfileDropdown"] = GetProfileIndex(pList, curProf)
                    LeaPlusLC["DeleteProfileDropdown"] = 1
                    profileDrop.RefreshList(pList)
                    copyDrop.RefreshList(pList)
                    deleteDrop.RefreshList(dList)
                    LeaPlusLC.ProfileToDelete = nil
                end,
                timeout = 0,
                whileDead = 1,
                hideOnEscape = 1,
                showAlert = 1,
                preferredIndex = 3,
            }
        end
        StaticPopupDialogs["LEATRIX_PLUS_DELETE_PROFILE"].text = string.format("Are you sure you want to permanently delete the profile '%s'?", target)
        StaticPopup_Show("LEATRIX_PLUS_DELETE_PROFILE")
    end)

    -- Refresh all dropdowns when Page 9 opens
    LeaPlusLC["Page9"]:HookScript("OnShow", function()
        curProf = LeaPlusDB["ProfileKeys"] and LeaPlusDB["ProfileKeys"][charKey] or "Default"
        profileList = GetProfileList()
        local dList = GetDeletableProfileList(curProf)

        LeaPlusLC["ActiveProfileDropdown"] = GetProfileIndex(profileList, curProf)
        LeaPlusLC["CopyProfileDropdown"] = 1
        LeaPlusLC["DeleteProfileDropdown"] = 1

        profileDrop.RefreshList(profileList)
        copyDrop.RefreshList(profileList)
        deleteDrop.RefreshList(dList)
    end)

    if LeaPlusCB["PlusPanelScale"] then
        local function ApplyPanelScale()
            local val = LeaPlusLC["PlusPanelScale"] or 1
            local a = LeaPlusLC["MainPanelA"] or "CENTER"
            local r = LeaPlusLC["MainPanelR"] or "CENTER"
            local x = LeaPlusLC["MainPanelX"] or 0
            local y = LeaPlusLC["MainPanelY"] or 0

            if LeaPlusLC["PageF"] then
                LeaPlusLC["PageF"]:ClearAllPoints()
                LeaPlusLC["PageF"]:SetPoint(a, UIParent, r, x, y)
                LeaPlusLC["PageF"]:SetScale(val)
            end
            for _, panel in pairs(LeaConfigList) do
                panel:ClearAllPoints()
                panel:SetPoint(a, UIParent, r, x, y)
                panel:SetScale(val)
            end
        end

        LeaPlusCB["PlusPanelScale"]:HookScript("OnMouseUp", ApplyPanelScale)
        LeaPlusCB["PlusPanelScale"]:HookScript("OnMouseWheel", ApplyPanelScale)
    end

    LeaPlusLC:MakeTx(LeaPlusLC["Page8"], "Transparency", 340, -132)
    LeaPlusLC:MakeSL(LeaPlusLC["Page8"], "PlusPanelAlpha", "Drag to set the transparency of the Leatrix Plus panel.", 0, 1, 0.1, 340, -152, "%.1f")

    if LeaPlusCB["PlusPanelAlpha"] then
        local function ApplyAllPanelsAlpha()
            if LeaPlusLC["PageF"] then
                LeaPlusLC:ApplyPanelAlpha(LeaPlusLC["PageF"])
            end
            for _, panel in pairs(LeaConfigList) do
                LeaPlusLC:ApplyPanelAlpha(panel)
            end
        end

        LeaPlusCB["PlusPanelAlpha"]:HookScript("OnValueChanged", ApplyAllPanelsAlpha)
        ApplyAllPanelsAlpha()
    end

    -- Config gear buttons
    LeaPlusLC:CfgBtn("AutomateQuestsBtn", LeaPlusCB["AutomateQuests"])
    LeaPlusLC:CfgBtn("AutoAcceptSummonBtn", LeaPlusCB["AutoAcceptSummon"])
    LeaPlusLC:CfgBtn("AutoAcceptResBtn", LeaPlusCB["AutoAcceptRes"])
    LeaPlusLC:CfgBtn("AutoReleasePvPBtn", LeaPlusCB["AutoReleasePvP"])
    LeaPlusLC:CfgBtn("AutoSellJunkBtn", LeaPlusCB["AutoSellJunk"])
    LeaPlusLC:CfgBtn("AutoRepairBtn", LeaPlusCB["AutoRepairGear"])

    LeaPlusLC:CfgBtn("InvWhisperBtn", LeaPlusCB["InviteFromWhisper"])

    LeaPlusLC:CfgBtn("FilterChatMessagesBtn", LeaPlusCB["FilterChatMessages"])

    LeaPlusLC:CfgBtn("ModMinimapBtn", LeaPlusCB["MinimapModder"])
    LeaPlusLC:CfgBtn("MoveTooltipButton", LeaPlusCB["TipModEnable"])
    LeaPlusLC:CfgBtn("EnhanceQuestLogBtn", LeaPlusCB["EnhanceQuestLog"])
    LeaPlusLC:CfgBtn("EnhanceTrainersBtn", LeaPlusCB["EnhanceTrainers"])

    LeaPlusLC:CfgBtn("MoveFramesButton", LeaPlusCB["FrmEnabled"])
    LeaPlusLC:CfgBtn("ManageBuffsButton", LeaPlusCB["ManageBuffs"])
    LeaPlusLC:CfgBtn("ManageDeBuffsButton", LeaPlusCB["ManageDeBuffs"])
    LeaPlusLC:CfgBtn("ManageVehicleButton", LeaPlusCB["ManageVehicle"])
    LeaPlusLC:CfgBtn("ManageWidgetButton", LeaPlusCB["ManageWidget"])
    LeaPlusLC:CfgBtn("ManageFocusButton", LeaPlusCB["ManageFocus"])
    LeaPlusLC:CfgBtn("ManageTimerButton", LeaPlusCB["ManageTimer"])
    LeaPlusLC:CfgBtn("ManageDurabilityButton", LeaPlusCB["ManageDurability"])
    LeaPlusLC:CfgBtn("ManageTrackerButton", LeaPlusCB["ManageTracker"])
    LeaPlusLC:CfgBtn("ClassColFramesBtn", LeaPlusCB["ClassColFrames"])
    LeaPlusLC:CfgBtn("ShowPlayerChainBtn", LeaPlusCB["ShowPlayerChain"])

    LeaPlusLC:CfgBtn("SetWeatherDensityBtn", LeaPlusCB["SetWeatherDensity"])
    LeaPlusLC:CfgBtn("ModViewportBtn", LeaPlusCB["ViewPortEnable"])

    -- Minimap launcher
    local ldb = LibStub("LibDataBroker-1.1", true)
    local icon = LibStub("LibDBIcon-1.0", true)
    if ldb and icon then
        LeaPlusDB["MinimapIcon"] = LeaPlusDB["MinimapIcon"] or { hide = (LeaPlusLC["ShowMinimapIcon"] == "Off") }

        local miniButton = ldb:NewDataObject("Leatrix_Plus", {
            type = "data source",
            text = "Leatrix Plus",
            icon = "Interface\\AddOns\\Leatrix_Plus\\Assets\\reportlagicon-movement",
            OnClick = function(_, btn)
                if btn == "LeftButton" then
                    SlashCmdList["Leatrix_Plus"]("")
                elseif btn == "RightButton" then
                    ReloadUI()
                end
            end,
            OnTooltipShow = function(tooltip)
                tooltip:AddLine("Leatrix Plus")
                tooltip:AddLine("|cffeda55fClick|r |cff99ff00to toggle options.|r")
                tooltip:AddLine("|cffeda55fRight-Click|r |cff99ff00to reload UI.|r")
            end,
        })

        icon:Register("Leatrix_Plus", miniButton, LeaPlusDB["MinimapIcon"])
        if LeaPlusLC["ShowMinimapIcon"] == "On" then
            icon:Show("Leatrix_Plus")
        else
            icon:Hide("Leatrix_Plus")
        end
    end
end

-- Slash commands
SLASH_Leatrix_Plus1 = "/ltp"
SLASH_Leatrix_Plus2 = "/lea"
SLASH_Leatrix_Plus3 = "/leatrix"
SlashCmdList["Leatrix_Plus"] = function(msg)
    RunScript('ACTIVE_CHAT_EDIT_BOX = ACTIVE_CHAT_EDIT_BOX')
    RunScript('LAST_ACTIVE_CHAT_EDIT_BOX = LAST_ACTIVE_CHAT_EDIT_BOX')
    msg = strtrim(msg or ""):lower()
    if msg == "reset" then
        LeaPlusLC["MainPanelA"], LeaPlusLC["MainPanelR"] = "CENTER", "CENTER"
        LeaPlusLC["MainPanelX"], LeaPlusLC["MainPanelY"] = 0, 0
        if LeaPlusLC["PageF"] then
            LeaPlusLC["PageF"]:ClearAllPoints()
            LeaPlusLC["PageF"]:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
        for _, panel in pairs(LeaConfigList) do
            panel:ClearAllPoints()
            panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
        LeaPlusLC:Print("Panel position reset.")
    elseif msg == "resetchat" then
        if ChatFrame1 then
            ChatFrame1:ClearAllPoints()
            ChatFrame1:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 32, 70)
            ChatFrame1:SetSize(430, 200)
            ChatFrame1:SetClampedToScreen(true)
            FCF_SavePositionAndDimensions(ChatFrame1)
            LeaPlusLC:Print("Chat frame 1 position reset.")
        end
    elseif msg == "wipe" then
        if InCombatLockdown() then
            LeaPlusLC:Print("You cannot do that in combat.")
            return
        end

        LeaPlusLC:HideFrames()
        LeaPlusLC:HideConfigPanels()

        if not StaticPopupDialogs["LEATRIX_PLUS_WIPE"] then
            StaticPopupDialogs["LEATRIX_PLUS_WIPE"] = {
                text = "Are you sure you want to reset your active profile to factory defaults? This will reload your UI.",
                button1 = YES,
                button2 = NO,
                OnAccept = function()
                    if InCombatLockdown() then return end
                    local charKey = GetCharacterKey()
                    local activeName = (LeaPlusDB["ProfileKeys"] and LeaPlusDB["ProfileKeys"][charKey]) or "Default"
                    LeaPlusDB["Profiles"] = LeaPlusDB["Profiles"] or {}
                    LeaPlusDB["Profiles"][activeName] = CopyTable(dbDefaults)
                    isProfileReload = true
                    ReloadUI()
                end,
                OnShow = function(self)
                    self:SetFrameStrata("TOOLTIP")
                    self:Raise()
                end,
                OnHide = function(self)
                    self:SetFrameStrata("DIALOG")
                end,
                timeout = 0,
                whileDead = 1,
                hideOnEscape = 1,
                showAlert = 1,
                preferredIndex = 3,
            }
        end
        local dialog = StaticPopup_Show("LEATRIX_PLUS_WIPE")
        if dialog then
            dialog:SetFrameStrata("TOOLTIP")
            dialog:Raise()
        end
    else
        if LeaPlusLC:IsPlusShowing() then
            LeaPlusLC:HideFrames()
            LeaPlusLC:HideConfigPanels()
        else
            LeaPlusLC:HideFrames()
            if LeaPlusLC["PageF"] then
                LeaPlusLC["PageF"]:Show()
                local startPage = LeaPlusLC["LeaStartPage"] or 0
                if LeaPlusLC["Page" .. startPage] then
                    LeaPlusLC["Page" .. startPage]:Show()
                end
            end
        end
    end
end

SLASH_LEATRIX_PLUS_RL1 = "/rl"
SlashCmdList["LEATRIX_PLUS_RL"] = function() ReloadUI() end

-- Event broker
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:RegisterEvent("PLAYER_LOGIN")
EventFrame:RegisterEvent("PLAYER_LOGOUT")

EventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Leatrix_Plus" then
        self:UnregisterEvent("ADDON_LOADED")
        LoadSettings()
        CreateMainPanel()
        LeaPlusLC:SetDim()

        for i = 1, #Leatrix_Plus.ModuleOrder do
            local mod = Leatrix_Plus.ModuleOrder[i]
            if mod.OnEnable then mod:OnEnable() end
        end

        LeaPlusLC:InvalidateSetDimCache()
        LeaPlusLC:SetDim()

    elseif event == "PLAYER_LOGIN" then
        if ShowFriends then ShowFriends() end
        for i = 1, #Leatrix_Plus.ModuleOrder do
            local mod = Leatrix_Plus.ModuleOrder[i]
            if mod.OnLogin then mod:OnLogin() end
        end
        collectgarbage()

    elseif event == "PLAYER_LOGOUT" then
        SaveSettings()
        for i = #Leatrix_Plus.ModuleOrder, 1, -1 do
            local mod = Leatrix_Plus.ModuleOrder[i]
            if mod.OnLogout then mod:OnLogout(false) end
        end
    end
end)