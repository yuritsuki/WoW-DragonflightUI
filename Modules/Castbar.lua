local strbyte, strlen, strsub, type = string.byte, string.len, string.sub, type

-- returns the number of bytes used by the UTF-8 character at byte i in s
-- also doubles as a UTF-8 character validator
local function utf8charbytes(s, i)
    -- argument defaults
    i = i or 1

    -- argument checking
    if type(s) ~= "string" then
        error("bad argument #1 to 'utf8charbytes' (string expected, got ".. type(s).. ")")
    end
    if type(i) ~= "number" then
        error("bad argument #2 to 'utf8charbytes' (number expected, got ".. type(i).. ")")
    end

    local c = strbyte(s, i)

    -- determine bytes needed for character, based on RFC 3629
    -- validate byte 1
    if c > 0 and c <= 127 then
        -- UTF8-1
        return 1

    elseif c >= 194 and c <= 223 then
        -- UTF8-2
        local c2 = strbyte(s, i + 1)

        if not c2 then
            error("UTF-8 string terminated early")
        end

        -- validate byte 2
        if c2 < 128 or c2 > 191 then
            error("Invalid UTF-8 character")
        end

        return 2

    elseif c >= 224 and c <= 239 then
        -- UTF8-3
        local c2 = strbyte(s, i + 1)
        local c3 = strbyte(s, i + 2)

        if not c2 or not c3 then
            error("UTF-8 string terminated early")
        end

        -- validate byte 2
        if c == 224 and (c2 < 160 or c2 > 191) then
            error("Invalid UTF-8 character")
        elseif c == 237 and (c2 < 128 or c2 > 159) then
            error("Invalid UTF-8 character")
        elseif c2 < 128 or c2 > 191 then
            error("Invalid UTF-8 character")
        end

        -- validate byte 3
        if c3 < 128 or c3 > 191 then
            error("Invalid UTF-8 character")
        end

        return 3

    elseif c >= 240 and c <= 244 then
        -- UTF8-4
        local c2 = strbyte(s, i + 1)
        local c3 = strbyte(s, i + 2)
        local c4 = strbyte(s, i + 3)

        if not c2 or not c3 or not c4 then
            error("UTF-8 string terminated early")
        end

        -- validate byte 2
        if c == 240 and (c2 < 144 or c2 > 191) then
            error("Invalid UTF-8 character")
        elseif c == 244 and (c2 < 128 or c2 > 143) then
            error("Invalid UTF-8 character")
        elseif c2 < 128 or c2 > 191 then
            error("Invalid UTF-8 character")
        end

        -- validate byte 3
        if c3 < 128 or c3 > 191 then
            error("Invalid UTF-8 character")
        end

        -- validate byte 4
        if c4 < 128 or c4 > 191 then
            error("Invalid UTF-8 character")
        end

        return 4

    else
        error("Invalid UTF-8 character")
    end
end

-- returns the number of characters in a UTF-8 string
local function utf8len(s)
    -- argument checking
    if type(s) ~= "string" then
        error("bad argument #1 to 'utf8len' (string expected, got ".. type(s).. ")")
    end

    local pos = 1
    local bytes = strlen(s)
    local len = 0

    while pos <= bytes do
        len = len + 1
        pos = pos + utf8charbytes(s, pos)
    end

    return len
end

-- install in the string library
if not string.utf8len then
    string.utf8len = utf8len
end

-- functions identically to string.sub except that i and j are UTF-8 characters
-- instead of bytes
local function utf8sub(s, i, j)
    -- argument defaults
    j = j or -1

    -- argument checking
    if type(s) ~= "string" then
        error("bad argument #1 to 'utf8sub' (string expected, got ".. type(s).. ")")
    end
    if type(i) ~= "number" then
        error("bad argument #2 to 'utf8sub' (number expected, got ".. type(i).. ")")
    end
    if type(j) ~= "number" then
        error("bad argument #3 to 'utf8sub' (number expected, got ".. type(j).. ")")
    end

    local pos = 1
    local bytes = strlen(s)
    local len = 0

    -- only set l if i or j is negative
    local l = (i >= 0 and j >= 0) or utf8len(s)
    local startChar = (i >= 0) and i or l + i + 1
    local endChar   = (j >= 0) and j or l + j + 1

    -- can't have start before end!
    if startChar > endChar then
        return ""
    end

    -- byte offsets to pass to string.sub
    local startByte, endByte = 1, bytes

    while pos <= bytes do
        len = len + 1

        if len == startChar then
            startByte = pos
        end

        pos = pos + utf8charbytes(s, pos)

        if len == endChar then
            endByte = pos - 1
            break
        end
    end

    return strsub(s, startByte, endByte)
