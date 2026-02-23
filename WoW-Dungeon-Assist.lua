local addon = CreateFrame("Frame")

local DB_NAME = "WoWDungeonAssistDB"
local VISIBILITY_DRIVER = "[group] show; hide"

local defaults = {
	point = "TOP",
	relativePoint = "TOP",
	x = 0,
	y = -220,
	expanded = false,
}

local db
local anchor
local headerButton
local dropdown
local arrowLabel
local moverOverlay
local isEditMode = false
local forcedShow = false
local pendingVisibilityUpdate = false
local classColor = { r = 1, g = 0.82, b = 0 }
local markerConditionName = {
	[8] = "skull",
	[7] = "cross",
	[6] = "square",
	[5] = "moon",
	[4] = "triangle",
	[3] = "diamond",
	[2] = "circle",
	[1] = "star",
}

local function Round(value)
	if value >= 0 then
		return math.floor(value + 0.5)
	end

	return math.ceil(value - 0.5)
end

local function EnsureDatabase()
	if type(_G[DB_NAME]) ~= "table" then
		_G[DB_NAME] = {}
	end

	db = _G[DB_NAME]
	for key, value in pairs(defaults) do
		if db[key] == nil then
			db[key] = value
		end
	end
end

local function SavePosition()
	local point, _, relativePoint, x, y = anchor:GetPoint(1)
	if point and relativePoint then
		db.point = point
		db.relativePoint = relativePoint
		db.x = Round(x)
		db.y = Round(y)
	end
end

local function RestorePosition()
	anchor:ClearAllPoints()
	anchor:SetPoint(db.point, UIParent, db.relativePoint, db.x, db.y)
end

local function PrintMessage(text)
	print("|cff33aaffWoW Dungeon Assist:|r " .. text)
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
		classColor = { r = color.r, g = color.g, b = color.b }
	end
end

local function UpdateArrow()
	if dropdown:IsShown() then
		arrowLabel:SetText("^")
	else
		arrowLabel:SetText("v")
	end
end

local function ApplyExpandedState()
	if db.expanded then
		dropdown:Show()
	else
		dropdown:Hide()
	end

	UpdateArrow()
end

local function ApplyVisibilityDriver()
	if InCombatLockdown() then
		pendingVisibilityUpdate = true
		return
	end

	pendingVisibilityUpdate = false
	UnregisterStateDriver(anchor, "visibility")

	if isEditMode or forcedShow then
		anchor:Show()
	else
		RegisterStateDriver(anchor, "visibility", VISIBILITY_DRIVER)
	end
end

local function SetEditModeEnabled(enabled)
	isEditMode = enabled and true or false
	moverOverlay:SetShown(isEditMode)
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

local function ResetPosition()
	db.point = defaults.point
	db.relativePoint = defaults.relativePoint
	db.x = defaults.x
	db.y = defaults.y
	RestorePosition()
	SavePosition()
end

local function RegisterSlashCommands()
	SLASH_WOWDUNGEONASSIST1 = "/wda"
	SlashCmdList.WOWDUNGEONASSIST = function(msg)
		local command = (msg or ""):lower():match("^%s*(.-)%s*$")

		if command == "show" then
			forcedShow = true
			ApplyVisibilityDriver()
			PrintMessage("Forced show enabled. Use /wda auto to return to party-only visibility.")
		elseif command == "auto" or command == "hide" then
			forcedShow = false
			ApplyVisibilityDriver()
			PrintMessage("Party/raid visibility restored.")
		elseif command == "reset" then
			ResetPosition()
			forcedShow = true
			ApplyVisibilityDriver()
			PrintMessage("Position reset and forced show enabled.")
		elseif command == "where" then
			PrintMessage(string.format("Position: %s %d, %d", db.point, db.x, db.y))
		else
			PrintMessage("Commands: /wda show, /wda auto, /wda reset, /wda where")
		end
	end
end

