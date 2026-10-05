-- Chat.lua
local _, Leatrix_Plus = ...
local LeaPlusLC = Leatrix_Plus.LC
local LeaPlusCB = Leatrix_Plus.CB
local L = Leatrix_Plus.L

local Module = {}
Leatrix_Plus:RegisterModule("Chat", Module)

-- Native chat message ring buffer
local LeaChatBuffer = {}
for i = 1, NUM_CHAT_WINDOWS do
    LeaChatBuffer[i] = {}
end

local function HookChatFrameAddMessage(cf, idx)
    if not cf or cf.__leaHooked then return end
    cf.__leaHooked = true
    local origAddMessage = cf.AddMessage

    cf.AddMessage = function(self, text, r, g, b, id, ...)
        if text and not self.__leaRestoring then
            text = tostring(text)
            local buf = LeaChatBuffer[idx]
            if buf then
                local stored = text
                if r and g and b and (r < 0.99 or g < 0.99 or b < 0.99) then
                    local cr = math.max(0, math.min(255, math.floor(r * 255)))
                    local cg = math.max(0, math.min(255, math.floor(g * 255)))
                    local cb = math.max(0, math.min(255, math.floor(b * 255)))
                    local hex = string.format("|cff%02x%02x%02x", cr, cg, cb)
                    if text:find("|r", 1, true) then
                        stored = hex .. text:gsub("|r", "|r" .. hex) .. "|r"
                    else
                        stored = hex .. text .. "|r"
                    end
                end
                if #buf >= 128 then
                    table.remove(buf, 1)
                end
                buf[#buf + 1] = stored
            end
        end
        return origAddMessage(self, text, r, g, b, id, ...)
    end
end

-- Recent chat window
local function SetupRecentChatWindow()
    if LeaPlusLC["RecentChatWindow"] ~= "On" then return end

    local frame = CreateFrame("Frame", "LeaPlusRecentChatFrame", UIParent)
    frame:Hide()
    frame:SetSize(600, LeaPlusLC["RecentChatSize"] or 170)
    frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 130)
    frame:SetFrameStrata("HIGH")
    frame:EnableMouse(true)
    frame:SetResizable(true)
    frame:SetMinResize(600, 50)
    frame:SetMaxResize(600, 680)
    frame:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.7)
    tinsert(UISpecialFrames, "LeaPlusRecentChatFrame")

    local title = CreateFrame("Frame", nil, frame)
    title:SetSize(600, 36)
    title:SetPoint("TOP", frame, "TOP", 0, 40)
    title:SetFrameStrata("HIGH")
    title:EnableMouse(true)
    title:SetBackdrop(frame:GetBackdrop())
    title:SetBackdropColor(0, 0, 0, 0.7)

    title.count = title:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title.count:SetPoint("LEFT", 9, 0)
    local cntFont, _, cntFlags = title.count:GetFont()
    title.count:SetFont(cntFont, 16, cntFlags)
    title.count:SetText("Messages: 0")

    title.hint = title:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title.hint:SetPoint("RIGHT", -9, 0)
    local hintFont, _, hintFlags = title.hint:GetFont()
    title.hint:SetFont(hintFont, 16, hintFlags)
    title.hint:SetText(L["Drag to size"] .. " | " .. L["Right-click to close"])

    local function Close()
        if frame:IsShown() then frame:Hide() end
    end

    title:HookScript("OnMouseDown", function(_, btn)
        if btn == "LeftButton" then
            frame:StartSizing("TOP")
        elseif btn == "RightButton" then
            Close()
        end
    end)
    title:HookScript("OnMouseUp", function(_, btn)
        if btn == "LeftButton" then
            frame:StopMovingOrSizing()
            LeaPlusLC["RecentChatSize"] = frame:GetHeight()
        elseif btn == "MiddleButton" then
            LeaPlusLC["RecentChatSize"] = 170
            frame:SetSize(600, 170)
        end
    end)
    frame:HookScript("OnMouseUp", function(_, btn)
        if btn == "LeftButton" then
            frame:StopMovingOrSizing()
            LeaPlusLC["RecentChatSize"] = frame:GetHeight()
        end
    end)

    local scroll = CreateFrame("ScrollFrame", "LeaPlusRecentChatScroll", frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, 26, -36)
    scroll:SetPoint("BOTTOMRIGHT", frame, -34, 8)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetFontObject(ChatFontNormal)
    edit:SetMultiLine(true)
    edit:SetMaxLetters(0)
    edit:SetAutoFocus(false)
    edit:EnableMouse(true)
    edit:EnableMouseWheel(true)
    edit:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    edit:SetWidth(scroll:GetWidth())
    edit:SetScript("OnEscapePressed", Close)
    edit:HookScript("OnMouseDown", function(_, btn)
        if btn == "RightButton" then Close() end
    end)
    edit:SetScript("OnMouseWheel", function(_, delta)
        local onWheel = scroll:GetScript("OnMouseWheel")
        if onWheel then
            onWheel(scroll, delta)
        end
    end)
    scroll:SetScrollChild(edit)

    scroll:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = self:GetVerticalScrollRange()
        if not maxScroll or maxScroll <= 0 then return end
        local curScroll = self:GetVerticalScroll()

        if IsShiftKeyDown() then
            self:SetVerticalScroll(delta > 0 and 0 or maxScroll)
        elseif IsAltKeyDown() then
            local page = self:GetHeight()
            self:SetVerticalScroll(delta > 0 and math.max(0, curScroll - page) or math.min(maxScroll, curScroll + page))
        else
            local step = 42
            self:SetVerticalScroll(delta > 0 and math.max(0, curScroll - step) or math.min(maxScroll, curScroll + step))
        end
    end)

    local function ShowRecentChat(chatFrame)
        local id = chatFrame:GetID()
        local buffer = LeaChatBuffer[id] or {}
        title.count:SetText("Messages: " .. #buffer)

        if #buffer == 0 then
            edit:SetText("")
            frame:Show()
            return
        end

        local content = table.concat(buffer, "\n")
        local scrollW = scroll:GetWidth()
        edit:SetWidth((scrollW and scrollW > 0) and scrollW or 540)
        edit:SetText(content)
        local _, fontHeight = edit:GetFont()
        local lineCount = #buffer
        edit:SetHeight(math.max(lineCount * ((fontHeight or 14) + 2), scroll:GetHeight()))

        frame:Show()
        LibCompat.After(0.05, function()
            if scroll.UpdateScrollChildRect then
                scroll:UpdateScrollChildRect()
            end
            scroll:SetVerticalScroll(scroll:GetVerticalScrollRange())
        end)
    end

    for id = 1, NUM_CHAT_WINDOWS do
        local tab = _G["ChatFrame" .. id .. "Tab"]
        if tab then
            tab:HookScript("OnMouseUp", function(_, btn)
                if btn == "LeftButton" and IsControlKeyDown() then
                    if frame:IsShown() and frame.currentSource == _G["ChatFrame" .. id] then
                        Close()
                    else
                        frame.currentSource = _G["ChatFrame" .. id]
                        ShowRecentChat(_G["ChatFrame" .. id])
                    end
                end
            end)
        end
    end
end

-- Chat filter handlers
local function BuildFilterPattern(str)
    if not str then return "" end
    str = str:gsub("%%%d%$s", "\1")
    str = str:gsub("%%s", "\1")
    str = str:gsub("([%^%$%(%)%.%[%]%*%+%-%?%%])", "%%%1")
    str = str:gsub("\1", ".-")
    return str
end

local duelPattern1 = BuildFilterPattern(DUEL_WINNER_KNOCKOUT)
local duelPattern2 = BuildFilterPattern(DUEL_WINNER_RETREAT)

local drunkPatterns = {}
for i = 1, 4 do
    local p1 = BuildFilterPattern(_G["DRUNK_MESSAGE_ITEM_OTHER" .. i])
    if p1 ~= "" then drunkPatterns[#drunkPatterns + 1] = p1 end
    local p2 = BuildFilterPattern(_G["DRUNK_MESSAGE_OTHER" .. i])
    if p2 ~= "" then drunkPatterns[#drunkPatterns + 1] = p2 end
end

local function FilterHandler(_, _, msg)
    if not msg then return end

    if LeaPlusLC["BlockSpellLinks"] == "On" and UnitAffectingCombat("player") then
        if msg:find("|Hspell", 1, true) then return true end
    end

    if LeaPlusLC["BlockDuelSpam"] == "On" then
        if (duelPattern1 ~= "" and msg:find(duelPattern1)) or (duelPattern2 ~= "" and msg:find(duelPattern2)) then
            local myName = UnitName("player")
            if myName and not msg:find(myName, 1, true) then return true end
        end
    end

    if LeaPlusLC["BlockDrunkenSpam"] == "On" then
        local myName = UnitName("player") or ""
        for i = 1, #drunkPatterns do
            if msg:find(drunkPatterns[i]) then
                if myName == "" or not msg:find(myName, 1, true) then return true end
            end
        end
    end
end

local function UpdateFilterRegistrations()
    ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SAY", FilterHandler)
    ChatFrame_RemoveMessageEventFilter("CHAT_MSG_YELL", FilterHandler)
    ChatFrame_RemoveMessageEventFilter("CHAT_MSG_EMOTE", FilterHandler)
    ChatFrame_RemoveMessageEventFilter("CHAT_MSG_PARTY", FilterHandler)
    ChatFrame_RemoveMessageEventFilter("CHAT_MSG_PARTY_LEADER", FilterHandler)
    ChatFrame_RemoveMessageEventFilter("CHAT_MSG_RAID", FilterHandler)
    ChatFrame_RemoveMessageEventFilter("CHAT_MSG_RAID_LEADER", FilterHandler)
    ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", FilterHandler)

    if LeaPlusLC["FilterChatMessages"] ~= "On" then return end

    if LeaPlusLC["BlockSpellLinks"] == "On" then
        ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", FilterHandler)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", FilterHandler)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", FilterHandler)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", FilterHandler)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", FilterHandler)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", FilterHandler)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", FilterHandler)
    end

    if LeaPlusLC["BlockDrunkenSpam"] == "On" or LeaPlusLC["BlockDuelSpam"] == "On" then
        ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", FilterHandler)
    end
