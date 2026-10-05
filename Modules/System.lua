-- System.lua
local _, Leatrix_Plus = ...
local LeaPlusLC = Leatrix_Plus.LC
local LeaPlusCB = Leatrix_Plus.CB
local LeaLockList = Leatrix_Plus.LockList
local L = Leatrix_Plus.L

local Module = {}
Leatrix_Plus:RegisterModule("System", Module)

local userSoundSetting = GetCVar("Sound_EnableEmoteSounds") or "1"
if userSoundSetting == "0" and not IsResting() then
    userSoundSetting = "1"
end
local bTop, bBot, bLeft, bRight

-- Graphics and sound
local function SetupGraphicsAndSound()
    local function ApplyGlow()
        SetCVar("ffxGlow", LeaPlusLC["NoScreenGlow"] == "On" and "0" or "1")
    end

    local function ApplyDeathEffects()
        SetCVar("ffxDeath", LeaPlusLC["NoScreenEffects"] == "On" and "0" or "1")
    end

    local function ApplyCameraZoom()
        if LeaPlusLC["MaxCameraZoom"] == "On" then
            SetCVar("cameraDistanceMax", "50")
            SetCVar("cameraDistanceMaxFactor", "3.4")
        else
            SetCVar("cameraDistanceMaxFactor", "1.9")
        end
    end

    ApplyGlow()
    ApplyDeathEffects()
    ApplyCameraZoom()

    if LeaPlusCB["NoScreenGlow"] then
        LeaPlusCB["NoScreenGlow"]:HookScript("OnClick", ApplyGlow)
    end
    if LeaPlusCB["NoScreenEffects"] then
        LeaPlusCB["NoScreenEffects"]:HookScript("OnClick", ApplyDeathEffects)
    end
    if LeaPlusCB["MaxCameraZoom"] then
        LeaPlusCB["MaxCameraZoom"]:HookScript("OnClick", ApplyCameraZoom)
    end

    local function ApplyWeatherDensity()
        if LeaPlusLC["SetWeatherDensity"] == "On" then
            SetCVar("weatherDensity", LeaPlusLC["WeatherLevel"] or 3)
        else
            SetCVar("weatherDensity", "3")
        end
    end

    ApplyWeatherDensity()

    if not LeaPlusLC.__leaWeatherHooked then
        LeaPlusLC.__leaWeatherHooked = true
        local wFrame = CreateFrame("Frame")
        wFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        wFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        wFrame:SetScript("OnEvent", ApplyWeatherDensity)

        -- Prevent Blizzard Video Options (particle density changes) from resetting weather density
        hooksecurefunc("SetCVar", function(setting, value)
            if setting and LeaPlusLC["SetWeatherDensity"] == "On" then
                if setting == "particleDensity" or setting == "graphicsParticleDensity" then
                    local targetLevel = tostring(LeaPlusLC["WeatherLevel"] or 3)
                    if GetCVar("weatherDensity") ~= targetLevel then
                        SetCVar("weatherDensity", targetLevel)
                    end
                end
            end
        end)
    end

    local weatherPanel = LeaPlusLC:CreatePanel("Set Weather Density", "weatherPanel")
    LeaPlusLC:MakeTx(weatherPanel, "Settings", 16, -72)
    LeaPlusLC:MakeSL(weatherPanel, "WeatherLevel", "Intensity level of weather effects (0 = off, 3 = heavy).", 0, 3, 1, 16, -92, "%.0f")
    weatherPanel.h:Hide()
    weatherPanel.b:SetScript("OnClick", function()
        weatherPanel:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page7"]:Show()
    end)
    weatherPanel.r:SetScript("OnClick", function()
        LeaPlusLC["WeatherLevel"] = 3
        if LeaPlusLC["SetWeatherDensity"] == "On" then
            SetCVar("weatherDensity", 3)
        end
        weatherPanel:Hide(); weatherPanel:Show()
    end)
    if LeaPlusCB["WeatherLevel"] then
        LeaPlusCB["WeatherLevel"]:HookScript("OnValueChanged", function(_, val)
            if LeaPlusLC["SetWeatherDensity"] == "On" then
                SetCVar("weatherDensity", val)
            end
        end)
    end
    if LeaPlusCB["SetWeatherDensityBtn"] then
        LeaPlusCB["SetWeatherDensityBtn"]:SetScript("OnClick", function()
            weatherPanel:Show(); LeaPlusLC:HideFrames()
        end)
    end

    local SideViewport = LeaPlusLC:CreatePanel("Enable Viewport Letterbox", "SideViewport")
    LeaPlusLC:MakeTx(SideViewport, "Top", 16, -72)
    LeaPlusLC:MakeSL(SideViewport, "ViewPortTop", "Height in pixels of the top black letterbox border.", 0, 300, 5, 16, -92, "%.0f")
    LeaPlusLC:MakeTx(SideViewport, "Bottom", 16, -132)
    LeaPlusLC:MakeSL(SideViewport, "ViewPortBottom", "Height in pixels of the bottom black letterbox border.", 0, 300, 5, 16, -152, "%.0f")

    SideViewport.h:Hide()
    SideViewport.b:SetScript("OnClick", function()
        SideViewport:Hide(); LeaPlusLC["PageF"]:Show(); LeaPlusLC["Page7"]:Show()
    end)
    SideViewport.r:SetScript("OnClick", function()
        if InCombatLockdown() then
            LeaPlusLC:Print("You cannot do that in combat.")
            return
        end
        LeaPlusLC["ViewPortTop"] = 0
        LeaPlusLC["ViewPortBottom"] = 0
        if LeaPlusCB["ViewPortTop"] then LeaPlusCB["ViewPortTop"]:SetValue(0) end
        if LeaPlusCB["ViewPortBottom"] then LeaPlusCB["ViewPortBottom"]:SetValue(0) end
        if bTop then bTop:SetHeight(0) end
        if bBot then bBot:SetHeight(0) end
        if bLeft then bLeft:SetWidth(0) end
        if bRight then bRight:SetWidth(0) end
        WorldFrame:ClearAllPoints()
        WorldFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
        WorldFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
        SideViewport:Hide(); SideViewport:Show()
    end)

    if LeaPlusCB["ModViewportBtn"] then
        LeaPlusCB["ModViewportBtn"]:SetScript("OnClick", function()
            SideViewport:Show(); LeaPlusLC:HideFrames()
        end)
    end

    if LeaPlusLC["ViewPortEnable"] == "On" then
        bTop = WorldFrame:CreateTexture(nil, "ARTWORK")
        bTop:SetTexture("Interface\\Buttons\\WHITE8X8")
        bTop:SetVertexColor(0, 0, 0, 1)
        bTop:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
        bTop:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)

        bBot = WorldFrame:CreateTexture(nil, "ARTWORK")
        bBot:SetTexture("Interface\\Buttons\\WHITE8X8")
        bBot:SetVertexColor(0, 0, 0, 1)
        bBot:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
        bBot:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)

        bLeft = WorldFrame:CreateTexture(nil, "ARTWORK")
        bLeft:SetTexture("Interface\\Buttons\\WHITE8X8")
        bLeft:SetVertexColor(0, 0, 0, 1)
        bLeft:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
        bLeft:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)

        bRight = WorldFrame:CreateTexture(nil, "ARTWORK")
        bRight:SetTexture("Interface\\Buttons\\WHITE8X8")
        bRight:SetVertexColor(0, 0, 0, 1)
        bRight:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
        bRight:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)

        local alpha = 1 - (LeaPlusLC["ViewPortAlpha"] or 0)
        bTop:SetHeight(LeaPlusLC["ViewPortTop"] or 0); bTop:SetAlpha(alpha)
        bBot:SetHeight(LeaPlusLC["ViewPortBottom"] or 0); bBot:SetAlpha(alpha)
        bLeft:SetWidth(LeaPlusLC["ViewPortLeft"] or 0); bLeft:SetAlpha(alpha)
        bRight:SetWidth(LeaPlusLC["ViewPortRight"] or 0); bRight:SetAlpha(alpha)

        WorldFrame:ClearAllPoints()
        WorldFrame:SetPoint("TOPLEFT", 0, -(LeaPlusLC["ViewPortTop"] or 0))
        WorldFrame:SetPoint("BOTTOMRIGHT", 0, (LeaPlusLC["ViewPortBottom"] or 0))

        if LeaPlusCB["ViewPortTop"] then
            LeaPlusCB["ViewPortTop"]:HookScript("OnValueChanged", function(_, val)
                if InCombatLockdown() then return end
                bTop:SetHeight(val)
                WorldFrame:ClearAllPoints()
                WorldFrame:SetPoint("TOPLEFT", 0, -val)
                WorldFrame:SetPoint("BOTTOMRIGHT", 0, LeaPlusLC["ViewPortBottom"] or 0)
            end)
        end
        if LeaPlusCB["ViewPortBottom"] then
            LeaPlusCB["ViewPortBottom"]:HookScript("OnValueChanged", function(_, val)
                if InCombatLockdown() then return end
                bBot:SetHeight(val)
                WorldFrame:ClearAllPoints()
                WorldFrame:SetPoint("TOPLEFT", 0, -(LeaPlusLC["ViewPortTop"] or 0))
                WorldFrame:SetPoint("BOTTOMRIGHT", 0, val)
            end)
        end

        if CinematicFrame then
            hooksecurefunc(CinematicFrame, "Show", function()
                if bTop then bTop:Hide() end
                if bBot then bBot:Hide() end
                if bLeft then bLeft:Hide() end
                if bRight then bRight:Hide() end
            end)
            hooksecurefunc(CinematicFrame, "Hide", function()
                if LeaPlusLC["ViewPortEnable"] == "On" and not (CinematicFrame and CinematicFrame:IsShown()) then
                    if bTop then bTop:Show() end
                    if bBot then bBot:Show() end
                    if bLeft then bLeft:Show() end
                    if bRight then bRight:Show() end
                end
            end)
        end
    end

    if LeaPlusLC["NoRestedEmotes"] == "On" then
        local rFrame = CreateFrame("Frame")
        local function UpdateEmoteSound()
            local szone = GetSubZoneText() or ""
            local isResting = IsResting() or szone == "The Grim Guzzler"
            if isResting then
                SetCVar("Sound_EnableEmoteSounds", "0")
            else
                SetCVar("Sound_EnableEmoteSounds", userSoundSetting)
            end
        end
        rFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
        rFrame:RegisterEvent("ZONE_CHANGED")
        rFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        rFrame:SetScript("OnEvent", UpdateEmoteSound)
        UpdateEmoteSound()
    end