local function CreateSecureActionButton(parent, label, width, height, point, relativeTo, relativePoint, x, y)
	local button = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate,BackdropTemplate")
	button:SetSize(width, height)
	button:SetPoint(point, relativeTo, relativePoint, x, y)
	button:RegisterForClicks("AnyDown", "AnyUp")
	button:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	button:SetBackdropColor(0.02, 0.02, 0.02, 0.95)
	button:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
	button:SetScript("OnEnter", function()
		button:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
	end)
	button:SetScript("OnLeave", function()
		button:SetBackdropColor(0.02, 0.02, 0.02, 0.95)
	end)

	if label and label ~= "" then
		local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		text:SetPoint("CENTER")
		text:SetText(label)
		text:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	end

	return button
end

local function CreateMarkerButton(parent, markerIndex, point, relativeTo, relativePoint, x, y)
	local button = CreateSecureActionButton(parent, nil, 24, 24, point, relativeTo, relativePoint, x, y)
	local markerName = markerConditionName[markerIndex] or tostring(markerIndex)
	button:SetAttribute("type", "raidtarget")
	button:SetAttribute("unit", "target")
	button:SetAttribute("action", "set")
	button:SetAttribute("marker", markerIndex)
	button:SetAttribute("type2", "macro")
	button:SetAttribute("macrotext2", "/tm [@target,exists,raidtarget:" .. markerName .. "] 0")

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetPoint("TOPLEFT", 2, -2)
	icon:SetPoint("BOTTOMRIGHT", -2, 2)
	icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. markerIndex)

	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(_G["RAID_TARGET_" .. markerIndex] or ("Marker " .. markerIndex), classColor.r, classColor.g, classColor.b)
		GameTooltip:AddLine("Left click: set on target", 0.8, 0.8, 0.8)
		GameTooltip:AddLine("Right click: clear this marker from target", 0.8, 0.8, 0.8)
		GameTooltip:Show()
	end)

	button:SetScript("OnLeave", function()
		GameTooltip_Hide()
	end)

	return button
end

