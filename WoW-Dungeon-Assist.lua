local addon = CreateFrame("Frame")
local unpack = unpack or table.unpack

local DB_NAME = "WoWDungeonAssistDB"

local SHOW_MODE_GROUP = "group"
local SHOW_MODE_ALWAYS = "always"
local SHOW_MODE_HIDDEN = "hidden"

local VISIBILITY_DRIVER_BY_MODE = {
	[SHOW_MODE_GROUP] = "[group] show; hide",
	[SHOW_MODE_ALWAYS] = "show",
	[SHOW_MODE_HIDDEN] = "hide",
}

local SHOW_MODE_LABELS = {
	[SHOW_MODE_GROUP] = "Group Only",
	[SHOW_MODE_ALWAYS] = "Always Show",
	[SHOW_MODE_HIDDEN] = "Hidden",
}

local ACCENT_SOURCE_LABELS = {
	class = "Class Color",
	custom = "Custom Color",
}

local DROPDOWN_DIRECTION_LABELS = {
	down = "Down",
	up = "Up",
}

local THEME_LABELS = {
	qui = "QUI Dark",
	slate = "Slate Steel",
	ember = "Ember",
}

local BUILTIN_FONT_ENTRIES = {
	{ id = "frizqt", label = "Friz Quadrata", path = "Fonts\\FRIZQT__.TTF" },
	{ id = "arialn", label = "Arial Narrow", path = "Fonts\\ARIALN.TTF" },
	{ id = "arialnb", label = "Arial Narrow Bold", path = "Fonts\\ARIALNB.TTF" },
	{ id = "arialni", label = "Arial Narrow Italic", path = "Fonts\\ARIALNI.TTF" },
	{ id = "arialnbi", label = "Arial Narrow Bold Italic", path = "Fonts\\ARIALNBI.TTF" },
	{ id = "morpheus", label = "Morpheus", path = "Fonts\\MORPHEUS.ttf" },
	{ id = "skurri", label = "Skurri", path = "Fonts\\skurri.ttf" },
	{ id = "blei", label = "Blei", path = "Fonts\\blei00d.TTF" },
	{ id = "quest", label = "Quest", path = "Fonts\\2002.TTF" },
}

local MARKER_CONDITION_NAME = {
	[8] = "skull",
	[7] = "cross",
	[6] = "square",
	[5] = "moon",
	[4] = "triangle",
	[3] = "diamond",
	[2] = "circle",
	[1] = "star",
}

local MARKER_ORDER = { 8, 7, 6, 5, 4, 3, 2, 1 }
local COUNTDOWN_PRESETS = { 5, 8, 10, 12, 15 }
local LUST_LOCKOUT_SPELL_IDS = { 57723, 57724, 80354, 264689, 390435 }
local BATTLE_RES_SPELL_IDS = { 20484, 61999, 20707, 391054 }

local defaults = {
	point = "TOP",
	relativePoint = "TOP",
	x = 0,
	y = -220,
	expanded = false,
	showMode = SHOW_MODE_GROUP,
	scale = 1,
	alpha = 1,
	locked = false,
	themePreset = "qui",
	countdownSeconds = 10,
	announceMarkers = false,
	tankShortcut = true,
	showMythicWidgets = true,
	accentColorMode = "class",
	customAccentColor = { r = 1, g = 0.82, b = 0 },
	dropdownDirection = "down",
	fontPreset = "frizqt",
}

local themePresets = {
	qui = {
		panelBg = { 0.03, 0.035, 0.045, 0.96 },
		panelBorder = { 0.19, 0.22, 0.26, 1 },
		headerBg = { 0.055, 0.06, 0.075, 0.94 },
		headerHover = { 0.085, 0.095, 0.12, 0.98 },
		buttonBg = { 0.025, 0.03, 0.04, 0.95 },
		buttonHover = { 0.07, 0.08, 0.105, 0.95 },
		buttonBorder = { 0.19, 0.22, 0.26, 1 },
		mutedText = { 0.72, 0.74, 0.78, 1 },
		moverBg = { 0.12, 0.35, 0.6, 0.45 },
		moverBorder = { 0.25, 0.65, 1, 1 },
	},
	slate = {
		panelBg = { 0.04, 0.04, 0.045, 0.97 },
		panelBorder = { 0.3, 0.31, 0.33, 1 },
		headerBg = { 0.06, 0.06, 0.07, 0.95 },
		headerHover = { 0.1, 0.1, 0.12, 0.98 },
		buttonBg = { 0.035, 0.035, 0.04, 0.95 },
		buttonHover = { 0.08, 0.08, 0.1, 0.95 },
		buttonBorder = { 0.3, 0.31, 0.33, 1 },
		mutedText = { 0.72, 0.72, 0.74, 1 },
		moverBg = { 0.2, 0.24, 0.29, 0.5 },
		moverBorder = { 0.45, 0.52, 0.6, 1 },
	},
	ember = {
		panelBg = { 0.045, 0.03, 0.028, 0.96 },
		panelBorder = { 0.34, 0.21, 0.16, 1 },
		headerBg = { 0.065, 0.04, 0.036, 0.94 },
		headerHover = { 0.11, 0.06, 0.048, 0.98 },
		buttonBg = { 0.05, 0.03, 0.03, 0.94 },
		buttonHover = { 0.11, 0.06, 0.06, 0.96 },
		buttonBorder = { 0.34, 0.21, 0.16, 1 },
		mutedText = { 0.78, 0.7, 0.66, 1 },
		moverBg = { 0.4, 0.2, 0.14, 0.5 },
		moverBorder = { 0.72, 0.38, 0.23, 1 },
	},
}

local normalLayout = {
	anchorWidth = 178,
	dropdownWidth = 178,
	dropdownHeight = 148,
	clearWidth = 158,
	clearHeight = 22,
	clearTopOffset = -10,
	markersLabelY = -44,
	markerHolderY = -58,
	markerSize = 24,
	markerXSpacing = 30,
	markerYSpacing = 28,
	iconInset = 3,
	actionWidth = 66,
	actionHeight = 26,
	buttonsBottom = 10,
	readyLeft = 14,
	countdownRight = -14,
	readyIconSize = 18,
	countdownIconSize = 16,
}

local backdropTemplate = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

local db
local anchor
local headerButton
local dropdown
local arrowLabel
local moverOverlay
local clearButton
local readyButton
local countdownButton
local countdownText
local countdownIcon
local readyIcon
local markersLabel
local markerHolder
local dropdownShade
local dropdownAccent
local headerAccent
local titleText
local brStatusText
local lustStatusText
local optionsPanel
local accentPickerButton
local optionsRefreshers = {}
local optionsAccentLabels = {}
local trackedFontStrings = {}

local markerButtons = {}
local themedButtons = {}
local fontOptions = {}
local fontOptionByID = {}

local isEditMode = false
local pendingVisibilityUpdate = false
local pendingSecureUpdate = false
local currentRole = "NONE"
local playerClassColor = { r = 1, g = 0.82, b = 0 }
local classColor = { r = 1, g = 0.82, b = 0 }
local palette = themePresets.qui

_G.BINDING_HEADER_WOWDUNGEONASSIST = "WoW Dungeon Assist"
_G.BINDING_NAME_WOWDUNGEONASSIST_TOGGLE_PANEL = "Toggle Panel"
_G["BINDING_NAME_CLICK WoWDungeonAssistReadyCheckButton:LeftButton"] = "Ready Check"
_G["BINDING_NAME_CLICK WoWDungeonAssistCountdownButton:LeftButton"] = "Pull Countdown"
_G["BINDING_NAME_CLICK WoWDungeonAssistClearMarkersButton:LeftButton"] = "Clear Markers"

