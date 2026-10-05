-- Automation.lua
local _, Leatrix_Plus = ...
local LeaPlusLC = Leatrix_Plus.LC
local LeaPlusCB = Leatrix_Plus.CB
local L = Leatrix_Plus.L

local Module = {}
Leatrix_Plus:RegisterModule("Automation", Module)

-- Automate Quests
local function SetupAutomateQuests()
    local qFrame = CreateFrame("Frame")
    qFrame.completedQuests = {}
    qFrame.uncompletedQuests = {}

    local function IsOverrideKeyDown()
        if (LeaPlusLC["AutoQuestKeyMenu"] == 1 and IsShiftKeyDown())
            or (LeaPlusLC["AutoQuestKeyMenu"] == 2 and IsAltKeyDown())
            or (LeaPlusLC["AutoQuestKeyMenu"] == 3 and IsControlKeyDown()) then
            return true
        end
        return false
    end

    local function CanAutomate()
        if (LeaPlusLC["AutoQuestShift"] == "On" and not IsOverrideKeyDown())
            or (LeaPlusLC["AutoQuestShift"] == "Off" and IsOverrideKeyDown()) then
            return false
        end
        return true
    end

    local function StripQuestText(text)
        if not text then return "" end
        text = text:gsub("|c%x%x%x%x%x%x%x%x(.-)|r", "%1")
        text = text:gsub("%[.*%]%s*", "")
        text = text:gsub(" %([Cc][Oo][Mm][Pp][Ll][Ee][Tt][Ee]%)", "")
        text = text:gsub(" %([Dd][Aa][Ii][Ll][Yy]%)", "")
        text = text:gsub(" %([Ll][Oo][Ww] [Ll][Ee][Vv][Ee][Ll]%)", "")
        text = text:gsub(" %([Rr][Ee][Pp][Ee][Aa][Tt][Aa][Bb][Ll][Ee]%)", "")
        return strtrim(text)
    end

    qFrame:SetScript("OnEvent", function(self, event)
        if event ~= "QUEST_LOG_UPDATE" and not CanAutomate() then return end

        if event == "QUEST_PROGRESS" then
            if LeaPlusLC["AutoQuestCompleted"] == "On" and IsQuestCompletable() and (GetQuestMoneyToGet() == 0) then
                CompleteQuest()
            end
        elseif event == "QUEST_LOG_UPDATE" then
            local startEntry = GetQuestLogSelection()
            local numEntries = GetNumQuestLogEntries()
            wipe(self.completedQuests)
            wipe(self.uncompletedQuests)

            for i = 1, numEntries do
                SelectQuestLogEntry(i)
                local title, _, _, _, isHeader, _, isComplete = GetQuestLogTitle(i)
                local noObjectives = (GetNumQuestLeaderBoards() == 0)
                if not isHeader and title then
                    if (isComplete and isComplete > 0) or noObjectives then
                        self.completedQuests[title] = true
                    else
                        self.uncompletedQuests[title] = true
                    end
                end
            end
            if startEntry and startEntry > 0 then
                SelectQuestLogEntry(startEntry)
            end
        elseif event == "GOSSIP_SHOW" then
            if LeaPlusLC["AutoQuestCompleted"] == "On" then
                for i = 1, 32 do
                    local btn = _G["GossipTitleButton" .. i]
                    if btn and btn:IsVisible() and btn.type == "Active" then
                        local text = StripQuestText(btn:GetText())
                        if self.completedQuests[text] then
                            btn:Click()
                            return
                        end
                    end
                end
            end
            if LeaPlusLC["AutoQuestAvailable"] == "On" then
                for i = 1, 32 do
                    local btn = _G["GossipTitleButton" .. i]
                    if btn and btn:IsVisible() and btn.type == "Available" then
                        btn:Click()
                        return
                    end
                end
            end
        elseif event == "QUEST_GREETING" then
            if LeaPlusLC["AutoQuestCompleted"] == "On" then
                for i = 1, 32 do
                    local btn = _G["QuestTitleButton" .. i]
                    if btn and btn:IsVisible() and btn.isActive == 1 then
                        local text = StripQuestText(btn:GetText())
                        if self.completedQuests[text] then
                            btn:Click()
                            return
                        end
                    end
                end
            end
            if LeaPlusLC["AutoQuestAvailable"] == "On" then
                for i = 1, 32 do
                    local btn = _G["QuestTitleButton" .. i]
                    if btn and btn:IsVisible() and btn.isActive ~= 1 then
                        local text = StripQuestText(btn:GetText())
                        if not self.uncompletedQuests[text] then
                            btn:Click()
                            return
                        end
                    end
                end
            end
        elseif event == "QUEST_DETAIL" then
            if LeaPlusLC["AutoQuestAvailable"] == "On" then
                local numQuests = 0
                for i = 1, GetNumQuestLogEntries() do
                    local _, _, _, _, isHeader = GetQuestLogTitle(i)
                    if not isHeader then
                        numQuests = numQuests + 1
                    end
                end
                if numQuests < 25 then
                    AcceptQuest()
                end
            end
        elseif event == "QUEST_COMPLETE" then
            if LeaPlusLC["AutoQuestCompleted"] == "On" then
                local choices = GetNumQuestChoices()
                if choices <= 1 then
                    GetQuestReward(QuestFrameRewardPanel.itemChoice or 0)
                end
            end
        end
    end)

    local function UpdateQuestEvents()
        if LeaPlusLC["AutomateQuests"] == "On" then
            qFrame:RegisterEvent("GOSSIP_SHOW")
            qFrame:RegisterEvent("QUEST_COMPLETE")
            qFrame:RegisterEvent("QUEST_DETAIL")
            qFrame:RegisterEvent("QUEST_GREETING")
            qFrame:RegisterEvent("QUEST_LOG_UPDATE")
            qFrame:RegisterEvent("QUEST_PROGRESS")
        else
            qFrame:UnregisterAllEvents()
        end
    end

    if LeaPlusCB["AutomateQuests"] then
        LeaPlusCB["AutomateQuests"]:HookScript("OnClick", UpdateQuestEvents)
    end
    UpdateQuestEvents()

    local QuestPanel = LeaPlusLC:CreatePanel("Automate Quests", "QuestPanel")
    LeaPlusLC:MakeTx(QuestPanel, "Settings", 16, -72)
    LeaPlusLC:MakeCB(QuestPanel, "AutoQuestAvailable", "Accept Available Quests", 16, -92, false, "Automatically accepts offered quests from NPCs.")
    LeaPlusLC:MakeCB(QuestPanel, "AutoQuestCompleted", "Complete Finished Quests", 16, -112, false, "Automatically turns in completed quests. Pauses automation if a quest offers multiple reward choices.")
    LeaPlusLC:MakeCB(QuestPanel, "AutoQuestShift", "Require Override Key", 16, -132, false, "Inverts automation so quests are only automated while holding the chosen override key.")
    LeaPlusLC:CreateDropDown("AutoQuestKeyMenu", "Override Key", QuestPanel, 146, "TOPLEFT", 356, -115, { L["SHIFT"], L["ALT"], L["CONTROL"] }, "Key held to enable or pause quest automation.")
    QuestPanel.h:Hide()
    QuestPanel.b:SetScript("OnClick", function()
        QuestPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page1"]:Show(); UpdateQuestEvents()
    end)
    QuestPanel.r:SetScript("OnClick", function()
        LeaPlusLC["AutoQuestShift"] = "Off"
        LeaPlusLC["AutoQuestAvailable"] = "On"
        LeaPlusLC["AutoQuestCompleted"] = "On"
        LeaPlusLC["AutoQuestKeyMenu"] = 1
        QuestPanel:Hide(); QuestPanel:Show(); UpdateQuestEvents()
    end)

    if LeaPlusCB["AutomateQuestsBtn"] then
        LeaPlusCB["AutomateQuestsBtn"]:SetScript("OnClick", function()
            QuestPanel:Show(); LeaPlusLC:HideFrames(); UpdateQuestEvents()
        end)
    end
