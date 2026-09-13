-- System.lua
local _, Leatrix_Plus = ...
local LeaPlusLC = Leatrix_Plus.LC
local LeaPlusCB = Leatrix_Plus.CB
local LeaLockList = Leatrix_Plus.LockList
local L = Leatrix_Plus.L

local Module = {}
Leatrix_Plus:RegisterModule("System", Module)

----------------------------------------------------------------------
-- 1. Graphics, Sound & Viewport
----------------------------------------------------------------------
local function SetupGraphicsAndSound()
    if LeaPlusLC["NoScreenGlow"] == "On" then SetCVar("ffxGlow", "0") end
    if LeaPlusLC["NoScreenEffects"] == "On" then SetCVar("ffxDeath", "0"); SetCVar("ffxNetherWorld", "0") end
    if LeaPlusLC["MaxCameraZoom"] == "On" then SetCVar("cameraDistanceMaxFactor", 4.0) end

    if LeaPlusLC["SetWeatherDensity"] == "On" then
        SetCVar("weatherDensity", LeaPlusLC["WeatherLevel"] or 3)
    end

    if LeaPlusLC["ViewPortEnable"] == "On" then
        local bTop = WorldFrame:CreateTexture(nil, "ARTWORK")
        bTop:SetVertexColor(0, 0, 0, 1)
        bTop:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
        bTop:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)

        local bBot = WorldFrame:CreateTexture(nil, "ARTWORK")
        bBot:SetVertexColor(0, 0, 0, 1)
        bBot:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
        bBot:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)

        local bLeft = WorldFrame:CreateTexture(nil, "ARTWORK")
        bLeft:SetVertexColor(0, 0, 0, 1)
        bLeft:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
        bLeft:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)

        local bRight = WorldFrame:CreateTexture(nil, "ARTWORK")
        bRight:SetVertexColor(0, 0, 0, 1)
        bRight:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
        bRight:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)

        local a = 1 - (LeaPlusLC["ViewPortAlpha"] or 0)
        bTop:SetHeight(LeaPlusLC["ViewPortTop"] or 0); bTop:SetAlpha(a)
        bBot:SetHeight(LeaPlusLC["ViewPortBottom"] or 0); bBot:SetAlpha(a)
        bLeft:SetWidth(LeaPlusLC["ViewPortLeft"] or 0); bLeft:SetAlpha(a)
        bRight:SetWidth(LeaPlusLC["ViewPortRight"] or 0); bRight:SetAlpha(a)

        WorldFrame:SetPoint("TOPLEFT", 0, -(LeaPlusLC["ViewPortResizeTop"] or 0))
        WorldFrame:SetPoint("BOTTOMRIGHT", 0, (LeaPlusLC["ViewPortResizeBottom"] or 0))
    end

    if LeaPlusLC["NoRestedEmotes"] == "On" then
        local rFrame = CreateFrame("Frame")
        local function UpdateEmoteSound()
            local szone = GetSubZoneText() or ""
            local isResting = IsResting() or (szone == "The Grim Guzzler" or szone == "Трактир Угрюмый обжора" or szone == "黑铁酒吧")
            SetCVar("Sound_EnableEmoteSounds", isResting and "0" or "1")
        end
        rFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
        rFrame:RegisterEvent("ZONE_CHANGED")
        rFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        rFrame:SetScript("OnEvent", UpdateEmoteSound)
        UpdateEmoteSound()
    end
end

----------------------------------------------------------------------
-- 2. Gameplay, Cinematics & Plates
----------------------------------------------------------------------
local function SetupGameplayTweaks()
    if LeaPlusLC["FasterMovieSkip"] == "On" and CinematicFrame then
        CinematicFrame:HookScript("OnShow", function(self)
            HideUIPanel(self)
            LibCompat.After(0.01, StopCinematic)
        end)
    end

    if LeaPlusLC["CombatPlates"] == "On" then
        local cp = CreateFrame("Frame")
        cp:RegisterEvent("PLAYER_REGEN_DISABLED")
        cp:RegisterEvent("PLAYER_REGEN_ENABLED")
        cp:SetScript("OnEvent", function(_, event)
            SetCVar("nameplateShowEnemies", event == "PLAYER_REGEN_DISABLED" and 1 or 0)
        end)
        SetCVar("nameplateShowEnemies", UnitAffectingCombat("player") and 1 or 0)
    end

    if LeaPlusLC["EasyItemDestroy"] == "On" then
        hooksecurefunc("StaticPopup_Show", function(which)
            if (which == "DELETE_ITEM" or which == "DELETE_GOOD_ITEM") and LeaPlusLC["EasyItemDestroy"] == "On" then
                local dialog = StaticPopup_Visible(which)
                if dialog and _G[dialog] then
                    local eb = _G[dialog .. "EditBox"]
                    local b1 = _G[dialog .. "Button1"]
                    if eb and eb:IsShown() then eb:Hide() end
                    if b1 then b1:Enable() end
                end
            end
        end)
    end

    if LeaPlusLC["UnivGroupColor"] == "On" then
        ChangeChatColor("RAID", 0.67, 0.67, 1)
        ChangeChatColor("RAID_LEADER", 0.46, 0.78, 1)
    end
