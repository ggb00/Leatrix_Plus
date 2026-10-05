-- Interface.lua
local _, Leatrix_Plus = ...
local LeaPlusLC = Leatrix_Plus.LC
local LeaPlusCB = Leatrix_Plus.CB
local LeaLockList = Leatrix_Plus.LockList
local L = Leatrix_Plus.L

local Module = {}
Leatrix_Plus:RegisterModule("Interface", Module)

-- Durability status
local DURABILITY_SLOTS = {
    { slot = "HeadSlot",           name = "Head" },
    { slot = "ShoulderSlot",       name = "Shoulders" },
    { slot = "ChestSlot",          name = "Chest" },
    { slot = "WristSlot",          name = "Wrist" },
    { slot = "HandsSlot",          name = "Hands" },
    { slot = "WaistSlot",          name = "Waist" },
    { slot = "LegsSlot",           name = "Legs" },
    { slot = "FeetSlot",           name = "Feet" },
    { slot = "MainHandSlot",       name = "Main Hand" },
    { slot = "SecondaryHandSlot",  name = "Off Hand" },
    { slot = "RangedSlot",         name = "Ranged" },
}

for i = 1, #DURABILITY_SLOTS do
    DURABILITY_SLOTS[i].id = GetInventorySlotInfo(DURABILITY_SLOTS[i].slot)
end

local function GetTotalDurability()
    local curTotal, maxTotal = 0, 0
    for i = 1, #DURABILITY_SLOTS do
        local slotID = DURABILITY_SLOTS[i].id
        if slotID then
            local cur, maxDura = GetInventoryItemDurability(slotID)
            if cur and maxDura and maxDura > 0 then
                curTotal = curTotal + cur
                maxTotal = maxTotal + maxDura
            end
        end
    end
    return maxTotal > 0 and (curTotal / maxTotal * 100) or 100
end

local function ColorForPct(pct)
    if pct >= 80 then return 0, 1, 0
    elseif pct >= 60 then return 0.5, 1, 0
    elseif pct >= 40 then return 1, 1, 0
    elseif pct >= 20 then return 1, 0.5, 0
    else return 1, 0, 0
    end
end

local function SetupDurabilityStatus()
    if not PaperDollFrame then return end

    if not PaperDollFrame.__leaDuraBtn then
        local duraBtn = CreateFrame("Button", "LeaDurabilityButton", PaperDollFrame)
        PaperDollFrame.__leaDuraBtn = duraBtn
        duraBtn:SetFrameStrata("HIGH")
        duraBtn:SetSize(32, 32)
        duraBtn:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -40, 80)
        duraBtn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
        duraBtn:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
        duraBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")

        duraBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 4, 0)
            GameTooltip:AddLine(L["Durability"], 1, 0.82, 0, 1)

            local anyShown = false
            for i = 1, #DURABILITY_SLOTS do
                local entry = DURABILITY_SLOTS[i]
                local slotID = entry.id
                if slotID then
                    local cur, maxDura = GetInventoryItemDurability(slotID)
                    if cur and maxDura and maxDura > 0 then
                        local pct = cur / maxDura * 100
                        local r, g, b = ColorForPct(pct)
                        GameTooltip:AddDoubleLine(entry.name, string.format("%.0f%%", pct),
                            1, 1, 1, r, g, b)
                        anyShown = true
                    end
                end
            end

            if anyShown then
                local overall = GetTotalDurability()
                local r, g, b = ColorForPct(overall)
                GameTooltip:AddLine(" ", 1, 1, 1)
                GameTooltip:AddDoubleLine(L["Overall"] or "Overall", string.format("%.0f%%", overall),
                    1, 0.82, 0, r, g, b)
            else
                GameTooltip:AddLine(L["No items with durability equipped."], 1, 1, 1)
            end

            GameTooltip:Show()
        end)
        duraBtn:SetScript("OnLeave", GameTooltip_Hide)
    end

    if not PaperDollFrame.__leaDuraDeath then
        local dDeath = CreateFrame("Frame")
        PaperDollFrame.__leaDuraDeath = dDeath
        local lastDeathPrint = 0
        dDeath:RegisterEvent("PLAYER_DEAD")
        dDeath:SetScript("OnEvent", function()
            local now = GetTime()
            if LeaPlusLC["DurabilityStatus"] == "On" and (now - lastDeathPrint > 5) then
                lastDeathPrint = now
                LeaPlusLC:Print(L["You have"] .. string.format(" %.0f%% ", GetTotalDurability()) .. L["durability"] .. ".")
            end
        end)
    end

    if LeaPlusCB["DurabilityStatus"] and not LeaPlusCB["DurabilityStatus"].__leaHooked then
        LeaPlusCB["DurabilityStatus"].__leaHooked = true
        LeaPlusCB["DurabilityStatus"]:HookScript("OnClick", function()
            if PaperDollFrame.__leaDuraBtn then
                if LeaPlusLC["DurabilityStatus"] == "On" then
                    PaperDollFrame.__leaDuraBtn:Show()
                else
                    PaperDollFrame.__leaDuraBtn:Hide()
                end
            end
        end)
    end

    if LeaPlusLC["DurabilityStatus"] == "On" then
        PaperDollFrame.__leaDuraBtn:Show()
    else
        PaperDollFrame.__leaDuraBtn:Hide()
    end
end