end

-- Automate Gossip
local function SetupAutomateGossip()
    local gFrame = CreateFrame("Frame")
    local isPrinted = false

    local function SkipGossip(skipAlt)
        if not skipAlt and not IsAltKeyDown() then return end
        local numOptions = GetNumGossipOptions()
        local numAvailable = GetNumGossipAvailableQuests()
        local numActive = GetNumGossipActiveQuests()

        -- Force skip if user intentionally holds Alt, or auto-skip if NPC has exactly 1 option and no quests
        if (numOptions == 1 and numAvailable == 0 and numActive == 0) or (IsAltKeyDown() and numOptions == 1) then
            SelectGossipOption(1)
            if not isPrinted then
                LeaPlusLC:Print(L["Option chosen. Hold Shift to override."])
                isPrinted = true
            end
        end
    end

    gFrame:SetScript("OnEvent", function(_, event)
        if event == "GOSSIP_SHOW" then
            local _, gossipType = GetGossipOptions()
            if gossipType == "binder" or gossipType == "trainer" then return end
            if not IsShiftKeyDown() then
                SkipGossip(true)
            end
        elseif event == "GOSSIP_CLOSED" then
            isPrinted = false
        end
    end)

    local function ToggleGossip()
        if LeaPlusLC["AutomateGossip"] == "On" then
            gFrame:RegisterEvent("GOSSIP_SHOW")
            gFrame:RegisterEvent("GOSSIP_CLOSED")
        else
            gFrame:UnregisterAllEvents()
        end
    end

    if LeaPlusCB["AutomateGossip"] then
        LeaPlusCB["AutomateGossip"]:HookScript("OnClick", ToggleGossip)
    end
    ToggleGossip()
