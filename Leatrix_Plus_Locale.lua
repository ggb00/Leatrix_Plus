-- Leatrix_Plus_Locale.lua
local _, Leatrix_Plus = ...

Leatrix_Plus.L = setmetatable({}, {
    __index = function(t, key)
        if key ~= nil then
            rawset(t, key, key)
        end
        return key
    end,
})