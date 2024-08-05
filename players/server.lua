local DB

local function isValidEmail(email)
    local pattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+%.[a-zA-Z]+$"
    return email:match(pattern) ~= nil
end

local function connect()
	loadstring( exports.interfacer:extend( "SDB" ) )(  )
	DB = Connection.new( "Test", "127.0.0.1", "root", "13371337" )
	DB:connect(  )
end

addEventHandler( "onResourceStart", resourceRoot, connect )

--===========================Custom events===========================

local function add_player( player )
	spawnPlayer( player, 0, 0, 5 )
	fadeCamera( player, true )
	setCameraTarget( player, player )
end

addEvent( "onPlayerSignIn", true )
addEventHandler( "onPlayerSignIn", resourceRoot, add_player )

local function add_player_db( player, email, password, serial )
	if getElementType( player ) ~= "player" then return end
	if not isValidEmail( email ) then return end
	if type( password ) ~= "string" then return end
	if type( serial ) ~= "string" then return end

	DB:query( "INSERT INTO players (email, password, serial, status) VALUES (?, ?, ?, ?)", email, password, serial, "member" )
	add_player( player )
end

addEvent( "onPlayerSignUp", true )
addEventHandler( "onPlayerSignUp", resourceRoot, add_player_db )

local function get_serials( player )
	if getElementType( player ) ~= "player" then return end

	local serial = getPlayerSerial( player )

	local data = DB:query( "SELECT * FROM players WHERE serial = ?", serial )

	triggerClientEvent( player, "onPlayerFetchSerials", resourceRoot, #data )
end

addEvent( "onPlayerRequestSerials", true )
addEventHandler( "onPlayerRequestSerials", resourceRoot, get_serials )

local function check_validation( player, email, password )
	if getElementType( player ) ~= "player" then return end
	if not isValidEmail( email ) then return end
	if type( password ) ~= "string" then return end

	local is_validated = false

	local data = DB:query( "SELECT * FROM players WHERE email = ? AND password = ?", email, password )
	local status

	if data and #data > 0 then
		is_validated = true

		for _, v in pairs( data ) do
			status = v.status
		end
	end

	if status then
		setElementData( player, "player_status", status, false )
	end
	triggerClientEvent( player, "onPlayerFetchValidation", resourceRoot, is_validated )
end

addEvent( "onPlayerRequestValidation", true )
addEventHandler( "onPlayerRequestValidation", resourceRoot, check_validation )