end

-- Summon & Resurrection
local function SetupSummonAndRes()
    local resFrame = CreateFrame("Frame")

    local function UpdateResEvents()
        if LeaPlusLC["AutoAcceptSummon"] == "On" then
            resFrame:RegisterEvent("CONFIRM_SUMMON")
        else
            resFrame:UnregisterEvent("CONFIRM_SUMMON")
        end
        if LeaPlusLC["AutoAcceptRes"] == "On" then
            resFrame:RegisterEvent("RESURRECT_REQUEST")
        else
            resFrame:UnregisterEvent("RESURRECT_REQUEST")
        end
    end

    local function IsGroupInCombat()
        if UnitAffectingCombat("player") then return true end
        local numRaid = GetNumRaidMembers()
        if numRaid > 0 then
            for i = 1, numRaid do
                if UnitAffectingCombat("raid" .. i) then return true end
            end
        else
            local numParty = GetNumPartyMembers()
            for i = 1, numParty do
                if UnitAffectingCombat("party" .. i) then return true end
            end
        end
        return false
    end

    resFrame:SetScript("OnEvent", function(_, event)
        if event == "CONFIRM_SUMMON" then
            if not UnitAffectingCombat("player") then
                local sName = GetSummonConfirmSummoner()
                local sLocation = GetSummonConfirmAreaName()
                local delay = LeaPlusLC["AutoAcceptSummonDelay"] or 10
                if delay == 0 then
                    ConfirmSummon()
                    StaticPopup_Hide("CONFIRM_SUMMON")
                else
                    LeaPlusLC:Print(string.format("Accepting summon from %s (%s) in %d seconds...", sName or "Unknown", sLocation or "Unknown", delay))
                    LibCompat.After(delay, function()
                        if not UnitAffectingCombat("player") and sName and sName == GetSummonConfirmSummoner() and StaticPopup_Visible("CONFIRM_SUMMON") then
                            ConfirmSummon()
                            StaticPopup_Hide("CONFIRM_SUMMON")
                        end
                    end)
                end
            end
        elseif event == "RESURRECT_REQUEST" then
            if not (LeaPlusLC["AutoResNoCombat"] == "On" and IsGroupInCombat()) then
                AcceptResurrect()
                StaticPopup_Hide("RESURRECT")
                StaticPopup_Hide("RESURRECT_NO_SICKNESS")
                StaticPopup_Hide("RESURRECT_NO_TIMER")
            end
        end
    end)

    if LeaPlusCB["AutoAcceptSummon"] then
        LeaPlusCB["AutoAcceptSummon"]:HookScript("OnClick", UpdateResEvents)
    end
    if LeaPlusCB["AutoAcceptRes"] then
        LeaPlusCB["AutoAcceptRes"]:HookScript("OnClick", UpdateResEvents)
    end

    UpdateResEvents()

    -- Dedicated Summon Panel
    local AcceptSummonPanel = LeaPlusLC:CreatePanel("Accept Summons Automatically", "AcceptSummonPanel")
    LeaPlusLC:MakeTx(AcceptSummonPanel, "Settings", 16, -72)
    LeaPlusLC:MakeSL(AcceptSummonPanel, "AutoAcceptSummonDelay", "Delay in seconds before automatically accepting a summon (set to 0 for instant).", 0, 10, 1, 16, -92, "%.0f sec")
    AcceptSummonPanel.h:Hide()
    AcceptSummonPanel.b:SetScript("OnClick", function()
        AcceptSummonPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page1"]:Show()
    end)
    AcceptSummonPanel.r:SetScript("OnClick", function()
        LeaPlusLC["AutoAcceptSummonDelay"] = 10
        AcceptSummonPanel:Hide(); AcceptSummonPanel:Show()
    end)

    if LeaPlusCB["AutoAcceptSummonBtn"] then
        LeaPlusCB["AutoAcceptSummonBtn"]:SetScript("OnClick", function()
            AcceptSummonPanel:Show(); LeaPlusLC:HideFrames()
        end)
    end

    -- Dedicated Resurrect Panel
    local AcceptResPanel = LeaPlusLC:CreatePanel("Accept Resurrection Automatically", "AcceptResPanel")
    LeaPlusLC:MakeTx(AcceptResPanel, "Settings", 16, -72)
    LeaPlusLC:MakeCB(AcceptResPanel, "AutoResNoCombat", "Exclude Combat Resurrection", 16, -92, false, "Prevent automatically accepting resurrections while you're in combat.")
    AcceptResPanel.h:Hide()
    AcceptResPanel.b:SetScript("OnClick", function()
        AcceptResPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page1"]:Show()
    end)
    AcceptResPanel.r:SetScript("OnClick", function()
        LeaPlusLC["AutoResNoCombat"] = "On"
        AcceptResPanel:Hide(); AcceptResPanel:Show()
    end)

    if LeaPlusCB["AutoAcceptResBtn"] then
        LeaPlusCB["AutoAcceptResBtn"]:SetScript("OnClick", function()
            AcceptResPanel:Show(); LeaPlusLC:HideFrames()
        end)
    end
