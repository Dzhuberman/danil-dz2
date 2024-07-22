local roles = {
	ADMIN = "admin",
	MEMBER = "member",
}

local cityMayor = {
	name = "City Mayor",
	id = "city_mayor",
	members = {},
}

local factions = {
	cityMayor,
}

local invitesCooldown = {}

--===========================Utils===========================

local function getFactionById(factionId)
	for i = 1, #factions do
        if factionId == factions[i].id then
			return factions[i]
		end
    end

    return nil
end

local function getFactionByPlayer(playerId)
	for i = 1, #factions do
		if factions[i].members[playerId] then
			return factions[i]
		end
	end

	return nil
end

--========================Faction Management========================

local function promoteToLeader(player, playerId, faction)
	faction.members[playerId].role = roles.ADMIN
	triggerClientEvent(player, "onPlayerGetFaction", resourceRoot, faction, faction.members[playerId])

	outputChatBox(
		faction.members[playerId].name.." стал лидером фракции "..faction.name,
		player,
		0, 255, 0
	)
end

local function setFactionLeader(player, command, playerIdArg, factionIdArg)
	local playerId = tonumber(playerIdArg)
	local factionId = tostring(factionIdArg)
	local targetFaction = getFactionById(factionId)
	local currentFaction = getFactionByPlayer(playerId)

	if not GetPlayerById(playerId) then
		outputChatBox("Такого ID не существует", player, 255, 0, 0)
		return
	end
	if not targetFaction then
		outputChatBox("Такой фракции не существует", player, 255, 0, 0)
		return
	end
	if not currentFaction then
		outputChatBox("Игрок не является участником фракции", player, 255, 0, 0)
		return
	end
	if targetFaction ~= currentFaction then
		outputChatBox("Игрок в другой фракции", player, 255, 0, 0)
		return
	end
	if targetFaction.members[playerId].role == roles.ADMIN then
		outputChatBox("Игрок уже является лидером данной фракции", player, 255, 0, 0)
		return
	end

	promoteToLeader(player, playerId, targetFaction)
end

local function addMember(player, playerId, faction)
	faction.members[playerId] = { name = getPlayerName(player), role = roles.MEMBER }
	triggerClientEvent(player, "onPlayerGetFaction", resourceRoot, faction, faction.members[playerId])

	outputChatBox(
		getPlayerName(player).." вступил во фракцию  "..faction.name,
		player,
		0, 255, 0
	)
end

local function deleteMember(player, playerId, faction)
	outputChatBox(faction.members[playerId].name.." вышел из фракции  "..faction.name, player, 0, 255, 0)
	faction.members[playerId] = nil

	triggerClientEvent(player, "onPlayerGetFaction", resourceRoot, nil, nil)
end

local function setFaction(player, command, playerIdArg, factionIdArg)
	local playerId = tonumber(playerIdArg)
	local factionId = tostring(factionIdArg)
	local targetFaction = getFactionById(factionId)
	local currentFaction = getFactionByPlayer(playerId)

	if not GetPlayerById(playerId) then
		outputChatBox("Такого ID не существует", player, 255, 0, 0)
		return
	end
	if factionIdArg == nil then
		if currentFaction then
			deleteMember(player, playerId, currentFaction)
			return
		end
	end
	if not targetFaction then
		outputChatBox("Такой фракции не существует", player, 255, 0, 0)
		return
	end
	if targetFaction == currentFaction then
		outputChatBox("Игрок уже является участником данной фракции", player, 255, 0, 0)
		return
	end

	addMember(player, playerId, targetFaction)
end

local function sendFactionMessage(player, command, ...)
	local playerId = GetPlayerId(player)
	local faction = getFactionByPlayer(playerId)
	if not faction then
		outputChatBox("Вы не состоите ни в одной фракции", player, 255, 0, 0)
	end

	local fullMessage = table.concat({...}, " ")

	for k, v in pairs(faction.members) do
		local recipient = GetPlayerById(k)
		outputChatBox(v.name..": "..fullMessage, recipient, 160, 43, 255)
	end
end

addCommandHandler("set_player_faction_leader", setFactionLeader)
addCommandHandler("set_player_faction", setFaction)
addCommandHandler("f", sendFactionMessage)

--===========================Custom events===========================

local function getFaction(player)
	local playerId = GetPlayerId(player)
	local faction = getFactionByPlayer(playerId)
	if not faction then return end
	local member = faction.members[playerId]

	triggerClientEvent(player, "onPlayerGetFaction", resourceRoot, faction, member)
end

addEvent("onPlayerRequestFaction", true)
addEventHandler("onPlayerRequestFaction", resourceRoot, getFaction)

local function startInviteCooldown(time, playerId)
	invitesCooldown[playerId] = true
	setTimer(function ()
		invitesCooldown[playerId] = nil
	end, time, 1)
end

local function inviteMember(playerId, factionId, adminId)
	if type(playerId) ~= "number" then return end
	local player = GetPlayerById(playerId)
	if not player then return end

	local faction = getFactionById(factionId)
	if not faction then return end

	if type(adminId) ~= "number" then return end
	local admin = faction.members[adminId]
	if not admin then return end
	if admin.role ~= roles.ADMIN then return end

	if getFactionByPlayer(playerId) then
		outputChatBox("Данный игрок уже является членом фракции", GetPlayerById(adminId), 255, 0, 0)
		return
	end

	if invitesCooldown[playerId] then
		outputChatBox("Вы не можете приглашать более одного раза в минуту", GetPlayerById(adminId), 255, 0, 0)
		return
	end

	outputChatBox("Приглашение во фракцию "..faction.name.." отправлено", GetPlayerById(adminId), 0, 255, 0)
	startInviteCooldown(60000, playerId)
	triggerClientEvent(player, "onInviteRecieve", resourceRoot, faction, admin.name)
end

addEvent("onAdminInviteMember", true)
addEventHandler("onAdminInviteMember", resourceRoot, inviteMember)

local function acceptInvite(playerId, factionId)
	if type(playerId) ~= "number" then return end
	local player = GetPlayerById(playerId)
	if not player then return end

	local faction = getFactionById(factionId)
	if not faction then return end

	addMember(player, playerId, faction)
end

addEvent("onPlayerAcceptInvite", true)
addEventHandler("onPlayerAcceptInvite", resourceRoot, acceptInvite)

local function adminDeleteMember(playerId, factionId)
	local faction = getFactionById(factionId)
	if not faction then return end

	if type(playerId) ~= "number" then return end
	local player = GetPlayerById(playerId)
	if not player then return end

	local currentFaction = getFactionByPlayer(playerId)
	if not currentFaction then return end

	deleteMember(player, playerId, faction)
end

addEvent("onAdminDeleteMember", true)
addEventHandler("onAdminDeleteMember", resourceRoot, adminDeleteMember)