-- Vanity controls (helm / cloak)
local function SetupVanityControls()
    if not PaperDollFrame then return end

    if not PaperDollFrame.__leaHelmCB then
        local helm = CreateFrame("CheckButton", nil, PaperDollFrame, "UICheckButtonTemplate")
        PaperDollFrame.__leaHelmCB = helm
        helm:SetFrameStrata("HIGH")
        helm:SetFrameLevel(PaperDollFrame:GetFrameLevel() + 10)
        helm:SetSize(24, 24)
        helm:SetHitRectInsets(-4, -70, -4, -4)

        helm.label = helm:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        helm.label:SetPoint("LEFT", helm, "RIGHT", 0, 0)
        helm.label:SetText(L["Helm"])

        helm:SetScript("OnShow", function(self)
            self:SetChecked(ShowingHelm() and true or false)
        end)
        helm:SetScript("OnClick", function(self)
            ShowHelm(self:GetChecked() and true or false)
        end)

        local cloak = CreateFrame("CheckButton", nil, PaperDollFrame, "UICheckButtonTemplate")
        PaperDollFrame.__leaCloakCB = cloak
        cloak:SetFrameStrata("HIGH")
        cloak:SetFrameLevel(PaperDollFrame:GetFrameLevel() + 10)
        cloak:SetSize(24, 24)
        cloak:SetPoint("TOPLEFT", helm, "BOTTOMLEFT", 0, -2)
        cloak:SetHitRectInsets(-4, -70, -4, -4)

        cloak.label = cloak:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        cloak.label:SetPoint("LEFT", cloak, "RIGHT", 0, 0)
        cloak.label:SetText(L["Cloak"])

        cloak:SetScript("OnShow", function(self)
            self:SetChecked(ShowingCloak() and true or false)
        end)
        cloak:SetScript("OnClick", function(self)
            ShowCloak(self:GetChecked() and true or false)
        end)

        helm:ClearAllPoints()
        helm:SetPoint("TOPLEFT", PaperDollFrame, "TOPLEFT", 66, -110)
        cloak:ClearAllPoints()
        cloak:SetPoint("TOPLEFT", helm, "BOTTOMLEFT", 0, -2)
    end

    local function SyncVanity()
        if PaperDollFrame.__leaHelmCB and PaperDollFrame.__leaHelmCB:IsShown() then
            PaperDollFrame.__leaHelmCB:SetChecked(ShowingHelm() and true or false)
        end
        if PaperDollFrame.__leaCloakCB and PaperDollFrame.__leaCloakCB:IsShown() then
            PaperDollFrame.__leaCloakCB:SetChecked(ShowingCloak() and true or false)
        end
    end

    if not PaperDollFrame.__leaVanityInvHooked then
        PaperDollFrame.__leaVanityInvHooked = true
        local vFrame = CreateFrame("Frame")
        vFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
        vFrame:SetScript("OnEvent", function(_, _, unit)
            if unit == "player" then SyncVanity() end
        end)
    end

    if not PaperDollFrame.__leaVanityHooked then
        PaperDollFrame.__leaVanityHooked = true
        hooksecurefunc("ShowHelm", SyncVanity)
        hooksecurefunc("ShowCloak", SyncVanity)
    end

    if LeaPlusCB["ShowVanityControls"] and not LeaPlusCB["ShowVanityControls"].__leaHooked then
        LeaPlusCB["ShowVanityControls"].__leaHooked = true
        LeaPlusCB["ShowVanityControls"]:HookScript("OnClick", function()
            local show = (LeaPlusLC["ShowVanityControls"] == "On")
            if PaperDollFrame.__leaHelmCB then
                if show and LeaPlusLC["HideDressupStats"] ~= "On" then
                    PaperDollFrame.__leaHelmCB:Show()
                    PaperDollFrame.__leaCloakCB:Show()
                else
                    PaperDollFrame.__leaHelmCB:Hide()
                    PaperDollFrame.__leaCloakCB:Hide()
                end
            end
        end)
    end

    if LeaPlusLC["ShowVanityControls"] == "On" and LeaPlusLC["HideDressupStats"] ~= "On" then
        PaperDollFrame.__leaHelmCB:Show()
        PaperDollFrame.__leaCloakCB:Show()
        SyncVanity()
    else
        PaperDollFrame.__leaHelmCB:Hide()
        PaperDollFrame.__leaCloakCB:Hide()
    end
end

-- Show Player Chain
local function SetupPlayerChain()
    if PetPortrait and PetPortrait:GetParent() then
        PetPortrait:GetParent():SetFrameLevel(4)
    end

    local function SetChainStyle()
        if UnitHasVehicleUI and UnitHasVehicleUI("player") then return end
        if not PlayerFrameTexture then return end

        local isEnhanced = (LeaPlusLC["EnhanceUnitFrames"] == "On" and not LeaLockList["EnhanceUnitFrames"])
        local assetPrefix = isEnhanced and "Interface\\AddOns\\Leatrix_Plus\\Assets\\" or "Interface\\TargetingFrame\\"

        if LeaPlusLC["ShowPlayerChain"] ~= "On" or LeaLockList["ShowPlayerChain"] then
            PlayerFrameTexture:SetTexture(assetPrefix .. "UI-TargetingFrame")
            PlayerFrameTexture:SetTexCoord(1.0, 0.09375, 0.0, 0.78125)
            PlayerFrameTexture:SetVertexColor(1.0, 1.0, 1.0, 1.0)
            return
        end

        local chain = LeaPlusLC["PlayerChainMenu"] or 1
        if chain == 1 then
            -- Rare (Silver dragon)
            PlayerFrameTexture:SetTexture(assetPrefix .. "UI-TargetingFrame-Rare")
            PlayerFrameTexture:SetTexCoord(1.0, 0.09375, 0.0, 0.78125)
        elseif chain == 2 then
            -- Elite (Gold dragon)
            PlayerFrameTexture:SetTexture(assetPrefix .. "UI-TargetingFrame-Elite")
            PlayerFrameTexture:SetTexCoord(1.0, 0.09375, 0.0, 0.78125)
        elseif chain == 3 then
            -- Rare Elite (Winged dragon)
            if isEnhanced then
                PlayerFrameTexture:SetTexture(assetPrefix .. "UI-TargetingFrame-Rare-Elite")
                PlayerFrameTexture:SetTexCoord(1.0, 0.09375, 0.0, 0.78125)
            else
                PlayerFrameTexture:SetTexture("Interface\\AddOns\\Leatrix_Plus\\Assets\\Leatrix_Plus")
                PlayerFrameTexture:SetTexCoord(0.25, 0.0234375, 0.0, 0.1953125)
            end
        end
        PlayerFrameTexture:SetVertexColor(1.0, 1.0, 1.0, 1.0)
    end

    if not LeaPlusLC.__leaChainHooked then
        LeaPlusLC.__leaChainHooked = true
        if PlayerFrame_ToPlayerArt then
            hooksecurefunc("PlayerFrame_ToPlayerArt", SetChainStyle)
        end
        if PlayerFrame_UpdateArt then
            hooksecurefunc("PlayerFrame_UpdateArt", SetChainStyle)
        end
    end

    if LeaPlusCB["ShowPlayerChain"] then
        LeaPlusCB["ShowPlayerChain"]:HookScript("OnClick", SetChainStyle)
    end

    local ChainPanel = LeaPlusLC:CreatePanel("Player Chain", "ChainPanel")
    LeaPlusLC:MakeTx(ChainPanel, "Settings", 16, -72)
    local chainDrop = LeaPlusLC:CreateDropDown("PlayerChainMenu", "Chain Style", ChainPanel, 160, "TOPLEFT", 16, -145,
        { L["Rare"], L["Elite"], L["Rare Elite"] }, "Select the style of dragon chain displayed around your character frame.")

    chainDrop.OnSelect = function()
        SetChainStyle()
    end

    ChainPanel.h:Hide()
    ChainPanel.b:SetScript("OnClick", function()
        ChainPanel:Hide()
        LeaPlusLC["PageF"]:Show()
        LeaPlusLC["Page5"]:Show()
    end)

    ChainPanel.r:SetScript("OnClick", function()
        LeaPlusLC["PlayerChainMenu"] = 1
        SetChainStyle()
        ChainPanel:Hide()
        ChainPanel:Show()
    end)

    if LeaPlusCB["ShowPlayerChainBtn"] then
        LeaPlusCB["ShowPlayerChainBtn"]:SetScript("OnClick", function()
            ChainPanel:Show()
            LeaPlusLC:HideFrames()
        end)
    end

    SetChainStyle()
