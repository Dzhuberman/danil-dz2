local player_id = 0
local player_ids = {}
local screenWidth, screenHeight = guiGetScreenSize()

local faction = nil
local member = {}
local roles = {
	ADMIN = "admin",
	MEMBER = "member",
}

local factionWindow = nil
local isWindowOpened = false

--===========================dxDraw Section===========================

local function drawIdAbovePlayers()
	for k, v in ipairs(player_ids) do
		local x, y, z = getPedBonePosition(v, 8);
		local sX, sY = getScreenFromWorldPosition(x, y, z);
		if sX then
			dxDrawText("[   "..k.."   ]", sX, sY - 160, sX, sY, tocolor(255, 255, 255, 255), 1, "pricedown", "center", "center")
		end
	end
end

local function drawIdRect()
	local rectPos = { x = screenWidth / 1.3, y = screenHeight / 1.2 }
	local rectSize = { x = screenWidth / 6, y = screenHeight / 10 }
	dxDrawRectangle(rectPos.x, rectPos.y, rectSize.x, rectSize.y, tocolor(255, 255, 255, 100))
	dxDrawText(
		"Id: "..tostring(player_id),
		rectPos.x,
		rectPos.y,
		rectPos.x + rectSize.x,
		rectPos.y + rectSize.y,
		tocolor(0, 0, 0, 255),
		2,
		"pricedown",
		"center",
		"center"
	)
end

local function renderId()
	drawIdRect()
	drawIdAbovePlayers()
end

--===========================GUI Section===========================

local function alert( message )
    local alert_window = guiCreateWindow( 0.4, 0.45, 0.2, 0.1, "Предупреждение", true )
    local message_label = guiCreateLabel( 0, 0.3, 1, 0.3, message, true, alert_window )
    guiLabelSetHorizontalAlign( message_label, "center" )

    local close_button = guiCreateButton( 0.2, 0.6, 0.6, 0.3, "Закрыть", true, alert_window )
    addEventHandler( "onClientGUIClick", close_button, function ()
        destroyElement( alert_window )
    end, false )
end

local function drawFactionMenu()
	destroyElement(factionWindow)
	triggerServerEvent("onPlayerRequestFaction", resourceRoot, localPlayer)
	if not isWindowOpened then return end

	factionWindow = guiCreateWindow(0.25, 0.2, 0.5, 0.4, "Фракции", true)
	local tabPanel = guiCreateTabPanel(0, 0.1, 1, 1, true, factionWindow)
	local tabMembers = guiCreateTab("Участники", tabPanel)
	local tabCityManagement = guiCreateTab("Управление городом", tabPanel)
	local scrollPaneMembers = guiCreateScrollPane(0, 0.1, 1, 0.9, true, tabMembers)

	-- Members tab
	for _, v in ipairs(getElementChildren(scrollPaneMembers)) do
		destroyElement(v)
	end

	if faction then
		local i = 0
		for k, v in pairs(faction.members) do
			local memberLabel = guiCreateLabel(0, i * 0.1, 0.5, 0.1, "id: ["..k.."] name: "..v.name, true, scrollPaneMembers)
			if member.role == roles.ADMIN then
				local deleteMemberButton = guiCreateButton(0.7, i * 0.1, 0.2, 0.1, "Уволить", true, scrollPaneMembers)
				addEventHandler("onClientGUIClick", deleteMemberButton, function ()
					destroyElement(memberLabel)
					destroyElement(deleteMemberButton)
					triggerServerEvent("onAdminDeleteMember", resourceRoot, k, faction.id)
				end, false)
			end
			i = i + 1
		end
	else
		guiCreateLabel(0.02, 0.04, 0.94, 0.92, "Вы не состоите ни в одной фракции", true, tabMembers)
	end

	if member.role == roles.ADMIN then
		guiSetEnabled(tabCityManagement, true)
		local inviteButton = guiCreateButton(0, 0, 0.3, 0.1, "Пригласить", true, tabMembers)
		local inviteEdit = guiCreateEdit(0.4, 0, 0.3, 0.1, "", true, tabMembers)
		addEventHandler("onClientGUIClick", inviteButton, function ()
			local playerId = tonumber(guiGetText(inviteEdit))
			if not playerId then return end

			triggerServerEvent("onAdminInviteMember", resourceRoot, playerId, faction.id, player_id)
		end, false)
	else
		guiSetEnabled(tabCityManagement, false)
	end

	-- City Management tab
	local city_name_label = guiCreateLabel( 0.02, 0, 0.2, 0.1, faction.name, true, tabCityManagement )
	local city_name_edit = guiCreateEdit(0.4, 0, 0.3, 0.1, "", true, tabCityManagement)
	local city_name_button = guiCreateButton(0.7, 0, 0.2, 0.1, "Изменить имя", true, tabCityManagement)
	addEventHandler("onClientGUIClick", city_name_button, function ()
		local new_city_name = guiGetText( city_name_edit )
		triggerServerEvent( "onCityNameChange", resourceRoot, new_city_name, player_id, faction.id )

		if faction.cooldowns.name then return end

		destroyElement( city_name_label )
		city_name_label = guiCreateLabel( 0.02, 0, 0.2, 0.1, new_city_name, true, tabCityManagement )
	end, false)

	guiCreateLabel( 0.02, 0.8, 0.2, 0.1, "Свободные очки: ", true, tabCityManagement )
	local points_label = guiCreateLabel( 0.2, 0.8, 0.05, 0.1, tonumber( faction.points ), true, tabCityManagement )

	local y_pos = {}

	local i = 1
	for key, tax in pairs( faction.taxes ) do
		guiCreateLabel( 0.02, i * 0.1, 0.94, 0.92, tax.name, true, tabCityManagement )

		local points_counter = guiCreateLabel( 0.5, i * 0.1, 0.05, 0.1, tostring( faction.taxes[key].tax ), true, tabCityManagement )
		guiLabelSetHorizontalAlign( points_counter, "center" )
		guiLabelSetVerticalAlign( points_counter, "center" )

		local minus_button = guiCreateButton( 0.4, i * 0.1, 0.05, 0.1, "-", true, tabCityManagement )
		y_pos[minus_button] = i * 0.1
		addEventHandler( "onClientGUIClick", minus_button, function ()
			if faction.taxes[key].tax <= 0 then return end

			destroyElement( points_counter )
			destroyElement( points_label )
			faction.taxes[key].tax = faction.taxes[key].tax - 1
			faction.points = faction.points + 1

			points_counter = guiCreateLabel( 0.5, y_pos[minus_button], 0.05, 0.1, tostring( faction.taxes[key].tax ), true, tabCityManagement )
			guiLabelSetHorizontalAlign( points_counter, "center" )
			guiLabelSetVerticalAlign( points_counter, "center" )
			points_label = guiCreateLabel( 0.2, 0.8, 0.05, 0.1, tonumber( faction.points ), true, tabCityManagement )
		end, false )

		local plus_button = guiCreateButton( 0.6, i * 0.1, 0.05, 0.1, "+", true, tabCityManagement )
		y_pos[plus_button] = i * 0.1
		addEventHandler( "onClientGUIClick", plus_button, function ()
			if faction.points <= 0 then return end

			destroyElement( points_counter )
			destroyElement( points_label )
			faction.taxes[key].tax = faction.taxes[key].tax + 1
			faction.points = faction.points - 1

			points_counter = guiCreateLabel( 0.5, y_pos[plus_button], 0.05, 0.1, tostring( faction.taxes[key].tax ), true, tabCityManagement )
			guiLabelSetHorizontalAlign( points_counter, "center" )
			guiLabelSetVerticalAlign( points_counter, "center" )
			points_label = guiCreateLabel( 0.2, 0.8, 0.05, 0.1, tonumber( faction.points ), true, tabCityManagement )
		end, false )

		i = i + 1
	end

	local accept_button = guiCreateButton( 0.5, 0.8, 0.2, 0.1, "Применить", true, tabCityManagement )
	addEventHandler( "onClientGUIClick", accept_button, function ()
		if faction.points ~= 0 then
			alert( "Вы не распределили очки" )
			return
		end

		triggerServerEvent( "onAcceptTaxes", resourceRoot, player_id, faction.id, faction.taxes )
	end, false )

	local reset_button = guiCreateButton( 0.75, 0.8, 0.2, 0.1, "Сбросить", true, tabCityManagement )
	addEventHandler( "onClientGUIClick", reset_button, function ()
		triggerServerEvent( "onResetTaxes", resourceRoot, player_id, faction.id )
	end, false )
