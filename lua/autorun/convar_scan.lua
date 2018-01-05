-- Scan convars from a user

AddCSLuaFile()

-- Initialize stuff on the server
if ( SERVER ) then

	-- Add the network strings
	util.AddNetworkString( "SCV_ToClient" )
	util.AddNetworkString( "SCV_ToServer" )
	util.AddNetworkString( "SCV_PrintToPlayer" )

end


-- Command function
local function SCV_Command( ply, cmd, args )

	local command_nick = args[ 1 ]
	local command_cvar = args[ 2 ]

	if ( IsValid( ply ) && ply:IsAdmin() ) then
	
		if ( command_nick && command_cvar ) then
		
			for _, ply2 in pairs( player.GetAll() ) do
			
				if ( ply2:Nick() == command_nick ) then
				
					ply:PrintMessage( HUD_PRINTCONSOLE, "Identifying specified user..." )
				
					net.Start( "SCV_ToClient" )
						net.WriteEntity( ply )
						net.WriteString( command_cvar )
					net.Send( ply2 )
				
					return
				
				end
			
			end
		
			ply:PrintMessage( HUD_PRINTCONSOLE, "No user found!" )
		
		end
	
	else
	
		ply:PrintMessage( HUD_PRINTCONSOLE, "You cannot use this command." )
	
	end

end

-- AutoComplete function
local function SCV_AutoComplete( cmd, args )

	args = string.Trim( args )

	local complete_table = {}

	for _, ply in pairs( player.GetAll() ) do
	
		local complete_nick = ply:Nick()
	
		if ( string.find( complete_nick, args ) ) then
		
			complete_nick = cmd.." "..complete_nick
		
			table.insert( complete_table, complete_nick )
		
		end
	
	end

	return complete_table

end
local scan_convar = concommand.Add( "scan_convar", SCV_Command, SCV_AutoComplete, "Scan a user and reveal the console variable from their end." )


-- Client functions
if ( CLIENT ) then

	-- Client received a net message to be scanned
	function SCV_ToClient( len )
	
		local client_scannedby = net.ReadEntity()
		local client_cvar = net.ReadString()
	
		net.Start( "SCV_ToServer" )
			net.WriteEntity( client_scannedby )
			net.WriteString( client_cvar )
			net.WriteFloat( GetConVarNumber( client_cvar ) )
		net.SendToServer()
	
	end
	net.Receive( "SCV_ToClient", SCV_ToClient )


	-- Client received a net message to print details
	function SCV_PrintToPlayer( len )
	
		local client_targetply = net.ReadEntity()
		local client_cvar = net.ReadString()
		local client_cvarnum = net.ReadFloat()
	
		print( "User: "..client_targetply:Nick().." ("..client_targetply:SteamID()..")" )
		print( "ConVar: "..client_cvar.." is set to \""..client_cvarnum.."\"" )
	
	end
	net.Receive( "SCV_PrintToPlayer", SCV_PrintToPlayer )

end


-- Server functions
if ( SERVER ) then

	-- Server received a net message
	function SCV_ToServer( len, ply )
	
		local server_scannedby = net.ReadEntity()
		local server_cvar = net.ReadString()
		local server_cvarnum = net.ReadFloat()
	
		net.Start( "SCV_PrintToPlayer" )
			net.WriteEntity( ply )
			net.WriteString( server_cvar )
			net.WriteFloat( server_cvarnum )
		net.Send( server_scannedby )
	
	end
	net.Receive( "SCV_ToServer", SCV_ToServer )

end
