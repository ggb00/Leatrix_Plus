-- Chat.lua
local _, Leatrix_Plus = ...
local LeaPlusLC = Leatrix_Plus.LC
local LeaPlusCB = Leatrix_Plus.CB
local L = Leatrix_Plus.L

local Module = {}
Leatrix_Plus:RegisterModule("Chat", Module)

----------------------------------------------------------------------
-- 1. Native 3.3.5 Chat Ring Buffer
----------------------------------------------------------------------
local LeaChatBuffer = {}
for i = 1, NUM_CHAT_WINDOWS do
    LeaChatBuffer[i] = {}
end

local function HookChatFrameAddMessage(cf, idx)
    if not cf or cf.__leaHooked then return end
    cf.__leaHooked = true
    local origAddMessage = cf.AddMessage

    cf.AddMessage = function(self, text, r, g, b, id, ...)
        if text then
            local buf = LeaChatBuffer[idx]
            if buf then
                if #buf >= 128 then
                    table.remove(buf, 1)
                end
                local hex = (r and g and b) and string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255) or "|cffffffff"
                table.insert(buf, hex .. tostring(text) .. "|r")
            end
        end
        return origAddMessage(self, text, r, g, b, id, ...)
    end
end

----------------------------------------------------------------------
-- 2. Recent Chat Window (Reused EditBox to Prevent Leaks)
----------------------------------------------------------------------
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
    title:SetFrameStrata("MEDIUM")
    title:EnableMouse(true)
    title:SetBackdrop(frame:GetBackdrop())
    title:SetBackdropColor(0, 0, 0, 0.7)

    title.count = title:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title.count:SetPoint("LEFT", 9, 0)
    title.count:SetFont(title.count:GetFont(), 16)
    title.count:SetText("Messages: 0")

    title.hint = title:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title.hint:SetPoint("RIGHT", -9, 0)
    title.hint:SetFont(title.hint:GetFont(), 16)
    title.hint:SetText(L["Drag to size"] .. " | " .. L["Right-click to close"])

    local function Close()
        if frame:IsShown() then frame:Hide() end
    end

    title:HookScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" then
            frame:StartSizing("TOP")
        elseif btn == "RightButton" then
            Close()
        end
    end)
    title:HookScript("OnMouseUp", function(self, btn)
        if btn == "LeftButton" then
            frame:StopMovingOrSizing()
            LeaPlusLC["RecentChatSize"] = frame:GetHeight()
        elseif btn == "MiddleButton" then
            LeaPlusLC["RecentChatSize"] = 170
            frame:SetSize(600, 170)
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
    edit:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    edit:SetWidth(scroll:GetWidth())
    edit:SetScript("OnEscapePressed", Close)
    edit:HookScript("OnMouseDown", function(_, btn) if btn == "RightButton" then Close() end end)
    scroll:SetScrollChild(edit)

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
        edit:SetText(content)
        local _, fontHeight = edit:GetFont()
        local lineCount = select(2, content:gsub("\n", "\n")) + 1
        edit:SetHeight(math.max(lineCount * ((fontHeight or 14) + 2), scroll:GetHeight()))

        frame:Show()
        LibCompat.After(0.05, function()
            scroll:SetVerticalScroll(scroll:GetVerticalScrollRange())
        end)
    end

    for id = 1, NUM_CHAT_WINDOWS do
        local tab = _G["ChatFrame" .. id .. "Tab"]
        if tab then
            tab:HookScript("OnMouseUp", function(self, btn)
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

----------------------------------------------------------------------
-- 3. Mechanics & Toggles
----------------------------------------------------------------------
local function SetupChatTweaks()
    -- Editbox to Top
    if LeaPlusLC["MoveChatEditBoxToTop"] == "On" then
        for i = 1, NUM_CHAT_WINDOWS do
            local eb = _G["ChatFrame" .. i .. "EditBox"]
            if eb then
                eb:ClearAllPoints()
                eb:SetPoint("BOTTOMLEFT", _G["ChatFrame" .. i], "TOPLEFT", 0, 2)
                eb:SetPoint("BOTTOMRIGHT", _G["ChatFrame" .. i], "TOPRIGHT", 0, 2)
            end
        end
    end

    -- Arrow Keys in Chat
    if LeaPlusLC["UseArrowKeysInChat"] == "On" then
        for i = 1, NUM_CHAT_WINDOWS do
            local eb = _G["ChatFrame" .. i .. "EditBox"]
            if eb then
                eb:SetAltArrowKeyMode(false)
            end
        end
    end

    -- Disable Sticky Chat
    if LeaPlusLC["NoStickyChat"] == "On" then
        ChatTypeInfo.WHISPER.sticky = nil
        ChatTypeInfo.BN_WHISPER.sticky = nil
        ChatTypeInfo.CHANNEL.sticky = nil
    end

    -- Disable Chat Fade
    if LeaPlusLC["NoChatFade"] == "On" then
        for i = 1, NUM_CHAT_WINDOWS do
            local cf = _G["ChatFrame" .. i]
            if cf then cf:SetFading(false) end
        end
    end

    -- Alt-Click Invite
    if LeaPlusLC["AltClickInv"] == "On" then
        local origSetItemRef = SetItemRef
        SetItemRef = function(link, text, button, chatFrame)
            local linkType, name = strsplit(":", link)
            if linkType == "player" and IsAltKeyDown() and name then
                InviteUnit(strsplit("-", name))
                return
            end
            return origSetItemRef(link, text, button, chatFrame)
        end
    end
end

----------------------------------------------------------------------
-- Lifecycle Hooks
----------------------------------------------------------------------
function Module:OnEnable()
    for i = 1, NUM_CHAT_WINDOWS do
        if i ~= 2 then
            HookChatFrameAddMessage(_G["ChatFrame" .. i], i)
        end
    end

    SetupRecentChatWindow()
    SetupChatTweaks()
end

function Module:OnLogin()
    -- Restore session history if enabled
    if LeaPlusLC["RestoreChatMessages"] == "On" and LeaPlusDB["ChatHistoryTime"] then
        if time() - LeaPlusDB["ChatHistoryTime"] < 3600 then
            for i = 1, NUM_CHAT_WINDOWS do
                if i ~= 2 and _G["ChatFrame" .. i] and LeaPlusDB["ChatHistory" .. i] then
                    for _, line in ipairs(LeaPlusDB["ChatHistory" .. i]) do
                        _G["ChatFrame" .. i]:AddMessage(line)
                    end
                end
            end
        end
    end
end

function Module:OnLogout(wipeData)
    if LeaPlusLC["RestoreChatMessages"] == "On" and not wipeData then
        LeaPlusDB["ChatHistoryTime"] = time()
        for i = 1, NUM_CHAT_WINDOWS do
            if i ~= 2 and LeaChatBuffer[i] and #LeaChatBuffer[i] > 0 then
                LeaPlusDB["ChatHistory" .. i] = LeaChatBuffer[i]
            end
        end
    else
        LeaPlusDB["ChatHistoryTime"] = nil
        for i = 1, NUM_CHAT_WINDOWS do
            LeaPlusDB["ChatHistory" .. i] = nil
        end
    end
end