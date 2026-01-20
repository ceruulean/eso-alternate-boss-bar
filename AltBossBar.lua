local NAME = 'AltBossBar'
local SV_VER = 3

local SETTINGS

local ICONSIZE = ZO_COMPASS_FRAME_HEIGHT_KEYBOARD-8
local ABB_TEMPLATE_NAME = "ABB_BossBar_Emb"
local FN_ABB_GET_WIDTH = nil

local THEME_OFFSET = 0

local OVERSHIELD_COLOR_START = ZO_ColorDef:New("392952")
local OVERSHIELD_COLOR_END = ZO_ColorDef:New("968498")
local UNWAVERING_COLOR_START = ZO_ColorDef:New("7D7750")
local UNWAVERING_COLOR_END = ZO_ColorDef:New("DDDDCB")

local OVERSHIELD_GRADIENT = { OVERSHIELD_COLOR_START, OVERSHIELD_COLOR_END }
local UNWAVERING_GRADIENT = { UNWAVERING_COLOR_START, UNWAVERING_COLOR_END }

-- equal to ZO_POWER_BAR_GRADIENT_COLORS[COMBAT_MECHANIC_FLAGS_HEALTH]
local DEFAULT_HP_COLOR_START = { 0.447, 0.137, 0.137 }
local DEFAULT_HP_COLOR_END = { 0.855, 0.188, 0.188 }

local THEMES = {
    ["Plain"] = {
        template = "ABB_BossBar",
        calcWidth = function() return GuiRoot:GetWidth() * 0.35 end
    },
    ["Embellished"] = {
        template = "ABB_BossBar_Emb",
        calcWidth = function() return GuiRoot:GetWidth() * 0.35 - 20 end
    }
}

local function getWidth()
    if FN_ABB_GET_WIDTH ~= nil then return zo_clamp(FN_ABB_GET_WIDTH(), 400, 800) end
    return zo_clamp(GuiRoot:GetWidth() * .35, 400, 800)
end

local PercentLineManager = ZO_ControlPool:Subclass()
function PercentLineManager:New(parent, ...)
    local obj = ZO_ControlPool.New(self, "ABB_HP_Line_"..SETTINGS.PERCENTAGE_LINE_STYLE.."_Template", parent, "ABB_HP_Line")
    --obj:Initialize( ... )
    return obj
end

local bossBars = {}
currentBossHealth = {}
local bossCount = 0
local CONSOLIDATE_BARS = false

local ABB_BossBar = ZO_Object:Subclass()
function ABB_BossBar:New(...)
    local bar = ZO_Object.New(self)
    bar:Initialize(...)
    return bar
end

function ABB_BossBar:Initialize(bossTag, topLevelCtrl, previousBar)
    self.unitTag = bossTag
    self.parent = topLevelCtrl
    self.control = CreateControlFromVirtual("ABB_Frame"..bossTag, topLevelCtrl, ABB_TEMPLATE_NAME)
    self.control:SetHidden(true)
    local healthControl = GetControl(self.control, "Health")
    self.nameText = GetControl(healthControl, "Name")
    self.healthText = GetControl(healthControl, "Text")
    self.healthBar = GetControl(healthControl, "Bar")
    self.healthLeftBgBar = GetControl(healthControl, "LeftBgBar")
    self.previousBar = previousBar
    self.nextBar = nil
    self.percentLinePool = PercentLineManager:New(self.healthBar)
    self.bossPercentages = nil
    self.hasShield = false
    self.hasImmunity = false
    self.bracketLeft = self.control:GetNamedChild("BracketLeft")
    self.bracketRight = self.control:GetNamedChild("BracketRight")
    self.scaleX = 1.0
    self.shouldWarn = false
    self.warner = GetControl(self.control, "Warner")
    self.warnerAnimation = ZO_AlphaAnimation:New(self.warner)

    local function PowerUpdateHandlerFunction(unitTag, powerPoolIndex, powerType, powerPool, powerPoolMax)
        self:OnPowerUpdate(unitTag, powerPool, powerPoolMax, false)
    end
    local powerUpdateEventHandler = ZO_MostRecentPowerUpdateHandler:New("BossBar"..bossTag, PowerUpdateHandlerFunction)
    powerUpdateEventHandler:AddFilterForEvent(REGISTER_FILTER_POWER_TYPE, POWERTYPE_HEALTH)
    
    if bossTag == "reticleover" then
        powerUpdateEventHandler:AddFilterForEvent(REGISTER_FILTER_UNIT_TAG, bossTag)
    else
        powerUpdateEventHandler:AddFilterForEvent(REGISTER_FILTER_UNIT_TAG_PREFIX, "boss")
    end

    self:RegisterUnit(bossTag)
    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function() self:UpdateWidth() end)
    self.control:RegisterForEvent(EVENT_SCREEN_RESIZED, function() self:UpdateWidth() end)
    
    self:ResetColors()
    self:ApplyStyle()
    self:ApplyAnchors()
