--
-- Part of TownClothes AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local _, ns = ...
local TCAD = ns.TCAD
TCAD.UI = {}

TCAD.UI.options =
{
    name = "Town Clothes",
    handler = TCAD,
    type = "group",
    args =
    {
        logo =
        {
            type = "description",
            name = "",
            image ="Interface\\AddOns\\TownClothes\\assets\\townclothes-header.tga",
            imageWidth=128,
            imageHeight=64,
            order = 0
        },

        desc =
        {
            type = "description",
            fontSize = "medium",
            name = "A simple AddOn for changing equipment sets while in a rested zone, allowing for your transmog to change\
depending on whether you're in town, or out on adventure!\
Want to look like a crafter, trader or comfy citizen while in town without the hassle of managing switches? Now you can!\
\
To setup, simply equip a different set of gear, such as cheap low level gear, and save it to the 'Town Clothes' equipment set.\
You can then transmog that gear separately to your combat gear. For any slots you don't want to change, use the ignore slot feature when saving the equipment set.\
\
Happy transmogging!\n\n",
            order = 1
        },

        characterSettingsHeader =
        {
            type = "header",
            name = "Character Settings",
            order = 2
        },

        toggleAddon =
        {
            type = "toggle",
            name = "Town Clothes Enabled",
            desc = "Whether the Town Clothes AddOn should run for this character.",
            set = function(info, val)
                TCAD.db.char.addonEnabled = val
                if val then
                    TCAD:AutoSwitchTownClothes()
                else
                    TCAD:SyncState()
                    if TCAD.townClothesActive then
                        TCAD:SetTownClothesActive(false)
                    end
                    TCAD:SetHudShown(false)
                end
            end,
            get = function() return TCAD.db.char.addonEnabled end,
            order = 2.1
        },

        -- Changing title requires a hardware event :(
        --toggleChangeTitle =
        --{
        --    type = "toggle",
        --    name = "Change Title",
        --    desc = "Whether to also change title when equipping Town Clothes.",
        --    set = function(info, val)
        --        TCAD.db.char.changeTitle = val
        --        if val then
        --            TCAD:AutoSwitchTownClothes()
        --        else
        --            TCAD:SyncState()
        --            if TCAD.townClothesActive then
        --                TCAD:SetTownClothesActive(false)
        --            end
        --            TCAD:SetHudShown(false)
        --        end
        --    end,
        --    get = function() return TCAD.db.char.changeTitle end,
        --    order = 2.2
        --},
        --
        --selectTitle =
        --{
        --    type = "select",
        --    name = "Select Town Title",
        --    hidden = function() return not TCAD.db.char.changeTitle end,
        --    order = 2.3,
        --    values = function()
        --        local availableTitles = {}
        --        availableTitles["-1"] = "No title"
        --        for titleID = 1, GetNumTitles() do
        --            if IsTitleKnown(titleID) then
        --                availableTitles[titleID] = GetTitleName(titleID)
        --            end
        --        end
        --        return availableTitles
        --    end,
        --    get = function()
        --        return TCAD.db.char.townTitleID
        --        --if TCAD.db.char.townTitleID > 0 then
        --        --    return GetTitleName(TCAD.db.char.townTitleID)
        --        --end
        --        --return "No title"
        --    end,
        --    set = function(options, key)
        --        TCAD.db.char.townTitleID = tonumber(key)
        --        if TCAD.db.char.addonEnabled and TCAD.db.char.changeTitle and TCAD.townClothesActive then
        --            SetCurrentTitle(self.db.char.townTitleID)
        --        end
        --    end
        --},

        globalSettingsHeader =
        {
            type = "header",
            name = "Global Settings",
            order = 3
        },

        toggleAutoSwitch =
        {
            type = "toggle",
            name = "Auto Switch",
            desc = "Whether Town Clothes should automatically be switched. When disabled, the HUD button can be used to switch sets.",
            set = function(info, val)
                TCAD.db.global.autoSwitch = val
                if val then
                    TCAD:AutoSwitchTownClothes()
                end
            end,
            get = function() return TCAD.db.global.autoSwitch end,
            order = 3.1
        },

        buttonResetHud =
        {
            type = "execute",
            name = "Reset HUD",
            desc = "Reset HUD position back to default. Useful it you lose it somewhere!",
            func = function()
                for k,v in pairs(TCAD.dataDefaults.global.hudData) do
                    TCAD.db.global.hudData[k] = v
                end
                TCAD:UpdateHud()
            end,
            order = 3.2
        },

        toggleDebugMode =
        {
            type = "toggle",
            name = "Debug Mode",
            desc = "Enable verbose debug output.",
            set = function(info, val)
                TCAD.db.global.debugMode = val
            end,
            get = function() return TCAD.db.global.debugMode end,
            order = 999
        },
    },
}

function TCAD.UI:Init()
    LibStub("AceConfig-3.0"):RegisterOptionsTable("TCAD", self.options)
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")
    self.optionsFrameRoot = AceConfigDialog:AddToBlizOptions("TCAD", "Town Clothes", nil)
    -- Profiles options
    --self.options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(TCAD.db)
    --AceConfigDialog:AddToBlizOptions("TCAD", "Profiles", "Town Clothes", "profiles")
end