-- Social.lua
local _, Leatrix_Plus = ...
local LeaPlusLC = Leatrix_Plus.LC
local LeaPlusCB = Leatrix_Plus.CB
local L = Leatrix_Plus.L

local Module = {}
Leatrix_Plus:RegisterModule("Social", Module)

local sFrame = CreateFrame("Frame")

function Module:OnEnable()
    -- Whisper invite keyword configuration
    local InvPanel = LeaPlusLC:CreatePanel("Invite from whispers", "InvPanel")
    LeaPlusLC:MakeTx(InvPanel, "Settings", 16, -72)
    LeaPlusLC:MakeCB(InvPanel, "InviteFriendsOnly", "Restrict to friends", 16, -92, false, "If checked, group invites will only be sent to friends.")

    LeaPlusLC:MakeTx(InvPanel, "Keyword", 356, -72)
    local KeyBox = LeaPlusLC:CreateEditBox("KeyBox", InvPanel, 140, 24, "TOPLEFT", 356, -92, "KeyBox", "KeyBox", 10)

    local function SetInvKey()
        local keytext = KeyBox:GetText()
        LeaPlusLC["InvKey"] = (keytext and keytext ~= "") and strtrim(keytext) or "inv"
    end

    KeyBox:SetScript("OnTextChanged", SetInvKey)
    KeyBox:SetScript("OnEditFocusLost", function() KeyBox:SetText(LeaPlusLC["InvKey"]) end)
    KeyBox:HookScript("OnShow", function() KeyBox:SetText(LeaPlusLC["InvKey"] or "inv") end)

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
        KeyBox:SetText("inv")
        SetInvKey()
        InvPanel:Hide(); InvPanel:Show()
    end)

    LeaPlusCB["InvWhisperBtn"]:SetScript("OnClick", function()
        InvPanel:Show()
        LeaPlusLC:HideFrames()
    end)

    -- Event listener
    sFrame:SetScript("OnEvent", function(self, event, arg1, arg2, ...)
        -- Whisper Invites
        if event == "CHAT_MSG_WHISPER" then
            if LeaPlusLC["InviteFromWhisper"] == "On" then
                if (not UnitExists("party1") or UnitIsPartyLeader("player") or UnitIsRaidOfficer("player")) then
                    if strlower(strtrim(arg1)) == strlower(LeaPlusLC["InvKey"] or "inv") then
                        if not LeaPlusLC:IsInLFGQueue() then
                            if LeaPlusLC["InviteFriendsOnly"] == "Off" or LeaPlusLC:FriendCheck(arg2) then
                                InviteUnit(arg2)
                            end
                        end
                    end
                end
            end

        -- Block Duels
        elseif event == "DUEL_REQUESTED" then
            if LeaPlusLC["NoDuelRequests"] == "On" and not LeaPlusLC:FriendCheck(arg1) then
                CancelDuel()
                StaticPopup_Hide("DUEL_REQUESTED")
            end

        -- Party Invites
        elseif event == "PARTY_INVITE_REQUEST" then
            if LeaPlusLC["AcceptPartyFriends"] == "On" and LeaPlusLC:FriendCheck(arg1) then
                if not LeaPlusLC:IsInLFGQueue() then
                    AcceptGroup()
                    StaticPopup_Hide("PARTY_INVITE")
                    return
                end
            end
            if LeaPlusLC["NoPartyInvites"] == "On" and not LeaPlusLC:FriendCheck(arg1) then
                DeclineGroup()
                StaticPopup_Hide("PARTY_INVITE")
            end

        -- Guild Invites
        elseif event == "GUILD_INVITE_REQUEST" then
            if LeaPlusLC["NoGuildInvites"] == "On" and not LeaPlusLC:FriendCheck(arg1) then
                DeclineGuild()
                StaticPopup_Hide("GUILD_INVITE")
            end

        -- Block Shared Quests
        elseif event == "QUEST_DETAIL" then
            if LeaPlusLC["NoSharedQuests"] == "On" then
                local npcName = UnitName("questnpc")
                if npcName and (UnitInParty(npcName) or UnitInRaid(npcName)) then
                    if not LeaPlusLC:FriendCheck(npcName) then
                        DeclineQuest()
                    end
                end
            end
        end
    end)

    sFrame:RegisterEvent("CHAT_MSG_WHISPER")
    sFrame:RegisterEvent("DUEL_REQUESTED")
    sFrame:RegisterEvent("PARTY_INVITE_REQUEST")
    sFrame:RegisterEvent("GUILD_INVITE_REQUEST")
    sFrame:RegisterEvent("QUEST_DETAIL")
end

function Module:OnLogin() end
function Module:OnLogout(wipeData) end