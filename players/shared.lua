function IsValidEmail( email )
    local pattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+%.[a-zA-Z]+$"
    return email:match( pattern ) ~= nil
end

function IsValidPassword( password )
    if type( password ) ~= "string" then return false end
    if #password < 8 then return false end
    local hasSpace = string.find( password, " " )
    if hasSpace then return false end

    return true
end

function IsValidSerial( player, serial )
    if type( serial ) ~= "string" then return false end
    local player_serial = getPlayerSerial( player )
    if player_serial ~= serial then return false end

    return true
end