end

-- Enhance trainers
local function SetupEnhanceTrainers()
    local TrainerPanel = LeaPlusLC:CreatePanel("Double-Wide Class Trainers", "TrainerPanel")
    LeaPlusLC:MakeTx(TrainerPanel, "Settings", 16, -72)
    LeaPlusLC:MakeCB(TrainerPanel, "ShowTrainAllBtn", "Show Train All Button", 16, -92, false, "Adds a Train All button to the class trainer window to purchase all available skills at once.")
    TrainerPanel.h:Hide()
    TrainerPanel.b:SetScript("OnClick", function()
        TrainerPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page5"]:Show()
    end)
    TrainerPanel.r:SetScript("OnClick", function()
        LeaPlusLC["ShowTrainAllBtn"] = "On"
        TrainerPanel:Hide(); TrainerPanel:Show()
    end)
    if LeaPlusCB["EnhanceTrainersBtn"] then
        LeaPlusCB["EnhanceTrainersBtn"]:SetScript("OnClick", function()
            TrainerPanel:Show(); LeaPlusLC:HideFrames()
        end)
    end

    if LeaPlusLC["EnhanceTrainers"] ~= "On" then return end

    local tall = 73
    local MAX_TRAINER_SKILLS = 23

    local trainerHooksInstalled = false
    local function ApplyTrainer()
        if not ClassTrainerFrame or ClassTrainerFrame.__leaApplied then return end
        ClassTrainerFrame.__leaApplied = true

        -- Unlock SetHeight if an external skin locked it
        if ClassTrainerListScrollFrame then ClassTrainerListScrollFrame.SetHeight = nil end
        if ClassTrainerDetailScrollFrame then ClassTrainerDetailScrollFrame.SetHeight = nil end

        -- Make the frame double-wide in UIPanelWindows
        UIPanelWindows["ClassTrainerFrame"] = {
            area = "override", pushable = 0, xoffset = 0, yoffset = 12,
            bottomClampOverride = 140 + 12, width = 714, height = 487, whileDead = 1,
        }

        ClassTrainerFrame:SetSize(714, 487 + tall)

        if ClassTrainerNameText then
            ClassTrainerNameText:ClearAllPoints()
            ClassTrainerNameText:SetPoint("TOP", ClassTrainerFrame, "TOP", 0, -18)
        end

        ClassTrainerListScrollFrame:ClearAllPoints()
        ClassTrainerListScrollFrame:SetPoint("TOPLEFT", ClassTrainerFrame, "TOPLEFT", 25, -75)
        ClassTrainerListScrollFrame:SetSize(295, 336 + tall)

        -- Expand skill rows up to MAX_TRAINER_SKILLS (23)
        do
            local oldSkillsDisplayed = CLASS_TRAINER_SKILLS_DISPLAYED or 11
            for i = 2, oldSkillsDisplayed do
                local btn = _G["ClassTrainerSkill" .. i]
                if btn then
                    btn:ClearAllPoints()
                    btn:SetPoint("TOPLEFT", _G["ClassTrainerSkill" .. (i - 1)], "BOTTOMLEFT", 0, 1)
                end
            end

            for i = oldSkillsDisplayed + 1, MAX_TRAINER_SKILLS do
                local button = _G["ClassTrainerSkill" .. i]
                if not button then
                    button = CreateFrame("Button", "ClassTrainerSkill" .. i, ClassTrainerFrame, "ClassTrainerSkillButtonTemplate")
                    button:SetID(i)
                    button:Hide()
                end
                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", _G["ClassTrainerSkill" .. (i - 1)], "BOTTOMLEFT", 0, 1)
            end

            _G.CLASS_TRAINER_SKILLS_DISPLAYED = MAX_TRAINER_SKILLS

            local function UpdateTrainerSkillsCount()
                _G.CLASS_TRAINER_SKILLS_DISPLAYED = MAX_TRAINER_SKILLS
                ClassTrainerListScrollFrame:SetHeight(336 + tall)
                ClassTrainerDetailScrollFrame:SetHeight(336 + tall)
            end

            if not trainerHooksInstalled then
                trainerHooksInstalled = true
                hooksecurefunc("ClassTrainer_SetToTradeSkillTrainer", UpdateTrainerSkillsCount)
                hooksecurefunc("ClassTrainer_SetToClassTrainer", UpdateTrainerSkillsCount)
            end

            hooksecurefunc("ClassTrainerFrame_Update", function()
                _G.CLASS_TRAINER_SKILLS_DISPLAYED = MAX_TRAINER_SKILLS
                for i = 1, MAX_TRAINER_SKILLS do
                    local skillBtn = _G["ClassTrainerSkill" .. i]
                    if skillBtn then skillBtn:SetWidth(293) end
                end
                local extraIndex = MAX_TRAINER_SKILLS + 1
                while _G["ClassTrainerSkill" .. extraIndex] do
                    _G["ClassTrainerSkill" .. extraIndex]:Hide()
                    extraIndex = extraIndex + 1
                end
            end)
        end

        if _G["ClassTrainerSkillHighlightFrame"] then
            hooksecurefunc(_G["ClassTrainerSkillHighlightFrame"], "Show", function(self)
                self:SetWidth(290)
            end)
        end

        ClassTrainerDetailScrollFrame:ClearAllPoints()
        ClassTrainerDetailScrollFrame:SetPoint("TOPLEFT", ClassTrainerFrame, "TOPLEFT", 352, -74)
        ClassTrainerDetailScrollFrame:SetSize(296, 336 + tall)

        if ClassTrainerDetailScrollFrameTop then ClassTrainerDetailScrollFrameTop:SetAlpha(0) end
        if ClassTrainerDetailScrollFrameBottom then ClassTrainerDetailScrollFrameBottom:SetAlpha(0) end
        if ClassTrainerExpandTabLeft then ClassTrainerExpandTabLeft:Hide() end

        -- Slices from Assets/Leatrix_Plus.blp
        local regions = { ClassTrainerFrame:GetRegions() }
        local texPath = "Interface\\AddOns\\Leatrix_Plus\\Assets\\Leatrix_Plus"

        if regions[2] and regions[2].SetTexture then
            regions[2]:SetTexture(texPath)
            regions[2]:SetTexCoord(0.25, 0.75, 0, 1)
            regions[2]:SetSize(512, 512)
        end

        if regions[3] and regions[3].SetTexture and regions[2] then
            regions[3]:ClearAllPoints()
            regions[3]:SetPoint("TOPLEFT", regions[2], "TOPRIGHT", 0, 0)
            regions[3]:SetTexture(texPath)
            regions[3]:SetTexCoord(0.75, 1, 0, 1)
            regions[3]:SetSize(256, 512)
        end

        if regions[4] and regions[4].Hide then regions[4]:Hide() end
        if regions[5] and regions[5].Hide then regions[5]:Hide() end
        if regions[9] and regions[9].Hide then regions[9]:Hide() end
        if ClassTrainerHorizontalBarLeft then ClassTrainerHorizontalBarLeft:Hide() end

        -- Insets
        local recipeInset = ClassTrainerFrame:CreateTexture(nil, "ARTWORK")
        recipeInset:SetSize(304, 361 + tall)
        recipeInset:SetPoint("TOPLEFT", ClassTrainerFrame, "TOPLEFT", 16, -72)
        recipeInset:SetTexture("Interface\\RAIDFRAME\\UI-RaidFrame-GroupBg")

        local detailsInset = ClassTrainerFrame:CreateTexture(nil, "ARTWORK")
        detailsInset:SetSize(302, 339 + tall)
        detailsInset:SetPoint("TOPLEFT", ClassTrainerFrame, "TOPLEFT", 348, -72)
        detailsInset:SetTexture("Interface\\AddOns\\Leatrix_Plus\\Assets\\ui-guildachievement-parchment-horizontal-desaturated.blp")

        ClassTrainerTrainButton:ClearAllPoints()
        ClassTrainerTrainButton:SetPoint("RIGHT", ClassTrainerCancelButton, "LEFT", -1, 0)

        ClassTrainerCancelButton:SetSize(80, 22)
        ClassTrainerCancelButton:SetText(CLOSE)
        ClassTrainerCancelButton:ClearAllPoints()
        ClassTrainerCancelButton:SetPoint("BOTTOMRIGHT", ClassTrainerFrame, "BOTTOMRIGHT", -42, 54)

        ClassTrainerFrameCloseButton:ClearAllPoints()
        ClassTrainerFrameCloseButton:SetPoint("TOPRIGHT", ClassTrainerFrame, "TOPRIGHT", -30, -8)

        if ClassTrainerFrameFilterDropDown then
            ClassTrainerFrameFilterDropDown:ClearAllPoints()
            ClassTrainerFrameFilterDropDown:SetPoint("TOPLEFT", ClassTrainerFrame, "TOPLEFT", 501, -40)
        end

        if ClassTrainerMoneyFrame then
            ClassTrainerMoneyFrame:ClearAllPoints()
            ClassTrainerMoneyFrame:SetPoint("TOPLEFT", ClassTrainerFrame, "TOPLEFT", 143, -49)
        end
        if ClassTrainerGreetingText then ClassTrainerGreetingText:Hide() end

        -- Train All button & smart cost calculation
        local trainAllBtn = LeaPlusLC:CreateButton("TrainAllButton", ClassTrainerFrame, "Train All", "BOTTOMLEFT", 344, 54, 100, 22, false, "")
        _G.LeaPlusGlobalTrainAllButton = trainAllBtn

        local cachedCount, cachedCost = 0, 0
        local isSilentScanning = false

        local function CalculateTotalTrainerCost()
            if isSilentScanning then return end

            local unavailFilter = (GetTrainerServiceTypeFilter("unavailable") == 1)
            if not unavailFilter then
                isSilentScanning = true
                SetTrainerServiceTypeFilter("unavailable", 1)
            end

            local count, cost = 0, 0
            local playerLevel = UnitLevel("player")
            local isTrade = IsTradeskillTrainer and IsTradeskillTrainer()

            local learnableSpells = {}
            for i = 1, GetNumTrainerServices() do
                local serviceName, _, serviceType = GetTrainerServiceInfo(i)
                if serviceName and serviceType == "available" then
                    learnableSpells[serviceName] = true
                end
            end

            for i = 1, GetNumTrainerServices() do
                local serviceName, _, serviceType = GetTrainerServiceInfo(i)
                if serviceName and serviceType ~= "header" and serviceType ~= "used" then
                    local reqLevel = GetTrainerServiceLevelReq(i) or 0
                    local meetsLevel = (reqLevel <= 1 or playerLevel >= reqLevel)
                    local meetsSkill = true
                    if isTrade and GetTrainerServiceSkillReq then
                        local _, _, hasReq = GetTrainerServiceSkillReq(i)
                        if hasReq == false then meetsSkill = false end
                    end

                    if serviceType == "available" then
                        count = count + 1
                        cost = cost + (GetTrainerServiceCost(i) or 0)
                    elseif serviceType == "unavailable" and meetsLevel and meetsSkill then
                        local isPrereqMet = false
                        if learnableSpells[serviceName] then
                            isPrereqMet = true
                        else
                            local numReq = GetTrainerServiceNumAbilityReq(i) or 0
                            if numReq > 0 then
                                for r = 1, numReq do
                                    local _, hasReq = GetTrainerServiceAbilityReq(i, r)
                                    if hasReq then
                                        isPrereqMet = true
                                        break
                                    end
                                end
                            end
                        end

                        if isPrereqMet then
                            count = count + 1
                            cost = cost + (GetTrainerServiceCost(i) or 0)
                        end
                    end
                end
            end

            if not unavailFilter then
                SetTrainerServiceTypeFilter("unavailable", 0)
                LibCompat.After(0.2, function()
                    isSilentScanning = false
                end)
            end

            cachedCount = count
            cachedCost = cost
        end

        trainAllBtn:SetScript("OnEnter", function(self)
            if cachedCount > 0 then
                GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 4)
                GameTooltip:ClearLines()
                local costStr = GetCoinTextureString and GetCoinTextureString(cachedCost) or (GetCoinText(cachedCost) .. ".")
                if cachedCount > 1 then
                    GameTooltip:AddLine("Train " .. cachedCount .. " skills for " .. costStr)
                else
                    GameTooltip:AddLine("Train " .. cachedCount .. " skill for " .. costStr)
                end
                GameTooltip:Show()
            end
        end)

        local isTraining = false
        local trainWatcher = CreateFrame("Frame")
        trainWatcher:RegisterEvent("TRAINER_UPDATE")
        trainWatcher:RegisterEvent("TRAINER_CLOSED")

        local function StopTraining()
            trainWatcher:SetScript("OnUpdate", nil)
            isTraining = false
            if ClassTrainerFrame_Update then
                ClassTrainerFrame_Update()
            end
        end

        local function TrainBatch()
            local count = 0
            local money = GetMoney()

            for i = GetNumTrainerServices(), 1, -1 do
                local _, _, isAvail = GetTrainerServiceInfo(i)
                if isAvail == "available" then
                    local cost = GetTrainerServiceCost(i) or 0
                    if money >= cost then
                        money = money - cost
                        count = count + 1
                        BuyTrainerService(i)
                    else
                        StopTraining()
                        return
                    end
                end
            end

            if count > 0 then
                trainWatcher.timeout = 1.5
                trainWatcher:SetScript("OnUpdate", function(self, elapsed)
                    self.timeout = self.timeout - elapsed
                    if self.timeout <= 0 then
                        StopTraining()
                    end
                end)
            else
                StopTraining()
            end
        end

        trainWatcher:SetScript("OnEvent", function(self, event)
            if event == "TRAINER_UPDATE" then
                if isTraining then
                    TrainBatch()
                else
                    CalculateTotalTrainerCost()
                end
            elseif event == "TRAINER_CLOSED" then
                StopTraining()
            end
        end)

        trainAllBtn:SetScript("OnClick", function(self)
            if isTraining then return end
            isTraining = true
            self:Disable()
            TrainBatch()
        end)

        ClassTrainerFrame:HookScript("OnShow", CalculateTotalTrainerCost)

        hooksecurefunc("ClassTrainerFrame_Update", function()
            if isTraining then return end
            local skillsAvailable = false
            for i = 1, GetNumTrainerServices() do
                local _, _, isAvail = GetTrainerServiceInfo(i)
                if isAvail and isAvail == "available" then
                    skillsAvailable = true
                    break
                end
            end
            if skillsAvailable then
                trainAllBtn:Enable()
            else
                trainAllBtn:Disable()
            end
        end)

        local function SetTrainAllFunc()
            if LeaPlusLC["ShowTrainAllBtn"] == "On" then
                trainAllBtn:Show()
            else
                trainAllBtn:Hide()
            end
        end

        if LeaPlusCB["ShowTrainAllBtn"] then
            LeaPlusCB["ShowTrainAllBtn"]:HookScript("OnClick", SetTrainAllFunc)
        end
        TrainerPanel.r:HookScript("OnClick", SetTrainAllFunc)
        SetTrainAllFunc()
    end

    if IsAddOnLoaded("Blizzard_TrainerUI") then
        ApplyTrainer()
    else
        local tw = CreateFrame("Frame")
        tw:RegisterEvent("ADDON_LOADED")
        tw:SetScript("OnEvent", function(self, _, addon)
            if addon == "Blizzard_TrainerUI" then
                ApplyTrainer()
                self:UnregisterAllEvents()
            end
        end)
    end