function WoWDungeonAssist_TogglePanel()
	if not db or not dropdown then
		return
	end

	if InCombatLockdown() then
		return
	end

	dropdown:SetShown(not dropdown:IsShown())
	db.expanded = dropdown:IsShown()
	if arrowLabel then
		local isDownDirection = db.dropdownDirection ~= "up"
		if dropdown:IsShown() then
			arrowLabel:SetText(isDownDirection and "^" or "v")
		else
			arrowLabel:SetText(isDownDirection and "v" or "^")
		end
	end
end

local function Clamp(value, minValue, maxValue)
	if value < minValue then
		return minValue
	end
	if value > maxValue then
		return maxValue
	end
	return value
end

local function Round(value)
	if value >= 0 then
		return math.floor(value + 0.5)
	end
	return math.ceil(value - 0.5)
end

local function DeepCopyTable(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, nestedValue in pairs(value) do
		copy[key] = DeepCopyTable(nestedValue)
	end
	return copy
end

local function CopyTheme(theme)
	local copy = {}
	for key, value in pairs(theme) do
		copy[key] = { value[1], value[2], value[3], value[4] }
	end
	return copy
end

local function AddFontOption(id, label, path)
	if not id or id == "" or not path or path == "" then
		return
	end
	if fontOptionByID[id] then
		return
	end

	local entry = {
		id = id,
		label = label or id,
		path = path,
	}
	fontOptionByID[id] = entry
	table.insert(fontOptions, entry)
end

local function BuildFontOptions()
	fontOptions = {}
	fontOptionByID = {}

	for _, entry in ipairs(BUILTIN_FONT_ENTRIES) do
		AddFontOption(entry.id, entry.label, entry.path)
	end

	if STANDARD_TEXT_FONT then
		AddFontOption("std", "Standard UI", STANDARD_TEXT_FONT)
	end
	if UNIT_NAME_FONT then
		AddFontOption("unit", "Unit Name", UNIT_NAME_FONT)
	end
	if DAMAGE_TEXT_FONT then
		AddFontOption("damage", "Damage Text", DAMAGE_TEXT_FONT)
	end
	if NAMEPLATE_FONT then
		AddFontOption("nameplate", "Nameplate", NAMEPLATE_FONT)
	end

	if LibStub then
		local lsm = LibStub("LibSharedMedia-3.0", true)
		if lsm and lsm.List and lsm.Fetch then
			local names = lsm:List("font")
			if names then
				for _, name in ipairs(names) do
					local path = lsm:Fetch("font", name, true)
					if path then
						AddFontOption("lsm:" .. name, name, path)
					end
				end
			end
		end
	end

	table.sort(fontOptions, function(a, b)
		return a.label:lower() < b.label:lower()
	end)
end

local function GetSelectedFontPath()
	if db and db.fontPreset and fontOptionByID[db.fontPreset] then
		return fontOptionByID[db.fontPreset].path
	end
	if fontOptionByID[defaults.fontPreset] then
		return fontOptionByID[defaults.fontPreset].path
	end
	if STANDARD_TEXT_FONT then
		return STANDARD_TEXT_FONT
	end
	return "Fonts\\FRIZQT__.TTF"
end

local function TrackFontString(fontString, size, flags)
	if not fontString then
		return
	end

	table.insert(trackedFontStrings, {
		fontString = fontString,
		size = size or 12,
		flags = flags,
	})
end

local function ApplyTrackedFonts()
	local fontPath = GetSelectedFontPath()

	for _, entry in ipairs(trackedFontStrings) do
		local fontString = entry.fontString
		if fontString and fontString.SetFont then
			fontString:SetFont(fontPath, entry.size, entry.flags)
		end
	end
end

local function SetBackdropStyle(frame, edgeSize)
	frame:SetBackdrop({
		bgFile = backdropTemplate.bgFile,
		edgeFile = backdropTemplate.edgeFile,
		edgeSize = edgeSize or 8,
		insets = backdropTemplate.insets,
	})
end

local function SetClassAccentBorder(frame, alpha, brightness)
	local boost = brightness or 0.85
	local r = math.min(classColor.r * boost + 0.1, 1)
	local g = math.min(classColor.g * boost + 0.1, 1)
	local b = math.min(classColor.b * boost + 0.1, 1)
	frame:SetBackdropBorderColor(r, g, b, alpha or 1)
end

local function PrintMessage(text)
	print("|cff33aaffWoW Dungeon Assist:|r " .. text)
end

local function GetAssignedRole()
	local role = UnitGroupRolesAssigned("player")
	if not role or role == "" or role == "NONE" then
		if GetSpecialization and GetSpecializationRole then
			local spec = GetSpecialization()
			if spec then
				role = GetSpecializationRole(spec)
			end
		end
	end
	if not role or role == "" then
		role = "NONE"
	end
	return role
end

local function IsGroupLeaderOrAssistant()
	return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
end

local function UpdateClassColor()
	local _, classTag = UnitClass("player")
	if not classTag then
		return
	end

	local color
	if C_ClassColor and C_ClassColor.GetClassColor then
		color = C_ClassColor.GetClassColor(classTag)
	end
	if not color and RAID_CLASS_COLORS then
		color = RAID_CLASS_COLORS[classTag]
	end

	if color and color.r and color.g and color.b then
		playerClassColor = { r = color.r, g = color.g, b = color.b }
	end
end

local function RefreshAccentColorFromDB()
	if db.accentColorMode == "custom" then
		classColor = {
			r = db.customAccentColor.r,
			g = db.customAccentColor.g,
			b = db.customAccentColor.b,
		}
	else
		classColor = {
			r = playerClassColor.r,
			g = playerClassColor.g,
			b = playerClassColor.b,
		}
	end
end

local function RefreshPaletteFromDB()
	palette = CopyTheme(themePresets[db.themePreset] or themePresets.qui)
end

local function EnsureDatabase()
	BuildFontOptions()

	if type(_G[DB_NAME]) ~= "table" then
		_G[DB_NAME] = {}
	end

	db = _G[DB_NAME]
	for key, value in pairs(defaults) do
		if db[key] == nil then
			db[key] = DeepCopyTable(value)
		elseif type(value) == "table" and type(db[key]) ~= "table" then
			db[key] = DeepCopyTable(value)
		end
	end

	db.scale = Clamp(tonumber(db.scale) or defaults.scale, 0.7, 1.4)
	db.alpha = Clamp(tonumber(db.alpha) or defaults.alpha, 0.35, 1)
	db.countdownSeconds = Clamp(math.floor(tonumber(db.countdownSeconds) or defaults.countdownSeconds), 3, 30)
	db.customAccentColor.r = Clamp(tonumber(db.customAccentColor.r) or defaults.customAccentColor.r, 0, 1)
	db.customAccentColor.g = Clamp(tonumber(db.customAccentColor.g) or defaults.customAccentColor.g, 0, 1)
	db.customAccentColor.b = Clamp(tonumber(db.customAccentColor.b) or defaults.customAccentColor.b, 0, 1)

	if not VISIBILITY_DRIVER_BY_MODE[db.showMode] then
		db.showMode = defaults.showMode
	end
	if not themePresets[db.themePreset] then
		db.themePreset = defaults.themePreset
	end
	if db.accentColorMode ~= "class" and db.accentColorMode ~= "custom" then
		db.accentColorMode = defaults.accentColorMode
	end
	if db.dropdownDirection ~= "down" and db.dropdownDirection ~= "up" then
		db.dropdownDirection = defaults.dropdownDirection
	end
	if not fontOptionByID[db.fontPreset] then
		db.fontPreset = defaults.fontPreset
	end
end

local function SavePosition()
	if not anchor then
		return
	end

	local point, _, relativePoint, x, y = anchor:GetPoint(1)
	if point and relativePoint then
		db.point = point
		db.relativePoint = relativePoint
		db.x = Round(x)
		db.y = Round(y)
	end
end

local function RestorePosition()
	if not anchor then
		return
	end
	anchor:ClearAllPoints()
	anchor:SetPoint(db.point, UIParent, db.relativePoint, db.x, db.y)
end

local function UpdateArrow()
	if not dropdown or not arrowLabel then
		return
	end

	local isDownDirection = db.dropdownDirection ~= "up"
	if dropdown:IsShown() then
		arrowLabel:SetText(isDownDirection and "^" or "v")
	else
		arrowLabel:SetText(isDownDirection and "v" or "^")
	end
end

local function ApplyExpandedState()
	if not dropdown then
		return
	end
	dropdown:SetShown(db.expanded)
	UpdateArrow()
end

local function UpdateMoverVisibility()
	if not moverOverlay then
		return
	end
	moverOverlay:SetShown(isEditMode and not db.locked)
end

local function ApplyDropdownDirection()
	if not dropdown or not anchor then
		return
	end

	dropdown:ClearAllPoints()
	if db.dropdownDirection == "up" then
		dropdown:SetPoint("BOTTOM", anchor, "TOP", 0, 2)
	else
		dropdown:SetPoint("TOP", anchor, "BOTTOM", 0, -2)
	end
end

local function ApplyVisibilityDriver()
	if not anchor then
		return
	end

	if InCombatLockdown() then
		pendingVisibilityUpdate = true
		return
	end

	pendingVisibilityUpdate = false
	UnregisterStateDriver(anchor, "visibility")

	if isEditMode then
		anchor:Show()
		return
	end

	local driver = VISIBILITY_DRIVER_BY_MODE[db.showMode] or VISIBILITY_DRIVER_BY_MODE[SHOW_MODE_GROUP]
	if driver == "show" then
		anchor:Show()
	elseif driver == "hide" then
		anchor:Hide()
	else
		RegisterStateDriver(anchor, "visibility", driver)
	end
end

local function SetEditModeEnabled(enabled)
	isEditMode = enabled and true or false
	UpdateMoverVisibility()
	ApplyVisibilityDriver()
end

local function SetupEditModeCallbacks()
	if EventRegistry and EventRegistry.RegisterCallback then
		EventRegistry:RegisterCallback("EditMode.Enter", function()
			SetEditModeEnabled(true)
		end, addon)

		EventRegistry:RegisterCallback("EditMode.Exit", function()
			SetEditModeEnabled(false)
		end, addon)
	end

	if EditModeManagerFrame and EditModeManagerFrame:IsShown() then
		SetEditModeEnabled(true)
	end
end

local function ApplyAnchorScaleAndAlpha()
	if not anchor then
		return
	end
	anchor:SetScale(db.scale)
	anchor:SetAlpha(db.alpha)
end

local function ShowButtonTooltip(button, owner)
	if not button then
		return
	end

	GameTooltip:SetOwner(owner or button, button.tooltipAnchor or "ANCHOR_RIGHT")

	local title = button.tooltipTitle or ""
	if button.tooltipDynamicTitle then
		title = button.tooltipDynamicTitle()
	end
	GameTooltip:SetText(title, classColor.r, classColor.g, classColor.b)

	if button.tooltipLines then
		for _, line in ipairs(button.tooltipLines) do
			GameTooltip:AddLine(line, unpack(palette.mutedText))
		end
	end

	if button.disabledReason then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(button.disabledReason, 1, 0.35, 0.35, true)
	end

	GameTooltip:Show()
end

local function CreateDisabledOverlay(button)
	local overlay = CreateFrame("Frame", nil, button)
	overlay:SetAllPoints(button)
	overlay:SetFrameLevel(button:GetFrameLevel() + 6)
	overlay:EnableMouse(true)
	overlay:SetScript("OnMouseDown", function()
	end)
	overlay:SetScript("OnMouseUp", function()
	end)
	overlay:SetScript("OnEnter", function(self)
		ShowButtonTooltip(button, self)
	end)
	overlay:SetScript("OnLeave", function()
		GameTooltip_Hide()
	end)
	overlay:Hide()
	button.disabledOverlay = overlay
end

local function RefreshButtonVisual(button)
	if not button then
		return
	end

	button:SetBackdropColor(unpack(palette.buttonBg))
	button:SetBackdropBorderColor(unpack(palette.buttonBorder))

	if button.label then
		if button.isDisabled then
			button.label:SetTextColor(unpack(palette.mutedText))
		else
			button.label:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
		end
	end

	if button.icon and button.icon.SetVertexColor then
		if button.isDisabled then
			button.icon:SetVertexColor(unpack(palette.mutedText))
		else
			button.icon:SetVertexColor(classColor.r, classColor.g, classColor.b, 1)
		end
	end

	button:SetAlpha(button.isDisabled and 0.45 or 1)
end

local function SetButtonDisabled(button, disabled, reason)
	button.isDisabled = disabled and true or false
	button.disabledReason = disabled and reason or nil

	if button.disabledOverlay then
		button.disabledOverlay:SetShown(button.isDisabled)
	end

	if button.icon and button.icon.SetDesaturated then
		button.icon:SetDesaturated(button.isDisabled)
	end

	RefreshButtonVisual(button)
end

local function CreateSecureActionButton(name, parent, label, width, height, point, relativeTo, relativePoint, x, y)
	local button = CreateFrame("Button", name, parent, "SecureActionButtonTemplate,BackdropTemplate")
	button:SetSize(width, height)
	button:SetPoint(point, relativeTo, relativePoint, x, y)
	button:RegisterForClicks("AnyDown", "AnyUp")
	SetBackdropStyle(button, 8)
	button:SetBackdropColor(unpack(palette.buttonBg))
	button:SetBackdropBorderColor(unpack(palette.buttonBorder))
	button.tooltipTitle = label or ""
	button.tooltipLines = {}
	button.tooltipAnchor = "ANCHOR_RIGHT"

	button:SetScript("OnEnter", function(self)
		self:SetBackdropColor(unpack(palette.buttonHover))
		SetClassAccentBorder(self, 0.95, 0.8)
		ShowButtonTooltip(self)
	end)

	button:SetScript("OnLeave", function(self)
		self:SetBackdropColor(unpack(palette.buttonBg))
		self:SetBackdropBorderColor(unpack(palette.buttonBorder))
		GameTooltip_Hide()
	end)

	if label and label ~= "" then
		local text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		text:SetPoint("CENTER")
		text:SetText(label)
		text:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
		TrackFontString(text, 12)
		text:SetShadowOffset(1, -1)
		text:SetShadowColor(0, 0, 0, 0.9)
		button.label = text
	end

	CreateDisabledOverlay(button)
	table.insert(themedButtons, button)
	return button
end

local function GetGroupChatChannel()
	if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
		return "INSTANCE_CHAT"
	end
	if IsInRaid(LE_PARTY_CATEGORY_HOME) then
		return "RAID"
	end
	if IsInGroup(LE_PARTY_CATEGORY_HOME) then
		return "PARTY"
	end
	return nil
end

local function AnnounceMarker(markerIndex)
	if not db.announceMarkers then
		return
	end

	local channel = GetGroupChatChannel()
	if not channel then
		return
	end
	if not UnitExists("target") then
		return
	end

	local targetName = UnitName("target")
	if not targetName or targetName == "" then
		return
	end

	SendChatMessage(string.format("{rt%d} %s", markerIndex, targetName), channel)
end

local function CreateMarkerButton(parent, markerIndex)
	local button = CreateSecureActionButton(nil, parent, nil, 24, 24, "TOPLEFT", parent, "TOPLEFT", 0, 0)
	button.markerIndex = markerIndex
	button.tooltipTitle = _G["RAID_TARGET_" .. markerIndex] or ("Marker " .. markerIndex)
	button.tooltipLines = {
		"Left click: set on target",
		"Right click: clear this marker from target",
	}

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetPoint("TOPLEFT", 3, -3)
	icon:SetPoint("BOTTOMRIGHT", -3, 3)
	icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. markerIndex)
	button.icon = icon

	button:HookScript("OnClick", function(self, mouseButton, down)
		if down or mouseButton ~= "LeftButton" or self.isDisabled then
			return
		end
		AnnounceMarker(markerIndex)
	end)

	return button
