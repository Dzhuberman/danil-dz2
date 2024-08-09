local DB

local players = {}

local roles = {
	ADMIN = "admin",
	MEMBER = "member",
}

local cityMayor = {
	name = "City Mayor",
	id = "city_mayor",
	members = {},
	taxes = {
		business_tax = { name = "Налог на прибыль с бизнесов", tax = 5 },
		worker_tax   = { name = "Налог на доход рабочих"	 , tax = 5 },
		faction_tax  = { name = "Налог на доход фракций"	 , tax = 5 },
		buy_veh_tax  = { name = "Налог на покупку ТС"		 , tax = 5 },
		sell_veh_tax = { name = "Налог на продажу ТС"		 , tax = 5 },
	},
	points = 0,
	cooldowns = { name = false, accept = false, reset = false }
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

	local player_status = getElementData( player, "player_status" )

	if player_status ~= 1 then
		outputChatBox( "Вы не имеете доступа к данной команде", player, 255, 0, 0 )
		return
	end

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

	local player_status = getElementData( player, "player_status" )

	if player_status ~= 1 then
		outputChatBox( "Вы не имеете доступа к данной команде", player, 255, 0, 0 )
		return
	end

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
	local faction = getFactionByPlayer( players[ player ]:GetID(  ) )
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

local function load_faction_data( faction_id )
	local faction = getFactionById( faction_id )

	local data = DB:query( "SELECT * FROM city_mayor" )

	for _, v in pairs( data ) do
		faction.name = v.name
		faction.taxes.business_tax.tax = v.business_tax
		faction.taxes.worker_tax.tax   = v.worker_tax
		faction.taxes.faction_tax.tax  = v.faction_tax
		faction.taxes.buy_veh_tax.tax  = v.buy_veh_tax
		faction.taxes.sell_veh_tax.tax = v.sell_veh_tax
	end
end

local function start_resource()
	loadstring( exports.interfacer:extend( "SharedPlayer" ) )(  )
	loadstring( exports.interfacer:extend( "SDB" ) )(  )
	DB = Connection.new( "Test", "127.0.0.1", "root", "13371337" )
	DB:connect(  )

	load_faction_data( "city_mayor" )
end

addEventHandler( "onResourceStart", resourceRoot, start_resource )

--===========================Custom events===========================

local function getId(  )
	local player_obj = Player.new( client )
	players[ client ] = player_obj
	triggerClientEvent( client, "onPlayerResponseId", resourceRoot, player_obj:GetID(  ) )
	triggerClientEvent("onPlayerGetIds", resourceRoot, ID_TABLE)
end

addEvent("onPlayerRequestId", true)
addEventHandler("onPlayerRequestId", resourceRoot, getId)

local function getFaction(  )
	local faction = getFactionByPlayer( players[ client ]:GetID(  ) )
	if not faction then return end
	local member = faction.members[ players[ client ]:GetID(  ) ]

	triggerClientEvent(client, "onPlayerGetFaction", resourceRoot, faction, member)
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

local function save_faction_data( faction_id )
	local faction = getFactionById( faction_id )

	DB:query(
		"UPDATE city_mayor SET name = ?, business_tax = ?, worker_tax = ?, faction_tax = ?, buy_veh_tax = ?, sell_veh_tax = ?",
		faction.name,
		faction.taxes.business_tax.tax,
		faction.taxes.worker_tax.tax,
		faction.taxes.faction_tax.tax,
		faction.taxes.buy_veh_tax.tax,
		faction.taxes.sell_veh_tax.tax
	)
end

local function accept_taxes( playerId, factionId, taxes )
	local faction = getFactionById( factionId )
	if not faction then return end

	if type( playerId ) ~= "number" then return end
	local player = GetPlayerById( playerId )
	if not player then return end

	if not taxes then return end
	if type( taxes ) ~= "table" then return end
	local sum = 0
	for _, v in pairs( taxes ) do
		sum = sum + v.tax
	end
	if sum ~= 25 then return end

	if faction.cooldowns.accept then
		triggerClientEvent( player, "onCooldownAlert", resourceRoot, "Изменения применимы раз в 24 часа" )
		return
	end

	faction.taxes = taxes
	save_faction_data( faction.id )

	triggerClientEvent( player, "onPlayerGetFaction", resourceRoot, faction, faction.members[ playerId ] )

	faction.cooldowns.accept = true
	setTimer(function(  )
		faction.cooldowns.accept = false
	end, 86400000, 1)
end

addEvent( "onAcceptTaxes", true )
addEventHandler( "onAcceptTaxes", resourceRoot, accept_taxes )

local function reset_taxes( playerId, factionId )
	local faction = getFactionById( factionId )
	if not faction then return end

	if type( playerId ) ~= "number" then return end
	local player = GetPlayerById( playerId )
	if not player then return end

	if faction.cooldowns.reset then
		triggerClientEvent( player, "onCooldownAlert", resourceRoot, "Сбрасывать можно раз в 24 часа" )
		return
	end

	faction.taxes = {
		business_tax = { name = "Налог на прибыль с бизнесов", tax = 5 },
		worker_tax   = { name = "Налог на доход рабочих"	 , tax = 5 },
		faction_tax  = { name = "Налог на доход фракций"	 , tax = 5 },
		buy_veh_tax  = { name = "Налог на покупку ТС"		 , tax = 5 },
		sell_veh_tax = { name = "Налог на продажу ТС"		 , tax = 5 },
	}
	faction.points = 0

	save_faction_data( faction.id )

	triggerClientEvent( player, "onPlayerGetFaction", resourceRoot, faction, faction.members[ playerId ] )

	faction.cooldowns.reset = true
	setTimer(function(  )
		faction.cooldowns.reset = false
	end, 86400000, 1)
end

addEvent( "onResetTaxes", true )
addEventHandler( "onResetTaxes", resourceRoot, reset_taxes )

local function change_city_name( new_name, player_id, faction_id )
	local faction = getFactionById( faction_id )
	if not faction then return end

	if type( player_id ) ~= "number" then return end
	local player = GetPlayerById( player_id )
	if not player then return end

	if type( new_name ) ~= "string" then return end

	if faction.cooldowns.name then
		triggerClientEvent( player, "onCooldownAlert", resourceRoot, "Изменять имя города можно раз в 24 часа" )
		triggerClientEvent( player, "onPlayerGetFaction", resourceRoot, faction, faction.members[ playerId ] )
		return
	end

	faction.name = new_name

	save_faction_data( faction.id )

	faction.cooldowns.name = true
	setTimer(function(  )
		faction.cooldowns.name = false
	end, 86400000, 1)
end

addEvent( "onCityNameChange", true )
addEventHandler( "onCityNameChange", resourceRoot, change_city_name )