local DB

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

local function get_reg_serials( serial )
	local data = DB:query( "SELECT * FROM players WHERE serial = ?", serial )
	return #data
end

local function add_player_db( email, password, serial )
	local is_auth = true

	if not IsValidEmail( email ) then
		is_auth = false
	end
	if not IsValidPassword( password ) then
		is_auth = false
	end
	if not IsValidSerial( client, serial ) then
		is_auth = false
	end

	local registered_serials = get_reg_serials( serial )
	if registered_serials >= 3 then
		triggerClientEvent( client, "onAlertReceive", resourceRoot, "Слишком много аккаунтов" )
		is_auth = false
	end

	if not is_auth then
		triggerClientEvent( client, "onAuthResponse", resourceRoot, is_auth )
		return
	end

	DB:query( "INSERT INTO players (email, password, serial, status) VALUES (?, ?, ?, ?)", email, password, serial, 0 )
	triggerClientEvent( client, "onAuthResponse", resourceRoot, is_auth )
	add_player( client )
end

addEvent( "onPlayerSignUp", true )
addEventHandler( "onPlayerSignUp", resourceRoot, add_player_db )

local function check_validation( email, password )
	local is_validated = true

	if not IsValidEmail( email ) then
		is_validated = false
	end
	if not IsValidPassword( password ) then
		is_validated = false
	end

	local data = DB:query( "SELECT * FROM players WHERE email = ? AND password = ?", email, password )

	if not data or #data <= 0 then
		is_validated = false
	end

	if not is_validated then
		triggerClientEvent( client, "onAlertReceive", resourceRoot, "Неверные почта/пароль" )
		triggerClientEvent( client, "onAuthResponse", resourceRoot, is_validated )
		return
	end

	local status
	for _, v in pairs( data ) do
		status = v.status
	end

	if status then
		setElementData( client, "player_status", status, false )
	end

	triggerClientEvent( client, "onAuthResponse", resourceRoot, is_validated )
	add_player( client )
end

addEvent( "onPlayerRequestValidation", true )
addEventHandler( "onPlayerRequestValidation", resourceRoot, check_validation )