end

-- Chat tweaks
local function SetupChatTweaks()
    if LeaPlusLC["MoveChatEditBoxToTop"] == "On" then
        local function ApplyEditBoxTop(cf)
            if not cf then return end
            local eb = _G[cf:GetName() .. "EditBox"]
            if eb then
                eb:ClearAllPoints()
                eb:SetPoint("BOTTOMLEFT", cf, "TOPLEFT", 0, 2)
                eb:SetPoint("BOTTOMRIGHT", cf, "TOPRIGHT", 0, 2)
            end
        end

        for i = 1, NUM_CHAT_WINDOWS do
            ApplyEditBoxTop(_G["ChatFrame" .. i])
        end

        hooksecurefunc("FCF_OpenTemporaryWindow", function()
            ApplyEditBoxTop(FCF_GetCurrentChatFrame())
        end)
    end

    if LeaPlusLC["NoCombatLogTab"] == "On" then
        local function ShrinkCombatTab()
            if not ChatFrame2Tab or not ChatFrame2 or not ChatFrame2.isDocked then return end
            ChatFrame2Tab:EnableMouse(false)
            ChatFrame2Tab:SetText(" ")
            ChatFrame2Tab:SetScale(0.01)
            ChatFrame2Tab:SetWidth(0.01)
            ChatFrame2Tab:SetHeight(0.01)
            ChatFrame2Tab:SetAlpha(0)
        end

        ShrinkCombatTab()

        local clFrame = CreateFrame("Frame")
        clFrame:RegisterEvent("UPDATE_CHAT_WINDOWS")
        clFrame:SetScript("OnEvent", ShrinkCombatTab)

        hooksecurefunc("FCF_SetTabPosition", function()
            if ChatFrame1Tab and ChatFrame2Tab then
                ChatFrame2Tab:SetPoint("BOTTOMLEFT", ChatFrame1Tab, "BOTTOMRIGHT", 0, 0)
            end
        end)
    end

    if LeaPlusLC["NoChatButtons"] == "On" then
        local tframe = CreateFrame("Frame")
        tframe:Hide()

        local function HideButtons(chtfrm)
            local bf = _G[chtfrm .. "ButtonFrame"]
            if not bf then return end

            local up = _G[chtfrm .. "ButtonFrameUpButton"]
            local dn = _G[chtfrm .. "ButtonFrameDownButton"]
            local mn = _G[chtfrm .. "ButtonFrameMinimizeButton"]
            local bt = _G[chtfrm .. "ButtonFrameBottomButton"]

            if up then up:SetParent(tframe); up:Hide() end
            if dn then dn:SetParent(tframe); dn:Hide() end
            if mn then mn:SetParent(tframe); mn:Hide() end

            if bt then
                bt:SetParent(tframe)
                bt:Hide()
                if not bt.__leaHooked then
                    bt.__leaHooked = true
                    bt:HookScript("OnShow", bt.Hide)
                end
            end

            bf:SetSize(0.1, 0.1)
            bf:SetAlpha(0)
        end

        local function HandleChatWheel(self, delta)

            if IsControlKeyDown() then
                if delta > 0 then
                    if self.ScrollToTop then self:ScrollToTop()
                    else for _ = 1, 500 do self:ScrollUp() end end
                else
                    if self.ScrollToBottom then self:ScrollToBottom()
                    else for _ = 1, 500 do self:ScrollDown() end end
                end
            elseif IsShiftKeyDown() then
                if delta > 0 then self:PageUp() else self:PageDown() end
            else
                if delta > 0 then self:ScrollUp() else self:ScrollDown() end
            end
        end

        local function InstallWheel(cf)
            if not cf then return end
            cf:EnableMouseWheel(true)
            -- If our handler is already the active one, nothing to do.
            if cf:GetScript("OnMouseWheel") == HandleChatWheel then return end
            cf:SetScript("OnMouseWheel", HandleChatWheel)
        end

        if ChatFrameMenuButton then ChatFrameMenuButton:SetParent(tframe) end
        if FriendsMicroButton then FriendsMicroButton:SetParent(tframe) end

        for i = 1, 50 do
            local cf = _G["ChatFrame" .. i]
            local tab = _G["ChatFrame" .. i .. "Tab"]
            if cf then
                InstallWheel(cf)
                HideButtons("ChatFrame" .. i)
                if tab and not tab.__leaScrollHooked then
                    tab.__leaScrollHooked = true
                    tab:HookScript("OnClick", function(_, btn)
                        if btn == "LeftButton" and not IsControlKeyDown() then
                            cf:ScrollToBottom()
                        end
                    end)
                end
            end
        end

        hooksecurefunc("FCF_OpenTemporaryWindow", function()
            local cf = FCF_GetCurrentChatFrame()
            if cf and cf.GetName then
                local name = cf:GetName()
                if name then
                    InstallWheel(cf)
                    HideButtons(name)
                end
            end
        end)

        local ensureFrame = CreateFrame("Frame")
        ensureFrame:RegisterEvent("UPDATE_CHAT_WINDOWS")
        ensureFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        ensureFrame:SetScript("OnEvent", function()
            for i = 1, 50 do
                local cf = _G["ChatFrame" .. i]
                if cf then
                    InstallWheel(cf)
                    HideButtons("ChatFrame" .. i)
                end
            end
        end)
    end

    if LeaPlusLC["UnclampChat"] == "On" then
        local function ApplyChatUnclamp(cf)
            if not cf then return end
            cf:SetClampedToScreen(true)
            cf:SetClampRectInsets(0, 0, 0, 0)
        end

        for i = 1, NUM_CHAT_WINDOWS do
            ApplyChatUnclamp(_G["ChatFrame" .. i])
        end

        hooksecurefunc("FCF_OpenTemporaryWindow", function()
            ApplyChatUnclamp(FCF_GetCurrentChatFrame())
        end)
    end

    if LeaPlusLC["MoreFontSizes"] == "On" then
        local heights = { 10, 12, 14, 16, 18, 20, 22, 24, 26 }
        CHAT_FONT_HEIGHTS = heights
    end

    if LeaPlusLC["UseArrowKeysInChat"] == "On" then
        for i = 1, NUM_CHAT_WINDOWS do
            local eb = _G["ChatFrame" .. i .. "EditBox"]
            if eb then
                eb:SetAltArrowKeyMode(false)
                eb:SetHistoryLines(64)
            end
        end
    end

    if LeaPlusLC["NoStickyChat"] == "On" then
        if ChatTypeInfo.WHISPER then ChatTypeInfo.WHISPER.sticky = nil end
        if ChatTypeInfo.BN_WHISPER then ChatTypeInfo.BN_WHISPER.sticky = nil end
        if ChatTypeInfo.CHANNEL then ChatTypeInfo.CHANNEL.sticky = nil end
    end

    if LeaPlusLC["NoChatFade"] == "On" then
        for i = 1, NUM_CHAT_WINDOWS do
            local cf = _G["ChatFrame" .. i]
            if cf then cf:SetFading(false) end
        end
        hooksecurefunc("FCF_OpenTemporaryWindow", function()
            local cf = FCF_GetCurrentChatFrame()
            if cf then cf:SetFading(false) end
        end)
    end

    if LeaPlusLC["UseEasyChatResizing"] == "On" then
        ChatFrame1Tab:HookScript("OnMouseDown", function(_, btn)
            if btn == "LeftButton" then
                if select(8, GetChatWindowInfo(1)) then
                    ChatFrame1:StartSizing("TOP")
                end
            end
        end)
        ChatFrame1Tab:HookScript("OnMouseUp", function(_, btn)
            if btn == "LeftButton" then
                ChatFrame1:StopMovingOrSizing()
                FCF_SavePositionAndDimensions(ChatFrame1)
            end
        end)
    end

    if LeaPlusLC["MaxChatHstory"] == "On" then
        for i = 1, 50 do
            local cf = _G["ChatFrame" .. i]
            if cf and cf.GetMaxLines and cf:GetMaxLines() ~= 4096 then
                cf:SetMaxLines(4096)
            end
        end
        hooksecurefunc("FCF_OpenTemporaryWindow", function()
            local cf = FCF_GetCurrentChatFrame()
            if cf and cf.GetMaxLines and cf:GetMaxLines() ~= 4096 then
                cf:SetMaxLines(4096)
            end
        end)
    end

    if LeaPlusLC["ClassColorsInChat"] == "On" then
        for _, info in pairs(ChatTypeInfo) do
            info.colorNameByClass = true
        end

        LibCompat.After(0.1, function()
            for i = 1, 18 do
                local chk = _G["ChatConfigChatSettingsLeftCheckBox" .. i .. "Check"]
                if chk and ToggleChatColorNamesByClassGroup then
                    ToggleChatColorNamesByClassGroup(true, chk:GetParent().type)
                    local cc = _G["ChatConfigChatSettingsLeftCheckBox" .. i .. "ColorClasses"]
                    if cc then
                        LeaPlusLC:LockItem(cc, true)
                    end
                end
            end
            if ToggleChatColorNamesByClassGroup then
                for i = 1, 50 do
                    ToggleChatColorNamesByClassGroup(true, "CHANNEL" .. i)
                end
            end
            hooksecurefunc("ChatConfig_CreateCheckboxes", function()
                if ChatConfigChannelSettingsLeft and ChatConfigChannelSettingsLeft.checkBoxTable then
                    for i = 1, 50 do
                        local cc = _G["ChatConfigChannelSettingsLeftCheckBox" .. i .. "ColorClasses"]
                        if cc then
                            LeaPlusLC:LockItem(cc, true)
                        end
                    end
                end
            end)
        end)
    end

    -- Alt-click invite: intercept chat frame hyperlink clicks safely
    if LeaPlusLC["AltClickInv"] == "On" then
        local function HookChatHyperlink(cf)
            if not cf or cf.__leaAltHooked then return end
            cf.__leaAltHooked = true
            local origHandler = cf:GetScript("OnHyperlinkClick")
            cf:SetScript("OnHyperlinkClick", function(self, link, text, button, ...)
                if IsAltKeyDown() and button == "LeftButton" and link then
                    local linkType, name = strsplit(":", link)
                    if linkType == "player" and name and name ~= "" then
                        local cleanName = strsplit("-", name)
                        if cleanName and cleanName ~= "" then
                            InviteUnit(cleanName)
                            return
                        end
                    end
                end
                if origHandler then
                    return origHandler(self, link, text, button, ...)
                elseif ChatFrame_OnHyperlinkShow then
                    return ChatFrame_OnHyperlinkShow(self, link, text, button, ...)
                end
            end)
        end

        for i = 1, NUM_CHAT_WINDOWS do
            HookChatHyperlink(_G["ChatFrame" .. i])
        end

        hooksecurefunc("FCF_OpenTemporaryWindow", function()
            local cf = FCF_GetCurrentChatFrame()
            if cf and type(cf) == "table" then
                HookChatHyperlink(cf)
            end
        end)
    end

    -- Chat filter sub-panel
    local ChatFilterPanel = LeaPlusLC:CreatePanel("Filter Chat Messages", "ChatFilterPanel")
    LeaPlusLC:MakeTx(ChatFilterPanel, "Settings", 16, -72)
    LeaPlusLC:MakeCB(ChatFilterPanel, "BlockSpellLinks", "Block Spell Links in Combat", 16, -92, false, "Hides messages containing spell hyperlinks during combat across Say, Yell, Party, and Raid channels.")
    LeaPlusLC:MakeCB(ChatFilterPanel, "BlockDrunkenSpam", "Block Drunken Spam", 16, -112, false, "Hides drunken emote messages unless directed at your character.")
    LeaPlusLC:MakeCB(ChatFilterPanel, "BlockDuelSpam", "Block Duel Spam", 16, -132, false, "Hides duel victory and retreat announcements unless involving your character.")
    ChatFilterPanel.h:Hide()
    ChatFilterPanel.b:SetScript("OnClick", function()
        ChatFilterPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page3"]:Show()
    end)
    ChatFilterPanel.r:SetScript("OnClick", function()
        LeaPlusLC["BlockSpellLinks"] = "Off"
        LeaPlusLC["BlockDrunkenSpam"] = "Off"
        LeaPlusLC["BlockDuelSpam"] = "Off"
        UpdateFilterRegistrations()
        ChatFilterPanel:Hide(); ChatFilterPanel:Show()
    end)

    if LeaPlusCB["FilterChatMessagesBtn"] then
        LeaPlusCB["FilterChatMessagesBtn"]:SetScript("OnClick", function()
            ChatFilterPanel:Show(); LeaPlusLC:HideFrames()
        end)
    end

    local filterOptions = { "FilterChatMessages", "BlockSpellLinks", "BlockDrunkenSpam", "BlockDuelSpam" }
    for _, key in ipairs(filterOptions) do
        if LeaPlusCB[key] then
            LeaPlusCB[key]:HookScript("OnClick", UpdateFilterRegistrations)
        end
    end

    UpdateFilterRegistrations()
