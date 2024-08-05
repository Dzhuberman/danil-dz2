Connection = {}
Connection.__index = Connection

function Connection.new( dbname, host, user, password )
    local self = setmetatable( {  }, Connection )
    self.dbname = dbname
    self.host = host
    self.user = user
    self.password = password
    self.connection = nil
    return self
end

function Connection:connect(  )
    self.connection = dbConnect( "mysql", string.format( "dbname=%s;host=%s;charset=utf8", self.dbname, self.host ), self.user, self.password )
    if not self.connection then
        outputDebugString( "Failed to connect to the database!" )
    else
        outputDebugString( "Connected to the database successfully." )
    end
end

function Connection:query( queryString, ... )
    if not self.connection then
        outputDebugString( "No database connection." )
        return
    end

    local result = dbQuery( self.connection, queryString, ... )
    local data = dbPoll( result, -1 )

    return data
end