end

local function ApplyLayout()
	if not anchor then
		return
	end

	local layout = normalLayout

	anchor:SetWidth(layout.anchorWidth)
	dropdown:SetSize(layout.dropdownWidth, layout.dropdownHeight)

	clearButton:ClearAllPoints()
	clearButton:SetPoint("TOP", dropdown, "TOP", 0, layout.clearTopOffset)
	clearButton:SetSize(layout.clearWidth, layout.clearHeight)

	markersLabel:ClearAllPoints()
	markersLabel:SetPoint("TOPLEFT", 12, layout.markersLabelY)

	markerHolder:ClearAllPoints()
	markerHolder:SetPoint("TOPLEFT", 11, layout.markerHolderY)
	markerHolder:SetSize(layout.dropdownWidth - 22, 52)

	for index, button in ipairs(markerButtons) do
		local col = (index - 1) % 4
		local row = math.floor((index - 1) / 4)
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", markerHolder, "TOPLEFT", col * layout.markerXSpacing, -(row * layout.markerYSpacing))
		button:SetSize(layout.markerSize, layout.markerSize)
		button.icon:ClearAllPoints()
		button.icon:SetPoint("TOPLEFT", layout.iconInset, -layout.iconInset)
		button.icon:SetPoint("BOTTOMRIGHT", -layout.iconInset, layout.iconInset)
	end

	readyButton:ClearAllPoints()
	readyButton:SetPoint("BOTTOMLEFT", dropdown, "BOTTOMLEFT", layout.readyLeft, layout.buttonsBottom)
	readyButton:SetSize(layout.actionWidth, layout.actionHeight)

	countdownButton:ClearAllPoints()
	countdownButton:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", layout.countdownRight, layout.buttonsBottom)
	countdownButton:SetSize(layout.actionWidth, layout.actionHeight)

	readyIcon:SetSize(layout.readyIconSize, layout.readyIconSize)
	countdownIcon:SetSize(layout.countdownIconSize, layout.countdownIconSize)
