-- Automation.lua
local _, Leatrix_Plus = ...
local LeaPlusLC = Leatrix_Plus.LC
local LeaPlusCB = Leatrix_Plus.CB
local L = Leatrix_Plus.L

local Module = {}
Leatrix_Plus:RegisterModule("Automation", Module)

----------------------------------------------------------------------
-- 1. Automate Quests
----------------------------------------------------------------------
local function SetupAutomateQuests()
    local qFrame = CreateFrame("Frame")
    qFrame.completedQuests = {}
    qFrame.uncompletedQuests = {}

    local function IsOverrideKeyDown()
        if LeaPlusLC["AutoQuestKeyMenu"] == 1 and IsShiftKeyDown()
                or LeaPlusLC["AutoQuestKeyMenu"] == 2 and IsAltKeyDown()
                or LeaPlusLC["AutoQuestKeyMenu"] == 3 and IsControlKeyDown() then
            return true
        end
        return false
    end

    local function CanAutomate()
        if LeaPlusLC["AutoQuestCompleted"] == "Off"
                or (LeaPlusLC["AutoQuestShift"] == "On" and not IsOverrideKeyDown())
                or (LeaPlusLC["AutoQuestShift"] == "Off" and IsOverrideKeyDown()) then
            return false
        end
        return true
    end

    local function StripQuestText(text)
        if not text then return "" end
        text = text:gsub('|c%x%x%x%x%x%x%x%x(.-)|r', '%1')
        text = text:gsub('%[.*%]%s*', '')
        text = text:gsub('(.+) %(.+%)', '%1')
        return strtrim(text)
    end

    qFrame:SetScript("OnEvent", function(self, event)
        if not CanAutomate() then return end

        if event == "QUEST_PROGRESS" then
            if IsQuestCompletable() then
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
                if not isHeader and title then
                    local noObjectives = (GetNumQuestLeaderBoards(i) == 0)
                    if isComplete or noObjectives then
                        self.completedQuests[title] = true
                    else
                        self.uncompletedQuests[title] = true
                    end
                end
            end
            SelectQuestLogEntry(startEntry)
        elseif event == "GOSSIP_SHOW" then
            for i = 1, 32 do
                local btn = _G['GossipTitleButton' .. i]
                if btn and btn:IsVisible() then
                    local text = StripQuestText(btn:GetText())
                    if btn.type == 'Available' and LeaPlusLC["AutoQuestAvailable"] == "On" then
                        btn:Click()
                    elseif btn.type == 'Active' and LeaPlusLC["AutoQuestCompleted"] == "On" and self.completedQuests[text] then
                        btn:Click()
                    end
                end
            end
        elseif event == "QUEST_GREETING" then
            for i = 1, 32 do
                local btn = _G['QuestTitleButton' .. i]
                if btn and btn:IsVisible() then
                    local text = StripQuestText(btn:GetText())
                    if LeaPlusLC["AutoQuestCompleted"] == "On" and self.completedQuests[text] then
                        btn:Click()
                    elseif LeaPlusLC["AutoQuestAvailable"] == "On" and not self.uncompletedQuests[text] then
                        btn:Click()
                    end
                end
            end
        elseif event == "QUEST_DETAIL" then
            if LeaPlusLC["AutoQuestAvailable"] == "On" then
                AcceptQuest()
            end
        elseif event == "QUEST_COMPLETE" then
            if LeaPlusLC["AutoQuestCompleted"] == "On" then
                local choices = GetNumQuestChoices()
                if choices == 0 then
                    GetQuestReward(0)
                elseif choices == 1 then
                    GetQuestReward(1)
                end
            end
        end
    end)

    local function UpdateQuestEvents()
        if LeaPlusLC["AutomateQuests"] == "On" then
            qFrame:RegisterEvent('GOSSIP_SHOW')
            qFrame:RegisterEvent('QUEST_COMPLETE')
            qFrame:RegisterEvent('QUEST_DETAIL')
            qFrame:RegisterEvent('QUEST_FINISHED')
            qFrame:RegisterEvent('QUEST_GREETING')
            qFrame:RegisterEvent('QUEST_LOG_UPDATE')
            qFrame:RegisterEvent('QUEST_PROGRESS')
        else
            qFrame:UnregisterAllEvents()
        end
    end

    LeaPlusCB["AutomateQuests"]:HookScript("OnClick", UpdateQuestEvents)
    UpdateQuestEvents()

    -- Config Panel
    local QuestPanel = LeaPlusLC:CreatePanel("Automate quests", "QuestPanel")
    LeaPlusLC:MakeTx(QuestPanel, "Settings", 16, -72)
    LeaPlusLC:MakeCB(QuestPanel, "AutoQuestAvailable", "Accept available quests automatically", 16, -92, false, "If checked, available quests will be accepted automatically.")
    LeaPlusLC:MakeCB(QuestPanel, "AutoQuestCompleted", "Turn-in completed quests automatically", 16, -112, false, "If checked, completed quests will be turned-in automatically.")
    LeaPlusLC:MakeCB(QuestPanel, "AutoQuestShift", "Require override key for quest automation", 16, -132, false, "If checked, you will need to hold the override key down for quests to be automated.")
    LeaPlusLC:CreateDropDown("AutoQuestKeyMenu", "Override key", QuestPanel, 146, "TOPLEFT", 356, -115, { L["SHIFT"], L["ALT"], L["CONTROL"] }, "")
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
    LeaPlusCB["AutomateQuestsBtn"]:SetScript("OnClick", function()
        QuestPanel:Show(); LeaPlusLC:HideFrames(); UpdateQuestEvents()
    end)
