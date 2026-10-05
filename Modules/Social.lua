-- Social.lua
local _, Leatrix_Plus = ...
local LeaPlusLC = Leatrix_Plus.LC
local LeaPlusCB = Leatrix_Plus.CB
local L = Leatrix_Plus.L

local Module = {}
Leatrix_Plus:RegisterModule("Social", Module)

local sFrame = CreateFrame("Frame")

-- Group-state helper: can the player invite someone via keyword?
local function CanInviteFromWhisper()
    local inInstance, instanceType = IsInInstance()
    if inInstance and (instanceType == "pvp" or instanceType == "arena") then
        return false
    end

    if GetNumRaidMembers() > 0 then
        local maxRaid = LeaPlusLC["InvMaxRaidSize"] or 25
        if GetNumRaidMembers() >= maxRaid then return false end
        return (IsPartyLeader() or UnitIsRaidOfficer("player")) and true or false
    elseif GetNumPartyMembers() > 0 then
        if GetNumPartyMembers() >= 4 then return false end
        return IsPartyLeader() and true or false
    end
    return true
end

-- Invite from whispers (config panel)
local function SetupWhisperInvite()
    local InvPanel = LeaPlusLC:CreatePanel("Invite from Whispers", "InvPanel")

    LeaPlusLC:MakeTx(InvPanel, "Settings", 16, -72)
    LeaPlusLC:MakeCB(InvPanel, "InviteFriendsOnly", "Restrict to Friends and Guild", 16, -92, false, "Only sends group invitations to players on your friends list or in your guild.")
    LeaPlusLC:MakeTx(InvPanel, "Raid limit", 16, -132)
    LeaPlusLC:MakeSL(InvPanel, "InvMaxRaidSize", "Stops accepting keyword invites once your raid reaches this member count.", 5, 40, 5, 16, -152, "%.0f players")

    LeaPlusLC:MakeTx(InvPanel, "Keyword", 356, -72)
    local KeyBox = LeaPlusLC:CreateEditBox("KeyBox", InvPanel, 140, 24, "TOPLEFT", 356, -92, "KeyBox", "KeyBox", 10)

    local function UpdateInviteTooltip()
        if LeaPlusCB["InviteFromWhisper"] then
            local key = LeaPlusLC["InvKey"] or "inv"
            LeaPlusCB["InviteFromWhisper"].tiptext = "Automatically invite players to your group when they whisper you a specific keyword.|n|nKeyword: |cffffffff" .. key .. "|r"
        end
    end

    local function SetInvKey()
        local keytext = KeyBox:GetText()
        LeaPlusLC["InvKey"] = (keytext and keytext ~= "") and strtrim(keytext) or "inv"
        UpdateInviteTooltip()
    end

    KeyBox:SetScript("OnTextChanged", SetInvKey)
    KeyBox:SetScript("OnEditFocusLost", function()
        KeyBox:SetText(LeaPlusLC["InvKey"])
    end)
    KeyBox:HookScript("OnShow", function()
        KeyBox:SetText(LeaPlusLC["InvKey"] or "inv")
    end)
    UpdateInviteTooltip()

    InvPanel.h:Hide()
    InvPanel.b:SetScript("OnClick", function()
        SetInvKey()
        InvPanel:Hide()
        LeaPlusLC["PageF"]:Show()
        LeaPlusLC["Page2"]:Show()
    end)
    InvPanel.r:SetScript("OnClick", function()
        LeaPlusLC["InviteFriendsOnly"] = "Off"
        LeaPlusLC["InvKey"] = "inv"
        LeaPlusLC["InvMaxRaidSize"] = 25
        KeyBox:SetText("inv")
        SetInvKey()
        InvPanel:Hide(); InvPanel:Show()
    end)

    if LeaPlusCB["InvWhisperBtn"] then
        LeaPlusCB["InvWhisperBtn"]:SetScript("OnClick", function()
            InvPanel:Show()
            LeaPlusLC:HideFrames()
        end)
    end
end