end

local function ApplyTheme()
	if not anchor then
		return
	end

	headerButton:SetBackdropColor(unpack(palette.headerBg))
	headerButton:SetBackdropBorderColor(unpack(palette.panelBorder))
	dropdown:SetBackdropColor(unpack(palette.panelBg))
	dropdown:SetBackdropBorderColor(unpack(palette.panelBorder))
	dropdownShade:SetColorTexture(0, 0, 0, 0.2)

	if dropdownAccent then
		dropdownAccent:SetColorTexture(classColor.r, classColor.g, classColor.b, 0.4)
	end
	if headerAccent then
		headerAccent:SetColorTexture(classColor.r, classColor.g, classColor.b, 0.35)
	end

	titleText:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	arrowLabel:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	brStatusText:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	lustStatusText:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	markersLabel:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	countdownText:SetTextColor(classColor.r, classColor.g, classColor.b, 1)

	for _, label in ipairs(optionsAccentLabels) do
		label:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	end

	if moverOverlay then
		moverOverlay:SetBackdropColor(unpack(palette.moverBg))
		moverOverlay:SetBackdropBorderColor(unpack(palette.moverBorder))
	end

	for _, button in ipairs(themedButtons) do
		RefreshButtonVisual(button)
	end

	headerButton:SetScript("OnEnter", function()
		headerButton:SetBackdropColor(unpack(palette.headerHover))
		SetClassAccentBorder(headerButton, 0.95, 0.8)
	end)

	headerButton:SetScript("OnLeave", function()
		headerButton:SetBackdropColor(unpack(palette.headerBg))
		headerButton:SetBackdropBorderColor(unpack(palette.panelBorder))
	end)
end

local function BuildCountdownMacroText()
	return "/countdown " .. tostring(db.countdownSeconds)
end

local function UpdateReadyTooltip()
	if not readyButton then
		return
	end

	local lines = { "Left click: start ready check" }
	if db.tankShortcut and currentRole == "TANK" then
		table.insert(lines, "Right click: start pull countdown")
	end
	readyButton.tooltipLines = lines
end

local function UpdateCountdownDisplay()
	if not countdownText or not countdownButton then
		return
	end

	countdownText:SetText(tostring(db.countdownSeconds))
	countdownButton.tooltipDynamicTitle = function()
		return "Countdown " .. tostring(db.countdownSeconds)
	end
end

local function ApplySecureAttributesNow()
	if InCombatLockdown() then
		pendingSecureUpdate = true
		return
	end

	pendingSecureUpdate = false

	if clearButton then
		clearButton:SetAttribute("type", "raidtarget")
		clearButton:SetAttribute("action", "clear-all")
	end

	if readyButton then
		readyButton:SetAttribute("type", "macro")
		readyButton:SetAttribute("macrotext", "/readycheck")

		if db.tankShortcut and currentRole == "TANK" then
			readyButton:SetAttribute("type2", "macro")
			readyButton:SetAttribute("macrotext2", BuildCountdownMacroText())
		else
			readyButton:SetAttribute("type2", nil)
			readyButton:SetAttribute("macrotext2", nil)
		end
	end

	if countdownButton then
		countdownButton:SetAttribute("type", "macro")
		countdownButton:SetAttribute("macrotext", BuildCountdownMacroText())
	end

	for _, button in ipairs(markerButtons) do
		local markerIndex = button.markerIndex
		local markerName = MARKER_CONDITION_NAME[markerIndex] or tostring(markerIndex)
		button:SetAttribute("type", "macro")
		button:SetAttribute("macrotext", "/tm [@target,exists] " .. markerIndex)
		button:SetAttribute("type2", "macro")
		button:SetAttribute("macrotext2", "/tm [@target,exists,raidtarget:" .. markerName .. "] 0")
	end
end

local function QueueSecureAttributesUpdate()
	if InCombatLockdown() then
		pendingSecureUpdate = true
	else
		ApplySecureAttributesNow()
	end
end

local function GetRaidControlPermissionReason()
	if not IsInGroup() then
		return false, "Join a party or raid to use this action."
	end
	if IsInRaid() and not IsGroupLeaderOrAssistant() then
		return false, "Requires raid leader or assistant."
	end
	return true, nil
end

local function GetReadyCheckPermissionReason()
	local ok, reason = GetRaidControlPermissionReason()
	if not ok then
		return false, reason
	end
	return true, nil
end

local function GetCountdownPermissionReason()
	local ok, reason = GetRaidControlPermissionReason()
	if not ok then
		return false, reason
	end
	return true, nil
end

local function GetMarkerPermissionReason()
	local ok, reason = GetRaidControlPermissionReason()
	if not ok then
		return false, reason
	end
	if not UnitExists("target") then
		return false, "You need a valid target."
	end
	if CanBeRaidTarget and not CanBeRaidTarget("target") then
		return false, "Current target cannot be marked."
	end
	return true, nil
end

local function UpdateActionAvailability()
	if not readyButton then
		return
	end

	local readyOK, readyReason = GetReadyCheckPermissionReason()
	SetButtonDisabled(readyButton, not readyOK, readyReason)

	local countdownOK, countdownReason = GetCountdownPermissionReason()
	SetButtonDisabled(countdownButton, not countdownOK, countdownReason)

	local clearOK, clearReason = GetRaidControlPermissionReason()
	SetButtonDisabled(clearButton, not clearOK, clearReason)

	local markerOK, markerReason = GetMarkerPermissionReason()
	for _, button in ipairs(markerButtons) do
		SetButtonDisabled(button, not markerOK, markerReason)
	end
end

local function UnitHasAuraBySpellID(unit, spellID)
	if C_UnitAuras and C_UnitAuras.GetAuraDataBySpellID then
		return C_UnitAuras.GetAuraDataBySpellID(unit, spellID) ~= nil
	end

	for index = 1, 40 do
		local _, _, _, _, _, _, _, _, _, auraSpellID = UnitDebuff(unit, index)
		if not auraSpellID then
			break
		end
		if auraSpellID == spellID then
			return true
		end
	end

	return false
