
local NAME = 'AltBossBar'
local SV_VER = 2

local SETTINGS

local ICONSIZE = ZO_COMPASS_FRAME_HEIGHT_KEYBOARD-8

local StupidBossNamesInsteadOfId = {
    ["Ra Kotu"] = { 35, 0 }, ["Ра Коту"] = { 35, 0 },
    ["The Warrior"] = { 35, 0 }, ["Krieger"] = { 35, 0 }, ["Guerrierd"] = { 35, 0 }, ["Воин"] = { 35, 0 },
    ["Yokeda Kai"] = { 30, 0 }, ["Yokeda Kaid"] = { 30, 0 }, ["Йокеда Кай"] = { 30, 0 },
    ["Zhaj'hassa the Forgotten"] = { 70, 30 }, ["Zhaj'hassa der Vergessene"] = { 70, 30 }, ["Zhaj'hassa l'Oublié"] = { 70, 30 }, ["Жай'хасса Забытый"] = { 70, 30 },
    ["Hunter-Killer Negatrix"] = { 30, 0 }, ["Abfänger Negatrix"] = { 30, 0 }, ["Chasseur-tueur négatrix"] = { 30, 0 }, ["Охотник-убийца Негатрикс"] = { 30, 0 },
    ["Hunter-Killer Positrox"] = { 30, 0 }, ["Abfänger Positrox"] = { 30, 0 }, ["Chasseur-tueur positrox"] = { 30, 0 }, ["Охотник-убийца Позитрокс"] = { 30, 0 },
    ["Reactor"] = { 70, 40, 20 }, ["Reaktor"] = { 70, 40, 20 }, ["Réacteur"] = { 70, 40, 20 }, ["Реактор"] = { 70, 40, 20 },
    ["Reducer"] = { 70, 40, 20 }, ["Minderer"] = { 70, 40, 20 }, ["Réducteur"] = { 70, 40, 20 }, ["Редуктор"] = { 70, 40, 20 },
    ["Reclaimer"] = { 70, 40, 20 }, ["Rückforderer"] = { 70, 40, 20 }, ["Récupérateur"] = { 70, 40, 20 }, ["Регенератор"] = { 70, 40, 20 },
    ["Assembly General"] = { 86, 66, 46, 26 }, ["Montagegeneral"] = { 86, 66, 46, 26 }, ["Assembleur général"] = { 86, 66, 46, 26 }, ["Сборочный генерал"] = { 86, 66, 46, 26 },
    ["Saint Olms the Just"] = { 90, 75, 50, 25 }, ["Heiliger Olms der Gerechte"] = { 90, 75, 50, 25 }, ["Saint Olms le Juste"] = { 90, 75, 50, 25 }, ["Святой Олмс Справедливый"] = { 90, 75, 50, 25 },
    ["Foundation Stone Atronach"] = { 75, 25 }, ["Grundsteinatronach"] = { 75, 25 }, ["Atronach de pierre des fondationsm"] = { 75, 25 }, ["Фундаментальный каменный атронах"] = { 75, 25 },
    ["The Mage"] = { 16, 0 }, ["Magierin"] = { 16, 0 }, ["Maged"] = { 16, 0 }, ["Маг"] = { 16, 0 },
    ["Tree-Minder Na-Kesh"] = { 70, 40 }, ["Baumhirtin Na-Kesh"] = { 70, 40 }, ["Sylvegarde Na-Keshd"] = { 70, 40 }, ["Древохранительница На-Кеш"] = { 70, 40 },
    ["Domihaus the Bloody-Horned"] = { 80, 60, 40, 25 }, ["Domihaus der Blutgehörnte"] = { 80, 60, 40, 25 }, ["Domihaus Corne-Sanglante"] = { 80, 60, 40, 25 }, ["Домихаус Кровавые Рога"] = { 80, 60, 40, 25 },
    ["Hiath the Battlemaster"] = { 75, 45, 20 }, ["Hiath der Kampfmeister"] = { 75, 45, 20 }, ["Hiath le Maître de guerre"] = { 75, 45, 20 }, ["Хиат Полководец"] = { 75, 45, 20 },
    ["Stonebreaker"] = { 75, 50, 25 }, ["Steinbrecher"] = { 75, 50, 25 }, ["Briseroc"] = { 75, 50, 25 }, ["Камнелом"] = { 75, 50, 25 },
    ["Velidreth"] = { 65, 30 }, ["Велидрет"] = { 65, 30 },
    ["Ash Titan"] = { 65, 35 }, ["Aschtitan"] = { 65, 35 }, ["Titan de cendres"] = { 65, 35 }, ["Пепельный титан"] = { 65, 35 },
    ["Stormfist"] = { 70, 40 }, ["Sturmfaust"] = { 70, 40 }, ["Poigne-tempête"] = { 70, 40 }, ["Штормовой Кулак"] = { 70, 40 },
    ["Valkyn Skoria"] = { 60, 20 }, ["Валкин Скория"] = { 60, 20 },
    ["Zaan the Scalecaller"] = { 80, 60, 40, 20 }, ["Zaan die Schuppenruferin"] = { 80, 60, 40, 20 }, ["Zaan la Mandécailles"] = { 80, 60, 40, 20 }, ["Заан Призывательница Чешуи"] = { 80, 60, 40, 20 },
    ["Thurvokun"] = { 80, 60, 40, 20 }, ["Турвокун"] = { 80, 60, 40, 20 },
    ["Molag Kena"] = { 60, 30 }, ["Молаг Кена"] = { 60, 30 },
    ["Z'Maja"] = { 75, 50, 25, 5 }, ["З'Маджа"] = { 75, 50, 25, 5 },
    ["Tarcyr"] = { 80, 50, 20 }, ["Тарсир"] = { 80, 50, 20 },
    ["Doylemish Ironheart"] = { 80, 60, 40, 20 }, ["Doylemish Eisenherz"] = { 80, 60, 40, 20 }, ["Doylemish Cœur-de-Fer"] = { 80, 60, 40, 20 }, ["Дойлемиш Железное Сердце"] = { 80, 60, 40, 20 },
    ["Vykosa the Ascendant"] = { 90, 70, 50, 30 }, ["Vykosa die Aufgestiegene"] = { 90, 70, 50, 30 }, ["Vykosa l'Ascendante"] = { 90, 70, 50, 30 }, ["Вайкоса Вознесшаяся"] = { 90, 70, 50, 30 },
    ["Tames-the-Beast"] = { 60, 40 }, ["Zähmt-die-Bestien"] = { 60, 40 }, ["Dompte-la-Bête"] = { 60, 40 }, ["Приручает-Чудовищ"] = { 60, 40 },
    ["Pinnacle Factotum"] = { 80, 60, 40, 20 }, ["Perfektioniertes Faktotum"] = { 80, 60, 40, 20 }, ["Factotum du Pinnacle"] = { 80, 60, 40, 20 }, ["Вершинный фактотум"] = { 80, 60, 40, 20 },
    ["Balorgh"] = { 80, 60, 40, 20 },
    Yolnahkriin = { 75, 50, 25 },
    Lokkestiiz = { 80, 50, 20 },
    Nahviintaas = { 80, 60, 40 },
}