end

-- Lifecycle
function Module:OnEnable()
    if LeaPlusLC["RecentChatWindow"] == "On" or LeaPlusLC["RestoreChatMessages"] == "On" then
        for i = 1, NUM_CHAT_WINDOWS do
            if i ~= 2 then
                HookChatFrameAddMessage(_G["ChatFrame" .. i], i)
            end
        end
    end

    SetupRecentChatWindow()
    SetupChatTweaks()
end

function Module:OnLogin()
    local db = Leatrix_Plus.DB
    local charKey = (UnitName("player") or "Unknown") .. " - " .. (GetRealmName() or "Unknown")
    if LeaPlusLC["RestoreChatMessages"] == "On" and db["ChatHistoryTime"] and db["ChatHistoryChar"] == charKey then
        if time() - db["ChatHistoryTime"] < 3600 then
            for i = 1, NUM_CHAT_WINDOWS do
                local cf = _G["ChatFrame" .. i]
                local hist = db["ChatHistory" .. i]
                if i ~= 2 and cf and hist then
                    cf.__leaRestoring = true
                    for _, line in ipairs(hist) do
                        if not line:find("from previous session", 1, true) then
                            cf:AddMessage(line)
                            if LeaChatBuffer[i] and #LeaChatBuffer[i] < 128 then
                                table.insert(LeaChatBuffer[i], line)
                            end
                        end
                    end
                    cf.__leaRestoring = nil
                end
            end
        end
    end
end

function Module:OnLogout(wipeData)
    local db = Leatrix_Plus.DB
    local charKey = (UnitName("player") or "Unknown") .. " - " .. (GetRealmName() or "Unknown")
    if LeaPlusLC["RestoreChatMessages"] == "On" and not wipeData then
        db["ChatHistoryTime"] = time()
        db["ChatHistoryChar"] = charKey
        for i = 1, NUM_CHAT_WINDOWS do
            if i ~= 2 and LeaChatBuffer[i] and #LeaChatBuffer[i] > 0 then
                db["ChatHistory" .. i] = LeaChatBuffer[i]
            end
        end
    else
        db["ChatHistoryTime"] = nil
        db["ChatHistoryChar"] = nil
        for i = 1, NUM_CHAT_WINDOWS do
            db["ChatHistory" .. i] = nil
        end
    end
end