end

-- Universal group color
local function SetupUniversalGroupColor()
    local isBlue = (LeaPlusLC["UnivGroupColor"] == "On")
    local r1, g1, b1 = isBlue and 0.67 or 1.0, isBlue and 0.67 or 0.50, isBlue and 1.0 or 0.0
    local r2, g2, b2 = isBlue and 0.46 or 1.0, isBlue and 0.78 or 0.28, isBlue and 1.0 or 0.04

    ChangeChatColor("RAID", r1, g1, b1)
    ChangeChatColor("RAID_LEADER", r2, g2, b2)

    if ChatTypeInfo then
        if ChatTypeInfo["RAID"] then
            ChatTypeInfo["RAID"].r, ChatTypeInfo["RAID"].g, ChatTypeInfo["RAID"].b = r1, g1, b1
        end
        if ChatTypeInfo["RAID_LEADER"] then
            ChatTypeInfo["RAID_LEADER"].r, ChatTypeInfo["RAID_LEADER"].g, ChatTypeInfo["RAID_LEADER"].b = r2, g2, b2
        end
    end
end

local function HookUnivGroupColorToggle()
    if LeaPlusCB["UnivGroupColor"] and not LeaPlusCB["UnivGroupColor"].__leaHooked then
        LeaPlusCB["UnivGroupColor"].__leaHooked = true
        LeaPlusCB["UnivGroupColor"]:HookScript("OnClick", SetupUniversalGroupColor)
    end
