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

        toggleHUD =
        {
            type = "toggle",
            name = "Show HUD",
            desc = "Whether to show a HUD with the equipped state of your Town Clothes and a button to toggle them.",
            set = function(info, val)
                TCAD.db.char.showHud = val
                TCAD:SyncState()
            end,
            get = function() return TCAD.db.char.showHud end,
            order = 2.2
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
                TCAD.UI:UpdateEquipmentSetButtons()
                if val then
                    TCAD:AutoSwitchTownClothes()
                end
            end,
            get = function() return TCAD.db.global.autoSwitch end,
            order = 3.1
        },

        toggleHUDSwitchButton =
        {
            type = "toggle",
            name = "HUD Switch Button",
            desc = "Whether to show a button on the HUD for toggling your Town Clothes.",
            set = function(info, val)
                TCAD.db.global.showHudSwitchButton = val
                TCAD:UpdateHud()
            end,
            get = function() return TCAD.db.global.showHudSwitchButton end,
            order = 3.2
        },

        rangeHUDAlpha =
        {
            type = "range",
            name = "HUD Transparency",
            desc = "Transparency of the HUD. 0% = fully opaque, 100% = fully transparent.",
            min = 0,
            max = 1,
            step = 0.01,
            isPercent = true,
            get = function()
                return 1 - TCAD.db.global.hudAlpha
            end,
            set = function(info, val)
                TCAD.db.global.hudAlpha = 1 - val
                TCAD:UpdateHud()
            end,
            order = 3.3
        },

        buttonResetHud =
        {
            type = "execute",
            name = "Reset HUD Position",
            desc = "Reset HUD position back to default. Useful it you lose it somewhere!",
            func = function()
                for k,v in pairs(TCAD.dataDefaults.global.hudPositionData) do
                    TCAD.db.global.hudPositionData[k] = v
                end
                TCAD:UpdateHud()
            end,
            order = 3.4
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

    PaperDollFrame.EquipmentManagerPane:HookScript("OnShow", self.UpdateEquipmentSetButtons, self)
end

function TCAD.UI:UpdateEquipmentSetButtons()
    if not TCAD.activeEquipmentSetID or not PaperDollFrame.EquipmentManagerPane:IsShown() then
        return
    end
    -- Add auto-switch toggle to equipment set button.
    for _, equipmentSetBtn in ipairs(PaperDollFrame.EquipmentManagerPane.ScrollBox:GetFrames()) do
        if equipmentSetBtn.townClothesAutoSwitchToggle then
            TCAD:DebugLog(format("[UI] Btn %d - showing auto-switch button: %s", equipmentSetBtn.setID, tostring(equipmentSetBtn.setID == TCAD.activeEquipmentSetID)))
            equipmentSetBtn.townClothesAutoSwitchToggle:SetShown(equipmentSetBtn.setID == TCAD.activeEquipmentSetID)
            equipmentSetBtn.townClothesAutoSwitchToggle:SetChecked(TCAD.db.global.autoSwitch)
        else
            if equipmentSetBtn.setID == TCAD.activeEquipmentSetID then
                TCAD:DebugLog("[UI] Creating auto-switch button.")
                local autoSwitchToggle = CreateFrame("CheckButton", "Auto Switch Town Clothes", equipmentSetBtn, "ChatConfigCheckButtonTemplate")
                autoSwitchToggle:SetHitRectInsets(0, -70, 0, 0)
                autoSwitchToggle:SetWidth(16)
                autoSwitchToggle:SetHeight(16)
                autoSwitchToggle:SetPoint("BOTTOMLEFT", 40, -2)
                autoSwitchToggle:SetChecked(TCAD.db.global.autoSwitch)
                autoSwitchToggle.Text:SetText("Auto Switch")
                autoSwitchToggle.Text:SetFont(select(1, autoSwitchToggle.Text:GetFont()), 10, nil)
                autoSwitchToggle.tooltip = "Whether Town Clothes should automatically be switched. When disabled, the HUD button can be used to switch sets."
                autoSwitchToggle:HookScript("OnClick", function()
                    TCAD.db.global.autoSwitch = not TCAD.db.global.autoSwitch
                    if TCAD.db.global.autoSwitch then
                        TCAD:AutoSwitchTownClothes()
                    end
                    autoSwitchToggle:SetChecked(TCAD.db.global.autoSwitch)
                end)
                equipmentSetBtn.townClothesAutoSwitchToggle = autoSwitchToggle
                equipmentSetBtn.townClothesAutoSwitchToggle:Show()
            end
        end
    end
end