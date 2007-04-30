AddCSLuaFile( "autorun/Beam_NetVars.lua" )

//***********************************************************
//		Get/Set Networked Beam Var
//
//	Basicly this one doesn't umsg.PoolString( Key )
//	And has some other tweaks
//***********************************************************

local meta = FindMetaTable( "Entity" )

// Return if there's nothing to add on to
if (!meta) then return end

local Vector_Default 	= Vector(0,0,0)
local Angle_Default		= Angle(0,0,0)

local NetworkVars 			= {}

local NetworkFunction 	= {}
local DelayedUpdates 	= {}

local NextCleanup		= CurTime()

if ( CLIENT ) then

	local function Dump()
	
		Msg("Networked Beam Vars...\n")
		PrintTable( NetworkVars )
		
	end
	
	concommand.Add( "networkbeamvars_dump", Dump )

end

local function AttemptToSwitchTables( Ent, EntIndex )

	if ( NetworkVars[ EntIndex ] == nil ) then return end

	// We have an old entindex based entry! Move it over!
	NetworkVars[ Ent ] = NetworkVars[ EntIndex ]
	NetworkVars[ EntIndex ] = nil
	
end

local function CleaupNetworkVars()

	if ( NextCleanup > CurTime() ) then return end
	NextCleanup	= CurTime() + 2

	for k, v in pairs( NetworkVars ) do
	
		if ( type( k ) != "number" && type( k ) != "string" ) then
		
			if ( !k:IsValid() ) then
				NetworkVars[ k ] = nil
			end
		
		end
	
	end

end

local function GetNetworkTable( ent, name )
	
	if ( CLIENT ) then
		CleaupNetworkVars()
	end
	
	if ( !NetworkVars[ ent ] ) then
	
		NetworkVars[ ent ] = {}
		
		// This is the first time this entity has been created. 
		// Check whether we previously had an entindex based table
		if ( CLIENT && type( ent ) != "number" && type( ent ) != "string" ) then
			AttemptToSwitchTables( ent, ent:EntIndex() )
		end
	
	end
	
	NetworkVars[ ent ][ name ] = NetworkVars[ ent ][ name ] or {}
	return NetworkVars[ ent ][ name ]

end

local function SendNetworkUpdate( VarType, Index, Key, Value, Player )
	
	umsg.Start( "RcvEntityVarBeam_"..VarType, Player )
		umsg.Short( Index )
		umsg.String( Key )
		umsg[ NetworkFunction[VarType].SetFunction ]( Value )
	umsg.End()
	
	//umsg.PoolString( Key )

end

local function AddDelayedNetworkUpdate( VarType, Ent, Key, Value )
	if (Wire_FastOverlayTextUpdate) then
		SendNetworkUpdate( VarType, Ent, Key, Value )
	else
		DelayedUpdates[ VarType ] = DelayedUpdates[ VarType ] or {}
		DelayedUpdates[ VarType ][Ent] = DelayedUpdates[ VarType ][Ent] or {}
		DelayedUpdates[ VarType ][Ent][Key] = Value
	end
end

local function AddNetworkFunctions( name, SetFunction, GetFunction, Default )

	NetworkFunction[ name ] = {}
	NetworkFunction[ name ].SetFunction = SetFunction
	NetworkFunction[ name ].GetFunction = GetFunction
	
	// SetNetworkedBlah
	meta[ "SetNetworkedBeam" .. name ] = function ( self, key, value, urgent )
	
		key = tostring(key)
	
		// The same - don't waste our time.
		if ( value == GetNetworkTable( self, name )[ key ] ) then return end
		
		// Clients can set this too, but they should only really be setting it
		// when they expect the exact same result coming over the wire (ie prediction)
		GetNetworkTable( self, name )[key] = value
			
		if ( SERVER ) then
		
			local Index = self:EntIndex()
			if (Index <= 0) then return end
		
			if ( urgent ) then
				SendNetworkUpdate( name, Index, key, value )
			else
				AddDelayedNetworkUpdate( name, Index, key, value )
			end
			
		end
		
	end
	
	meta[ "SetNWB" .. name ] = meta[ "SetNetworkedBeam" .. name ]
	
	// GetNetworkedBlah
	meta[ "GetNetworkedBeam" .. name ] = function ( self, key, default )
	
		key = tostring(key)
	
		local out = GetNetworkTable( self, name )[ key ]
		if ( out != nil ) then return out end
		if ( default == nil ) then return Default end
		//default = default or Default

		return default
		
	end
	
	meta[ "GetNWB" .. name ] = meta[ "GetNetworkedBeam" .. name ]
	
	
	// SetGlobalBlah
	_G[ "SetGlobalBeam"..name ] = function ( key, value, urgent ) 

		key = tostring(key)
	
		if ( value == GetNetworkTable( "G", name )[key] ) then return end
		GetNetworkTable( "G", name )[key] = value
			
		if ( SERVER ) then
			if ( urgent ) then
				SendNetworkUpdate( name, -1, key, value )
			else
				AddDelayedNetworkUpdate( name, -1, key, value )
			end
		end
		
	end
	
	
	// GetGlobalBlah
	_G[ "GetGlobalBeam"..name ] = function ( key ) 

		key = tostring(key)
	
		local out = GetNetworkTable( "G", name )[key]
		if ( out != nil ) then return out end
		
		return Default
		
	end
	
	
	if ( SERVER ) then
		// Pool the name of the function. 
		// Makes it send a number representing the string rather than the string itself.
		// Only do this with strings that you send quite a bit and always stay the same.
		umsg.PoolString( "RcvEntityBeamVar_"..name )
	end
	
	// Client Receive Function
	if ( CLIENT ) then
	
		local function RecvFunc( m )
		
			local EntIndex 	= m:ReadShort()
			local Key		= m:ReadString()
			local Value		= m[GetFunction]( m )
			
			local IndexKey
			
			if ( EntIndex <= 0 ) then 
			
				IndexKey = "G" 
				
			else
			
				IndexKey = Entity( EntIndex )
				
				// No entity yet - store using entindex
				if ( IndexKey == NULL ) then IndexKey = EntIndex end
				
			end
			
			GetNetworkTable( IndexKey, name )[Key] = Value	
			
			//Msg("RECV: "..EntIndex.." | "..tostring(IndexKey).." - "..tostring(Key).." - "..tostring(Value).."\n");
			
		end
		
		usermessage.Hook( "RcvEntityVarBeam_"..name, RecvFunc )
	
	end