end

-- Enhance professions
local function SetupEnhanceProfessions()
    if LeaPlusLC["EnhanceProfessions"] ~= "On" or LeaLockList["EnhanceProfessions"] then return end

    local tall = 73
    local numTallProfs = 19

    local function ApplyTrade()
        if not TradeSkillFrame or TradeSkillFrame.__leaApplied then return end
        TradeSkillFrame.__leaApplied = true

        UIPanelWindows["TradeSkillFrame"] = {
            area = "override", pushable = 3, xoffset = 0, yoffset = 12,
            bottomClampOverride = 140 + 12, width = 714, height = 487, whileDead = 1,
        }

        TradeSkillFrame:SetWidth(714)
        TradeSkillFrame:SetHeight(487 + tall)

        if TradeSkillFrameTitleText then
            TradeSkillFrameTitleText:ClearAllPoints()
            TradeSkillFrameTitleText:SetPoint("TOP", TradeSkillFrame, "TOP", 0, -18)
        end

        TradeSkillListScrollFrame:ClearAllPoints()
        TradeSkillListScrollFrame:SetPoint("TOPLEFT", TradeSkillFrame, "TOPLEFT", 25, -75)
        TradeSkillListScrollFrame:SetSize(295, 336 + tall)

        if not TradeSkillFrame.__leaRowsExtended then
            TradeSkillFrame.__leaRowsExtended = true
            local oldCount = TRADE_SKILLS_DISPLAYED or 11
            for i = 2, oldCount do
                local btn = _G["TradeSkillSkill" .. i]
                if btn then
                    btn:ClearAllPoints()
                    btn:SetPoint("TOPLEFT", _G["TradeSkillSkill" .. (i - 1)], "BOTTOMLEFT", 0, 1)
                end
            end
            _G.TRADE_SKILLS_DISPLAYED = oldCount + numTallProfs
            for i = oldCount + 1, _G.TRADE_SKILLS_DISPLAYED do
                local btn = _G["TradeSkillSkill" .. i]
                if not btn then
                    btn = CreateFrame("Button", "TradeSkillSkill" .. i, TradeSkillFrame, "TradeSkillSkillButtonTemplate")
                    btn:SetID(i)
                    btn:Hide()
                end
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", _G["TradeSkillSkill" .. (i - 1)], "BOTTOMLEFT", 0, 1)
            end
        end

        if _G["TradeSkillHighlightFrame"] and not TradeSkillFrame.__leaHighlightHooked then
            TradeSkillFrame.__leaHighlightHooked = true
            hooksecurefunc(_G["TradeSkillHighlightFrame"], "Show", function(self)
                self:SetWidth(290)
            end)
        end

        TradeSkillDetailScrollFrame:ClearAllPoints()
        TradeSkillDetailScrollFrame:SetPoint("TOPLEFT", TradeSkillFrame, "TOPLEFT", 352, -74)
        TradeSkillDetailScrollFrame:SetSize(298, 336 + tall)

        if TradeSkillDetailScrollFrameTop then TradeSkillDetailScrollFrameTop:SetAlpha(0) end
        if TradeSkillDetailScrollFrameBottom then TradeSkillDetailScrollFrameBottom:SetAlpha(0) end

        if not TradeSkillFrame.__leaRecipeInset then
            local inset = TradeSkillFrame:CreateTexture(nil, "ARTWORK")
            TradeSkillFrame.__leaRecipeInset = inset
            inset:SetTexture("Interface\\RAIDFRAME\\UI-RaidFrame-GroupBg")
        end
        TradeSkillFrame.__leaRecipeInset:ClearAllPoints()
        TradeSkillFrame.__leaRecipeInset:SetSize(304, 361 + tall)
        TradeSkillFrame.__leaRecipeInset:SetPoint("TOPLEFT", TradeSkillFrame, "TOPLEFT", 16, -72)

        if not TradeSkillFrame.__leaDetailsInset then
            local inset = TradeSkillFrame:CreateTexture(nil, "ARTWORK")
            TradeSkillFrame.__leaDetailsInset = inset
            inset:SetTexture("Interface\\AddOns\\Leatrix_Plus\\Assets\\ui-guildachievement-parchment-horizontal-desaturated.blp")
        end
        TradeSkillFrame.__leaDetailsInset:ClearAllPoints()
        TradeSkillFrame.__leaDetailsInset:SetSize(302, 339 + tall)
        TradeSkillFrame.__leaDetailsInset:SetPoint("TOPLEFT", TradeSkillFrame, "TOPLEFT", 348, -72)

        if TradeSkillExpandTabLeft then TradeSkillExpandTabLeft:Hide() end

        if TradeSkillHorizontalBarLeft then
            TradeSkillHorizontalBarLeft:SetSize(1, 1)
            TradeSkillHorizontalBarLeft:Hide()
        end

        local regions = { TradeSkillFrame:GetRegions() }

        if regions[3] and regions[3].SetTexture then
            regions[3]:SetTexture("Interface\\AddOns\\Leatrix_Plus\\Assets\\Leatrix_Plus")
            regions[3]:SetTexCoord(0.25, 0.75, 0, 1)
            regions[3]:SetSize(512, 512)
        end
        if regions[4] and regions[4].SetTexture and regions[3] then
            regions[4]:ClearAllPoints()
            regions[4]:SetPoint("TOPLEFT", regions[3], "TOPRIGHT", 0, 0)
            regions[4]:SetTexture("Interface\\AddOns\\Leatrix_Plus\\Assets\\Leatrix_Plus")
            regions[4]:SetTexCoord(0.75, 1, 0, 1)
            regions[4]:SetSize(256, 512)
        end

        if TradeSkillFrameBottomLeftTexture then TradeSkillFrameBottomLeftTexture:Hide() end
        if TradeSkillFrameBottomRightTexture then TradeSkillFrameBottomRightTexture:Hide() end

        if regions[8] then regions[8]:Hide() end
        if regions[9] then regions[9]:Hide() end

        if TradeSkillRankFrameSkillRank then
            TradeSkillRankFrameSkillRank:ClearAllPoints()
            TradeSkillRankFrameSkillRank:SetPoint("TOP", TradeSkillRankFrame, "TOP", 0, -1)
        end

        if TradeSkillCreateButton and TradeSkillCancelButton then
            TradeSkillCreateButton:ClearAllPoints()
            TradeSkillCreateButton:SetPoint("RIGHT", TradeSkillCancelButton, "LEFT", -1, 0)
        end

        if TradeSkillCancelButton then
            TradeSkillCancelButton:SetSize(80, 22)
            TradeSkillCancelButton:SetText(CLOSE)
            TradeSkillCancelButton:ClearAllPoints()
            TradeSkillCancelButton:SetPoint("BOTTOMRIGHT", TradeSkillFrame, "BOTTOMRIGHT", -42, 54)
        end

        if TradeSkillFrameCloseButton then
            TradeSkillFrameCloseButton:ClearAllPoints()
            TradeSkillFrameCloseButton:SetPoint("TOPRIGHT", TradeSkillFrame, "TOPRIGHT", -30, -8)
        end

        if TradeSkillInvSlotDropDown then
            TradeSkillInvSlotDropDown:ClearAllPoints()
            TradeSkillInvSlotDropDown:SetPoint("TOPLEFT", TradeSkillFrame, "TOPLEFT", 510, -40)
        end
        if TradeSkillSubClassDropDown and TradeSkillInvSlotDropDown then
            TradeSkillSubClassDropDown:ClearAllPoints()
            TradeSkillSubClassDropDown:SetPoint("RIGHT", TradeSkillInvSlotDropDown, "LEFT", 0, 0)
        end

        if TradeSkillFrameEditBox then
            TradeSkillFrameEditBox:ClearAllPoints()
            TradeSkillFrameEditBox:SetPoint("TOPRIGHT", TradeSkillRankFrame, "BOTTOMRIGHT", 0, 1)
            TradeSkillFrameEditBox:SetFrameLevel(3)
        end

        if TradeSkillFrameAvailableFilterCheckButton then
            TradeSkillFrameAvailableFilterCheckButton:ClearAllPoints()
            TradeSkillFrameAvailableFilterCheckButton:SetPoint("TOPLEFT", TradeSkillFrame, "TOPLEFT", 70, -53)
        end
        if TradeSkillFrameAvailableFilterCheckButtonText then
            TradeSkillFrameAvailableFilterCheckButtonText:SetWidth(110)
            TradeSkillFrameAvailableFilterCheckButtonText:SetWordWrap(false)
            TradeSkillFrameAvailableFilterCheckButtonText:SetJustifyH("LEFT")
        end
    end

    if IsAddOnLoaded("Blizzard_TradeSkillUI") then
        ApplyTrade()
    else
        local pw = CreateFrame("Frame")
        pw:RegisterEvent("ADDON_LOADED")
        pw:SetScript("OnEvent", function(self, _, addon)
            if addon == "Blizzard_TradeSkillUI" then
                ApplyTrade()
                self:UnregisterAllEvents()
            end
        end)
    end

    if TradeSkillFrame and not TradeSkillFrame.__leaHookInstalled then
        TradeSkillFrame.__leaHookInstalled = true
        TradeSkillFrame:HookScript("OnShow", ApplyTrade)
    end
