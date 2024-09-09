--
-- Part of TownClothes AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local _, ns = ...

local TCAD = LibStub("AceAddon-3.0"):NewAddon("TownClothes", "AceConsole-3.0", "AceEvent-3.0")
ns.TCAD = TCAD
TCAD.TOWN_EQUIPMENT_SET_NAME_ACTIVE = "Town Clothes"
TCAD.TOWN_EQUIPMENT_SET_NAME_INACTIVE = "Auto TCInactive"

TCAD.townClothesActive = false
TCAD.townClothesInactiveTitleID = false

TCAD.dataDefaults =
{
    char =
    {
        addonEnabled = true,
        changeTitle = false,
        townTitleID = -1
    },
    global =
    {
        autoSwitch = true,
        hudData =
        {
            point = "TOP",
            relativePoint = "TOP",
            offsetX = 0,
            offsetY = -30,
        },
        debugMode = false
    },
}

function TCAD:DebugLog(msg)
    if not self.db.global.debugMode then
        return
    end
    self:InfoLog("[DEBUG] "..msg)
end

function TCAD:InfoLog(msg)
    print("|cFF2873ED[Town Clothes]|r "..msg)
end

function TCAD:OnInitialize()
    self:RegisterChatCommand("tc", "TownClothesCommand")
    self:RegisterChatCommand("townclothes", "TownClothesCommand")

    self.db = LibStub("AceDB-3.0"):New("TownClothesDB", self.dataDefaults, true)
    self:DebugLog("Initialising...")
    self.UI:Init()

    if not C_EquipmentSet.GetEquipmentSetID(self.TOWN_EQUIPMENT_SET_NAME_ACTIVE) then
        self:DebugLog("Creating active set.")
        C_EquipmentSet.CreateEquipmentSet(self.TOWN_EQUIPMENT_SET_NAME_ACTIVE, "achievement_guildperk_hastyhearth")
    end
    self.active_equipment_set_id = C_EquipmentSet.GetEquipmentSetID(self.TOWN_EQUIPMENT_SET_NAME_ACTIVE)
    if not C_EquipmentSet.GetEquipmentSetID(self.TOWN_EQUIPMENT_SET_NAME_INACTIVE) then
        self:DebugLog("Creating inactive set.")
        C_EquipmentSet.CreateEquipmentSet(self.TOWN_EQUIPMENT_SET_NAME_INACTIVE, "achievement_explore_argus")
    end
    self.inactive_equipment_set_id = C_EquipmentSet.GetEquipmentSetID(self.TOWN_EQUIPMENT_SET_NAME_INACTIVE)

    self:RegisterEvent("PLAYER_UPDATE_RESTING", self.AutoSwitchTownClothes, self)
    self:RegisterEvent("PLAYER_REGEN_ENABLED", self.AutoSwitchTownClothes, self)
    -- These events should just update state, rather than swapping sets.
    self:RegisterEvent("EQUIPMENT_SWAP_FINISHED", self.SyncState, self)
    self:RegisterEvent("EQUIPMENT_SETS_CHANGED", self.SyncState, self)
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", self.SyncState, self)

    self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        self:AutoSwitchTownClothes()
    end)
end

function TCAD:TownClothesCommand()
    Settings.OpenToCategory(self.UI.optionsFrameRoot.name)
end

---
--- Syncs cached AddOn state with the current state of the player's equipment.
---
function TCAD:SyncState()
    if not self.db.char.addonEnabled then
        return
    end
    self:SetHudShown(IsResting())
    _,_,_,isEquipped = C_EquipmentSet.GetEquipmentSetInfo(self.active_equipment_set_id)
    if isEquipped then
        self:DebugLog("[SyncState] Town clothes equipped.")
        self.townClothesActive = true
    else
        self:DebugLog("[SyncState] Town clothes not equipped.")
        self.townClothesActive = false
    end
    self:UpdateHud()
end

---
--- Auto switches town clothes if auto-switch is enabled.
--- Will sync state first, so this can be called even if auto-switch is disabled.
---
function TCAD:AutoSwitchTownClothes()
    if not self.db.char.addonEnabled then
        return
    end
    self:SyncState(event)
    if not self.db.global.autoSwitch then
        return
    end
    if self.townClothesActive and not IsResting() then
        self:DebugLog("[AutoSwitchTownClothes] Not in a rested zone, removing town clothes.")
        self:SetTownClothesActive(false)
    elseif not self.townClothesActive and IsResting() then
        self:DebugLog("[AutoSwitchTownClothes] Town clothes not equipped but in a rested zone, equipping.")
        self:SetTownClothesActive(true)
    end
end

---
--- Sets Town Clothes set active or inactive, if current context allows.
--- Does not sync state, so ensure state is valid before calling!
---
function TCAD:SetTownClothesActive(newActiveState)
    if not self.db.char.addonEnabled then
        return
    end
    if InCombatLockdown() then
        self:DebugLog("[SetTownClothesActive] Skipping change due to combat.")
        return
    end
    if newActiveState then
        self:DebugLog("[SetTownClothesActive] Equipping Town Clothes")
        C_EquipmentSet.SaveEquipmentSet(self.inactive_equipment_set_id)
        C_EquipmentSet.UseEquipmentSet(self.active_equipment_set_id)
    else
        self:DebugLog("[SetTownClothesActive] Removing Town Clothes")
        C_EquipmentSet.UseEquipmentSet(self.inactive_equipment_set_id)
    end
    self:SetTownClothesTitleActive(newActiveState)