end

function ABB_BossBar:RegisterUnit(unitTag)
    self:UnregisterUnit()
    self.unitTag = unitTag
    self.control:RegisterForEvent(EVENT_UNIT_ATTRIBUTE_VISUAL_ADDED, function(eventCode, unitTag, ...) self:OnUavUpdate(...) end)
    self.control:AddFilterForEvent(EVENT_UNIT_ATTRIBUTE_VISUAL_ADDED, REGISTER_FILTER_UNIT_TAG, self.unitTag)
    self.control:RegisterForEvent(EVENT_UNIT_ATTRIBUTE_VISUAL_UPDATED, function(eventCode, unitTag, ...) self:OnUavUpdate(...) end)
    self.control:AddFilterForEvent(EVENT_UNIT_ATTRIBUTE_VISUAL_UPDATED, REGISTER_FILTER_UNIT_TAG, self.unitTag)
    self.control:RegisterForEvent(EVENT_UNIT_ATTRIBUTE_VISUAL_REMOVED, function(eventCode, unitTag, ...) self:OnUavRemoval(...) end)
    self.control:AddFilterForEvent(EVENT_UNIT_ATTRIBUTE_VISUAL_REMOVED, REGISTER_FILTER_UNIT_TAG, self.unitTag)
end

function ABB_BossBar:UnregisterUnit()
    self.control:UnregisterForEvent(EVENT_UNIT_ATTRIBUTE_VISUAL_ADDED)
    self.control:UnregisterForEvent(EVENT_UNIT_ATTRIBUTE_VISUAL_UPDATED)
    self.control:UnregisterForEvent(EVENT_UNIT_ATTRIBUTE_VISUAL_REMOVED)
end

local instancedBosses = {}

function ABB_BossBar:SetBossPercentages(name, maxHealth)
    if CrutchAlerts and SETTINGS.USE_CRUTCHALERTS_TH and (CrutchAlerts.BossHealthBar.thresholds[name]) then
        local thresholds = CrutchAlerts.BossHealthBar.thresholds[name]
        self.bossPercentages = {}
        local thresholds_mode = thresholds
        if (thresholds.hmHealth == maxHealth) then
            thresholds_mode = thresholds.Hardmode or thresholds
        elseif (thresholds.vetHealth == maxHealth) then
            thresholds_mode = thresholds.Veteran or thresholds
        elseif (thresholds.Normal ~= nil) then
            thresholds_mode = thresholds.Normal or thresholds
        end
        for key, _ in pairs(thresholds_mode) do
            if type(key) == "number" then table.insert(self.bossPercentages, key) end
        end
        self.shouldWarn = true
        return
    end
    if instancedBosses[name] ~= nil then
        self.bossPercentages = instancedBosses[name]
        self.shouldWarn = true
        return
    end
    if CONSOLIDATE_BARS then -- assumes all bosses have equal hp
        local n = 100.0 / bossCount
        self.bossPercentages = {}
        for i = 1, bossCount - 1 do
            table.insert(self.bossPercentages, zo_round(i * n) )
        end
    elseif SETTINGS.SHOW_DEFAULTS then
        self.bossPercentages = { 75, 50, 25 } -- default Percentages
    else 
        self.bossPercentages = nil
    end
    self.shouldWarn = false