end

local function UnitHasLustLockout(unit)
	if not UnitExists(unit) then
		return false
	end
	for _, spellID in ipairs(LUST_LOCKOUT_SPELL_IDS) do
		if UnitHasAuraBySpellID(unit, spellID) then
			return true
		end
	end
	return false
end

local function GroupHasLustLockout()
	if IsInRaid() then
		for index = 1, GetNumGroupMembers() do
			if UnitHasLustLockout("raid" .. index) then
				return true
			end
		end
		return false
	end

	if UnitHasLustLockout("player") then
		return true
	end

	for index = 1, GetNumSubgroupMembers() do
		if UnitHasLustLockout("party" .. index) then
			return true
		end
	end
	return false
end

local function GetKnownSpellCharges(spellID)
	if C_Spell and C_Spell.GetSpellCharges then
		local info = C_Spell.GetSpellCharges(spellID)
		if info and info.currentCharges ~= nil then
			return info.currentCharges, info.maxCharges
		end
	end
	if GetSpellCharges then
		local current, maxCharges = GetSpellCharges(spellID)
		if current ~= nil then
			return current, maxCharges
		end
	end
	return nil, nil
end

local function GetBattleResCharges()
	for _, spellID in ipairs(BATTLE_RES_SPELL_IDS) do
		local known = (IsPlayerSpell and IsPlayerSpell(spellID))
		if not known and IsSpellKnownOrOverridesKnown then
			known = IsSpellKnownOrOverridesKnown(spellID)
		end
		if known then
			local charges, maxCharges = GetKnownSpellCharges(spellID)
			if charges ~= nil then
				return charges, maxCharges
			end
		end
	end
	return nil, nil
end

local function UpdateMythicWidgets()
	if not brStatusText or not lustStatusText or not titleText then
		return
	end

	if not db.showMythicWidgets then
		titleText:Show()
		brStatusText:Hide()
		lustStatusText:Hide()
		return
	end

	titleText:Hide()
	brStatusText:Show()
	lustStatusText:Show()

	local challengeActive = C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive()
	if not challengeActive then
		brStatusText:SetText("BR --")
		brStatusText:SetTextColor(unpack(palette.mutedText))
		lustStatusText:SetText("Lust --")
		lustStatusText:SetTextColor(unpack(palette.mutedText))
		return
	end

	local charges, maxCharges = GetBattleResCharges()
	if charges ~= nil then
		local suffix = ""
		if maxCharges and maxCharges > 0 then
			suffix = string.format("/%d", maxCharges)
		end
		brStatusText:SetText(string.format("BR %d%s", charges, suffix))
		brStatusText:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	else
		brStatusText:SetText("BR ?")
		brStatusText:SetTextColor(unpack(palette.mutedText))
	end

	if GroupHasLustLockout() then
		lustStatusText:SetText("Lust Used")
		lustStatusText:SetTextColor(1, 0.35, 0.35, 1)
	else
		lustStatusText:SetText("Lust Ready")
		lustStatusText:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	end
end

local function RefreshOptionsPanelValues()
	if not optionsPanel then
		return
	end

	for _, refresher in ipairs(optionsRefreshers) do
		refresher()
	end
end

local function ApplyConfiguredState()
	currentRole = GetAssignedRole()
	BuildFontOptions()
	if not fontOptionByID[db.fontPreset] then
		db.fontPreset = defaults.fontPreset
	end
	RefreshAccentColorFromDB()
	RefreshPaletteFromDB()
	ApplyDropdownDirection()
	UpdateArrow()
	ApplyLayout()
	ApplyTrackedFonts()
	ApplyTheme()
	ApplyAnchorScaleAndAlpha()
	UpdateMoverVisibility()
	UpdateCountdownDisplay()
	UpdateReadyTooltip()
	QueueSecureAttributesUpdate()
	ApplyVisibilityDriver()
	UpdateActionAvailability()
	UpdateMythicWidgets()
	RefreshOptionsPanelValues()
end

local function OpenOptionsPanel()
	if not optionsPanel then
		return
	end

	if Settings and Settings.OpenToCategory and optionsPanel.categoryID then
		Settings.OpenToCategory(optionsPanel.categoryID)
		return
	end

	if InterfaceOptionsFrame_OpenToCategory then
		InterfaceOptionsFrame_OpenToCategory(optionsPanel)
		InterfaceOptionsFrame_OpenToCategory(optionsPanel)
		return
	end

	optionsPanel:Show()
end

local function ResetPosition()
	db.point = defaults.point
	db.relativePoint = defaults.relativePoint
	db.x = defaults.x
	db.y = defaults.y
	RestorePosition()
	SavePosition()
end

local function SetCountdownSeconds(seconds)
	db.countdownSeconds = Clamp(math.floor(seconds), 3, 30)
	ApplyConfiguredState()
end

local function RegisterSlashCommands()
	SLASH_WOWDUNGEONASSIST1 = "/wda"
	SlashCmdList.WOWDUNGEONASSIST = function(msg)
		local command, argument = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
		command = (command or ""):lower()
		argument = argument or ""

		if command == "show" then
			db.showMode = SHOW_MODE_ALWAYS
			ApplyConfiguredState()
			PrintMessage("Visibility mode set to Always Show.")
		elseif command == "auto" or command == "hide" then
			db.showMode = SHOW_MODE_GROUP
			ApplyConfiguredState()
			PrintMessage("Visibility mode set to Group Only.")
		elseif command == "mode" then
			local mode = argument:lower()
			if mode == "group" or mode == "always" or mode == "hidden" then
				db.showMode = mode
				ApplyConfiguredState()
				PrintMessage("Visibility mode: " .. (SHOW_MODE_LABELS[db.showMode] or db.showMode))
			else
				PrintMessage("Usage: /wda mode group|always|hidden")
			end
		elseif command == "reset" then
			ResetPosition()
			db.showMode = SHOW_MODE_ALWAYS
			ApplyConfiguredState()
			PrintMessage("Position reset and visibility mode set to Always Show.")
		elseif command == "where" then
			PrintMessage(string.format("Position: %s %d, %d", db.point, db.x, db.y))
		elseif command == "config" or command == "options" then
			OpenOptionsPanel()
		elseif command == "cd" or command == "countdown" then
			local value = tonumber(argument)
			if value then
				SetCountdownSeconds(value)
				PrintMessage("Countdown default set to " .. db.countdownSeconds .. " seconds.")
			else
				PrintMessage("Usage: /wda cd <seconds>")
			end
		elseif command == "announce" then
			db.announceMarkers = not db.announceMarkers
			ApplyConfiguredState()
			PrintMessage("Marker announce " .. (db.announceMarkers and "enabled." or "disabled."))
		elseif command == "lock" then
			db.locked = not db.locked
			ApplyConfiguredState()
			PrintMessage("Panel lock " .. (db.locked and "enabled." or "disabled."))
		else
			PrintMessage("Commands: /wda config, /wda show, /wda auto, /wda mode, /wda cd, /wda lock, /wda announce, /wda reset, /wda where")
		end
	end
end

local function RegisterOptionsPanel()
	if not optionsPanel then
		return
	end

	if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
		local category = Settings.RegisterCanvasLayoutCategory(optionsPanel, "WoW Dungeon Assist")
		Settings.RegisterAddOnCategory(category)
		optionsPanel.categoryID = category:GetID()
	elseif InterfaceOptions_AddCategory then
		optionsPanel.name = "WoW Dungeon Assist"
		InterfaceOptions_AddCategory(optionsPanel)
	end
end

local function AddOptionsRefresher(func)
	table.insert(optionsRefreshers, func)
end

local function AddOptionsLabel(label, size, flags)
	table.insert(optionsAccentLabels, label)
	TrackFontString(label, size or 12, flags)