end

-- Enhance quest log
local function SetupEnhanceQuestLog()
    local EnhanceQuestPanel = LeaPlusLC:CreatePanel("Enhance Quest Log", "EnhanceQuestPanel")
    LeaPlusLC:MakeTx(EnhanceQuestPanel, "Settings", 16, -72)
    LeaPlusLC:MakeCB(EnhanceQuestPanel, "EnhanceQLShowLevel", "Show Quest Level", 16, -92, false, "Shows the quest level next to the title in the quest details pane.")
    LeaPlusLC:MakeCB(EnhanceQuestPanel, "EnhanceQLDifficulty", "Show Quest Difficulty", 16, -112, false, "Shows difficulty tags (D for Dungeon, R for Raid, P for PvP, + for Elite) in the quest details pane.")
    LeaPlusLC:MakeCB(EnhanceQuestPanel, "EnhanceQLHeaders", "Show Toggle Headers Button", 16, -132, false, "Adds a Collapse and Expand button to the top of the quest log.")
    LeaPlusLC:MakeCB(EnhanceQuestPanel, "EnhanceQLListDifficulty", "Show Difficulty in Quest List", 16, -152, false, "Shows [Level+Tag] next to each quest title in the scrolling list.")
    EnhanceQuestPanel.h:Hide()
    EnhanceQuestPanel.b:SetScript("OnClick", function()
        EnhanceQuestPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page5"]:Show()
    end)
    EnhanceQuestPanel.r:SetScript("OnClick", function()
        LeaPlusLC["EnhanceQLShowLevel"] = "On"
        LeaPlusLC["EnhanceQLDifficulty"] = "On"
        LeaPlusLC["EnhanceQLHeaders"] = "On"
        LeaPlusLC["EnhanceQLListDifficulty"] = "Off"
        EnhanceQuestPanel:Hide(); EnhanceQuestPanel:Show()
    end)
    if LeaPlusCB["EnhanceQuestLogBtn"] then
        LeaPlusCB["EnhanceQuestLogBtn"]:SetScript("OnClick", function()
            EnhanceQuestPanel:Show(); LeaPlusLC:HideFrames()
        end)
    end

    if LeaPlusLC["EnhanceQuestLog"] ~= "On" then return end

    local headerBtn = CreateFrame("Button", nil, QuestLogFrame, "UIPanelButtonTemplate")
    headerBtn:SetSize(80, 20)
    headerBtn:SetPoint("TOPRIGHT", QuestLogFrame, "TOPRIGHT", -40, -44)
    headerBtn:SetText("Collapse")
    headerBtn.collapsed = false
    headerBtn:SetScript("OnClick", function(self)
        if self.collapsed then
            self.collapsed = false
            self:SetText("Collapse")
            ExpandQuestHeader(0)
        else
            self.collapsed = true
            self:SetText("Expand")
            CollapseQuestHeader(0)
        end
    end)

    local function UpdateHeaderButton()
        if LeaPlusLC["EnhanceQLHeaders"] == "On" then
            headerBtn:Show()
        else
            headerBtn:Hide()
        end
    end
    UpdateHeaderButton()
    if LeaPlusCB["EnhanceQLHeaders"] then
        LeaPlusCB["EnhanceQLHeaders"]:HookScript("OnClick", UpdateHeaderButton)
    end

    hooksecurefunc("QuestLog_UpdateQuestDetails", function()
        if not QuestInfoTitleHeader then return end
        local quest = GetQuestLogSelection()
        if not quest or quest == 0 then return end
        local title, level, questTag, suggestedGroup = GetQuestLogTitle(quest)
        if not title then return end

        local prefix = ""
        if LeaPlusLC["EnhanceQLShowLevel"] == "On" and level and level > 0 then
            prefix = tostring(level)
        end

        local tag = ""
        if LeaPlusLC["EnhanceQLDifficulty"] == "On" then
            if questTag == "Heroic" then tag = "H"
            elseif questTag == "Dungeon" then tag = "D"
            elseif questTag == "Raid" or questTag == RAID then tag = "R"
            elseif questTag == "PVP" or questTag == PVP then tag = "P"
            elseif questTag == "Elite" or questTag == ELITE or (suggestedGroup and suggestedGroup > 1) then tag = "+"
            end
        end

        if prefix == "" and tag == "" then
            QuestInfoTitleHeader:SetText(title)
        else
            QuestInfoTitleHeader:SetText("[" .. prefix .. tag .. "] " .. title)
        end
    end)

    hooksecurefunc("QuestLogTitleButton_Resize", function(questLogTitle)
        if LeaPlusLC["EnhanceQLListDifficulty"] ~= "On" then return end
        if questLogTitle.isHeader then return end

        local questIndex = questLogTitle:GetID()
        local title, level, questTag, suggestedGroup = GetQuestLogTitle(questIndex)
        if not title then return end

        local tag = ""
        if questTag == "Heroic" then tag = "H"
        elseif questTag == "Dungeon" then tag = "D"
        elseif questTag == "Raid" or questTag == RAID then tag = "R"
        elseif questTag == "PVP" or questTag == PVP then tag = "P"
        elseif questTag == "Elite" or questTag == ELITE or (suggestedGroup and suggestedGroup > 1) then tag = "+"
        end

        local normalText = questLogTitle.normalText or _G[questLogTitle:GetName() .. "NormalText"]
        if normalText then
            normalText:SetWidth(0)
            local lvlStr = (level and level > 0) and tostring(level) or "??"
            normalText:SetText(string.format("  [%s%s] %s", lvlStr, tag, title))

            local totalWidth = questLogTitle:GetWidth() or 275
            local tagIcon = questLogTitle.tag or _G[questLogTitle:GetName() .. "Tag"]
            if tagIcon and tagIcon:IsShown() then
                local tagWidth = tagIcon:GetWidth() or 0
                normalText:SetWidth(totalWidth - tagWidth - 20)
            else
                normalText:SetWidth(totalWidth - 20)
            end
        end
    end)
