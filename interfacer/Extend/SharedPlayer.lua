ID_TABLE = {}

Player = {}
Player.__index = Player

function Player.new( source )
	local self = setmetatable( {  }, Player )

	self.playerElement = source

	local new_player_id = #ID_TABLE
	local current_id = new_player_id + 1
	self.id = current_id
	ID_TABLE[ current_id ] = source

	return self
end

function Player:GetID(  )
	return self.id
end

function Player:GetPlayerElement(  )
	return self.playerElement
end

function GetPlayerById( id )
	return ID_TABLE[ id ]
end