local id_table = {}
local next_id = 0

function IsIdExists(id)
	for i = 1, #id_table do
		if id == id_table[i].id then
			return true
		end
    end

	return false
end

function GetPlayerById(id)
	for i = 1, #id_table do
		if id == id_table[i].id then
			return id_table[i].player
		end
    end

	return nil
end

function GetPlayerId(player)
	for i = 1, #id_table do
		if player == id_table[i].player then
			return id_table[i].id
		end
    end

	return nil
end

local function addPlayerId()
	next_id = next_id + 1
	table.insert(id_table, { id = next_id, player = source })

	triggerClientEvent("onPlayerGetIds", resourceRoot, id_table)
end

local function removePlayerId()
	for i = 1, #id_table do
		if source == id_table[i].player then
			table.remove(id_table, i)
		end
    end
end

addEventHandler("onPlayerJoin", root, addPlayerId)
addEventHandler("onPlayerQuit", root, removePlayerId)

--===========================Custom events===========================

local function getId(player)
	for i = 1, #id_table do
		if player == id_table[i].player then
			triggerClientEvent(player, "onPlayerResponseId", resourceRoot, id_table[i].id)
		end
	end
end

addEvent("onPlayerRequestId", true)
addEventHandler("onPlayerRequestId", resourceRoot, getId)