end

function ABB_BossBar:CreateLine(percent)
    local line = self.percentLinePool:AcquireObject()
    local x = (self.healthBar:GetWidth() / 100) * percent
    if SETTINGS.THEME_NAME == "Embellished" then
        x = x - 8.5
    else
        x = x - 9 -- mod for better simmetry cause of healthLeftBgBar
    end
    line:SetAnchor(TOPLEFT, self.healthBar, TOPLEFT, x, 0)
    line:SetAnchor(BOTTOMRIGHT, self.healthBar, TOPLEFT,  x, -0 + self.healthBar:GetHeight())
end

function ABB_BossBar:Refresh(force)
    if force then
        self:ApplyStyle()
        self:ResetColors()
        self:ApplyAnchors()
    else
        self:UpdateWidth()
    end
    if DoesUnitExist(self.unitTag) then
        local rawName = GetRawUnitName(self.unitTag)
        local health, maxHealth = GetUnitPower(self.unitTag, POWERTYPE_HEALTH)
        currentBossHealth[self.unitTag] = { health = health, maxHealth = maxHealth }
        self:SetBossPercentages(rawName, maxHealth)
        self.percentLinePool:ReleaseAllObjects()
        if self.bossPercentages ~= nil then
            for i = 1, #self.bossPercentages do
                self:CreateLine(self.bossPercentages[i])
            end
        end
        self.nameText:SetText(zo_strformat(SI_UNIT_NAME, rawName))
        self:OnPowerUpdate(self.unitTag, health, maxHealth, force)
    end
end

function ABB_BossBar:FormatPercent(health, maxHealth)
    local percent = 0
    local percentText
    if maxHealth ~= 0 then
        percent = (health / maxHealth) * 100
    end
    if percent < 10 then
        percentText = ZO_CommaDelimitDecimalNumber(zo_roundToNearest(percent, .1))
        percentText = ZO_FastFormatDecimalNumber(percentText)
    else
        percentText = zo_round(percent)
    end
    if self.bossPercentages ~= nil and SETTINGS.NOTIFY_ALERT then
        for i = 1, #self.bossPercentages do
            if (percent >= self.bossPercentages[i] and percent <= self.bossPercentages[i] + SETTINGS.NOTIFY_BEFORE_PERCENT) then
                if SETTINGS.NOTIFY_ALERT_TYPE == "Flash" then
                    self:FlashWarning()
                else
                    return zo_iconFormat("esoui/art/interaction/questnewavailable.dds", ICONSIZE-8, ICONSIZE-8)..percentText..'%'
                end
            end
        end
    end
    return percentText..'%'
end

function ABB_BossBar:SetHealthText(health, maxHealth)
    self.healthLeftBgBar:SetValue((health > 0 and 1 or 0))
    if health > 0 and not IsUnitDead(self.unitTag) then
        self.healthText:SetText(ZO_AbbreviateAndLocalizeNumber(health, NUMBER_ABBREVIATION_PRECISION_TENTHS, false) .. " " .. self:FormatPercent(health, maxHealth))
    else
        self.healthText:SetText(zo_iconFormat("esoui/art/icons/mapkey/mapkey_groupboss.dds", ICONSIZE, ICONSIZE))
    end
end