local function getBossPercentagesByName(name)
    if StupidBossNamesInsteadOfId[name] ~= nil then
        return StupidBossNamesInsteadOfId[name]
    end
    if SETTINGS.SHOW_DEFAULTS then
        return { 75, 50, 25 } -- default Percentages
    end
end

local function getWidth()
    return zo_clamp(GuiRoot:GetWidth() * .35, 400, 800)
end

local PercentLineManager = ZO_ControlPool:Subclass()
function PercentLineManager:New(parent, ...)
    local obj = ZO_ControlPool.New(self, "ABB_HP_Line_Template", parent, "ABB_HP_Line")
    --obj:Initialize( ... )
    return obj
end

local ABB_BossBar = ZO_Object:Subclass()
function ABB_BossBar:New(...)
    local bar = ZO_Object.New(self)
    bar:Initialize(...)
    return bar
end

function ABB_BossBar:Initialize(bossTag, topLevelCtrl, previousBar)
    self.unitTag = bossTag
    self.parent = topLevelCtrl
    self.control = CreateControlFromVirtual("ABB_Frame"..bossTag, topLevelCtrl, "ABB_BossBar")
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

    ZO_StatusBar_SetGradientColor(self.healthBar, ZO_POWER_BAR_GRADIENT_COLORS[POWERTYPE_HEALTH])

    local function PowerUpdateHandlerFunction(unitTag, powerPoolIndex, powerType, powerPool, powerPoolMax)
        self:OnPowerUpdate(powerPool, powerPoolMax, false)
    end
    local powerUpdateEventHandler = ZO_MostRecentPowerUpdateHandler:New("BossBar"..bossTag, PowerUpdateHandlerFunction)
    powerUpdateEventHandler:AddFilterForEvent(REGISTER_FILTER_POWER_TYPE, POWERTYPE_HEALTH)
    powerUpdateEventHandler:AddFilterForEvent(REGISTER_FILTER_UNIT_TAG, bossTag)
    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function() self:UpdateWidth() end)
    self.control:RegisterForEvent(EVENT_SCREEN_RESIZED, function() self:UpdateWidth() end)
    self.control:RegisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() self:ApplyStyle() end)

    self:ApplyStyle()
    self:ApplyAnchors()