end

-- install in the string library
if not string.utf8sub then
    string.utf8sub = utf8sub
end

-- replace UTF-8 characters based on a mapping table
local function utf8replace(s, mapping)
    -- argument checking
    if type(s) ~= "string" then
        error("bad argument #1 to 'utf8replace' (string expected, got ".. type(s).. ")")
    end
    if type(mapping) ~= "table" then
        error("bad argument #2 to 'utf8replace' (table expected, got ".. type(mapping).. ")")
    end

    local pos = 1
    local bytes = strlen(s)
    local charbytes
    local newstr = ""

    while pos <= bytes do
        charbytes = utf8charbytes(s, pos)
        local c = strsub(s, pos, pos + charbytes - 1)

        newstr = newstr .. (mapping[c] or c)

        pos = pos + charbytes
    end

    return newstr
end

-- identical to string.upper except it knows about unicode simple case conversions
local function utf8upper(s)
    return utf8replace(s, utf8_lc_uc)
end

-- install in the string library
if not string.utf8upper and utf8_lc_uc then
    string.utf8upper = utf8upper
end

-- identical to string.lower except it knows about unicode simple case conversions
local function utf8lower(s)
    return utf8replace(s, utf8_uc_lc)
end

-- install in the string library
if not string.utf8lower and utf8_uc_lc then
    string.utf8lower = utf8lower
end

-- identical to string.reverse except that it supports UTF-8
local function utf8reverse(s)
    -- argument checking
    if type(s) ~= "string" then
        error("bad argument #1 to 'utf8reverse' (string expected, got ".. type(s).. ")")
    end

    local bytes = strlen(s)
    local pos = bytes
    local charbytes
    local newstr = ""
    local c

    while pos > 0 do
        c = strbyte(s, pos)
        while c >= 128 and c <= 191 do
            pos = pos - 1
            c = strbyte(pos)
        end

        charbytes = utf8charbytes(s, pos)

        newstr = newstr .. strsub(s, pos, pos + charbytes - 1)

        pos = pos - 1
    end

    return newstr
end

-- install in the string library
if not string.utf8reverse then
    string.utf8reverse = utf8reverse
end

local function subWithDots(str, maxLen)
    if utf8len(str) <= maxLen then
        return str
    end
    return utf8sub(str, 1, maxLen) .. "..."
end

local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')
local mName = 'Castbar'
local Module = DF:NewModule(mName, 'AceConsole-3.0')

local db, getOptions

local defaults = {
    profile = {
        scale = 1,
        x = 0,
        y = 245,
        sizeX = 460,
        sizeY = 207,
        preci = 1,
        preciMax = 1
    }
}

local function getDefaultStr(key)
    return ' (Default: ' .. tostring(defaults.profile[key]) .. ')'
end

local function setDefaultValues()
    for k, v in pairs(defaults.profile) do
        Module.db.profile[k] = v
    end
    Module.ApplySettings()
end

