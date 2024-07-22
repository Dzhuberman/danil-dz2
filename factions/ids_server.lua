local id_table = {}

function GetPlayerById(id)
	return id_table[id]
end

function GetPlayerId(player)
	for i = 1, #id_table do
		if player == id_table[i] then
			return i
		end
    end

	return nil
end

local function addPlayerId()
	local newPlayerId = #id_table
	local currentId = newPlayerId + 1
	id_table[currentId] = source

	triggerClientEvent("onPlayerGetIds", resourceRoot, id_table)
end

local function removePlayerId()
	local playerId = GetPlayerId(source)
	id_table[playerId] = nil
end

addEventHandler("onPlayerJoin", root, addPlayerId)
addEventHandler("onPlayerQuit", root, removePlayerId)

--===========================Custom events===========================

local function getId(player)
	local playerId = GetPlayerId(player)
	triggerClientEvent(player, "onPlayerResponseId", resourceRoot, playerId)
end

addEvent("onPlayerRequestId", true)
addEventHandler("onPlayerRequestId", resourceRoot, getId)