end

local function CreateOptionsValueText(parent, x, y)
	local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	text:SetPoint("TOPLEFT", x, y)
	text:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	text:SetShadowOffset(1, -1)
	text:SetShadowColor(0, 0, 0, 0.9)
	AddOptionsLabel(text, 12)
	return text
end

local function CreateOptionsButton(parent, width, height)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width, height)
	return button
end

local function CreateNumericRow(parent, y, labelText, getter, setter, step, minValue, maxValue, formatter)
	local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("TOPLEFT", 22, y)
	label:SetText(labelText)
	label:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	label:SetShadowOffset(1, -1)
	label:SetShadowColor(0, 0, 0, 0.9)
	AddOptionsLabel(label, 12)

	local minus = CreateOptionsButton(parent, 24, 20)
	minus:SetPoint("TOPLEFT", 260, y + 2)
	minus:SetText("-")

	local value = CreateOptionsValueText(parent, 292, y - 2)
	value:SetJustifyH("CENTER")
	value:SetWidth(80)

	local plus = CreateOptionsButton(parent, 24, 20)
	plus:SetPoint("TOPLEFT", 378, y + 2)
	plus:SetText("+")

	local function applyDelta(delta)
		local nextValue = Clamp(getter() + delta, minValue, maxValue)
		setter(nextValue)
		ApplyConfiguredState()
	end

	minus:SetScript("OnClick", function()
		applyDelta(-step)
	end)
	plus:SetScript("OnClick", function()
		applyDelta(step)
	end)

	AddOptionsRefresher(function()
		value:SetText(formatter(getter()))
	end)
end

local function CreateCycleRow(parent, y, labelText, values, getter, setter, formatter)
	local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("TOPLEFT", 22, y)
	label:SetText(labelText)
	label:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	label:SetShadowOffset(1, -1)
	label:SetShadowColor(0, 0, 0, 0.9)
	AddOptionsLabel(label, 12)

	local button = CreateOptionsButton(parent, 142, 20)
	button:SetPoint("TOPLEFT", 260, y + 2)
	button:SetScript("OnClick", function()
		local current = getter()
		local index = 1
		for i, value in ipairs(values) do
			if value == current then
				index = i
				break
			end
		end

		if IsShiftKeyDown() then
			index = index - 1
			if index < 1 then
				index = #values
			end
		else
			index = index + 1
			if index > #values then
				index = 1
			end
		end

		setter(values[index])
		ApplyConfiguredState()
	end)

	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Click to cycle", classColor.r, classColor.g, classColor.b)
		GameTooltip:AddLine("Shift-click cycles backwards.", unpack(palette.mutedText))
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		GameTooltip_Hide()
	end)

	AddOptionsRefresher(function()
		button:SetText(formatter(getter()))
	end)
end

local function CreateDropdownRow(parent, y, labelText, width, getItems, getter, setter)
	local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("TOPLEFT", 22, y)
	label:SetText(labelText)
	label:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	label:SetShadowOffset(1, -1)
	label:SetShadowColor(0, 0, 0, 0.9)
	AddOptionsLabel(label, 12)

	local dropdownFrame = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
	dropdownFrame:SetPoint("TOPLEFT", 232, y + 14)
	UIDropDownMenu_SetWidth(dropdownFrame, width or 170)

	local function initialize(_, level)
		if level ~= 1 then
			return
		end

		for _, item in ipairs(getItems()) do
			local value = item.value
			local text = item.label
			local info = UIDropDownMenu_CreateInfo()
			info.text = text
			info.value = value
			info.checked = (getter() == value)
			info.func = function()
				setter(value)
				ApplyConfiguredState()
			end
			UIDropDownMenu_AddButton(info, level)
		end
	end

	local function refresh()
		UIDropDownMenu_Initialize(dropdownFrame, initialize)

		local selected = getter()
		local selectedLabel = nil
		for _, item in ipairs(getItems()) do
			if item.value == selected then
				selectedLabel = item.label
				break
			end
		end
		UIDropDownMenu_SetText(dropdownFrame, selectedLabel or tostring(selected))
	end

	AddOptionsRefresher(refresh)
	return dropdownFrame
end

local function CreateToggleRow(parent, y, labelText, getter, setter)
	local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("TOPLEFT", 22, y)
	label:SetText(labelText)
	label:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	label:SetShadowOffset(1, -1)
	label:SetShadowColor(0, 0, 0, 0.9)
	AddOptionsLabel(label, 12)

	local button = CreateOptionsButton(parent, 142, 20)
	button:SetPoint("TOPLEFT", 260, y + 2)
	button:SetScript("OnClick", function()
		setter(not getter())
		ApplyConfiguredState()
	end)

	AddOptionsRefresher(function()
		button:SetText(getter() and "Enabled" or "Disabled")
	end)
end

local function BuildColorHexText(color)
	local r = Clamp(math.floor((color.r or 1) * 255 + 0.5), 0, 255)
	local g = Clamp(math.floor((color.g or 1) * 255 + 0.5), 0, 255)
	local b = Clamp(math.floor((color.b or 1) * 255 + 0.5), 0, 255)
	return string.format("#%02X%02X%02X", r, g, b)
end

local function OpenAccentColorPicker()
	if not ColorPickerFrame or not db then
		return
	end

	local startColor = {
		r = db.customAccentColor.r,
		g = db.customAccentColor.g,
		b = db.customAccentColor.b,
	}

	local function applyColor(r, g, b)
		db.customAccentColor.r = Clamp(r or startColor.r, 0, 1)
		db.customAccentColor.g = Clamp(g or startColor.g, 0, 1)
		db.customAccentColor.b = Clamp(b or startColor.b, 0, 1)
		db.accentColorMode = "custom"
		ApplyConfiguredState()
	end

	if ColorPickerFrame.SetupColorPickerAndShow then
		local info = {}
		info.r = startColor.r
		info.g = startColor.g
		info.b = startColor.b
		info.hasOpacity = false
		info.previousValues = startColor
		info.swatchFunc = function()
			local r, g, b = ColorPickerFrame:GetColorRGB()
			applyColor(r, g, b)
		end
		info.cancelFunc = function(previousValues)
			local previousR = previousValues and (previousValues.r or previousValues[1]) or startColor.r
			local previousG = previousValues and (previousValues.g or previousValues[2]) or startColor.g
			local previousB = previousValues and (previousValues.b or previousValues[3]) or startColor.b
			applyColor(previousR, previousG, previousB)
		end
		ColorPickerFrame:SetupColorPickerAndShow(info)
		return
	end

	ColorPickerFrame.hasOpacity = false
	ColorPickerFrame.previousValues = startColor
	ColorPickerFrame:SetColorRGB(startColor.r, startColor.g, startColor.b)
	ColorPickerFrame.func = function()
		local r, g, b = ColorPickerFrame:GetColorRGB()
		applyColor(r, g, b)
	end
	ColorPickerFrame.cancelFunc = function(previousValues)
		local previousR = previousValues and (previousValues.r or previousValues[1]) or startColor.r
		local previousG = previousValues and (previousValues.g or previousValues[2]) or startColor.g
		local previousB = previousValues and (previousValues.b or previousValues[3]) or startColor.b
		applyColor(previousR, previousG, previousB)
	end
	ColorPickerFrame:Hide()
	ColorPickerFrame:Show()
end