-- db[info[#info] = VALUE
local function getOption(info)
    return db[info[#info]]
end

local function setOption(info, value)
    local key = info[1]
    Module.db.profile[key] = value
    Module.ApplySettings()
end

local options = {
    type = 'group',
    name = 'DragonflightUI - ' .. mName,
    get = getOption,
    set = setOption,
    args = {
        toggle = {
            type = 'toggle',
            name = 'Enable',
            get = function()
                return DF:GetModuleEnabled(mName)
            end,
            set = function(info, v)
                DF:SetModuleEnabled(mName, v)
            end,
            order = 1
        },
        reload = {
            type = 'execute',
            name = '/reload',
            desc = 'reloads UI',
            func = function()
                ReloadUI()
            end,
            order = 1.1
        },
        defaults = {
            type = 'execute',
            name = 'Defaults',
            desc = 'Sets Config to default values',
            func = setDefaultValues,
            order = 1.1
        },
        config = {
            type = 'header',
            name = 'Config - Player',
            order = 100
        },
        scale = {
            type = 'range',
            name = 'Scale',
            desc = '' .. getDefaultStr('scale'),
            min = 0.2,
            max = 1.5,
            bigStep = 0.025,
            order = 101,
            disabled = true
        },
        x = {
            type = 'range',
            name = 'X',
            desc = 'X relative to BOTTOM CENTER' .. getDefaultStr('x'),
            min = -2500,
            max = 2500,
            bigStep = 0.50,
            order = 102
        },
        y = {
            type = 'range',
            name = 'Y',
            desc = 'Y relative to BOTTOM CENTER' .. getDefaultStr('y'),
            min = -2500,
            max = 2500,
            bigStep = 0.50,
            order = 102
        },
        preci = {
            type = 'range',
            name = 'Precision (time left)',
            desc = '...' .. getDefaultStr('preci'),
            min = 0,
            max = 3,
            bigStep = 1,
            order = 103
        },
        preciMax = {
            type = 'range',
            name = 'Precision (time max)',
            desc = '...' .. getDefaultStr('preciMax'),
            min = 0,
            max = 3,
            bigStep = 1,
            order = 103
        }
    }
}

function Module:OnInitialize()
    DF:Debug(self, 'Module ' .. mName .. ' OnInitialize()')
    self.db = DF.db:RegisterNamespace(mName, defaults)
    db = self.db.profile

    self:SetEnabledState(DF:GetModuleEnabled(mName))
    DF:RegisterModuleOptions(mName, options)
end

function Module:OnEnable()
    DF:Debug(self, 'Module ' .. mName .. ' OnEnable()')
    Module.Wrath()
    Module:ApplySettings()
end

function Module:OnDisable()
end

function Module:ApplySettings()
    db = Module.db.profile
    Module.frame.Castbar:SetPoint('CENTER', UIParent, 'BOTTOM', db.x, db.y)
end

local frame = CreateFrame('FRAME', 'ImprovedUICastbarFrame', UIParent)
Module.frame = frame

function Module.ChangeDefaultCastbar()
    CastingBarFrame:ClearAllPoints()
    CastingBarFrame:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, -100)

    CastingBarFrame:GetStatusBarTexture():SetVertexColor(0, 0, 0, 0)
    CastingBarFrame:GetStatusBarTexture():SetAlpha(0)

    -- CastingBarFrame.Border:Hide()
    -- CastingBarFrame.BorderShield:Hide()
    -- CastingBarFrame.Text:Hide()
    -- CastingBarFrame.Icon:Hide()
    -- CastingBarFrame.Spark:Hide()
    -- CastingBarFrame.Flash:Hide()

    local children = {CastingBarFrame:GetRegions()}
    for i, child in pairs(children) do
        --print('child', child:GetName())
        child:Hide()
    end
end

function Module.CreateNewCastbar()
    local standardRef = 'Interface\\AddOns\\DragonflightUI\\Textures\\Castbar\\CastingBarStandard2'
    local borderRef = 'Interface\\AddOns\\DragonflightUI\\Textures\\Castbar\\CastingBarFrame2'
    local backgroundRef = 'Interface\\AddOns\\DragonflightUI\\Textures\\Castbar\\CastingBarBackground2'
    local sparkRef = 'Interface\\AddOns\\DragonflightUI\\Textures\\Castbar\\CastingBarSpark'

    local sizeX = 250
    local sizeY = 20
    local f = CreateFrame('Frame', 'ImprovedUICastBar', CastingBarFrame)
    f:SetSize(sizeX, sizeY)
    f:SetPoint('CENTER', UIParent, 'BOTTOM', 0, 230)

    local tex = f:CreateTexture('Background', 'ARTWORK')
    tex:SetAllPoints()
    tex:SetTexture(backgroundRef)
    f.Background = tex

    -- actual status bar, child of parent above
    f.Bar = CreateFrame('StatusBar', nil, f)
    f.Bar:SetStatusBarTexture(standardRef)
    f.Bar:SetPoint('TOPLEFT', 0, 0)
    f.Bar:SetPoint('BOTTOMRIGHT', 0, 0)

    f.Bar:SetMinMaxValues(0, 100)
    f.Bar:SetValue(50)

    frame.Castbar = f

    local UpdateCastBarValues = function(other)
        local value = other:GetValue()
        local statusMin, statusMax = other:GetMinMaxValues()

        frame.Castbar.Bar:SetValue(value)
        frame.Castbar.Bar:SetMinMaxValues(statusMin, statusMax)
    end

    local border = f.Bar:CreateTexture('Border', 'OVERLAY')
    border:SetTexture(borderRef)
    local dx, dy = 2, 4
    border:SetSize(sizeX + dx, sizeY + dy)
    border:SetPoint('CENTER', f.Bar, 'CENTER', 0, 0)
    f.Border = border

    local spark = f.Bar:CreateTexture('Spark', 'OVERLAY')
    spark:SetTexture(sparkRef)
    spark:SetSize(20, 32)
    spark:SetPoint('CENTER', f.Bar, 'CENTER', 0, 0)
    spark:SetBlendMode('ADD')
    f.Spark = spark

    local UpdateSpark = function(other)
        local value = other:GetValue()
        local statusMin, statusMax = other:GetMinMaxValues()
        if statusMax == 0 then
            return
        end

        local percent = value / statusMax
        if percent == 1 then
            f.Spark:Hide()
        else
            --f.Spark:SetPoint('CENTER', f.Bar, 'LEFT', sizeX / 2, 0 + 15)
            f.Spark:Show()
            local dx = 2
            f.Spark:SetPoint('CENTER', f.Bar, 'LEFT', (value * sizeX) / statusMax, 0)
        end
    end

    local bg = CreateFrame('Frame', 'ImprovedUICastbarNameBackgroundFrame', CastingBarFrame)
    bg:SetSize(sizeX, sizeY)
    bg:SetPoint('TOP', f, 'BOTTOM', 0, 0)

    local bgTex = bg:CreateTexture('ImprovedUICastbarNameBackground', 'ARTWORK')
    bgTex:ClearAllPoints()
    bgTex:SetTexture('Interface\\AddOns\\DragonflightUI\\Textures\\MinimapBorder')
    bgTex:SetSize(sizeX, 30)
    bgTex:SetPoint('TOP', f, 'BOTTOM', 2, 2)

    bg.tex = bgTex
    f.Background = bg

    local text = bg:CreateFontString('ImprovedUICastbarText', 'OVERLAY', 'GameFontHighlight')
    text:SetText('12')
    text:SetPoint('TOP', f, 'BOTTOM', 0, -1)
    text:SetText('SHADOW BOLT DEBUG')
    f.Text = text

    local textValueMax = bg:CreateFontString('ImprovedUICastbarText', 'OVERLAY', 'GameFontHighlight')
    textValueMax:SetPoint('TOP', f, 'BOTTOM', 0, -1)
    textValueMax:SetPoint('RIGHT', f.Background, 'RIGHT', -10, 0)
    textValueMax:SetText('/ 4.2')
    f.TextValueMax = textValueMax

    local textValue = bg:CreateFontString('ImprovedUICastbarText', 'OVERLAY', 'GameFontHighlight')
    textValue:SetPoint('RIGHT', f.TextValueMax, 'LEFT', 0, 0)
    textValue:SetText('0.69')
    f.TextValue = textValue

    local UpdateExtratext = function(other)
        local value = other:GetValue()
        local statusMin, statusMax = other:GetMinMaxValues()

        local preci = Module.db.profile.preci
        local preciMax = Module.db.profile.preciMax

        if value == statusMax then
            frame.Castbar.TextValue:SetText('')
            frame.Castbar.TextValueMax:SetText('')
        elseif frame.Castbar.bChanneling then
            f.TextValue:SetText(string.format('%.' .. preci .. 'f', value))
            f.TextValueMax:SetText(' / ' .. string.format('%.' .. preciMax .. 'f', statusMax))
        else
            f.TextValue:SetText(string.format('%.' .. preci .. 'f', statusMax - value))
            f.TextValueMax:SetText(' / ' .. string.format('%.' .. preciMax .. 'f', statusMax))
        end
    end

    local ticks = {}
    for i = 1, 15 do
        local tick = f.Bar:CreateTexture('Tick' .. i, 'OVERLAY')
        tick:SetTexture('Interface\\ChatFrame\\ChatFrameBackground')
        tick:SetVertexColor(0, 0, 0)
        tick:SetAlpha(0.75)
        tick:SetSize(2.5, sizeY - 2)
        tick:SetPoint('CENTER', f.Bar, 'LEFT', sizeX / 2, 0)
        ticks[i] = tick
    end
    f.Ticks = ticks

    CastingBarFrame:HookScript(
        'OnUpdate',
        function(self)
            UpdateCastBarValues(self)
            UpdateSpark(self)
            UpdateExtratext(self)
        end
    )
end

function Module.SetBarNormal()
    local standardRef = 'Interface\\AddOns\\DragonflightUI\\Textures\\Castbar\\CastingBarStandard2'
    frame.Castbar.Bar:SetStatusBarTexture(standardRef)

    frame.Castbar.bChanneling = false
    local name, _, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId =
        UnitCastingInfo('player')

    frame.Castbar.Text:SetText(subWithDots(text, 22))
    frame.Castbar.Text:ClearAllPoints()
    frame.Castbar.Text:SetPoint('TOP', frame.Castbar, 'BOTTOM', 0, -1)
    frame.Castbar.Text:SetPoint('LEFT', frame.Castbar.Background, 'LEFT', 10, 0)
end

Module.ChannelTicks = {
    --wl
    [GetSpellInfo(5740)] = 4, -- rain of fire
    [GetSpellInfo(5138)] = 5, -- drain mana
    [GetSpellInfo(689)] = 5, -- drain life
    [GetSpellInfo(1120)] = 5, -- drain soul
    [GetSpellInfo(755)] = 10, -- health funnel
    [GetSpellInfo(1949)] = 15, -- hellfire
    --priest
    [GetSpellInfo(47540)] = 2, -- penance
    [GetSpellInfo(15407)] = 3, -- mind flay
    [GetSpellInfo(64843)] = 4, -- divine hymn
    [GetSpellInfo(64901)] = 4, -- hymn of hope
    [GetSpellInfo(48045)] = 5, -- mind sear
    --hunter
    [GetSpellInfo(1510)] = 6, -- volley
    -- druid
    [GetSpellInfo(740)] = 4, -- tranquility
    [GetSpellInfo(16914)] = 10, -- hurricane
    -- mage
    [GetSpellInfo(5145)] = 5, -- arcane missiles
    [GetSpellInfo(10)] = 8 -- blizzard
}


function Module.HideAllTicks()
    if frame.Castbar.Ticks then
        for i = 1, 15 do
            frame.Castbar.Ticks[i]:Hide()
        end
    end
end

function Module.SetBarChannel()
    local channelRef = 'Interface\\AddOns\\DragonflightUI\\Textures\\Castbar\\CastingBarChannel'
    frame.Castbar.Bar:SetStatusBarTexture(channelRef)

    frame.Castbar.bChanneling = true
    local name, _, _, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible, spellId =
        UnitChannelInfo('player')
    frame.Castbar.Text:SetText(subWithDots(name, 22))
    frame.Castbar.Text:ClearAllPoints()
    frame.Castbar.Text:SetPoint('TOP', frame.Castbar, 'BOTTOM', 0, -1)
    frame.Castbar.Text:SetPoint('LEFT', frame.Castbar.Background, 'LEFT', 10, 0)

    local tickCount = Module.ChannelTicks[name]
    if tickCount then
        local tickDelta = frame.Castbar:GetWidth() / tickCount
        for i = 1, tickCount - 1 do
            frame.Castbar.Ticks[i]:Show()
            frame.Castbar.Ticks[i]:SetPoint('CENTER', frame.Castbar, 'LEFT', i * tickDelta, 0)
        end

        for i = tickCount, 15 do
            frame.Castbar.Ticks[i]:Hide()
        end
    else
        Module.HideAllTicks()
    end
end

function Module.SetBarInterrupted()
    local interruptedRef = 'Interface\\AddOns\\DragonflightUI\\Textures\\Castbar\\CastingBarInterrupted2'
    frame.Castbar.Bar:SetStatusBarTexture(interruptedRef)

    frame.Castbar.Text:SetText('Прервано')
    frame.Castbar.Text:ClearAllPoints()
    frame.Castbar.Text:SetPoint('TOP', frame.Castbar, 'BOTTOM', 0, -1)
end

function frame:OnEvent(event, arg1)
    --print('event', event, arg1)
    Module.ChangeDefaultCastbar()
    if event == 'PLAYER_ENTERING_WORLD' then
    elseif (event == 'UNIT_SPELLCAST_START' and arg1 == 'player') then
        Module.SetBarNormal()
        Module.HideAllTicks()
    elseif (event == 'UNIT_SPELLCAST_INTERRUPTED' and arg1 == 'player') then
        Module.SetBarInterrupted()
    elseif (event == 'UNIT_SPELLCAST_CHANNEL_START' and arg1 == 'player') then
        Module.SetBarChannel()
    else
    end
end
frame:SetScript('OnEvent', frame.OnEvent)

-- Wrath
function Module.Wrath()
    frame:RegisterEvent('UNIT_SPELLCAST_INTERRUPTED')
    frame:RegisterEvent('UNIT_SPELLCAST_DELAYED')
    frame:RegisterEvent('UNIT_SPELLCAST_CHANNEL_START')
    frame:RegisterEvent('UNIT_SPELLCAST_CHANNEL_UPDATE')
    frame:RegisterEvent('UNIT_SPELLCAST_CHANNEL_STOP')
    frame:RegisterEvent('UNIT_SPELLCAST_START')
    frame:RegisterEvent('UNIT_SPELLCAST_STOP')
    frame:RegisterEvent('UNIT_SPELLCAST_FAILED')

    Module.ChangeDefaultCastbar()
    Module.CreateNewCastbar()
end