function ABB_BossBar:OnPowerUpdate(sourceUnit, health, maxHealth, force)
    -- redo percent lines on hardmode activation
    if currentBossHealth[self.unitTag] and currentBossHealth[self.unitTag].maxHealth ~= maxHealth then
        self:Refresh(true)
    end

    local function RefreshConsolidatedHpBar(barframe, textframe, force)
        local totalHp = 0
        local currentHp = 0
        for unitTag, bossEntry in pairs(currentBossHealth) do
            currentHp = currentHp + bossEntry.health
            totalHp = totalHp + bossEntry.maxHealth
        end
        ZO_StatusBar_SmoothTransition(barframe, currentHp, totalHp, force)
        self:SetHealthText(currentHp, totalHp)
    end
    if CONSOLIDATE_BARS and self.unitTag == bossBars[1].unitTag then
        if currentBossHealth[sourceUnit] ~= nil then
            local health, maxHealth = GetUnitPower(sourceUnit, POWERTYPE_HEALTH)
            currentBossHealth[sourceUnit].health = health
            currentBossHealth[sourceUnit].maxHealth = maxHealth
        end
        RefreshConsolidatedHpBar(self.healthBar, self.healthText, force)
        return
    end

    if sourceUnit ~= self.unitTag then
        return
    end
    ZO_StatusBar_SmoothTransition(self.healthBar, health, maxHealth, force)
    self:SetHealthText(health, maxHealth)
end

function ABB_BossBar:OnUavUpdate(unitAttributeVisual, _, _, _, value1)
    if (unitAttributeVisual == ATTRIBUTE_VISUAL_UNWAVERING_POWER) then
        if value1 ~= nil and value1 > 0 then
            if not self.hasImmunity then
                self.hasImmunity = true
                ZO_StatusBar_SetGradientColor(self.healthBar, UNWAVERING_GRADIENT)
                self.healthLeftBgBar:SetColor(UNWAVERING_COLOR_START:UnpackRGBA())
            end
        else
            self:OnUavRemoval(unitAttributeVisual)
        end
        return
    end
    if (unitAttributeVisual == ATTRIBUTE_VISUAL_POWER_SHIELDING and not self.hasImmunity) then
        if value1 ~= nil and value1 > 0 then
            if not self.hasShield then
                self.hasShield = true
                ZO_StatusBar_SetGradientColor(self.healthBar, OVERSHIELD_GRADIENT)
                self.healthLeftBgBar:SetColor(OVERSHIELD_COLOR_START:UnpackRGBA())
            end
        else
            self:OnUavRemoval(unitAttributeVisual)
        end
    end
end

function ABB_BossBar:OnUavRemoval(unitAttributeVisual)
    if (unitAttributeVisual == ATTRIBUTE_VISUAL_UNWAVERING_POWER) then
        if self.hasImmunity then
            self.hasImmunity = false
            self:ResetColors()
        end
        return
    end
    if (unitAttributeVisual == ATTRIBUTE_VISUAL_POWER_SHIELDING and not self.hasImmunity) then
        if self.hasShield then
            self.hasShield = false
            self:ResetColors()
        end
    end
end

function ABB_BossBar:ResetColors()
    local gradient = {ZO_ColorDef:New(unpack(SETTINGS.HP_COLOR_START) ), ZO_ColorDef:New(unpack(SETTINGS.HP_COLOR_END))}
    ZO_StatusBar_SetGradientColor(self.healthBar, gradient)
    self.healthLeftBgBar:SetColor(gradient[1]:UnpackRGBA())
end

function ABB_BossBar:ApplyAnchors()
    self.control:ClearAnchors()
    if self.previousBar ~= nil then
        self.previousBar.nextBar = self
        self.control:SetAnchor(TOP, self.previousBar.control, BOTTOM)
    else
        -- Only apply to the first bar
        self.control:SetAnchor(TOPLEFT, self.parent, TOPLEFT, 0, 0)
        -- self.warner:SetWidth(getWidth() * self.scaleX)
        if SETTINGS.THEME_NAME == "Embellished" then
            self.bracketLeft:SetHidden(false)
            self.bracketRight:SetHidden(false)
        end
    end
end

function ABB_BossBar:ApplyStyle()
    ApplyTemplateToControl(self.control, ZO_GetPlatformTemplate(ABB_TEMPLATE_NAME))
    self:UpdateWidth()
end

function ABB_BossBar:UpdateWidth()
    self.control:SetWidth(getWidth() * self.scaleX)
