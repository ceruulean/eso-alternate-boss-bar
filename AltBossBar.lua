local ADDON = "AltBossBar"

local function UpdateStamina(_, _, _, _, value, max)
	d(max)
    local bar = ABBBarStatus
    local label = ABBBarLabel

    bar:SetMinMax(0, max)
    bar:SetValue(value)

    label:SetText(value .. " / " .. max)

end


local function OnLoaded(_, name)

    if name ~= ADDON then return end

    local value, max = GetUnitPower("player", POWERTYPE_STAMINA)

    ABBBarStatus:SetMinMax(0, max)
    ABBBarStatus:SetValue(value)

    EVENT_MANAGER:RegisterForEvent(ADDON, EVENT_POWER_UPDATE, UpdateStamina)

    EVENT_MANAGER:AddFilterForEvent(
        ADDON,
        EVENT_POWER_UPDATE,
        REGISTER_FILTER_UNIT_TAG,
        "player"
    )

    EVENT_MANAGER:AddFilterForEvent(
        ADDON,
        EVENT_POWER_UPDATE,
        REGISTER_FILTER_POWER_TYPE,
        POWERTYPE_STAMINA
    )

end

EVENT_MANAGER:RegisterForEvent(ADDON, EVENT_ADD_ON_LOADED, OnLoaded)