end

local function showFactionMenu()
	isWindowOpened = not isWindowOpened
	showCursor(isWindowOpened)
	drawFactionMenu()
end

local function handleFactionStart()
	triggerServerEvent("onPlayerRequestId", resourceRoot, localPlayer)

	bindKey("p", "down", showFactionMenu)
	triggerServerEvent("onPlayerRequestFaction", resourceRoot, localPlayer)
end

addEventHandler("onClientResourceStart", resourceRoot, handleFactionStart)
addEventHandler("onClientRender", root, renderId)

--===========================Custom events===========================

local function setId(id)
	player_id = id
end

addEvent("onPlayerResponseId", true)
addEventHandler("onPlayerResponseId", resourceRoot, setId)

local function getAllIds(ids)
	player_ids = ids
end

addEvent("onPlayerGetIds", true)
addEventHandler("onPlayerGetIds", resourceRoot, getAllIds)

local function setMember(factionData, memberData)
	faction = factionData
	member = memberData
end

addEvent("onPlayerGetFaction", true)
addEventHandler("onPlayerGetFaction", resourceRoot, setMember)

local function openInvite(invitedFaction, inviteFromName)
	if faction then return end

	local inviteWindow = guiCreateWindow(0.375, 0.4, 0.25, 0.2, "Приглашение", true)
	local inviteLabel = guiCreateLabel(0, 0.3, 1, 0.2, inviteFromName.." приглашает вас вступить в "..invitedFaction.name, true, inviteWindow)
	guiLabelSetHorizontalAlign(inviteLabel, "center")
	local acceptButton = guiCreateButton(0.2, 0.7, 0.2, 0.1, "Принять", true, inviteWindow)
	local cancelButton = guiCreateButton(0.6, 0.7, 0.2, 0.1, "Отказаться", true, inviteWindow)

	showCursor(true)

	addEventHandler("onClientGUIClick", acceptButton, function ()
		triggerServerEvent("onPlayerAcceptInvite", resourceRoot, player_id, invitedFaction.id)

		destroyElement(inviteWindow)
		showCursor(false)
	end, false)

	addEventHandler("onClientGUIClick", cancelButton, function ()
		destroyElement(inviteWindow)
		showCursor(false)
	end, false)
end

addEvent("onInviteRecieve", true)
addEventHandler("onInviteRecieve", resourceRoot, openInvite)

local function cooldown_alert( message )
	alert( message )
end

addEvent( "onCooldownAlert", true )
addEventHandler( "onCooldownAlert", resourceRoot, cooldown_alert )