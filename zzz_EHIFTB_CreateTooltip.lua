EggonsMU.config.enableEvent("OnBeforeFirstInventoryTooltipDisplay")

local function isBookRedundant(item, identifier)
    local skill = item:getSkillTrained()
    if skill then
        local maxLevel = item:getMaxLevelTrained()
        -- print("skill", skill)
        local currentLevel = getPlayer():getPerkLevel(Perks[skill])
        if currentLevel >= maxLevel then
            EHIFTB.getPlayerMemory().redundantBooks[identifier] = true
            return true
        end
    end
    return false
end

local function isMagazineRedundant(magazine, identifier)
    local taughtRecipes = magazine:getTeachedRecipes()
    if getPlayer():getKnownRecipes():containsAll(taughtRecipes) then
        EHIFTB.getPlayerMemory().redundantBooks[identifier] = true
        return true
    end
    return false
end

local function createTooltip(item)
    local foundBooks = EHIFTB.getPlayerMemory().rememberedBooks
    local fullType = item:getFullType()
    local identifier = EHIFTB.getItemIdentifier(item)
    local foundBook = foundBooks[identifier]
    local itemName
    local staticModel = item:getStaticModel()
    if staticModel == "Book" then
        itemName = "ce livre"
        if isBookRedundant(item, identifier) then
            return "Je connais tout ça!"
        end
    elseif staticModel == "Magazine" then
        itemName = "ce magazine"
        if not foundBook then
            if isMagazineRedundant(item, identifier) then
                return "Je connais tout ça!"
            end
        end
    elseif (item.getMap and item:getMap()) or (item.IsMap and item:IsMap()) then
        itemName = "cette carte"
    elseif item:isRecordedMedia() then
        local mediaDataType = item:getMediaData():getMediaType()
        if mediaDataType == 0 then
            itemName = "ce CD"
        elseif mediaDataType == 1 then
            itemName = "cette cassette"
        end
    else
        itemName = "cet objet"
    end
    if not foundBook then
        return EHIFTB.Options.notFoundPrefix ..
            "Je n'ai pas pris " .. itemName .. " pour le moment." .. EHIFTB.Options.notFoundSuffix
    end
    local currentlyInText = ""
    local currentlyOutText = ""
    local currentlyInCount = 0
    local currentlyOutCount = 0
    local output = EHIFTB.Options.foundPrefix .. "J'ai pris " .. itemName .. " , c'est certains." .. EHIFTB.Options.foundSuffix
    return output
end

function EHIFTB.prepareTooltipData(item, self)
    if EHIFTB.isValidEHIFTBItem(item, "showTooltip") then
        local newTooltip = createTooltip(item)
        item:setTooltip(newTooltip)
    end
end

Events.OnBeforeFirstInventoryTooltipDisplay.Add(EHIFTB.prepareTooltipData)

local function drawText(self)
    self:drawText(
        self.EHIFTB.message,
        16,
        self.EHIFTB.tooltipStartY,
        self.EHIFTB.red,
        self.EHIFTB.green,
        self.EHIFTB.blue,
        1,
        self.EHIFTB.font
    )
end
local function drawBorder(self)
    self:drawRectBorder(
        0,
        0,
        self.width,
        self.height,
        self.borderColor.a,
        self.EHIFTB.red,
        self.EHIFTB.green,
        self.EHIFTB.blue
    )
end

-- code from PePePePePeil
local function countLines(str)
    if not str then
        return 0
    end
    local num = 0
    for s in string.gmatch(str, "([^\n]+)") do
        num = num + 1
    end
    return num
end
-- END code from PePePePePeil
ISToolTipInv.EHIFTB = ISToolTipInv.EHIFTB or {}

local function calculateTooltipStartYNormal(self)
    return self.height - self.EHIFTB.lineHeight - 5
end
local function calculateTooltipStartY4Multiline(self)
    return self.height - (self.EHIFTB.lineHeight * countLines(self.EHIFTB.message)) - 5
end

if getActivatedMods():contains("P4VideoMeister") then
    -- enables longer algorithm for P4VideoMeister compatibility
    ISToolTipInv.calculateTooltipStartY = calculateTooltipStartY4Multiline
else -- enables minimal algorithm
    ISToolTipInv.calculateTooltipStartY = calculateTooltipStartYNormal
end

local function tooltipRender(self)
    self.EHIFTB = self.EHIFTB or {}
    if EHIFTB.isValidEHIFTBItem(self.item, "showTooltip") then
        -- print("Tooltip item valid!")
        self.EHIFTB.lastItem = self.item
        self.EHIFTB.font = ISToolTip.GetFont()
        self.EHIFTB.message = self.item:getTooltip()

        self.EHIFTB.lineHeight = getTextManager():getFontFromEnum(self.EHIFTB.font):getLineHeight()
        self.EHIFTB.numberOfTooltipLines = math.floor((self.height / self.EHIFTB.lineHeight) + 0.5)
        self.EHIFTB.tooltipStartY = self:calculateTooltipStartY()

        self.EHIFTB.blue = 0
        self:EHIFTB_Store_render()
        if EHIFTB.isItemMemorized(self.item) then
            -- print("Tooltip memorized")
            self.EHIFTB.green = 1
            self.EHIFTB.red = 0
            if EHIFTB.Options.colorTooltipText and EHIFTB.Options.colorTooltipText_positive then
                -- print("Drawing text")
                drawText(self)
            end
            if EHIFTB.Options.colorTooltipBorder and EHIFTB.Options.colorTooltipText_positive then
                -- print("Drawing border")
                drawBorder(self)
            end
        else
            -- print("Not memorized")
            self.EHIFTB.green = 0
            self.EHIFTB.red = 1
            if EHIFTB.Options.colorTooltipText then
                -- print("Drawing text")
                drawText(self)
            end
            if EHIFTB.Options.colorTooltipBorder then
                -- print("Drawing border")
                drawBorder(self)
            end
        end
    else
        -- print("Tooltip item INvalid!")
        self:EHIFTB_Store_render()
    end
end

function EHIFTB.initTooltipOverride()
    print("initTooltipOverride")
    ISToolTipInv.EHIFTB_Store_render = ISToolTipInv.render
    ISToolTipInv.render = tooltipRender
end

function EHIFTB.disableTooltipOverride()
    print("disableTooltipOverride")
    ISToolTipInv.render = ISToolTipInv.EHIFTB_Store_render
    ISToolTipInv.EHIFTB_Store_render = nil
end

if EHIFTB.Options.colorTooltipText or EHIFTB.Options.colorTooltipBorder then
    EHIFTB.initTooltipOverride()
end