end

function TCAD:SetTownClothesTitleActive(newActiveState)
    -- Setting title requires a hardware event so it won't work with auto-switch :(
    return
    --if not self.db.char.addonEnabled or not self.db.char.changeTitle then
    --    return
    --end
    --if newActiveState then
    --    self:DebugLog("Enabling town title: "..GetTitleName(self.db.char.townTitleID))
    --    self.townClothesInactiveTitleID = GetCurrentTitle()
    --    SetCurrentTitle(self.db.char.townTitleID)
    --else
    --    self:DebugLog("Reverting town title to "..GetTitleName(self.townClothesInactiveTitleID))
    --    SetCurrentTitle(self.townClothesInactiveTitleID)
    --end
end

---
--- Updates state of the HUD without toggling its visibility.
---
function TCAD:UpdateHud()
    if not self.hud then
        return
    end
    self.hud.title:SetText(self.townClothesActive and "Town Clothes Equipped" or "Town Clothes Unequipped")
    --self:DebugLog(string.format("Point: %s, relativePoint: %s, x: %d, y: %d",
    --        self.db.global.hudData.point,
    --        self.db.global.hudData.relativePoint,
    --        self.db.global.hudData.offset,
    --        self.db.global.hudData.offsetY)
    --)
    self.hud:ClearAllPoints()
    self.hud:SetPoint(self.db.global.hudData.point, nil, self.db.global.hudData.relativePoint, self.db.global.hudData.offsetX, self.db.global.hudData.offsetY)
end

---
--- Sets the HUD shown or hidden, initialising it if required.
---
function TCAD:SetHudShown(shown)
    if not self.hud then
        self.hud = CreateFrame("Frame", nil, UIParent)
        self.hud:SetPoint(self.db.global.hudData.point, nil, self.db.global.hudData.relativePoint, self.db.global.hudData.offsetX, self.db.global.hudData.offsetY)
        self.hud:SetMovable(true)
        self.hud:SetResizable(false)
        self.hud:SetClampedToScreen(true)
        -- BackdropTemplateMixin and "BackdropTemplate"
        --self.hud:SetBackdrop(
        --{
        --    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        --    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        --    tile = true, tileSize = 16, edgeSize = 16,
        --    insets = { left = 4, right = 4, top = 4, bottom = 4 }
        --})
        -- Draggable
        self.hud:EnableMouse(true)
        self.hud:RegisterForDrag("LeftButton")
        self.hud:SetScript("OnDragStart", self.hud.StartMoving)
        self.hud:SetScript("OnDragStop", function()
            self.hud:StopMovingOrSizing()

            local newPoint, _, relativePoint, newOffsetX, newOffsetY = self.hud:GetPoint()
            self.db.global.hudData.point = newPoint
            self.db.global.hudData.relativePoint = relativePoint
            self.db.global.hudData.offsetX = newOffsetX
            self.db.global.hudData.offsetY = newOffsetY
        end)

        self.hud.toggleTownClothesBtn = CreateFrame("Button", nil, self.hud);
        local buttonTex = self.hud.toggleTownClothesBtn:CreateTexture()
        buttonTex:SetTexture("interface\\icons\\achievement_bg_returnxflags_def_wsg")
        buttonTex:SetWidth(30)
        buttonTex:SetHeight(30)
        buttonTex:SetAllPoints()
        self.hud.toggleTownClothesBtn:SetNormalTexture(buttonTex)
        self.hud.toggleTownClothesBtn:SetSize(30, 30)
        self.hud.toggleTownClothesBtn:SetPoint("LEFT", self.hud, "LEFT", 0, 0)
        self.hud.toggleTownClothesBtn:RegisterForClicks("AnyUp")

        self.hud.toggleTownClothesBtn:SetScript("OnClick", function(btn)
            local cachedState = self.townClothesActive
            self:SyncState()
            if self.townClothesActive ~= cachedState then
                self:InfoLog("Equipment has changed from what Town Clothes expected, updating UI. Press the switch button again if still desired.")
                return
            end
            self:SetTownClothesActive(not self.townClothesActive)
        end)
        self.hud.toggleTownClothesBtn:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_CURSOR")
            GameTooltip:SetText("Toggle town clothes")
            GameTooltip:Show()
        end)
        self.hud.toggleTownClothesBtn:SetScript("OnLeave", function(btn)
            GameTooltip:Hide()
        end)

        -- Title
        local titlePadding = 5
        self.hud.title = self.hud:CreateFontString()
        self.hud.title:SetFontObject(GameFontNormal)
        self.hud.title:SetTextColor(1, 1, 1, 1)
        self.hud.title:SetPoint("LEFT", self.hud.toggleTownClothesBtn, "RIGHT", titlePadding, 0)
        self.hud.title:SetText(self.townClothesActive and "Town Clothes Equipped" or "Town Clothes Unequipped")

        -- Resize to fit text and button
        self.hud:SetSize(self.hud.title:GetStringWidth() + self.hud.toggleTownClothesBtn:GetWidth() + titlePadding, 30)
    end

    self.hud:SetShown(shown)
end