end

function ABB_BossBar:Show()
    self.control:SetHidden(false)
    self.control:SetAlpha(1)
end

function ABB_BossBar:Hide()
    self.control:SetHidden(true)
    self.hasShield = false
    self.hasImmunity = false
    self:ResetColors()
    if self.nextBar ~= nil then
        self.nextBar:Hide()
    end
end

function ABB_BossBar:FlashWarning()
    local RESOURCE_WARNER_FLASH_TIME = 300
    local RESOURCE_WARNER_NUM_FLASHES = 3
    if not self.shouldWarn then return end
    if not self.warnerAnimation:IsPlaying() then
        self.warnerAnimation:PingPong(0, 1, RESOURCE_WARNER_FLASH_TIME, RESOURCE_WARNER_NUM_FLASHES)
    else
        --Reset the animation by making it do RESOURCE_WARNER_NUM_FLASHES after this point
        local remainingLoops = self.warnerAnimation:GetPlaybackLoopsRemaining()
        local newLoops = RESOURCE_WARNER_NUM_FLASHES
        --If we're on the backswing of the ping pong we need to do one addition loop to make sure it ends in the alpha down state, otherwise it stops at full alpha
        if remainingLoops % 2 == 0 then
            newLoops = newLoops + 1
        end
        self.warnerAnimation:SetPlaybackLoopCount(newLoops)
    end
end

local function AttachTargetTo(control)
    local targetFrame = UNIT_FRAMES:GetFrame("reticleover")
    local targetControl = targetFrame.frame
    targetControl:ClearAnchors()
    targetControl:SetAnchor(TOP, control, BOTTOM, 0, 5)
end

local function InitBars(topLevelCtrl)
    local prevBossBar

    for i = 1, MAX_BOSSES do
        local bossTag = "boss"..i
        bossBars[i] = ABB_BossBar:New(bossTag, topLevelCtrl, prevBossBar)
        prevBossBar = bossBars[i]
    end
    
    if SETTINGS.INCLUDE_DUMMY then
        bossBars[MAX_BOSSES + 1] = ABB_BossBar:New("reticleover", topLevelCtrl)
    end
end

local function ScaleBossBars()
    local highestHealthValue = 1
    local bossOrder = {}
    
    if SETTINGS.SCALE_HP_PROPORTION then
        for i = 1, MAX_BOSSES do
            local bossTag = "boss"..i
            local _, maxHealth = GetUnitPower(bossTag, POWERTYPE_HEALTH)
            table.insert(bossOrder, { tag = bossTag, maxhp = maxHealth})
            if maxHealth > highestHealthValue then
                highestHealthValue = maxHealth
            end
        end

        table.sort(bossOrder, function(a,b) return a.maxhp > b.maxhp end)
        for i, val in ipairs(bossOrder) do
            bossBars[i]:RegisterUnit(val.tag)
            bossBars[i].scaleX = zo_clamp(val.maxhp / highestHealthValue, 0.5, 1.0)
        end
    else
        for i = 1, MAX_BOSSES do
            bossBars[i].scaleX = 1.0
        end
    end
end