local function CreateOptionsPanel()
	optionsPanel = CreateFrame("Frame", "WoWDungeonAssistOptionsPanel", UIParent)
	optionsPanel.name = "WoW Dungeon Assist"

	local title = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("WoW Dungeon Assist")
	title:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	title:SetShadowOffset(1, -1)
	title:SetShadowColor(0, 0, 0, 0.9)
	AddOptionsLabel(title, 16)

	local subtitle = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtitle:SetPoint("TOPLEFT", 16, -40)
	subtitle:SetText("Control panel behavior, style, countdown defaults, and role-aware helpers.")
	subtitle:SetTextColor(unpack(palette.mutedText))
	TrackFontString(subtitle, 11)

	local y = -78
	CreateNumericRow(optionsPanel, y, "Panel Scale", function()
		return db.scale
	end, function(value)
		db.scale = Clamp(Round(value * 100) / 100, 0.7, 1.4)
	end, 0.05, 0.7, 1.4, function(value)
		return string.format("%.2f", value)
	end)

	y = y - 30
	CreateNumericRow(optionsPanel, y, "Panel Alpha", function()
		return db.alpha
	end, function(value)
		db.alpha = Clamp(Round(value * 100) / 100, 0.35, 1)
	end, 0.05, 0.35, 1, function(value)
		return string.format("%.2f", value)
	end)

	y = y - 30
	CreateCycleRow(optionsPanel, y, "Visibility Mode", { SHOW_MODE_GROUP, SHOW_MODE_ALWAYS, SHOW_MODE_HIDDEN }, function()
		return db.showMode
	end, function(value)
		db.showMode = value
	end, function(value)
		return SHOW_MODE_LABELS[value] or value
	end)

	y = y - 30
	CreateCycleRow(optionsPanel, y, "Theme Preset", { "qui", "slate", "ember" }, function()
		return db.themePreset
	end, function(value)
		db.themePreset = value
	end, function(value)
		return THEME_LABELS[value] or value
	end)

	y = y - 30
	CreateDropdownRow(optionsPanel, y, "Accent Source", 170, function()
		return {
			{ value = "class", label = ACCENT_SOURCE_LABELS.class },
			{ value = "custom", label = ACCENT_SOURCE_LABELS.custom },
		}
	end, function()
		return db.accentColorMode
	end, function(value)
		db.accentColorMode = value
	end)

	y = y - 30
	local accentLabel = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	accentLabel:SetPoint("TOPLEFT", 22, y)
	accentLabel:SetText("Custom Accent Color")
	accentLabel:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	accentLabel:SetShadowOffset(1, -1)
	accentLabel:SetShadowColor(0, 0, 0, 0.9)
	AddOptionsLabel(accentLabel, 12)

	accentPickerButton = CreateOptionsButton(optionsPanel, 142, 20)
	accentPickerButton:SetPoint("TOPLEFT", 260, y + 2)
	accentPickerButton:SetScript("OnClick", function()
		OpenAccentColorPicker()
	end)

	AddOptionsRefresher(function()
		if db.accentColorMode == "custom" then
			accentPickerButton:Enable()
			accentPickerButton:SetText("Pick " .. BuildColorHexText(db.customAccentColor))
		else
			accentPickerButton:Disable()
			accentPickerButton:SetText("Class Color")
		end
	end)

	y = y - 30
	CreateCycleRow(optionsPanel, y, "Dropdown Direction", { "down", "up" }, function()
		return db.dropdownDirection
	end, function(value)
		db.dropdownDirection = value
	end, function(value)
		return DROPDOWN_DIRECTION_LABELS[value] or value
	end)

	y = y - 30
	CreateDropdownRow(optionsPanel, y, "Font", 220, function()
		local items = {}
		for _, fontEntry in ipairs(fontOptions) do
			items[#items + 1] = {
				value = fontEntry.id,
				label = fontEntry.label,
			}
		end
		return items
	end, function()
		return db.fontPreset
	end, function(value)
		db.fontPreset = value
	end)

	y = y - 30
	CreateCycleRow(optionsPanel, y, "Default Countdown", COUNTDOWN_PRESETS, function()
		return db.countdownSeconds
	end, function(value)
		db.countdownSeconds = value
	end, function(value)
		return string.format("%ds", value)
	end)

	y = y - 40
	local behaviorHeader = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	behaviorHeader:SetPoint("TOPLEFT", 16, y)
	behaviorHeader:SetText("Behavior")
	behaviorHeader:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	behaviorHeader:SetShadowOffset(1, -1)
	behaviorHeader:SetShadowColor(0, 0, 0, 0.9)
	AddOptionsLabel(behaviorHeader, 13)

	y = y - 28
	CreateToggleRow(optionsPanel, y, "Lock Mover In Edit Mode", function()
		return db.locked
	end, function(value)
		db.locked = value
	end)

	y = y - 30
	CreateToggleRow(optionsPanel, y, "Announce Marker Sets", function()
		return db.announceMarkers
	end, function(value)
		db.announceMarkers = value
	end)

	y = y - 30
	CreateToggleRow(optionsPanel, y, "Tank Shortcut (Ready RMB = Countdown)", function()
		return db.tankShortcut
	end, function(value)
		db.tankShortcut = value
	end)

	y = y - 30
	CreateToggleRow(optionsPanel, y, "Mythic+ Header Widgets", function()
		return db.showMythicWidgets
	end, function(value)
		db.showMythicWidgets = value
	end)

	local resetPositionButton = CreateOptionsButton(optionsPanel, 142, 22)
	resetPositionButton:SetPoint("TOPLEFT", 22, y - 44)
	resetPositionButton:SetText("Reset Position")
	resetPositionButton:SetScript("OnClick", function()
		ResetPosition()
		ApplyConfiguredState()
		PrintMessage("Panel position reset.")
	end)

	local resetVisualButton = CreateOptionsButton(optionsPanel, 142, 22)
	resetVisualButton:SetPoint("LEFT", resetPositionButton, "RIGHT", 10, 0)
	resetVisualButton:SetText("Reset Visuals")
	resetVisualButton:SetScript("OnClick", function()
		db.scale = defaults.scale
		db.alpha = defaults.alpha
		db.themePreset = defaults.themePreset
		db.accentColorMode = defaults.accentColorMode
		db.customAccentColor = DeepCopyTable(defaults.customAccentColor)
		db.fontPreset = defaults.fontPreset
		db.dropdownDirection = defaults.dropdownDirection
		ApplyConfiguredState()
		PrintMessage("Visual settings reset.")
	end)

	optionsPanel:SetScript("OnShow", function()
		RefreshOptionsPanelValues()
	end)
end