end

----------------------------------------------------------------------
-- 3. PaperDoll Extras
----------------------------------------------------------------------
local function SetupPaperDollExtras()
    if LeaPlusLC["ShowVolume"] == "On" and CharacterModelFrame then
        LeaPlusLC["LeaPlusMaxVol"] = tonumber(GetCVar("Sound_MasterVolume")) or 1.0
        LeaPlusLC:MakeSL(CharacterModelFrame, "LeaPlusMaxVol", "", 0, 1, 0.05, -42, -328, "%.2f")
        if LeaPlusCB["LeaPlusMaxVol"] then
            LeaPlusCB["LeaPlusMaxVol"]:SetWidth(64)
            LeaPlusCB["LeaPlusMaxVol"]:HookScript("OnValueChanged", function()
                SetCVar("Sound_MasterVolume", LeaPlusLC["LeaPlusMaxVol"])
            end)
        end
    end

    if LeaPlusLC["DurabilityStatus"] == "On" and PaperDollFrame then
        local duraBtn = CreateFrame("Button", nil, PaperDollFrame)
        duraBtn:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -40, 80)
        duraBtn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
        duraBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        duraBtn:SetSize(32, 32)

        local slots = { "HeadSlot", "ShoulderSlot", "ChestSlot", "WristSlot", "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "MainHandSlot", "SecondaryHandSlot", "RangedSlot" }
        local function GetTotalDurability()
            local curTotal, maxTotal = 0, 0
            for _, slot in ipairs(slots) do
                local slotID = GetInventorySlotInfo(slot)
                if slotID then
                    local cur, maxDura = GetInventoryItemDurability(slotID)
                    if cur and maxDura and maxDura > 0 then
                        curTotal = curTotal + cur
                        maxTotal = maxTotal + maxDura
                    end
                end
            end
            return (maxTotal > 0) and (curTotal / maxTotal * 100) or 100
        end

        duraBtn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(duraBtn, "ANCHOR_RIGHT")
            GameTooltip:AddLine(L["Durability"] .. string.format(": %.0f%%", GetTotalDurability()))
            GameTooltip:Show()
        end)
        duraBtn:SetScript("OnLeave", GameTooltip_Hide)

        local dDeath = CreateFrame("Frame")
        dDeath:RegisterEvent("PLAYER_DEAD")
        dDeath:SetScript("OnEvent", function()
            LeaPlusLC:Print(L["You have"] .. string.format(" %.0f%% ", GetTotalDurability()) .. L["durability"] .. ".")
        end)
    end

    if LeaPlusLC["ShowVanityControls"] == "On" and PaperDollFrame then
        LeaPlusLC:MakeCB(PaperDollFrame, "ShowHelm", L["Helm"], 65, -246, false, "")
        LeaPlusLC:MakeCB(PaperDollFrame, "ShowCloak", L["Cloak"], 275, -246, false, "")

        if LeaPlusCB["ShowHelm"] then
            LeaPlusCB["ShowHelm"]:HookScript("OnClick", function() ShowHelm(not ShowingHelm()) end)
            LeaPlusCB["ShowHelm"]:SetChecked(ShowingHelm())
        end
        if LeaPlusCB["ShowCloak"] then
            LeaPlusCB["ShowCloak"]:HookScript("OnClick", function() ShowCloak(not ShowingCloak()) end)
            LeaPlusCB["ShowCloak"]:SetChecked(ShowingCloak())
        end
    end
end