end

-- Sell Junk & Repair
local function SetupAutoSellAndRepair()
    local whiteList = {}

    local function ParseWhiteList(text)
        wipe(whiteList)
        if text and text ~= "" then
            for itemID in string.gmatch(text, "(%d+)") do
                local id = tonumber(itemID)
                if id then whiteList[id] = true end
            end
        end
    end

    ParseWhiteList(LeaPlusLC["AutoSellExcludeList"])

    local sFrame = CreateFrame("Frame")
    local sellState = { active = false, totalPrice = 0, retries = 0 }

    local function SellJunkTick()
        if not sellState.active then return end
        if not MerchantFrame or not MerchantFrame:IsShown() or IsShiftKeyDown() then
            sellState.active = false
            return
        end
        local soldThisTick = 0
        local hasLockedJunk = false

        for bag = 0, 4 do
            for slot = 1, (GetContainerNumSlots(bag) or 0) do
                local itemID = GetContainerItemID(bag, slot)
                if itemID then
                    local _, _, rarity, _, _, _, _, _, _, _, itemPrice = GetItemInfo(itemID)
                    local _, itemCount, locked = GetContainerItemInfo(bag, slot)

                    if itemCount and itemPrice and itemPrice > 0 then
                        local isJunk = (rarity == 0 and not whiteList[itemID]) or (rarity == 1 and whiteList[itemID])
                        if isJunk then
                            if locked then
                                hasLockedJunk = true
                            else
                                sellState.totalPrice = sellState.totalPrice + (itemPrice * itemCount)
                                soldThisTick = soldThisTick + 1
                                UseContainerItem(bag, slot)
                                if soldThisTick >= 10 then
                                    LibCompat.After(0.2, SellJunkTick)
                                    return
                                end
                            end
                        end
                    end
                end
            end
        end

        if hasLockedJunk and sellState.retries < 30 then
            sellState.retries = sellState.retries + 1
            LibCompat.After(0.2, SellJunkTick)
            return
        end

        if sellState.totalPrice > 0 and LeaPlusLC["AutoSellShowSummary"] == "On" then
            LeaPlusLC:Print(L["Sold junk for"] .. " " .. GetCoinText(sellState.totalPrice) .. ".")
        end
        sellState.active = false
        sellState.retries = 0
    end

    local function SellJunk()
        if not sellState.active then
            sellState.active = true
            sellState.totalPrice = 0
            sellState.retries = 0
            SellJunkTick()
        end
    end

    -- Vendor refusal listener
    local vendorRefuseFrame = CreateFrame("Frame")
    local vendorRefuseText = ERR_VENDOR_DOESNT_BUY or "The merchant doesn't want that item."

    vendorRefuseFrame:SetScript("OnEvent", function(_, _, msg)
        if msg and (msg == vendorRefuseText or msg == 46) then
            sellState.active = false
        end
    end)

    sFrame:RegisterEvent("MERCHANT_SHOW")
    sFrame:RegisterEvent("MERCHANT_CLOSED")
    sFrame:SetScript("OnEvent", function(_, event)
        if event == "MERCHANT_SHOW" then
            vendorRefuseFrame:RegisterEvent("UI_ERROR_MESSAGE")
            if LeaPlusLC["AutoSellJunk"] == "On" then
                LibCompat.After(0.2, SellJunk)
            end
            if LeaPlusLC["AutoRepairGear"] == "On" and not IsShiftKeyDown() then
                local cost, canRepair = GetRepairAllCost()
                if canRepair and cost and cost > 0 then
                    local useGuild = (LeaPlusLC["AutoRepairGuildFunds"] == "On" and IsInGuild() and CanGuildBankRepair and CanGuildBankRepair())
                    if useGuild then
                        RepairAllItems(1)
                        RepairAllItems()
                    elseif GetMoney() >= cost then
                        RepairAllItems()
                    end

                    if LeaPlusLC["AutoRepairShowSummary"] == "On" then
                        LeaPlusLC:Print(L["Repaired for"] .. " " .. GetCoinText(cost) .. ".")
                    end
                end
            end
        elseif event == "MERCHANT_CLOSED" then
            vendorRefuseFrame:UnregisterEvent("UI_ERROR_MESSAGE")
            sellState.active = false
            sellState.totalPrice = 0
            sellState.retries = 0
        end
    end)

    local SellJunkFrame = LeaPlusLC:CreatePanel("Sell Junk Automatically", "SellJunkFrame")
    LeaPlusLC:MakeTx(SellJunkFrame, "Settings", 16, -72)
    LeaPlusLC:MakeCB(SellJunkFrame, "AutoSellShowSummary", "Show Vendor Summary in Chat", 16, -92, false, "Prints the total profit earned from selling junk items to the chat window.")
    LeaPlusLC:MakeTx(SellJunkFrame, "Exclusions", 16, -122)

    local eb = CreateFrame("Frame", nil, SellJunkFrame)
    eb:SetSize(340, 140)
    eb:SetPoint("TOPLEFT", 16, -142)
    eb:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight",
        edgeSize = 16,
        insets = { left = 8, right = 6, top = 8, bottom = 8 },
    })
    eb:SetBackdropBorderColor(1.0, 0.85, 0.0, 0.5)
    eb:EnableMouse(true)

    local function ShowExclusionsTip(self)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR", 4, 4)
        GameTooltip:SetText(L["Enter junk item IDs separated by commas."], nil, nil, nil, nil, true)
        GameTooltip:Show()
    end
    eb:SetScript("OnEnter", ShowExclusionsTip)
    eb:SetScript("OnLeave", GameTooltip_Hide)

    local scroll = CreateFrame("ScrollFrame", nil, eb)
    scroll:SetPoint("TOPLEFT", eb, 12, -10)
    scroll:SetPoint("BOTTOMRIGHT", eb, -30, 10)
    scroll:EnableMouse(true)
    scroll:SetScript("OnEnter", ShowExclusionsTip)
    scroll:SetScript("OnLeave", GameTooltip_Hide)

    local ExcludeBox = CreateFrame("EditBox", nil, scroll)
    ExcludeBox:SetMultiLine(true)
    ExcludeBox:SetAutoFocus(false)
    ExcludeBox:SetMaxLetters(600)
    ExcludeBox:SetFontObject(GameFontNormalLarge)
    ExcludeBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    ExcludeBox:SetWidth(scroll:GetWidth())
    ExcludeBox:SetHeight(200)
    ExcludeBox:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    scroll:SetScrollChild(ExcludeBox)
    ExcludeBox:EnableMouse(true)
    ExcludeBox:SetScript("OnEnter", ShowExclusionsTip)
    ExcludeBox:SetScript("OnLeave", GameTooltip_Hide)

    local function FocusExcludeBox()
        ExcludeBox:SetFocus()
        ExcludeBox:SetCursorPosition(ExcludeBox:GetMaxLetters())
    end

    eb:SetScript("OnMouseDown", FocusExcludeBox)
    scroll:SetScript("OnMouseDown", FocusExcludeBox)
    ExcludeBox:SetScript("OnMouseDown", FocusExcludeBox)

    local parseToken = 0
    ExcludeBox:SetScript("OnTextChanged", function(self, userInput)
        local t = self:GetText() or ""
        LeaPlusLC["AutoSellExcludeList"] = t
        if userInput then
            parseToken = parseToken + 1
            local current = parseToken
            LibCompat.After(0.3, function()
                if current == parseToken then
                    ParseWhiteList(t)
                end
            end)
        else
            ParseWhiteList(t)
        end
    end)
    ExcludeBox:HookScript("OnShow", function(self)
        local w = scroll:GetWidth()
        self:SetWidth((w and w > 0) and w or 298)
        self:SetText(LeaPlusLC["AutoSellExcludeList"] or "")
    end)

    SellJunkFrame.h:Hide()
    SellJunkFrame.b:SetScript("OnClick", function()
        SellJunkFrame:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page1"]:Show()
    end)
    SellJunkFrame.r:SetScript("OnClick", function()
        LeaPlusLC["AutoSellShowSummary"] = "On"
        LeaPlusLC["AutoSellExcludeList"] = ""
        ParseWhiteList("")
        if ExcludeBox then ExcludeBox:SetText("") end
        SellJunkFrame:Hide(); SellJunkFrame:Show()
    end)

    if LeaPlusCB["AutoSellJunkBtn"] then
        LeaPlusCB["AutoSellJunkBtn"]:SetScript("OnClick", function()
            SellJunkFrame:Show(); LeaPlusLC:HideFrames()
        end)
    end

    GameTooltip:HookScript("OnTooltipSetItem", function(self)
        if SellJunkFrame and SellJunkFrame:IsShown() then
            local _, link = self:GetItem()
            if link then
                local itemID = link:match("item:(%d+):")
                if itemID then
                    self:AddLine("Item ID: |cffffffff" .. itemID .. "|r")
                    self:Show()
                end
            end
        end
    end)

    local RepairPanel = LeaPlusLC:CreatePanel("Repair Gear Automatically", "RepairPanel")
    LeaPlusLC:MakeTx(RepairPanel, "Settings", 16, -72)
    LeaPlusLC:MakeCB(RepairPanel, "AutoRepairGuildFunds", "Use Guild Funds First", 16, -92, false, "Uses guild bank repair funds if allowed by guild rank, falling back to personal funds if unavailable.")
    LeaPlusLC:MakeCB(RepairPanel, "AutoRepairShowSummary", "Show Repair Cost in Chat", 16, -112, false, "Prints the total repair cost to the chat window when a repair occurs.")
    RepairPanel.h:Hide()
    RepairPanel.b:SetScript("OnClick", function()
        RepairPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page1"]:Show()
    end)
    RepairPanel.r:SetScript("OnClick", function()
        LeaPlusLC["AutoRepairGuildFunds"] = "On"
        LeaPlusLC["AutoRepairShowSummary"] = "On"
        RepairPanel:Hide(); RepairPanel:Show()
    end)

    if LeaPlusCB["AutoRepairBtn"] then
        LeaPlusCB["AutoRepairBtn"]:SetScript("OnClick", function()
            RepairPanel:Show(); LeaPlusLC:HideFrames()
        end)
    end