end

-- Disable bag automation
local function SetupBagAutomation()
    if LeaPlusLC["NoBagAutomation"] ~= "On" then return end

    local f = CreateFrame("Frame")
    f:RegisterEvent("MERCHANT_SHOW")
    f:RegisterEvent("BANKFRAME_OPENED")
    f:RegisterEvent("MAIL_SHOW")

    f:SetScript("OnEvent", function()
        if CloseAllBags then
            CloseAllBags()
        end
    end)
end

-- Disable loot warnings
local function SetupNoLootWarnings()
    local f = CreateFrame("Frame")

    local function UpdateLootRegistration()
        if LeaPlusLC["NoConfirmLoot"] == "On" then
            f:RegisterEvent("CONFIRM_LOOT_ROLL")
            f:RegisterEvent("LOOT_BIND_CONFIRM")
            f:RegisterEvent("CONFIRM_DISENCHANT_ROLL")
            f:RegisterEvent("MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL")
            f:RegisterEvent("MAIL_LOCK_SEND_ITEMS")
        else
            f:UnregisterAllEvents()
        end
    end

    f:SetScript("OnEvent", function(_, event, a1, a2)
        if event == "CONFIRM_LOOT_ROLL" then
            ConfirmLootRoll(a1, a2)
            StaticPopup_Hide("CONFIRM_LOOT_ROLL")
        elseif event == "LOOT_BIND_CONFIRM" then
            ConfirmLootSlot(a1)
            StaticPopup_Hide("LOOT_BIND")
        elseif event == "CONFIRM_DISENCHANT_ROLL" then
            ConfirmLootRoll(a1, a2)
            StaticPopup_Hide("CONFIRM_LOOT_ROLL")
        elseif event == "MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL" then
            local dialog = StaticPopup_Visible("MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL")
            if dialog and _G[dialog] then
                StaticPopup_OnClick(_G[dialog], 1)
            else
                if CursorHasItem() then
                    PickupMerchantItem()
                end
                StaticPopup_Hide("MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL")
            end
        elseif event == "MAIL_LOCK_SEND_ITEMS" then
            RespondMailLockSendItem(a1, true)
        end
    end)

    if LeaPlusCB["NoConfirmLoot"] then
        LeaPlusCB["NoConfirmLoot"]:HookScript("OnClick", UpdateLootRegistration)
    end

    UpdateLootRegistration()
end

-- Lifecycle
function Module:OnEnable()
    SetupGraphicsAndSound()
    SetupUniversalGroupColor()
    HookUnivGroupColorToggle()
    SetupBagAutomation()
    SetupNoLootWarnings()
end

function Module:OnLogin()
    SetupUniversalGroupColor()
    HookUnivGroupColorToggle()
end

function Module:OnLogout(wipeData)
    if LeaPlusLC["NoRestedEmotes"] == "On" and (IsResting() or GetSubZoneText() == "The Grim Guzzler") then
        SetCVar("Sound_EnableEmoteSounds", userSoundSetting)
    end

    if wipeData then
        SetCVar("ffxGlow", "1")
        SetCVar("ffxDeath", "1")
        SetCVar("weatherDensity", "3")
        SetCVar("cameraDistanceMax", "15")
        SetCVar("cameraDistanceMaxFactor", "1.9")
        ChangeChatColor("RAID", 1, 0.5, 0)
        ChangeChatColor("RAID_LEADER", 1, 0.28, 0.04)
    end
end