local function CreateUI()
	anchor = CreateFrame("Frame", "WoWDungeonAssistRaidControlAnchor", UIParent, "SecureHandlerStateTemplate")
	anchor:SetSize(normalLayout.anchorWidth, 24)
	anchor:SetFrameStrata("MEDIUM")
	anchor:SetMovable(true)
	anchor:SetClampedToScreen(true)

	headerButton = CreateFrame("Button", "WoWDungeonAssistHeaderButton", anchor, "BackdropTemplate")
	headerButton:SetAllPoints(anchor)
	headerButton:RegisterForClicks("LeftButtonUp")
	SetBackdropStyle(headerButton, 8)
	headerButton:SetBackdropColor(unpack(palette.headerBg))
	headerButton:SetBackdropBorderColor(unpack(palette.panelBorder))
	headerButton:SetScript("OnClick", function()
		WoWDungeonAssist_TogglePanel()
	end)

	titleText = headerButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	titleText:SetPoint("CENTER", -5, 0)
	titleText:SetText("Dungeon Assist")
	titleText:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	TrackFontString(titleText, 13)
	titleText:SetShadowOffset(1, -1)
	titleText:SetShadowColor(0, 0, 0, 0.9)

	arrowLabel = headerButton:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	arrowLabel:SetPoint("RIGHT", -8, 0)
	arrowLabel:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	TrackFontString(arrowLabel, 11)

	dropdown = CreateFrame("Frame", nil, anchor, "BackdropTemplate")
	dropdown:SetPoint("TOP", anchor, "BOTTOM", 0, -2)
	dropdown:SetSize(normalLayout.dropdownWidth, normalLayout.dropdownHeight)
	dropdown:SetFrameStrata("MEDIUM")
	SetBackdropStyle(dropdown, 10)
	dropdown:SetBackdropColor(unpack(palette.panelBg))
	dropdown:SetBackdropBorderColor(unpack(palette.panelBorder))

	dropdownShade = dropdown:CreateTexture(nil, "BACKGROUND")
	dropdownShade:SetAllPoints(dropdown)
	dropdownShade:SetColorTexture(0, 0, 0, 0.2)

	dropdownAccent = dropdown:CreateTexture(nil, "BORDER")
	dropdownAccent:SetPoint("TOPLEFT", 6, -6)
	dropdownAccent:SetPoint("TOPRIGHT", -6, -6)
	dropdownAccent:SetHeight(1)
	dropdownAccent:SetColorTexture(classColor.r, classColor.g, classColor.b, 0.4)

	headerAccent = headerButton:CreateTexture(nil, "BORDER")
	headerAccent:SetPoint("BOTTOMLEFT", 4, 2)
	headerAccent:SetPoint("BOTTOMRIGHT", -4, 2)
	headerAccent:SetHeight(1)
	headerAccent:SetColorTexture(classColor.r, classColor.g, classColor.b, 0.35)

	clearButton = CreateSecureActionButton("WoWDungeonAssistClearMarkersButton", dropdown, "Clear Markers", 158, 22, "TOP", dropdown, "TOP", 0, -10)
	clearButton.tooltipLines = { "Left click: clear all raid target markers." }

	markersLabel = dropdown:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	markersLabel:SetPoint("TOPLEFT", 12, -44)
	markersLabel:SetText("Target Markers")
	markersLabel:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	TrackFontString(markersLabel, 11)

	markerHolder = CreateFrame("Frame", nil, dropdown)
	markerHolder:SetPoint("TOPLEFT", 11, -58)
	markerHolder:SetSize(156, 52)

	for index, markerID in ipairs(MARKER_ORDER) do
		local button = CreateMarkerButton(markerHolder, markerID)
		local col = (index - 1) % 4
		local row = math.floor((index - 1) / 4)
		button:SetPoint("TOPLEFT", markerHolder, "TOPLEFT", col * 30, -(row * 28))
		table.insert(markerButtons, button)
	end

	brStatusText = headerButton:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	brStatusText:SetPoint("CENTER", headerButton, "CENTER", -18, 0)
	brStatusText:SetWidth(44)
	brStatusText:SetJustifyH("RIGHT")
	brStatusText:SetText("BR --")
	brStatusText:SetTextColor(unpack(palette.mutedText))
	TrackFontString(brStatusText, 11)
	brStatusText:SetShadowOffset(1, -1)
	brStatusText:SetShadowColor(0, 0, 0, 0.9)

	lustStatusText = headerButton:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	lustStatusText:SetPoint("LEFT", brStatusText, "RIGHT", 6, 0)
	lustStatusText:SetWidth(62)
	lustStatusText:SetJustifyH("LEFT")
	lustStatusText:SetText("Lust --")
	lustStatusText:SetTextColor(unpack(palette.mutedText))
	TrackFontString(lustStatusText, 11)
	lustStatusText:SetShadowOffset(1, -1)
	lustStatusText:SetShadowColor(0, 0, 0, 0.9)

	readyButton = CreateSecureActionButton("WoWDungeonAssistReadyCheckButton", dropdown, nil, 66, 26, "BOTTOMLEFT", dropdown, "BOTTOMLEFT", 14, 10)
	readyButton.tooltipTitle = "Ready Check"
	readyButton.tooltipLines = { "Left click: start ready check" }
	readyIcon = readyButton:CreateTexture(nil, "ARTWORK")
	readyIcon:SetAtlas("common-icon-checkmark", true)
	readyIcon:SetVertexColor(classColor.r, classColor.g, classColor.b, 1)
	readyIcon:SetSize(18, 18)
	readyIcon:SetPoint("CENTER")
	readyButton.icon = readyIcon

	countdownButton = CreateSecureActionButton("WoWDungeonAssistCountdownButton", dropdown, nil, 66, 26, "BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", -14, 10)
	countdownButton.tooltipTitle = "Countdown 10"
	countdownButton.tooltipLines = { "Left click: start pull timer." }
	countdownButton.tooltipAnchor = "ANCHOR_LEFT"
	countdownIcon = countdownButton:CreateTexture(nil, "ARTWORK")
	countdownIcon:SetAtlas("icon-clock", true)
	countdownIcon:SetVertexColor(classColor.r, classColor.g, classColor.b, 1)
	countdownIcon:SetSize(16, 16)
	countdownIcon:SetPoint("LEFT", 8, 0)
	countdownButton.icon = countdownIcon

	countdownText = countdownButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	countdownText:SetPoint("LEFT", countdownIcon, "RIGHT", 4, 0)
	countdownText:SetText("10")
	countdownText:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	TrackFontString(countdownText, 12)
	countdownText:SetShadowOffset(1, -1)
	countdownText:SetShadowColor(0, 0, 0, 0.9)

	moverOverlay = CreateFrame("Button", nil, anchor, "BackdropTemplate")
	moverOverlay:SetAllPoints(anchor)
	moverOverlay:SetFrameStrata("DIALOG")
	moverOverlay:RegisterForDrag("LeftButton")
	SetBackdropStyle(moverOverlay, 10)
	moverOverlay:SetBackdropColor(unpack(palette.moverBg))
	moverOverlay:SetBackdropBorderColor(unpack(palette.moverBorder))
	moverOverlay:SetScript("OnDragStart", function()
		if InCombatLockdown() then
			return
		end
		anchor:StartMoving()
	end)
	moverOverlay:SetScript("OnDragStop", function()
		anchor:StopMovingOrSizing()
		SavePosition()
	end)

	local moverText = moverOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	moverText:SetPoint("CENTER")
	moverText:SetText("Drag to move")
	moverText:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	TrackFontString(moverText, 12)
	moverText:SetShadowOffset(1, -1)
	moverText:SetShadowColor(0, 0, 0, 0.9)
	moverOverlay:Hide()

	RestorePosition()
	ApplyExpandedState()
end

addon:SetScript("OnEvent", function(_, event, ...)
	if event == "PLAYER_LOGIN" then
		EnsureDatabase()
		UpdateClassColor()
		currentRole = GetAssignedRole()
		RefreshPaletteFromDB()
		CreateUI()
		CreateOptionsPanel()
		RegisterOptionsPanel()
		RegisterSlashCommands()
		SetupEditModeCallbacks()
		ApplyConfiguredState()
	elseif event == "PLAYER_REGEN_ENABLED" then
		if pendingVisibilityUpdate then
			ApplyVisibilityDriver()
		end
		if pendingSecureUpdate then
			ApplySecureAttributesNow()
		end
	elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
		UpdateActionAvailability()
		UpdateMythicWidgets()
	elseif event == "PLAYER_ROLES_ASSIGNED" then
		ApplyConfiguredState()
	elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
		local unit = ...
		if unit == "player" then
			ApplyConfiguredState()
		end
	elseif event == "UNIT_AURA" then
		local unit = ...
		if not unit then
			return
		end
		if unit == "player" or unit:match("^party%d+$") or unit:match("^raid%d+$") then
			UpdateMythicWidgets()
		end
	elseif event == "CHALLENGE_MODE_START" or event == "CHALLENGE_MODE_COMPLETED" or event == "CHALLENGE_MODE_RESET" then
		UpdateMythicWidgets()
	end
end)

addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("PLAYER_REGEN_ENABLED")
addon:RegisterEvent("GROUP_ROSTER_UPDATE")
addon:RegisterEvent("PLAYER_TARGET_CHANGED")
addon:RegisterEvent("PLAYER_ENTERING_WORLD")
addon:RegisterEvent("PLAYER_ROLES_ASSIGNED")
addon:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
addon:RegisterEvent("UNIT_AURA")
addon:RegisterEvent("CHALLENGE_MODE_START")
addon:RegisterEvent("CHALLENGE_MODE_COMPLETED")
addon:RegisterEvent("CHALLENGE_MODE_RESET")