end

function ABB_BossBar:CreateLine(percent)
    local line = self.percentLinePool:AcquireObject()
    local x = (self.healthBar:GetWidth() / 100) * percent
    x = x - 9 -- mod for better simmetry cause of healthLeftBgBar
    line:SetAnchor(TOPLEFT, self.healthBar, TOPLEFT, x, 0)
    line:SetAnchor(BOTTOMRIGHT, self.healthBar, TOPLEFT,  x, -0 + self.healthBar:GetHeight())
end

function ABB_BossBar:Refresh(force)
    local bossName = GetUnitName(self.unitTag)
    self.bossPercentages = getBossPercentagesByName(bossName)
    self.percentLinePool:ReleaseAllObjects()
    if self.bossPercentages ~= nil then
        for i = 1, #self.bossPercentages do
            self:CreateLine(self.bossPercentages[i])
        end
    end
    self.nameText:SetText(bossName)
    local health, maxHealth = GetUnitPower(self.unitTag, POWERTYPE_HEALTH)
    self:OnPowerUpdate(health, maxHealth, force)
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
    if self.bossPercentages ~= nil then
        for i = 1, #self.bossPercentages do
            if (percent >= self.bossPercentages[i] and percent <= self.bossPercentages[i] + SETTINGS.NOTIFY_BEFORE_PERCENT) then
                return zo_iconFormat("esoui/art/interaction/questnewavailable.dds", ICONSIZE-8, ICONSIZE-8)..percentText..'%'
            end
        end
    end
    return percentText..'%'
end

function ABB_BossBar:OnPowerUpdate(health, maxHealth, force)
    ZO_StatusBar_SmoothTransition(self.healthBar, health, maxHealth, force)
    self.healthLeftBgBar:SetValue((health > 0 and 1 or 0))

    if health > 0 and not IsUnitDead(self.unitTag) then
        self.healthText:SetText(self:FormatPercent(health, maxHealth))
    else
        self.healthText:SetText(zo_iconFormat("esoui/art/icons/mapkey/mapkey_groupboss.dds", ICONSIZE, ICONSIZE))
    end
end

function ABB_BossBar:ApplyAnchors()
    self.control:ClearAnchors()
    if self.previousBar ~= nil then
        self.previousBar.nextBar = self
        self.control:SetAnchor(TOP, self.previousBar.control, BOTTOM)
    else
        self.control:SetAnchor(TOP, self.parent, BOTTOM)
    end
end

function ABB_BossBar:ApplyStyle()
    ApplyTemplateToControl(self.control, ZO_GetPlatformTemplate("ABB_BossBar"))
    self:UpdateWidth()
