-- Leatrix_Plus_Library.lua
local void, Leatrix_Plus = ...

function Leatrix_Plus:LeaPlusCandyBar()
    -- LibCandyBar-3.0 (embedded for flight timer display)
    local GetTime, floor, next = GetTime, floor, next
    local CreateFrame, error, setmetatable, UIParent = CreateFrame, error, setmetatable, UIParent

    if not LibStub then error("LibCandyBar-3.0 requires LibStub.") end
    local cbh = LibStub:GetLibrary("CallbackHandler-1.0")
    if not cbh then error("LibCandyBar-3.0 requires CallbackHandler-1.0") end
    local lib = LibStub:NewLibrary("LibCandyBar-3.0", 100)
    if not lib then return end

    lib.callbacks = lib.callbacks or cbh:New(lib)
    local cb = lib.callbacks
    lib.dummyFrame = lib.dummyFrame or CreateFrame("Frame")
    lib.barFrameMT = lib.barFrameMT or { __index = lib.dummyFrame }
    lib.barPrototype = lib.barPrototype or setmetatable({}, lib.barFrameMT)
    lib.barPrototype_mt = lib.barPrototype_mt or { __index = lib.barPrototype }
    lib.barCache = lib.barCache or {}

    local barPrototype = lib.barPrototype
    local barPrototype_meta = lib.barPrototype_mt
    local barCache = lib.barCache

    local scripts = {
        "OnUpdate", "OnDragStart", "OnDragStop",
        "OnEnter", "OnLeave", "OnHide",
        "OnShow", "OnMouseDown", "OnMouseUp",
        "OnMouseWheel", "OnSizeChanged", "OnEvent"
    }
    local numScripts = #scripts
    local _fontName, _fontSize = GameFontHighlightSmallOutline:GetFont()
    local _fontShadowX, _fontShadowY = GameFontHighlightSmallOutline:GetShadowOffset()
    local _fontShadowR, _fontShadowG, _fontShadowB, _fontShadowA = nil
    local SetWidth, SetHeight, SetSize = lib.dummyFrame.SetWidth, lib.dummyFrame.SetHeight, lib.dummyFrame.SetSize

    local function stopBar(bar)
        bar.updater:Stop()
        bar.data = nil
        bar.funcs = nil
        bar.running = nil
        bar.paused = nil
        bar:Hide()
        bar:SetParent(UIParent)
    end

    local tformat1 = "%d:%02d:%02d"
    local tformat2 = "%d:%02d"
    local tformat3 = "%.1f"
    local tformat4 = "%.0f"

    local function barUpdate(updater)
        local bar = updater.parent
        local t = GetTime()
        if t >= bar.exp then
            bar:Stop()
        else
            local time = bar.exp - t
            bar.remaining = time
            bar.candyBarBar:SetValue(bar.fill and (t - bar.start) + bar.gap or time)

            if time > 3599.9 then
                local h = floor(time / 3600)
                local m = floor((time - (h * 3600)) / 60)
                local s = (time - (m * 60)) - (h * 3600)
                bar.candyBarDuration:SetFormattedText(tformat1, h, m, s)
            elseif time > 59.9 then
                local m = floor(time / 60)
                local s = time - (m * 60)
                bar.candyBarDuration:SetFormattedText(tformat2, m, s)
            elseif time < 10 then
                bar.candyBarDuration:SetFormattedText(tformat3, time)
            else
                bar.candyBarDuration:SetFormattedText(tformat4, time)
            end

            if bar.funcs then
                for i = 1, #bar.funcs do
                    bar.funcs[i](bar)
                end
            end
        end
    end

    local function restyleBar(self)
        if not self.running then return end
        self.candyBarIconFrame:ClearAllPoints()
        self.candyBarBar:ClearAllPoints()

        if self.candyBarIconFrame.icon then
            self.candyBarIconFrame:SetWidth(self.height)
            if self.iconPosition == "RIGHT" then
                self.candyBarIconFrame:SetPoint("TOPRIGHT", self)
                self.candyBarIconFrame:SetPoint("BOTTOMRIGHT", self)
                self.candyBarBar:SetPoint("TOPRIGHT", self.candyBarIconFrame, "TOPLEFT")
                self.candyBarBar:SetPoint("BOTTOMRIGHT", self.candyBarIconFrame, "BOTTOMLEFT")
                self.candyBarBar:SetPoint("TOPLEFT", self)
                self.candyBarBar:SetPoint("BOTTOMLEFT", self)
            else
                self.candyBarIconFrame:SetPoint("TOPLEFT")
                self.candyBarIconFrame:SetPoint("BOTTOMLEFT")
                self.candyBarBar:SetPoint("TOPLEFT", self.candyBarIconFrame, "TOPRIGHT")
                self.candyBarBar:SetPoint("BOTTOMLEFT", self.candyBarIconFrame, "BOTTOMRIGHT")
                self.candyBarBar:SetPoint("TOPRIGHT", self)
                self.candyBarBar:SetPoint("BOTTOMRIGHT", self)
            end
            self.candyBarIconFrame:Show()
        else
            self.candyBarBar:SetPoint("TOPLEFT", self)
            self.candyBarBar:SetPoint("BOTTOMRIGHT", self)
            self.candyBarIconFrame:Hide()
        end

        if self.showLabel and self.candyBarLabel.text then
            self.candyBarLabel:Show()
        else
            self.candyBarLabel:Hide()
        end

        if self.showTime then
            self.candyBarDuration:Show()
        else
            self.candyBarDuration:Hide()
        end
    end

    function barPrototype:SetFill(fill) self.fill = fill end
    function barPrototype:AddUpdateFunction(func)
        if not self.funcs then self.funcs = {} end
        self.funcs[#self.funcs + 1] = func
    end
    function barPrototype:Set(key, data)
        if not self.data then self.data = {} end
        self.data[key] = data
    end
    function barPrototype:Get(key) return self.data and self.data[key] end
    function barPrototype:SetColor(...) self.candyBarBar:SetStatusBarColor(...) end
    function barPrototype:SetTextColor(...)
        self.candyBarLabel:SetTextColor(...)
        self.candyBarDuration:SetTextColor(...)
    end
    function barPrototype:SetShadowColor(...)
        self.candyBarLabel:SetShadowColor(...)
        self.candyBarDuration:SetShadowColor(...)
    end
    function barPrototype:SetTexture(texture)
        self.candyBarBar:SetStatusBarTexture(texture)
        self.candyBarBackground:SetTexture(texture)
    end
    function barPrototype:SetWidth(width)
        self.width = width
        SetWidth(self, width)
    end
    function barPrototype:SetHeight(height)
        self.height = height
        SetHeight(self, height)
        restyleBar(self)
    end
    function barPrototype:SetSize(width, height)
        self.width = width
        self.height = height
        SetSize(self, width, height)
        restyleBar(self)
    end
    function barPrototype:GetLabel() return self.candyBarLabel.text end
    function barPrototype:SetLabel(text)
        self.candyBarLabel.text = text
        self.candyBarLabel:SetText(text)
        if text then self.candyBarLabel:Show() else self.candyBarLabel:Hide() end
    end
    function barPrototype:GetIcon() return self.candyBarIconFrame.icon end
    function barPrototype:SetIcon(icon, ...)
        self.candyBarIconFrame.icon = icon
        self.candyBarIconFrame:SetTexture(icon)
        if ... then
            self.candyBarIconFrame:SetTexCoord(...)
        else
            self.candyBarIconFrame:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        end
        restyleBar(self)
    end
    function barPrototype:SetIconPosition(position)
        self.iconPosition = position
        restyleBar(self)
    end
    function barPrototype:SetTimeVisibility(bool)
        self.showTime = bool
        if bool then self.candyBarDuration:Show() else self.candyBarDuration:Hide() end
    end
    function barPrototype:SetLabelVisibility(bool)
        self.showLabel = bool
        if bool then self.candyBarLabel:Show() else self.candyBarLabel:Hide() end
    end
    function barPrototype:SetDuration(duration) self.remaining = duration end
    function barPrototype:Start(maxValue)
        self.running = true
        local time = self.remaining
        self.gap = maxValue and (maxValue - time) or 0
        restyleBar(self)
        self.start = GetTime()
        self.exp = self.start + time

        self.candyBarBar:SetMinMaxValues(0, maxValue or time)
        self.candyBarBar:SetValue(self.fill and 0 or time)

        if time > 3599.9 then
            local h = floor(time / 3600)
            local m = floor((time - (h * 3600)) / 60)
            local s = (time - (m * 60)) - (h * 3600)
            self.candyBarDuration:SetFormattedText(tformat1, h, m, s)
        elseif time > 59.9 then
            local m = floor(time / 60)
            local s = time - (m * 60)
            self.candyBarDuration:SetFormattedText(tformat2, m, s)
        elseif time < 10 then
            self.candyBarDuration:SetFormattedText(tformat3, time)
        else
            self.candyBarDuration:SetFormattedText(tformat4, time)
        end

        self.updater:SetScript("OnLoop", barUpdate)
        self.updater:Play()
        self:Show()
    end
    function barPrototype:Pause()
        if not self.paused then
            self.updater:Pause()
            self.paused = GetTime()
        end
    end
    function barPrototype:Resume()
        if self.paused then
            local t = GetTime()
            self.exp = t + self.remaining
            self.start = self.start + (t - self.paused)
            self.updater:Play()
            self.paused = nil
        end
    end
    function barPrototype:Stop(...)
        cb:Fire("LibCandyBar_Stop", self, ...)
        stopBar(self)
        barCache[self] = true
    end

    function lib:New(texture, width, height)
        local bar = next(barCache)
        if not bar then
            local frame = CreateFrame("Frame", nil, UIParent)
            bar = setmetatable(frame, barPrototype_meta)

            local icon = bar:CreateTexture()
            icon:SetPoint("TOPLEFT")
            icon:SetPoint("BOTTOMLEFT")
            icon:Show()
            bar.candyBarIconFrame = icon

            local statusbar = CreateFrame("StatusBar", nil, bar)
            statusbar:SetPoint("TOPRIGHT")
            statusbar:SetPoint("BOTTOMRIGHT")
            bar.candyBarBar = statusbar

            local bg = statusbar:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bar.candyBarBackground = bg

            local duration = statusbar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
            duration:SetPoint("TOPLEFT", statusbar, "TOPLEFT", 2, 0)
            duration:SetPoint("BOTTOMRIGHT", statusbar, "BOTTOMRIGHT", -2, 0)
            bar.candyBarDuration = duration

            local label = statusbar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
            label:SetPoint("TOPLEFT", statusbar, "TOPLEFT", 2, 0)
            label:SetPoint("BOTTOMRIGHT", statusbar, "BOTTOMRIGHT", -2, 0)
            bar.candyBarLabel = label

            local updater = bar:CreateAnimationGroup()
            updater:SetLooping("REPEAT")
            updater.parent = bar
            local anim = updater:CreateAnimation()
            anim:SetDuration(0.04)
            bar.updater = updater
            bar.repeater = anim
        else
            barCache[bar] = nil
        end

        bar:SetFrameStrata("MEDIUM")
        bar:SetFrameLevel(100)
        bar.candyBarBar:SetStatusBarTexture(texture)
        bar.candyBarBackground:SetTexture(texture)
        bar.width = width
        bar.height = height

        bar.fill = nil
        bar.showTime = true
        bar.showLabel = true
        bar.iconPosition = nil
        for i = 1, numScripts do
            bar:SetScript(scripts[i], nil)
        end

        bar.candyBarBackground:SetVertexColor(0.5, 0.5, 0.5, 0.3)
        bar.candyBarBar:SetStatusBarColor(0.5, 0.5, 0.5, 1)
        bar:ClearAllPoints()
        SetWidth(bar, width)
        SetHeight(bar, height)
        bar:SetMovable(1)
        bar:SetScale(1)
        bar:SetAlpha(1)
        bar:SetClampedToScreen(false)
        bar:EnableMouse(false)

        bar.candyBarLabel:SetTextColor(1, 1, 1, 1)
        bar.candyBarLabel:SetJustifyH("LEFT")
        bar.candyBarLabel:SetJustifyV("MIDDLE")
        bar.candyBarLabel:SetFont(_fontName, _fontSize)
        bar.candyBarLabel:SetShadowOffset(_fontShadowX, _fontShadowY)
        bar.candyBarLabel:SetShadowColor(_fontShadowR, _fontShadowG, _fontShadowB, _fontShadowA)

        bar.candyBarDuration:SetTextColor(1, 1, 1, 1)
        bar.candyBarDuration:SetJustifyH("RIGHT")
        bar.candyBarDuration:SetJustifyV("MIDDLE")
        bar.candyBarDuration:SetFont(_fontName, _fontSize)
        bar.candyBarDuration:SetShadowOffset(_fontShadowX, _fontShadowY)
        bar.candyBarDuration:SetShadowColor(_fontShadowR, _fontShadowG, _fontShadowB, _fontShadowA)

        bar:SetLabel()
        bar:SetIcon()
        bar:SetDuration()

        return bar
    end
end