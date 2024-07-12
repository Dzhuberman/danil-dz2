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

--===========================Utils===========================

local function isFactionIdExists(factionId)
	for i = 1, #factions do
        if factionId == factions[i].id then
			return true
		end
    end

    return false
end

local function getFactionById(factionId)
	for i = 1, #factions do
        if factionId == factions[i].id then
			return factions[i]
		end
    end

    return nil
end

local function getFactionByPlayer(playerName)
	for i = 1, #factions do
		if factions[i].members[playerName] then
			return factions[i]
		end
	end

	return nil
end

--========================Faction Management========================

local function promoteToLeader(player, faction)
	if not faction then return end

	faction.members[getPlayerName(player)].role = roles.ADMIN
	triggerClientEvent(player, "onPlayerGetFaction", resourceRoot, faction, faction.members[getPlayerName(player)])

	outputChatBox(
		getPlayerName(player).." Is Now Admin Of "..faction.name.." Faction",
		player,
		0, 255, 0
	)
end

local function addMember(player, faction)
	if not faction then return end

	local playerId = GetPlayerId(player)
	if not playerId then return end

	faction.members[getPlayerName(player)] = { id = playerId, role = roles.MEMBER }
	triggerClientEvent(player, "onPlayerGetFaction", resourceRoot, faction, faction.members[getPlayerName(player)])

	outputChatBox(
		getPlayerName(player).." Is Part Of "..faction.name.." Faction",
		player,
		0, 255, 0
	)
end

local function setFactionLeader(player, command, playerIdArg, factionIdArg)
	local playerId = tonumber(playerIdArg)
	local factionId = tostring(factionIdArg)
	local targetPlayer = GetPlayerById(playerId)
	local faction = getFactionByPlayer(getPlayerName(targetPlayer))

	if not IsIdExists(playerId) then
		outputChatBox("Invalid Player ID", player, 255, 0, 0)
		return
	end
	if not isFactionIdExists(factionId) then
		outputChatBox("Invalid Faction ID", player, 255, 0, 0)
		return
	end
	if not faction then
		outputChatBox("Player Is Not In Any Faction", player, 255, 0, 0)
		return
	end
	if faction ~= getFactionById(factionId) then
		outputChatBox("Player Is In Different Faction", player, 255, 0, 0)
		return
	end
	if faction.members[getPlayerName(targetPlayer)].role == roles.ADMIN then
		outputChatBox("Player Is Already a Leader", player, 255, 0, 0)
		return
	end

	promoteToLeader(targetPlayer, faction)
end

local function setFaction(player, command, playerIdArg, factionIdArg)
	local playerId = tonumber(playerIdArg)
	local factionId = tostring(factionIdArg)
	local currentFaction = getFactionByPlayer(getPlayerName(player))

	if not IsIdExists(playerId) then
		outputChatBox("Invalid Player ID", player, 255, 0, 0)
		return
	end
	if factionIdArg == nil then
		if currentFaction then
			currentFaction.members[getPlayerName(player)] = nil
			return
		end
	end
	if not isFactionIdExists(factionId) then
		outputChatBox("Invalid Faction ID", player, 255, 0, 0)
		return
	end
	if faction == getFactionById(factionId) then
		outputChatBox("Player Already in This Faction", player, 255, 0, 0)
		return
	end

	local faction = getFactionById(factionId)
	local targetPlayer = GetPlayerById(playerId)
	addMember(targetPlayer, faction)
end

local function sendFactionMessage(player, command, ...)
	local faction = getFactionByPlayer(getPlayerName(player))
	if not faction then
		outputChatBox("Вы не состоите ни в одной фракции", player, 255, 0, 0)
	end

	local fullMessage = table.concat({...}, " ")

	for k, v in pairs(faction.members) do
		local recipient = GetPlayerById(v.id)
		outputChatBox(getPlayerName(player)..": "..fullMessage, recipient, 160, 43, 255)
	end
end

addCommandHandler("set_player_faction_leader", setFactionLeader)
addCommandHandler("set_player_faction", setFaction)
addCommandHandler("f", sendFactionMessage)

--===========================Custom events===========================

local function getFaction(player)
	local faction = getFactionByPlayer(getPlayerName(player))
	if not faction then return end
	local member = faction.members[getPlayerName(player)]

	triggerClientEvent(player, "onPlayerGetFaction", resourceRoot, faction, member)
end

addEvent("onPlayerRequestFaction", true)
addEventHandler("onPlayerRequestFaction", resourceRoot, getFaction)

local function inviteMember(playerId, factionId, inviteFrom)
	if not IsIdExists(playerId) then return end
	local faction = getFactionById(factionId)
	if not faction then return end
	if type(inviteFrom) ~= "string" then return end

	triggerClientEvent(GetPlayerById(playerId), "onInviteRecieve", resourceRoot, faction, inviteFrom)
end

addEvent("onAdminInviteMember", true)
addEventHandler("onAdminInviteMember", resourceRoot, inviteMember)

local function acceptInvite(player, factionId)
	if not player then return end
	local faction = getFactionById(factionId)
	if not faction then return end

	addMember(player, faction)
end

addEvent("onPlayerAcceptInvite", true)
addEventHandler("onPlayerAcceptInvite", resourceRoot, acceptInvite)

local function deleteMember(playerName, factionId)
	local faction = getFactionById(factionId)
	if not faction then return end
	if type(playerName) ~= "string" then return end

	faction.members[playerName] = nil
end

addEvent("onAdminDeleteMember", true)
addEventHandler("onAdminDeleteMember", resourceRoot, deleteMember)