----------------------------------------------------------------------
-- 4. Bag Search Box (Container Size Safe)
----------------------------------------------------------------------
local function SetupBagSearch()
    if LeaPlusLC["ShowBagSearchBox"] ~= "On" or LeaLockList["ShowBagSearchBox"] then return end
    if not ContainerFrame1MoneyFrame then return end

    local sBox = CreateFrame("EditBox", "Leatrix_SearchFrame", ContainerFrame1MoneyFrame, "InputBoxTemplate")
    sBox:SetSize(120, 15)
    sBox:SetPoint("TOPRIGHT", ContainerFrame1MoneyFrame, "TOPRIGHT", -9, 185)
    sBox:SetAutoFocus(false)
    sBox:SetTextInsets(14, 20, 0, 0)

    local function FilterBags()
        local query = strtrim(sBox:GetText() or ""):lower()
        for bag = 0, NUM_BAG_SLOTS do
            local cFrame = _G["ContainerFrame" .. (bag + 1)]
            local size = cFrame and cFrame.size or 0
            for slot = 1, size do
                local btn = _G["ContainerFrame" .. (bag + 1) .. "Item" .. slot]
                if btn then
                    local link = GetContainerItemLink(bag, btn:GetID())
                    if query == "" or (link and link:lower():find(query, 1, true)) then
                        btn:EnableDrawLayer("BORDER")
                        btn:EnableDrawLayer("OVERLAY")
                    else
                        btn:DisableDrawLayer("BORDER")
                        btn:DisableDrawLayer("OVERLAY")
                    end
                end
            end
        end
    end

    sBox:SetScript("OnTextChanged", FilterBags)
    sBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
        FilterBags()
    end)
end

----------------------------------------------------------------------
-- 5. Auction House Enhancements
----------------------------------------------------------------------
local function SetupAuctionHouse()
    if LeaPlusLC["AhExtras"] ~= "On" then return end

    local function OnAuctionLoaded()
        if not AuctionFrameAuctions then return end

        hooksecurefunc("DurationDropDown_Initialize", function()
            if LeaPlusDB["AHDuration"] and LeaPlusDB["AHDuration"] >= 1 and LeaPlusDB["AHDuration"] <= 3 then
                AuctionFrameAuctions.duration = LeaPlusDB["AHDuration"]
            end
        end)
        hooksecurefunc("DurationDropDown_OnClick", function()
            LeaPlusDB["AHDuration"] = AuctionFrameAuctions.duration
        end)

        hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", function(self, button)
            if button == "LeftButton" and IsAltKeyDown() and AuctionFrame and AuctionFrame:IsShown() then
                local bag, slot = self:GetParent():GetID(), self:GetID()
                PickupContainerItem(bag, slot)
                ClickAuctionSellItemButton()
                ClearCursor()
            end
        end)
    end

    if IsAddOnLoaded("Blizzard_AuctionUI") then
        OnAuctionLoaded()
    else
        local aWait = CreateFrame("Frame")
        aWait:RegisterEvent("ADDON_LOADED")
        aWait:SetScript("OnEvent", function(self, _, addon)
            if addon == "Blizzard_AuctionUI" then
                OnAuctionLoaded()
                self:UnregisterAllEvents()
            end
        end)
    end
end

----------------------------------------------------------------------
-- 6. Enlarged Trainers, Professions & Quest Log
----------------------------------------------------------------------
local function SetupFrameEnlargements()
    -- Trainers
    if LeaPlusLC["EnhanceTrainers"] == "On" then
        local function ApplyTrainer()
            if not ClassTrainerFrame then return end
            ClassTrainerFrame:SetWidth(714)
            ClassTrainerListScrollFrame:SetWidth(295)
            ClassTrainerDetailScrollFrame:ClearAllPoints()
            ClassTrainerDetailScrollFrame:SetPoint("TOPLEFT", ClassTrainerFrame, "TOPLEFT", 352, -74)
        end
        if IsAddOnLoaded("Blizzard_TrainerUI") then ApplyTrainer()
        else
            local tw = CreateFrame("Frame")
            tw:RegisterEvent("ADDON_LOADED")
            tw:SetScript("OnEvent", function(self, _, addon)
                if addon == "Blizzard_TrainerUI" then ApplyTrainer(); self:UnregisterAllEvents() end
            end)
        end
    end

    -- Professions (3.3.5 Safe: No TradeSkillFrameEditBox call)
    if LeaPlusLC["EnhanceProfessions"] == "On" and not LeaLockList["EnhanceProfessions"] then
        local function ApplyTrade()
            if not TradeSkillFrame then return end
            TradeSkillFrame:SetWidth(714)
            TradeSkillListScrollFrame:SetWidth(295)
            TradeSkillDetailScrollFrame:ClearAllPoints()
            TradeSkillDetailScrollFrame:SetPoint("TOPLEFT", TradeSkillFrame, "TOPLEFT", 352, -74)
        end
        if IsAddOnLoaded("Blizzard_TradeSkillUI") then ApplyTrade()
        else
            local pw = CreateFrame("Frame")
            pw:RegisterEvent("ADDON_LOADED")
            pw:SetScript("OnEvent", function(self, _, addon)
                if addon == "Blizzard_TradeSkillUI" then ApplyTrade(); self:UnregisterAllEvents() end
            end)
        end
    end

    -- Quest Log Details & Levels
    if LeaPlusLC["EnhanceQuestLog"] == "On" then
        hooksecurefunc("QuestLog_UpdateQuestDetails", function()
            if LeaPlusLC["EnhanceQuestLevels"] == "On" then
                local quest = GetQuestLogSelection()
                if quest then
                    local title, level, questTag, suggestedGroup = GetQuestLogTitle(quest)
                    if title and level then
                        local tag = ""
                        if questTag == "Dungeon" or questTag == LFG_TYPE_DUNGEON then tag = "D"
                        elseif questTag == "Raid" or questTag == RAID then tag = "R"
                        elseif questTag == "PVP" or questTag == PVP then tag = "P"
                        elseif questTag == "Elite" or questTag == ELITE or (suggestedGroup and suggestedGroup > 1) then tag = "+" end
                        QuestInfoTitleHeader:SetText("[" .. level .. tag .. "] " .. title)
                    end
                end
            end
        end)
    end
