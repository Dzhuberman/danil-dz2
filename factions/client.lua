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

local function drawFactionMenu()
	destroyElement(factionWindow)
	triggerServerEvent("onPlayerRequestFaction", resourceRoot, localPlayer)
	if not isWindowOpened then return end

	factionWindow = guiCreateWindow(0.25, 0.2, 0.5, 0.4, "Фракции", true)
	local tabPanel = guiCreateTabPanel(0, 0.1, 1, 1, true, factionWindow)
	local tabMembers = guiCreateTab("Участники", tabPanel)
	local tabCityManagement = guiCreateTab("Управление городом", tabPanel)
	local scrollPaneMembers = guiCreateScrollPane(0, 0.1, 1, 0.9, true, tabMembers)

	guiCreateLabel(0.02, 0.04, 0.94, 0.92, "Coming Soon", true, tabCityManagement)

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