end

function ABB_BossBar:UpdateWidth()
    self.control:SetWidth(getWidth())
end

function ABB_BossBar:Show()
    self.control:SetHidden(false)
end

function ABB_BossBar:Hide()
    self.control:SetHidden(true)
    if self.nextBar ~= nil then
        self.nextBar:Hide()
    end
end

local function AttachTargetTo(control)
    local targetFrame = UNIT_FRAMES:GetFrame("reticleover")
    local targetControl = targetFrame.frame
    targetControl:ClearAnchors()
    targetControl:SetAnchor(TOP, control, BOTTOM, 0, 5)
end

local bossBars = {}

local function InitBars(topLevelCtrl)
    local prevBossBar
    for i = 1, MAX_BOSSES do
        local bossTag = "boss"..i
        bossBars[bossTag] = ABB_BossBar:New(bossTag, topLevelCtrl, prevBossBar)
        prevBossBar = bossBars[bossTag]
    end
end

local function RefreshAllBosses(forceReset)
    local lastBossBar

    for i = 1, MAX_BOSSES do
        local bossTag = "boss"..i

        if DoesUnitExist(bossTag) then
            bossBars[bossTag]:Refresh(forceReset)
            bossBars[bossTag]:Show()
        else
            bossBars[bossTag]:Hide()
            do break end
        end

        lastBossBar = bossBars[bossTag]
    end

    if lastBossBar ~= nil then
        COMPASS_FRAME_FRAGMENT:SetHiddenForReason("ABBar", true)
        AttachTargetTo(lastBossBar.control)
    else
        COMPASS_FRAME_FRAGMENT:SetHiddenForReason("ABBar", false)
        AttachTargetTo(ZO_CompassFrame)
    end
end

ABB_FakeGloss = ZO_Object:Subclass()
function ABB_FakeGloss:New()
    return ZO_Object.New(self)
end
function ABB_FakeGloss:SetMinMax() end
function ABB_FakeGloss:SetValue() end

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
        version = string.format('|c00FF00%s|r', 1),
        registerForRefresh = true,
    })

    LAM2:RegisterOptionControls("ABB_Settings", {
        {
            type = "checkbox",
            name = "Show Default Percent Lines (75%, 50%, 25%)",
            getFunc = function() return SETTINGS.SHOW_DEFAULTS end,
            setFunc = function(newValue)
                SETTINGS.SHOW_DEFAULTS = newValue
                RefreshAllBosses()
            end,
        },
        {
            type = "slider",
            name = 'Number of %, BEFORE showing alert icon',
            min = 0,
            max = 5,
            step = 1,
            getFunc = function() return SETTINGS.NOTIFY_BEFORE_PERCENT end,
            setFunc = function(newValue)
                SETTINGS.NOTIFY_BEFORE_PERCENT = zo_round(newValue)
                RefreshAllBosses()
            end,
        },
    })
end

function ABB_Initialize(topLevelCtrl)

    local function OnAddOnLoaded(_, addonName)
        if addonName == NAME then

            SETTINGS = ZO_SavedVars:NewCharacterIdSettings("AltBossBarSavedVariables", SV_VER, nil, {
                SHOW_DEFAULTS = false,
                NOTIFY_BEFORE_PERCENT = 2,
            })

            InitializeAddonMenu()

            COMPASS_FRAME:SetBossBarHiddenForReason('modded', true)
            local fragment = ZO_SimpleSceneFragment:New(topLevelCtrl)
            HUD_SCENE:AddFragment(fragment)
            HUD_UI_SCENE:AddFragment(fragment)

            InitBars(topLevelCtrl)
            topLevelCtrl:RegisterForEvent(EVENT_BOSSES_CHANGED, function(_, forceReset) RefreshAllBosses(forceReset) end)
            topLevelCtrl:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function() RefreshAllBosses() end)

            EVENT_MANAGER:UnregisterForEvent(NAME, EVENT_ADD_ON_LOADED)
        end
    end

    EVENT_MANAGER:RegisterForEvent(NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
end