end

----------------------------------------------------------------------
-- 2. Automate Gossip
----------------------------------------------------------------------
local function SetupAutomateGossip()
    local gFrame = CreateFrame("Frame")
    local isPrinted = false

    local function SkipGossip(skipAlt)
        if not skipAlt and not IsAltKeyDown() then return end
        if GetNumGossipOptions() > 0 and GetNumGossipAvailableQuests() == 0 and GetNumGossipActiveQuests() == 0 then
            SelectGossipOption(1)
            if not isPrinted then
                print("|cFF00ff99Leatrix Plus:|r option chosen. Hold Shift to override.")
                isPrinted = true
            end
        end
    end

    gFrame:SetScript("OnEvent", function(self, event)
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

    LeaPlusCB["AutomateGossip"]:HookScript("OnClick", ToggleGossip)
    ToggleGossip()
end

----------------------------------------------------------------------
-- 3. Auto Sell Junk & Repair
----------------------------------------------------------------------
local function SetupAutoSellAndRepair()
    local whiteList = {}
    local isUpdatingList = false

    local function ParseWhiteList(text)
        wipe(whiteList)
        if text and text ~= "" then
            text = text:gsub("[^,%d]", "")
            for itemID in string.gmatch(text, "(%d+)") do
                whiteList[tonumber(itemID)] = true
            end
        end
    end

    ParseWhiteList(LeaPlusLC["AutoSellExcludeList"])

    -- Vendor Junk
    local sFrame = CreateFrame("Frame")
    local totalPrice = 0

    local function SellJunk()
        if not MerchantFrame:IsShown() or IsShiftKeyDown() then return end
        totalPrice = 0
        local soldCount = 0

        for bag = 0, 4 do
            for slot = 1, (GetContainerNumSlots(bag) or 0) do
                local itemID = GetContainerItemID(bag, slot)
                if itemID then
                    local _, _, rarity, _, _, _, _, _, _, _, itemPrice = GetItemInfo(itemID)
                    local _, itemCount, locked = GetContainerItemInfo(bag, slot)

                    if not locked and itemCount and itemPrice and itemPrice > 0 then
                        local isJunk = (rarity == 0 and not whiteList[itemID]) or (rarity == 1 and whiteList[itemID])
                        if isJunk then
                            totalPrice = totalPrice + (itemPrice * itemCount)
                            soldCount = soldCount + 1
                            UseContainerItem(bag, slot)
                        end
                    end
                end
            end
        end

        if soldCount > 0 and totalPrice > 0 and LeaPlusLC["AutoSellShowSummary"] == "On" then
            LeaPlusLC:Print(L["Sold junk for"] .. " " .. GetCoinText(totalPrice) .. ".")
        end
    end

    sFrame:SetScript("OnEvent", function(self, event)
        if event == "MERCHANT_SHOW" then
            if LeaPlusLC["AutoSellJunk"] == "On" then
                LibCompat.After(0.2, SellJunk)
            end
            if LeaPlusLC["AutoRepairGear"] == "On" and CanMerchantRepair() and not IsShiftKeyDown() then
                local cost, canRepair = GetRepairAllCost()
                if canRepair and cost > 0 then
                    if LeaPlusLC["AutoRepairGuildFunds"] == "On" and IsInGuild() and CanGuildBankRepair() then
                        RepairAllItems(1)
                    end
                    if GetRepairAllCost() > 0 then
                        RepairAllItems()
                    end
                    if LeaPlusLC["AutoRepairShowSummary"] == "On" then
                        LeaPlusLC:Print(L["Repaired for"] .. " " .. GetCoinText(cost) .. ".")
                    end
                end
            end
        end
    end)

    sFrame:RegisterEvent("MERCHANT_SHOW")
end

----------------------------------------------------------------------
-- 4. Auto Release in PvP
----------------------------------------------------------------------
local function SetupAutoReleasePvP()
    hooksecurefunc("StaticPopup_Show", function(sType)
        if sType == "DEATH" and LeaPlusLC["AutoReleasePvP"] == "On" then
            if HasSoulstone and HasSoulstone() then return end
            local inInstance, instanceType = IsInInstance()
            if inInstance and instanceType == "pvp" then
                if LeaPlusLC["AutoReleaseNoAlterac"] == "On" then
                    local zone = GetZoneText()
                    if zone == "Alterac Valley" or GetCurrentMapAreaID() == 401 then
                        return
                    end
                end

                local delay = (LeaPlusLC["AutoReleaseDelay"] or 200) / 1000
                LibCompat.After(delay, function()
                    local dialog = StaticPopup_Visible("DEATH")
                    if dialog then
                        if LeaPlusLC["AutoReleaseShiftCancel"] == "On" and IsShiftKeyDown() then
                            ActionStatus_DisplayMessage(L["Automatic Release Cancelled"], true)
                        else
                            StaticPopup_OnClick(_G[dialog], 1)
                        end
                    end
                end)
            end
        end
    end)
end

----------------------------------------------------------------------
-- 5. Faster Looting (3.3.5 Native)
----------------------------------------------------------------------
local function SetupFasterLooting()
    if LeaPlusLC["FasterLooting"] ~= "On" then return end

    local lootFrame = CreateFrame("Frame")
    lootFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "LOOT_OPENED" then
            local autoLoot = ...
            if autoLoot == 1 or GetCVarBool("autoLootDefault") ~= IsModifiedClick("AUTOLOOTTOGGLE") then
                local numItems = GetNumLootItems()
                if numItems > 0 then
                    for i = numItems, 1, -1 do
                        LootSlot(i)
                    end
                end
            end
        end
    end)
    lootFrame:RegisterEvent("LOOT_OPENED")
end

----------------------------------------------------------------------
-- Lifecycle Hooks
----------------------------------------------------------------------
function Module:OnEnable()
    SetupAutomateQuests()
    SetupAutomateGossip()
    SetupAutoSellAndRepair()
    SetupAutoReleasePvP()
    SetupFasterLooting()
end

function Module:OnLogin()
    -- Reserved for post-login automation checks
end

function Module:OnLogout(wipeData)
    -- Reserved for session persistence
end