end

AddNetworkFunctions( "Vector", 	"Vector", 	"ReadVector", 	Vector_Default )
AddNetworkFunctions( "Angle", 	"Angle", 	"ReadAngle", 	Angle_Default )
AddNetworkFunctions( "Float", 	"Float", 	"ReadFloat", 	0 )
AddNetworkFunctions( "Int", 	"Short", 	"ReadShort", 	0 )
AddNetworkFunctions( "Entity", 	"Entity", 	"ReadEntity", 	NULL )
AddNetworkFunctions( "Bool", 	"Bool", 	"ReadBool", 	false )
AddNetworkFunctions( "String", 	"String", 	"ReadString", 	"" )

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
// Send a networkvar staggered to avoid sending too much in one tick
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
local function StaggeredNetworkUpdate( Type, Index, Key, Value, ply )

	SendNetworkUpdate( Type, Index , Key, Value, ply )

end

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
// Send a full update to player that have just joined the server
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
local function FullUpdateEntityNetworkVars( ply )

	for Ent, EntTable in pairs(NetworkVars) do
	
		for Type, TypeTable in pairs(EntTable) do
		
			for Key, Value in pairs(TypeTable) do
			
				local Index = Ent
				
				if ( type(Ent) != "string" ) then
					Index = Ent:EntIndex()
				end
			
				SendNetworkUpdate( Type, Index , Key, Value, ply )
							
			end
		end

	end


end

hook.Add( "PlayerInitialSpawn", "FullUpdateEntityNetworkBeamVars", FullUpdateEntityNetworkVars )

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
// We want our networked vars to save don't we? Yeah - we do - stupid.
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
local function Save( save )

	// Remove baggage
	for k, v in pairs(NetworkVars) do
		if ( k == NULL ) then
			NetworkVars[k] = nil
		end
	end
	
	//PrintTable(NetworkVars)
	saverestore.WriteTable( NetworkVars, save )

end

local function Restore( restore )

	NetworkVars = saverestore.ReadTable( restore )
	//PrintTable(NetworkVars)

end

saverestore.AddSaveHook( "EntityNetworkedBeamVars", Save )
saverestore.AddRestoreHook( "EntityNetworkedBeamVars", Restore )


///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
// We update the vars periodically instead of on demand, because we're not made of bandwidth
// Do you think it grows on trees or something? You'll see. You'll find out when you get your
// own job and you come home every night and the fire is on full blast.
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
local NextBeamVarsDelayedSendTime = 0
local function NetworkVarsSend()
	if (CurTime() >= NextBeamVarsDelayedSendTime) then
		
		for VarType, a in pairs(DelayedUpdates) do
			
			for Index, b in pairs(a) do
			
				for Key, Value in pairs(b) do
				
					SendNetworkUpdate( VarType, Index, Key, Value )
					
				end
				
			end
			
		end
		
		// Clear the sent entries
		DelayedUpdates = {}
		
		NextBeamVarsDelayedSendTime = CurTime() +  .1
	end
end
//timer.Create( "NetworkBeamVarsSend", 0.01, 0, NetworkVarsSend )
hook.Add("Think", "NetBeamLib_Think", NetworkVarsSend)


///////////////////////////////////////////////////////////////////////////////////////////////
// Listen out for dead entities so we can remove their vars
///////////////////////////////////////////////////////////////////////////////////////////////
local function NetworkVarsCleanup( ent )

	if ( SERVER ) then
		NetworkVars[ ent ] = nil
	end

end

hook.Add( "EntityRemoved", "NetworkBeamVarsCleanup", NetworkVarsCleanup )