local function ConsolidateBars(forceReset)
    local aliveBossCount = 0
    --if there are multiple bosses and one of them dies and despawns in the middle of the fight we
    --still show them as part of the boss bar (otherwise it'll reset to 100%).
    for i = 1, MAX_BOSSES do
        local unitTag = "boss" .. i
        if DoesUnitExist(unitTag) then
            local h, m = GetUnitPower(unitTag, COMBAT_MECHANIC_FLAGS_HEALTH)
            currentBossHealth[unitTag] = { health = h, maxHealth = m}
            aliveBossCount = aliveBossCount + 1
        end
    end

    if aliveBossCount > 0 then
        bossCount = math.max(bossCount, aliveBossCount)
        bossBars[1].scaleX = 1.0
        bossBars[1]:Show()
    else
        bossCount = 0
        bossBars[1]:Hide()
    end

    if forceReset or (aliveBossCount == 0 and next(currentBossHealth) ~= nil) then
        currentBossHealth = {}
        for i = 1, MAX_BOSSES do
            bossBars[i]:Hide()
        end
    else
        bossBars[1]:Refresh(forceReset)
    end
end

local function RefreshAllBosses(forceReset)
    local abbContainer = GetControl("ABB_Container")
    local lastBossBar

    if CONSOLIDATE_BARS then
        ConsolidateBars(forceReset)
        lastBossBar = bossBars[1]
    else
        ScaleBossBars()
        for i = 1, MAX_BOSSES do
            if DoesUnitExist(bossBars[i].unitTag) then
                bossBars[i]:Refresh(forceReset)
                bossBars[i]:Show()
            else
                bossBars[i]:Hide()
                do break end
            end
            lastBossBar = bossBars[i]
        end
    end

    if lastBossBar ~= nil then
        COMPASS_FRAME_FRAGMENT:SetHiddenForReason("ABBar", SETTINGS.REPLACE_COMPASS)
        AttachTargetTo(lastBossBar.control)
    else
        COMPASS_FRAME_FRAGMENT:SetHiddenForReason("ABBar")
        AttachTargetTo(ZO_CompassFrame)
    end
end

local function RefreshExtraBar()
    local i = MAX_BOSSES + 1
    local isDummy = GetUnitType(bossBars[i].unitTag) == 12
    if isDummy and DoesUnitExist(bossBars[i].unitTag) then
        bossBars[i]:Refresh(forceReset)
        bossBars[i]:Show()
    else
        bossBars[i]:Hide()
    end
end

local function InOsseinCageShaperMap()
    return (GetZoneId(GetUnitZoneIndex("player")) == 1548 and (GetMapTileTexture():match('Art/maps/dungeons/OssCage_Section1Map002_0.dds')))
end

local function OnPlayerZoneChange(topLevelCtrl)
    if (GetCurrentZoneHouseId() > 0) and SETTINGS.INCLUDE_DUMMY then
        topLevelCtrl:RegisterForEvent(EVENT_RETICLE_TARGET_CHANGED, function() RefreshExtraBar() end)
    else
        topLevelCtrl:UnregisterForEvent(EVENT_RETICLE_TARGET_CHANGED)
    end
    -- Ossein Cage Shapers of Flesh
    if SETTINGS.CONSOLIDATE_SHAPERS and InOsseinCageShaperMap() then
        CONSOLIDATE_BARS = true
    else
        CONSOLIDATE_BARS = false
    end
	instancedBosses = BossData:GetInstanceThresholds()
    RefreshAllBosses(true)
end

ABB_FakeGloss = ZO_Object:Subclass()
function ABB_FakeGloss:New()
    return ZO_Object.New(self)
end
function ABB_FakeGloss:SetMinMax() end
function ABB_FakeGloss:SetValue() end

local function SetVisualSettings()
    local offset = SETTINGS.REPLACE_COMPASS and 0 or ZO_CompassFrame:GetHeight()
    local container = GetControl("ABB_Container")
    container:SetAnchor(TOPLEFT, ZO_CompassFrame, TOPLEFT, 0, offset)
    ABB_TEMPLATE_NAME = THEMES[SETTINGS.THEME_NAME or "Plain"].template
    FN_ABB_GET_WIDTH = THEMES[SETTINGS.THEME_NAME or "Plain"].calcWidth
end

-------------------------------------
--Settings Menu--
-------------------------------------
local function InitializeAddonMenu()
    local LAM2 = LibAddonMenu2

    LAM2:RegisterAddonPanel("ABB_Settings", {
        type = "panel",
        name = "Alternative Boss Bars",
        displayName = "Alternative Boss Bars",
        author = "|c943810BulDeZir|r",
        version = string.format('|c00FF00%s|r', 3.2),
        registerForRefresh = true,
        registerForDefaults = true,
    })

    LAM2:RegisterOptionControls("ABB_Settings", {
        {
            type = "checkbox",
            name = "Replace compass",
            tooltip = "If turned off, HP bars will show under the compass instead of replacing it.",
            getFunc = function() return SETTINGS.REPLACE_COMPASS end,
            setFunc = function(newValue)
                SETTINGS.REPLACE_COMPASS = newValue
                SetVisualSettings()
                RefreshAllBosses(true)
            end,
            default = true,
        },
        {
            type = "checkbox",
            name = "Proportional Bars",
            tooltip = "Bosses with less max HP have shorter bars, and bars are sorted from most to least HP.",
            getFunc = function() return SETTINGS.SCALE_HP_PROPORTION end,
            setFunc = function(newValue)
                SETTINGS.SCALE_HP_PROPORTION = newValue
                RefreshAllBosses(true)
            end,
            default = false,
        },
        {
            type = "checkbox",
            name = "Include Combat Dummies",
            requiresReload = true,
            tooltip = "Show boss bar when fighting a dummy.",
            getFunc = function() return SETTINGS.INCLUDE_DUMMY end,
            setFunc = function(newValue)
                SETTINGS.INCLUDE_DUMMY = newValue
            end,
            default = false,
        },
        {
            type = "divider",
            height = 3,
            alpha = 1,
            width = "full"
        },
        {
            type = "checkbox",
            name = "Show Default Percent Lines (75%, 50%, 25%)",
            getFunc = function() return SETTINGS.SHOW_DEFAULTS end,
            setFunc = function(newValue)
                SETTINGS.SHOW_DEFAULTS = newValue
                RefreshAllBosses()
            end,
            default = false,
        },
        {
            type = "checkbox",
            name = "Use CrutchAlerts Thresholds",
            tooltip = "If CrutchAlerts is installed, use their mechanic thresholds instead.",
            getFunc = function() return SETTINGS.USE_CRUTCHALERTS_TH end,
            setFunc = function(newValue)
                SETTINGS.USE_CRUTCHALERTS_TH = newValue
                RefreshAllBosses()
            end,
            default = false,
            warning = function()
                if not (CrutchAlerts) then return "CrutchAlerts is not active." else return nil end
            end,
            disabled = function() return not CrutchAlerts end,
            width = "full"
        },
        {
            type = "checkbox",
            name = "Alert Notification",
            tooltip = "Whether the HP bar displays an alert for percent-based mechanics.",
            getFunc = function() return SETTINGS.NOTIFY_ALERT end,
            setFunc = function(newValue)
                SETTINGS.NOTIFY_ALERT = newValue
                RefreshAllBosses()
            end,
            default = false,
            width = "half"
        },
        {
            type = "slider",
            name = "Threshold (%)",
            tooltip = "Number of percent (%), BEFORE showing alert.",
            min = 0,
            max = 5,
            step = 1,
            getFunc = function() return SETTINGS.NOTIFY_BEFORE_PERCENT end,
            setFunc = function(newValue)
                SETTINGS.NOTIFY_BEFORE_PERCENT = zo_round(newValue)
                RefreshAllBosses()
            end,
            disabled = function() return not SETTINGS.NOTIFY_ALERT end,
            default = 2,
            width = "half"
        },
        {
            type = "dropdown",
            name = "Alert Type",
            tooltip = "'Icon' displays an icon near the HP total. 'Flash' makes the bar flash with a red glow.",
            choices = {"Icon", "Flash"},
            getFunc = function() return SETTINGS.NOTIFY_ALERT_TYPE end,
            setFunc = function(newValue)
                SETTINGS.NOTIFY_ALERT_TYPE = newValue
            end,
            disabled = function() return not SETTINGS.NOTIFY_ALERT end,
            default = "Flash"
        },
        {
            type = "divider",
            height = 5,
            alpha = 1,
            width = "full"
        },
        {
            type = "colorpicker",
            name = "HP Color Gradient Start",
            getFunc = function() return unpack(SETTINGS.HP_COLOR_START) end,
            setFunc = function(r,g,b,a)
                SETTINGS.HP_COLOR_START = { r,g,b }
                RefreshAllBosses(true)
            end,
            width = "half",
            default = ZO_POWER_BAR_GRADIENT_COLORS[COMBAT_MECHANIC_FLAGS_HEALTH][1],
        },
        {
            type = "colorpicker",
            name = "HP Color Gradient End",
            getFunc = function() return unpack(SETTINGS.HP_COLOR_END) end,
            setFunc = function(r,g,b,a)
                SETTINGS.HP_COLOR_END = { r,g,b }
                RefreshAllBosses(true)
            end,
            width = "half",
            default = ZO_POWER_BAR_GRADIENT_COLORS[COMBAT_MECHANIC_FLAGS_HEALTH][2],
        },
        {
            type = "dropdown",
            name = "Percentage Line Style",
            requiresReload = true,
            choices = {"Hard", "Soft"},
            getFunc = function() return SETTINGS.PERCENTAGE_LINE_STYLE end,
            setFunc = function(newValue)
                SETTINGS.PERCENTAGE_LINE_STYLE = newValue
                RefreshAllBosses()
            end,
            default = "Hard"
        },
        {
            type = "dropdown",
            name = "Theme",
            requiresReload = true,
            choices = {"Plain", "Embellished"},
            getFunc = function() return SETTINGS.THEME_NAME end,
            setFunc = function(newValue)
                SETTINGS.THEME_NAME = newValue
                RefreshAllBosses()
            end,
            default = "Plain"
        },
        {
            type = "divider",
            height = 5,
            alpha = 1,
            width = "full"
        },
        {
            type = "checkbox",
            name = "Ossein Cage: Consolidate Shapers",
            tooltip = "Display the Shapers of Flesh as one bar.",
            getFunc = function() return SETTINGS.CONSOLIDATE_SHAPERS end,
            setFunc = function(newValue)
                SETTINGS.CONSOLIDATE_SHAPERS = newValue
                if InOsseinCageShaperMap() then CONSOLIDATE_BARS = newValue end
                RefreshAllBosses(true)
            end,
            default = false,
            width = "full"
        }
    })
end

function ABB_Initialize(topLevelCtrl)
    local function OnAddOnLoaded(_, addonName)
        if addonName == NAME then

            SETTINGS = ZO_SavedVars:NewAccountWide("AltBossBarSavedVariables", SV_VER, nil, {
                REPLACE_COMPASS = true,
                SHOW_DEFAULTS = false,
                INCLUDE_DUMMY = false,
                PERCENTAGE_LINE_STYLE = "Hard",
                USE_CRUTCHALERTS_TH = false,
                NOTIFY_ALERT = false,
                NOTIFY_BEFORE_PERCENT = 2,
                NOTIFY_ALERT_TYPE = "Flash",
                SCALE_HP_PROPORTION = false,
                HP_COLOR_START = DEFAULT_HP_COLOR_START,
                HP_COLOR_END = DEFAULT_HP_COLOR_END,
                THEME_NAME = "Plain",
                CONSOLIDATE_SHAPERS = false,
            })

            InitializeAddonMenu()

            COMPASS_FRAME:SetBossBarHiddenForReason('modded', true)
            local fragment = ZO_SimpleSceneFragment:New(topLevelCtrl)
            HUD_SCENE:AddFragment(fragment)
            HUD_UI_SCENE:AddFragment(fragment)
            SetVisualSettings()

            InitBars(topLevelCtrl)
            topLevelCtrl:RegisterForEvent(EVENT_BOSSES_CHANGED, function(_, forceReset) RefreshAllBosses(forceReset) end)
            topLevelCtrl:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function() OnPlayerZoneChange(topLevelCtrl) end)
            topLevelCtrl:RegisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() RefreshAllBosses(true) end)

            EVENT_MANAGER:UnregisterForEvent(NAME, EVENT_ADD_ON_LOADED)
        end
    end

    EVENT_MANAGER:RegisterForEvent(NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
end