end

-- Enhance dressup
local function SetupEnhanceDressup()
    if LeaPlusLC["EnhanceDressup"] ~= "On" then return end

    local function ToggleStats()
        local hideStats = (LeaPlusLC["HideDressupStats"] == "On")
        if hideStats then
            if CharacterResistanceFrame then CharacterResistanceFrame:Hide() end
            if CharacterAttributesFrame then CharacterAttributesFrame:Hide() end
            CharacterModelFrame:ClearAllPoints()
            CharacterModelFrame:SetPoint("TOPLEFT", PaperDollFrame, "TOPLEFT", 66, -76)
            CharacterModelFrame:SetPoint("BOTTOMRIGHT", PaperDollFrame, "BOTTOMRIGHT", -86, 134)
        else
            if CharacterResistanceFrame then CharacterResistanceFrame:Show() end
            if CharacterAttributesFrame then CharacterAttributesFrame:Show() end
            CharacterModelFrame:ClearAllPoints()
            CharacterModelFrame:SetPoint("TOPLEFT", PaperDollFrame, "TOPLEFT", 66, -76)
            CharacterModelFrame:SetPoint("BOTTOMRIGHT", PaperDollFrame, "BOTTOMRIGHT", -86, 243)
        end

        if PaperDollFrame.__leaHelmCB and LeaPlusLC["ShowVanityControls"] == "On" then
            if hideStats then
                PaperDollFrame.__leaHelmCB:Hide()
                PaperDollFrame.__leaCloakCB:Hide()
            else
                PaperDollFrame.__leaHelmCB:Show()
                PaperDollFrame.__leaCloakCB:Show()
            end
        end
    end

    CharacterModelFrame:HookScript("OnMouseDown", function(_, btn)
        if btn == "MiddleButton" then
            LeaPlusLC["HideDressupStats"] = (LeaPlusLC["HideDressupStats"] == "On") and "Off" or "On"
            ToggleStats()
        end
    end)

    if not PaperDollFrame.__leaStatsBtn then
        local toggleBtn = CreateFrame("Button", nil, PaperDollFrame)
        PaperDollFrame.__leaStatsBtn = toggleBtn
        toggleBtn:SetFrameStrata("HIGH")
        toggleBtn:SetSize(36, 36)
        toggleBtn:SetPoint("TOPLEFT", PaperDollFrame, "TOPLEFT", 64, -45)
        toggleBtn:SetNormalTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-RotationRight-Big-Up")
        toggleBtn:SetHighlightTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-RotationRight-Big-Up")
        toggleBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_NONE")
            GameTooltip:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", 0, 0)
            GameTooltip:SetText(L["Toggle character stats"], nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        toggleBtn:SetScript("OnLeave", GameTooltip_Hide)
        toggleBtn:SetScript("OnClick", function()
            LeaPlusLC["HideDressupStats"] = (LeaPlusLC["HideDressupStats"] == "On") and "Off" or "On"
            ToggleStats()
        end)
    end

    local function InstallDressupButtons()
        if not DressUpFrame then return end
        if DressUpFrame.__leaButtonsInstalled then return end
        if not DressUpFrameResetButton then return end

        DressUpFrame.__leaButtonsInstalled = true

        local baseLevel = DressUpFrameResetButton:GetFrameLevel()

        local nudeBtn = CreateFrame("Button", nil, DressUpFrame, "UIPanelButtonTemplate")
        nudeBtn:SetSize(28, 22)
        nudeBtn:SetFrameLevel(baseLevel + 2)
        nudeBtn:SetPoint("RIGHT", DressUpFrameResetButton, "LEFT", -4, 0)
        nudeBtn:SetText("N")
        nudeBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(L["Remove all items"] or "Remove all items", nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        nudeBtn:SetScript("OnLeave", GameTooltip_Hide)
        nudeBtn:SetScript("OnClick", function()
            DressUpModel:Undress()
        end)

        local showMeBtn = CreateFrame("Button", nil, DressUpFrame, "UIPanelButtonTemplate")
        showMeBtn:SetSize(28, 22)
        showMeBtn:SetFrameLevel(baseLevel + 2)
        showMeBtn:SetPoint("RIGHT", nudeBtn, "LEFT", -4, 0)
        showMeBtn:SetText("M")
        showMeBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(L["Show me"] or "Show me", nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        showMeBtn:SetScript("OnLeave", GameTooltip_Hide)
        showMeBtn:SetScript("OnClick", function()
            DressUpModel:SetUnit("player")
        end)

        local targetBtn = CreateFrame("Button", nil, DressUpFrame, "UIPanelButtonTemplate")
        targetBtn:SetSize(28, 22)
        targetBtn:SetFrameLevel(baseLevel + 2)
        targetBtn:SetPoint("RIGHT", showMeBtn, "LEFT", -4, 0)
        targetBtn:SetText("T")
        targetBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(L["Show target model"] or "Show target model", nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        targetBtn:SetScript("OnLeave", GameTooltip_Hide)
        targetBtn:SetScript("OnClick", function()
            if UnitExists("target") then
                DressUpModel:SetUnit("target")
            end
        end)

        DressUpFrameResetButton:HookScript("OnClick", function()
            DressUpModel:SetUnit("player")
        end)
    end

    InstallDressupButtons()
    if DressUpFrame then
        DressUpFrame:HookScript("OnShow", InstallDressupButtons)
    end

    if PaperDollFrame then
        PaperDollFrame:HookScript("OnShow", ToggleStats)
    end

    ToggleStats()
end

-- Lifecycle
function Module:OnEnable()
    SetupDurabilityStatus()
    SetupVanityControls()
    SetupPlayerChain()
    SetupEnhanceTrainers()
    SetupEnhanceProfessions()
    SetupEnhanceQuestLog()
    SetupEnhanceDressup()
end

function Module:OnLogin()
    SetupDurabilityStatus()
    SetupVanityControls()
end

function Module:OnLogout(wipeData) end