end

-- Release in PvP
local function SetupAutoReleasePvP()
    hooksecurefunc("StaticPopup_Show", function(sType)
        if sType == "DEATH" and LeaPlusLC["AutoReleasePvP"] == "On" then
            if (HasSoulstone and HasSoulstone()) or (CanUseSoulstone and CanUseSoulstone()) then
                return
            end

            local inInstance, instanceType = IsInInstance()
            if inInstance and instanceType == "pvp" then
                if LeaPlusLC["AutoReleaseNoAlterac"] == "On" then
                    local zone = GetRealZoneText()
                    local mapID = GetCurrentMapAreaID()
                    if zone == "Alterac Valley" or mapID == 401 or mapID == 1459 then
                        return
                    end
                end

                local delay = (LeaPlusLC["AutoReleaseDelay"] or 200) / 1000
                LibCompat.After(delay, function()
                    local dialog = StaticPopup_Visible("DEATH")
                    if dialog then
                        if LeaPlusLC["AutoReleaseShiftCancel"] == "On" and IsShiftKeyDown() then
                            LeaPlusLC:Print("Automatic release cancelled.")
                        else
                            local dialogFrame = type(dialog) == "string" and _G[dialog] or dialog
                            if dialogFrame then
                                StaticPopup_OnClick(dialogFrame, 1)
                            end
                        end
                    end
                end)
            end
        end
    end)

    local ReleasePanel = LeaPlusLC:CreatePanel("Release Spirit in Battlegrounds", "ReleasePanel")
    LeaPlusLC:MakeTx(ReleasePanel, "Settings", 16, -72)
    LeaPlusLC:MakeCB(ReleasePanel, "AutoReleaseNoAlterac", "Exclude Alterac Valley", 16, -92, false, "Disables automatic spirit release inside Alterac Valley.")
    LeaPlusLC:MakeCB(ReleasePanel, "AutoReleaseShiftCancel", "Cancel Release with Shift Key", 16, -112, false, "Cancels automatic spirit release if the Shift key is held while dead.")
    LeaPlusLC:MakeSL(ReleasePanel, "AutoReleaseDelay", "Delay before automatically releasing your spirit.", 0, 2000, 50, 16, -152, "%.0f ms")
    ReleasePanel.h:Hide()
    ReleasePanel.b:SetScript("OnClick", function()
        ReleasePanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page1"]:Show()
    end)
    ReleasePanel.r:SetScript("OnClick", function()
        LeaPlusLC["AutoReleaseNoAlterac"] = "Off"
        LeaPlusLC["AutoReleaseShiftCancel"] = "On"
        LeaPlusLC["AutoReleaseDelay"] = 200
        ReleasePanel:Hide(); ReleasePanel:Show()
    end)

    if LeaPlusCB["AutoReleasePvPBtn"] then
        LeaPlusCB["AutoReleasePvPBtn"]:SetScript("OnClick", function()
            ReleasePanel:Show(); LeaPlusLC:HideFrames()
        end)
    end
end

-- Faster Looting
local function SetupFasterLooting()
    if LeaPlusLC["FasterLooting"] ~= "On" then return end

    if LootFrame then
        LootFrame:UnregisterEvent("LOOT_OPENED")
    end

    local lootFrame = CreateFrame("Frame")
    lootFrame:SetScript("OnEvent", function(_, event, autoLoot)
        local isAuto = (autoLoot == 1 or GetCVarBool("autoLootDefault") ~= IsModifiedClick("AUTOLOOTTOGGLE"))
        local numItems = GetNumLootItems()

        if numItems > 0 and isAuto then
            for i = numItems, 1, -1 do
                LootSlot(i)
            end
        elseif numItems > 0 and not isAuto then
            if LootFrame_Show then
                LootFrame_Show(LootFrame)
            end
        end
    end)
    lootFrame:RegisterEvent("LOOT_OPENED")
end

-- Lifecycle
function Module:OnEnable()
    SetupAutomateQuests()
    SetupAutomateGossip()
    SetupSummonAndRes()
    SetupAutoSellAndRepair()
    SetupAutoReleasePvP()
    SetupFasterLooting()
end

function Module:OnLogin() end
function Module:OnLogout(wipeData) end