local DF = LibStub('AceAddon-3.0'):NewAddon('DragonflightUI', 'AceConsole-3.0')
local db

DF.InterfaceVersion = select(4, GetBuildInfo())
DF.Wrath = DF.InterfaceVersion >= 30400
DF.Era = DF.InterfaceVersion <= 20000

local defaults = {
    profile = {
        modules = {['Unitframe'] = true, ['Castbar'] = true, ['Chat'] = true},
        bestnumber = 42
    }
}

function DF:OnInitialize()
    -- Called when the addon is loaded
    self.db = LibStub('AceDB-3.0'):New('DragonflightUIDB', defaults, true)
    db = self.db.profile
    self:SetupOptions()
    self:RegisterSlashCommands()
end

function DF:OnEnable()
    -- Called when the addon is enabled
    --self:Print('DragonflightUI enabled!')
    self:ShowStartMessage()
end

function DF:OnDisable()
    -- Called when the addon is disabled
end

function DF:GetModuleEnabled(module)
    return db.modules[module]
end

function DF:SetModuleEnabled(module, value)
    local old = db.modules[module]
    db.modules[module] = value
    if old ~= value then
        if value then
            self:EnableModule(module)
        else
            self:DisableModule(module)
        end
        self:Print('/reload')
    end
end

local name, realm = UnitName('player')
local showDebug = name == 'Zimtdev'
function DF:Debug(m, value)
    if showDebug then
        m:Print(value)
    end
end

function DF:ShowStartMessage()
    local version = ''

    if not GetAddOnMetadata then
        version = C_AddOns.GetAddOnMetadata('DragonflightUI', 'Version')
    else
        version = GetAddOnMetadata('DragonflightUI', 'Version')
    end

    self:Print(version .. " loaded! Type '/dragonflight'or '/df' to open the options menu.")
end

local CLASS_COLORS = {
    WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
    MAGE = { r = 0.41, g = 0.8, b = 0.94 },
    ROGUE = { r = 1.0, g = 0.96, b = 0.41 },
    DRUID = { r = 1.0, g = 0.49, b = 0.04 },
    HUNTER = { r = 0.67, g = 0.83, b = 0.45 },
    SHAMAN = { r = 0.0, g = 0.44, b = 0.87 },
    PRIEST = { r = 1.0, g = 1.0, b = 1.0 },
    WARLOCK = { r = 0.58, g = 0.51, b = 0.79 },
    PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
    DEATHKNIGHT = { r = 0.77, g = 0.12, b = 0.23 },
}

function DF:GetClassColor(class, alpha)
    local classUpper = class:upper() -- Convert class to uppercase
    local color = CLASS_COLORS[classUpper]

    if color then
        if alpha then
            return color.r, color.g, color.b, alpha
        else
            return color.r, color.g, color.b, 1
        end
    else
        -- Default to white color if class not found (should not happen if classes are correct)
        return 1, 1, 1, 1
    end
end
