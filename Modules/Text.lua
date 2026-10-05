-- Text.lua
local _, Leatrix_Plus = ...
local LeaPlusLC = Leatrix_Plus.LC
local LeaPlusCB = Leatrix_Plus.CB
local LeaLockList = Leatrix_Plus.LockList
local L = Leatrix_Plus.L

local Module = {}
Leatrix_Plus:RegisterModule("Text", Module)

-- Action bar groups we patch
local ACTION_BAR_GROUPS = {
    "ActionButton",
    "BonusActionButton",
    "VehicleMenuBarActionButton",
    "MultiCastActionButton",
    "MultiCastSlotButton",
    "MultiBarBottomRightButton",
    "MultiBarBottomLeftButton",
    "MultiBarRightButton",
    "MultiBarLeftButton",
}

-- Set alpha on a named fontstring across every action bar
local function SetActionBarFieldAlpha(field, alpha)
    for _, prefix in ipairs(ACTION_BAR_GROUPS) do
        for i = 1, 12 do
            local region = _G[prefix .. i .. field]
            if region then
                region:SetAlpha(alpha)
            end
        end
    end
end

-- Errors that should still be shown even when error messages are hidden
local IMPORTANT_ERRORS = {}
local function AddImportantError(err)
    if err then IMPORTANT_ERRORS[err] = true end
end
AddImportantError(ERR_INV_FULL)
AddImportantError(ERR_QUEST_LOG_FULL)
AddImportantError(ERR_RAID_GROUP_ONLY)
AddImportantError(ERR_PET_SPELL_DEAD)
AddImportantError(ERR_PLAYER_DEAD)
AddImportantError(ERR_FEIGN_DEATH_RESISTED)
AddImportantError(SPELL_FAILED_TARGET_NO_POCKETS)
AddImportantError(ERR_ALREADY_PICKPOCKETED)

local IMPORTANT_PATTERNS = {
    "requires",
    "mount",
    "gold",
    "money",
    "afford",
    "shapeshift",
    "disarm",
}

local function IsImportantError(err)
    if not err then return false end
    if IMPORTANT_ERRORS[err] then return true end
    if type(err) == "string" then
        local lowerErr = strlower(err)
        for _, pattern in ipairs(IMPORTANT_PATTERNS) do
            if string.find(lowerErr, pattern, 1, true) then
                return true
            end
        end
    end
    return false
end

-- Hide error messages (live toggle)
local OrigErrHandler

local function FilteredErrorHandler(self, event, err, ...)
    local handler = OrigErrHandler or UIErrorsFrame_OnEvent
    if event == "UI_ERROR_MESSAGE" then
        if not IsImportantError(err) then
            return
        end
        if handler then return handler(self, event, err, ...) end
    elseif handler then
        return handler(self, event, err, ...)
    end
end

local function FilterErrors()
    if LeaPlusLC["HideErrorMessages"] ~= "On" then
        UIErrorsFrame:SetScript("OnEvent", OrigErrHandler or UIErrorsFrame_OnEvent)
    else
        UIErrorsFrame:SetScript("OnEvent", FilteredErrorHandler)
    end
end

local function SetupHideErrors()
    OrigErrHandler = UIErrorsFrame:GetScript("OnEvent")

    if LeaPlusCB["HideErrorMessages"] then
        LeaPlusCB["HideErrorMessages"]:HookScript("OnClick", FilterErrors)
    end

    FilterErrors()
end

-- Hide portrait numbers
local function SetupHidePortraitNumbers()
    if LeaPlusLC["NoHitIndicators"] ~= "On" or LeaLockList["NoHitIndicators"] then return end
    if PlayerHitIndicator then
        PlayerHitIndicator:Hide()
        hooksecurefunc(PlayerHitIndicator, "Show", PlayerHitIndicator.Hide)
    end
    if PetHitIndicator then
        PetHitIndicator:Hide()
        hooksecurefunc(PetHitIndicator, "Show", PetHitIndicator.Hide)
    end
end

-- Hide zone text by unregistering zone change events
local function SetupHideZoneText()
    if LeaPlusLC["HideZoneText"] ~= "On" then return end
    if ZoneTextFrame then
        ZoneTextFrame:UnregisterAllEvents()
        ZoneTextFrame:Hide()
    end
    if SubZoneTextFrame then
        SubZoneTextFrame:UnregisterAllEvents()
        SubZoneTextFrame:Hide()
    end
    if AutoSubZoneTextFrame then
        AutoSubZoneTextFrame:UnregisterAllEvents()
        AutoSubZoneTextFrame:Hide()
    end
end

-- Hide keybind text with persistent hook
local function SetupHideKeybindText()
    if LeaPlusLC["HideKeybindText"] ~= "On" or LeaLockList["HideKeybindText"] then return end
    SetActionBarFieldAlpha("HotKey", 0)

    if not LeaPlusLC.__leaHotKeyHooked and ActionButton_UpdateHotkeys then
        LeaPlusLC.__leaHotKeyHooked = true
        hooksecurefunc("ActionButton_UpdateHotkeys", function(self)
            if LeaPlusLC["HideKeybindText"] == "On" then
                local hotkey = _G[self:GetName() .. "HotKey"]
                if hotkey then
                    hotkey:SetAlpha(0)
                end
            end
        end)
    end
end

-- Hide macro text with persistent hook
local function SetupHideMacroText()
    if LeaPlusLC["HideMacroText"] ~= "On" or LeaLockList["HideMacroText"] then return end
    SetActionBarFieldAlpha("Name", 0)

    if not LeaPlusLC.__leaMacroNameHooked and ActionButton_Update then
        LeaPlusLC.__leaMacroNameHooked = true
        hooksecurefunc("ActionButton_Update", function(self)
            if LeaPlusLC["HideMacroText"] == "On" then
                local name = _G[self:GetName() .. "Name"]
                if name then
                    name:SetAlpha(0)
                end
            end
        end)
    end
end

-- Lifecycle
function Module:OnEnable()
    SetupHideErrors()
    SetupHidePortraitNumbers()
    SetupHideZoneText()
    SetupHideKeybindText()
    SetupHideMacroText()
end

function Module:OnLogin() end
function Module:OnLogout(wipeData) end