-- Dynamic event registration
local function UpdateEventRegistration()
    if LeaPlusLC["InviteFromWhisper"] == "On" then
        sFrame:RegisterEvent("CHAT_MSG_WHISPER")
        sFrame:RegisterEvent("CHAT_MSG_BN_WHISPER")
    else
        sFrame:UnregisterEvent("CHAT_MSG_WHISPER")
        sFrame:UnregisterEvent("CHAT_MSG_BN_WHISPER")
    end

    if LeaPlusLC["NoDuelRequests"] == "On" then
        sFrame:RegisterEvent("DUEL_REQUESTED")
    else
        sFrame:UnregisterEvent("DUEL_REQUESTED")
    end

    if LeaPlusLC["NoPartyInvites"] == "On" or LeaPlusLC["AcceptPartyFriends"] == "On" then
        sFrame:RegisterEvent("PARTY_INVITE_REQUEST")
    else
        sFrame:UnregisterEvent("PARTY_INVITE_REQUEST")
    end

    if LeaPlusLC["NoGuildInvites"] == "On" then
        sFrame:RegisterEvent("GUILD_INVITE_REQUEST")
    else
        sFrame:UnregisterEvent("GUILD_INVITE_REQUEST")
    end

    if LeaPlusLC["NoSharedQuests"] == "On" then
        sFrame:RegisterEvent("QUEST_SHARED")
    else
        sFrame:UnregisterEvent("QUEST_SHARED")
    end
end

-- Event listeners
local function SetupSocialEvents()
    sFrame:SetScript("OnEvent", function(_, event, arg1, arg2, ...)
        if event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_BN_WHISPER" then
            if not arg1 or not arg2 then return end
            if not CanInviteFromWhisper() then return end

            local whisper = strlower(strtrim(arg1))
            local keyword = strlower(LeaPlusLC["InvKey"] or "inv")
            if whisper ~= keyword then return end

            if LeaPlusLC:IsInLFGQueue() then return end

            if event == "CHAT_MSG_WHISPER" then
                if LeaPlusLC["InviteFriendsOnly"] == "On" and not LeaPlusLC:FriendCheck(arg2) then return end
                local nameOnly = strsplit("-", arg2)
                local cleanName = strtrim(nameOnly or arg2)
                if cleanName and cleanName ~= "" then
                    InviteUnit(cleanName)
                end
            elseif event == "CHAT_MSG_BN_WHISPER" then
                -- Battle.net whisper support in 3.3.5
                local presenceID = select(11, ...)
                if presenceID and BNGetFriendIndex then
                    local friendIndex = BNGetFriendIndex(presenceID)
                    if friendIndex then
                        local _, _, _, _, toonName, _, client = BNGetFriendInfo(friendIndex)
                        if client == BNET_CLIENT_WOW and toonName and toonName ~= "" then
                            InviteUnit(toonName)
                        end
                    end
                end
            end

        elseif event == "DUEL_REQUESTED" then
            if not LeaPlusLC:FriendCheck(arg1) then
                CancelDuel()
                StaticPopup_Hide("DUEL_REQUESTED")
            end

        elseif event == "PARTY_INVITE_REQUEST" then
            if LeaPlusLC["AcceptPartyFriends"] == "On" and LeaPlusLC:FriendCheck(arg1) then
                if not LeaPlusLC:IsInLFGQueue() then
                    AcceptGroup()
                    for i = 1, STATICPOPUP_NUMDIALOGS do
                        local popup = _G["StaticPopup" .. i]
                        if popup and popup.which == "PARTY_INVITE" then
                            popup.inviteAccepted = 1
                            StaticPopup_Hide("PARTY_INVITE")
                        end
                    end
                    return
                end
            end
            if (LeaPlusLC["NoPartyInvites"] == "On" or LeaPlusLC["AcceptPartyFriends"] == "On") and not LeaPlusLC:FriendCheck(arg1) then
                DeclineGroup()
                StaticPopup_Hide("PARTY_INVITE")
            end

        elseif event == "GUILD_INVITE_REQUEST" then
            if not LeaPlusLC:FriendCheck(arg1) then
                DeclineGuild()
                StaticPopup_Hide("GUILD_INVITE")
            end

        elseif event == "QUEST_SHARED" then
            if not LeaPlusLC:FriendCheck(arg2) then
                LibCompat.After(0.1, function()
                    -- Only decline if the currently shown quest is genuinely from a player, not an NPC
                    if QuestFrame and QuestFrame:IsShown() and (QuestFrame.isShared or UnitInParty(arg2) or UnitInRaid(arg2)) then
                        DeclineQuest()
                    end
                end)
            end
        end
    end)

    -- Hook checkboxes so toggling them updates the event set live
    local optionButtons = {
        "InviteFromWhisper",
        "NoDuelRequests",
        "NoPartyInvites",
        "NoGuildInvites",
        "NoSharedQuests",
        "AcceptPartyFriends",
    }

    for _, key in ipairs(optionButtons) do
        local cb = LeaPlusCB[key]
        if cb then
            cb:HookScript("OnClick", UpdateEventRegistration)
        end
    end

    -- Initial registration based on current options
    UpdateEventRegistration()
end

-- Lifecycle
function Module:OnEnable()
    SetupWhisperInvite()
    SetupSocialEvents()
end

function Module:OnLogin() end
function Module:OnLogout(wipeData) end