end

----------------------------------------------------------------------
-- 7. Flight Times (LibCandyBar)
----------------------------------------------------------------------
local function SetupFlightTimes()
    if LeaPlusLC["ShowFlightTimes"] ~= "On" then return end

    local candy = LibStub("LibCandyBar-3.0", true)
    if not candy then return end

    Leatrix_Plus["FlightData"] = Leatrix_Plus["FlightData"] or {}
    if Leatrix_Plus.LoadFlightDataAlliance then Leatrix_Plus:LoadFlightDataAlliance() end
    if Leatrix_Plus.LoadFlightDataHorde then Leatrix_Plus:LoadFlightDataHorde() end

    hooksecurefunc("TakeTaxiNode", function(node)
        if UnitAffectingCombat("player") then return end
        local faction = UnitFactionGroup("player")
        local continent = GetCurrentMapContinent()
        local data = Leatrix_Plus["FlightData"]

        for i = 1, NumTaxiNodes() do
            if TaxiNodeGetType(i) == "CURRENT" then
                local startX, startY = TaxiNodePosition(i)
                local endX, endY = TaxiNodePosition(node)
                local route = string.format("%0.2f:%0.2f:%0.2f:%0.2f", startX, startY, endX, endY)

                if data[faction] and data[faction][continent] and data[faction][continent][route] then
                    local duration = data[faction][continent][route]
                    if duration and duration > 0 then
                        if LeaPlusLC.FlightProgressBar then
                            LeaPlusLC.FlightProgressBar:Stop()
                        end
                        local bar = candy:New("Interface\\TargetingFrame\\UI-StatusBar", LeaPlusLC["FlightBarWidth"] or 230, 16)
                        bar:SetPoint(LeaPlusLC["FlightBarA"] or "TOP", UIParent, LeaPlusLC["FlightBarR"] or "TOP", LeaPlusLC["FlightBarX"] or 0, LeaPlusLC["FlightBarY"] or -66)
                        bar:SetScale(LeaPlusLC["FlightBarScale"] or 2)
                        bar:SetDuration(duration)
                        bar:Start()
                        LeaPlusLC.FlightProgressBar = bar

                        -- Stop when landing detected
                        local landingWatcher = CreateFrame("Frame")
                        landingWatcher:SetScript("OnUpdate", function(self, elapsed)
                            if not UnitOnTaxi("player") then
                                self:SetScript("OnUpdate", nil)
                                if LeaPlusLC.FlightProgressBar then
                                    LeaPlusLC.FlightProgressBar:Stop()
                                    LeaPlusLC.FlightProgressBar = nil
                                end
                            end
                        end)
                    end
                end
                break
            end
        end
    end)
end

----------------------------------------------------------------------
-- Lifecycle Hooks
----------------------------------------------------------------------
function Module:OnEnable()
    SetupGraphicsAndSound()
    SetupGameplayTweaks()
    SetupBagSearch()
    SetupAuctionHouse()
    SetupFrameEnlargements()
    SetupFlightTimes()
end

function Module:OnLogin()
    SetupPaperDollExtras()
end

function Module:OnLogout(wipeData)
    if wipeData then
        SetCVar("ffxGlow", "1")
        SetCVar("ffxDeath", "1")
        SetCVar("ffxNetherWorld", "1")
        SetCVar("weatherDensity", "3")
        SetCVar("cameraDistanceMaxFactor", "1.9")
        ChangeChatColor("RAID", 1, 0.5, 0)
        ChangeChatColor("RAID_LEADER", 1, 0.28, 0.04)
    end
end