local function CreateUI()
	anchor = CreateFrame("Frame", "WoWDungeonAssistRaidControlAnchor", UIParent, "SecureHandlerStateTemplate")
	anchor:SetSize(140, 24)
	anchor:SetFrameStrata("MEDIUM")
	anchor:SetMovable(true)
	anchor:SetClampedToScreen(true)

	headerButton = CreateFrame("Button", nil, anchor, "BackdropTemplate")
	headerButton:SetAllPoints(anchor)
	headerButton:RegisterForClicks("LeftButtonUp")
	headerButton:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	headerButton:SetBackdropColor(0.06, 0.06, 0.06, 0.9)
	headerButton:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
	headerButton:SetScript("OnClick", function()
		if InCombatLockdown() then
			return
		end

		dropdown:SetShown(not dropdown:IsShown())
		db.expanded = dropdown:IsShown()
		UpdateArrow()
	end)

	local title = headerButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("CENTER", -5, 0)
	title:SetText("Dungeon Assist")
	title:SetTextColor(classColor.r, classColor.g, classColor.b, 1)

	arrowLabel = headerButton:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	arrowLabel:SetPoint("RIGHT", -8, 0)
	arrowLabel:SetTextColor(classColor.r, classColor.g, classColor.b, 1)

	dropdown = CreateFrame("Frame", nil, anchor, "BackdropTemplate")
	dropdown:SetPoint("TOP", anchor, "BOTTOM", 0, -2)
	dropdown:SetSize(170, 170)
	dropdown:SetFrameStrata("MEDIUM")
	dropdown:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 10,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	dropdown:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
	dropdown:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)

	headerButton:SetScript("OnEnter", function()
		headerButton:SetBackdropColor(0.11, 0.11, 0.11, 0.95)
	end)
	headerButton:SetScript("OnLeave", function()
		headerButton:SetBackdropColor(0.06, 0.06, 0.06, 0.9)
	end)

	local clearButton = CreateSecureActionButton(dropdown, "Clear Markers", 150, 22, "TOP", dropdown, "TOP", 0, -10)
	clearButton:SetAttribute("type", "raidtarget")
	clearButton:SetAttribute("action", "clear-all")

	local markersLabel = dropdown:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	markersLabel:SetPoint("TOPLEFT", 12, -42)
	markersLabel:SetText("Target Markers")
	markersLabel:SetTextColor(classColor.r, classColor.g, classColor.b, 1)

	local markerHolder = CreateFrame("Frame", nil, dropdown)
	markerHolder:SetPoint("TOPLEFT", 10, -56)
	markerHolder:SetSize(150, 52)

	local markerOrder = { 8, 7, 6, 5, 4, 3, 2, 1 }
	for index, markerID in ipairs(markerOrder) do
		local col = (index - 1) % 4
		local row = math.floor((index - 1) / 4)
		CreateMarkerButton(markerHolder, markerID, "TOPLEFT", markerHolder, "TOPLEFT", col * 30, -(row * 28))
	end

	local readyButton = CreateSecureActionButton(dropdown, nil, 64, 26, "BOTTOMLEFT", dropdown, "BOTTOMLEFT", 14, 10)
	readyButton:SetAttribute("type", "macro")
	readyButton:SetAttribute("macrotext", "/readycheck")
	local readyIcon = readyButton:CreateTexture(nil, "ARTWORK")
	readyIcon:SetAtlas("common-icon-checkmark", true)
	readyIcon:SetVertexColor(classColor.r, classColor.g, classColor.b, 1)
	readyIcon:SetSize(18, 18)
	readyIcon:SetPoint("CENTER")
	readyButton:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Ready Check", classColor.r, classColor.g, classColor.b)
		GameTooltip:Show()
	end)
	readyButton:HookScript("OnLeave", function()
		GameTooltip_Hide()
	end)

	local countdownButton = CreateSecureActionButton(dropdown, nil, 64, 26, "BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", -14, 10)
	countdownButton:SetAttribute("type", "macro")
	countdownButton:SetAttribute("macrotext", "/countdown 10")
	local countdownIcon = countdownButton:CreateTexture(nil, "ARTWORK")
	countdownIcon:SetAtlas("icon-clock", true)
	countdownIcon:SetVertexColor(classColor.r, classColor.g, classColor.b, 1)
	countdownIcon:SetSize(16, 16)
	countdownIcon:SetPoint("LEFT", 8, 0)
	local countdownText = countdownButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	countdownText:SetPoint("LEFT", countdownIcon, "RIGHT", 4, 0)
	countdownText:SetText("10")
	countdownText:SetTextColor(classColor.r, classColor.g, classColor.b, 1)
	countdownButton:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetText("Countdown 10", classColor.r, classColor.g, classColor.b)
		GameTooltip:Show()
	end)
	countdownButton:HookScript("OnLeave", function()
		GameTooltip_Hide()
	end)

	moverOverlay = CreateFrame("Button", nil, anchor, "BackdropTemplate")
	moverOverlay:SetAllPoints(anchor)
	moverOverlay:SetFrameStrata("DIALOG")
	moverOverlay:RegisterForDrag("LeftButton")
	moverOverlay:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 10,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	moverOverlay:SetBackdropColor(0.12, 0.35, 0.6, 0.45)
	moverOverlay:SetBackdropBorderColor(0.25, 0.65, 1, 1)
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
	moverOverlay:Hide()

	RestorePosition()
	ApplyExpandedState()
end

addon:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_LOGIN" then
		EnsureDatabase()
		UpdateClassColor()
		CreateUI()
		RegisterSlashCommands()
		SetupEditModeCallbacks()
		ApplyVisibilityDriver()
	elseif event == "PLAYER_REGEN_ENABLED" then
		if pendingVisibilityUpdate then
			ApplyVisibilityDriver()
		end
	end
end)

addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("PLAYER_REGEN_ENABLED")
